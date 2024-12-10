function firingSpaghettiOpsin(cohort, notconnected_data, connected_data, normalized)

[notconnected_mean_data, notconnected_preLightHzMean, notconnected_duringLightHzMean, notconnected_postLightHzMean] = firingSpaghettiOpsinPrep(notconnected_data, normalized);
[connected_mean_data, connected_preLightHzMean, connected_duringLightHzMean, connected_postLightHzMean] = firingSpaghettiOpsinPrep(connected_data, normalized);

% get today's date for naming output files
analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

if normalized == 0
    ymax = 60;
    ylabelToUse = "Firing rate (Hz)";
else
    ymax = 2;
    ylabelToUse = "Normalized firing rate";
end

%% generate fig with all data
figure('name', strcat("firingSpaghetti_all_", analysisDate, "_", cohort), 'Units', 'points');
hold on;
set(gcf,'OuterPosition',[0 100 110 222]);
set(gca,'FontName','Arial');
set(gca,'TickLength', [0.025, 0.025]);
set(gca,'LineWidth', 0.75);
axis([0.5 3.5 -1 ymax]);
set(gca,'YTick',0:ymax:ymax);

% plot not connected cell data in black
for row = 1:size(notconnected_mean_data,1)
    scatter([1:3], notconnected_mean_data(row,:), 25, [0 0 0], 'filled', 'MarkerFaceAlpha', 0.7);
    plot(notconnected_mean_data(row,:), 'color', [0 0 0 0.7]);
end

% plot connected cell data in pink
for row = 1:size(connected_mean_data,1)
    scatter([1:3], connected_mean_data(row,:), 25, [204/255, 121/255, 167/255], 'filled', 'MarkerFaceAlpha', 0.7);
    plot(connected_mean_data(row,:), 'color', [204/255, 121/255, 167/255 0.7]);
end

ylabel(ylabelToUse);
xticklabels({'OFF','ON','OFF (10s later)'});
% yticklabels({'0','','','60'});
set(findall(gcf,'-property','FontSize'),'FontSize',9)
hold off;


%% generate fig with not connectet only
figure('name', strcat("firingSpaghetti_opsin_neg_", analysisDate, "_", cohort), 'Units', 'points');
hold on;
set(gcf,'OuterPosition',[200 100 110 222]);
set(gca,'FontName','Arial');
set(gca,'TickLength', [0.025, 0.025]);
set(gca,'LineWidth', 0.75);
axis([0.5 3.5 -1 ymax]);
set(gca,'YTick',0:ymax:ymax);

% plot opsin negative cell data in black
for row = 1:size(notconnected_mean_data,1)
    scatter([1:3], notconnected_mean_data(row,:), 25, [0 0 0], 'filled', 'MarkerFaceAlpha', 0.7);
    plot(notconnected_mean_data(row,:), 'color', [0 0 0 0.7]);
end

ylabel(ylabelToUse);
xticklabels({'OFF','ON','OFF (10s later)'});
% yticklabels({'0','','','60'});
set(findall(gcf,'-property','FontSize'),'FontSize',9)
hold off;


%% generate fig with connected data only
figure('name', strcat("firingSpaghetti_opsin_pos_", analysisDate, "_", cohort), 'Units', 'points');
hold on;
set(gcf,'OuterPosition',[400 100 110 222]);
set(gca,'FontName','Arial');
set(gca,'TickLength', [0.025, 0.025]);
set(gca,'LineWidth', 0.75);
axis([0.5 3.5 -1 ymax]);
set(gca,'YTick',0:ymax:ymax);

% plot opsin positive cell data in pink
for row = 1:size(connected_mean_data,1)
    scatter([1:3], connected_mean_data(row,:), 25, [204/255, 121/255, 167/255], 'filled', 'MarkerFaceAlpha', 0.7);
    plot(connected_mean_data(row,:), 'color', [204/255, 121/255, 167/255 0.7]);
end

ylabel(ylabelToUse);
xticklabels({'OFF','ON','OFF (10s later)'});
% yticklabels({'0','','','60'});
set(findall(gcf,'-property','FontSize'),'FontSize',9)
hold off;


end
