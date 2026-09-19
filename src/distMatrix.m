function D = distMatrix(lat, lon, roadDistanceFile, siteNames, localRoadGraphFile, ...
        radiusKm, cacheDir)
% DISTMATRIX Computes local road distances from a MATLAB road shapefile.

    lat = lat(:);
    lon = lon(:);
    n = numel(lat);
    if nargin < 4
        siteNames = [];
    end
    if nargin < 5
        localRoadGraphFile = '';
    end
    if nargin < 6 || isempty(radiusKm)
        radiusKm = 5;
    end
    if nargin < 7
        cacheDir = '';
    end
    if n ~= numel(lon) || any(~isfinite(lat)) || any(~isfinite(lon))
        error('distMatrix:InvalidCoordinates', ...
            'Latitude and longitude must be finite vectors of equal length.');
    end

    metadataFile = [roadDistanceFile '.meta.mat'];
    if nargin >= 3 && ~isempty(roadDistanceFile) && exist(roadDistanceFile, 'file') ...
            && exist(metadataFile, 'file') && ~isempty(siteNames)
        cache = load(metadataFile);
        hasMatchingNames = isfield(cache, 'siteNames') ...
            && isequal(string(cache.siteNames(:)), string(siteNames(:)));
        hasMatchingCoordinates = isfield(cache, 'lat') ...
            && isfield(cache, 'lon') ...
            && isequal(cache.lat(:), lat) ...
            && isequal(cache.lon(:), lon);
        if hasMatchingNames && hasMatchingCoordinates
            D = readmatrix(roadDistanceFile);
            if isequal(size(D), [n, n]) && all(isfinite(D(:))) && all(D(:) >= 0)
                fprintf('Loaded cached local road distances for %d sites.\n', n);
                return;
            end
        end
    end

    if isempty(localRoadGraphFile) || ~exist(localRoadGraphFile, 'file')
        error('distMatrix:LocalRoadMapMissing', ...
            'Local road map not found: %s', localRoadGraphFile);
    end

    D = localRoadGraphDistances(lat, lon, localRoadGraphFile, radiusKm, cacheDir);
    if nargin >= 3 && ~isempty(roadDistanceFile)
        outputFolder = fileparts(roadDistanceFile);
        if ~isempty(outputFolder) && ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end
        writematrix(D, roadDistanceFile);
        save(metadataFile, 'siteNames', 'lat', 'lon');
    end
    fprintf('Built local road graph and computed distances for %d sites.\n', n);
end

function D = localRoadGraphDistances(lat, lon, graphFile, radiusKm, cacheDir)
    cacheKey = sprintf('%.4f_%.4f_%.4f_%.4f', ...
        min(lat), min(lon), max(lat), max(lon));
    cacheKey = [cacheKey sprintf('_r%.2f', radiusKm)];
    if isempty(cacheDir)
        graphCacheFile = [graphFile '.' cacheKey '.local_graph.mat'];
    else
        graphCacheFolder = fullfile(cacheDir, 'road_graphs');
        if ~exist(graphCacheFolder, 'dir')
            mkdir(graphCacheFolder);
        end
        graphCacheFile = fullfile(graphCacheFolder, [cacheKey '.local_graph.mat']);
    end
    if exist(graphCacheFile, 'file')
        cached = load(graphCacheFile, 'nodeLat', 'nodeLon', ...
            'edgeStart', 'edgeEnd', 'edgeDistanceKm', 'bbox');
        nodeLat = cached.nodeLat;
        nodeLon = cached.nodeLon;
        edgeStart = cached.edgeStart;
        edgeEnd = cached.edgeEnd;
        edgeDistanceKm = cached.edgeDistanceKm;
    else
        [nodeLat, nodeLon, edgeStart, edgeEnd, edgeDistanceKm, bbox] = ...
            readRoadShapefile(graphFile, lat, lon, radiusKm);
        save(graphCacheFile, 'nodeLat', 'nodeLon', 'edgeStart', ...
            'edgeEnd', 'edgeDistanceKm', 'bbox', '-v7.3');
    end
    nNodes = numel(nodeLat);

    nearestNode = zeros(numel(lat), 1);
    for i = 1:numel(lat)
        [~, nearestNode(i)] = min(haversineDistances( ...
            lat(i), lon(i), nodeLat, nodeLon));
    end

    roadGraph = graph(edgeStart, edgeEnd, edgeDistanceKm, nNodes);
    [uniqueNodes, ~, nodeGroups] = unique(nearestNode, 'stable');
    uniqueDistances = distances(roadGraph, uniqueNodes, uniqueNodes);
    D = uniqueDistances(nodeGroups, nodeGroups);
    if any(~isfinite(D(:)))
        error('distMatrix:DisconnectedRoadMap', ...
            'The local road map cannot connect all candidate sites.');
    end
    D(1:size(D, 1)+1:end) = 0;
