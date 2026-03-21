%% get opto data

% determine light channel
% 3 is B (blue)
% 4 is G (green) or GR (green-red)
if contains(protocol_name, "_B_")
    lightCh = 3;
else
    lightCh = 4;       
end

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

% niceplot
figure('name',strcat(fileName,'_opto niceplot'))
subplot(4,1,[1,2])
    for sweep=1:nSweeps
        plot(xAxis,yFiltered_All(:,mainDataCh,sweep),'Color',[0, 0, 0, 0.25]);
        hold on;
    end
    plot(xAxis,yMean_main,'Color',[0, 0, 0, 1]);
    hold off;
    ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"),"Interpreter","none");
    axis([xMin xMax yMin_main yMax_main])
    title([fileName '_niceplot'],'Interpreter','none');

subplot(4,1,3)
    for sweep=1:nSweeps
        plot(xAxis,yFiltered_All(:,cmdCh,sweep),'Color',[0, 0, 0, 0.25]);
        hold on;
    end
    plot(xAxis,yMean_cmd,'Color',[0, 0, 0, 1]);
    hold off;
    ylabel(strcat(cell2mat(h.recChNames(cmdCh)), " (", (cell2mat(h.recChUnits(cmdCh))), ")"),"Interpreter","none");
    axis([xMin xMax yMin_cmd yMax_cmd])

subplot(4,1,4)
    for sweep=1:nSweeps
        plot(xAxis,yFiltered_All(:,lightCh,sweep),'Color',[0, 0, 0, 0.25]);
        hold on;
    end
    plot(xAxis,yMean(:,lightCh),'Color',[0, 0, 0, 1]);
    hold off;
    ylabel(strcat(cell2mat(h.recChNames(lightCh)), " (", (cell2mat(h.recChUnits(lightCh))), ")"), "Interpreter","none");
    axis([xMin xMax yMinNiceplot_light yMaxNiceplot_light])        
    
xlabel('Time (s)');
set(gcf,'Position',[1000 50 350 400]);












