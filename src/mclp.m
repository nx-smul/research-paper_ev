function [idx, x, u] = mclp(A, demand, p)
% Solves the Maximal Covering Location Problem
%   A      - precomputed coverage matrix (n x n logical/double), A(i,j)=1 if site i covers demand j
%   demand - demand weight per site
%   p      - number of stations to pick

    n = size(A, 1);
    demand = demand(:);

    f = [zeros(n,1); -demand];

    % Sparse constraints - much faster for intlinprog
    Aineq = sparse([-A, speye(n)]);
    bineq = zeros(n,1);

    Aeq = sparse([ones(1,n), zeros(1,n)]);
    beq = p;

    lb = zeros(2*n,1);
    ub = ones(2*n,1);
    intcon = 1:2*n;

    opts = optimoptions('intlinprog', ...
        'Display', 'off', ...
        'RelativeGapTolerance', 1e-4, ...   % small speed/accuracy tradeoff
        'IntegerTolerance', 1e-5);

    sol = intlinprog(f, intcon, Aineq, bineq, Aeq, beq, lb, ub, opts);

    x = round(sol(1:n));
    u = round(sol(n+1:end));
    idx = find(x == 1);

    fprintf('Selected %d stations | Coverage: %.1f%%\n', ...
        sum(x), 100*sum(demand(u==1))/sum(demand));
end