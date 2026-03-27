%% get spont firing data from ON recordings - getSpontFiringData

allTimeStampsBySweep = [];

% iterate through sweeps
for sweep=1:nSweeps
    % find peaks
    [pks,locs,w,p] = findpeaks(yFiltered_All(:,params.mainDataCh,sweep),xAxis,'MinPeakHeight',params.minPeakHeight,'MinPeakDistance',params.minPeakDistance);
    sweepNumberArray = sweep.* ones(length(locs),1);               
    % collect sweep-by-sweep data
    tsBySweep{1,sweep} = locs;
    sweepNumberArrayBySweep{1,sweep} = sweepNumberArray;
    firingRateMeanBySweep(sweep,1) = size(locs,1) / sweepDurationInSeconds;  % in Hz
    allTimeStampsBySweep = [allTimeStampsBySweep; locs];
    
    % save first and last sweep (for quality control later)
    if sweep == 1
        yFilteredFirstSweep = yFiltered_All(:,params.mainDataCh,sweep);
        pksFirst = pks;
        locsFirst = locs;
    elseif sweep == nSweeps
        yFilteredLastSweep = yFiltered_All(:,params.mainDataCh,sweep);
        pksLast = pks;
        locsLast = locs;
    end

    % save example sweep (for plotting later)
    if sweep == params.example_sweep
        yFilteredExampleSweep = yFiltered_All(:,params.mainDataCh,sweep);
        pksExample = pks;
        locsExample = locs;
    end
end   

% calculate mean and std of firing rate
firingRateMean = mean(firingRateMeanBySweep);
firingRateStd = std(firingRateMeanBySweep);

