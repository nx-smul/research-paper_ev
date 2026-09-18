function plotMap(data, idx, R, outDir)
% Plots candidate and selected sites on a Dhaka map, with location names

    figure('Name','EV Charging Station Optimization - Dhaka');

    % All candidates in blue
    geoscatter(data.Lat, data.Lon, 60, 'blue', 'filled', 'DisplayName', 'Candidates');
    hold on

    % Selected stations in red
    geoscatter(data.Lat(idx), data.Lon(idx), 150, 'red', 'filled', 'DisplayName', 'Selected');

    geobasemap streets
    title(sprintf('Optimized EV Charging Stations (R = %d km)', R));
    legend('Location','best');

    % --- Add labels for ALL candidate sites (small, gray) ---
    for i = 1:height(data)
        text(data.Lat(i), data.Lon(i), ['  ' data.Name{i}], ...
            'FontSize', 7, 'Color', [0.4 0.4 0.4]);
    end

    % --- Add labels for SELECTED stations (bold, black, on top) ---
    for k = 1:length(idx)
        text(data.Lat(idx(k)), data.Lon(idx(k)), ['  ' data.Name{idx(k)}], ...
            'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k');
    end

    outFile = fullfile(outDir, 'coverage_map.png');
    exportgraphics(gcf, outFile, 'Resolution', 300);
    fprintf('Saved: %s\n', outFile);
end