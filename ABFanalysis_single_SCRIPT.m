clear all
close all

%% USER INPUT

fileDir = 'M:\EphysData\20260318\2026_03_18_0005.abf';  % use single quotes
saveDir = 'C:\Users\ambrosi\OHSU Dropbox\Priscilla Ambrosi\Dropbox - Moss Lab\Lab - Data summaries\2026-03-19 ephys dreadds';
mainDataCh = 1;     % channel with recording from cell
smoothSpan = 5;
xMinInSec = 0;
xMaxInSec = 1.75;
testPulse = 1;     % 1 if this is a test pulse for looking at intrinsic properties and Rs; 0 if not

% for APs
minPeakHeight = -500;         % amplitude threshold
minPeakDistance = 0.001;    % in seconds
cellAttached = 0;
highpassThreshold = 100;
lowpassThreshold = 1500; 
yMin = -1500;
yMax = 1500;

% for optogenetics
optogenetics = 0;   % 1 if this is an optogenetics expt; 0 if not
lightCh = 4;        % channel with opto stim. 3 is B. 4 is GR

% for PSC
cmdCh = 2;

% niceplot
xMinInSecNiceplot_VC = 0;
xMaxInSecNiceplot_VC = 2.5;
xMinInSecNiceplot_CC = 1.45;
xMaxInSecNiceplot_CC = 1.55;
yMinNiceplot_main = -500;
yMaxNiceplot_main = 500;
yMinNiceplot_cmd = -70;
yMaxNiceplot_cmd = -55;
yMinNiceplot_light = -5;
yMaxNiceplot_light = 10;

saveFigs = 0;
plotAllCh = 1;


%% MAIN CODE

% load ABF file
[d,si,h]=abfload(fileDir);

% get file name
fileName = fileDir(end-18:end-4);

% convert sampling interval into sampling frequency
% si is the sampling interval in us
% samplingFrequency is in Hz
samplingFrequency = 1000000/si;

% d is organized like this:
% 1st column: data points (time series)
% 2nd column: channel
% 3rd column: sweep #

% convert data points into seconds
sweepDurationInSeconds = h.sweepLengthInPts/samplingFrequency;
xAxis = linspace(0,sweepDurationInSeconds,h.sweepLengthInPts)';

% collect some simple info from header
nSweeps = size(d,3);
nChannels = size(h.recChNames,1);

if optogenetics == 1
    % find light stim info
    % rationale: I trigger the LED with a 5V digital pulse that is also
    % recorded by one of my analog inputs. I am looking for a big change in the
    % derivative of this channel.
    % ASSUMPTIONs: light stim is the same in all sweeps
    lightPulseStartInDataPts = find(diff(d(:,lightCh,1))>1);
    lightPulseStartInSecs = lightPulseStartInDataPts/samplingFrequency;
    lightPulseEndInDataPts = find(diff(d(:,lightCh,1))<-1);
    lightPulseEndInSecs = lightPulseEndInDataPts/samplingFrequency;
    lightPulseDurInSecs = lightPulseEndInSecs - lightPulseStartInSecs;
end

% create matrix that will be filled
yFiltered_All=zeros(h.sweepLengthInPts,nSweeps);

if plotAllCh == 1
    % plot all the channels and sweeps
    figure('name',strcat(fileName,'_all'))
    for channel=1:nChannels
        subplot(nChannels,1,channel)
        for sweep=1:nSweeps
            yFiltered = smooth(d(:,channel,sweep),smoothSpan);
            yFiltered_All(:,sweep) = yFiltered;
            plot(xAxis,yFiltered,'Color',[0, 0, 0, 0.25]);
            hold on;
        end
        % calculate mean
        yMean = sum(yFiltered_All,2)/nSweeps;
        plot(xAxis,yMean,'Color',[0, 0, 0, 1]);
        hold off;
        ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"));
        axis([xMinInSec xMaxInSec -inf inf])
    end
    xlabel('Time (s)');
end

