function [trials, trial_times, epoch_info] = extract_epochs(data, trigger_indices, fs, pre_time, post_time, varargin)
    % EXTRACT_EPOCHS - Extract trial epochs from continuous data
    %
    % Syntax:
    %   [trials, trial_times] = extract_epochs(data, trigger_indices, fs, pre_time, post_time)
    %   [trials, trial_times, epoch_info] = extract_epochs(..., 'Name', Value)
    %
    % Inputs:
    %   data            - N_channels × N_samples, continuous data
    %   trigger_indices - 1 × N_triggers, trigger point indices
    %   fs              - scalar, sampling rate (Hz)
    %   pre_time        - scalar, time before trigger (seconds)
    %   post_time       - scalar, time after trigger (seconds)
    %
    % Optional Name-Value Pairs:
    %   'BaselineCorrection' - 是否进行基线校正（默认: true）
    %   'BaselineWindow'     - 基线窗口 [start, end] 秒（默认: [-pre_time, 0]）
    %   'Verbose'            - 是否输出信息（默认: false）
    %   'ReturnTrialData'    - 是否返回TrialData对象（默认: false）
    %
    % Outputs:
    %   trials       - N_channels × N_samples_per_trial × N_trials, epoched data
    %                  或 TrialData 对象（如果 ReturnTrialData=true）
    %   trial_times  - 1 × N_samples_per_trial, relative time axis (seconds)
    %   epoch_info   - 结构体，包含分割信息:
    %                  .n_triggers: 总触发数
    %                  .n_valid_trials: 有效试次数
    %                  .skipped_trials: 跳过的试次索引
    %                  .valid_trigger_indices: 有效试次的触发索引
    %                  .sample_info: [start_sample, end_sample, offset] 矩阵
    %
    % Description:
    %   Extracts trial epochs from continuous data based on trigger points.
    %   Each trial spans from pre_time before to post_time after the trigger.
    %   Handles boundary cases where triggers are too close to data edges.
    %   Creates a relative time axis with t=0 at the trigger point.
    %
    % Requirements: 5.4
    % Property: Property 22 - Epoching Correctness
    %
    % Example:
    %   fs = 4800;
    %   pre_time = 0.2;   % 200ms before trigger
    %   post_time = 1.3;  % 1300ms after trigger
    %   [trials, trial_times, info] = extract_epochs(data, trigger_indices, fs, ...
    %       pre_time, post_time, 'BaselineCorrection', true, 'Verbose', true);
    
    % Parse optional arguments
    p = inputParser;
    addRequired(p, 'data');
    addRequired(p, 'trigger_indices');
    addRequired(p, 'fs');
    addRequired(p, 'pre_time');
    addRequired(p, 'post_time');
    addParameter(p, 'BaselineCorrection', true, @islogical);
    addParameter(p, 'BaselineWindow', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
    addParameter(p, 'Verbose', false, @islogical);
    addParameter(p, 'ReturnTrialData', false, @islogical);
    parse(p, data, trigger_indices, fs, pre_time, post_time, varargin{:});
    
    baseline_correction = p.Results.BaselineCorrection;
    baseline_window = p.Results.BaselineWindow;
    verbose = p.Results.Verbose;
    return_trial_data = p.Results.ReturnTrialData;
    
    % Set default baseline window
    if isempty(baseline_window)
        baseline_window = [-pre_time, 0];
    end
    
    % Validate data
    if ~isnumeric(data) || ndims(data) > 2
        error('MEG:ExtractEpochs:InvalidData', ...
            'data must be a 2D numeric matrix (N_channels × N_samples)');
    end
    
    % Validate trigger_indices
    if ~isnumeric(trigger_indices) || ~isvector(trigger_indices)
        error('MEG:ExtractEpochs:InvalidTriggers', ...
            'trigger_indices must be a numeric vector');
    end
    
    % Validate sampling rate
    if ~isscalar(fs) || ~isnumeric(fs) || fs <= 0
        error('MEG:ExtractEpochs:InvalidSamplingRate', ...
            'fs must be a positive numeric scalar');
    end
    
    % Validate time parameters
    if ~isscalar(pre_time) || ~isnumeric(pre_time) || pre_time < 0
        error('MEG:ExtractEpochs:InvalidPreTime', ...
            'pre_time must be a non-negative numeric scalar');
    end
    
    if ~isscalar(post_time) || ~isnumeric(post_time) || post_time <= 0
        error('MEG:ExtractEpochs:InvalidPostTime', ...
            'post_time must be a positive numeric scalar');
    end
    
    % Get data dimensions
    [n_channels, n_samples] = size(data);
    
    % Convert time to samples
    pre_samples = round(pre_time * fs);
    post_samples = round(post_time * fs);
    samples_per_trial = pre_samples + post_samples;  % 不需要+1，使用完整范围
    
    % Create relative time axis
    trial_times = (0:samples_per_trial-1) / fs - pre_time;
    
    % Initialize output and info
    n_triggers = length(trigger_indices);
    valid_trials = [];
    skipped_trials = [];
    sample_info = [];
    
    if verbose
        fprintf('提取试次:\n');
        fprintf('  总触发数: %d\n', n_triggers);
        fprintf('  数据长度: %d 采样点 (%.2f 秒)\n', n_samples, n_samples/fs);
        fprintf('  试次长度: %.2f 秒 (pre: %.2f, post: %.2f)\n', ...
            pre_time + post_time, pre_time, post_time);
    end
    
    % Check which triggers are valid (not too close to edges)
    for i = 1:n_triggers
        trigger_idx = trigger_indices(i);
        start_idx = trigger_idx - pre_samples;
        end_idx = start_idx + samples_per_trial - 1;
        
        % Check if trial is within data bounds
        if start_idx >= 1 && end_idx <= n_samples
            valid_trials = [valid_trials, i];
            sample_info = [sample_info; start_idx, end_idx, -pre_samples];
        else
            skipped_trials = [skipped_trials, i];
            if verbose
                if start_idx < 1
                    fprintf('  警告: 触发 %d (位置 %d) 起点 < 1，跳过\n', i, trigger_idx);
                else
                    fprintf('  警告: 触发 %d (位置 %d) 终点 > 数据长度，跳过\n', i, trigger_idx);
                end
            end
        end
    end
    
    % Handle case where no valid trials exist
    if isempty(valid_trials)
        warning('MEG:ExtractEpochs:NoValidTrials', ...
            'No valid trials found. All triggers too close to data edges.');
        trials = [];
        trial_times = [];
        epoch_info = struct();
        epoch_info.n_triggers = n_triggers;
        epoch_info.n_valid_trials = 0;
        epoch_info.skipped_trials = skipped_trials;
        epoch_info.valid_trigger_indices = [];
        epoch_info.sample_info = [];
        return;
    end
    
    % Extract valid trials
    n_valid_trials = length(valid_trials);
    trials = zeros(n_channels, samples_per_trial, n_valid_trials);
    
    for i = 1:n_valid_trials
        trial_idx = valid_trials(i);
        trigger_idx = trigger_indices(trial_idx);
        start_idx = trigger_idx - pre_samples;
        end_idx = start_idx + samples_per_trial - 1;
        
        % Extract trial data
        trials(:, :, i) = data(:, start_idx:end_idx);
    end
    
    % Apply baseline correction if requested
    if baseline_correction
        % Convert baseline window to samples
        baseline_start_sample = round((baseline_window(1) + pre_time) * fs) + 1;
        baseline_end_sample = round((baseline_window(2) + pre_time) * fs) + 1;
        
        % Ensure indices are valid
        baseline_start_sample = max(1, baseline_start_sample);
        baseline_end_sample = min(samples_per_trial, baseline_end_sample);
        
        if baseline_end_sample > baseline_start_sample
            % Calculate baseline for each trial
            for i = 1:n_valid_trials
                baseline_mean = mean(trials(:, baseline_start_sample:baseline_end_sample, i), 2);
                trials(:, :, i) = trials(:, :, i) - baseline_mean;
            end
            
            if verbose
                fprintf('  已应用基线校正 (窗口: [%.3f, %.3f] 秒)\n', ...
                    baseline_window(1), baseline_window(2));
            end
        end
    end
    
    if verbose
        fprintf('  成功提取 %d 个有效试次 (跳过 %d 个)\n', n_valid_trials, length(skipped_trials));
    end
    
    % Build epoch_info structure
    epoch_info = struct();
    epoch_info.n_triggers = n_triggers;
    epoch_info.n_valid_trials = n_valid_trials;
    epoch_info.skipped_trials = skipped_trials;
    epoch_info.valid_trigger_indices = trigger_indices(valid_trials);
    epoch_info.sample_info = sample_info;
    epoch_info.pre_time = pre_time;
    epoch_info.post_time = post_time;
    epoch_info.samples_per_trial = samples_per_trial;
    
    % Ensure trial_times is a row vector
    trial_times = trial_times(:)';
    
    % Optionally return TrialData object
    if return_trial_data
        trial_data_obj = TrialData();
        trial_data_obj.trials = trials;
        trial_data_obj.trial_times = trial_times;
        trial_data_obj.trigger_indices = epoch_info.valid_trigger_indices;
        trial_data_obj.fs = fs;
        trial_data_obj.pre_time = pre_time;
        trial_data_obj.post_time = post_time;
        trials = trial_data_obj;
    end
end
