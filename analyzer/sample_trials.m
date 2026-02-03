function sampled_average = sample_trials(trials, n_samples)
    % SAMPLE_TRIALS - Randomly sample N trials and compute their average
    %
    % Syntax:
    %   sampled_average = sample_trials(trials, n_samples)
    %
    % Inputs:
    %   trials    - N_channels × N_samples_per_trial × N_trials, trial data
    %   n_samples - scalar, number of trials to randomly sample
    %
    % Outputs:
    %   sampled_average - N_channels × N_samples_per_trial, averaged response
    %
    % Description:
    %   Randomly samples N trials from the full trial set and computes
    %   their arithmetic mean. This is used for convergence analysis to
    %   determine how many trials are needed for a stable average.
    %   Sampling is done without replacement.
    %
    % Requirements: 6.2
    % Property: Property 24 - Random Sampling Size
    %
    % Example:
    %   sampled_avg = sample_trials(trials, 20);  % Sample 20 trials
    
    % Input validation
    if nargin < 2
        error('MEG:SampleTrials:InsufficientInputs', ...
            'Two inputs required: trials, n_samples');
    end
    
    % Validate trials
    if ~isnumeric(trials)
        error('MEG:SampleTrials:InvalidTrials', ...
            'trials must be a numeric array');
    end
    
    % Check dimensions
    if ndims(trials) ~= 3
        error('MEG:SampleTrials:InvalidDimensions', ...
            'trials must be a 3D array (N_channels × N_samples_per_trial × N_trials)');
    end
    
    % Validate n_samples
    if ~isscalar(n_samples) || ~isnumeric(n_samples) || n_samples <= 0 || n_samples ~= round(n_samples)
        error('MEG:SampleTrials:InvalidNSamples', ...
            'n_samples must be a positive integer scalar');
    end
    
    % Get dimensions
    [n_channels, n_samples_per_trial, n_trials] = size(trials);
    
    % Check if n_samples exceeds available trials
    if n_samples > n_trials
        error('MEG:SampleTrials:InsufficientTrials', ...
            'Requested %d samples but only %d trials available', ...
            n_samples, n_trials);
    end
    
    % Randomly sample trial indices without replacement
    trial_indices = randperm(n_trials, n_samples);
    
    % Extract sampled trials
    sampled_trials = trials(:, :, trial_indices);
    
    % Compute average of sampled trials
    sampled_average = mean(sampled_trials, 3);
    
    % Verify output dimensions
    assert(size(sampled_average, 1) == n_channels, ...
        'Output channel count mismatch');
    assert(size(sampled_average, 2) == n_samples_per_trial, ...
        'Output sample count mismatch');
end
