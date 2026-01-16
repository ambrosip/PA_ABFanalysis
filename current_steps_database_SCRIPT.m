
clear all;
close all;

%% USER INPUT

databaseFile = 'M:\EphysData\Ephys Database.xlsx';
sheetName = 'TH Gq-DREADDs';
saveDir = "C:\Users\ambrosi\OHSU Dropbox\Priscilla Ambrosi\Dropbox - Moss Lab\Lab - Data summaries\2026-01-15 ephys dreadds";
firstRow = 1;          % set firstRow to be analyzed - remember to account for header when counting rows!
analyzeOnlyOneRow = 0;  % 1 (yes) or 0 (no)
saveFigs = 1;
saveData = 1;
plot_QC = 1;
plotFigs = 1;

% default parameters (will be overwritten by database)
mainDataCh = 1;             % channel with recording from cell
cmdCh = 2;                  % channel with current command
xMinInSec = 0;
xMaxInSec = 20;
yMin = -100;                % in pA or mV
yMax = 20;                  % in pA or mV
plot_cmd = 0;
yMin_cmd = -100;            % in pA
yMax_cmd = 250;             % in pA
smoothSpan = 5;             % in data pts
minPeakHeight = -20;        % amplitude threshold
minPeakDistance = 0.005;   % in seconds
example_sweep = 1;
cmd_y_scaleBarSize = 25;    % in pA
data_y_scaleBarSize = 10;   % in pA
time_scaleBarSize = 1;      % in s

% affects data viz
xScaleBar = 500;
yMinWC_CC = -100;
yMaxWC_CC = 40;
yScaleBarWC_CC = 10;
ymaxhist = 50;

% affects AP detection
minPeakHeight_WC_CC = -20;  % FYI code looks for peaks


%% GATHER DATA FROM DATABASE

% save importing options so we can change them
opts = detectImportOptions(databaseFile, 'Sheet', sheetName);

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

% if user only wants to analye 1 row, overwrite the variable "rows"
if analyzeOnlyOneRow == 1
    rows = firstRow;
end

% get path of database file to figure out path of raw data files
[filepath,name,ext]=fileparts(databaseFile);


%% CREATE MATRICES that may or may not be filled later

mouseNameByFile = [];
cellNameByFile = [];
dreaddsExpressionByFile = [];
recordingTypeByFile = [];
abfFileNameByFile = [];
sweepNumberByFile = [];
dreaddsActiveByFile = [];
sweepDurationInSecondsByFile = [];
firingRateMeanByFile = [];
currentPulseDurInSecsByFile = [];
currentPulseAmplitudeByFile = [];


%% PROCESS DATA FROM DATABASE

% get analysis date
analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

