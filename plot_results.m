function plot_results(scenarioPath)
    if nargin < 1
        scenarioPath = 'examples/uma_trp1_3gpp';
    end
    
    outputPath = fullfile(scenarioPath, 'Output');
    jsonPath = fullfile(outputPath, 'detection.json');
    csvPath = fullfile(outputPath, 'error.csv');
    
    if ~exist(jsonPath, 'file')
        error('detection.json not found in %s', outputPath);
    end
    
    % Read detection JSON using MATLAB's jsondecode
    fid = fopen(jsonPath, 'r');
    raw = fread(fid, inf, '*char').';
    fclose(fid);
    data = jsondecode(raw);
    
    % Gather all gtPosition and stPositionEstimate
    gtAll = [];
    estAll = [];
    
    for k = 1:numel(data)
        if isfield(data(k), 'gtPosition') && ~isempty(data(k).gtPosition)
            gtAll = [gtAll; data(k).gtPosition];
        end
        if isfield(data(k), 'stPositionEstimate') && ~isempty(data(k).stPositionEstimate)
            estAll = [estAll; data(k).stPositionEstimate];
        end
    end
    
    % Create 3D Trajectory Figure
    fig1 = figure('Visible', 'off');
    hold on;
    if ~isempty(gtAll)
        scatter3(gtAll(:,1), gtAll(:,2), gtAll(:,3), 40, 'b', 'filled', 'DisplayName', 'Ground Truth');
    end
    if ~isempty(estAll)
        scatter3(estAll(:,1), estAll(:,2), estAll(:,3), 50, 'r', 'x', 'DisplayName', 'Detections');
    end
    grid on;
    xlabel('X Position (m)');
    ylabel('Y Position (m)');
    zlabel('Z Position (m)');
    title('3D Target Trajectories vs. Radar Detections');
    legend('show', 'Location', 'best');
    view(3);
    
    img1 = fullfile(outputPath, 'trajectory_3d.png');
    saveas(fig1, img1);
    close(fig1);
    
    % Read error CSV
    if exist(csvPath, 'file')
        opts = detectImportOptions(csvPath);
        tbl = readtable(csvPath, opts);
        
        posErr = tbl.positionErrorH; % horizontal position error
        % Remove NaNs
        posErr(isnan(posErr)) = [];
        
        if ~isempty(posErr)
            fig2 = figure('Visible', 'off');
            % Empirical CDF plot
            sortedErr = sort(posErr);
            n = numel(sortedErr);
            p = (1:n) / n;
            plot(sortedErr, p, 'LineWidth', 2);
            grid on;
            xlabel('Horizontal Position Error (m)');
            ylabel('Cumulative Probability');
            title('Empirical CDF of Horizontal Position Error');
            xlim([0, max(sortedErr) + 1]);
            
            img2 = fullfile(outputPath, 'error_cdf.png');
            saveas(fig2, img2);
            close(fig2);
        end
    end
    
    fprintf('Plots saved successfully in %s\n', outputPath);
end
