function Model_A_initialize(mdl)
% InitFcn: ALWAYS recompute a consistent SEP, including direct Run clicks.
if nargin<1,mdl='Model_A';end
p=Model_A_parameters();
mw=get_param(mdl,'ModelWorkspace');
if mw.hasVariable('p'),p=mw.getVariable('p');end
names=Model_A_parameter_fields();
for k=1:numel(names)
    % Numeric literal mask fields deliberately avoid stale base-workspace vars.
    v=str2double(get_param([mdl '/Parameters'],names{k}));
    p.(names{k})=v;
end
p.solver=get_param([mdl '/Parameters'],'solverName');
Model_A_validate_parameters(p);
ic=Model_A_initial_state(p);
mw.assignin('p',p);mw.assignin('ic',ic);
mw.assignin('networkParameters',Model_A_network_parameters(p));
set_param(mdl,'StopTime',sprintf('%.17g',p.tStop),'Solver',p.solver, ...
 'MaxStep',sprintf('%.17g',p.maxStep),'RelTol',sprintf('%.17g',p.relTol), ...
 'AbsTol',sprintf('%.17g',p.absTol));
% Immutable active-run snapshot also used by StopFcn and external sweeps.
set_param([mdl '/Parameters'],'UserData',struct('p',p,'ic',ic),'UserDataPersistent','off');
end
