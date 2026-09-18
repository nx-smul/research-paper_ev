%% EV Charging Station Optimization - Dhaka City
% Now includes vehicle category demand (cars, motorbikes - rickshaws excluded),
% population density, and land cost as combined factors.

clear; clc; close all;

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
dataFile = fullfile(root, 'data', 'candidates.csv');
outDir   = fullfile(root, 'results');
if ~exist(outDir, 'dir'); mkdir(outDir); end

%% 1. Load data
data = loadData(dataFile);

%% 2. Distance matrix
D = distMatrix(data.Lat, data.Lon);

%% 3. Combine factors into one demand score
% Adjust these weights based on your paper's assumptions/priorities
w.car  = 1.0;   % weight for private EV car demand
w.bike = 1.2;   % weight for e-motorbike demand (higher - more common in Dhaka)
w.pop  = 0.8;   % weight for population density
w.cost = 1.5;   % penalty weight for land cost (higher = more cost-averse siting)

h = computeDemand(data, w);

%% 4. Optimize
R = 2;              % coverage radius (km)
p = 8;               % max number of stations
budget = 30;         % total budget in cost units (sum of LandCost of selected sites)

A = D <= R;
[idx, x, u] = mclp(A, h, p, data.LandCost, budget);

fprintf('\nSelected Stations:\n');
disp(data(idx, {'Name','Lat','Lon','Type','Weight_Car','Weight_Bike','LandCost'}));

%% 5. Plot map
plotMap(data, idx, R, outDir);

%% 6. Save results
writetable(data(idx,:), fullfile(outDir, 'selected_stations.csv'));
fprintf('\nSaved: %s\n', fullfile(outDir, 'selected_stations.csv'));

%% 7. Sensitivity: coverage vs number of stations (budget unconstrained here)
pRange = 1:15;
cov = zeros(size(pRange));

for k = 1:length(pRange)
    [~, ~, uk] = mclp(A, h, pRange(k), data.LandCost, Inf);
    cov(k) = 100 * sum(h(uk==1)) / sum(h);
end

figure('Name','Sensitivity Analysis');
plot(pRange, cov, '-o', 'LineWidth', 2, 'MarkerFaceColor','b');
xlabel('Number of Stations (p)');
ylabel('Demand Coverage (%)');
title('Coverage vs Number of Charging Stations');
grid on;
exportgraphics(gcf, fullfile(outDir, 'sensitivity.png'), 'Resolution', 300);
fprintf('Saved: %s\n', fullfile(outDir, 'sensitivity.png'));%% EV Charging Station Optimization - Dhaka City
% Now includes vehicle category demand (cars, motorbikes - rickshaws excluded),
% population density, and land cost as combined factors.

clear; clc; close all;

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
dataFile = fullfile(root, 'data', 'candidates.csv');
outDir   = fullfile(root, 'results');
if ~exist(outDir, 'dir'); mkdir(outDir); end

%% 1. Load data
data = loadData(dataFile);

%% 2. Distance matrix
D = distMatrix(data.Lat, data.Lon);

%% 3. Combine factors into one demand score
% Adjust these weights based on your paper's assumptions/priorities
w.car  = 1.0;   % weight for private EV car demand
w.bike = 1.2;   % weight for e-motorbike demand (higher - more common in Dhaka)
w.pop  = 0.8;   % weight for population density
w.cost = 1.5;   % penalty weight for land cost (higher = more cost-averse siting)

h = computeDemand(data, w);

%% 4. Optimize
R = 2;              % coverage radius (km)
p = 8;               % max number of stations
budget = 30;         % total budget in cost units (sum of LandCost of selected sites)

A = D <= R;
[idx, x, u] = mclp(A, h, p, data.LandCost, budget);

fprintf('\nSelected Stations:\n');
disp(data(idx, {'Name','Lat','Lon','Type','Weight_Car','Weight_Bike','LandCost'}));

%% 5. Plot map
plotMap(data, idx, R, outDir);

%% 6. Save results
writetable(data(idx,:), fullfile(outDir, 'selected_stations.csv'));
fprintf('\nSaved: %s\n', fullfile(outDir, 'selected_stations.csv'));

%% 7. Sensitivity: coverage vs number of stations (budget unconstrained here)
pRange = 1:15;
cov = zeros(size(pRange));

for k = 1:length(pRange)
    [~, ~, uk] = mclp(A, h, pRange(k), data.LandCost, Inf);
    cov(k) = 100 * sum(h(uk==1)) / sum(h);
end

figure('Name','Sensitivity Analysis');
plot(pRange, cov, '-o', 'LineWidth', 2, 'MarkerFaceColor','b');
xlabel('Number of Stations (p)');
ylabel('Demand Coverage (%)');
title('Coverage vs Number of Charging Stations');
grid on;
exportgraphics(gcf, fullfile(outDir, 'sensitivity.png'), 'Resolution', 300);
fprintf('Saved: %s\n', fullfile(outDir, 'sensitivity.png'));