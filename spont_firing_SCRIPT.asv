
clear all;
close all;

%% USER INPUT

fileDir = 'M:\EphysData\20251212\2025_12_12_0028.abf';
saveDir = "C:\Users\ambrosi\OHSU Dropbox\Priscilla Ambrosi\Dropbox - Moss Lab\Lab - Data summaries\2025-12-18 ephys dreadds";
rec_type = "ON_VC_spont";
cellAttached = 0;

mainDataCh = 1;             % channel with recording from cell
cmdCh = 2;                  % channel with current command
xMinInSec = 0;
xMaxInSec = 20;
yMin = -400;                % in pA or mV
yMax = 100;                  % in pA or mV
plot_cmd = 0;
yMin_cmd = -100;            % in pA
yMax_cmd = 250;             % in pA
smoothSpan = 5;             % in data pts
smooth_cellAttached = 1;
bandpass_cellAttached = 1;
highpassThreshold = 5;    % in Hz
lowpassThreshold = 20000;    % in Hz
minPeakHeight = -20;        % amplitude threshold
minPeakDistance = 0.005;   % in seconds
example_sweep = 1;
cmd_y_scaleBarSize = 25;    % in pA
data_y_scaleBarSize = 50;   % in pA
time_scaleBarSize = 1;      % in s

saveFigs = 1;
saveData = 0;
plot_QC = 0;


%% MAIN CODE

% load ABF file
[d,si,h]=abfload(fileDir);

% get file name
[~, fileName, ~] = fileparts(fileDir);

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

% create matrix that will be filled
yForMean=zeros(h.sweepLengthInPts,nSweeps);

% plot quality control plots or not
if plot_QC == 1

    % plot all the channels and sweeps
    figure('name',strcat(fileName,'_all'))
    for channel=1:nChannels
        subplot(nChannels,1,channel)
        for sweep=1:nSweeps
            yFiltered = smooth(d(:,channel,sweep),smoothSpan);
            yForMean(:,sweep) = yFiltered;
            plot(xAxis,yFiltered,'Color',[0, 0, 0, 0.25]);
            hold on;
        end
        % calculate mean
        yMean = sum(yForMean,2)/nSweeps;
        plot(xAxis,yMean,'Color',[0, 0, 0, 1]);
        hold off;
        ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"));
        axis([xMinInSec xMaxInSec -inf inf])
    end
    xlabel('Time (s)');
    
    % plot the 1st sweep of all the channels to compare filtered vs not
    % filtered data
    figure('name',strcat(fileName,'_filtered vs not'))
    for channel=1:nChannels
        subplot(nChannels,1,channel)
        plot(xAxis,d(:,channel,sweep),'Color','b');
        hold on;
        yFiltered = smooth(d(:,channel,sweep),smoothSpan);
        plot(xAxis,yFiltered,'Color','r');
        hold off;
        ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"));
        axis([xMinInSec xMaxInSec -inf inf])
    end
    xlabel('Time (s)');

end


%% FIND APs (if applicable)

