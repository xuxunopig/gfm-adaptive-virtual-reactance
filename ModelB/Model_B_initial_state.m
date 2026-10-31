function ic=Model_B_initial_state(p)
% 沿新增网侧滤波支路从零至目标值延拓高压稳态。
icA=Model_A_initial_state(p);ic.Vnom=icA.Vnom;ic.referenceA=icA;
z=[icA.x0(1);icA.x0(3);icA.x0(4);real(icA.V0);imag(icA.V0)];
opt=optimoptions('fsolve','Display','off','FunctionTolerance',1e-12, ...
    'StepTolerance',1e-12,'OptimalityTolerance',1e-12,'MaxIterations',300);
for lam=linspace(0,1,21)
    [z,r,flag]=fsolve(@(zz) equations(zz,lam),z,opt);
    assert(flag>0 && norm(r,inf)<1e-9,'Model_B:InitialPoint','稳态延拓失败。');
end
Io=(z(2)*exp(1i*z(1))-complex(z(4),z(5)))/(p.rLc+1i*(p.xLc+p.xe+p.xL1+z(3)));
io=[real(Io*exp(-1i*z(1)));imag(Io*exp(-1i*z(1)))];
J=[0 -1;1 0];vc=[z(2);0]-z(3)*J*io;iF=io+p.bCf*J*vc;
ic.x0=[z(1);0;z(2);z(3);zeros(2,1);p.rLf/p.Kic*iF;iF;vc;io];
[dx,ic.y0]=Model_B_rhs(ic.x0,0,p,ic.Vnom);ic.residual=norm(dx,inf);
assert(ic.residual<1e-7,'Model_B:InitialResidual','14状态初始残差过大。');
Jac=zeros(14);
for k=1:14
 h=1e-6*(1+abs(ic.x0(k)));xp=ic.x0;xm=xp;xp(k)=xp(k)+h;xm(k)=xm(k)-h;
 Jac(:,k)=(Model_B_rhs(xp,0,p,ic.Vnom)-Model_B_rhs(xm,0,p,ic.Vnom))/(2*h);
end
ic.Jacobian=Jac;ic.eigenvalues=eig(Jac);
    function r=equations(z,lam)
        V=complex(z(4),z(5));Ei=z(2)*exp(1i*z(1));
        I=(Ei-V)/(lam*p.rLc+1i*(lam*p.xLc+p.xe+p.xL1+z(3)));
        Se=Ei*conj(I);Vs=p.VS*exp(1i*p.thetaS);
        g=V*conj(I-(V-Vs)/(1i*p.xL2))-complex(p.PL,p.QL);
        r=[real(Se)-p.Pref;imag(Se)+p.Dq*(z(2)-p.Eref)-p.Qref; ...
            z(3)-p.KVI*p.SigmaXR*max(abs(I)-p.Ithresh,0);real(g);imag(g)];
    end
end