% % plot the 1st sweep of all the channels to compare filtered vs not
% % filtered data
% figure('name',strcat(fileName,'_filtered vs not'))
% for channel=1:nChannels
%     subplot(nChannels,1,channel)
%     plot(xAxis,d(:,channel,sweep),'Color','b');
%     hold on;
%     yFiltered = smooth(d(:,channel,sweep),smoothSpan);
%     plot(xAxis,yFiltered,'Color','r');
%     hold off;
%     ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"));
%     axis([xMinInSec xMaxInSec -inf inf])
% end
% xlabel('Time (s)');

% niceplot WC VC
if strcmp(cell2mat(h.recChUnits(mainDataCh)),'pA')
    figure('name',strcat(fileName,'_niceplot VC'))
    
        subplot(4,1,[1,2])
            for sweep=1:nSweeps
                yFiltered_main = smooth(d(:,mainDataCh,sweep),smoothSpan);
                yFiltered_main_All(:,sweep) = yFiltered_main;
                plot(xAxis,yFiltered_main,'Color',[0, 0, 0, 0.25]);
                hold on;
            end
            yMean_main = sum(yFiltered_main_All,2)/nSweeps;
            plot(xAxis,yMean_main,'Color',[0, 0, 0, 1]);
            hold off;
            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
            if size(yFiltered_main,1)/samplingFrequency >= xMaxInSecNiceplot_VC
                axis([xMinInSecNiceplot_VC xMaxInSecNiceplot_VC yMinNiceplot_main yMaxNiceplot_main])
            else
                axis([xMinInSecNiceplot_VC inf yMinNiceplot_main yMaxNiceplot_main])
            end
            title([fileName '_niceplot'],'Interpreter','none');
    
        subplot(4,1,3)
            for sweep=1:nSweeps
                yFiltered_cmd = smooth(d(:,cmdCh,sweep),smoothSpan);
                yFiltered_cmd_All(:,sweep) = yFiltered_cmd;
                plot(xAxis,yFiltered_cmd,'Color',[0, 0, 0, 0.25]);
                hold on;
            end
            yMean_cmd = sum(yFiltered_cmd_All,2)/nSweeps;
            plot(xAxis,yMean_cmd,'Color',[0, 0, 0, 1]);
            hold off;
            ylabel(strcat(cell2mat(h.recChNames(cmdCh)), " (", (cell2mat(h.recChUnits(cmdCh))), ")"));
            if size(yFiltered_main,1)/samplingFrequency >= xMaxInSecNiceplot_VC
                axis([xMinInSecNiceplot_VC xMaxInSecNiceplot_VC yMinNiceplot_cmd yMaxNiceplot_cmd])
            else
                axis([xMinInSecNiceplot_VC inf yMinNiceplot_cmd yMaxNiceplot_cmd])
            end

        if optogenetics == 1    
            subplot(4,1,4)
                for sweep=1:nSweeps
                    yFiltered_light = smooth(d(:,lightCh,sweep),smoothSpan);
                    yFiltered_light_All(:,sweep) = yFiltered_light;
                    plot(xAxis,yFiltered_light,'Color',[0, 0, 0, 0.25]);
                    hold on;
                end
                yMean_light = sum(yFiltered_light_All,2)/nSweeps;
                plot(xAxis,yMean_light,'Color',[0, 0, 0, 1]);
                hold off;
                ylabel(strcat(cell2mat(h.recChNames(lightCh)), " (", (cell2mat(h.recChUnits(lightCh))), ")"));
                axis([xMinInSecNiceplot_VC xMaxInSecNiceplot_VC yMinNiceplot_light yMaxNiceplot_light])
        end
    
        xlabel('Time (s)');
        set(gcf,'Position',[1000 50 350 400]);
end