% if data was collected in whole cell mode, current clamp, find action
% potentials and plot a raster
if rec_type == "WC_CC_spont"

    disp("rec_type = WC_CC_spont");

    % double check that data was collected in current clamp by looking at
    % the units of the main data channel
    if strcmp(cell2mat(h.recChUnits(mainDataCh)),'mV')

        disp("main data channel in mV");
    
        % create arrays that will be filled
        tsBySweep = cell(1,nSweeps);
        sweepNumberArrayBySweep = cell(1,nSweeps);
        firingRateBySweep = zeros(nSweeps,1);
    
        % iterate through sweeps
        for sweep=1:nSweeps
            yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
            [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
            sweepNumberArray = sweep.* ones(length(locs),1);
    
            % collect sweep-by-sweep data
            tsBySweep{1,sweep} = locs;
            sweepNumberArrayBySweep{1,sweep} = sweepNumberArray;
            firingRateBySweep(sweep,1) = size(locs,1) / sweepDurationInSeconds;  % in Hz
        end   
    
        if plot_QC == 1
            % quality control of found APs
            figure('name', strcat(fileName, '_firing_qc'))
            plot(xAxis,yFiltered)
            hold on;
            plot(locs,pks,'o')
            yline(minPeakHeight)
            hold off;
            axis([xMinInSec xMaxInSec -100 40])
            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
            xlabel('Time (s)');
        end

        % niceplot
        if plot_cmd == 1                    
            figure('name', strcat(fileName, '_firing_raster'));

            subplot(3,1,1)
                % plot example traces
                plot(xAxis,smooth(d(:,mainDataCh,example_sweep),smoothSpan),'k','LineWidth',0.5)
                axis([xMinInSec xMaxInSec yMin yMax])
                set(gca,'Visible','off');
                % scale bars
                line([xMaxInSec-2*time_scaleBarSize xMaxInSec],[yMin yMin],'Color','k')
                line([xMaxInSec xMaxInSec],[yMin yMin + data_y_scaleBarSize],'Color','k')
                text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize/2, strcat(num2str(time_scaleBarSize), " s"))
                text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize, strcat(num2str(data_y_scaleBarSize), " mV"))
                % -60 mV line
                yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                text(xMinInSec, yMin + 10, "line @ -60 mV")
        
            subplot(3,1,2)
                % plot cmd traces for example
                plot(xAxis,smooth(d(:,cmdCh,example_sweep),smoothSpan),'k','LineWidth',0.5)
                axis([xMinInSec xMaxInSec yMin_cmd yMax_cmd])
                set(gca,'Visible','off');
                % scale bars
                line([xMaxInSec-2*time_scaleBarSize xMaxInSec],[yMin_cmd yMin_cmd],'Color','k')
                line([xMaxInSec xMaxInSec],[yMin_cmd yMin_cmd + cmd_y_scaleBarSize],'Color','k')
                text(xMaxInSec-2*time_scaleBarSize, yMin_cmd + cmd_y_scaleBarSize/2, strcat(num2str(time_scaleBarSize), " s"))
                text(xMaxInSec-2*time_scaleBarSize, yMin_cmd + cmd_y_scaleBarSize, strcat(num2str(cmd_y_scaleBarSize), " mV"))
        
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
                axis([xMinInSec xMaxInSec 0 nSweeps+1])
                ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                yticks([]);
                xticks([]);
                set(gca, 'YDir','reverse');
                xlabel('Time (s)');

        else
            figure('name', strcat(fileName, '_firing_raster'));
            
            subplot(2,1,1)
                % plot example traces
                plot(xAxis,smooth(d(:,mainDataCh,example_sweep),smoothSpan),'k','LineWidth',0.5)
                axis([xMinInSec xMaxInSec yMin yMax])
                set(gca,'Visible','off');
                % scale bars
                line([xMaxInSec-time_scaleBarSize xMaxInSec],[yMin yMin],'Color','k')
                line([xMaxInSec xMaxInSec],[yMin yMin + data_y_scaleBarSize],'Color','k')
                text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize/2, strcat(num2str(time_scaleBarSize), " s"))
                text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize, strcat(num2str(data_y_scaleBarSize), " mV"))
                % -60 mV line
                yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                yline(0,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                text(xMinInSec, yMin + 10, "lines @ 0 mV & -60 mV")                 
        
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
                axis([xMinInSec xMaxInSec 0 nSweeps+1])
                ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                yticks([]);
                xticks([]);
                set(gca, 'YDir','reverse');
                xlabel('Time (s)');
        end
    else
        disp("main data channel is NOT in mV")
    end
else
    disp("rec_type is NOT WC_CC_spont")
end


%% Cell Attached (ON) or Loose Seal (LS) Analysis

% check if this is a cell attached recording
if cellAttached == 1 || extractBefore(rec_type,"_") == "ON" || extractBefore(rec_type,"_") == "LS"

    disp("this is a cell attached recording");

    % create arrays that will be filled
    tsBySweep = cell(1,nSweeps);
    sweepNumberArrayBySweep = cell(1,nSweeps);
    firingRateBySweep = zeros(nSweeps,1);

    % iterate through sweeps
    for sweep=1:nSweeps
        if smooth_cellAttached == 1 & bandpass_cellAttached == 1
            yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
            yFiltered = bandpass(yFiltered,[highpassThreshold lowpassThreshold],samplingFrequency);
        elseif smooth_cellAttached == 0 & bandpass_cellAttached == 1
            yFiltered = bandpass(d(:,mainDataCh,sweep),[highpassThreshold lowpassThreshold],samplingFrequency);
        elseif smooth_cellAttached == 1 & bandpass_cellAttached == 0
            yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
        end
        [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',-minPeakHeight,'MinPeakDistance',minPeakDistance);
        sweepNumberArray = sweep.* ones(length(locs),1);

        % save first and last sweep (to save time later)
        if sweep == 1
            yFilteredFirstSweep = yFiltered;
            pksFirst = pks;
            locsFirst = locs;
        elseif sweep == nSweeps
            yFilteredLastSweep = yFiltered;
            pksLast = pks;
            locsLast = locs;
        end

        % collect sweep-by-sweep data
        tsBySweep{1,sweep} = locs;
        sweepNumberArrayBySweep{1,sweep} = sweepNumberArray;
        firingRateBySweep(sweep,1) = size(locs,1) / sweepDurationInSeconds;  % in Hz
    end

    if plot_QC == 1
        % quality control of bandpass filter
        figure('name',strcat(fileName,'_bandpass vs not'))
        subplot(2,1,1)
            plot(xAxis,yFilteredFirstSweep,'b')
            hold on;
            plot(xAxis,d(:,mainDataCh,1),'r')
            hold off;
            axis([xMinInSec xMaxInSec -inf inf])
            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
            xlabel('Time (s)');
        subplot(2,1,2)
            plot(xAxis,yFilteredLastSweep,'b')
            hold on;
            plot(xAxis,d(:,mainDataCh,nSweeps),'r')
            hold off;
            axis([xMinInSec xMaxInSec -inf inf])
            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
            xlabel('Time (s)');
    
        % quality control of found APs
        figure('name', strcat(fileName, '_cell_attached_qc'))
        subplot(2,1,1)
            plot(xAxis,yFilteredFirstSweep)
            hold on;
            plot(locsFirst,pksFirst,'o')
            yline(-minPeakHeight)
            hold off;
            axis([xMinInSec xMaxInSec yMin yMax])
            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
            xlabel('Time (s)');
        subplot(2,1,2)
            plot(xAxis,yFilteredLastSweep)
            hold on;
            plot(locsLast,pksLast,'o')
            yline(-minPeakHeight)
            hold off;
            axis([xMinInSec xMaxInSec yMin yMax])
            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
            xlabel('Time (s)');
    end
    
    % niceplot
    figure('name', strcat(fileName, '_cell_attached_raster'));
    subplot(2,1,1)
        % plot example trace
        plot(xAxis,bandpass(d(:,mainDataCh,example_sweep),[highpassThreshold lowpassThreshold],samplingFrequency),'k','LineWidth',0.5)
        axis([xMinInSec xMaxInSec yMin yMax])
        set(gca,'Visible','off');
        % scale bars
            line([xMaxInSec-time_scaleBarSize xMaxInSec],[yMin yMin],'Color','k')
            line([xMaxInSec xMaxInSec],[yMin yMin + data_y_scaleBarSize],'Color','k')
            text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize/2, strcat(num2str(time_scaleBarSize), " s"))
            if strcmp(cell2mat(h.recChUnits(mainDataCh)),'mV')
                disp('main data channel in mV')
                text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize, strcat(num2str(data_y_scaleBarSize), " mV"))    
            else
                disp('main data channel is NOT in mV')
                text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize, strcat(num2str(data_y_scaleBarSize), " pA"))
            end

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
        axis([xMinInSec xMaxInSec 0 nSweeps+1])
        ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
        yticks([]);
        xticks([]);
        set(gca, 'YDir','reverse');
        xlabel('Time (s)');
end


%% SAVING

if saveFigs == 1
    saveAllFigs(saveDir); close all
end