%{
to do
    write code to analyze current steps
    double check ymin and ymax values within plots
    create spreadsheets w data
    plot SEM instead of 2+-SD

pre-reqs
    abfload
    saveAllFigs
    curve fitting toolbox (smooth)
    signal processing toolbox (bandpass)
%}


%% USER INPUT

databaseFile = 'C:\Users\ambrosi\OHSU Dropbox\Priscilla Ambrosi\Dropbox - Moss Lab\Lab - Data\Ephys\Ephys Database_PC.xlsx';
saveDir = 'C:\Users\ambrosi\OHSU Dropbox\Priscilla Ambrosi\Dropbox - Moss Lab\Lab - Data summaries\2024-12-10 spag';
firstRow = 1;               % remember to account for header when counting rows!
analyzeOnlyOneRow = 0;      % 1 (yes) or 0 (no)
plotFigs = 0;               % 1 (yes) or 0 (no)
saveFigs = 0;               % 1 (yes) or 0 (no)
saveData = 1;               % 1 (yes) or 0 (no)

% affects data analysis
mainDataCh = 1;             % channel with recording from cell
cmdCh = 2;                  % channel with voltage or current command
blueLightCh = 3;            % channel with blue opto stim
greenLightCh = 4;           % channel with green opto stim

% affects data viz
xMinInSec = 0;
xMaxInSec = 3.5;
xScaleBar = 500;
yMinWC_VC = -500;
yMaxWC_VC = 500;
yScaleBarWC_VC = 100;
yMinWC_CC = -100;
yMaxWC_CC = 40;
yScaleBarWC_CC = 10;
yMinLS_CC = -10;
yMaxLS_CC = 10;
yScaleBarLS_CC = 1;
yMinLS_VC = -1500;
yMaxLS_VC = 1500;
yScaleBarLS_VC = 100;
ymaxhist = 50;

% affects AP detection
smoothSpan = 5;
highpassThreshold = 100;
lowpassThreshold = 1500; 
minPeakDistance = 0.001;    % in seconds
minPeakHeight_WC_CC = -20;
minPeakHeight_LS_VC = 100;  % FYI code looks for valleys instead of peaks
minPeakHeight_LS_CC = 0.5;  % FYI code looks for valleys instead of peaks

% affects analysis of data without o-stim
usualLightPulseDurInSec = 0.5;
usualLightPulseStartInSecs = 0.6126;


%% GATHER DATA FROM DATABASE

% save importing options so we can change them
opts = detectImportOptions(databaseFile);

% change the variable type in column 4 (file_num) to char so that matlab
% will actially read all the values in each cell. Why? Each cell is column
% 4 can contain multiple numbers, separated by a comma. If you let matlab
% do its auto variable type detection, it will interpret column 4 cells as
% doubles and will import cells with multiple numbers as "NaN".
% ALERT: change the column number if you add/remove database columns
opts.VariableTypes(4) = {'char'};

% read database file using custom options
database = readtable(databaseFile, opts);

% each row is one type of recording
% one cell can be represented by multiple rows
rows = height(database);

% is user only wants to analye 1 row, overwrite the variable "rows"
if analyzeOnlyOneRow == 1
    rows = firstRow;
end

% get path of database file to figure out path of raw data files
[filepath,name,ext]=fileparts(databaseFile);


%% CREATE MATRICES that may or may not be filled later

mouseNameByFile = [];
mouseSexByFile = [];
cellNameByFile = [];
opsinExpressionByFile = [];
LEDcolorByFile = [];
LEDpowerByFile = [];
recordingTypeByFile = [];
abfFileNameByFile = [];
sweepDurationInSecondsByFile = [];
lightPulseDurInSecsByFile = [];
hzPreLightMeanByFile = []; 
hzPreLightStdByFile = [];                 
hzDuringLightMeanByFile = [];               
hzDuringLightStdByFile = [];
hzPostLightMeanByFile = [];
hzPostLightStdByFile = [];
hz10sPostLightMeanByFile = [];
hz10sPostLightStdByFile = [];
lightEffectByFile = [];
recovery10sAfterLightByFile = [];


%% PROCESS DATA FROM DATABASE

% get analysis date
analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

