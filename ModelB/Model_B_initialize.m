function Model_B_initialize(mdl)
% 直接运行时从模型参数面板读取并重新求解一致初值。
if nargin<1,mdl='Model_B';end
here=fileparts(mfilename('fullpath'));addpath(here,fullfile(here,'..','ModelA'));
mw=get_param(mdl,'ModelWorkspace');p=mw.getVariable('p');
mask=Simulink.Mask.get([mdl '/参数']);
for k=1:numel(mask.Parameters)
    name=mask.Parameters(k).Name;p.(name)=str2double(mask.Parameters(k).Value);
end
assert(all([p.xLf,p.xLc,p.bCf,p.Kpv,p.Kiv,p.Kpc,p.Kic]>0),'内环与滤波参数必须为正。');
ic=Model_B_initial_state(p);mw.assignin('p',p);mw.assignin('ic',ic);
mw.assignin('networkParameters',Model_A_network_parameters(p));
set_param(mdl,'StopTime',num2str(p.tStop,17),'Solver','ode15s', ...
 'MaxStep',num2str(p.maxStep,17),'RelTol',num2str(p.relTol,17),'AbsTol',num2str(p.absTol,17));
end
