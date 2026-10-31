function Model_A_on_stop(mdl)
% Post-run plots for the Simulink toolbar Run button.
% Logging reaches the workspace after StopFcn; defer via a short single timer.
if nargin<1,mdl='Model_A';end
snapshot=get_param([mdl '/Parameters'],'UserData');
t=timer('ExecutionMode','singleShot','StartDelay',0.2, ...
 'TimerFcn',@finish,'StopFcn',@(obj,~)delete(obj));start(t);
    function finish(~,~)
        try
            if evalin('base','exist(''out'',''var'')')
                out=evalin('base','out');
                if isa(out,'Simulink.SimulationOutput') && any(strcmp(out.who,'ModelA_log'))
                    r=Model_A_process_results(out,snapshot.p,snapshot.ic);
                    assignin('base','ModelA_result',r);return
                end
            end
            if evalin('base','exist(''ModelA_log'',''var'')')
                ts=evalin('base','ModelA_log');
                out=Simulink.SimulationOutput;out=out.set('ModelA_log',ts);
                r=Model_A_process_results(out,snapshot.p,snapshot.ic);
                assignin('base','ModelA_result',r);
            end
        catch err
            warning('Model_A:Plotting','Automatic plotting: %s',err.message);
        end
    end
end
