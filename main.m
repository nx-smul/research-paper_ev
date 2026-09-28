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
if ~isempty(csvFiles)
    [~, order] = sort(lower({csvFiles.name}));
    csvFiles = csvFiles(order);
end

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
    candidateCount = height(readtable(dataFile, 'ReadVariableNames', true));
    params = validateParams(params, cityName, csvFiles(i).name, candidateCount);

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
    if isempty(settings) || ~ismember('CityFile', settings.Properties.VariableNames)
        return;
    end

    cityFiles = string(settings.CityFile);
    matches = find(strcmpi(strtrim(cityFiles), cityName));
    if isempty(matches)
        return;
    end
    if numel(matches) > 1
        warning('main:DuplicateCitySettings', ...
            'Multiple settings rows match "%s"; using the first row.', cityName);
    end

    row = settings(matches(1), :);
    params.R      = scalarSetting(row, 'R', params.R);
    params.p      = scalarSetting(row, 'p', params.p);
    params.budget = parseBudget(scalarSetting(row, 'budget', params.budget));
    params.w.car  = scalarSetting(row, 'w_car', params.w.car);
    params.w.bike = scalarSetting(row, 'w_bike', params.w.bike);
    params.w.pop  = scalarSetting(row, 'w_pop', params.w.pop);
    params.w.cost = scalarSetting(row, 'w_cost', params.w.cost);
    params.minFast = scalarSetting(row, 'min_fast', params.minFast);
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

function value = scalarSetting(row, name, defaultValue)
    if ~ismember(name, row.Properties.VariableNames)
        value = defaultValue;
        return;
    end

    rawValue = row.(name);
    if iscell(rawValue)
        rawValue = rawValue{1};
    end
    if isstring(rawValue) || ischar(rawValue) || iscategorical(rawValue)
        value = str2double(string(rawValue));
    else
        value = rawValue(1);
    end
    if isempty(value)
        value = defaultValue;
    end
end

function params = validateParams(params, cityName, filename, candidateCount)
    numericFields = [params.R, params.p, params.budget, params.minFast, ...
        params.w.car, params.w.bike, params.w.pop, params.w.cost];
    if any(~isfinite(numericFields(~isinf(numericFields))))
        error('main:InvalidParameters', ...
            'Non-finite parameters found for %s (%s).', cityName, filename);
    end
    if ~isscalar(params.R) || params.R <= 0
        error('main:InvalidRadius', ...
            'Service radius for %s must be a positive scalar.', cityName);
    end
    if ~isscalar(params.budget) || params.budget < 0
        error('main:InvalidBudget', ...
            'Budget for %s must be nonnegative or Inf.', cityName);
    end

    weights = [params.w.car, params.w.bike, params.w.pop, params.w.cost];
    if any(~isfinite(weights)) || any(weights < 0) || sum(weights) <= 0
        error('main:InvalidWeights', ...
            'Demand weights for %s must be finite, nonnegative, and nonzero.', cityName);
    end
    weights = weights / sum(weights);
    [params.w.car, params.w.bike, params.w.pop, params.w.cost] = deal(weights(1), ...
        weights(2), weights(3), weights(4));

    params.p = round(params.p);
    if params.p < 1
        error('main:InvalidStationLimit', ...
            'Station limit p for %s must be at least 1.', cityName);
    end
    if params.p > candidateCount
        warning('main:StationLimitClamped', ...
            'Station limit p=%d exceeds %d candidates for %s; clamping to %d.', ...
            params.p, candidateCount, cityName, candidateCount);
        params.p = candidateCount;
    end
    params.minFast = round(params.minFast);
    if params.minFast < 0
        error('main:InvalidMinimumFast', ...
            'min_fast for %s cannot be negative.', cityName);
    end
    params.minFast = min(params.minFast, params.p);
end