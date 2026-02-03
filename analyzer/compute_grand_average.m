function grand_average = compute_grand_average(trials)
    % COMPUTE_GRAND_AVERAGE - Compute grand average across trials
    %
    % Syntax:
    %   grand_average = compute_grand_average(trials)
    %
    % Inputs:
    %   trials - N_channels × N_samples_per_trial × N_trials, trial data
    %
    % Outputs:
    %   grand_average - N_channels × N_samples_per_trial, averaged response
    %
    % Description:
    %   Computes the arithmetic mean across all trials at each time point.
    %   This is the standard approach for computing evoked responses in
    %   MEG/EEG analysis. The grand average represents the time-locked
    %   response to the stimulus, with random noise averaged out.
    %
    % Requirements: 5.5, 6.1
    % Property: Property 23 - Grand Average Calculation
    %
    % Example:
    %   grand_avg = compute_grand_average(trials);
    %   plot(trial_times, grand_avg(1, :));  % Plot channel 1
    
    % Input validation
    if nargin < 1
        error('MEG:ComputeGrandAverage:InsufficientInputs', ...
            'One input required: trials');
    end
    
    % Validate trials
    if ~isnumeric(trials)
        error('MEG:ComputeGrandAverage:InvalidTrials', ...
            'trials must be a numeric array');
    end
    
    % Check dimensions
    if ndims(trials) ~= 3
        error('MEG:ComputeGrandAverage:InvalidDimensions', ...
            'trials must be a 3D array (N_channels × N_samples_per_trial × N_trials)');
    end
    
    % Handle empty input
    if isempty(trials)
        warning('MEG:ComputeGrandAverage:EmptyTrials', ...
            'Empty trials array provided. Returning empty grand average.');
        grand_average = [];
        return;
    end
    
    % Get dimensions
    [n_channels, n_samples_per_trial, n_trials] = size(trials);
    
    % Check for sufficient trials
    if n_trials < 1
        warning('MEG:ComputeGrandAverage:InsufficientTrials', ...
            'No trials available for averaging.');
        grand_average = [];
        return;
    end
    
    % Compute arithmetic mean across trials (dimension 3)
    grand_average = mean(trials, 3);
    
    % Verify output dimensions
    assert(size(grand_average, 1) == n_channels, ...
        'Output channel count mismatch');
    assert(size(grand_average, 2) == n_samples_per_trial, ...
        'Output sample count mismatch');
end
