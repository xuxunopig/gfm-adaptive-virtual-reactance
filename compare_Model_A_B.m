function comparison=compare_Model_A_B()
% 运行固定ModelA、优化前/后ModelB，重建全部主要曲线和性能对照表。
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'ModelA'),fullfile(root,'ModelB'));
dataDir=fullfile(root,'结果数据');figDir=fullfile(root,'结果图片');
if ~isfolder(dataDir),mkdir(dataDir);end;if ~isfolder(figDir),mkdir(figDir);end
pA=Model_A_parameters();pA.tClear=.18;pA.saveResults=false;pA.showFigures=false;
a=run_Model_A(pA);p0=Model_B_parameters('baseline');p=Model_B_parameters();
bBefore=run_Model_B(p0,false);b=run_Model_B(p,false);
assert(strcmp(a.status,'completed') && strcmp(bBefore.status,'completed') && strcmp(b.status,'completed'),'3s工况未完成。');
assert(isequaln(rmfield(bBefore.parameters,{'Kpv','Kiv','Kpc','Kic'}),rmfield(b.parameters,{'Kpv','Kiv','Kpc','Kic'})),'PI之外的参数不一致。');
before=PI_performance(a,bBefore);after=PI_performance(a,b);comparison.before=before;comparison.after=after;
save(fullfile(dataDir,'typical_AB.mat'),'a','b','bBefore','-v7');save(fullfile(dataDir,'comparison.mat'),'comparison','-v7');
writetable(after.metrics,fullfile(dataDir,'comparison_metrics.csv'));
writeRun(a,fullfile(dataDir,'ModelA_018.csv'));writeRun(bBefore,fullfile(dataDir,'ModelB_before_018.csv'));writeRun(b,fullfile(dataDir,'ModelB_018.csv'));
makeTables(before,after,p0,p,root,b);
drawResults(after,b,p,figDir);drawBeforeAfter(before,after,p,figDir);
p10=p;p10.tStop=10;b10=run_Model_B(p10,false);assert(strcmp(b10.status,'completed') && b10.time(end)>=10 && all(isfinite(b10.data),'all'),'10s检查未完整运行。');
save(fullfile(dataDir,'ModelB_10s.mat'),'b10','-v7');writeRun(b10,fullfile(dataDir,'ModelB_10s.csv'));
Model_B_configure(p);pA.showFigures=false;Model_A_configure(pA);
fprintf('A/B主工况均完成3s；ModelB延长工况完成10s。\n');
end
function writeRun(r,path)
writetable(array2table([r.time r.data],'VariableNames',[{'time_s'} r.columns]),path);
end
function makeTables(base,c,p0,p,root,b)
pA=Model_A_parameters();pA.tClear=.18;fields=[Model_A_parameter_fields(),{'basekV','xLf','xLc','bCf','rLf','rLc','Kpv','Kiv','Kpc','Kic'}];
va=nan(numel(fields),1);v0=va;v1=va;units=repmat("pu",numel(fields),1);
for kk=1:numel(fields)
 n=fields{kk};if isfield(pA,n),va(kk)=pA.(n);end;v0(kk)=p0.(n);v1(kk)=p.(n);
 if any(strcmp(n,{'tFault','tClear','tStop','maxStep','M','K'})),units(kk)="s";
 elseif any(strcmp(n,{'Kiv','Kic','omegaVI'})),units(kk)="1/s";
 elseif strcmp(n,'freq'),units(kk)="Hz";elseif strcmp(n,'baseMVA'),units(kk)="MVA";elseif strcmp(n,'basekV'),units(kk)="kV";
 elseif strcmp(n,'thetaS'),units(kk)="rad";
 elseif any(strcmp(n,{'Kpv','Kpc','D','Dq','SigmaXR','faultEnabled','faultLoadToZ','relTol','absTol','initTol','residualTol'})),units(kk)="1";end
