function selected = assignChargerType(selected, costProfile)
% ASSIGNCHARGERTYPE Adds charger options and explicit site costs.
%   Level 2 is available at every site. DC Fast is available at transport
%   hubs, intersections, highways, bus terminals, and high-car-demand sites.
%   The optimizer chooses the final type subject to cost and policy limits.
%
%   Adds three columns to the input table:
%       ChargerType            - "DC Fast" or "Level 2"
%       HardwareCost            - charger hardware cost
%       GridUpgradeCost         - transformer, connection, and electrical work
%       CivilWorkCost           - foundation, cabling, and site preparation
%       AdjustedCost            - total capital cost used by the optimizer

    if nargin < 2
        costProfile.level2 = [4, 1, 1];
        costProfile.dcFast = [12, 8, 4];
    end

    requiredColumns = ["Name", "Type", "LandCost"];
    availableColumns = string(selected.Properties.VariableNames);
    missingColumns = requiredColumns(~ismember(requiredColumns, availableColumns));
    if ~isempty(missingColumns)
        error('assignChargerType:MissingColumns', ...
            'Missing required column(s): %s', strjoin(missingColumns, ', '));
    end

    n = height(selected);
    hardwareCost = zeros(n,1);
    gridUpgradeCost = zeros(n,1);
    civilWorkCost = zeros(n,1);

    fastChargeTypes = ["TransportHub", "Intersection", "Highway", "BusTerminal"];
    stationTypes = string(selected.Type);
    isFastCharge = ismember(stationTypes, fastChargeTypes);

    % Level 2 is available at every candidate. DC Fast is available at
    % high-turnover locations or locations with strong car demand.
    dcFastEligible = isFastCharge | (selected.Weight_Car >= 8);
    level2Cost = selected.LandCost + sum(costProfile.level2);
    dcFastCost = selected.LandCost + sum(costProfile.dcFast);

    selected.Level2Eligible = true(n,1);
    selected.DCFastEligible = dcFastEligible;
    selected.Level2AdjustedCost = level2Cost;
    selected.DCFastAdjustedCost = dcFastCost;

    % Retain a default recommendation for reports and backwards-compatible
    % callers. The optimization can now choose a different type per site.
    chargerType = repmat("Level 2", n, 1);
    chargerType(dcFastEligible) = "DC Fast";
    selected.ChargerType = chargerType;
    selected.HardwareCost = zeros(n,1);
    selected.GridUpgradeCost = zeros(n,1);
    selected.CivilWorkCost = zeros(n,1);
    selected.HardwareCost(dcFastEligible) = costProfile.dcFast(1);
    selected.GridUpgradeCost(dcFastEligible) = costProfile.dcFast(2);
    selected.CivilWorkCost(dcFastEligible) = costProfile.dcFast(3);
    selected.AdjustedCost = selected.LandCost + selected.HardwareCost ...
        + selected.GridUpgradeCost + selected.CivilWorkCost;

    fprintf('\nCharger types assigned:\n');
    for i = 1:n
        fprintf('  %-28s -> %-8s (adjusted cost: %.1f)\n', ...
            string(selected.Name(i)), selected.ChargerType(i), selected.AdjustedCost(i));
    end
end