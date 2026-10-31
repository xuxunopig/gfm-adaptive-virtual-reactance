function p=Model_B_parameters(mode)
% 标幺参数；积分增益采用秒制。原外环及外部网络沿用ModelA。
if nargin<1,mode='tuned';end
here=fileparts(mfilename('fullpath'));addpath(fullfile(here,'..','ModelA'));
p=Model_A_parameters();p.basekV=345;p.tClear=.18;
p.xLf=.15;p.xLc=.15;p.bCf=.066;p.rLf=.005;p.rLc=.005;
p.Kpv=.52;p.Kiv=1.16;p.Kpc=.73;p.Kic=1.19;
p.maxStep=2e-4;p.relTol=1e-7;p.absTol=1e-9;
switch mode
 case 'initial'
 case {'baseline','tuned'}
  p=design_Model_B_PI(p,3000,.5,4);
  if strcmp(mode,'tuned')
   p.Kpv=0.0048344652483415206;
   p.Kiv=0.0017252201254877612;
   p.Kpc=6.6570597145874624;
   p.Kic=91.186772946123014;
  end
 otherwise
  error('Model_B:ParameterMode','参数模式应为initial、baseline或tuned。');
end
end
