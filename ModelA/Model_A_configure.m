function Model_A_configure(p,mdl)
% Push a complete parameter struct into the single editable model mask.
if nargin<2,mdl='Model_A';end
Model_A_validate_parameters(p);
load_system(mdl);
names=Model_A_parameter_fields();
for k=1:numel(names)
    set_param([mdl '/Parameters'],names{k},sprintf('%.17g',p.(names{k})));
end
set_param([mdl '/Parameters'],'solverName',p.solver);
mw=get_param(mdl,'ModelWorkspace');mw.assignin('p',p);
Model_A_initialize(mdl);
end
