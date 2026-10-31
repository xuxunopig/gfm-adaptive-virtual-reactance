function result = run_Model_A(p)
% RUN_MODEL_A Run Simulink, recompute initial state, show and save results.
% p=Model_A_parameters(); p.tClear=0.28; result=run_Model_A(p);
folder=fileparts(mfilename('fullpath'));addpath(folder);
if nargin<1,p=Model_A_parameters();end
if ~isfile(fullfile(folder,'Model_A.slx')),build_Model_A();end
load_system(fullfile(folder,'Model_A.slx'));
Model_A_configure(p);
sc=find_system('Model_A','LookUnderMasks','all','BlockType','Scope');
for k=1:numel(sc),c=get_param(sc{k},'ScopeConfiguration');c.OpenAtSimulationStart=p.showFigures;end
restoreScope=onCleanup(@() reopenScope(sc)); %#ok<NASGU>
% Suppress duplicate StopFcn handling; the wrapper handles failed runs too.
set_param('Model_A','StopFcn','');
restore=onCleanup(@()set_param('Model_A','StopFcn','Model_A_on_stop(bdroot);')); %#ok<NASGU>
out=sim('Model_A','CaptureErrors','on');
snapshot=get_param('Model_A/Parameters','UserData');
result=Model_A_process_results(out,snapshot.p,snapshot.ic);
assignin('base','ModelA_result',result);
end

function reopenScope(sc)
for k=1:numel(sc),c=get_param(sc{k},'ScopeConfiguration');c.OpenAtSimulationStart=true;end
end
