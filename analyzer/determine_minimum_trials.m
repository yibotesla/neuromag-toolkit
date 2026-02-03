function [min_trials, convergence_data] = determine_minimum_trials(trials, threshold, trial_counts, n_iterations)
    % DETERMINE_MINIMUM_TRIALS - Find minimum number of trials for stable average
    %
    % Syntax:
    %   [min_trials, convergence_data] = determine_minimum_trials(trials, threshold, trial_counts, n_iterations)
    %
    % Inputs:
    %   trials        - N_channels × N_samples_per_trial × N_trials, trial data
    %   threshold     - scalar, correlation threshold (default: 0.9)
    %   trial_counts  - vector, trial numbers to test (default: 10:10:N_trials)
    %   n_iterations  - scalar, number of random samples per trial count (default: 10)
    %
    % Outputs:
    %   min_trials        - scalar, minimum number of trials needed
    %   convergence_data  - struct with fields:
    %       .n_trials     - vector of trial counts tested
    %       .correlation  - vector of mean correlation coefficients
    %       .correlation_std - vector of standard deviations
    %       .rmse         - vector of mean RMSE values
    %       .rmse_std     - vector of standard deviations
    %
    % Description:
    %   Determines the minimum number of trials needed to achieve a stable
    %   averaged response. For each trial count, randomly samples trials
    %   multiple times and computes correlation with the grand average.
    %   The minimum trial count is where correlation reaches the threshold
    %   and the curve plateaus.
    %
    % Requirements: 6.5
    % Property: Property 27 - Minimum Trial Threshold Detection
    %
    % Example:
    %   [min_n, conv_data] = determine_minimum_trials(trials, 0.9);
    %   plot(conv_data.n_trials, conv_data.correlation);
    
    % Input validation
    if nargin < 1
        error('MEG:DetermineMinimumTrials:InsufficientInputs', ...
            'At least one input required: trials');
    end
    
    % Validate trials
    if ~isnumeric(trials) || ndims(trials) ~= 3
        error('MEG:DetermineMinimumTrials:InvalidTrials', ...
            'trials must be a 3D numeric array (N_channels × N_samples_per_trial × N_trials)');
    end
    
    % Get total number of trials
    n_total_trials = size(trials, 3);
    
    % Set default threshold
    if nargin < 2 || isempty(threshold)
        threshold = 0.9;
    end
    
    % Validate threshold
    if ~isscalar(threshold) || ~isnumeric(threshold) || threshold < 0 || threshold > 1
        error('MEG:DetermineMinimumTrials:InvalidThreshold', ...
            'threshold must be a scalar in range [0, 1]');
    end
    
    % Set default trial counts
    if nargin < 3 || isempty(trial_counts)
        % Test from 10 trials up to total, in steps of 10
        trial_counts = 10:10:n_total_trials;
        % Ensure we include the total number of trials
        if trial_counts(end) ~= n_total_trials
            trial_counts = [trial_counts, n_total_trials];
        end
    end
    
    % Validate trial_counts
    if ~isnumeric(trial_counts) || ~isvector(trial_counts)
        error('MEG:DetermineMinimumTrials:InvalidTrialCounts', ...
            'trial_counts must be a numeric vector');
    end
    
    % Remove trial counts that exceed available trials
    trial_counts = trial_counts(trial_counts <= n_total_trials);
    trial_counts = sort(unique(trial_counts));  % Sort and remove duplicates
    
    if isempty(trial_counts)
        error('MEG:DetermineMinimumTrials:NoValidTrialCounts', ...
            'No valid trial counts to test');
    end
    
    % Set default number of iterations
    if nargin < 4 || isempty(n_iterations)
        n_iterations = 10;
    end
    
    % Validate n_iterations
    if ~isscalar(n_iterations) || ~isnumeric(n_iterations) || n_iterations <= 0
        error('MEG:DetermineMinimumTrials:InvalidIterations', ...
            'n_iterations must be a positive scalar');
    end
    
    % Compute grand average (gold standard)
    grand_average = compute_grand_average(trials);
    
    % Initialize storage for results
    n_test_points = length(trial_counts);
    mean_correlations = zeros(1, n_test_points);
    std_correlations = zeros(1, n_test_points);
    mean_rmse = zeros(1, n_test_points);
    std_rmse = zeros(1, n_test_points);
    
    % Loop over each trial count
    for i = 1:n_test_points
        n_trials = trial_counts(i);
        
        % Storage for this trial count
        correlations = zeros(1, n_iterations);
        rmse_values = zeros(1, n_iterations);
        
        % Perform multiple random samplings
        for j = 1:n_iterations
            % Sample trials and compute average
            sampled_avg = sample_trials(trials, n_trials);
            
            % Compute metrics
            metrics = compute_convergence_metrics(sampled_avg, grand_average);
            
            correlations(j) = metrics.correlation;
            rmse_values(j) = metrics.rmse;
        end
        
        % Compute mean and standard deviation
        mean_correlations(i) = mean(correlations);
        std_correlations(i) = std(correlations);
        mean_rmse(i) = mean(rmse_values);
        std_rmse(i) = std(rmse_values);
    end
    
    % Find minimum trials where correlation >= threshold
    above_threshold = find(mean_correlations >= threshold);
    
    if isempty(above_threshold)
        warning('MEG:DetermineMinimumTrials:ThresholdNotReached', ...
            'Correlation threshold %.2f not reached with available trials. Maximum correlation: %.3f', ...
            threshold, max(mean_correlations));
        min_trials = n_total_trials;  % Return maximum available
    else
        min_trials = trial_counts(above_threshold(1));
    end
    
    % Create output structure
    convergence_data = struct();
    convergence_data.n_trials = trial_counts;
    convergence_data.correlation = mean_correlations;
    convergence_data.correlation_std = std_correlations;
    convergence_data.rmse = mean_rmse;
    convergence_data.rmse_std = std_rmse;
end
