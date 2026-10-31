function r = Model_A_process_results(out,p,ic)
r.parameters=p;r.initial=ic;r.matlabVersion=version;
r.errorMessage=out.ErrorMessage;
r.status='completed';r.time=[];r.data=[];
if ~isempty(r.errorMessage)
    if contains(r.errorMessage,'Model_A_DAE_'),r.status='algebraic_failure';
    else,r.status='simulation_error';end
end
if any(strcmp(out.who,'ModelA_log'))
    ts=out.get('ModelA_log');r.time=ts.Time;r.data=squeeze(ts.Data);
    if size(r.data,1)~=numel(r.time),r.data=r.data.';end
end
r.columns={'delta_rad','omega_pu_deviation','E_pu','xv_pu', ...
 'VG_real','VG_imag','VG_abs','Pe_pu','Qe_internal_pu','I_abs_pu', ...
 'Q_bus_pu','CP_discriminant','load_is_Z','algebraic_residual', ...
 'jacobian_sigma_min','reserved','fault_active'};
r.maxResidual=NaN;r.xvExceeded=false;r.endDistance=NaN;
if ~isempty(r.time)
    r.maxResidual=max(r.data(:,14));
    r.xvExceeded=max(r.data(:,4))>p.xvmax+1e-6;
    r.endDistance=norm(r.data(end,1:4)'-ic.x0,inf);
    if isempty(r.errorMessage) && r.time(end)<p.tStop-1e-7,r.status='stopped_early';end
    if r.maxResidual>p.residualTol,r.status='residual_check_failed';end
end
if p.saveResults
    if ~isfolder(p.outputDir),mkdir(p.outputDir);end
    stem=['ModelA_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')) ...
        '_tc_' strrep(sprintf('%.6f',p.tClear),'.','p')];
    r.resultFolder=fullfile(p.outputDir,stem);mkdir(r.resultFolder);
    save(fullfile(r.resultFolder,'result.mat'),'r');
    if ~isempty(r.time)
        T=array2table([r.time,r.data],'VariableNames',[{'time_s'},r.columns]);
        writetable(T,fullfile(r.resultFolder,'trajectory.csv'));
    end
else,r.resultFolder='';end
if ~isempty(r.time)
    vis='off';if p.showFigures,vis='on';end
    f=figure('Name','Model A results','Color','w','Visible',vis, ...
        'Position',[80 80 1150 900]);
    tiledlayout(f,4,2,'TileSpacing','compact','Padding','compact');
    cols=[7,1,3,10,4,8,9,15];
    labels={'Load bus voltage |V_G| (pu)','GFM angle delta (deg)', ...
      'Internal voltage E (pu)','GFM output current |I| (pu)', ...
      'Adaptive virtual reactance x_v (pu)','GFM active power P_e (pu)', ...
      'GFM reactive power Q_e internal (pu)','Algebraic Jacobian minimum singular value'};
    for k=1:8
        ax=nexttile;yy=r.data(:,cols(k));if k==2,yy=yy*180/pi;end
        plot(ax,r.time,yy,'LineWidth',1.4);grid(ax,'on');hold(ax,'on');
        if p.faultEnabled
            xline(ax,p.tFault,'--r','Fault','LabelVerticalAlignment','bottom');
            xline(ax,p.tClear,'--b','Clear','LabelVerticalAlignment','bottom');
        end
        title(ax,labels{k});xlabel(ax,'Time (s)');
    end
    sgtitle(f,sprintf('Model A | t_{clear}=%.4f s | %s',p.tClear,r.status),'Interpreter','tex');
    if p.saveResults
        exportgraphics(f,fullfile(r.resultFolder,'curves.png'),'Resolution',160);
        savefig(f,fullfile(r.resultFolder,'curves.fig'));
    end
    if ~p.showFigures,close(f);end
end
if p.saveResults
    fid=fopen(fullfile(r.resultFolder,'run_summary.txt'),'w','n','UTF-8');
    fprintf(fid,'MATLAB: %s\nStatus: %s\nInitial residual: %.4g\nMaximum g residual: %.4g\n', ...
      r.matlabVersion,r.status,ic.residual,r.maxResidual);
    fprintf(fid,'xv exceeded analysis bound: %d\nEnd state distance: %.6g\nError: %s\n', ...
      r.xvExceeded,r.endDistance,r.errorMessage);fclose(fid);
    save(fullfile(r.resultFolder,'result.mat'),'r');
end
fprintf('Model A: %s, maximum algebraic residual %.3g\n',r.status,r.maxResidual);
if r.xvExceeded
    warning('Model_A:AnalysisBound','xv exceeds xvmax analysis bound; the paper equation was not clipped.');
end
if ~isempty(r.errorMessage),fprintf('%s\n',r.errorMessage);end
end
