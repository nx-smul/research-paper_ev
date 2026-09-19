function [idx, typeIdx, x, u] = mclpWithChargerTypes(W, demand, p, cost, ...
        allowed, budget, typeNames, minTypeCounts)
%MCLPWITHCHARGERTYPES Selects sites and charger types jointly.
%   W(i,j,t) is the coverage credit from candidate j using type t to
%   cover demand point i. Each site can receive at most one charger type.

    [n, nSites, nTypes] = size(W);
    if n ~= nSites
        error('mclpWithChargerTypes:InvalidWeights', ...
            'Coverage weights must be square in their first two dimensions.');
    end
    if nargin < 7
        typeNames = strings(1, nTypes);
        typeNames(:) = "Type";
    end
    if nargin < 8
        minTypeCounts = zeros(1, nTypes);
    end

    demand = demand(:);
    cost = double(cost);
    allowed = logical(allowed);
    if ~isequal(size(cost), [n, nTypes]) || ~isequal(size(allowed), [n, nTypes])
        error('mclpWithChargerTypes:InvalidOptions', ...
            'Cost and allowed matrices must be n-by-number-of-types.');
    end
    minTypeCounts = minTypeCounts(:)';
    if numel(minTypeCounts) ~= nTypes
        error('mclpWithChargerTypes:InvalidMinimums', ...
            'Minimum charger counts must contain one value per charger type.');
    end

    nX = n * nTypes;
    yStart = nX + 1;
    f = [zeros(nX, 1); -demand];

    coverageRows = sparse(n, nX + n);
    for t = 1:nTypes
        cols = (t - 1) * n + (1:n);
        coverageRows(:, cols) = -double(W(:, :, t));
    end
    coverageRows(:, yStart:yStart + n - 1) = speye(n);
    Aineq = coverageRows;
    bineq = zeros(n, 1);

    siteRows = sparse(n, nX + n);
    for t = 1:nTypes
        cols = (t - 1) * n + (1:n);
        siteRows(:, cols) = speye(n);
    end
    Aineq = [Aineq; siteRows]; %#ok<AGROW>
    bineq = [bineq; ones(n, 1)]; %#ok<AGROW>

    minimumRows = sparse(nTypes, nX + n);
    for t = 1:nTypes
        cols = (t - 1) * n + (1:n);
        minimumRows(t, cols) = -1;
    end
    Aineq = [Aineq; minimumRows]; %#ok<AGROW>
    bineq = [bineq; -minTypeCounts(:)]; %#ok<AGROW>

    if isfinite(budget)
        budgetRow = sparse(1, nX + n);
        for t = 1:nTypes
            cols = (t - 1) * n + (1:n);
            budgetRow(cols) = cost(:, t)';
        end
        Aineq = [Aineq; budgetRow]; %#ok<AGROW>
        bineq = [bineq; budget]; %#ok<AGROW>
    end

    stationRow = sparse(1, nX + n);
    stationRow(1:nX) = 1;
    Aineq = [Aineq; stationRow]; %#ok<AGROW>
    bineq = [bineq; p]; %#ok<AGROW>

    lb = zeros(nX + n, 1);
    ub = ones(nX + n, 1);
    for t = 1:nTypes
        cols = (t - 1) * n + (1:n);
        ub(cols) = double(allowed(:, t));
    end
    intcon = 1:nX;

    opts = optimoptions('intlinprog', 'Display', 'off', ...
        'RelativeGapTolerance', 1e-4);
    [sol, ~, exitflag] = intlinprog(f, intcon, Aineq, bineq, [], [], ...
        lb, ub, opts);
    if exitflag <= 0 || isempty(sol)
        error('mclpWithChargerTypes:NoSolution', ...
            'No feasible charger/site plan was found for the supplied budget and limits.');
    end

    x = round(reshape(sol(1:nX), n, nTypes));
    u = sol(yStart:end);
    [idx, typeIdx] = find(x);

    budgetUsed = sum(sum(cost .* x));
    coveragePct = 100 * sum(demand .* u) / sum(demand);
    fprintf('-> Built %d station(s) | Demand covered: %.1f%% | Cost: %.1f\n', ...
        numel(idx), coveragePct, budgetUsed);
    for k = 1:numel(idx)
        fprintf('   %-28s -> %s\n', string(idx(k)), string(typeNames(typeIdx(k))));
    end
end
