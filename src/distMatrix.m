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
    cacheKey = [cacheKey sprintf('_r%.2f_v2', radiusKm)];
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

    % Connect each candidate to the nearest point on a road segment rather
    % than snapping it to the nearest shapefile vertex. This avoids adding
    % artificial access distance at long or sparsely sampled road segments.
    candidateNode = (nNodes + (1:numel(lat)))';
    nodeLat = [nodeLat; lat]; %#ok<AGROW>
    nodeLon = [nodeLon; lon]; %#ok<AGROW>
    [snapStart, snapEnd, snapStartDistance, snapEndDistance] = ...
        nearestRoadSegmentConnections(lat, lon, nodeLat(1:nNodes), ...
        nodeLon(1:nNodes), edgeStart, edgeEnd);

    edgeStart = [edgeStart; candidateNode; candidateNode]; %#ok<AGROW>
    edgeEnd = [edgeEnd; snapStart; snapEnd]; %#ok<AGROW>
    edgeDistanceKm = [edgeDistanceKm; snapStartDistance; ...
        snapEndDistance]; %#ok<AGROW>

    roadGraph = graph(edgeStart, edgeEnd, edgeDistanceKm, ...
        nNodes + numel(candidateNode));
    D = distances(roadGraph, candidateNode, candidateNode);
    if any(~isfinite(D(:)))
        error('distMatrix:DisconnectedRoadMap', ...
            'The local road map cannot connect all candidate sites.');
    end

    function [snapStart, snapEnd, startDistance, endDistance] = ...
            nearestRoadSegmentConnections(candidateLat, candidateLon, ...
            nodeLat, nodeLon, edgeStart, edgeEnd)
        nCandidates = numel(candidateLat);
        snapStart = zeros(nCandidates, 1);
        snapEnd = zeros(nCandidates, 1);
        startDistance = zeros(nCandidates, 1);
        endDistance = zeros(nCandidates, 1);

        referenceLat = mean([candidateLat(:); nodeLat(:)]);
        kmPerDegreeLat = 111.132;
        kmPerDegreeLon = 111.132 * max(cosd(referenceLat), 0.1);
        nodeX = nodeLon * kmPerDegreeLon;
        nodeY = nodeLat * kmPerDegreeLat;

        for candidateIndex = 1:nCandidates
            candidateX = candidateLon(candidateIndex) * kmPerDegreeLon;
            candidateY = candidateLat(candidateIndex) * kmPerDegreeLat;
            x1 = nodeX(edgeStart);
            y1 = nodeY(edgeStart);
            x2 = nodeX(edgeEnd);
            y2 = nodeY(edgeEnd);
            dx = x2 - x1;
            dy = y2 - y1;
            denominator = dx.^2 + dy.^2;
            projection = ((candidateX - x1) .* dx + ...
                (candidateY - y1) .* dy) ./ max(denominator, eps);
            projection = min(max(projection, 0), 1);
            projectedX = x1 + projection .* dx;
            projectedY = y1 + projection .* dy;
            segmentOffset = (projectedX - candidateX).^2 + ...
                (projectedY - candidateY).^2;
            [~, bestSegment] = min(segmentOffset);

            snapStart(candidateIndex) = edgeStart(bestSegment);
            snapEnd(candidateIndex) = edgeEnd(bestSegment);
            segmentLength = haversineDistances( ...
                nodeLat(snapStart(candidateIndex)), ...
                nodeLon(snapStart(candidateIndex)), ...
                nodeLat(snapEnd(candidateIndex)), ...
                nodeLon(snapEnd(candidateIndex)));
            perpendicularDistance = sqrt(segmentOffset(bestSegment));
            startDistance(candidateIndex) = perpendicularDistance + ...
                projection(bestSegment) * segmentLength;
            endDistance(candidateIndex) = perpendicularDistance + ...
                (1 - projection(bestSegment)) * segmentLength;
        end
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
        partStart = find(valid & [true; ~valid(1:end-1)]);
        partEnd = find(valid & [~valid(2:end); true]);
        for partIndex = 1:numel(partStart)
            partLat = latValues(partStart(partIndex):partEnd(partIndex));
            partLon = lonValues(partStart(partIndex):partEnd(partIndex));
            if numel(partLat) < 2
                continue;
            end
            for vertexIndex = 1:(numel(partLat) - 1)
                [startNode, nodeLat, nodeLon, nodeLookup] = getRoadNode( ...
                    partLat(vertexIndex), partLon(vertexIndex), ...
                    nodeLat, nodeLon, nodeLookup);
                [endNode, nodeLat, nodeLon, nodeLookup] = getRoadNode( ...
                    partLat(vertexIndex + 1), partLon(vertexIndex + 1), ...
                    nodeLat, nodeLon, nodeLookup);
                segmentDistance = haversineDistances( ...
                    partLat(vertexIndex), partLon(vertexIndex), ...
                    partLat(vertexIndex + 1), partLon(vertexIndex + 1));
                if startNode ~= endNode && segmentDistance > 0
                    edgeStart(end + 1, 1) = startNode; %#ok<AGROW>
                    edgeEnd(end + 1, 1) = endNode; %#ok<AGROW>
                    edgeDistanceKm(end + 1, 1) = segmentDistance; %#ok<AGROW>
                end
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
