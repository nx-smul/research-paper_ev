function h = computeDemand(data, w)
% COMPUTEDEMAND Combines vehicle categories + other factors into one demand score
%   data - candidate table:
%       Weight_Car         - private EV car demand (1-10, qualitative estimate)
%       Weight_Bike        - e-motorbike/scooter demand (1-10, qualitative estimate)
%       PopDensity         - population density score (1-10, derived from BBS 2022 census)
%       LandCost_LakhBDT   - estimated land + installation cost (lakh BDT, real currency)
%   w    - struct of weighting coefficients (car, bike, pop, cost)
%
%   h    - combined demand score per site (higher = more attractive to serve)

    costPenalty = data.LandCost_LakhBDT / max(data.LandCost_LakhBDT);

    h = w.car  * data.Weight_Car ...
      + w.bike * data.Weight_Bike ...
      + w.pop  * data.PopDensity ...
      - w.cost * costPenalty;

    h = max(h, 0.01); % keep strictly positive for the optimizer

    fprintf('Demand scores computed (range: %.2f - %.2f).\n', min(h), max(h));
end