function ic = Model_A_initial_state(p)
% Solve joint steady differential/algebraic equations for CURRENT parameters.
Model_A_validate_parameters(p);
a = Model_A_network_parameters(p);
opts=optimoptions('fsolve','Display','off','FunctionTolerance',p.initTol/10, ...
 'StepTolerance',1e-12,'OptimalityTolerance',1e-12,'MaxIterations',300);
solutions=[];
for Eguess=[p.Eref,0.9*p.Eref,1.1*p.Eref]
 for dguess=p.thetaS+[-0.1,0.05,0.3,-0.4]
    z0=[dguess;Eguess;0;p.VS*cos(p.thetaS);p.VS*sin(p.thetaS)];
    [z,res,flag]=fsolve(@equations,z0,opts);
    if flag<=0 || norm(res,inf)>p.initTol || z(2)<=0 || z(3)<-p.initTol
        continue
    end
    x=[z(1);0;z(2);z(3)];
    try
        n=Model_A_network(x,0,a,p.VS);
        if norm(n(1:2)-z(4:5),inf)>1e-6,continue,end
        % Test asymptotic stability of the actual differential dynamics.
        J=zeros(4);
        for j=1:4
            h=1e-6*(1+abs(x(j)));xp=x;xm=x;xp(j)=xp(j)+h;xm(j)=xm(j)-h;
            J(:,j)=(rhs(xp)-rhs(xm))/(2*h);
        end
        if max(real(eig(J)))>=-1e-7,continue,end
        solutions(:,end+1)=z; %#ok<AGROW>
    catch
        continue
    end
 end
end
assert(~isempty(solutions),'Model_A:NoStableEquilibrium', ...
 'No regular stable pre-fault equilibrium found for CURRENT parameters. Parameters were not changed.');
[~,idx]=max(vecnorm(solutions(4:5,:)));z=solutions(:,idx);
ic.x0=[z(1);0;z(2);z(3)];
ic.V0=complex(z(4),z(5));ic.Vnom=abs(ic.V0);
ic.network=Model_A_network(ic.x0,0,a,ic.Vnom);
ic.residual=norm(equations(z),inf);
ic.eigenvalues=eig(localJacobian(ic.x0));
    function r=equations(z)
        Ei=z(2)*exp(1i*z(1));V=complex(z(4),z(5));
        X=p.xe+p.xL1+z(3);
        if abs(V)==0 || abs(X)<1e-12
            r=1e10*ones(5,1);return
        end
        I=(Ei-V)/(1i*X);Sint=Ei*conj(I);
        Vs=p.VS*exp(1i*p.thetaS);
        g=V*conj(I-(V-Vs)/(1i*p.xL2))-complex(p.PL,p.QL);
        r=[real(Sint)-p.Pref;imag(Sint)+p.Dq*(z(2)-p.Eref)-p.Qref; ...
          z(3)-p.KVI*p.SigmaXR*max(abs(I)-p.Ithresh,0);real(g);imag(g)];
    end
    function dx=rhs(x)
        n=Model_A_network(x,0,a,p.VS);
        dx=[2*pi*p.freq*x(2);(p.Pref-n(4)-p.D*x(2))/p.M; ...
          (p.Qref-n(5)-p.Dq*(x(3)-p.Eref))/p.K; ...
          p.omegaVI*(p.KVI*p.SigmaXR*max(n(6)-p.Ithresh,0)-x(4))];
    end
    function J=localJacobian(x)
        J=zeros(4);
        for j=1:4
            h=1e-6*(1+abs(x(j)));xp=x;xm=x;xp(j)=xp(j)+h;xm(j)=xm(j)-h;
            J(:,j)=(rhs(xp)-rhs(xm))/(2*h);
        end
    end
end
