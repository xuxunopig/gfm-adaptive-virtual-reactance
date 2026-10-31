function r=run_Model_B(p,showScopes)
% 运行Simulink模型，保留失败前的实际输出及错误信息。
here=fileparts(mfilename('fullpath'));addpath(here,fullfile(here,'..','ModelA'));
if nargin<1,p=Model_B_parameters();end
if nargin<2,showScopes=true;end
if ~isfile(fullfile(here,'Model_B.slx')),build_Model_B(p);end
load_system(fullfile(here,'Model_B.slx'));Model_B_configure(p);
sc=find_system('Model_B','LookUnderMasks','all','BlockType','Scope');
for k=1:numel(sc),c=get_param(sc{k},'ScopeConfiguration');c.OpenAtSimulationStart=showScopes;end
restore=onCleanup(@() restoreScopes(sc)); %#ok<NASGU>
o=sim('Model_B','CaptureErrors','on');
mw=get_param('Model_B','ModelWorkspace');r.parameters=mw.getVariable('p');r.initial=mw.getVariable('ic');
r.matlabVersion=version;r.errorMessage=o.ErrorMessage;r.status='completed';r.time=[];r.data=[];
if any(strcmp(o.who,'ModelB_log'))
 t=o.get('ModelB_log');r.time=t.Time;r.data=squeeze(t.Data);
 if size(r.data,1)~=numel(r.time),r.data=r.data.';end
end
if ~isempty(r.errorMessage),r.status='simulation_error';if contains(r.errorMessage,'Model_B_DAE_'),r.status='algebraic_failure';end
elseif isempty(r.time) || r.time(end)<p.tStop-1e-7,r.status='stopped_early';end
r.columns={'delta_rad','omega_pu_deviation','E_pu','xv_pu','xi_vd_pus','xi_vq_pus','xi_id_pus','xi_iq_pus', ...
 'if_d_pu','if_q_pu','vc_d_pu','vc_q_pu','io_d_pu','io_q_pu', ...
 'VG_real_pu','VG_imag_pu','VG_abs_pu','VT_real_pu','VT_imag_pu','VT_abs_pu','VB_d_pu','VB_q_pu', ...
 'CP_discriminant','load_is_Z','algebraic_residual','jacobian_sigma_min','P_PCC_pu','Q_PCC_pu','Io_abs_pu', ...
 'vc_ref_d_pu','vc_ref_q_pu','if_ref_d_pu','if_ref_q_pu','vm_d_pu','vm_q_pu','ev_d_pu','ev_q_pu','ei_d_pu','ei_q_pu','fault_active'};
r.maxResidual=NaN;if ~isempty(r.data),r.maxResidual=max(r.data(:,25));end
actualEnd=NaN;if ~isempty(r.time),actualEnd=r.time(end);end
fprintf('Model B: %s, end %.9g s, maximum algebraic residual %.3g\n',r.status,actualEnd,r.maxResidual);
if ~isempty(r.errorMessage),fprintf('%s\n',r.errorMessage);end
end
function restoreScopes(sc)
for k=1:numel(sc),c=get_param(sc{k},'ScopeConfiguration');c.OpenAtSimulationStart=true;end
end
