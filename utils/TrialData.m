classdef TrialData
    % TrialData - Data structure for epoched trial data
    %
    % Properties:
    %   trials          - N_channels × N_samples_per_trial × N_trials
    %   trial_times     - 1 × N_samples_per_trial, relative time axis
    %   trigger_indices - 1 × N_trials, trigger points in original data
    %   fs              - scalar, sampling rate (Hz)
    %   pre_time        - scalar, time before trigger (seconds)
    %   post_time       - scalar, time after trigger (seconds)
    
    properties
        trials          % N_channels × N_samples_per_trial × N_trials
        trial_times     % 1 × N_samples_per_trial
        trigger_indices % 1 × N_trials
        fs              % scalar
        pre_time        % scalar
        post_time       % scalar
    end
    
    methods
        function obj = TrialData()
            % Constructor - initialize empty TrialData structure
            obj.trials = [];
            obj.trial_times = [];
            obj.trigger_indices = [];
            obj.fs = [];
            obj.pre_time = [];
            obj.post_time = [];
        end
        
        function n_trials = get_n_trials(obj)
            % Get the number of trials
            if isempty(obj.trials)
                n_trials = 0;
            else
                n_trials = size(obj.trials, 3);
            end
        end
        
        function n_channels = get_n_channels(obj)
            % Get the number of channels
            if isempty(obj.trials)
                n_channels = 0;
            else
                n_channels = size(obj.trials, 1);
            end
        end
    end
end