end

function [nodeLat, nodeLon, edgeStart, edgeEnd, edgeDistanceKm, bbox] = ...
        readRoadShapefile(filename, candidateLat, candidateLon, radiusKm)
    if exist('shaperead', 'file') ~= 2
        error('distMatrix:MappingToolboxRequired', ...
            'Reading local road shapefiles requires the MATLAB Mapping Toolbox.');
    end

    meanLat = mean(candidateLat);
    latMargin = radiusKm / 111;
    lonMargin = radiusKm / (111 * max(cosd(meanLat), 0.1));
    bbox = [min(candidateLon) - lonMargin, min(candidateLat) - latMargin; ...
        max(candidateLon) + lonMargin, max(candidateLat) + latMargin];
    roads = shaperead(filename, 'UseGeoCoords', true, 'BoundingBox', bbox);
    nodeLat = zeros(0, 1);
    nodeLon = zeros(0, 1);
    edgeStart = zeros(0, 1);
    edgeEnd = zeros(0, 1);
    edgeDistanceKm = zeros(0, 1);
    nodeLookup = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for roadIndex = 1:numel(roads)
        latValues = roads(roadIndex).Lat(:);
        lonValues = roads(roadIndex).Lon(:);
        valid = isfinite(latValues) & isfinite(lonValues);
        latValues = latValues(valid);
        lonValues = lonValues(valid);
        for vertexIndex = 1:(numel(latValues) - 1)
            [startNode, nodeLat, nodeLon, nodeLookup] = getRoadNode( ...
                latValues(vertexIndex), lonValues(vertexIndex), ...
                nodeLat, nodeLon, nodeLookup);
            [endNode, nodeLat, nodeLon, nodeLookup] = getRoadNode( ...
                latValues(vertexIndex + 1), lonValues(vertexIndex + 1), ...
                nodeLat, nodeLon, nodeLookup);
            segmentDistance = haversineDistances( ...
                latValues(vertexIndex), lonValues(vertexIndex), ...
                latValues(vertexIndex + 1), lonValues(vertexIndex + 1));
            if startNode ~= endNode && segmentDistance > 0
                edgeStart(end + 1, 1) = startNode; %#ok<AGROW>
                edgeEnd(end + 1, 1) = endNode; %#ok<AGROW>
                edgeDistanceKm(end + 1, 1) = segmentDistance; %#ok<AGROW>
            end
        end
    end

    if isempty(edgeStart)
        error('distMatrix:EmptyRoadMap', ...
            'The local shapefile contains no usable road segments.');
    end
end

function [node, nodeLat, nodeLon, nodeLookup] = getRoadNode( ...
        lat, lon, nodeLat, nodeLon, nodeLookup)
    key = sprintf('%.6f_%.6f', lat, lon);
    if isKey(nodeLookup, key)
        node = nodeLookup(key);
        return;
    end
    node = numel(nodeLat) + 1;
    nodeLookup(key) = node;
    nodeLat(node, 1) = lat;
    nodeLon(node, 1) = lon;
end

function D = haversineDistances(lat, lon, nodeLat, nodeLon)
    Re = 6371;
    latR = deg2rad(lat);
    lonR = deg2rad(lon);
    nodeLatR = deg2rad(nodeLat);
    nodeLonR = deg2rad(nodeLon);
    dLat = latR - nodeLatR;
    dLon = lonR - nodeLonR;
    a = sin(dLat/2).^2 + cos(latR) .* cos(nodeLatR) .* sin(dLon/2).^2;
    D = 2 * Re * asin(sqrt(max(0, a)));
end
