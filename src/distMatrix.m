function D = distMatrix(lat, lon, roadDistanceFile)
% DISTMATRIX Loads or downloads road-network distances.
%   If roadDistanceFile exists, it is loaded as an n-by-n CSV matrix in km.
%   Otherwise, OSRM is queried and the matrix is cached to that file.
%   Straight-line distance is used only when the download is unavailable.

    lat = lat(:);
    lon = lon(:);
    n = numel(lat);
    if n ~= numel(lon) || any(~isfinite(lat)) || any(~isfinite(lon))
        error('distMatrix:InvalidCoordinates', ...
            'Latitude and longitude must be finite vectors of equal length.');
    end

    if nargin >= 3 && ~isempty(roadDistanceFile) && exist(roadDistanceFile, 'file')
        D = readmatrix(roadDistanceFile);
        if ~isequal(size(D), [n, n]) || any(~isfinite(D(:))) || any(D(:) < 0)
            error('distMatrix:InvalidRoadMatrix', ...
                'Road distance file must be a finite %d-by-%d nonnegative matrix in km.', n, n);
        end
        D(1:n+1:end) = 0;
        fprintf('Loaded road-network distance matrix (%d x %d) from %s.\n', ...
            n, n, roadDistanceFile);
        return;
    end

    if nargin >= 3 && ~isempty(roadDistanceFile)
        try
            D = downloadRoadDistances(lat, lon);
            outputFolder = fileparts(roadDistanceFile);
            if ~isempty(outputFolder) && ~exist(outputFolder, 'dir')
                mkdir(outputFolder);
            end
            writematrix(D, roadDistanceFile);
            fprintf('Downloaded and cached road-network distances to %s.\n', ...
                roadDistanceFile);
            return;
        catch exception
            warning('distMatrix:RoadDownloadFailed', ...
                'Road-distance download failed (%s). Using straight-line fallback.', ...
                exception.message);
        end
    else
        warning('distMatrix:RoadMatrixMissing', ...
            'No road-distance cache path was provided. Using straight-line fallback.');
    end

    % Computes pairwise haversine distances (km) - vectorized
    Re = 6371; % Earth radius, km

    latR = deg2rad(lat);
    lonR = deg2rad(lon);

    dLat = latR - latR';
    dLon = lonR - lonR';

    a = sin(dLat/2).^2 + cos(latR) .* cos(latR') .* sin(dLon/2).^2;
    D = 2 * Re * asin(sqrt(a));

    fprintf('Straight-line distance matrix computed (%d x %d).\n', length(lat), length(lat));
end

function D = downloadRoadDistances(lat, lon)
    coordinates = strings(numel(lat), 1);
    for i = 1:numel(lat)
        coordinates(i) = sprintf('%.6f,%.6f', lon(i), lat(i));
    end

    url = "https://router.project-osrm.org/table/v1/driving/" ...
        + strjoin(coordinates, ';') + "?annotations=distance";
    response = webread(url, weboptions('Timeout', 120));

    if ~isfield(response, 'code') || ~strcmp(response.code, 'Ok') ...
            || ~isfield(response, 'distances')
        error('distMatrix:InvalidRoutingResponse', ...
            'OSRM returned an unsuccessful or incomplete response.');
    end

    D = double(response.distances) ./ 1000;
    n = numel(lat);
    if ~isequal(size(D), [n, n]) || any(~isfinite(D(:))) || any(D(:) < 0)
        error('distMatrix:InvalidDownloadedMatrix', ...
            'OSRM returned an invalid %d-by-%d distance matrix.', n, n);
    end
    D(1:n+1:end) = 0;
end