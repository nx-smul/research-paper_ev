function selected = assignChargerType(selected, costProfile)
% ASSIGNCHARGERTYPE Assigns a charger recommendation and explicit site costs.
%   Transport hubs / intersections -> DC Fast (short dwell time, transient traffic,
%       drivers need to charge quickly and move on)
%   Malls / hospitals / universities / commercial / residential -> Level 2
%       (longer dwell time - shopping, working, studying, visiting - so a slower,
%       cheaper charger is sufficient and more cost-effective)
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
    chargerType = strings(n,1);
    hardwareCost = zeros(n,1);
    gridUpgradeCost = zeros(n,1);
    civilWorkCost = zeros(n,1);

    fastChargeTypes = ["TransportHub", "Intersection", "Highway", "BusTerminal"];
    stationTypes = string(selected.Type);
    isFastCharge = ismember(stationTypes, fastChargeTypes);

    chargerType(:) = "Level 2";
    chargerType(isFastCharge) = "DC Fast";

    hardwareCost(~isFastCharge) = costProfile.level2(1);
    gridUpgradeCost(~isFastCharge) = costProfile.level2(2);
    civilWorkCost(~isFastCharge) = costProfile.level2(3);
    hardwareCost(isFastCharge) = costProfile.dcFast(1);
    gridUpgradeCost(isFastCharge) = costProfile.dcFast(2);
    civilWorkCost(isFastCharge) = costProfile.dcFast(3);

    selected.ChargerType = chargerType;
    selected.HardwareCost = hardwareCost;
    selected.GridUpgradeCost = gridUpgradeCost;
    selected.CivilWorkCost = civilWorkCost;
    selected.AdjustedCost = selected.LandCost + hardwareCost ...
        + gridUpgradeCost + civilWorkCost;

    fprintf('\nCharger types assigned:\n');
    for i = 1:n
        fprintf('  %-28s -> %-8s (adjusted cost: %.1f)\n', ...
            string(selected.Name(i)), selected.ChargerType(i), selected.AdjustedCost(i));
    end
end