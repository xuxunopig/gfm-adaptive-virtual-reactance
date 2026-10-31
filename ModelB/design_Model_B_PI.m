function p=design_Model_B_PI(p,fc,fv,zeta)
% 秒制对象：电流环 Lf/omega0*s+rLf，电压环 Cf/omega0*s。
% 电流PI零点补偿支路电阻极点；电压PI按二阶自然频率与阻尼选取。
if nargin<4,zeta=1/sqrt(2);end
w0=2*pi*p.freq;wc=2*pi*fc;wv=2*pi*fv;
p.Kpc=p.xLf*wc/w0;p.Kic=p.rLf*wc;
p.Kpv=2*zeta*wv*p.bCf/w0;p.Kiv=wv^2*p.bCf/w0;
p.designCurrentHz=fc;p.designVoltageHz=fv;p.designDamping=zeta;
end
