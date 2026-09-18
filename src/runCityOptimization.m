function runCityOptimization(dataFile, outDir, params, roadDistanceFile, costProfile)
% RUNCITYOPTIMIZATION Runs the full EV charging siting pipeline for one city

    if nargin < 4
        roadDistanceFile = '';
    end
    if nargin < 5
        costProfile.level2 = [4, 1, 1];
        costProfile.dcFast = [12, 8, 4];
    end

    if ~exist(outDir, 'dir'); mkdir(outDir); end

    %% 1. Load data
    data = loadData(dataFile);
    data = assignChargerType(data, costProfile);

    %% 2. Distance matrix
    D = distMatrix(data.Lat, data.Lon, roadDistanceFile);

    %% 3. Combine factors into one demand score
    h = computeDemand(data, params.w);

    %% 4. Optimize
    W = coverageWeights(D, params.R);
    fprintf('\n>> Finding the best station locations...\n');
    [idx, x, u] = mclp(W, h, params.p, data.AdjustedCost, params.budget);

    %% Build selected-stations table
    selected = data(idx, {'Name','Lat','Lon','Type','Weight_Car','Weight_Bike', ...
        'PopDensity','LandCost','ChargerType','HardwareCost','GridUpgradeCost', ...
        'CivilWorkCost','AdjustedCost'});

    hints = [ ...
    "What these columns mean:"
    "  Car          - How much demand from private EV cars is expected here (1-10)"
    "  Bike         - How much demand from e-motorbikes/scooters is expected here (1-10)"
    "  Pop          - How densely populated the surrounding area is (1-10)"
    "  Cost         - How expensive the land/site is, relatively (1-10, 1=cheapest)"
    "  ChargerType  - Recommended charger: DC Fast (quick turnover sites) or Level 2 (longer dwell-time sites)"
    "  AdjustedCost - Land + charger hardware + grid upgrade + civil/site work cost"
    "  Coverage credit is stronger for stations closer to a demand point, and fades toward the edge of the service radius."
    ];

    fprintf('\nRecommended Charging Station Locations:\n');
    fprintf('%-28s %-10s %-10s %-15s %-6s %-6s %-6s %-6s %-9s %-8s\n', ...
        'Name','Lat','Lon','Type','Car','Bike','Pop','Cost','Charger','AdjCost');
    fprintf('%s\n', repmat('-', 1, 115));
    for i = 1:height(selected)
        fprintf('%-28s %-10.4f %-10.4f %-15s %-6d %-6d %-6d %-6d %-9s %-8.1f\n', ...
            string(selected.Name(i)), selected.Lat(i), selected.Lon(i), string(selected.Type(i)), ...
            selected.Weight_Car(i), selected.Weight_Bike(i), selected.PopDensity(i), ...
            selected.LandCost(i), string(selected.ChargerType(i)), selected.AdjustedCost(i));
    end
    fprintf('\n');
    for i = 1:length(hints)
        fprintf('%s\n', hints(i));
    end

    % Save formatted output + hints to a text file
    txtFile = fullfile(outDir, 'selected_stations.txt');
    fid = fopen(txtFile, 'w');
    [~, cityName] = fileparts(dataFile);
    fprintf(fid, 'EV Charging Station Plan - %s\n', cityName);
    fprintf(fid, 'Stations to build: %d  |  Service radius: %d km  |  Budget limit: %s\n\n', ...
        params.p, params.R, budgetLabel(params.budget));
    fprintf(fid, '%-28s %-10s %-10s %-15s %-6s %-6s %-6s %-6s %-9s %-8s\n', ...
        'Name','Lat','Lon','Type','Car','Bike','Pop','Cost','Charger','AdjCost');
    fprintf(fid, '%s\n', repmat('-', 1, 115));
    for i = 1:height(selected)
        fprintf(fid, '%-28s %-10.4f %-10.4f %-15s %-6d %-6d %-6d %-6d %-9s %-8.1f\n', ...
            string(selected.Name(i)), selected.Lat(i), selected.Lon(i), string(selected.Type(i)), ...
            selected.Weight_Car(i), selected.Weight_Bike(i), selected.PopDensity(i), ...
            selected.LandCost(i), string(selected.ChargerType(i)), selected.AdjustedCost(i));
    end
    fprintf(fid, '\nDemand Covered: %.1f%%\n', 100*sum(h.*u)/sum(h));
    fprintf(fid, 'Adjusted Budget Used: %.1f out of %s\n', sum(selected.AdjustedCost), budgetLabel(params.budget));
    fprintf(fid, 'Original Land Cost: %.1f\n', sum(selected.LandCost));
    fprintf(fid, 'Adjusted Cost (charger-type aware): %.1f\n\n', sum(selected.AdjustedCost));
    for i = 1:length(hints)
        fprintf(fid, '%s\n', hints(i));
    end
    fclose(fid);
    fprintf('\nSaved: %s\n', txtFile);

    %% 5. Plot map
    plotMap(data, idx, params.R, outDir, true);
    drawnow;

    %% 6. Save results CSV (now includes charger type + adjusted cost)
    writetable(selected, fullfile(outDir, 'selected_stations.csv'));
    fprintf('Saved: %s\n', fullfile(outDir, 'selected_stations.csv'));

    %% 7a. How coverage changes as you add more stations
    fprintf('\n>> Testing how coverage improves as more stations are added...\n');
    pRange = 1:15;
    covP = zeros(size(pRange));
    for k = 1:length(pRange)
        [~, ~, uk] = mclp(W, h, pRange(k), data.AdjustedCost, Inf);
        covP(k) = 100 * sum(h.*uk) / sum(h);
    end
    plotSensitivity(pRange, covP, 'Number of Stations', ...
        sprintf('More Stations = More Coverage - %s', cityName), ...
        fullfile(outDir, 'sensitivity_p.png'));

    %% 7b. How coverage changes with budget
    fprintf('\n>> Testing how coverage improves as budget increases...\n');
    maxBudget = sum(data.AdjustedCost);
    budgetRange = linspace(0, maxBudget, 10);
    covBudget = zeros(size(budgetRange));
    for k = 1:length(budgetRange)
        [~, ~, uk] = mclp(W, h, params.p, data.AdjustedCost, budgetRange(k));
        covBudget(k) = 100 * sum(h.*uk) / sum(h);
    end
    plotSensitivity(budgetRange, covBudget, 'Budget Available', ...
        sprintf('Coverage vs Budget - %s', cityName), ...
        fullfile(outDir, 'sensitivity_budget.png'));

    %% 7c. How coverage changes with service radius
    fprintf('\n>> Testing how coverage changes with a bigger service radius...\n');
    Rrange = 0.5:0.5:5;
    covR = zeros(size(Rrange));
    for k = 1:length(Rrange)
        Wk = coverageWeights(D, Rrange(k));
        [~, ~, uk] = mclp(Wk, h, params.p, data.AdjustedCost, params.budget);
        covR(k) = 100 * sum(h.*uk) / sum(h);
    end
    plotSensitivity(Rrange, covR, 'Service Radius (km)', ...
        sprintf('Coverage vs Service Radius - %s', cityName), ...
        fullfile(outDir, 'sensitivity_R.png'));

    %% Print summary tables
    fprintf('\n--- Coverage as Stations Increase ---\n');
    for k = 1:length(pRange)
        fprintf('  %2d station(s)  ->  %.1f%% of demand covered\n', pRange(k), covP(k));
    end

    fprintf('\n--- Coverage as Budget Increases ---\n');
    for k = 1:length(budgetRange)
        fprintf('  Budget %6.1f  ->  %.1f%% of demand covered\n', budgetRange(k), covBudget(k));
    end

    fprintf('\n--- Coverage as Service Radius Increases ---\n');
    for k = 1:length(Rrange)
        fprintf('  %4.1f km radius  ->  %.1f%% of demand covered\n', Rrange(k), covR(k));
    end
end

function s = budgetLabel(b)
    if isinf(b)
        s = 'no limit';
    else
        s = sprintf('%.0f', b);
    end
end

function plotSensitivity(xVals, yVals, xLabelStr, titleStr, outFile)
    figure('Name', titleStr);
    plot(xVals, yVals, '-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
    xlabel(xLabelStr);
    ylabel('Percent of Demand Covered (%)');
    title(titleStr);
    grid on;
    ax = gca;
    ax.Toolbar.Visible = 'off';
    exportgraphics(gcf, outFile, 'Resolution', 150);
    fprintf('Saved: %s\n', outFile);
    drawnow;
end