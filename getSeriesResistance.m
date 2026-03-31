%% Get series resistance and intrinsic properties

% get the first data point with a significant drop in cmd voltage
rsTestPulseOnsetDataPoint = find(diff(yMean_cmd)<-0.5, 1);

if isempty(rsTestPulseOnsetDataPoint)
    disp("no test pulse found")
else
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

    % troubleshooting error "Array indices must be positive integers or logical values".
    rsBaselineDataPointInterval = round(rsBaselineDataPointInterval(1)):round(rsBaselineDataPointInterval(end));
    rsFirstTransientDataPointInterval = round(rsFirstTransientDataPointInterval(1)):round(rsFirstTransientDataPointInterval(end));
    rsPulseInterval = round(rsPulseInterval(1)):round(rsPulseInterval(end));
            
    % calculating series resistance from mean data
    rsBaselineCurrent = mean(yMean_main(rsBaselineDataPointInterval));  
    rsTransientCurrent = min(yMean_main(rsFirstTransientDataPointInterval));
    rsSteadyStateCurrent = mean(yMean_main(rsPulseInterval));
    dCurrentTransient = rsTransientCurrent-rsBaselineCurrent;
    dCurrentSteadyState = rsSteadyStateCurrent-rsBaselineCurrent;
    dVoltage = mean(yMean_cmd(rsPulseInterval)) - mean(yMean_cmd(rsBaselineDataPointInterval));
    seriesResistance = 1000 * dVoltage / dCurrentTransient; % mV/pA equals Gohm
    cellResistance = 1000 * dVoltage / dCurrentSteadyState;
    
    % niceplot WC VC
    if strcmp(cell2mat(h.recChUnits(params.mainDataCh)),'pA')
        figure('name',strcat(fileName,'_test pulse'))   
        subplot(3,1,[1,2])
            for sweep=1:nSweeps
                plot(xAxis,yFiltered_All(:,params.mainDataCh,sweep),'Color',[0, 0, 0, 0.25]);
                hold on;
            end
            plot(xAxis,yMean_main,'Color',[0, 0, 0, 1]);
            hold off;
            ylabel(strcat(cell2mat(h.recChNames(params.mainDataCh)), " (", (cell2mat(h.recChUnits(params.mainDataCh))), ")"));
            axis([rsTestPulseOnsetTime-0.05 rsTestPulseOffsetTime+0.05 params.yMin params.yMax])
            title([fileName '_test pulse'],'Interpreter','none');
    
        subplot(3,1,3)
            for sweep=1:nSweeps
                plot(xAxis,yFiltered_All(:,params.cmdCh,sweep),'Color',[0, 0, 0, 0.25]);
                hold on;
            end
            plot(xAxis,yMean_cmd,'Color',[0, 0, 0, 1]);
            hold off;
            ylabel(strcat(cell2mat(h.recChNames(params.cmdCh)), " (", (cell2mat(h.recChUnits(params.cmdCh))), ")"));
            axis([rsTestPulseOnsetTime-0.05 rsTestPulseOffsetTime+0.05 params.yMin_cmd params.yMax_cmd])   
        xlabel('Time (s)');
        set(gcf,'Position',[1000 50 350 400]);
    end
end

if build_structure == 1
    seriesResistance_thisFile = [firstSweepNum, relativeStartTime, seriesResistance]; 
    if ~isfield(s_ephys.(dateRecorded_fieldName).(mouseName).(cellName), 'seriesResistance')
        s_ephys.(dateRecorded_fieldName).(mouseName).(cellName).seriesResistance = seriesResistance_thisFile;
    else
        s_ephys.(dateRecorded_fieldName).(mouseName).(cellName).seriesResistance = [...
            s_ephys.(dateRecorded_fieldName).(mouseName).(cellName).seriesResistance;...
            seriesResistance_thisFile];
    end
end

