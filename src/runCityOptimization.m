function runCityOptimization(dataFile, outDir, params)
% RUNCITYOPTIMIZATION Runs the full EV charging siting pipeline for one city
%   dataFile - path to a candidates CSV (same column schema for every city)
%   outDir   - folder where this city's results will be saved
%   params   - struct with fields: w (car,bike,pop,cost), R, p, budget

    if ~exist(outDir, 'dir'); mkdir(outDir); end

    %% 1. Load data
    data = loadData(dataFile);

    %% 2. Distance matrix
    D = distMatrix(data.Lat, data.Lon);

    %% 3. Combine factors into one demand score
    h = computeDemand(data, params.w);

    %% 4. Optimize
    A = D <= params.R;
    [idx, x, u] = mclp(A, h, params.p, data.LandCost_LakhBDT, params.budget);

    %% Print and save selected stations
    selected = data(idx, {'Name','Lat','Lon','Type','Weight_Car','Weight_Bike','PopDensity','LandCost_LakhBDT'});

    hints = [ ...
    "Hints:"
    "  Car        - Estimated private EV car charging demand (scale 1-10, qualitative)"
    "  Bike       - Estimated e-motorbike/scooter charging demand (scale 1-10, qualitative)"
    "  Pop        - Population density score (scale 1-10, based on local census/estimate)"
    "  Cost(Lakh) - Estimated land + installation cost in lakh BDT (real currency, not 1-10 scale)"
    ];

    fprintf('\nSelected Stations:\n');
    fprintf('%-28s %-10s %-10s %-15s %-6s %-6s %-6s %-10s\n', ...
        'Name','Lat','Lon','Type','Car','Bike','Pop','Cost(Lakh)');
    fprintf('%s\n', repmat('-', 1, 100));
    for i = 1:height(selected)
        fprintf('%-28s %-10.4f %-10.4f %-15s %-6d %-6d %-6d %-10d\n', ...
            selected.Name{i}, selected.Lat(i), selected.Lon(i), selected.Type{i}, ...
            selected.Weight_Car(i), selected.Weight_Bike(i), selected.PopDensity(i), ...
            selected.LandCost_LakhBDT(i));
    end
    fprintf('\n');
    for i = 1:length(hints)
        fprintf('%s\n', hints(i));
    end

    % Save formatted output + hints to a text file
    txtFile = fullfile(outDir, 'selected_stations.txt');
    fid = fopen(txtFile, 'w');
    [~, cityName] = fileparts(dataFile);
    fprintf(fid, 'EV Charging Station Optimization - %s\n', cityName);
    fprintf(fid, 'Selected Stations (p = %d, R = %d km, Budget = %d Lakh BDT)\n\n', ...
        params.p, params.R, params.budget);
    fprintf(fid, '%-28s %-10s %-10s %-15s %-6s %-6s %-6s %-10s\n', ...
        'Name','Lat','Lon','Type','Car','Bike','Pop','Cost(Lakh)');
    fprintf(fid, '%s\n', repmat('-', 1, 100));
    for i = 1:height(selected)
        fprintf(fid, '%-28s %-10.4f %-10.4f %-15s %-6d %-6d %-6d %-10d\n', ...
            selected.Name{i}, selected.Lat(i), selected.Lon(i), selected.Type{i}, ...
            selected.Weight_Car(i), selected.Weight_Bike(i), selected.PopDensity(i), ...
            selected.LandCost_LakhBDT(i));
    end
    fprintf(fid, '\nTotal Demand Coverage: %.1f%%\n', 100*sum(h(u==1))/sum(h));
    fprintf(fid, 'Total Cost Used: %.1f / %.1f Lakh BDT\n\n', sum(data.LandCost_LakhBDT(idx)), params.budget);
    for i = 1:length(hints)
        fprintf(fid, '%s\n', hints(i));
    end
    fclose(fid);
    fprintf('\nSaved: %s\n', txtFile);

    %% 5. Plot map
    plotMap(data, idx, params.R, outDir);

    %% 6. Save results CSV
    writetable(data(idx,:), fullfile(outDir, 'selected_stations.csv'));
    fprintf('Saved: %s\n', fullfile(outDir, 'selected_stations.csv'));

    %% 7. Sensitivity: coverage vs number of stations
    pRange = 1:15;
    cov = zeros(size(pRange));
    for k = 1:length(pRange)
        [~, ~, uk] = mclp(A, h, pRange(k), data.LandCost_LakhBDT, Inf);
        cov(k) = 100 * sum(h(uk==1)) / sum(h);
    end

    figure('Name', ['Sensitivity Analysis - ' cityName]);
    plot(pRange, cov, '-o', 'LineWidth', 2, 'MarkerFaceColor','b');
    xlabel('Number of Stations (p)');
    ylabel('Demand Coverage (%)');
    title(sprintf('Coverage vs Number of Charging Stations - %s', cityName));
    grid on;
    exportgraphics(gcf, fullfile(outDir, 'sensitivity.png'), 'Resolution', 300);
    fprintf('Saved: %s\n', fullfile(outDir, 'sensitivity.png'));
    close(gcf);
end