function result=optimize_Model_B_PI(a,b0,folder,maxEvaluations)
% 四个PI增益的局部单纯形优化；其余参数固定为b0.parameters。
if nargin<4,maxEvaluations=160;end
if ~isfolder(folder),mkdir(folder);end
p0=b0.parameters;names={'Kpv','Kiv','Kpc','Kic'};g0=cellfun(@(n)p0.(n),names);base=PI_performance(a,b0);
records={};cache=containers.Map('KeyType','char','ValueType','double');bestScore=1;bestGains=g0;bestRun=b0;bestMetrics=base;
objective(ones(1,4));
% 正负坐标灵敏度确定局部下降方向。
for axisIndex=1:4,for sg=[-1 1],u=ones(1,4);u(axisIndex)=u(axisIndex)+sg*.12/log(2);objective(u);end,end
start=1+log(bestGains./g0)/log(2);
options=optimset('Display','off','MaxFunEvals',maxEvaluations,'MaxIter',120,'TolX',.004,'TolFun',2e-4);
[u,fval,exitflag,output]=fminsearch(@objective,start,options); %#ok<ASGLU>
result.parameters=p0;for j=1:4,result.parameters.(names{j})=bestGains(j);end
result.gains=bestGains;result.score=bestScore;result.base=base;result.best=bestMetrics;result.run=bestRun;result.records=records;result.searchOutput=output;result.exitflag=exitflag;Model_B_configure(result.parameters);
save(fullfile(folder,'optimization_complete.mat'),'result','-v7');
fprintf('OPTIMIZATION_END best %.9g gains %.12g %.12g %.12g %.12g\n',bestScore,bestGains);
    function val=objective(u)
        if any(u<0 | u>2),val=10+sum(max(-u,0).^2+max(u-2,0).^2);return;end
        gains=g0.*exp(log(2)*(u-1));key=sprintf('%.15g,',gains);
        if isKey(cache,key),val=cache(key);return;end
        p=p0;for j=1:4,p.(names{j})=gains(j);end
        id=numel(records)+1;rec=struct('id',id,'gains',gains,'status','failed','endTime',0,'score',100,'guard',inf,'metrics',[],'current',[],'inner',[],'error','');
        try
          if max(abs(gains-g0)./(1+g0))<1e-13,r=b0;else,r=run_Model_B(p,false);end
          rec.status=r.status;rec.error=r.errorMessage;
          if ~isempty(r.time),rec.endTime=r.time(end);end
          if strcmp(r.status,'completed') && rec.endTime>=3 && all(isfinite(r.data),'all') && r.maxResidual<1e-8
             other=rmfield(r.parameters,names);fixed=rmfield(p0,names);assert(isequaln(other,fixed),'PI以外的参数发生变化。');
             c=PI_performance(a,r);[val,guard,parts]=PI_objective(c,base);rec.score=val;rec.guard=guard;rec.metrics=c.metrics;rec.current=c.current;rec.inner=c.inner;rec.parts=parts;
             if guard<=1 && val<bestScore
                bestScore=val;bestGains=gains;bestRun=r;bestMetrics=c;
                save(fullfile(folder,'best_candidate.mat'),'r','c','gains','val','guard','-v7');
             end
             fprintf('PI_CANDIDATE %d J=%.6f guard=%.5f dRMSE=%.6f PRMSE=%.6f Pcorr=%.5f Ipeak=%.6f over=%.6f g=[%.8g %.8g %.8g %.8g]\n',id,val,guard,c.metrics.absolute_RMSE(1),c.metrics.absolute_RMSE(6),c.metrics.postfault_correlation(6),c.current(1:2),gains);
          else,val=100+3-rec.endTime;rec.score=val;fprintf('PI_CANDIDATE %d FAILED end=%.9g\n',id,rec.endTime);end
        catch e,val=104;rec.error=getReport(e,'basic');rec.score=val;fprintf('PI_CANDIDATE %d ERROR %s\n',id,e.message);end
        records{id}=rec;cache(key)=val;
        save(fullfile(folder,'search_history.mat'),'records','base','g0','p0','bestGains','bestScore','-v7');
        PI_history_table(records,folder);
    end
end
