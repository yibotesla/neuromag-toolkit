function metrics = compute_convergence_metrics(sampled_average, grand_average)
    % COMPUTE_CONVERGENCE_METRICS - Calculate convergence metrics
    %
    % Syntax:
    %   metrics = compute_convergence_metrics(sampled_average, grand_average)
    %
    % Inputs:
    %   sampled_average - N_channels × N_samples_per_trial, sampled average
    %   grand_average   - N_channels × N_samples_per_trial, grand average (gold standard)
    %
    % Outputs:
    %   metrics - struct with fields:
    %       .correlation - correlation coefficient between sampled and grand average
    %       .rmse        - root mean square error
    %
    % Description:
    %   Computes convergence metrics to evaluate how well a sampled average
    %   approximates the grand average. The correlation coefficient measures
    %   the similarity of waveform shapes, while RMSE measures the absolute
    %   difference in amplitude.
    %
    % Requirements: 6.3
    % Property: Property 25 - Convergence Metric Calculation
    %
    % Example:
    %   metrics = compute_convergence_metrics(sampled_avg, grand_avg);
    %   fprintf('Correlation: %.3f, RMSE: %.3e\n', metrics.correlation, metrics.rmse);
    
    % Input validation
    if nargin < 2
        error('MEG:ComputeConvergenceMetrics:InsufficientInputs', ...
            'Two inputs required: sampled_average, grand_average');
    end
    
    % Validate inputs
    if ~isnumeric(sampled_average) || ~isnumeric(grand_average)
        error('MEG:ComputeConvergenceMetrics:InvalidInputs', ...
            'Both inputs must be numeric arrays');
    end
    
    % Check dimensions match
    if ~isequal(size(sampled_average), size(grand_average))
        error('MEG:ComputeConvergenceMetrics:DimensionMismatch', ...
            'sampled_average and grand_average must have the same dimensions');
    end
    
    % Check for 2D arrays
    if ndims(sampled_average) ~= 2 || ndims(grand_average) ~= 2
        error('MEG:ComputeConvergenceMetrics:InvalidDimensions', ...
            'Inputs must be 2D arrays (N_channels × N_samples_per_trial)');
    end
    
    % Flatten arrays for correlation and RMSE calculation
    sampled_vec = sampled_average(:);
    grand_vec = grand_average(:);
    
    % Calculate correlation coefficient
    % Use corrcoef which returns a 2×2 correlation matrix
    corr_matrix = corrcoef(sampled_vec, grand_vec);
    correlation = corr_matrix(1, 2);  % Off-diagonal element
    
    % Handle edge case where both signals are constant (correlation undefined)
    if isnan(correlation)
        warning('MEG:ComputeConvergenceMetrics:UndefinedCorrelation', ...
            'Correlation is undefined (constant signals). Setting to 0.');
        correlation = 0;
    end
    
    % Calculate RMSE (Root Mean Square Error)
    squared_errors = (sampled_vec - grand_vec).^2;
    rmse = sqrt(mean(squared_errors));
    
    % Create output structure
    metrics = struct();
    metrics.correlation = correlation;
    metrics.rmse = rmse;
    
    % Verify property constraints
    assert(metrics.correlation >= -1 && metrics.correlation <= 1, ...
        'Correlation coefficient must be in range [-1, 1]');
    assert(metrics.rmse >= 0, ...
        'RMSE must be non-negative');
end
