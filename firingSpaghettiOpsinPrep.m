function [mean_data, preLightHzMean, duringLightHzMean, postLightHzMean] = firingSpaghettiOpsinPrep(mean_sd_data, normalized)
    if normalized == 0
        preLightHzMean = mean_sd_data(:,1);
        duringLightHzMean = mean_sd_data(:,3);
        postLightHzMean = mean_sd_data(:,5);
        mean_data = [preLightHzMean duringLightHzMean postLightHzMean];
    elseif normalized == 1
        preLightHzMean = mean_sd_data(:,1);
        duringLightHzMean = mean_sd_data(:,3);
        postLightHzMean = mean_sd_data(:,5);
        mean_data = [preLightHzMean./preLightHzMean duringLightHzMean./preLightHzMean postLightHzMean./preLightHzMean];
    end
end