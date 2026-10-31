function n=Model_B_network(z,phase,a,Vnom)
%#codegen
% z=[delta;iod;ioq]；电流端口连接原外部准稳态网络。
Io=complex(z(2),z(3))*exp(1i*z(1));Vs=a(6)*exp(1i*a(7));
Y=1/(1i*a(3));if phase==1,Y=Y+1/complex(a(8),a(9));end
A=Io+Vs/(1i*a(3));S=complex(a(4),a(5));
aa=abs(Y)^2;b=abs(A)^2-2*real(Y*S);disc=b*b-4*aa*abs(S)^2;
exists=disc>0 && b>0 && abs(A)>0;Vcp=complex(0,0);
if exists,u=(b+sqrt(disc))/(2*aa);Vcp=conj((Y*u+conj(S))/A);end
V=Vcp;loadZ=false;
if phase==1 && a(10)~=0
    Vz=A/(Y+conj(S)/(Vnom*Vnom));
    if (~exists || abs(Vcp)<a(11)) && abs(Vz)<a(11),V=Vz;loadZ=true;end
end
assert(~(disc==0 && b>0 && abs(A)>0 && ~loadZ),'Model_B_DAE_SINGULAR: algebraic branches meet.');
assert(exists || loadZ,'Model_B_DAE_NO_REAL_SOLUTION: original external network has no regular high-voltage solution.');
assert(abs(V)>0,'Model_B_DAE_ZERO_VOLTAGE');
Seff=S;if loadZ,Seff=S*abs(V)^2/(Vnom*Vnom);end
g=V*conj(A-Y*V)-Seff;
vr=real(V);vi=imag(V);G=real(Y);B=imag(Y);
J=[real(A)-2*G*vr,imag(A)-2*G*vi;-imag(A)+2*B*vr,real(A)+2*B*vi];
if loadZ,J=J-2/(Vnom*Vnom)*[a(4)*vr,a(4)*vi;a(5)*vr,a(5)*vi];end
sv=svd(J);
VT=V+1i*a(2)*Io;VB=(VT+1i*a(1)*Io)*exp(-1i*z(1));Spcc=VT*conj(Io);
n=[real(V);imag(V);abs(V);real(VT);imag(VT);abs(VT);real(VB);imag(VB); ...
    disc;double(loadZ);max(abs([real(g);imag(g)]));min(sv);real(Spcc);imag(Spcc);abs(Io)];
end
