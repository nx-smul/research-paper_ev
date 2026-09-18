function plotMap(data, idx, R, outDir, useBasemap, localRoadGraphFile)
% Plots candidate and selected sites, with location labels
%   useBasemap - true (default): fetch real map tiles (slower, prettier)
%                false: plain lat/lon scatter, no network calls (fast, for debugging)

    if nargin < 5
        useBasemap = true;
    end
    if nargin < 6
        localRoadGraphFile = '';
    end

    figure('Name','EV Charging Station Optimization');
    geographicMap = false;

    if useBasemap
        try
            geoaxes;
            hold on;
            [latLimits, lonLimits] = mapLimits(data, R);
            geolimits(latLimits, lonLimits);
            basemapLoaded = tryBasemaps(["streets", "satellite", "topographic"]);
            if ~basemapLoaded
                error('plotMap:NoBasemap', ...
                    'No MATLAB geographic basemap could be loaded.');
            end
            geoscatter(data.Lat, data.Lon, 60, 'blue', 'filled', ...
                'DisplayName', 'Candidates');
            geoscatter(data.Lat(idx), data.Lon(idx), 150, 'red', 'filled', ...
                'DisplayName', 'Selected');
            if ~isempty(localRoadGraphFile) && exist(localRoadGraphFile, 'file')
                roads = loadLocalRoadOverlay(data, outDir, localRoadGraphFile, R);
                plotLocalRoadGraph(roads, true);
            end

            for i = 1:height(data)
                text(data.Lat(i), data.Lon(i), ['  ' char(data.Name(i))], ...
                    'FontSize', 7, 'Color', [0.4 0.4 0.4]);
            end
            for k = 1:length(idx)
                text(data.Lat(idx(k)), data.Lon(idx(k)), ...
                    ['  ' char(data.Name(idx(k)))], 'FontSize', 9, ...
                    'FontWeight', 'bold', 'Color', 'k');
            end
            title(sprintf('Optimized EV Charging Stations (R = %d km)', R));
            geographicMap = true;
        catch exception
            warning('plotMap:BasemapUnavailable', ...
                'MATLAB street basemap unavailable (%s). Using local geographic road map.', ...
                exception.message);
            close(gcf);
            figure('Name','EV Charging Station Optimization');
            geoaxes;
            hold on;
            [latLimits, lonLimits] = mapLimits(data, R);
            geolimits(latLimits, lonLimits);
            if ~isempty(localRoadGraphFile) && exist(localRoadGraphFile, 'file')
                roads = loadLocalRoadOverlay(data, outDir, localRoadGraphFile, R);
                plotLocalRoadGraph(roads, true);
            end
            geoscatter(data.Lat, data.Lon, 60, 'blue', 'filled', ...
                'DisplayName', 'Candidates');
            geoscatter(data.Lat(idx), data.Lon(idx), 150, 'red', 'filled', ...
                'DisplayName', 'Selected');
            title(sprintf('Optimized EV Charging Stations (Local Geographic Map, R = %d km)', R));
            geographicMap = true;
        end
    end

    if ~geographicMap && ~isempty(localRoadGraphFile) && exist(localRoadGraphFile, 'file')
        roads = loadLocalRoadOverlay(data, outDir, localRoadGraphFile, R);
        plotLocalRoadGraph(roads, false);
        hold on;
        scatter(data.Lon, data.Lat, 60, 'blue', 'filled', 'DisplayName', 'Candidates');
        scatter(data.Lon(idx), data.Lat(idx), 150, 'red', 'filled', 'DisplayName', 'Selected');
        for k = 1:length(idx)
            text(data.Lon(idx(k)), data.Lat(idx(k)), ['  ' char(data.Name(idx(k)))], ...
                'FontSize', 9, 'FontWeight', 'bold');
        end
        xlabel('Longitude'); ylabel('Latitude'); grid on; axis equal;
        title(sprintf('Optimized EV Charging Stations (Local Road Graph, R = %d km)', R));
    elseif ~geographicMap
        scatter(data.Lon, data.Lat, 60, 'blue', 'filled', 'DisplayName', 'Candidates');
        scatter(data.Lon(idx), data.Lat(idx), 150, 'red', 'filled', 'DisplayName', 'Selected');
        for k = 1:length(idx)
            text(data.Lon(idx(k)), data.Lat(idx(k)), ['  ' char(data.Name(idx(k)))], ...
                'FontSize', 9, 'FontWeight', 'bold');
        end
        xlabel('Longitude'); ylabel('Latitude'); grid on; axis equal;
    end

    if ~geographicMap && (isempty(localRoadGraphFile) || ~exist(localRoadGraphFile, 'file'))
        title(sprintf('Optimized EV Charging Stations (R = %d km)', R));
    end
    legend('Location','best');

    outFile = fullfile(outDir, 'coverage_map.png');
    exportgraphics(gcf, outFile, 'Resolution', 150);
    fprintf('Saved: %s\n', outFile);
