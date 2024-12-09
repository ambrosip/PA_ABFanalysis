
%% USER INPUT

fileDir = '/Users/priscilla/OHSU Dropbox/Priscilla Ambrosi/Dropbox - Moss Lab/Lab - Data/Ephys/2024-12-05/2024_12_05_0000.abf';
smoothSpan = 5;
xMinInSec = 0;
xMaxInSec = 1.75;
minPeakHeight = -500;         % amplitude threshold
minPeakDistance = 0.001;    % in seconds
mainDataCh = 1;     % channel with recording from cell
lightCh = 3;        % channel with opto stim
cellAttached = 1;
highpassThreshold = 100;
lowpassThreshold = 1500; 
yMin = -1500;
yMax = 1500;


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

% create matrix that will be filled
yForMean=zeros(h.sweepLengthInPts,nSweeps);

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


%% FIND APs (if applicable)

% if data was collected in current clamp, find action potentials and plot a raster 
if strcmp(cell2mat(h.recChUnits(mainDataCh)),'mV')

    % create arrays that will be filled
    tsBySweep = {};
    sweepNumberArrayBySweep = {};

    % iterate through sweeps
    for sweep=1:nSweeps
        yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
        [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
        sweepNumberArray = sweep.* ones(length(locs),1);

        % collect sweep-by-sweep data
        tsBySweep = [tsBySweep, locs];
        sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
    end   

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
    
    % niceplot
    figure('name', strcat(fileName, '_firing_raster'));
    subplot(2,1,1)
        % plot example trace
        plot(xAxis,smooth(d(:,mainDataCh,1),smoothSpan),'k','LineWidth',0.5)
        % line([lightPulseStartInSecs,lightPulseStartInSecs+lightPulseDurInSecs],[35,35],'Color',[0 0.4470 0.7410],'LineWidth',5)
        if ~isempty(lightPulseStartInSecs)
            rectangle('Position', [lightPulseStartInSecs -100 lightPulseDurInSecs 200], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
        end
        axis([xMinInSec xMaxInSec -100 40])
        set(gca,'Visible','off');
        % scale bars
        line([xMaxInSec-0.05 xMaxInSec],[-100 -100],'Color','k')
        line([xMaxInSec xMaxInSec],[-100 -90],'Color','k')
        text(xMaxInSec-0.2, -90, "50 ms")
        text(xMaxInSec-0.2, -80, "10 mV")
        % -60 mV line
        yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
        text(xMinInSec, -90, "line @ -60 mV")        

    subplot(2,1,2)
        % plot AP raster for all sweeps
        for sweep = 1:nSweeps
            plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
            hold on;
        end    
        % adding light stim
        if ~isempty(lightPulseStartInSecs)
            rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');    
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


%% Cell Attached Analysis

if cellAttached == 1

    % create arrays that will be filled
    tsBySweep = {};
    sweepNumberArrayBySweep = {};

    % iterate through sweeps
    for sweep=1:nSweeps
        yFiltered = bandpass(d(:,mainDataCh,sweep),[highpassThreshold lowpassThreshold],samplingFrequency);
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
        tsBySweep = [tsBySweep, locs];
        sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
    end   

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
    
    % niceplot
    figure('name', strcat(fileName, '_cell_attached_raster'));
    subplot(2,1,1)
        % plot example trace
        plot(xAxis,bandpass(d(:,mainDataCh,1),[highpassThreshold lowpassThreshold],samplingFrequency),'k','LineWidth',0.5)
        % line([lightPulseStartInSecs,lightPulseStartInSecs+lightPulseDurInSecs],[35,35],'Color',[0 0.4470 0.7410],'LineWidth',5)
        if ~isempty(lightPulseStartInSecs)
            rectangle('Position', [lightPulseStartInSecs -100 lightPulseDurInSecs 200], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');
        end
        axis([xMinInSec xMaxInSec yMin yMax])
        set(gca,'Visible','off');
        % scale bars
        line([xMaxInSec-0.05 xMaxInSec],[-100 -100],'Color','k')
        line([xMaxInSec xMaxInSec],[-100 -90],'Color','k')
        text(xMaxInSec-0.2, -90, "50 ms")
        text(xMaxInSec-0.2, -80, "10 mV")       

    subplot(2,1,2)
        % plot AP raster for all sweeps
        for sweep = 1:nSweeps
            plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
            hold on;
        end    
        % adding light stim
        if ~isempty(lightPulseStartInSecs)
            rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', [0 0.4470 0.7410], 'EdgeColor', 'none');    
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