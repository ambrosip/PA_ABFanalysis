clear all
% close all

%% USER INPUT

% fileDir = 'M:\EphysData\20260303\2026_03_03_0006.abf';  % use single quotes
fileDir = 'M:\EphysData\20260318\2026_03_18_0033.abf';  % use single quotes
saveDir = 'C:\Users\ambrosi\OHSU Dropbox\Priscilla Ambrosi\Dropbox - Moss Lab\Lab - Data summaries\2026-03-19 ephys dreadds';

% for all
mainDataCh = 1;     % channel with recording from cell
cmdCh = 2;          % channel with command voltage or current
smoothSpan = 5;
xMinInSec = 0;
xMaxInSec = 1.75;

% for APs
minPeakHeight = -500;         % amplitude threshold
minPeakDistance = 0.001;      % in seconds
highpassThreshold = 100;
lowpassThreshold = 1500; 

% niceplot x limits
xMinInSecNiceplot_VC = 0;
xMaxInSecNiceplot_VC = 2.5;
xMinInSecNiceplot_CC = 1.45;
xMaxInSecNiceplot_CC = 1.55;
xMinInSecNiceplot_ON = 0;
xMaxInSecNiceplot_ON = 5;

% niceplot y limits
yMin_main_CellAttached = -1500;
yMax_main_CellAttached = 1500;
yMin_cmd_CellAttached = -200;
yMax_cmd_CellAttached = 200;
yMinNiceplot_main_VC = -500;
yMaxNiceplot_main_VC = 500;
yMinNiceplot_main_CC = -100;
yMaxNiceplot_main_CC = 50;
yMinNiceplot_cmd_VC = -70;
yMaxNiceplot_cmd_VC = -55;
yMinNiceplot_cmd_CC = 200;
yMaxNiceplot_cmd_CC = -200;
yMinNiceplot_light = -5;
yMaxNiceplot_light = 10;

saveFigs = 0;
plotAllCh = 1;

fileparts(mfilename('fullpath'))


%% Collect data and metadata

% load ABF file
[d,si,h]=abfload(fileDir);

% get file name
[~, fileName, ~] = fileparts(fileDir);

% get protocol used
[~, protocol_name, ~] = fileparts(h.protocolName);

% get first sweep number
fileName_parts = split(fileName,"_");
firstSweepNum = str2num(cell2mat(fileName_parts(end)));

% get start time of recording in min from midnight
firstSweepStartTime = h.uFileStartTimeMS/60/1000;

% convert sampling interval into sampling frequency
% si is the sampling interval in us
% samplingFrequency is in Hz
samplingFrequency = 1000000/si;

% d is organized like this:
% 1st column: data points (time series)
% 2nd column: channel
% 3rd column: sweep #

% relevant variables in h:
% recTime: seconds from midnight

% convert data points into seconds
sweepDurationInSeconds = h.sweepLengthInPts/samplingFrequency;
xAxis = linspace(0,sweepDurationInSeconds,h.sweepLengthInPts)';

% collect some simple info from header
nSweeps = size(d,3);
nChannels = size(h.recChNames,1);

% create matrix that will be filled
yFiltered_All=zeros(h.sweepLengthInPts,nChannels,nSweeps);

% filter all data
for channel=1:nChannels
    for sweep=1:nSweeps
        yFiltered = smooth(d(:,channel,sweep),smoothSpan);
        yFiltered_All(:,channel,sweep) = yFiltered;
    end
end

% calculate mean for all channels
yMean = mean(yFiltered_All,3);

% set main and cmd signal 
yFiltered_main_All = yFiltered_All(:,mainDataCh,:);
yFiltered_cmd_All = yFiltered_All(:,cmdCh,:);
yMean_main = yMean(:,mainDataCh);
yMean_cmd = yMean(:,cmdCh);


%% Prep for plots

% set y range
% if recording unit is mV, use current clamp parameters
if strcmp(cell2mat(h.recChUnits(mainDataCh)),'mV')
    yMin_main = yMinNiceplot_main_CC;
    yMax_main = yMaxNiceplot_main_CC;
    yMin_cmd = yMinNiceplot_cmd_CC;
    yMax_cmd = yMaxNiceplot_cmd_CC;
    xMin = xMinInSecNiceplot_CC;
    xMax = xMaxInSecNiceplot_CC;
    cellAttached = 0; % ASSUMPTION: all cell attached recordings are in voltage clamp
% if recording unit is pA, use voltage clamp parameters
else
    yMin_main = yMinNiceplot_main_VC;
    yMax_main = yMaxNiceplot_main_VC;
    yMin_cmd = yMinNiceplot_cmd_VC;
    yMax_cmd = yMaxNiceplot_cmd_VC;
    xMin = xMinInSecNiceplot_VC;
    xMax = xMaxInSecNiceplot_VC;
    cellAttached = 0;
    if contains(protocol_name, "spont")
        yMin_main = yMin_main_CellAttached;
        yMax_main = yMax_main_CellAttached;
        yMin_cmd = yMin_cmd_CellAttached;
        yMax_cmd = yMax_cmd_CellAttached;
        xMin = xMinInSecNiceplot_ON;
        xMax = xMaxInSecNiceplot_ON;
        cellAttached = 1; % ASSUMPTION: spont firing recordings in voltage clamp are cell attached recordings
    end
end

if size(xAxis,1)/samplingFrequency < xMax
    xMax = size(xAxis,1)/samplingFrequency;
end


%% Plot all channels

% if applicable, plot all channels and sweeps
if plotAllCh == 1
    % plot all the channels and sweeps
    figure('name',strcat(fileName,'_all'))
    for channel=1:nChannels
        subplot(nChannels,1,channel)
        for sweep=1:nSweeps            
            plot(xAxis,yFiltered_All(:,channel,sweep),'Color',[0, 0, 0, 0.25]);
            hold on;            
        end
        % plot(xAxis,yMean(:,channel),'Color',[0, 0, 0, 1]);       
        hold off;
        ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"),"Interpreter","none");
        axis([-inf inf -inf inf])
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


%% Do protocol-specific analysis

% if applicable, get optogenetics data 
if contains(protocol_name, "LED")
    getOptogeneticsData;
    if strcmp(cell2mat(h.recChUnits(mainDataCh)),'pA')
        getSeriesResistance;
    end
end

% if applicable, get series resistance
if contains(protocol_name, "test pulse") &...
        strcmp(cell2mat(h.recChUnits(mainDataCh)),'pA')
    getSeriesResistance;
    disp('got series resistance')
end

if saveFigs == 1
    saveAllFigs(saveDir)
    
end




   
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