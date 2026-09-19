%% EV Charging Station Optimization - Multi-City Runner
% Reads every candidate CSV in data/ and applies per-city parameters from
% settings.csv, falling back to defaults if a city isn't listed there.

clear; clc; close all;

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
dataDir      = fullfile(root, 'data');
geodataDir   = fullfile(root, 'geodata');
cacheDir     = fullfile(root, 'cache');
distanceDir  = fullfile(cacheDir, 'road_distances');
mapsDir      = fullfile(geodataDir, 'maps');
resultsDir   = fullfile(root, 'results');
settingsFile = fullfile(root, 'settings.csv');
localRoadGraphFile = fullfile(mapsDir, 'bangladesh_roads.shp');

%% Default parameters (used if a city has no row in settings.csv)
defaultParams.w.car  = 0.25;
defaultParams.w.bike = 0.30;
defaultParams.w.pop  = 0.20;
defaultParams.w.cost = 0.25;
defaultParams.R      = 2;
defaultParams.p      = 8;
defaultParams.budget = 35;   % relative cost units, not currency
defaultParams.minFast = 2;   % minimum DC Fast sites when feasible

% Explicit relative capital-cost components:
% [charger hardware, grid upgrade, civil/site work].
costProfile.level2 = [4, 1, 1];
costProfile.dcFast = [12, 8, 4];

%% Load settings table (if it exists)
if exist(settingsFile, 'file')
    settings = readtable(settingsFile, 'TextType', 'string');
    fprintf('Loaded settings for %d cities.\n', height(settings));
else
    settings = table();
    fprintf('No settings.csv found - using default parameters for all cities.\n');
end

%% Find all candidate CSV files in data/ (excluding settings.csv)
csvFiles = dir(fullfile(dataDir, '*.csv'));
csvFiles = csvFiles(~strcmpi({csvFiles.name}, 'settings.csv'));

if isempty(csvFiles)
    error('No candidate CSV files found in %s.', dataDir);
end

fprintf('Found %d city dataset(s):\n', length(csvFiles));
for i = 1:length(csvFiles)
    fprintf('  - %s\n', csvFiles(i).name);
end

summaryRows = [];

%% Run the pipeline for each city
for i = 1:length(csvFiles)
    dataFile = fullfile(dataDir, csvFiles(i).name);
    [~, cityName] = fileparts(csvFiles(i).name);
    outDir = fullfile(resultsDir, cityName);
    roadDistanceFile = fullfile(distanceDir, [cityName '_road_distances.csv']);

    params = getCityParams(settings, cityName, defaultParams);

    fprintf('\n========== Processing: %s ==========\n', cityName);
    fprintf('R=%g km | p=%d | budget=%s\n', params.R, params.p, budgetLabel(params.budget));

    citySummary = runCityOptimization( ...
        dataFile, outDir, params, roadDistanceFile, costProfile, ...
        localRoadGraphFile, cacheDir, cityName);
    if isempty(summaryRows)
        summaryRows = citySummary;
    else
        summaryRows(end + 1, 1) = citySummary; %#ok<SAGROW>
    end
end

summaryFile = fullfile(resultsDir, 'all_cities_summary.csv');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end
writetable(struct2table(summaryRows), summaryFile);
fprintf('\nSaved cross-city summary: %s\n', summaryFile);
fprintf('\nAll cities processed. Results saved under: %s\n', resultsDir);

%% ---- Local helper functions ----
function params = getCityParams(settings, cityName, defaultParams)
    params = defaultParams;
    if isempty(settings) || ~any(strcmpi(settings.CityFile, cityName))
        return;
    end
    row = settings(strcmpi(settings.CityFile, cityName), :);
    params.R      = row.R;
    params.p      = row.p;
    params.budget = parseBudget(row.budget);
    params.w.car  = row.w_car;
    params.w.bike = row.w_bike;
    params.w.pop  = row.w_pop;
    params.w.cost = row.w_cost;
    if ismember("min_fast", string(row.Properties.VariableNames))
        params.minFast = row.min_fast;
    end
end

function b = parseBudget(val)
    if isstring(val) || ischar(val)
        b = str2double(val);
    else
        b = val;
    end
end

function s = budgetLabel(v)
    if isinf(v)
        s = 'unlimited';
    else
        s = sprintf('%g', v);
    end
end