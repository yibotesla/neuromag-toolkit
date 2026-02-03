function [data_clean, missing_info] = handle_missing_data(data, method, options)
% HANDLE_MISSING_DATA Detect and handle missing data (NaN values) in MEG signals
%
% Syntax:
%   [data_clean, missing_info] = handle_missing_data(data, method, options)
%
% Inputs:
%   data    - N_channels × N_samples matrix, input data
%   method  - String, handling method:
%             'interpolate' - Linear interpolation of NaN values
%             'mark'        - Mark NaN segments but don't modify data
%             'zero'        - Replace NaN with zeros
%             'remove'      - Remove samples with NaN (returns shorter data)
%   options - (optional) Structure with fields:
%             .max_gap - Maximum gap size to interpolate (samples), default: 100
%             .verbose - Display warnings, default: true
%
% Outputs:
%   data_clean   - N_channels × N_samples (or less), processed data
%   missing_info - Structure with fields:
%                  .has_missing - Boolean, true if NaN values found
%                  .n_missing - Total number of NaN values
%                  .missing_channels - Channels with NaN values
%                  .missing_segments - Cell array of [start, end] indices per channel
%                  .method_used - Method used for handling
%
% Description:
%   Detects NaN values in MEG data and handles them according to the specified
%   method. Provides detailed information about missing data locations.
%
% Requirements: 8.2
%
% Example:
%   [clean_data, info] = handle_missing_data(meg_data, 'interpolate');
%   if info.has_missing
%       fprintf('Found %d missing values in %d channels\n', ...
%           info.n_missing, length(info.missing_channels));
%   end

% Validate inputs
if nargin < 2
    method = 'interpolate';
end

if nargin < 3
    options = struct();
end

if ~isfield(options, 'max_gap')
    options.max_gap = 100;
end

if ~isfield(options, 'verbose')
    options.verbose = true;
end

% Validate data
if ~isnumeric(data) || ndims(data) > 2
    error('MEG:MissingData:InvalidInput', ...
        'data must be a 2D numeric matrix');
end

% Validate method
valid_methods = {'interpolate', 'mark', 'zero', 'remove'};
if ~ismember(method, valid_methods)
    error('MEG:MissingData:InvalidMethod', ...
        'method must be one of: %s', strjoin(valid_methods, ', '));
end

[n_channels, n_samples] = size(data);

% Initialize missing_info structure
missing_info = struct();
missing_info.method_used = method;
missing_info.has_missing = false;
missing_info.n_missing = 0;
missing_info.missing_channels = [];
missing_info.missing_segments = cell(n_channels, 1);

% Detect NaN values
nan_mask = isnan(data);
total_nans = sum(nan_mask(:));

if total_nans == 0
    % No missing data
    data_clean = data;
    return;
end

% Missing data found
missing_info.has_missing = true;
missing_info.n_missing = total_nans;

% Find channels with missing data
channels_with_nan = find(any(nan_mask, 2));
missing_info.missing_channels = channels_with_nan;

if options.verbose
    warning('MEG:MissingData:NaNDetected', ...
        'Detected %d NaN values in %d channels (%.2f%% of data)', ...
        total_nans, length(channels_with_nan), ...
        100 * total_nans / numel(data));
end

% Find missing segments for each channel
for ch = channels_with_nan'
    nan_indices = find(nan_mask(ch, :));
    
    if isempty(nan_indices)
        continue;
    end
    
    % Find contiguous segments
    segments = [];
    seg_start = nan_indices(1);
    
    for i = 2:length(nan_indices)
        if nan_indices(i) ~= nan_indices(i-1) + 1
            % End of segment
            seg_end = nan_indices(i-1);
            segments = [segments; seg_start, seg_end];
            seg_start = nan_indices(i);
        end
    end
    % Add last segment
    segments = [segments; seg_start, nan_indices(end)];
    
    missing_info.missing_segments{ch} = segments;
    
    if options.verbose
        for i = 1:size(segments, 1)
            seg_len = segments(i, 2) - segments(i, 1) + 1;
            fprintf('  Channel %d: NaN segment at samples %d-%d (length: %d)\n', ...
                ch, segments(i, 1), segments(i, 2), seg_len);
        end
    end
end

% Handle missing data according to method
switch method
    case 'interpolate'
        data_clean = interpolate_missing(data, nan_mask, missing_info, options);
        
    case 'mark'
        % Just return original data with info
        data_clean = data;
        if options.verbose
            fprintf('Missing data marked but not modified\n');
        end
        
    case 'zero'
        data_clean = data;
        data_clean(nan_mask) = 0;
        if options.verbose
            fprintf('Replaced %d NaN values with zeros\n', total_nans);
        end
        
    case 'remove'
        % Remove samples that have NaN in any channel
        samples_with_nan = any(nan_mask, 1);
        data_clean = data(:, ~samples_with_nan);
        n_removed = sum(samples_with_nan);
        if options.verbose
            fprintf('Removed %d samples containing NaN values\n', n_removed);
            fprintf('Data reduced from %d to %d samples\n', n_samples, size(data_clean, 2));
        end
end

end

%% Helper function for interpolation
function data_interp = interpolate_missing(data, nan_mask, missing_info, options)
    % Interpolate NaN values using linear interpolation
    
    [n_channels, n_samples] = size(data);
    data_interp = data;
    
    for ch = missing_info.missing_channels'
        segments = missing_info.missing_segments{ch};
        
        for i = 1:size(segments, 1)
            seg_start = segments(i, 1);
            seg_end = segments(i, 2);
            seg_len = seg_end - seg_start + 1;
            
            % Check if gap is too large
            if seg_len > options.max_gap
                if options.verbose
                    warning('MEG:MissingData:GapTooLarge', ...
                        'Channel %d: Gap at samples %d-%d (length %d) exceeds max_gap (%d). Filling with zeros.', ...
                        ch, seg_start, seg_end, seg_len, options.max_gap);
                end
                data_interp(ch, seg_start:seg_end) = 0;
                continue;
            end
            
            % Find valid data points before and after the gap
            before_idx = seg_start - 1;
            after_idx = seg_end + 1;
            
            % Handle edge cases
            if before_idx < 1
                % Gap at start of data
                if after_idx <= n_samples
                    % Use first valid value
                    data_interp(ch, seg_start:seg_end) = data(ch, after_idx);
                else
                    % Entire channel is NaN
                    data_interp(ch, seg_start:seg_end) = 0;
                end
            elseif after_idx > n_samples
                % Gap at end of data
                % Use last valid value
                data_interp(ch, seg_start:seg_end) = data(ch, before_idx);
            else
                % Gap in middle - linear interpolation
                val_before = data(ch, before_idx);
                val_after = data(ch, after_idx);
                
                % Create interpolation points
                x = [before_idx, after_idx];
                y = [val_before, val_after];
                xi = seg_start:seg_end;
                
                % Linear interpolation
                yi = interp1(x, y, xi, 'linear');
                data_interp(ch, seg_start:seg_end) = yi;
            end
        end
    end
    
    if options.verbose
        fprintf('Interpolated %d NaN values across %d channels\n', ...
            missing_info.n_missing, length(missing_info.missing_channels));
    end
end
