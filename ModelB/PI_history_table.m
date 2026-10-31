function PI_history_table(records,folder)
n=numel(records);values=nan(n,27);status=strings(n,1);
for k=1:n
 r=records{k};values(k,1:8)=[r.id,r.gains,r.endTime,r.score,r.guard];status(k)=string(r.status);
 if ~isempty(r.metrics)
  m=r.metrics;values(k,9:27)=[m.absolute_RMSE([1 3 6 5])',m.increment_RMSE([1 3 6 5])',m.postfault_correlation([1 3 6 5])',r.current,r.inner];
 end
end
T=array2table(values,'VariableNames',{'id','Kpv','Kiv','Kpc','Kic','end_s','objective','guard_ratio', ...
 'delta_RMSE_deg','VG_RMSE_pu','PCCP_RMSE_pu','Io_RMSE_pu','delta_inc_RMSE_deg','VG_inc_RMSE_pu','PCCP_inc_RMSE_pu','Io_inc_RMSE_pu', ...
 'delta_post_corr','VG_post_corr','PCCP_post_corr','Io_post_corr','Io_peak_pu','Io_overlimit_s','Io_excess_squared_integral','ev_RMS','ei_RMS','ev_peak','ei_peak'});
T.status=status;writetable(T,fullfile(folder,'PI_search_history.csv'));
end
