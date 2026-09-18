function [idx, x, u] = mclp(W, demand, p, cost, budget)
% Solves the (distance-weighted) Maximal Covering Location Problem
%   W      - coverage credit matrix (n x n), values in [0,1]
%   demand - combined demand score per site
%   p      - max number of stations to pick
%   cost   - relative cost ranking per site
%   budget - total budget cap; use Inf to disable

    n = size(W, 1);
    demand = demand(:);
    cost = cost(:);
    W = double(W);

    f = [zeros(n,1); -demand];

    Aineq = sparse([-W, speye(n)]);
    bineq = zeros(n,1);

    if isfinite(budget)
        Aineq = [Aineq; sparse([cost', zeros(1,n)])];
        bineq = [bineq; budget];
    end

    Aineq = [Aineq; sparse([ones(1,n), zeros(1,n)])];
    bineq = [bineq; p];

    lb = zeros(2*n,1);
    ub = ones(2*n,1);
    intcon = 1:n;

    opts = optimoptions('intlinprog', 'Display', 'off', 'RelativeGapTolerance', 1e-4);
    sol = intlinprog(f, intcon, Aineq, bineq, [], [], lb, ub, opts);

    x = round(sol(1:n));
    u = sol(n+1:end);
    idx = find(x == 1);

    if isinf(budget)
        budgetStr = 'no limit';
    else
        budgetStr = sprintf('%.0f', budget);
    end

    coveragePct = 100 * sum(demand.*u) / sum(demand);
    costUsed = sum(cost(x==1));

    fprintf('-> Built %d station(s)  |  Demand covered: %.1f%%  |  Cost: %.0f (limit: %s)\n', ...
        sum(x), coveragePct, costUsed, budgetStr);
end