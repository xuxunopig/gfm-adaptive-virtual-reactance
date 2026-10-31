function [J,g,parts,violation]=PI_objective(c,base)
% 以优化前性能归一化，PCC有功权重最高；越界退化另加惩罚。
m=c.metrics;z=base.metrics;wave=.6*m.absolute_RMSE./z.absolute_RMSE+.4*m.increment_RMSE./z.increment_RMSE;
corrLoss=(1-m.postfault_correlation)./(1-z.postfault_correlation);
pk=abs(m.peak_difference)./max(abs(z.peak_difference),1e-5);
partD=.60*wave(1)+.15*pk(1)+.25*corrLoss(1);
partV=.65*wave(3)+.15*pk(3)+.20*corrLoss(3);
partP=.50*wave(6)+.20*m.postfault_RMSE(6)/z.postfault_RMSE(6)+.30*corrLoss(6);
partI=.55*wave(5)+.25*c.current(1)/base.current(1)+.20*c.current(2)/base.current(2);
partInner=mean(c.inner(1:2)./base.inner(1:2));parts=[partD partV partP partI partInner];
J=parts*[.20;.15;.35;.20;.10];
rat=[m.absolute_RMSE([1 3 5 6])./z.absolute_RMSE([1 3 5 6]);m.increment_RMSE([1 3 5 6])./z.increment_RMSE([1 3 5 6]); ...
 m.absolute_RMSE([2 7])./z.absolute_RMSE([2 7]);c.current(1:2)'./base.current(1:2)';c.inner(1:2)'./base.inner(1:2)'];
lim=[1.05;1.05;1.05;1.01;1.05;1.05;1.05;1.01;1.10;1.10;1.01;1.05;1.10;1.10];
violation=rat-lim;g=max(rat./lim);J=J+20*sum(max(rat-lim,0).^2);
end