% % ARCHIVE
% % niceplot WC CC
% if strcmp(cell2mat(h.recChUnits(mainDataCh)),'mV')
% 
%     figure('name',strcat(fileName,'_opto niceplot CC'))
% 
%         subplot(4,1,[1,2])
%             for sweep=1:nSweeps
%                 yFiltered_main = smooth(d(:,mainDataCh,sweep),smoothSpan);
%                 yFiltered_main_All(:,sweep) = yFiltered_main;
%                 plot(xAxis,yFiltered_main,'Color',[0, 0, 0, 0.25]);
%                 hold on;
%             end
%             yMean_main = sum(yFiltered_main_All,2)/nSweeps;
%             plot(xAxis,yMean_main,'Color',[0, 0, 0, 1]);
%             hold off;
%             ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%             axis([xMinInSecNiceplot_CC xMaxInSecNiceplot_CC -100 50])
%             title([fileName '_niceplot'],'Interpreter','none');
% 
%         subplot(4,1,3)
%             for sweep=1:nSweeps
%                 yFiltered_cmd = smooth(d(:,cmdCh,sweep),smoothSpan);
%                 yFiltered_cmd_All(:,sweep) = yFiltered_cmd;
%                 plot(xAxis,yFiltered_cmd,'Color',[0, 0, 0, 0.25]);
%                 hold on;
%             end
%             yMean_cmd = sum(yFiltered_cmd_All,2)/nSweeps;
%             plot(xAxis,yMean_cmd,'Color',[0, 0, 0, 1]);
%             hold off;
%             ylabel(strcat(cell2mat(h.recChNames(cmdCh)), " (", (cell2mat(h.recChUnits(cmdCh))), ")"));
%             axis([xMinInSecNiceplot_CC xMaxInSecNiceplot_CC -200 200])
% 
%         subplot(4,1,4)
%             for sweep=1:nSweeps
%                 yFiltered_light = smooth(d(:,lightCh,sweep),smoothSpan);
%                 yFiltered_light_All(:,sweep) = yFiltered_light;
%                 plot(xAxis,yFiltered_light,'Color',[0, 0, 0, 0.25]);
%                 hold on;
%             end
%             yMean_light = sum(yFiltered_light_All,2)/nSweeps;
%             plot(xAxis,yMean_light,'Color',[0, 0, 0, 1]);
%             hold off;
%             ylabel(strcat(cell2mat(h.recChNames(lightCh)), " (", (cell2mat(h.recChUnits(lightCh))), ")"));
%             axis([xMinInSecNiceplot_CC xMaxInSecNiceplot_CC yMinNiceplot_light yMaxNiceplot_light])
% 
%         xlabel('Time (s)');
%         set(gcf,'Position',[0 50 350 400]);
% 
% 
% elseif strcmp(cell2mat(h.recChUnits(mainDataCh)),'pA')
% 
%     figure('name',strcat(fileName,'_opto niceplot VC'))
% 
%         subplot(4,1,[1,2])
%             for sweep=1:nSweeps
%                 yFiltered_main = smooth(d(:,mainDataCh,sweep),smoothSpan);
%                 yFiltered_main_All(:,sweep) = yFiltered_main;
%                 plot(xAxis,yFiltered_main,'Color',[0, 0, 0, 0.25]);
%                 hold on;
%             end
%             yMean_main = sum(yFiltered_main_All,2)/nSweeps;
%             plot(xAxis,yMean_main,'Color',[0, 0, 0, 1]);
%             hold off;
%             ylabel(strcat(cell2mat(h.recChNames(mainDataCh)), " (", (cell2mat(h.recChUnits(mainDataCh))), ")"));
%             if size(yFiltered_main,1)/samplingFrequency >= xMaxInSecNiceplot_VC
%                 axis([xMinInSecNiceplot_VC xMaxInSecNiceplot_VC yMinNiceplot_main yMaxNiceplot_main])
%             else
%                 axis([xMinInSecNiceplot_VC inf yMinNiceplot_main yMaxNiceplot_main])
%             end
%             title([fileName '_niceplot'],'Interpreter','none');
% 
%         subplot(4,1,3)
%             for sweep=1:nSweeps
%                 yFiltered_cmd = smooth(d(:,cmdCh,sweep),smoothSpan);
%                 yFiltered_cmd_All(:,sweep) = yFiltered_cmd;
%                 plot(xAxis,yFiltered_cmd,'Color',[0, 0, 0, 0.25]);
%                 hold on;
%             end
%             yMean_cmd = sum(yFiltered_cmd_All,2)/nSweeps;
%             plot(xAxis,yMean_cmd,'Color',[0, 0, 0, 1]);
%             hold off;
%             ylabel(strcat(cell2mat(h.recChNames(cmdCh)), " (", (cell2mat(h.recChUnits(cmdCh))), ")"));
%             if size(yFiltered_main,1)/samplingFrequency >= xMaxInSecNiceplot_VC
%                 axis([xMinInSecNiceplot_VC xMaxInSecNiceplot_VC yMinNiceplot_cmd yMaxNiceplot_cmd])
%             else
%                 axis([xMinInSecNiceplot_VC inf yMinNiceplot_cmd yMaxNiceplot_cmd])
%             end
% 
%         subplot(4,1,4)
%             for sweep=1:nSweeps
%                 yFiltered_light = smooth(d(:,lightCh,sweep),smoothSpan);
%                 yFiltered_light_All(:,sweep) = yFiltered_light;
%                 plot(xAxis,yFiltered_light,'Color',[0, 0, 0, 0.25]);
%                 hold on;
%             end
%             yMean_light = sum(yFiltered_light_All,2)/nSweeps;
%             plot(xAxis,yMean_light,'Color',[0, 0, 0, 1]);
%             hold off;
%             ylabel(strcat(cell2mat(h.recChNames(lightCh)), " (", (cell2mat(h.recChUnits(lightCh))), ")"));
%             axis([xMinInSecNiceplot_VC xMaxInSecNiceplot_VC yMinNiceplot_light yMaxNiceplot_light])
% end
% 
% xlabel('Time (s)');
% set(gcf,'Position',[1000 50 350 400]);
