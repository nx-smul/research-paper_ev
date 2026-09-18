function h = computeDemand(data, w)
% COMPUTEDEMAND Combines vehicle categories + other factors into one demand score
%   data - candidate table (must contain Weight_Car, Weight_Bike, PopDensity, LandCost)
%   w    - struct of weighting coefficients for each factor
%
%   h    - combined demand score per site (higher = more attractive to serve)

    % Normalize LandCost into a "penalty" (high cost = lower attractiveness)
    costPenalty = data.LandCost / max(data.LandCost);

    h = w.car  * data.Weight_Car ...
      + w.bike * data.Weight_Bike ...
      + w.pop  * data.PopDensity ...
      - w.cost * costPenalty;

    h = max(h, 0.01); % keep strictly positive for the optimizer

    fprintf('Demand scores computed (range: %.2f - %.2f).\n', min(h), max(h));
end