% iterate through every row
for row=firstRow:rows

    % ASSUMPTION: rec_type is written in the format "ON_CC_spont"
    rec_type = cell2mat(database.rec_type(row));
    recordingType = rec_type;

    % only look into cells that were NOT exluded & fit the parameters of
    % this code
    if cell2mat(database.analyze(row)) == "y" &&...
            rec_type == "WC_CC_step"
            
        % collect basic info from database
        mouseNumber = database.m(row);
        % pad mouse number with zeros (if needed) to get 4 digits
        mouseName = sprintf('m%04d',mouseNumber);  
        % keep collecting info
        dateRecorded = database.date_recorded(row);
        cellName = cell2mat(database.cell(row));
        dreadds_Expression = cell2mat(database.dreadds_pos(row));
        dreadds_Type = cell2mat(database.dreadds_type(row));
        if dreadds_Expression == 'n'
            dreaddsExpression = "DREADDS-NEG";
        elseif dreadds_Type == "Gq"
            dreaddsExpression = "DREADDS-Gq-POS";
        elseif dreadds_Type == "Gi"
            dreaddsExpression = "DREADDS-Gi-POS";
        end        
        dreadds_active = cell2mat(database.dreadds_active(row));
        mainDataCh = database.mainDataCh(row);
        cmdCh = database.cmdCh(row);
        xMinInSec = database.xMinInSec(row);
        xMaxInSec = database.xMaxInSec(row);
        yMin = database.yMin(row);
        yMax = database.yMax(row);
        plot_cmd = database.plot_cmd(row);
        yMin_cmd = database.yMin_cmd(row);
        yMax_cmd = database.yMax_cmd(row);
        smoothSpan = database.smoothSpan(row);
        minPeakHeight = database.minPeakHeight(row);
        minPeakDistance = database.minPeakDistance(row);
        example_sweep = database.example_sweep(row);
        cmd_y_scaleBarSize = database.cmd_y_scaleBarSize(row);
        data_y_scaleBarSize = database.data_y_scaleBarSize(row);
        time_scaleBarSize = database.time_scaleBarSize(row);

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
            str = [mouseName, cellName, dreaddsExpression, recordingType, abfFileName];
            prefix = join(str,'_');

            % this is the full path to the file that will be analyzed
            fileDir = fullfile(abfFilesDir,abfFileName);

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

            % find current step info
            % rationale: I am looking for a big change in the derivative 
            % of the cmd channel
            % ASSUMPTIONs: light stim timing is the same in all sweeps
            % I will analyze the last sweep because it will be the one with
            % the largest current step
            currentPulseStartInDataPts = find(diff(d(:,cmdCh,nSweeps))>10,1);
            currentPulseStartInSecs = currentPulseStartInDataPts/samplingFrequency;
            currentPulseEndInDataPts = find(diff(d(:,cmdCh,nSweeps))<-10,1);
            currentPulseEndInSecs = currentPulseEndInDataPts/samplingFrequency;
            currentPulseDurInSecs = currentPulseEndInSecs - currentPulseStartInSecs;

            if ~isempty(currentPulseStartInSecs)
                xMinInSec = currentPulseStartInSecs - currentPulseDurInSecs;
                xMaxInSec = currentPulseStartInSecs + 2*currentPulseDurInSecs;
            end
            
            % plot quality control plots or not
            if plot_QC == 1
            
                % plot all the channels and sweeps overlayed
                figure('name',strcat(prefix,'_all'))
                for channel=1:nChannels
                    subplot(nChannels,1,channel)
                    for sweep=1:nSweeps
                        yFiltered = smooth(d(:,channel,sweep),smoothSpan);
                        plot(xAxis,yFiltered,'Color',[0, 0, 0, 0.25]);
                        hold on;
                    end
                    ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"));
                    axis([xMinInSec xMaxInSec -inf inf])
                    xline(currentPulseStartInSecs);
                    xline(currentPulseEndInSecs);
                    title(prefix,'Interpreter','none');
                end
                xlabel('Time (s)');
                
                % % plot the 1st sweep of all the channels to compare filtered vs not
                % % filtered data
                % figure('name',strcat(prefix,'_filtered vs not'))
                % for channel=1:nChannels
                %     subplot(nChannels,1,channel)
                %     plot(xAxis,d(:,channel,1),'Color','b');
                %     hold on;
                %     yFiltered = smooth(d(:,channel,1),smoothSpan);
                %     plot(xAxis,yFiltered,'Color','r');
                %     hold off;
                %     ylabel(strcat(cell2mat(h.recChNames(channel)), " (", (cell2mat(h.recChUnits(channel))), ")"));
                %     axis([xMinInSec xMaxInSec -inf inf])
                % end
                % xline(currentPulseStartInSecs);
                % xline(currentPulseEndInSecs);
                % xlabel('Time (s)');     
                % title(prefix,'Interpreter','none');
            end

            % create arrays that will be filled
            tsBySweep = cell(1,nSweeps);
            sweepNumberArrayBySweep = cell(1,nSweeps);
            firingRateMeanBySweep = zeros(nSweeps,1);
            allTimeStampsBySweep = [];
            mouseNameBySweep = [];
            cellNameBySweep = [];
            dreaddsExpressionBySweep = [];
            recordingTypeBySweep = [];
            abfFileNameBySweep = [];
            sweepDurationInSecondsBySweep = [];
            dreaddsActiveBySweep = [];
            currentPulseDurInSecsBySweep = [];
            currentPulseAmplitudeBySweep = [];

            % iterate through sweeps to find action potentials
            for sweep=1:nSweeps

                yFiltered = smooth(d(:,mainDataCh,sweep),smoothSpan);
                [pks,locs,w,p] = findpeaks(yFiltered,xAxis,'MinPeakHeight',minPeakHeight,'MinPeakDistance',minPeakDistance);
                sweepNumberArray = sweep.* ones(length(locs),1);           
                
                % collect sweep-by-sweep data
                tsBySweep{1,sweep} = locs;
                sweepNumberArrayBySweep{1,sweep} = sweepNumberArray;

                % count APs during current pulse 
                idxToKeep = locs>=currentPulseStartInSecs & locs<=currentPulseEndInSecs;
                locs = locs(idxToKeep);
                pks = pks(idxToKeep);
                firingRateMeanBySweep(sweep,1) = size(locs,1) / currentPulseDurInSecs;  % in Hz

                % store all APs timestamps
                allTimeStampsBySweep = [allTimeStampsBySweep; locs];

                % get current step amplitute (rounded to the nearest 5)
                currentPulseAmplitudeBySweep = [currentPulseAmplitudeBySweep;...
                    round(mean(d(currentPulseStartInDataPts:currentPulseEndInDataPts,cmdCh,sweep))/5)*5];
                
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

                % save example sweep (for plotting later)
                if sweep == example_sweep
                    yFilteredExampleSweep = yFiltered;
                    pksExample = pks;
                    locsExample = locs;
                end

                % I had to use convertCharsToStrings because the function
                % "table" does not like chars, but it accepts strings
                mouseNameBySweep = [mouseNameBySweep; convertCharsToStrings(mouseName)];
                cellNameBySweep = [cellNameBySweep; convertCharsToStrings(cellName)];
                dreaddsExpressionBySweep = [dreaddsExpressionBySweep; convertCharsToStrings(dreaddsExpression)];
                recordingTypeBySweep = [recordingTypeBySweep; convertCharsToStrings(recordingType)];
                abfFileNameBySweep = [abfFileNameBySweep; convertCharsToStrings(abfFileName)];
                sweepDurationInSecondsBySweep = [sweepDurationInSecondsBySweep; sweepDurationInSeconds];
                dreaddsActiveBySweep = [dreaddsActiveBySweep; convertCharsToStrings(dreadds_active)];
                currentPulseDurInSecsBySweep = [currentPulseDurInSecsBySweep; currentPulseDurInSecs];
            end   

            if plotFigs == 1
                if plot_QC == 1
                    % % quality control of filter
                    % figure('name',strcat(prefix,'_filter_qc'))
                    %     subplot(2,1,1)
                    %         plot(xAxis,yFilteredExampleSweep,'b')
                    %         hold on;
                    %         plot(xAxis,d(:,mainDataCh,1),'r')
                    %         hold off;
                    %         axis([xMinInSec xMaxInSec -inf inf])
                    %         ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                    %         xlabel('Time (s)');
                    %         title(prefix,'Interpreter','none');
                    %     subplot(2,1,2)
                    %         plot(xAxis,yFilteredLastSweep,'b')
                    %         hold on;
                    %         plot(xAxis,d(:,mainDataCh,nSweeps),'r')
                    %         hold off;
                    %         axis([xMinInSec xMaxInSec -inf inf])
                    %         ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
                    %         xlabel('Time (s)');
                
                    % quality control of found APs
                    figure('name', strcat(prefix, '_AP_qc'))
                        subplot(2,1,1)
                            plot(xAxis,yFilteredExampleSweep)
                            hold on;
                            plot(locsExample,pksExample,'o')
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
                end
                
                % niceplot
                if plot_cmd == 1                    
                    figure('name', strcat(prefix, '_steps_firing_raster'));        
                    subplot(3,1,1)
                        % plot example traces
                        plot(xAxis,yFilteredExampleSweep,'k','LineWidth',0.5)
                        axis([xMinInSec xMaxInSec yMin yMax])
                        set(gca,'Visible','off');
                        % scale bars
                        line([xMaxInSec-2*time_scaleBarSize xMaxInSec],[yMin yMin],'Color','k')
                        line([xMaxInSec xMaxInSec],[yMin yMin + data_y_scaleBarSize],'Color','k')
                        text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize/2, strcat(num2str(time_scaleBarSize), " s"))                       
                        text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize, strcat(num2str(data_y_scaleBarSize), " ", cell2mat(h.recChUnits(mainDataCh))))  
                        % -60 mV line
                        yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                        yline(0,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                        text(xMinInSec, yMin + 10, "lines @ 0 mV & -60 mV") 
                        title(prefix,'Interpreter','none');
                        set(findall(gca, 'type', 'text'), 'visible', 'on'); % Makes the title visible again
                    subplot(3,1,2)
                        % plot cmd traces for example
                        plot(xAxis,smooth(d(:,cmdCh,example_sweep),smoothSpan),'k','LineWidth',0.5)
                        axis([xMinInSec xMaxInSec yMin_cmd yMax_cmd])
                        set(gca,'Visible','off');
                        % scale bars
                        line([xMaxInSec-2*time_scaleBarSize xMaxInSec],[yMin_cmd yMin_cmd],'Color','k')
                        line([xMaxInSec xMaxInSec],[yMin_cmd yMin_cmd + cmd_y_scaleBarSize],'Color','k')
                        text(xMaxInSec-2*time_scaleBarSize, yMin_cmd + cmd_y_scaleBarSize/2, strcat(num2str(time_scaleBarSize), " s"))
                        text(xMaxInSec-2*time_scaleBarSize, yMin_cmd + cmd_y_scaleBarSize, strcat(num2str(cmd_y_scaleBarSize),  " ", cell2mat(h.recChUnits(cmdCh))))                
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
                    figure('name', strcat(prefix, '_steps_firing_raster'));                    
                    subplot(2,1,1)
                        % plot example traces
                        plot(xAxis,yFilteredExampleSweep,'k','LineWidth',0.5)
                        axis([xMinInSec xMaxInSec yMin yMax])
                        set(gca,'Visible','off');
                        % scale bars
                        line([xMaxInSec-time_scaleBarSize xMaxInSec],[yMin yMin],'Color','k')
                        line([xMaxInSec xMaxInSec],[yMin yMin + data_y_scaleBarSize],'Color','k')
                        text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize/2, strcat(num2str(time_scaleBarSize), " s"))
                        text(xMaxInSec-2*time_scaleBarSize, yMin + data_y_scaleBarSize, strcat(num2str(data_y_scaleBarSize), " ", cell2mat(h.recChUnits(mainDataCh))))   
                        % -60 mV line
                        yline(-60,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                        yline(0,'Color',[0, 0, 0, 0.5],'LineWidth',0.1)
                        text(xMinInSec, yMin + 10, "lines @ 0 mV & -60 mV") 
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
                        axis([xMinInSec xMaxInSec 0 nSweeps+1])
                        ylabel(strcat('Sweeps (', num2str(nSweeps), ')'));
                        yticks([]);
                        xticks([]);
                        set(gca, 'YDir','reverse');
                        xlabel('Time (s)');
                end
                % 
                % % organize data for histogram (counting APs accross all
                % % sweeps)
                % edges = xMinInSec:xMaxInSec;
                % [N, edges] = histcounts(allTimeStampsBySweep,edges);
                % firingHz = N/nSweeps;
                % 
                % figure('name', strcat(prefix, '_firing_histogram'));
                % % plot histogram and 2*SD criteria
                % hold on;                    
                % histogram('BinEdges', xMinInSec:xMaxInSec, 'BinCounts', firingHz, 'DisplayStyle', 'stairs', 'EdgeColor', 'k');                           
                % % plot Hz mean as horizontal line
                % yline(firingRateMeanBySweep(1,1), '--');
                % % plot +- 2 SD as rectangle around mean - ALERT: need to check the math here
                % % [x y width height]
                % rectangle('Position', [0 firingRateMeanBySweep(1,1)-(2*firingRateStd) xMaxInSec 4*firingRateStd], 'FaceAlpha', 0.1, 'FaceColor', [0 0 0], 'EdgeColor', 'none');
                % xlabel('Time (s)');
                % ylabel('Firing rate (Hz)');
                % axis([xMinInSec xMaxInSec 0 ymaxhist])
                % yticks([0 ymaxhist]);
                % hold off;
                % title(prefix,'Interpreter','none');
            end

            mouseNameByFile = [mouseNameByFile; mouseNameBySweep];
            cellNameByFile = [cellNameByFile; cellNameBySweep];
            dreaddsExpressionByFile = [dreaddsExpressionByFile; dreaddsExpressionBySweep];
            recordingTypeByFile = [recordingTypeByFile; recordingTypeBySweep];
            abfFileNameByFile = [abfFileNameByFile; abfFileNameBySweep];
            sweepNumberByFile = [sweepNumberByFile; (1:nSweeps)'];
            dreaddsActiveByFile = [dreaddsActiveByFile; dreaddsActiveBySweep];
            sweepDurationInSecondsByFile = [sweepDurationInSecondsByFile; sweepDurationInSecondsBySweep];
            firingRateMeanByFile = [firingRateMeanByFile; firingRateMeanBySweep];
            currentPulseDurInSecsByFile = [currentPulseDurInSecsByFile; currentPulseDurInSecsBySweep];
            currentPulseAmplitudeByFile = [currentPulseAmplitudeByFile; currentPulseAmplitudeBySweep];
        end

    else
        disp(strcat("no analyzable data for row ", num2str(row)))
    end

    % save figs if user wants it and you have figs to save
    if saveFigs == 1 && exist('mouseNumber','var')
        saveAllFigs(saveDir); close all
    end

    % save data if user wants it and you have data to save
    if saveData == 1 && exist('mouseNumber','var')

        % use "categorical" so that table output will not have quotes around strings                
        mouse = categorical(mouseNameByFile);
        cell_name = categorical(cellNameByFile);
        dreadds = categorical(dreaddsExpressionByFile);
        type = categorical(recordingTypeByFile);
        abf = categorical(abfFileNameByFile);
        dreadds_active = categorical(dreaddsActiveByFile);

        spontFiringDataAsTable = table(mouse,...
            cell_name,...
            dreadds,...
            type,...
            abf,...
            sweepNumberByFile,...
            dreadds_active,...
            sweepDurationInSecondsByFile,...
            currentPulseDurInSecsByFile,...
            currentPulseAmplitudeByFile,...
            firingRateMeanByFile);

        fulldirectory = fullfile(saveDir,strcat(analysisDate, "_ephys_database_current_steps.xls"));
        if analyzeOnlyOneRow == 1
            fulldirectory = fullfile(saveDir,strcat(analysisDate, "_ephys_database_current_steps_ONE_BOI.xls"));
            disp('yo copy this data into the main data OR ELSE')
        end
        writetable(spontFiringDataAsTable, fulldirectory, 'WriteMode', 'overwritesheet');
        disp('I saved the current steps  xls file')
    end
end