if plotFigs == 1
    if plot_QC == 1
        % quality control of filter
        figure('name',strcat(prefix,'_filter_qc'))
            subplot(2,1,1)
                plot(xAxis,yFilteredFirstSweep,'b')
                hold on;
                plot(xAxis,d(:,params.mainDataCh,1),'r')
                hold off;
                axis([params.xMinInSec params.xMaxInSec -inf inf])
                ylabel(strcat(cell2mat(h.recChNames(params.mainDataCh)), " (", (cell2mat(h.recChUnits(params.mainDataCh))), ")"));
                xlabel('Time (s)');
                title(prefix,'Interpreter','none');
            subplot(2,1,2)
                plot(xAxis,yFilteredLastSweep,'b')
                hold on;
                plot(xAxis,d(:,params.mainDataCh,nSweeps),'r')
                hold off;
                axis([params.xMinInSec params.xMaxInSec -inf inf])
                ylabel(strcat(cell2mat(h.recChNames(params.mainDataCh)), " (", (cell2mat(h.recChUnits(params.mainDataCh))), ")"));
                xlabel('Time (s)');
        
        % quality control of found APs
        figure('name', strcat(prefix, '_AP_qc'))
            subplot(2,1,1)
                plot(xAxis,yFilteredFirstSweep)
                hold on;
                plot(locsFirst,pksFirst,'o')
                yline(params.minPeakHeight)
                hold off;
                axis([params.xMinInSec params.xMaxInSec params.yMin params.yMax])
                ylabel(strcat(cell2mat(h.recChNames(params.mainDataCh)), " (", (cell2mat(h.recChUnits(params.mainDataCh))), ")"));
                xlabel('Time (s)');
                title(prefix,'Interpreter','none');
            subplot(2,1,2)
                plot(xAxis,yFilteredLastSweep)
                hold on;
                plot(locsLast,pksLast,'o')
                yline(params.minPeakHeight)
                hold off;
                axis([params.xMinInSec params.xMaxInSec params.yMin params.yMax])
                ylabel(strcat(cell2mat(h.recChNames(params.mainDataCh)), " (", (cell2mat(h.recChUnits(params.mainDataCh))), ")"));
                xlabel('Time (s)');
        end
        
        % niceplot
        if params.plot_cmd == 1                    
            figure('name', strcat(prefix, '_firing_raster'));        
            subplot(3,1,1)
                % plot example traces
                plot(xAxis,yFilteredExampleSweep,'k','LineWidth',0.5)
                axis([params.xMinInSec params.xMaxInSec params.yMin params.yMax])
                set(gca,'Visible','off');
                % scale bars
                line([params.xMaxInSec-2*params.time_scaleBarSize params.xMaxInSec],[params.yMin params.yMin],'Color','k')
                line([params.xMaxInSec params.xMaxInSec],[params.yMin params.yMin + params.data_y_scaleBarSize],'Color','k')
                text(params.xMaxInSec-2*params.time_scaleBarSize, params.yMin + params.data_y_scaleBarSize/2, strcat(num2str(params.time_scaleBarSize), " s"))                       
                text(params.xMaxInSec-2*params.time_scaleBarSize, params.yMin + params.data_y_scaleBarSize, strcat(num2str(params.data_y_scaleBarSize), " ", cell2mat(h.recChUnits(params.mainDataCh))))  
                if rec_type == "WC_CC_spont" 
                    % -60 mV line
                    yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                    yline(0,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                    text(params.xMinInSec, params.yMin + 10, "lines @ 0 mV & -60 mV") 
                end
                title(prefix,'Interpreter','none');
                set(findall(gca, 'type', 'text'), 'visible', 'on'); % Makes the title visible again
            subplot(3,1,2)
                % plot cmd traces for example
                plot(xAxis,smooth(d(:,params.cmdCh,params.example_sweep),params.smoothSpan),'k','LineWidth',0.5)
                axis([params.xMinInSec params.xMaxInSec params.yMin_cmd params.yMax_cmd])
                set(gca,'Visible','off');
                % scale bars
                line([params.xMaxInSec-2*params.time_scaleBarSize params.xMaxInSec],[params.yMin_cmd params.yMin_cmd],'Color','k')
                line([params.xMaxInSec params.xMaxInSec],[params.yMin_cmd params.yMin_cmd + params.cmd_y_scaleBarSize],'Color','k')
                text(params.xMaxInSec-2*params.time_scaleBarSize, params.yMin_cmd + params.cmd_y_scaleBarSize/2, strcat(num2str(params.time_scaleBarSize), " s"))
                text(params.xMaxInSec-2*params.time_scaleBarSize, params.yMin_cmd + params.cmd_y_scaleBarSize, strcat(num2str(params.cmd_y_scaleBarSize),  " ", cell2mat(h.recChUnits(params.cmdCh))))                
            subplot(3,1,3)
                % plot AP raster for all sweeps
                for sweep = 1:nSweeps
                    if ~isempty(cell2mat(tsBySweep(sweep)))
                        plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
                        hold on;
                    end
                end    
                % adding finishing touches to plot
                hold off;
                axis([params.xMinInSec params.xMaxInSec 0 nSweeps+1])
                ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                yticks([]);
                xticks([]);
                set(gca, 'YDir','reverse');
                xlabel('Time (s)');       

        else
            figure('name', strcat(prefix, '_firing_raster'));                    
            subplot(2,1,1)
                % plot example traces
                plot(xAxis,yFilteredExampleSweep,'k','LineWidth',0.5)
                axis([params.xMinInSec params.xMaxInSec params.yMin params.yMax])
                set(gca,'Visible','off');
                % scale bars
                line([params.xMaxInSec-params.time_scaleBarSize params.xMaxInSec],[params.yMin params.yMin],'Color','k')
                line([params.xMaxInSec params.xMaxInSec],[params.yMin params.yMin + params.data_y_scaleBarSize],'Color','k')
                text(params.xMaxInSec-2*params.time_scaleBarSize, params.yMin + params.data_y_scaleBarSize/2, strcat(num2str(params.time_scaleBarSize), " s"))
                text(params.xMaxInSec-2*params.time_scaleBarSize, params.yMin + params.data_y_scaleBarSize, strcat(num2str(params.data_y_scaleBarSize), " ", cell2mat(h.recChUnits(params.mainDataCh))))   
                if rec_type == "WC_CC_spont" 
                    % -60 mV line
                    yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                    yline(0,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                    text(params.xMinInSec, params.yMin + 10, "lines @ 0 mV & -60 mV") 
                end  
                title(prefix,'Interpreter','none');
                set(findall(gca, 'type', 'text'), 'visible', 'on'); % Makes the title visible again
            subplot(2,1,2)
                % plot AP raster for all sweeps
                for sweep = 1:nSweeps
                    if ~isempty(cell2mat(tsBySweep(sweep)))
                        plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
                        hold on;
                    end
                end    
                % adding finishing touches to plot
                hold off;
                axis([params.xMinInSec params.xMaxInSec 0 nSweeps+1])
                ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                yticks([]);
                xticks([]);
                set(gca, 'YDir','reverse');
                xlabel('Time (s)');
        end
       
        % organize data for histogram (counting APs accross all
        % sweeps)
        edges = params.xMinInSec:params.xMaxInSec;
        [N, edges] = histcounts(allTimeStampsBySweep,edges);
        firingHz = N/nSweeps;

        figure('name', strcat(prefix, '_firing_histogram'));
        % plot histogram and 2*SD criteria
        hold on;                    
        histogram('BinEdges', params.xMinInSec:params.xMaxInSec, 'BinCounts', firingHz, 'DisplayStyle', 'stairs', 'EdgeColor', 'k');                           
        % plot Hz mean as horizontal line
        yline(firingRateMeanBySweep(1,1), '--');
        % plot +- 2 SD as rectangle around mean - ALERT: need to check the math here
        % [x y width height]
        rectangle('Position', [0 firingRateMeanBySweep(1,1)-(2*firingRateStd) params.xMaxInSec 4*firingRateStd], 'FaceAlpha', 0.1, 'FaceColor', [0 0 0], 'EdgeColor', 'none');
        xlabel('Time (s)');
        ylabel('Firing rate (Hz)');
        axis([params.xMinInSec params.xMaxInSec 0 ymaxhist])
        yticks([0 ymaxhist]);
        hold off;
        title(prefix,'Interpreter','none');
end
