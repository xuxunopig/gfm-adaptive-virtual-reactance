function Model_B_configure(p)
% 把参数写入模型自身并在下次仿真前重新初始化。
load_system('Model_B');mw=get_param('Model_B','ModelWorkspace');mw.assignin('p',p);
m=Simulink.Mask.get('Model_B/参数');
for k=1:numel(m.Parameters),m.Parameters(k).Value=num2str(p.(m.Parameters(k).Name),17);end
Model_B_initialize('Model_B');
end
