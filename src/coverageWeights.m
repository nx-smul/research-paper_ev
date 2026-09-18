function W = coverageWeights(D, R)
% COVERAGEWEIGHTS Computes distance-decayed coverage credit matrix
%   D - distance matrix (n x n), km
%   R - coverage radius (km)
%
%   W(i,j) = 1 - d(i,j)/R  for d <= R  (linear decay, full credit at d=0)
%           = 0            for d > R

    W = 1 - D ./ R;
    W(W < 0) = 0;
    W(D > R) = 0;   % safety, in case of floating point edge cases at d = R
end