function plotMap(data, idx, R, outDir, useBasemap)
% Plots candidate and selected sites, with location labels
%   useBasemap - true (default): fetch real map tiles (slower, prettier)
%                false: plain lat/lon scatter, no network calls (fast, for debugging)

    if nargin < 5
        useBasemap = true;
    end

    figure('Name','EV Charging Station Optimization');

    if useBasemap
        geoscatter(data.Lat, data.Lon, 60, 'blue', 'filled', 'DisplayName', 'Candidates');
        hold on
        geoscatter(data.Lat(idx), data.Lon(idx), 150, 'red', 'filled', 'DisplayName', 'Selected');
        geobasemap streets
        for i = 1:height(data)
            text(data.Lat(i), data.Lon(i), ['  ' data.Name{i}], 'FontSize', 7, 'Color', [0.4 0.4 0.4]);
        end
        for k = 1:length(idx)
            text(data.Lat(idx(k)), data.Lon(idx(k)), ['  ' data.Name{idx(k)}], ...
                'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k');
        end
        ax = gca;
        ax.Toolbar.Visible = 'off';
    else
        scatter(data.Lon, data.Lat, 60, 'blue', 'filled', 'DisplayName', 'Candidates');
        hold on
        scatter(data.Lon(idx), data.Lat(idx), 150, 'red', 'filled', 'DisplayName', 'Selected');
        for k = 1:length(idx)
            text(data.Lon(idx(k)), data.Lat(idx(k)), ['  ' data.Name{idx(k)}], ...
                'FontSize', 9, 'FontWeight', 'bold');
        end
        xlabel('Longitude'); ylabel('Latitude'); grid on;
    end

    title(sprintf('Optimized EV Charging Stations (R = %d km)', R));
    legend('Location','best');

    outFile = fullfile(outDir, 'coverage_map.png');
    exportgraphics(gcf, outFile, 'Resolution', 150);
    fprintf('Saved: %s\n', outFile);
end