function Model_A_scopes(m)
% 为原模型增加命名观测口，不改动原控制或网络方程。
if nargin<1,m='Model_A';end
if getSimulinkBlockHandle([m '/Live voltage current VI'])>0,delete_block([m '/Live voltage current VI']);end
names={'G母线电压_pu','输出电流_pu','功角_rad','内源有功无功_pu','虚拟电抗_pu'};
sources={{'Network quantities/3'},{'Network quantities/6'}, ...
 {'GFM outer loops and dynamic VI/1'},{'Network quantities/4','Network quantities/5'}, ...
 {'GFM outer loops and dynamic VI/4'}};
labels={{'VG_pu'},{'Io_pu'},{'delta_rad'},{'Pe_pu','Qe_pu'},{'xv_pu'}};
for k=1:5
 b=[m '/' names{k}];if getSimulinkBlockHandle(b)<0
  add_block('simulink/Sinks/Scope',b,'Position',[1370 100+105*k 1550 165+105*k],'NumInputPorts',num2str(numel(sources{k})));
  for j=1:numel(sources{k})
   h=add_line(m,sources{k}{j},[names{k} '/' num2str(j)],'autorouting','on');set_param(h,'Name',labels{k}{j});
  end
 end
 c=get_param(b,'ScopeConfiguration');c.TimeSpan='3';c.ShowLegend=true;c.OpenAtSimulationStart=true;c.YLabel='pu';c.YLimits=[-2 5];
 if k==1,c.YLimits=[0 1.5];elseif k==2,c.YLimits=[0 12];elseif k==3,c.YLimits=[-1 2];c.YLabel='rad';elseif k==4,c.YLimits=[-2 12];elseif k==5,c.YLimits=[0 1.5];end
 c.DataLogging=true;c.DataLoggingVariableName=['ScopeA_' num2str(k)];c.DataLoggingSaveFormat='Dataset';c.DataLoggingLimitDataPoints=false;
end
lines=find_system(m,'FindAll','on','Type','line');
for h=lines(:)',if isempty(get_param(h,'LineChildren')) && all(get_param(h,'DstPortHandle')<0),delete_line(h);end,end
set_param(m,'StopFcn','');
end

