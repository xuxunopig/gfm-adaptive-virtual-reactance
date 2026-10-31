function [dx,y]=Model_B_rhs(x,phase,p,Vnom)
% 独立方程入口用于稳态、线性化与结果复核，SLX采用分立控制模块。
w0=2*pi*p.freq;nu=1+x(2);J=[0 -1;1 0];
xiv=x(5:6);xii=x(7:8);iF=x(9:10);vc=x(11:12);io=x(13:14);
n=Model_B_network([x(1);io],phase,Model_A_network_parameters(p),Vnom);
ref=[x(3);0]-x(4)*J*io;ev=ref-vc;
iref=io+nu*p.bCf*J*vc+p.Kpv*ev+p.Kiv*xiv;ei=iref-iF;
vm=vc+nu*p.xLf*J*iF+p.Kpc*ei+p.Kic*xii;
Pe=x(3)*io(1);Qe=-x(3)*io(2);
dx=[w0*x(2);(p.Pref-Pe-p.D*x(2))/p.M; ...
    (p.Qref-Qe-p.Dq*(x(3)-p.Eref))/p.K; ...
    p.omegaVI*(p.KVI*p.SigmaXR*max(norm(io)-p.Ithresh,0)-x(4)); ...
    ev;ei;w0/p.xLf*(vm-vc-p.rLf*iF-nu*p.xLf*J*iF); ...
    w0/p.bCf*(iF-io-nu*p.bCf*J*vc); ...
    w0/p.xLc*(vc-n(7:8)-p.rLc*io-nu*p.xLc*J*io)];
y=[n;ref;iref;vm;ev;ei;phase];
end