% niceplot WC CC
if optogenetics == 1
    if strcmp(cell2mat(h.recChUnits(mainDataCh)),'mV')
        figure('name',strcat(fileName,'_niceplot CC'))
            
            subplot(4,1,[1,2])
                for sweep=1:nSweeps
                    yFiltered_main = smooth(d(:,mainDataCh,sweep),smoothSpan);
                    yFiltered_main_All(:,sweep) = yFiltered_main;
                    plot(xAxis,yFiltered_main,'Color',[0, 0, 0, 0.25]);
                    hold on;
                end
                yMean_main = sum(yFiltered_main_All,2)/nSweeps;
                plot(xAxis,yMean_main,'Color',[0, 0, 0, 1]);
                hold off;
                ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                axis([xMinInSecNiceplot_CC xMaxInSecNiceplot_CC -100 50])
                title([fileName '_niceplot'],'Interpreter','none');
        
            subplot(4,1,3)
                for sweep=1:nSweeps
                    yFiltered_cmd = smooth(d(:,cmdCh,sweep),smoothSpan);
                    yFiltered_cmd_All(:,sweep) = yFiltered_cmd;
                    plot(xAxis,yFiltered_cmd,'Color',[0, 0, 0, 0.25]);
                    hold on;
                end
                yMean_cmd = sum(yFiltered_cmd_All,2)/nSweeps;
                plot(xAxis,yMean_cmd,'Color',[0, 0, 0, 1]);
                hold off;
                ylabel(strcat(cell2mat(h.recChNames(cmdCh)), " (", (cell2mat(h.recChUnits(cmdCh))), ")"));
                axis([xMinInSecNiceplot_CC xMaxInSecNiceplot_CC -200 200])
        
            subplot(4,1,4)
                for sweep=1:nSweeps
                    yFiltered_light = smooth(d(:,lightCh,sweep),smoothSpan);
                    yFiltered_light_All(:,sweep) = yFiltered_light;
                    plot(xAxis,yFiltered_light,'Color',[0, 0, 0, 0.25]);
                    hold on;
                end
                yMean_light = sum(yFiltered_light_All,2)/nSweeps;
                plot(xAxis,yMean_light,'Color',[0, 0, 0, 1]);
                hold off;
                ylabel(strcat(cell2mat(h.recChNames(lightCh)), " (", (cell2mat(h.recChUnits(lightCh))), ")"));
                axis([xMinInSecNiceplot_CC xMaxInSecNiceplot_CC yMinNiceplot_light yMaxNiceplot_light])
        
            xlabel('Time (s)');
            set(gcf,'Position',[0 50 350 400]);
    end
end


if saveFigs == 1
    saveAllFigs(saveDir)
end



if testPulse == 1

    % get the first data point with a significant drop in cmd voltage
    rsTestPulseOnsetDataPoint = find(diff(yMean_cmd)<-0.5, 1);
    rsTestPulseOnsetTime = rsTestPulseOnsetDataPoint/samplingFrequency;

    % get the first data point with a significant rise in cmd voltage
    rsTestPulseOffsetDataPoint = find(diff(yMean_cmd)>0.5, 1);
    rsTestPulseOffsetTime = rsTestPulseOffsetDataPoint/samplingFrequency;

    midPulseTime = rsTestPulseOnsetTime + (rsTestPulseOffsetTime - rsTestPulseOnsetTime)/2;
    midPulseDataPoint = midPulseTime * samplingFrequency;

    % get analysis intervals
    rsBaselineDataPointInterval = ((rsTestPulseOnsetTime-0.05)*samplingFrequency):(rsTestPulseOnsetTime*samplingFrequency);
    rsFirstTransientDataPointInterval = (rsTestPulseOnsetTime*samplingFrequency):(rsTestPulseOnsetTime+0.0025)*samplingFrequency;
    rsPulseInterval = (rsTestPulseOnsetTime+0.0025)*samplingFrequency:(rsTestPulseOffsetTime-0.0025)*samplingFrequency;
            
    % calculating series resistance
    rsBaselineCurrent = mean(yFiltered_main(rsBaselineDataPointInterval));  
    rsTransientCurrent = min(yFiltered_main(rsFirstTransientDataPointInterval));
    rsSteadyStateCurrent = mean(yFiltered_main(rsPulseInterval));
    dCurrentTransient = rsTransientCurrent-rsBaselineCurrent;
    dCurrentSteadyState = rsSteadyStateCurrent-rsBaselineCurrent;
    dVoltage = mean(yMean_cmd(rsPulseInterval)) - mean(yMean_cmd(rsBaselineDataPointInterval));
    seriesResistance = 1000 * dVoltage / dCurrentTransient; % mV/pA equals Gohm
    cellResistance = 1000 * dVoltage / dCurrentSteadyState;