end

function loaded = tryBasemaps(names)
    loaded = false;
    for i = 1:numel(names)
        try
            geobasemap(names(i));
            drawnow;
            loaded = true;
            return;
        catch exception
            if i == numel(names)
                warning('plotMap:BasemapAttemptFailed', ...
                    'All geographic basemap options failed: %s', exception.message);
            end
        end
    end
end

function roads = loadLocalRoadOverlay(data, outDir, localRoadGraphFile, radiusKm)
    meanLat = mean(data.Lat);
    latMargin = radiusKm / 111;
    lonMargin = radiusKm / (111 * max(cosd(meanLat), 0.1));
    bbox = [min(data.Lon) - lonMargin, min(data.Lat) - latMargin; ...
        max(data.Lon) + lonMargin, max(data.Lat) + latMargin];
    roadsCacheFile = fullfile(outDir, 'local_roads_overlay.mat');
    if exist(roadsCacheFile, 'file')
        cached = load(roadsCacheFile, 'roads', 'bbox', 'sourceFile');
        if isequal(cached.bbox, bbox) && strcmp(cached.sourceFile, localRoadGraphFile)
            roads = cached.roads;
            if numel(roads) > 2500
                keep = round(linspace(1, numel(roads), 2500));
                roads = roads(keep);
                sourceFile = localRoadGraphFile;
                save(roadsCacheFile, 'roads', 'bbox', 'sourceFile', '-v7.3');
            end

            return;
        end
    end
    roads = shaperead(localRoadGraphFile, 'UseGeoCoords', true, ...
        'BoundingBox', bbox);
    maxRoads = 2500;
    if numel(roads) > maxRoads
        keep = round(linspace(1, numel(roads), maxRoads));
        roads = roads(keep);
    end
    sourceFile = localRoadGraphFile;
    save(roadsCacheFile, 'roads', 'bbox', 'sourceFile', '-v7.3');
end

function [latLimits, lonLimits] = mapLimits(data, radiusKm)
    meanLat = mean(data.Lat);
    latMargin = radiusKm / 111;
    lonMargin = radiusKm / (111 * max(cosd(meanLat), 0.1));
    latLimits = [min(data.Lat) - latMargin, max(data.Lat) + latMargin];
    lonLimits = [min(data.Lon) - lonMargin, max(data.Lon) + lonMargin];
end

function plotLocalRoadGraph(roads, geographic)
    maxRoads = 2500;
    if numel(roads) > maxRoads
        keep = round(linspace(1, numel(roads), maxRoads));
        roads = roads(keep);
    end
    for i = 1:numel(roads)
        if geographic
            geoplot(roads(i).Lat, roads(i).Lon, ...
                'Color', [0.78 0.78 0.78], 'LineWidth', 0.25, ...
                'HandleVisibility', 'off');
        else
            plot(roads(i).Lon, roads(i).Lat, ...
                'Color', [0.78 0.78 0.78], 'LineWidth', 0.25, ...
                'HandleVisibility', 'off');
        end
    end
end