end
writetable(table(string(fields'),units,va,v0,v1,'VariableNames',{'parameter','unit','ModelA','ModelB_before','ModelB_after'}),fullfile(root,'参数对照表.csv'));
d=b.data;w0=2*pi*p.freq;W=(p.xLf*sum(d(:,9:10).^2,2)+p.bCf*sum(d(:,11:12).^2,2)+p.xLc*sum(d(:,13:14).^2,2))/(2*w0);
Pbridge=sum(d(:,34:35).*d(:,9:10),2);Pport=sum(d(:,21:22).*d(:,13:14),2);Ploss=p.rLf*sum(d(:,9:10).^2,2)+p.rLc*sum(d(:,13:14).^2,2);
writetable(array2table([b.time W Pbridge Pport Ploss],'VariableNames',{'time_s','LCL_energy_pus','bridge_power_pu','external_port_power_pu','filter_loss_pu'}),fullfile(root,'结果数据','LCL_energy_power.csv'));
names={'Kpv';'Kiv';'Kpc';'Kic'};v0=cellfun(@(n)p0.(n),names);v=cellfun(@(n)p.(n),names);
writetable(table(string(names),["1";"1/s";"1";"1/s"],v0,v,100*(v./v0-1), ...
 'VariableNames',{'parameter','unit','before','after','change_percent'}),fullfile(root,'PI参数表.csv'));
a=base.metrics;b=c.metrics;
T=table(a.quantity,a.unit,a.absolute_RMSE,b.absolute_RMSE,100*(1-b.absolute_RMSE./a.absolute_RMSE), ...
 a.increment_RMSE,b.increment_RMSE,100*(1-b.increment_RMSE./a.increment_RMSE),a.postfault_correlation,b.postfault_correlation, ...
 a.B_peak,b.B_peak,a.peak_difference,b.peak_difference,a.recovery_B_s,b.recovery_B_s, ...
 'VariableNames',{'quantity','unit','RMSE_before','RMSE_after','RMSE_improvement_percent','increment_RMSE_before','increment_RMSE_after', ...
 'increment_improvement_percent','postfault_corr_before','postfault_corr_after','peak_before','peak_after','peak_error_before','peak_error_after','recovery_before_s','recovery_after_s'});
writetable(T,fullfile(root,'性能对照表.csv'));
vm=table(["故障前G电压";"故障期最低G电压";"故障跌落幅度";"全程G电压峰值"], ...
 [c.A(1,3);c.faultVoltageMin(1);c.A(1,3)-c.faultVoltageMin(1);c.metrics.A_peak(3)], ...
 [base.B(1,3);base.faultVoltageMin(2);base.B(1,3)-base.faultVoltageMin(2);base.metrics.B_peak(3)], ...
 [c.B(1,3);c.faultVoltageMin(2);c.B(1,3)-c.faultVoltageMin(2);c.metrics.B_peak(3)], ...
 'VariableNames',{'quantity','ModelA_pu','ModelB_before_pu','ModelB_after_pu'});
writetable(vm,fullfile(root,'结果数据','故障电压指标.csv'));
labels=["Io峰值";"Io超限累计时间";"Io超限平方积分";"电压PI误差RMS";"电流PI误差RMS";"电压PI误差峰值";"电流PI误差峰值"];
u=["pu";"s";"pu^2*s";"pu";"pu";"pu";"pu"];old=[base.current base.inner]';now=[c.current c.inner]';
writetable(table(labels,u,old,now,100*(1-now./old),'VariableNames',{'quantity','unit','before','after','improvement_percent'}),fullfile(root,'结果数据','内环与超限指标.csv'));
end
function drawBeforeAfter(base,c,p,folder)
f=figure('Color','w','Position',[60 40 1350 1050]);tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
for k=[1 3 6 5 2 7]
 nexttile;plot(c.time,c.A(:,k),'LineWidth',1.2);hold on;plot(base.time,base.B(:,k),'--','LineWidth',1.1);plot(c.time,c.B(:,k),'LineWidth',1.2);grid on;
 title(c.names{k});xlabel('时间 (s)');ylabel(c.units{k});legend('ModelA','ModelB优化前','ModelB优化后','Location','best','AutoUpdate','off');xline(p.tFault,':');xline(p.tClear,':');
end
savePlot(f,folder,'优化前后主要响应');
end
function drawResults(c,b,p,folder)
set(groot,'defaultAxesFontName','Microsoft YaHei','defaultTextFontName','Microsoft YaHei');
groups={[1 2 3 7 8 9],[4 5 6 10]};stems={'外环与虚拟电抗','原PCC测点'};
for inc=0:1
 if inc,aa=c.incrementA;bb=c.incrementB;prefix='增量';else,aa=c.A;bb=c.B;prefix='绝对值';end
 for g=1:2
  f=figure('Color','w','Position',[70 50 1350 930]);tiledlayout(ceil(numel(groups{g})/2),2,'TileSpacing','compact','Padding','compact');
  for k=groups{g}
   nexttile;plot(c.time,aa(:,k),c.time,bb(:,k),'LineWidth',1.15);grid on;
   xline(p.tFault,':');xline(p.tClear,':');title(c.names{k});xlabel('时间 (s)');ylabel(c.units{k});legend('ModelA','ModelB','Location','best');
  end
  if inc,sgtitle('各自故障前运行点为基准的增量响应');else,sgtitle('0.10–0.18 s故障：原始绝对值');end
  savePlot(f,folder,[prefix '_' stems{g}]);
 end
end
d=b.data;t=b.time;
f=figure('Color','w','Position',[60 50 1350 930]);tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
sets={[30 11],[31 12],[32 9],[33 10],[36 37],[38 39]};
ttl={'电容d轴电压跟踪','电容q轴电压跟踪','桥侧d轴电流跟踪','桥侧q轴电流跟踪','电压PI误差','电流PI误差'};
for k=1:6
 nexttile;plot(t,d(:,sets{k}),'LineWidth',1.1);grid on;title(ttl{k});xlabel('时间 (s)');ylabel('pu');
 if k<=4,legend('参考','反馈','Location','best');else,legend('d轴','q轴','Location','best');end
end
savePlot(f,folder,'双PI跟踪');
f=figure('Color','w','Position',[60 50 1350 930]);tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
sets={[9 10],[13 14],[11 12],[34 35],[5 6],[7 8]};ttl={'桥侧电流if','网侧电流io','电容电压vc','理想平均桥压vm','电压PI积分状态','电流PI积分状态'};
for k=1:6,nexttile;plot(t,d(:,sets{k}),'LineWidth',1.05);grid on;title(ttl{k});xlabel('时间 (s)');if k>=5,ylabel('pu·s');else,ylabel('pu');end;legend('d轴','q轴','Location','best');end
savePlot(f,folder,'LCL与内环状态');
f=figure('Color','w','Position',[60 50 1350 930]);tiledlayout(3,2,'TileSpacing','compact');
sets={[30 11],[32 9],[9 13],[36 38],29,4};ttl={'电容d轴电压','桥侧d轴电流','桥侧与网侧d轴电流','d轴PI误差','网侧电流幅值','虚拟电抗'};
for k=1:6,nexttile;plot(t,d(:,sets{k}),'LineWidth',1);grid on;xlim([.095 .25]);title(ttl{k});xlabel('时间 (s)');ylabel('pu');end
savePlot(f,folder,'故障切换快速动态');
w0=2*pi*p.freq;W=(p.xLf*sum(d(:,9:10).^2,2)+p.bCf*sum(d(:,11:12).^2,2)+p.xLc*sum(d(:,13:14).^2,2))/(2*w0);
f=figure('Color','w','Position',[60 50 1200 800]);tiledlayout(2,2,'TileSpacing','compact');
nexttile;plot(t,W,'LineWidth',1.1);grid on;ylabel('储能 (pu·s)');xlabel('时间 (s)');
nexttile;plot(t,d(:,23),'LineWidth',1.1);grid on;ylabel('恒功率支路判别式');xlabel('时间 (s)');
nexttile;stairs(t,d(:,24),'LineWidth',1.1);grid on;ylabel('负荷分支：1=恒阻抗');ylim([-.1 1.1]);xlabel('时间 (s)');
nexttile;plot(t,d(:,25),'LineWidth',1.1);grid on;ylabel('代数约束残差 (pu)');xlabel('时间 (s)');
savePlot(f,folder,'储能与网络约束');
end
function savePlot(f,folder,stem)
exportgraphics(f,fullfile(folder,[stem '.png']),'Resolution',600);savefig(f,fullfile(folder,[stem '.fig']));close(f);
end

