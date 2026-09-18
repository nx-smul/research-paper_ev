function [idx, x, u] = mclp(A, demand, p, cost, budget)
% Solves the Maximal Covering Location Problem with an optional budget cap
%   A      - coverage matrix (n x n), A(i,j)=1 if site i covers demand point j
%   demand - combined demand score per site
%   p      - max number of stations to pick
%   cost   - cost per site (e.g., LandCost_LakhBDT column)
%   budget - total budget available (lakh BDT); use Inf to disable

    n = size(A, 1);
    demand = demand(:);
    cost = cost(:);
    A = double(A);

    f = [zeros(n,1); -demand];

    % Coverage-linking constraint
    Aineq = sparse([-A, speye(n)]);
    bineq = zeros(n,1);

    % Budget constraint (only on x, not u)
    if isfinite(budget)
        Aineq = [Aineq; sparse([cost', zeros(1,n)])];
        bineq = [bineq; budget];
    end

    % Station count constraint: at most p
    Aineq = [Aineq; sparse([ones(1,n), zeros(1,n)])];
    bineq = [bineq; p];

    lb = zeros(2*n,1);
    ub = ones(2*n,1);
    intcon = 1:2*n;

    opts = optimoptions('intlinprog', 'Display', 'off', 'RelativeGapTolerance', 1e-4);

    sol = intlinprog(f, intcon, Aineq, bineq, [], [], lb, ub, opts);

    x = round(sol(1:n));
    u = round(sol(n+1:end));
    idx = find(x == 1);

    if isinf(budget)
        budgetStr = 'unlimited';
    else
        budgetStr = sprintf('%.1f', budget);
    end

    fprintf('Selected %d stations | Coverage: %.1f%% | Cost used: %.1f/%s\n', ...
        sum(x), 100*sum(demand(u==1))/sum(demand), sum(cost(x==1)), budgetStr);
end