% iterate through every row
for row=firstRow:rows

    % only look into cells that were NOT exluded
    if cell2mat(database.excluded(row)) ~= 'y'

        % collect basic info from database
        mouseNumber = database.m(row);
        % pad mouse number with zeros (if needed) to get 4 digits
        mouseName = sprintf('m%04d',mouseNumber);  
        % keep collecting info
        mouseSex = cell2mat(database.sex(row));
        dateRecorded = database.date_recorded(row);
        cellName = cell2mat(database.cell(row));
        opsinExpression = cell2mat(database.opsin_pos(row));
        if opsinExpression == 'n'
            opsinExpression = "OPSIN-NEG";
        else
            opsinExpression = "OPSIN-POS";
        end
        % set o-stim color based on LED used
        LEDcolor = cell2mat(database.LED_color(row));
        if LEDcolor == 'b'
            ostimColor = [0 0.4470 0.7410];
            lightCh = blueLightCh;
        elseif LEDcolor == 'g'
            ostimColor = [0.4660 0.6740 0.1880];
            lightCh = greenLightCh;
        else 
            ostimColor = [1 1 1];
            lightCh = blueLightCh;
        end
        LEDpower = sprintf('power%02d',database.LED_power(row));
        recordingType = cell2mat(database.rec_type(row));

        % collect basename of files in directory
        % abfFilesDir = cell2mat(database.dir(row));
        abfFilesDir = fullfile(filepath,num2str(dateRecorded));
        abfFiles = dir(fullfile(abfFilesDir, '*.abf'));
        abfFilesPrefix = abfFiles(1).name(1:end-8);

        % collect file numbers to analyze
        fileNumbers = str2double(split(database.file_num(row),','));

        % iterate through all the file numbers listed for this experiment
        % type
        for file=fileNumbers'

            % this is the name of the file that will be analyzed
            abfFileName = strcat(abfFilesPrefix, sprintf('%04d.abf',file));

            % make complete file name prefix for exporting data
            str = [mouseName, mouseSex, cellName, opsinExpression, LEDcolor, LEDpower, recordingType, abfFileName];
            prefix = join(str,'_');

            % this is the full path to the file that will be analyzed
            fileDir = fullfile(abfFilesDir,abfFileName);

            % load ABF file
            [d,si,h]=abfload(fileDir);
            
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

            if ~isempty(lightPulseStartInSecs)
                xMinInSec = lightPulseStartInSecs - lightPulseDurInSecs;
                xMaxInSec = lightPulseStartInSecs + 10*lightPulseDurInSecs;
            end

            if isempty(lightPulseDurInSecs)
                lightPulseDurInSecs = usualLightPulseDurInSec;
                lightPulseStartInSecs = usualLightPulseStartInSecs;
                xMinInSec = lightPulseStartInSecs - lightPulseDurInSecs;
                xMaxInSec = lightPulseStartInSecs + 10*lightPulseDurInSecs;
            end
            
            % create matrix that will be filled
            yForMean=zeros(h.sweepLengthInPts,nSweeps);          

            if plotFigs == 1
                % plot all the channels and sweeps
                figure('name',strcat(prefix,'_all'))
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
                        ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"),'Interpreter','none');
                        axis([-inf inf -inf inf])
                        if channel == mainDataCh
                            title(prefix,'Interpreter','none');
                        end
                    end
                    xlabel('Time (s)');
            end


            %% Find action potentials (APs) if data was collected in whole cell, current clamp mode
            if recordingType == "WC_CC"
                
                % adjust variables according to user input
                yScaleBar = yScaleBarWC_CC;
                yMin = yMinWC_CC;
                yMax = yMaxWC_CC;
                minPeakHeight = minPeakHeight_WC_CC;
                yRange = yMax-yMin; 
                xRange = xMaxInSec-xMinInSec;

                % adjust exceptions according to the database
                if ~isnan(database.yMin(row))
                    yMin = database.yMin(row);
                end
                if ~isnan(database.yMax(row))
                    yMax = database.yMax(row);
                end
                if ~isnan(database.minPeakHeight(row))
                    minPeakHeight = database.minPeakHeight(row);
                end
                yRange = yMax-yMin;

                % create arrays that will be filled
                tsBySweep = {};
                sweepNumberArrayBySweep = {};
                hzPreLightBySweep = [];
                hzDuringLightBySweep = [];
                hzPostLightBySweep = [];  
                allTimeStamps = [];
            
                % iterate through sweeps
                for sweep=1:nSweeps
                    yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
                    [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
                    sweepNumberArray = sweep.* ones(length(locs),1);           
                    % collect sweep-by-sweep data
                    tsBySweep = [tsBySweep, locs];
                    sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
                    % count APs before, during and after opto-stim
                    locsPreLight = locs(locs>=lightPulseStartInSecs-lightPulseDurInSecs & locs<lightPulseStartInSecs);
                    locsDuringLight = locs(locs>=lightPulseStartInSecs & locs<lightPulseStartInSecs+lightPulseDurInSecs);
                    locsPostLight = locs(locs>=lightPulseStartInSecs+lightPulseDurInSecs & locs<lightPulseStartInSecs+2*lightPulseDurInSecs);   
                    locs10sPostLight = locs(locs>=lightPulseStartInSecs+10 & locs<lightPulseStartInSecs+10+lightPulseDurInSecs);
                    % calculate firing rate before, during and after opto-stim
                    hzPreLightBySweep(sweep) = length(locsPreLight)/lightPulseDurInSecs;
                    hzDuringLightBySweep(sweep) = length(locsDuringLight)/lightPulseDurInSecs;
                    hzPostLightBySweep(sweep) = length(locsPostLight)/lightPulseDurInSecs;  
                    hz10sPostLightBySweep(sweep) = length(locs10sPostLight)/lightPulseDurInSecs; 
                    % save first and last sweep (for quality control later)
                    if sweep == 1
                        yFilteredFirstSweep = yFiltered;
                        pksFirst = pks;
                        locsFirst = locs;
                    elseif sweep == nSweeps
                        yFilteredLastSweep = yFiltered;
                        pksLast = pks;
                        locsLast = locs;
                    end  
                    allTimeStamps = [allTimeStamps; locs];
                end   

                % calculate mean and sd of firing rate
                hzPreLightMean = mean(hzPreLightBySweep);
                hzPreLightStd = std(hzPreLightBySweep);
                hzDuringLightMean = mean(hzDuringLightBySweep);
                hzDuringLightStd = std(hzDuringLightBySweep);
                hzPostLightMean = mean(hzPostLightBySweep);
                hzPostLightStd = std(hzPostLightBySweep);
                hz10sPostLightMean = mean(hz10sPostLightBySweep);
                hz10sPostLightStd = std(hz10sPostLightBySweep);

                % determine light effect
                if hzDuringLightMean < hzPreLightMean - 2*hzPreLightStd
                    lightEffect = -1;
                elseif hzDuringLightMean > hzPreLightMean + 2*hzPreLightStd
                    lightEffect = +1;
                else 
                    lightEffect = 0;
                end

                % determine recovery 10s after light
                if hz10sPostLightStd >= hzPreLightMean - 2*hzPreLightStd && hz10sPostLightStd <= hzPreLightMean + 2*hzPreLightStd
                    recovery10sAfterLight = 1;
                else 
                    recovery10sAfterLight = 0;
                end

                % organize data for histogram (counting APs accross all
                % sweeps)
                edges = xMinInSec:lightPulseDurInSecs:xMaxInSec;
                [N, edges] = histcounts(allTimeStamps,edges);
                firingHz = (1/lightPulseDurInSecs)*N/nSweeps;

                if plotFigs == 1
                    % quality control of filter
                    figure('name',strcat(prefix,'_filter_qc'))
                        subplot(2,1,1)
                            plot(xAxis,yFilteredFirstSweep,'b')
                            hold on;
                            plot(xAxis,d(:,mainDataCh,1),'r')
                            hold off;
                            axis([xMinInSec xMaxInSec -inf inf])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                            title(prefix,'Interpreter','none');
                        subplot(2,1,2)
                            plot(xAxis,yFilteredLastSweep,'b')
                            hold on;
                            plot(xAxis,d(:,mainDataCh,nSweeps),'r')
                            hold off;
                            axis([xMinInSec xMaxInSec -inf inf])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                
                    % quality control of found APs
                    figure('name', strcat(prefix, '_AP_qc'))
                        subplot(2,1,1)
                            plot(xAxis,yFilteredFirstSweep)
                            hold on;
                            plot(locsFirst,pksFirst,'o')
                            yline(minPeakHeight)
                            hold off;
                            axis([xMinInSec xMaxInSec yMin yMax])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                            title(prefix,'Interpreter','none');
                        subplot(2,1,2)
                            plot(xAxis,yFilteredLastSweep)
                            hold on;
                            plot(locsLast,pksLast,'o')
                            yline(minPeakHeight)
                            hold off;
                            axis([xMinInSec xMaxInSec yMin yMax])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                    
                    % niceplot
                    figure('name', strcat(prefix, '_AP_raster'));         
                        subplot(3,1,1)
                            % plot example trace
                            plot(xAxis,smooth(d(:,mainDataCh,1),smoothSpan),'k','LineWidth',0.5)
                            if ~isempty(lightPulseStartInSecs)
                                rectangle('Position', [lightPulseStartInSecs yMin lightPulseDurInSecs yMax-yMin], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');
                            end
                            axis([xMinInSec xMaxInSec yMin yMax])
                            set(gca,'Visible','off');
                            % scale bars
                            line([xMaxInSec-xScaleBar/1000 xMaxInSec],[yMin yMin],'Color','k')
                            line([xMaxInSec xMaxInSec],[yMin yMin+yScaleBar],'Color','k')
                            text(xMaxInSec-xRange/10, yMin+yRange*7/100, strcat(num2str(xScaleBar), " ms"));
                            text(xMaxInSec-xRange/10, yMin+yRange*14/100, strcat(num2str(yScaleBar), " ", cell2mat(h.recChUnits(mainDataCh))));
                            % -60 mV line
                            yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                            text(xMinInSec, yMin+yRange*7/100, "line @ -60 mV")
                        subplot(3,1,2)
                            % plot AP raster for all sweeps
                            for sweep = 1:nSweeps
                                plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
                                hold on;
                            end    
                            % adding light stim
                            if ~isempty(lightPulseStartInSecs)
                                rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');    
                            end
                            % adding finishing touches to plot
                            hold off;
                            axis([xMinInSec xMaxInSec 0 nSweeps+1])
                            ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                            yticks([]);
                            xticks([]);
                            set(gca, 'YDir','reverse');
                            xlabel('Time (s)');
                        subplot(3,1,3)
                            % plot histogram and 2*SD criteria
                            hold on;                    
                            histogram('BinEdges', xMinInSec:lightPulseDurInSecs:xMaxInSec, 'BinCounts', firingHz, 'DisplayStyle', 'stairs', 'EdgeColor', 'k'); 
                            % plot light stim as rectangle
                            rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs ymaxhist], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');                       
                            % plot Hz mean as horizontal line
                            yline(hzPreLightMean, '--');
                            % plot +- 2 SD as rectangle around mean
                            % [x y width height]
                            rectangle('Position', [0 hzPreLightMean-(2*hzPreLightStd) xMaxInSec 4*hzPreLightStd], 'FaceAlpha', 0.1, 'FaceColor', [0 0 0], 'EdgeColor', 'none');
                            xlabel('Time (s)');
                            ylabel('Firing rate (Hz)');
                            axis([xMinInSec xMaxInSec 0 ymaxhist])
                            yticks([0 ymaxhist]);
                            hold off;
                            title(prefix,'Interpreter','none');
                end
            end


            %% Find APs if data was collected in loose seal, voltage clamp mode
            if recordingType == "LS_VC"
      
                % adjust variables according to user input
                yScaleBar = yScaleBarLS_VC;
                yMin = yMinLS_VC;
                yMax = yMaxLS_VC;
                minPeakHeight = minPeakHeight_LS_VC;
                yRange = yMax-yMin; 
                xRange = xMaxInSec-xMinInSec;

                % adjust exceptions according to the database
                if ~isnan(database.yMin(row))
                    yMin = database.yMin(row);
                end
                if ~isnan(database.yMax(row))
                    yMax = database.yMax(row);
                end
                if ~isnan(database.minPeakHeight(row))
                    minPeakHeight = database.minPeakHeight(row);
                end
                yRange = yMax-yMin;
                
                % create arrays that will be filled
                tsBySweep = {};
                sweepNumberArrayBySweep = {};
                hzPreLightBySweep = [];
                hzDuringLightBySweep = [];
                hzPostLightBySweep = [];  
                allTimeStamps = [];
            
                % iterate through sweeps
                for sweep=1:nSweeps
                    yFiltered = bandpass(d(:,mainDataCh,sweep),[highpassThreshold lowpassThreshold],samplingFrequency);
                    [pks,locs,w,p] = findpeaks(-yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
                    sweepNumberArray = sweep.* ones(length(locs),1);           
                    % collect sweep-by-sweep data
                    tsBySweep = [tsBySweep, locs];
                    sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
                    % count APs before, during and after opto-stim
                    locsPreLight = locs(locs>=lightPulseStartInSecs-lightPulseDurInSecs & locs<lightPulseStartInSecs);
                    locsDuringLight = locs(locs>=lightPulseStartInSecs & locs<lightPulseStartInSecs+lightPulseDurInSecs);
                    locsPostLight = locs(locs>=lightPulseStartInSecs+lightPulseDurInSecs & locs<lightPulseStartInSecs+2*lightPulseDurInSecs);  
                    locs10sPostLight = locs(locs>=lightPulseStartInSecs+10 & locs<lightPulseStartInSecs+10+lightPulseDurInSecs);
                    % calculate firing rate before, during and after opto-stim
                    hzPreLightBySweep(sweep) = length(locsPreLight)/lightPulseDurInSecs;
                    hzDuringLightBySweep(sweep) = length(locsDuringLight)/lightPulseDurInSecs;
                    hzPostLightBySweep(sweep) = length(locsPostLight)/lightPulseDurInSecs;  
                    hz10sPostLightBySweep(sweep) = length(locs10sPostLight)/lightPulseDurInSecs; 
                    % save first and last sweep (for quality control later)
                    if sweep == 1
                        yFilteredFirstSweep = yFiltered;
                        pksFirst = pks;
                        locsFirst = locs;
                    elseif sweep == nSweeps
                        yFilteredLastSweep = yFiltered;
                        pksLast = pks;
                        locsLast = locs;
                    end  
                    allTimeStamps = [allTimeStamps; locs];
                end   

                % calculate mean and sd of firing rate
                hzPreLightMean = mean(hzPreLightBySweep);
                hzPreLightStd = std(hzPreLightBySweep);
                hzDuringLightMean = mean(hzDuringLightBySweep);
                hzDuringLightStd = std(hzDuringLightBySweep);
                hzPostLightMean = mean(hzPostLightBySweep);
                hzPostLightStd = std(hzPostLightBySweep);
                hz10sPostLightMean = mean(hz10sPostLightBySweep);
                hz10sPostLightStd = std(hz10sPostLightBySweep);

                % determine light effect
                if hzDuringLightMean < hzPreLightMean - 2*hzPreLightStd
                    lightEffect = -1;
                elseif hzDuringLightMean > hzPreLightMean + 2*hzPreLightStd
                    lightEffect = +1;
                else 
                    lightEffect = 0;
                end

                % determine recovery 10s after light
                if hz10sPostLightStd >= hzPreLightMean - 2*hzPreLightStd && hz10sPostLightStd <= hzPreLightMean + 2*hzPreLightStd
                    recovery10sAfterLight = 1;
                else 
                    recovery10sAfterLight = 0;
                end

                % organize data for histogram (counting APs accross all
                % sweeps)
                edges = xMinInSec:lightPulseDurInSecs:xMaxInSec;
                [N, edges] = histcounts(allTimeStamps,edges);
                firingHz = (1/lightPulseDurInSecs)*N/nSweeps;
                
                if plotFigs == 1
                    % quality control of bandpass filter
                    figure('name',strcat(prefix,'_filter_qc'))
                        subplot(2,1,1)
                            plot(xAxis,yFilteredFirstSweep,'b')
                            hold on;
                            plot(xAxis,d(:,mainDataCh,1),'r')
                            hold off;
                            axis([xMinInSec xMaxInSec -inf inf])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                            title(prefix,'Interpreter','none');
                        subplot(2,1,2)
                            plot(xAxis,yFilteredLastSweep,'b')
                            hold on;
                            plot(xAxis,d(:,mainDataCh,nSweeps),'r')
                            hold off;
                            axis([xMinInSec xMaxInSec -inf inf])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                
                    % quality control of found APs
                    figure('name', strcat(prefix, '_AP_qc'))
                        subplot(2,1,1)
                            plot(xAxis,yFilteredFirstSweep)
                            hold on;
                            plot(locsFirst,-pksFirst,'o')
                            yline(-minPeakHeight)
                            hold off;
                            axis([xMinInSec xMaxInSec yMin yMax])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                            title(prefix,'Interpreter','none');
                        subplot(2,1,2)
                            plot(xAxis,yFilteredLastSweep)
                            hold on;
                            plot(locsLast,-pksLast,'o')
                            yline(-minPeakHeight)
                            hold off;
                            axis([xMinInSec xMaxInSec yMin yMax])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                    
                    % niceplot
                    figure('name', strcat(prefix, '_AP_raster'));
                        subplot(3,1,1)
                            % plot example trace
                            plot(xAxis,bandpass(d(:,mainDataCh,1),[highpassThreshold lowpassThreshold],samplingFrequency),'k','LineWidth',0.5)
                            if ~isempty(lightPulseStartInSecs)
                                rectangle('Position', [lightPulseStartInSecs yMin lightPulseDurInSecs yRange], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');
                            end
                            axis([xMinInSec xMaxInSec yMin yMax])
                            set(gca,'Visible','off');
                            % scale bars
                            line([xMaxInSec-xScaleBar/1000 xMaxInSec],[yMin yMin],'Color','k')
                            line([xMaxInSec xMaxInSec],[yMin yMin+yScaleBar],'Color','k')
                            text(xMaxInSec-xRange/10, yMin+yRange*7/100, strcat(num2str(xScaleBar), " ms"));
                            text(xMaxInSec-xRange/10, yMin+yRange*14/100, strcat(num2str(yScaleBar), " ", cell2mat(h.recChUnits(mainDataCh))));      
                        subplot(3,1,2)
                            % plot AP raster for all sweeps
                            for sweep = 1:nSweeps
                                if size(tsBySweep,2)>=sweep
                                    plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
                                    hold on;
                                end
                            end    
                            % adding light stim
                            if ~isempty(lightPulseStartInSecs)
                                rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');    
                            end
                            % adding finishing touches to plot
                            hold off;
                            axis([xMinInSec xMaxInSec 0 nSweeps+1])
                            ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                            yticks([]);
                            xticks([]);
                            set(gca, 'YDir','reverse');
                            xlabel('Time (s)');  
                        subplot(3,1,3)
                            % plot histogram and 2*SD criteria
                            hold on;                    
                            histogram('BinEdges', xMinInSec:lightPulseDurInSecs:xMaxInSec, 'BinCounts', firingHz, 'DisplayStyle', 'stairs', 'EdgeColor', 'k'); 
                            % plot light stim as rectangle
                            rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs ymaxhist], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');                       
                            % plot Hz mean as horizontal line
                            yline(hzPreLightMean, '--');
                            % plot +- 2 SD as rectangle around mean
                            % [x y width height]
                            rectangle('Position', [0 hzPreLightMean-(2*hzPreLightStd) xMaxInSec 4*hzPreLightStd], 'FaceAlpha', 0.1, 'FaceColor', [0 0 0], 'EdgeColor', 'none');
                            xlabel('Time (s)');
                            ylabel('Firing rate (Hz)');
                            axis([xMinInSec xMaxInSec 0 ymaxhist])
                            yticks([0 ymaxhist]);
                            hold off;
                            title(prefix,'Interpreter','none');
                end
            end


            %% Find APs if data was collected in loose seal, current clamp mode
            if recordingType == "LS_CC"

                % adjust variables according to user input
                yScaleBar = yScaleBarLS_CC;
                yMin = yMinLS_CC;
                yMax = yMaxLS_CC;
                minPeakHeight = minPeakHeight_LS_CC;
                yRange = yMax-yMin; 
                xRange = xMaxInSec-xMinInSec;

                % adjust exceptions according to the database
                if ~isnan(database.yMin(row))
                    yMin = database.yMin(row);
                end
                if ~isnan(database.yMax(row))
                    yMax = database.yMax(row);
                end
                if ~isnan(database.minPeakHeight(row))
                    minPeakHeight = database.minPeakHeight(row);
                end
                yRange = yMax-yMin;

                % create arrays that will be filled
                tsBySweep = {};
                sweepNumberArrayBySweep = {};
                hzPreLightBySweep = [];
                hzDuringLightBySweep = [];
                hzPostLightBySweep = [];  
                allTimeStamps = [];
            
                % iterate through sweeps
                for sweep=1:nSweeps
                    yFiltered = bandpass(d(:,mainDataCh,sweep),[highpassThreshold lowpassThreshold],samplingFrequency);
                    [pks,locs,w,p] = findpeaks(-yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
                    sweepNumberArray = sweep.* ones(length(locs),1);           
                    % collect sweep-by-sweep data
                    tsBySweep = [tsBySweep, locs];
                    sweepNumberArrayBySweep = [sweepNumberArrayBySweep, sweepNumberArray];
                    % count APs before, during and after opto-stim
                    locsPreLight = locs(locs>=lightPulseStartInSecs-lightPulseDurInSecs & locs<lightPulseStartInSecs);
                    locsDuringLight = locs(locs>=lightPulseStartInSecs & locs<lightPulseStartInSecs+lightPulseDurInSecs);
                    locsPostLight = locs(locs>=lightPulseStartInSecs+lightPulseDurInSecs & locs<lightPulseStartInSecs+2*lightPulseDurInSecs);
                    locs10sPostLight = locs(locs>=lightPulseStartInSecs+10 & locs<lightPulseStartInSecs+10+lightPulseDurInSecs);
                    % calculate firing rate before, during and after opto-stim
                    hzPreLightBySweep(sweep) = length(locsPreLight)/lightPulseDurInSecs;
                    hzDuringLightBySweep(sweep) = length(locsDuringLight)/lightPulseDurInSecs;
                    hzPostLightBySweep(sweep) = length(locsPostLight)/lightPulseDurInSecs; 
                    hz10sPostLightBySweep(sweep) = length(locs10sPostLight)/lightPulseDurInSecs; 
                    % save first and last sweep (for quality control later)
                    if sweep == 1
                        yFilteredFirstSweep = yFiltered;
                        pksFirst = pks;
                        locsFirst = locs;
                    elseif sweep == nSweeps
                        yFilteredLastSweep = yFiltered;
                        pksLast = pks;
                        locsLast = locs;
                    end  
                    allTimeStamps = [allTimeStamps; locs];
                end   

                % calculate mean and sd of firing rate
                hzPreLightMean = mean(hzPreLightBySweep);
                hzPreLightStd = std(hzPreLightBySweep);
                hzDuringLightMean = mean(hzDuringLightBySweep);
                hzDuringLightStd = std(hzDuringLightBySweep);
                hzPostLightMean = mean(hzPostLightBySweep);
                hzPostLightStd = std(hzPostLightBySweep);
                hz10sPostLightMean = mean(hz10sPostLightBySweep);
                hz10sPostLightStd = std(hz10sPostLightBySweep);

                % determine light effect
                if hzDuringLightMean < hzPreLightMean - 2*hzPreLightStd
                    lightEffect = -1;
                elseif hzDuringLightMean > hzPreLightMean + 2*hzPreLightStd
                    lightEffect = +1;
                else 
                    lightEffect = 0;
                end

                % determine recovery 10s after light
                if hz10sPostLightStd >= hzPreLightMean - 2*hzPreLightStd && hz10sPostLightStd <= hzPreLightMean + 2*hzPreLightStd
                    recovery10sAfterLight = 1;
                else 
                    recovery10sAfterLight = 0;
                end

                % organize data for histogram (counting APs accross all
                % sweeps)
                edges = xMinInSec:lightPulseDurInSecs:xMaxInSec;
                [N, edges] = histcounts(allTimeStamps,edges);
                firingHz = (1/lightPulseDurInSecs)*N/nSweeps;
                
                if plotFigs == 1
                    % quality control of bandpass filter
                    figure('name',strcat(prefix,'_filter_qc'))
                        subplot(2,1,1)
                            plot(xAxis,yFilteredFirstSweep,'b')
                            hold on;
                            plot(xAxis,d(:,mainDataCh,1),'r')
                            hold off;
                            axis([xMinInSec xMaxInSec -inf inf])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                            title(prefix,'Interpreter','none');
                        subplot(2,1,2)
                            plot(xAxis,yFilteredLastSweep,'b')
                            hold on;
                            plot(xAxis,d(:,mainDataCh,nSweeps),'r')
                            hold off;
                            axis([xMinInSec xMaxInSec -inf inf])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                
                    % quality control of found APs
                    figure('name', strcat(prefix, '_AP_qc'))
                        subplot(2,1,1)
                            plot(xAxis,yFilteredFirstSweep)
                            hold on;
                            plot(locsFirst,-pksFirst,'o')
                            yline(-minPeakHeight)
                            hold off;
                            axis([xMinInSec xMaxInSec yMin yMax])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                            title(prefix,'Interpreter','none');
                        subplot(2,1,2)
                            plot(xAxis,yFilteredLastSweep)
                            hold on;
                            plot(locsLast,-pksLast,'o')
                            yline(-minPeakHeight)
                            hold off;
                            axis([xMinInSec xMaxInSec yMin yMax])
                            ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                            xlabel('Time (s)');
                    
                    % niceplot
                    figure('name', strcat(prefix, '_AP_raster'));
                        subplot(3,1,1)
                            % plot example trace
                            plot(xAxis,bandpass(d(:,mainDataCh,1),[highpassThreshold lowpassThreshold],samplingFrequency),'k','LineWidth',0.5)
                            if ~isempty(lightPulseStartInSecs)
                                rectangle('Position', [lightPulseStartInSecs yMin lightPulseDurInSecs yRange], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');
                            end
                            axis([xMinInSec xMaxInSec yMin yMax])
                            set(gca,'Visible','off');
                            % scale bars
                            line([xMaxInSec-xScaleBar/1000 xMaxInSec],[yMin yMin],'Color','k')
                            line([xMaxInSec xMaxInSec],[yMin yMin+yScaleBar],'Color','k')
                            text(xMaxInSec-xRange/10, yMin+yRange*7/100, strcat(num2str(xScaleBar), " ms"));
                            text(xMaxInSec-xRange/10, yMin+yRange*14/100, strcat(num2str(yScaleBar), " ", cell2mat(h.recChUnits(mainDataCh))));  
                        subplot(3,1,2)
                            % plot AP raster for all sweeps
                            for sweep = 1:nSweeps
                                plot(cell2mat(tsBySweep(sweep)), cell2mat(sweepNumberArrayBySweep(sweep)), '|', 'Color', 'k')
                                hold on;
                            end    
                            % adding light stim
                            if ~isempty(lightPulseStartInSecs)
                                rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs nSweeps+1], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');    
                            end
                            % adding finishing touches to plot
                            hold off;
                            axis([xMinInSec xMaxInSec 0 nSweeps+1])
                            ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                            yticks([]);
                            xticks([]);
                            set(gca, 'YDir','reverse');
                            xlabel('Time (s)');  
                        subplot(3,1,3)
                            % plot histogram and 2*SD criteria
                            hold on;                    
                            histogram('BinEdges', xMinInSec:lightPulseDurInSecs:xMaxInSec, 'BinCounts', firingHz, 'DisplayStyle', 'stairs', 'EdgeColor', 'k'); 
                            % plot light stim as rectangle
                            rectangle('Position', [lightPulseStartInSecs 0 lightPulseDurInSecs ymaxhist], 'FaceAlpha', 0.5, 'FaceColor', ostimColor, 'EdgeColor', 'none');                       
                            % plot Hz mean as horizontal line
                            yline(hzPreLightMean, '--');
                            % plot +- 2 SD as rectangle around mean
                            % [x y width height]
                            rectangle('Position', [0 hzPreLightMean-(2*hzPreLightStd) 30 4*hzPreLightStd], 'FaceAlpha', 0.1, 'FaceColor', [0 0 0], 'EdgeColor', 'none');
                            xlabel('Time (s)');
                            ylabel('Firing rate (Hz)');
                            axis([xMinInSec xMaxInSec 0 ymaxhist])
                            yticks([0 ymaxhist]);
                            hold off;
                            title(prefix,'Interpreter','none');
                end
            end

            % save data for exporting later
            if recordingType == "WC_CC" | recordingType == "LS_VC" | recordingType == "LS_CC"
                % I had to use convertCharsToStrings because the function
                % "table" does not like chars, but it accepts strings
                mouseNameByFile = [mouseNameByFile; convertCharsToStrings(mouseName)];
                mouseSexByFile = [mouseSexByFile; convertCharsToStrings(mouseSex)];
                cellNameByFile = [cellNameByFile; convertCharsToStrings(cellName)];
                opsinExpressionByFile = [opsinExpressionByFile; convertCharsToStrings(opsinExpression)];
                LEDcolorByFile = [LEDcolorByFile; convertCharsToStrings(LEDcolor)];
                LEDpowerByFile = [LEDpowerByFile; convertCharsToStrings(LEDpower)];
                recordingTypeByFile = [recordingTypeByFile; convertCharsToStrings(recordingType)];
                abfFileNameByFile = [abfFileNameByFile; convertCharsToStrings(abfFileName)];
                sweepDurationInSecondsByFile = [sweepDurationInSecondsByFile; sweepDurationInSeconds];
                lightPulseDurInSecsByFile = [lightPulseDurInSecsByFile; lightPulseDurInSecs];
                hzPreLightMeanByFile = [hzPreLightMeanByFile; hzPreLightMean]; 
                hzPreLightStdByFile = [hzPreLightStdByFile; hzPreLightStd];                 
                hzDuringLightMeanByFile = [hzDuringLightMeanByFile; hzDuringLightMean];               
                hzDuringLightStdByFile = [hzDuringLightStdByFile; hzDuringLightStd];
                hzPostLightMeanByFile = [hzPostLightMeanByFile; hzPostLightMean];
                hzPostLightStdByFile = [hzPostLightStdByFile; hzPostLightStd];
                hz10sPostLightMeanByFile = [hz10sPostLightMeanByFile; hz10sPostLightMean];
                hz10sPostLightStdByFile = [hz10sPostLightStdByFile; hz10sPostLightStd];
                lightEffectByFile = [lightEffectByFile; lightEffect];
                recovery10sAfterLightByFile = [recovery10sAfterLightByFile; recovery10sAfterLight];
            end
        end

        if saveFigs == 1
            saveAllFigs(saveDir); close all
        end

        if saveData == 1
            % only try to save data if you actually have data to save
            if length(hzPreLightMeanByFile)>=1

                % use "categorical" so that table output will not have quotes around strings                
                mouse = categorical(mouseNameByFile);
                sex = categorical(mouseSexByFile);
                cell = categorical(cellNameByFile);
                opsin = categorical(opsinExpressionByFile);
                color = categorical(LEDcolorByFile);
                power = categorical(LEDpowerByFile);
                type = categorical(recordingTypeByFile);
                abf = categorical(abfFileNameByFile);

                spontFiringDataAsTable = table(mouse,...
                    sex,...
                    cell,...
                    opsin,...
                    color,...
                    power,...
                    type,...
                    abf,...
                    sweepDurationInSecondsByFile,...
                    lightPulseDurInSecsByFile,...
                    hzPreLightMeanByFile,...
                    hzPreLightStdByFile,...
                    hzDuringLightMeanByFile,...
                    hzDuringLightStdByFile,...
                    hzPostLightMeanByFile,...
                    hzPostLightStdByFile,...
                    hz10sPostLightMeanByFile,...
                    hz10sPostLightStdByFile,...
                    lightEffectByFile,...
                    recovery10sAfterLightByFile);

                fulldirectory = fullfile(saveDir,strcat(analysisDate, "_ephys_database_spont_firing.xls"));
                if analyzeOnlyOneRow == 1
                    fulldirectory = fullfile(saveDir,strcat(analysisDate, "_ephys_database_spont_firing_ONE_BOI.xls"));
                    disp('yo copy this data into the main data OR ELSE')
                end
                writetable(spontFiringDataAsTable, fulldirectory, 'WriteMode', 'overwritesheet');
                disp('I saved the cell spont firing  xls file')
            end
        end
    end
end

