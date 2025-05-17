function hSparse = sparseThreshold(hEst, threshold)
%SPARSETHRESHOLD Performs soft thresholding on channel estimate
%
% Inputs:
%   hEst     - Estimated channel (complex vector or matrix)
%   threshold - Threshold value
%
% Output:
%   hSparse  - Thresholded (sparse) channel estimate

    % Soft-thresholding operation
    hSparse = hEst .* (abs(hEst) > threshold);
end
