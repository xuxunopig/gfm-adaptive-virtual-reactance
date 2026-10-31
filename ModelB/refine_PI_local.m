function result=refine_PI_local(a,b0,folder)
% 在局部信赖范围内采用SQP，进一步约束电流峰值及超限时间不增加。
load(fullfile(folder,'search_history.mat'),'records');p0=b0.parameters;names={'Kpv','Kiv','Kpc','Kic'};
g0=cellfun(@(n)p0.(n),names);base=PI_performance(a,b0);cache=containers.Map('KeyType','char','ValueType','double');
bestScore=1;bestGains=g0;bestRun=b0;bestMetrics=base;
for k=1:numel(records)
 rec=records{k};cache(sprintf('%.15g,',rec.gains))=k;
 if ~isempty(rec.metrics)
  c.metrics=rec.metrics;c.inner=rec.inner;c.current=rec.current;[J,gg]=PI_objective(c,base);
  if gg<=1 && all(c.current(1:2)<=base.current(1:2)*(1+1e-5)) && all(c.inner(3:4)<=1.1*base.inner(3:4)) && J<bestScore
   bestScore=J;bestGains=rec.gains;
  end
 end
end
p=p0;for k=1:4,p.(names{k})=bestGains(k);end;bestRun=run_Model_B(p,false);bestMetrics=PI_performance(a,bestRun);
start=1+log(bestGains./g0)/log(2);
options=optimoptions('fmincon','Algorithm','sqp','Display','off','MaxFunctionEvaluations',70,'MaxIterations',10, ...
 'FiniteDifferenceStepSize',[.002 .01 .002 .002],'FiniteDifferenceType','forward','StepTolerance',.001,'OptimalityTolerance',.002,'ConstraintTolerance',1e-4);
[u,J,exitflag,output]=fmincon(@objective,start,[],[],[],[],zeros(1,4),2*ones(1,4),@constraints,options); %#ok<ASGLU>
result.parameters=p0;for k=1:4,result.parameters.(names{k})=bestGains(k);end
result.gains=bestGains;result.score=bestScore;result.base=base;result.best=bestMetrics;result.run=bestRun;result.records=records;result.searchOutput=output;result.exitflag=exitflag;Model_B_configure(result.parameters);
save(fullfile(folder,'refinement_complete.mat'),'result','-v7');fprintf('SQP_END score=%.9g gains=[%.12g %.12g %.12g %.12g]\n',bestScore,bestGains);
    function J=objective(u)
      id=evaluate(u);J=records{id}.score;
    end
    function [v,eq]=constraints(u)
      id=evaluate(u);rec=records{id};eq=[];
      if isempty(rec.metrics),v=100*ones(18,1);return;end
      c.metrics=rec.metrics;c.current=rec.current;c.inner=rec.inner;[~,~,~,violation]=PI_objective(c,base);
      v=[violation;c.current(1:2)'./base.current(1:2)'-1;c.inner(3:4)'./base.inner(3:4)'-1.1];
    end
    function id=evaluate(u)
      gains=g0.*exp(log(2)*(u-1));key=sprintf('%.15g,',gains);if isKey(cache,key),id=cache(key);return;end
      p=p0;for gainIndex=1:4,p.(names{gainIndex})=gains(gainIndex);end
      id=numel(records)+1;rec=struct('id',id,'gains',gains,'status','failed','endTime',0,'score',104,'guard',inf,'metrics',[],'current',[],'inner',[],'error','');
      try
       r=run_Model_B(p,false);rec.status=r.status;rec.error=r.errorMessage;if ~isempty(r.time),rec.endTime=r.time(end);end
       if strcmp(r.status,'completed') && rec.endTime>=3 && all(isfinite(r.data),'all') && r.maxResidual<1e-8
        assert(isequaln(rmfield(r.parameters,names),rmfield(p0,names)),'PI以外参数改变。');
        c=PI_performance(a,r);[J,g,parts]=PI_objective(c,base);rec.score=J;rec.guard=g;rec.metrics=c.metrics;rec.current=c.current;rec.inner=c.inner;rec.parts=parts;
        if g<=1+1e-5 && all(c.current(1:2)<=base.current(1:2)*(1+1e-5)) && all(c.inner(3:4)<=1.1*base.inner(3:4)) && J<bestScore
         bestScore=J;bestGains=gains;bestRun=r;bestMetrics=c;save(fullfile(folder,'best_feasible.mat'),'r','c','gains','J','g','-v7');
        end
        fprintf('SQP_CANDIDATE %d J=%.6f guard=%.6f PRMSE=%.6f Pcorr=%.5f Ipeak=%.6f over=%.6f g=[%.8g %.8g %.8g %.8g]\n',id,J,g,c.metrics.absolute_RMSE(6),c.metrics.postfault_correlation(6),c.current(1:2),gains);
       end
      catch e,rec.error=getReport(e,'basic');end
      records{id}=rec;cache(key)=id;save(fullfile(folder,'search_history.mat'),'records','base','g0','p0','bestGains','bestScore','-v7');PI_history_table(records,folder);
    end
end

