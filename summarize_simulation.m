function report = summarize_simulation(scenarioPath, varargin)
% SUMMARIZE_SIMULATION Reads simulator results and outputs a graphical dashboard
% and text summary of KPIs (MSE, RMSE, Max/Min error, Detection/False Alarm Rates).
%
% Inputs:
%   scenarioPath - Path to scenario folder containing Output/ directory
%
% Optional Name-Value Pairs:
%   'PosThreshold' - Threshold for position RMSE (meters) (default: 5.0)
%   'VelThreshold' - Threshold for velocity RMSE (m/s) (default: 5.0)
%   'DetThreshold' - Threshold for target detection rate (0-1) (default: 0.8)
%   'FaThreshold'  - Threshold for false alarm rate (0-1) (default: 0.5)
%   'Visible'      - Whether to display the plot figure ('on' or 'off') (default: 'off')
%
% Outputs:
%   report       - Struct containing all calculated KPIs

    p = inputParser;
    addRequired(p, 'scenarioPath', @(x) ischar(x) || isstring(x));
    addParameter(p, 'PosThreshold', 5.0, @isnumeric);
    addParameter(p, 'VelThreshold', 5.0, @isnumeric);
    addParameter(p, 'DetThreshold', 0.8, @isnumeric);
    addParameter(p, 'FaThreshold', 0.5, @isnumeric);
    addParameter(p, 'Visible', 'off', @(x) ismember(x, {'on','off'}));
    parse(p, scenarioPath, varargin{:});
    
    opts = p.Results;
    scenarioPath = char(scenarioPath);
    
    outputDir = fullfile(scenarioPath, 'Output');
    errorFile = fullfile(outputDir, 'error.csv');
    detStatsFile = fullfile(outputDir, 'detStats.csv');
    detectionFile = fullfile(outputDir, 'detection.json');
    bsFile = fullfile(scenarioPath, 'Input', 'bsConfig.txt');
    
    if ~exist(errorFile, 'file') || ~exist(detStatsFile, 'file') || ~exist(detectionFile, 'file')
        error('Required output files (error.csv, detStats.csv, detection.json) not found in %s.', outputDir);
    end
    
    % Read BS position
    if exist(bsFile, 'file')
        try
            bsPos = load(bsFile);
            bsPos = bsPos(1, 1:3); % Ensure 3D vector
        catch
            bsPos = [0, 0, 25];
        end
    else
        bsPos = [0, 0, 25];
    end
    
    % Read Data
    errorTable = readtable(errorFile);
    detStatsTable = readtable(detStatsFile);
    
    jsonStr = fileread(detectionFile);
    detectionData = jsondecode(jsonStr);
    
    % Compute Errors
    % 3D Position Error from components
    posError3D = sqrt(errorTable.positionErrorX.^2 + errorTable.positionErrorY.^2 + errorTable.positionErrorZ.^2);
    validPosIdx = ~isnan(posError3D);
    posErrors = posError3D(validPosIdx);
    
    velError1D = abs(errorTable.velocityError);
    validVelIdx = ~isnan(velError1D);
    velErrors = velError1D(validVelIdx);
    
    posErrorH = errorTable.positionErrorH(validPosIdx);
    posErrorV = abs(errorTable.positionErrorV(validPosIdx));
    
    % Check for empty case
    if isempty(posErrors)
        posErrors = 0;
    end
    if isempty(velErrors)
        velErrors = 0;
    end
    
    % Position Statistics
    pos_MSE = mean(posErrors.^2);
    pos_RMSE = sqrt(pos_MSE);
    pos_Mean = mean(posErrors);
    pos_Median = median(posErrors);
    pos_Max = max(posErrors);
    pos_Min = min(posErrors);
    
    % Velocity Statistics
    vel_MSE = mean(velErrors.^2);
    vel_RMSE = sqrt(vel_MSE);
    vel_Mean = mean(velErrors);
    vel_Max = max(velErrors);
    vel_Min = min(velErrors);
    
    % Detection Statistics
    total_TP = sum(detStatsTable.truePositive);
    total_FN = sum(detStatsTable.falseNegative);
    total_FP = sum(detStatsTable.falsePositve); % spelling matching 'falsePositve' in CSV
    
    if (total_TP + total_FN) > 0
        detection_rate = total_TP / (total_TP + total_FN);
    else
        detection_rate = 0;
    end
    
    if (total_TP + total_FP) > 0
        false_alarm_rate = total_FP / (total_TP + total_FP);
    else
        false_alarm_rate = 0;
    end
    
    avg_snr = mean(errorTable.snr, 'omitnan');
    
    % Pass/Fail Logic
    passPos = pos_RMSE <= opts.PosThreshold;
    passVel = vel_RMSE <= opts.VelThreshold;
    passDet = detection_rate >= opts.DetThreshold;
    passFA = false_alarm_rate <= opts.FaThreshold;
    
    overall_pass = passPos && passVel && passDet && passFA;
    
    % Construct Report Struct
    report = struct();
    report.scenarioName = scenarioPath;
    report.position = struct('MSE', pos_MSE, 'RMSE', pos_RMSE, 'Mean', pos_Mean, 'Median', pos_Median, 'Max', pos_Max, 'Min', pos_Min);
    report.velocity = struct('MSE', vel_MSE, 'RMSE', vel_RMSE, 'Mean', vel_Mean, 'Max', vel_Max, 'Min', vel_Min);
    report.detection = struct('TP', total_TP, 'FN', total_FN, 'FP', total_FP, ...
                              'DetectionRate', detection_rate, 'FalseAlarmRate', false_alarm_rate);
    report.avg_snr = avg_snr;
    report.pass = overall_pass;
    
    % Doppler Ambiguity Detection (Unambiguous velocity limit check)
    % Carrier frequency fc and periodicity from config
    % Standard 5G cell maximum velocity is usually around 37.5 m/s at 4GHz with 0.5ms slots
    v_unambig_limit = 37.5; 
    high_vel_targets = any(velErrors > v_unambig_limit);
    
    % Print console dashboard
    fprintf('\n============================================================\n');
    fprintf('           SIMULATION PERFORMANCE SUMMARY REPORT\n');
    fprintf('============================================================\n');
    fprintf('Scenario: %s\n', scenarioPath);
    if overall_pass
        fprintf('Status:   PASS\n');
    else
        fprintf('Status:   FAIL\n');
    end
    fprintf('------------------------------------------------------------\n');
    fprintf('KPI Metric            | Computed Value | Threshold | Status \n');
    fprintf('------------------------------------------------------------\n');
    
    % Helper function for status text
    statusText = @(p) char(iff(p, '  PASS  ', '  FAIL  '));
    
    fprintf('Position RMSE         | %8.3f m   | %7.2f m | %s\n', pos_RMSE, opts.PosThreshold, statusText(passPos));
    fprintf('Velocity RMSE         | %8.3f m/s | %7.2f m/s| %s\n', vel_RMSE, opts.VelThreshold, statusText(passVel));
    fprintf('Detection Rate        | %8.1f %%  | %7.1f %% | %s\n', detection_rate * 100, opts.DetThreshold * 100, statusText(passDet));
    fprintf('False Alarm Rate      | %8.1f %%  | %7.1f %% | %s\n', false_alarm_rate * 100, opts.FaThreshold * 100, statusText(passFA));
    fprintf('------------------------------------------------------------\n');
    fprintf('Position Min/Max/Med  | %8.3f m / %8.3f m / %8.3f m\n', pos_Min, pos_Max, pos_Median);
    fprintf('Velocity Min/Max/Mean | %8.3f m/s / %8.3f m/s / %8.3f m/s\n', vel_Min, vel_Max, vel_Mean);
    fprintf('Average SNR           | %8.2f dB\n', avg_snr);
    if high_vel_targets
        fprintf('\n[Insight] High Velocity RMSE detected. This is likely due to\n');
        fprintf('Doppler Ambiguity Wrapping as target radial speeds exceed the\n');
        fprintf('unambiguous limits (~%.1f m/s) of the configured PRS period.\n', v_unambig_limit);
    end
    fprintf('============================================================\n\n');
    
    % Generate plots
    fig = figure('Name', ['Simulation Summary - ' scenarioPath], ...
                 'Units', 'normalized', ...
                 'OuterPosition', [0.05 0.05 0.9 0.9], ...
                 'Visible', opts.Visible);
             
    % Modern styling colors
    darkBg = [0.08 0.09 0.13];
    cardBg = [0.12 0.14 0.20];
    textColor = [0.9 0.9 0.95];
    gridColor = [0.2 0.22 0.3];
    accentGreen = [0.18 0.8 0.44];
    accentRed = [0.9 0.3 0.25];
    accentBlue = [0.2 0.6 0.9];
    accentOrange = [0.9 0.6 0.2];
    
    set(fig, 'Color', darkBg);
    
    % Title Banner
    statusBanner = char(iff(overall_pass, 'PASS', 'FAIL'));
    bannerColor = iff(overall_pass, accentGreen, accentRed);
    annotation('textbox', [0.05, 0.93, 0.9, 0.05], ...
               'String', sprintf('Scenario: %s  |  Overall Status: %s  |  Position RMSE: %.2fm  |  Detection Rate: %.1f%%', ...
                                 scenarioPath, statusBanner, pos_RMSE, detection_rate*100), ...
               'Color', textColor, ...
               'FontSize', 14, ...
               'FontWeight', 'bold', ...
               'EdgeColor', 'none', ...
               'HorizontalAlignment', 'center', ...
               'BackgroundColor', cardBg);
           
    % 1. 3D Trajectory Plot
    subplot(3, 2, 1);
    hold on;
    grid on;
    box on;
    
    % Extract trajectories
    gtPositions = [];
    estPositions = [];
    
    for d = 1:numel(detectionData)
        if ~isempty(detectionData(d).gtPosition)
            gtPositions = [gtPositions; detectionData(d).gtPosition];
        end
        if isfield(detectionData(d), 'stPositionEstimate') && ~isempty(detectionData(d).stPositionEstimate)
            estPositions = [estPositions; detectionData(d).stPositionEstimate];
        end
    end
    
    if ~isempty(gtPositions)
        hGt = plot3(gtPositions(:,1), gtPositions(:,2), gtPositions(:,3), 'o-', ...
                    'Color', accentBlue, 'LineWidth', 2, 'MarkerSize', 4, 'MarkerFaceColor', accentBlue);
    end
    if ~isempty(estPositions)
        hEst = plot3(estPositions(:,1), estPositions(:,2), estPositions(:,3), 'x--', ...
                     'Color', accentGreen, 'LineWidth', 1.5, 'MarkerSize', 6);
    end
    
    title('3D Target Trajectories (Ground Truth vs Estimated)', 'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X Position (m)', 'Color', textColor);
    ylabel('Y Position (m)', 'Color', textColor);
    zlabel('Z Position (m)', 'Color', textColor);
    set(gca, 'Color', cardBg, 'XColor', textColor, 'YColor', textColor, 'ZColor', textColor, 'GridColor', gridColor);
    view(3);
    if ~isempty(gtPositions) && ~isempty(estPositions)
        legend([hGt, hEst], {'Ground Truth', 'Estimated'}, 'TextColor', textColor, 'Color', cardBg, 'EdgeColor', gridColor);
    end
    
    % 2. Position Error CDF
    subplot(3, 2, 2);
    hold on;
    grid on;
    box on;
    
    if ~isempty(posErrors)
        sortedPosErrors = sort(posErrors);
        cdfY = (1:numel(sortedPosErrors)) / numel(sortedPosErrors);
        plot(sortedPosErrors, cdfY, 'Color', accentBlue, 'LineWidth', 2.5);
        
        % Vertical line for RMSE
        plot([pos_RMSE, pos_RMSE], [0, 1], 'Color', accentOrange, 'LineWidth', 1.5, 'LineStyle', '--');
        text(pos_RMSE + 0.1, 0.5, sprintf('RMSE: %.2fm', pos_RMSE), 'Color', accentOrange, 'FontSize', 9);
        
        % Vertical line for Median
        plot([pos_Median, pos_Median], [0, 1], 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5, 'LineStyle', '-.');
        text(pos_Median - 1.2, 0.7, sprintf('Median: %.2fm', pos_Median), 'Color', [0.7 0.7 0.7], 'FontSize', 9);
        
        % Vertical line for threshold
        plot([opts.PosThreshold, opts.PosThreshold], [0, 1], 'Color', accentRed, 'LineWidth', 1.5, 'LineStyle', ':');
        text(opts.PosThreshold + 0.1, 0.2, sprintf('Threshold: %.1fm', opts.PosThreshold), 'Color', accentRed, 'FontSize', 9);
    end
    
    title('3D Position Error CDF', 'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('3D Position Error (m)', 'Color', textColor);
    ylabel('Cumulative Probability', 'Color', textColor);
    set(gca, 'Color', cardBg, 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
    xlim([0, max([opts.PosThreshold * 1.5, pos_Max])]);
    ylim([0 1.05]);
    
    % 3. Tracking Errors vs. Drop Index
    subplot(3, 2, 3);
    hold on;
    grid on;
    box on;
    
    if ismember('timeIndex', errorTable.Properties.VariableNames)
        tIdx = errorTable.timeIndex;
    else
        tIdx = (1:height(errorTable)).';
    end
    
    uniqueT = unique(tIdx);
    avgPosErrorT = zeros(size(uniqueT));
    avgVelErrorT = zeros(size(uniqueT));
    for ti = 1:numel(uniqueT)
        idxT = (tIdx == uniqueT(ti));
        avgPosErrorT(ti) = mean(posError3D(idxT), 'omitnan');
        avgVelErrorT(ti) = mean(abs(errorTable.velocityError(idxT)), 'omitnan');
    end
    
    yyaxis left;
    plot(uniqueT, avgPosErrorT, '.-', 'Color', accentGreen, 'LineWidth', 1.5, 'MarkerSize', 8);
    ylabel('Avg Position Error (m)', 'Color', accentGreen);
    set(gca, 'YColor', accentGreen);
    
    yyaxis right;
    plot(uniqueT, avgVelErrorT, '.-', 'Color', accentRed, 'LineWidth', 1.5, 'MarkerSize', 8);
    ylabel('Avg Velocity Error (m/s)', 'Color', accentRed);
    set(gca, 'YColor', accentRed);
    
    title('Tracking Error vs. Drop Index', 'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Simulation Drop Index', 'Color', textColor);
    set(gca, 'Color', cardBg, 'XColor', textColor, 'GridColor', gridColor);
    
    % 4. Detection Statistics per Drop
    subplot(3, 2, 4);
    hold on;
    grid on;
    box on;
    
    barData = [detStatsTable.truePositive, detStatsTable.falseNegative, detStatsTable.falsePositve];
    hBar = bar(barData, 'stacked', 'EdgeColor', 'none');
    set(hBar(1), 'FaceColor', accentGreen);
    set(hBar(2), 'FaceColor', accentRed * 0.7);
    set(hBar(3), 'FaceColor', accentOrange);
    
    title('Detection Statistics per Drop', 'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Simulation Drop Index', 'Color', textColor);
    ylabel('Number of Targets', 'Color', textColor);
    set(gca, 'Color', cardBg, 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
    legend({'True Positives', 'False Negatives (Missed)', 'False Positives (False Alarms)'}, ...
           'TextColor', textColor, 'Color', cardBg, 'EdgeColor', gridColor, 'Location', 'NorthEast');
       
    % 5. SNR vs Range Scatter Plot
    subplot(3, 2, 5);
    hold on;
    grid on;
    box on;
    
    % Extract true ranges and SNRs
    ranges = [];
    snrs = [];
    
    row_counter = 1;
    for d = 1:numel(detectionData)
        gt = detectionData(d).gtPosition;
        N_tgt = size(gt, 1);
        for t = 1:N_tgt
            if row_counter <= height(errorTable)
                val_range = norm(gt(t, :) - bsPos);
                val_snr = errorTable.snr(row_counter);
                if ~isnan(val_snr)
                    ranges = [ranges; val_range];
                    snrs = [snrs; val_snr];
                end
            end
            row_counter = row_counter + 1;
        end
    end
    
    if ~isempty(ranges)
        scatter(ranges, snrs, 30, accentBlue, 'filled', 'MarkerFaceAlpha', 0.6);
        % Fit trendline
        p_fit = polyfit(ranges, snrs, 1);
        r_grid = linspace(min(ranges), max(ranges), 100);
        plot(r_grid, polyval(p_fit, r_grid), 'Color', accentGreen, 'LineWidth', 2);
        
        title(sprintf('Target SNR vs. Range (Path Loss Trend: %.1f dB/100m)', p_fit(1)*100), ...
              'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    else
        title('Target SNR vs. Range', 'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    end
    xlabel('Target Range from Base Station (m)', 'Color', textColor);
    ylabel('Detection SNR (dB)', 'Color', textColor);
    set(gca, 'Color', cardBg, 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
    
    % 6. Horizontal vs. Vertical Error Comparison
    subplot(3, 2, 6);
    hold on;
    grid on;
    box on;
    
    if ~isempty(posErrorH)
        scatter(posErrorH, posErrorV, 35, accentOrange, 'filled', 'MarkerFaceAlpha', 0.5);
        % Plot diagonal reference line (y=x)
        max_err_val = max([max(posErrorH), max(posErrorV)]);
        plot([0, max_err_val], [0, max_err_val], 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
        
        title(sprintf('Horizontal vs. Vertical Error (Avg: H=%.2fm, V=%.2fm)', mean(posErrorH), mean(posErrorV)), ...
              'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    else
        title('Horizontal vs. Vertical Error', 'Color', textColor, 'FontSize', 11, 'FontWeight', 'bold');
    end
    xlabel('Horizontal Position Error (m)', 'Color', textColor);
    ylabel('Vertical Position Error (m)', 'Color', textColor);
    set(gca, 'Color', cardBg, 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
    xlim([0, max([opts.PosThreshold, max(posErrorH)])]);
    ylim([0, max([opts.PosThreshold, max(posErrorV)])]);
    
    % Save figure
    saveas(fig, fullfile(outputDir, 'summary_dashboard.png'));
    close(fig);
    fprintf('Dashboard saved to: %s\n', fullfile(outputDir, 'summary_dashboard.png'));
end

function val = iff(cond, trueVal, falseVal)
    if cond
        val = trueVal;
    else
        val = falseVal;
    end
end
