function plotMap(data, idx, R, outDir)
% Plots candidate and selected sites on a Dhaka map, with location labels

    figure('Name','EV Charging Station Optimization - Dhaka');

    geoscatter(data.Lat, data.Lon, 60, 'blue', 'filled', 'DisplayName', 'Candidates');
    hold on
    geoscatter(data.Lat(idx), data.Lon(idx), 150, 'red', 'filled', 'DisplayName', 'Selected');

    geobasemap streets
    title(sprintf('Optimized EV Charging Stations (R = %d km)', R));
    legend('Location','best');

    for i = 1:height(data)
        text(data.Lat(i), data.Lon(i), ['  ' data.Name{i}], ...
            'FontSize', 7, 'Color', [0.4 0.4 0.4]);
    end
    for k = 1:length(idx)
        text(data.Lat(idx(k)), data.Lon(idx(k)), ['  ' data.Name{idx(k)}], ...
            'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k');
    end

    ax = gca;
    ax.Toolbar.Visible = 'off';

    outFile = fullfile(outDir, 'coverage_map.png');
    exportgraphics(gcf, outFile, 'Resolution', 300);
    fprintf('Saved: %s\n', outFile);
end