end



    
% 
% %% FIND APs (if applicable)
% 
% % if data was collected in current clamp, find action potentials and plot a raster 
% if strcmp(cell2mat(h.recChUnits(mainDataCh)),'mV')
% 
%     % create arrays that will be filled
%     tsBySweep = {};
%     sweepNumberArrayBySweep = {};
% 
%     % iterate through sweeps
%     for sweep=1:nSweeps
%         yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
%         [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
%         sweepNumberArray = sweep.* ones(length(locs),1);
% 
%         % collect sweep-by-sweep data
%         tsBySweep = [tsBySweep, locs];
%         sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
%     end   
% 
%     % quality control of found APs
%     figure('name', strcat(fileName, '_firing_qc'))
%     plot(xAxis,yFiltered)
%     hold on;
%     plot(locs,pks,'o')
%     yline(minPeakHeight)
%     hold off;
%     axis([xMinInSec xMaxInSec -100 40])
%     ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%     xlabel('Time (s)');
% 
%     % niceplot
%     figure('name', strcat(fileName, '_firing_raster'));
%     subplot(2,1,1)
%         % plot example trace
%         plot(xAxis,smooth(d(:,mainDataCh,1),smoothSpan),'k','LineWidth',0.5)
%         % line([lightPulseStartInSecs,lightPulseStartInSecs+lightPulseDurInSecs],[35,35],'Color',[0 0.4470 0.7410],'LineWidth',5)
%         if ~isempty(lightPulseStartInSecs)
%             rectangle('Position', [lightPulseStartInSecs -100 lightPulseDurInSecs 200], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
%         end
%         axis([xMinInSec xMaxInSec -100 40])
%         set(gca,'Visible','off');
%         % scale bars
%         line([xMaxInSec-0.05 xMaxInSec],[-100 -100],'Color','k')
%         line([xMaxInSec xMaxInSec],[-100 -90],'Color','k')
%         text(xMaxInSec-0.2, -90, "50 ms")
%         text(xMaxInSec-0.2, -80, "10 mV")
%         % -60 mV line
%         yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
%         text(xMinInSec, -90, "line @ -60 mV")        
% 
%     subplot(2,1,2)
%         % plot AP raster for all sweeps
%         for sweep = 1:nSweeps
%             plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
%             hold on;
%         end    
%         % adding light stim
%         if ~isempty(lightPulseStartInSecs)
%             rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');    
%         end
%         % adding finishing touches to plot
%         hold off;
%         axis([xMinInSec xMaxInSec 0 nSweeps+1])
%         ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
%         yticks([]);
%         xticks([]);
%         set(gca, 'YDir','reverse');
%         xlabel('Time (s)');
% 
% end
% 
% 
% %% Cell Attached Analysis
% 
% if cellAttached == 1
% 
%     % create arrays that will be filled
%     tsBySweep = {};
%     sweepNumberArrayBySweep = {};
% 
%     % iterate through sweeps
%     for sweep=1:nSweeps
%         yFiltered = bandpass(d(:,mainDataCh,sweep),[highpassThreshold lowpassThreshold],samplingFrequency);
%         [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',-minPeakHeight,'MinPeakDistance',minPeakDistance);
%         sweepNumberArray = sweep.* ones(length(locs),1);
% 
%         % save first and last sweep (to save time later)
%         if sweep == 1
%             yFilteredFirstSweep = yFiltered;
%             pksFirst = pks;
%             locsFirst = locs;
%         elseif sweep == nSweeps
%             yFilteredLastSweep = yFiltered;
%             pksLast = pks;
%             locsLast = locs;
%         end
% 
%         % collect sweep-by-sweep data
%         tsBySweep = [tsBySweep, locs];
%         sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
%     end   
% 
%     % quality control of bandpass filter
%     figure('name',strcat(fileName,'_bandpass vs not'))
%     subplot(2,1,1)
%         plot(xAxis,yFilteredFirstSweep,'b')
%         hold on;
%         plot(xAxis,d(:,mainDataCh,1),'r')
%         hold off;
%         axis([xMinInSec xMaxInSec -inf inf])
%         ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%         xlabel('Time (s)');
%     subplot(2,1,2)
%         plot(xAxis,yFilteredLastSweep,'b')
%         hold on;
%         plot(xAxis,d(:,mainDataCh,nSweeps),'r')
%         hold off;
%         axis([xMinInSec xMaxInSec -inf inf])
%         ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%         xlabel('Time (s)');
% 
%     % quality control of found APs
%     figure('name', strcat(fileName, '_cell_attached_qc'))
%     subplot(2,1,1)
%         plot(xAxis,yFilteredFirstSweep)
%         hold on;
%         plot(locsFirst,pksFirst,'o')
%         yline(-minPeakHeight)
%         hold off;
%         axis([xMinInSec xMaxInSec yMin yMax])
%         ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%         xlabel('Time (s)');
%     subplot(2,1,2)
%         plot(xAxis,yFilteredLastSweep)
%         hold on;
%         plot(locsLast,pksLast,'o')
%         yline(-minPeakHeight)
%         hold off;
%         axis([xMinInSec xMaxInSec yMin yMax])
%         ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%         xlabel('Time (s)');
% 
%     % niceplot
%     figure('name', strcat(fileName, '_cell_attached_raster'));
%     subplot(2,1,1)
%         % plot example trace
%         plot(xAxis,bandpass(d(:,mainDataCh,1),[highpassThreshold lowpassThreshold],samplingFrequency),'k','LineWidth',0.5)
%         % line([lightPulseStartInSecs,lightPulseStartInSecs+lightPulseDurInSecs],[35,35],'Color',[0 0.4470 0.7410],'LineWidth',5)
%         if ~isempty(lightPulseStartInSecs)
%             rectangle('Position', [lightPulseStartInSecs -100 lightPulseDurInSecs 200], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
%         end
%         axis([xMinInSec xMaxInSec yMin yMax])
%         set(gca,'Visible','off');
%         % scale bars
%         line([xMaxInSec-0.05 xMaxInSec],[-100 -100],'Color','k')
%         line([xMaxInSec xMaxInSec],[-100 -90],'Color','k')
%         text(xMaxInSec-0.2, -90, "50 ms")
%         text(xMaxInSec-0.2, -80, "10 mV")       
% 
%     subplot(2,1,2)
%         % plot AP raster for all sweeps
%         for sweep = 1:nSweeps
%             plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
%             hold on;
%         end    
%         % adding light stim
%         if ~isempty(lightPulseStartInSecs)
%             rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');    
%         end
%         % adding finishing touches to plot
%         hold off;
%         axis([xMinInSec xMaxInSec 0 nSweeps+1])
%         ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
%         yticks([]);
%         xticks([]);
%         set(gca, 'YDir','reverse');
%         xlabel('Time (s)');
% 
% end
% 
% 
% %% Find PSCs 
% 
% % if data was collected in voltage clamp, find oPSCs 
% if strcmp(cell2mat(h.recChUnits(mainDataCh)),'pA')
% 
%     for sweep=1:nSweeps
%         yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
%         [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
%         sweepNumberArray = sweep.* ones(length(locs),1);
% 
%         % collect sweep-by-sweep data
%         tsBySweep = [tsBySweep, locs];
%         sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
%     end  
% 
%     cmdCh
% 
% if autoRsOnsetTime == 1
%             [xV,yV] = obj.xy(sweepNumber, voltageCmdChannel);
%             rsTestPulseDataPoint = find(diff(yV)<-1);
%             rsTestPulseOnsetTime = rsTestPulseDataPoint/samplingFrequency;
%             rsBaselineDataPointInterval = ((rsTestPulseOnsetTime-0.05)*samplingFrequency):(rsTestPulseOnsetTime*samplingFrequency);
%             rsFirstTransientDataPointInterval = (rsTestPulseOnsetTime*samplingFrequency):(rsTestPulseOnsetTime+0.0025)*samplingFrequency;
% 
%             % trying to troubleshoot an error that I don't understand
%             rsBaselineDataPointInterval = round(rsBaselineDataPointInterval(1)):round(rsBaselineDataPointInterval(end));
%             rsFirstTransientDataPointInterval = round(rsFirstTransientDataPointInterval(1)):round(rsFirstTransientDataPointInterval(end));
%         end
%         %----------------------------------------------------------------------
% 
%         % calculating series resistance
%         rsBaselineCurrent = mean(y(rsBaselineDataPointInterval));  
%         rsTransientCurrent = min(y(rsFirstTransientDataPointInterval));
%         dCurrent = rsTransientCurrent-rsBaselineCurrent;
%         dVoltage = -5;  % ASSUMPTION ALERT
%         seriesResistance = 1000*dVoltage/dCurrent; %mV/pA equals Gohm
% 
%         % put series resistance values from each sweep into a different column
%         allRs = [allRs, seriesResistance];
% 
% 
% 
%     % create arrays that will be filled
%     tsBySweep = {};
%     sweepNumberArrayBySweep = {};
% 
%     % iterate through sweeps
%     for sweep=1:nSweeps
%         yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
%         [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
%         sweepNumberArray = sweep.* ones(length(locs),1);
% 
%         % collect sweep-by-sweep data
%         tsBySweep = [tsBySweep, locs];
%         sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
%     end   
% 
%     % quality control of found APs
%     figure('name', strcat(fileName, '_firing_qc'))
%     plot(xAxis,yFiltered)
%     hold on;
%     plot(locs,pks,'o')
%     yline(minPeakHeight)
%     hold off;
%     axis([xMinInSec xMaxInSec -100 40])
%     ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%     xlabel('Time (s)');
% 
%     % niceplot
%     figure('name', strcat(fileName, '_firing_raster'));
%     subplot(2,1,1)
%         % plot example trace
%         plot(xAxis,smooth(d(:,mainDataCh,1),smoothSpan),'k','LineWidth',0.5)
%         % line([lightPulseStartInSecs,lightPulseStartInSecs+lightPulseDurInSecs],[35,35],'Color',[0 0.4470 0.7410],'LineWidth',5)
%         if ~isempty(lightPulseStartInSecs)
%             rectangle('Position', [lightPulseStartInSecs -100 lightPulseDurInSecs 200], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
%         end
%         axis([xMinInSec xMaxInSec -100 40])
%         set(gca,'Visible','off');
%         % scale bars
%         line([xMaxInSec-0.05 xMaxInSec],[-100 -100],'Color','k')
%         line([xMaxInSec xMaxInSec],[-100 -90],'Color','k')
%         text(xMaxInSec-0.2, -90, "50 ms")
%         text(xMaxInSec-0.2, -80, "10 mV")
%         % -60 mV line
%         yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
%         text(xMinInSec, -90, "line @ -60 mV")        
% 
%     subplot(2,1,2)
%         % plot AP raster for all sweeps
%         for sweep = 1:nSweeps
%             plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
%             hold on;
%         end    
%         % adding light stim
%         if ~isempty(lightPulseStartInSecs)
%             rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');    
%         end
%         % adding finishing touches to plot
%         hold off;
%         axis([xMinInSec xMaxInSec 0 nSweeps+1])
%         ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
%         yticks([]);
%         xticks([]);
%         set(gca, 'YDir','reverse');
%         xlabel('Time (s)');
% 
% end