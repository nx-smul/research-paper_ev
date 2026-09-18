%% EV Charging Station Optimization - Dhaka City
clear; clc; close all;

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
dataFile = fullfile(root, 'data', 'candidates.csv');
outDir   = fullfile(root, 'results');
if ~exist(outDir, 'dir'); mkdir(outDir); end

%% 1. Load data
data = loadData(dataFile);

%% 2. Distance matrix (computed once)
D = distMatrix(data.Lat, data.Lon);

%% 3. Optimize
R = 2;   % coverage radius (km)
p = 8;   % number of stations

A = D <= R;   % coverage matrix, computed once and reused everywhere below
[idx, x, u] = mclp(A, data.Weight, p);

fprintf('\nSelected Stations:\n');
disp(data(idx, {'Name','Lat','Lon','Type'}));

%% 4. Plot map
plotMap(data, idx, R, outDir);

%% 5. Save results
writetable(data(idx,:), fullfile(outDir, 'selected_stations.csv'));
fprintf('\nSaved: %s\n', fullfile(outDir, 'selected_stations.csv'));

%% 6. Sensitivity: coverage vs number of stations
% A is reused directly - no recomputation inside the loop
pRange = 1:15;
cov = zeros(size(pRange));

for k = 1:length(pRange)
    [~, ~, uk] = mclp(A, data.Weight, pRange(k));
    cov(k) = 100 * sum(data.Weight(uk==1)) / sum(data.Weight);
end

figure('Name','Sensitivity Analysis');
plot(pRange, cov, '-o', 'LineWidth', 2, 'MarkerFaceColor','b');
xlabel('Number of Stations (p)');
ylabel('Demand Coverage (%)');
title('Coverage vs Number of Charging Stations');
grid on;
exportgraphics(gcf, fullfile(outDir, 'sensitivity.png'), 'Resolution', 300);
fprintf('Saved: %s\n', fullfile(outDir, 'sensitivity.png'));