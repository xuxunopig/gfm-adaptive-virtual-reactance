function c=PI_performance(a,b)
% 统一测点下的绝对值、各自稳态增量及内环误差指标。
t=(0:2e-4:3)';[ta,ia]=unique(a.time,'last');[tb,ib]=unique(b.time,'last');
aa=interp1(ta,a.data(ia,:),t,'linear');bb=interp1(tb,b.data(ib,:),t,'linear');
c.time=t;c.A=signalsA(aa,a.parameters);c.B=signalsB(bb);
c.incrementA=c.A-c.A(1,:);c.incrementB=c.B-c.B(1,:);
c.names={'功角','内电压E','G母线电压','PCC电压','PCC输出电流','PCC有功','虚拟电抗','内源有功Pe','内源无功Qe','PCC无功'};
c.units={'deg','pu','pu','pu','pu','pu','pu','pu','pu','pu'};
err=c.B-c.A;inc=c.incrementB-c.incrementA;post=t>=.18;tail=t>=2.8;
rawA=signalsA(a.data,a.parameters);rawB=signalsB(b.data);
cor=zeros(10,1);ra=cor;rb=cor;
for k=1:10
 C=corrcoef(c.A(post,k),c.B(post,k));cor(k)=C(1,2);
 ra(k)=recovery(t,c.A(:,k),c.A(1,k));rb(k)=recovery(t,c.B(:,k),c.B(1,k));
end
c.metrics=table(string(c.names'),string(c.units'),sqrt(mean(err.^2))',sqrt(mean(inc.^2))',sqrt(mean(err(post,:).^2))', ...
 cor,max(abs(err))',max(rawA)',max(rawB)',(max(rawB)-max(rawA))', ...
 (max(rawB)-rawB(1,:)-max(rawA)+rawA(1,:))',mean(err(tail,:))',ra,rb, ...
 'VariableNames',{'quantity','unit','absolute_RMSE','increment_RMSE','postfault_RMSE','postfault_correlation','max_abs_deviation', ...
 'A_peak','B_peak','peak_difference','increment_peak_difference','tail_mean_difference','recovery_A_s','recovery_B_s'});
d=b.data;tt=b.time;ev2=sum(d(:,36:37).^2,2);ei2=sum(d(:,38:39).^2,2);
c.inner=[sqrt(trapz(tt,ev2)/tt(end)),sqrt(trapz(tt,ei2)/tt(end)),sqrt(max(ev2)),sqrt(max(ei2))];
y=d(:,29);dt=diff(tt);y1=y(1:end-1);y2=y(2:end);limit=b.parameters.Imax;
fraction=double(y1>limit & y2>limit);up=y1<=limit & y2>limit;down=y1>limit & y2<=limit;
fraction(up)=(y2(up)-limit)./(y2(up)-y1(up));fraction(down)=(y1(down)-limit)./(y1(down)-y2(down));
c.current=[max(y),sum(dt.*fraction),trapz(tt,max(y-limit,0).^2)];
faultA=t>=.1 & t<.18;faultB=faultA;c.faultVoltageMin=[min(c.A(faultA,3)),min(c.B(faultB,3))];
end
function y=signalsA(d,p)
V=complex(d(:,5),d(:,6));Ei=d(:,3).*exp(1i*d(:,1));I=(Ei-V)./(1i*(p.xe+p.xL1+d(:,4)));VT=V+1i*p.xL1*I;S=VT.*conj(I);
y=[d(:,1)*180/pi,d(:,3),d(:,7),abs(VT),abs(I),real(S),d(:,4),d(:,8),d(:,9),imag(S)];
end
function y=signalsB(d)
y=[d(:,1)*180/pi,d(:,3),d(:,17),d(:,20),d(:,29),d(:,27),d(:,4),d(:,3).*d(:,13),-d(:,3).*d(:,14),d(:,28)];
end
function d=recovery(t,y,y0)
band=max(.02*abs(y0),.01);bad=find(t>=.18 & abs(y-y0)>band,1,'last');
if isempty(bad),d=0;elseif bad==numel(t),d=NaN;else,d=t(bad+1)-.18;end
end
