function trigger_indices = detect_triggers(trigger_signal, threshold, min_interval, varargin)
    % DETECT_TRIGGERS - Detect trigger events in a trigger signal
    %
    % Syntax:
    %   trigger_indices = detect_triggers(trigger_signal, threshold, min_interval)
    %   trigger_indices = detect_triggers(trigger_signal, threshold, min_interval, 'Name', Value)
    %
    % Inputs:
    %   trigger_signal - 1×N vector, trigger signal (sync or digital trigger)
    %   threshold      - scalar or 'auto', detection threshold
    %                    'auto': 自动计算为信号最大值的一半
    %   min_interval   - scalar, minimum interval between triggers (samples)
    %
    % Optional Name-Value Pairs:
    %   'SkipSamples'  - 检测到trigger后跳过的采样点数（默认: 0）
    %   'Edge'         - 检测边沿类型: 'rising', 'falling', 'both'（默认: 'rising'）
    %   'Verbose'      - 是否输出检测信息（默认: false）
    %
    % Outputs:
    %   trigger_indices - 1×M vector, indices of detected triggers
    %
    % Description:
    %   Detects trigger events using threshold-based detection with minimum
    %   interval constraint to prevent duplicate detections. The algorithm
    %   identifies rising edges where the signal crosses above the threshold
    %   and enforces a minimum spacing between consecutive triggers.
    %
    %   For real OPM-MEG data, use 'auto' threshold and set SkipSamples to
    %   match the stimulus duration (e.g., 5000 samples at 4800Hz for 1s stimuli).
    %
    % Requirements: 5.3
    % Property: Property 21 - Trigger Detection Accuracy
    %
    % Example:
    %   fs = 4800;
    %   % 使用自动阈值和跳过采样
    %   trigger_indices = detect_triggers(sync_signal, 'auto', 2400, ...
    %       'SkipSamples', 5000, 'Verbose', true);
    %
    %   % 使用固定阈值
    %   trigger_indices = detect_triggers(trigger_signal, 2.5, 2400);
    
    % Parse optional arguments
    p = inputParser;
    addRequired(p, 'trigger_signal');
    addRequired(p, 'threshold');
    addRequired(p, 'min_interval');
    addParameter(p, 'SkipSamples', 0, @(x) isnumeric(x) && x >= 0);
    addParameter(p, 'Edge', 'rising', @(x) ismember(lower(x), {'rising', 'falling', 'both'}));
    addParameter(p, 'Verbose', false, @islogical);
    parse(p, trigger_signal, threshold, min_interval, varargin{:});
    
    skip_samples = p.Results.SkipSamples;
    edge_type = lower(p.Results.Edge);
    verbose = p.Results.Verbose;
    
    % Ensure trigger_signal is a row vector
    if size(trigger_signal, 1) > 1
        trigger_signal = trigger_signal(:)';
    end
    
    % Validate inputs
    if ~isnumeric(trigger_signal) || ~isvector(trigger_signal)
        error('MEG:DetectTriggers:InvalidInput', ...
            'trigger_signal must be a numeric vector');
    end
    
    if ~isscalar(min_interval) || ~isnumeric(min_interval) || min_interval < 0
        error('MEG:DetectTriggers:InvalidMinInterval', ...
            'min_interval must be a non-negative numeric scalar');
    end
    
    % Initialize output
    trigger_indices = [];
    
    % Handle empty input
    if isempty(trigger_signal)
        return;
    end
    
    % Handle 'auto' threshold
    if ischar(threshold) || isstring(threshold)
        if strcmpi(threshold, 'auto')
            threshold = max(trigger_signal) / 2;
            if verbose
                fprintf('  自动阈值: %.4f (信号最大值的一半)\n', threshold);
            end
        else
            error('MEG:DetectTriggers:InvalidThreshold', ...
                'threshold must be a numeric scalar or ''auto''');
        end
    elseif ~isscalar(threshold) || ~isnumeric(threshold)
        error('MEG:DetectTriggers:InvalidThreshold', ...
            'threshold must be a numeric scalar or ''auto''');
    end
    
    % Detect threshold crossings based on edge type
    above_threshold = trigger_signal > threshold;
    
    switch edge_type
        case 'rising'
            % Find rising edges: transitions from below to above threshold
            edges = diff([false, above_threshold]) > 0;
        case 'falling'
            % Find falling edges: transitions from above to below threshold
            edges = diff([above_threshold, false]) > 0;
        case 'both'
            % Find both rising and falling edges
            rising = diff([false, above_threshold]) > 0;
            falling = diff([above_threshold, false]) > 0;
            edges = rising | falling;
    end
    
    % Get indices of all edges
    candidate_indices = find(edges);
    
    % Apply minimum interval and skip samples constraint
    if isempty(candidate_indices)
        if verbose
            fprintf('  未检测到任何触发\n');
        end
        return;
    end
    
    % Use the larger of min_interval and skip_samples for spacing
    effective_spacing = max(min_interval, skip_samples);
    
    % Alternative detection method (from processing_mission2.m style)
    % This is more robust for continuous signals
    n_samples = length(trigger_signal);
    current_pos = 1;
    
    while current_pos <= n_samples
        % Find first sample above threshold from current position
        remaining_signal = trigger_signal(current_pos:end);
        trigger_idx = find(remaining_signal > threshold, 1);
        
        if isempty(trigger_idx)
            break;  % No more triggers found
        end
        
        % Convert to global index
        global_idx = current_pos + trigger_idx - 1;
        trigger_indices = [trigger_indices, global_idx];
        
        % Skip ahead by effective_spacing
        current_pos = global_idx + effective_spacing;
    end
    
    % Ensure output is a row vector
    trigger_indices = trigger_indices(:)';
    
    if verbose
        fprintf('  检测到 %d 个触发\n', length(trigger_indices));
        if ~isempty(trigger_indices)
            fprintf('  第一个触发位置: %d\n', trigger_indices(1));
            fprintf('  最后一个触发位置: %d\n', trigger_indices(end));
        end
    end
end
