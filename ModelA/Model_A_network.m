function n = Model_A_network(x, phase, a, Vnom)
%#codegen
% EXACT algebraic solve of the paper's single-load-bus DAE, high-voltage
% component connected to the pre-fault SEP. No voltage floor/regularization.
% x=[delta; omega_pu_deviation; E; xv]
% a=[xe;xL1;xL2;PL;QL;VS;thetaS;Rf;Xf;faultLoadToZ;Vswitch]
% n=[Vr;Vi;|V|;Pe;Qe;|I|;Qbus;CP discriminant;loadZ;
%    |g|inf;sigma_min(dg/d[Vr,Vi]);xv_command_unused]
n = zeros(12,1);
X = a(1)+a(2)+x(4);
assert(X>0 && a(3)>0, 'Model_A: nonpositive equivalent reactance.');
Ei = x(3)*exp(1i*x(1));
Vs = a(6)*exp(1i*a(7));
Y = 1/(1i*X) + 1/(1i*a(3));
if phase == 1
    Y = Y + 1/complex(a(8),a(9));
end
A = Ei/(1i*X) + Vs/(1i*a(3));
S = complex(a(4),a(5));
aa = abs(Y)^2;
b = abs(A)^2-2*real(Y*S);
disc = b*b-4*aa*abs(S)^2;
cpExists = disc>=0 && b>0 && abs(A)>0;
Vcp = complex(0,0);
if cpExists
    u = (b+sqrt(disc))/(2*aa);
    Vcp = conj((Y*u+conj(S))/A);
end
loadZ = false;
V = Vcp;
if phase == 1 && a(10) ~= 0
    % The Z admittance uses the newly solved pre-fault voltage, as V0 in
    % runsimulation.m. Candidate selection solves the piecewise constraint
    % directly even when the fault CP equation has no real root.
    Vz = A/(Y+conj(S)/(Vnom*Vnom));
    if (~cpExists || abs(Vcp)<a(11)) && abs(Vz)<a(11)
        V = Vz;
        loadZ = true;
    end
end
assert(cpExists || loadZ, ...
 'Model_A_DAE_NO_REAL_SOLUTION: original algebraic constraint has no high-voltage real solution.');
assert(abs(V)>0, 'Model_A_DAE_ZERO_VOLTAGE: CPL voltage is zero.');
if loadZ
    Seff = S*abs(V)^2/(Vnom*Vnom);
else
    assert(disc>0, 'Model_A_DAE_SINGULAR: algebraic branches meet.');
    Seff = S;
end
I = (Ei-V)/(1i*X);
Sint = Ei*conj(I);
Sbus = V*conj(I);
% Original paper power-balance residual (negative sign is immaterial).
g = V*conj(A-Y*V)-Seff;
vr = real(V); vi = imag(V); G = real(Y); B = imag(Y);
% d/d[Vr,Vi] of [real(g);imag(g)], WITHOUT voltage perturbation.
J = [real(A)-2*G*vr, imag(A)-2*G*vi; ...
    -imag(A)+2*B*vr, real(A)+2*B*vi];
if loadZ
    J = J - 2/(Vnom*Vnom)*[a(4)*vr,a(4)*vi;a(5)*vr,a(5)*vi];
end
sv = svd(J);
n(1:11) = [vr;vi;abs(V);real(Sint);imag(Sint);abs(I); ...
    imag(Sbus);disc;double(loadZ);max(abs([real(g);imag(g)]));min(sv)];
end
