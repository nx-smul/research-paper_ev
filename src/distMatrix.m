function D = distMatrix(lat, lon)
% Computes pairwise haversine distances (km) - vectorized
    Re = 6371; % Earth radius, km
    lat = lat(:); lon = lon(:);

    latR = deg2rad(lat);
    lonR = deg2rad(lon);

    dLat = latR - latR';
    dLon = lonR - lonR';

    a = sin(dLat/2).^2 + cos(latR) .* cos(latR') .* sin(dLon/2).^2;
    D = 2 * Re * asin(sqrt(a));

    fprintf('Distance matrix computed (%d x %d).\n', length(lat), length(lat));
end