function [data_clean, saturation_info] = handle_saturated_channels(data, options)
% HANDLE_SATURATED_CHANNELS Detect, report, and exclude saturated channels
%
% Syntax:
%   [data_clean, saturation_info] = handle_saturated_channels(data, options)
%
% Inputs:
%   data    - N_channels × N_samples matrix, input MEG data
%   options - (optional) Structure with fields:
%             .saturation_threshold - Absolute value threshold for saturation
%                                     (default: 1e-10 Tesla)
%             .saturation_percentage - Percentage of samples that must be
%                                      saturated to mark channel as bad
%                                      (default: 1.0, i.e., 1%)
%             .exclude_saturated - Boolean, whether to exclude saturated
%                                  channels from output (default: true)
%             .verbose - Display detailed information (default: true)
%
% Outputs:
%   data_clean       - Cleaned data with saturated channels excluded (if requested)
%   saturation_info  - Structure with fields:
%                      .has_saturated - Boolean, true if saturated channels found
%                      .n_saturated - Number of saturated channels
%                      .saturated_channels - Indices of saturated channels
%                      .saturation_details - Cell array with details per channel
%                      .excluded - Boolean, whether channels were excluded
%                      .remaining_channels - Indices of remaining channels
%
% Description:
%   Detects channels with saturated values (values at or near maximum sensor
%   range), provides detailed reporting, and optionally excludes them from
%   further processing. Saturation can occur due to sensor overload or
%   electromagnetic interference.
%
% Requirements: 8.3
%
% Example:
%   options.saturation_threshold = 1e-10;
%   options.exclude_saturated = true;
%   [clean_data, info] = handle_saturated_channels(meg_data, options);
%   fprintf('Excluded %d saturated channels: %s\n', ...
%       info.n_saturated, mat2str(info.saturated_channels));

% Validate inputs
if nargin < 1 || isempty(data)
    error('MEG:SaturatedChannels:MissingInput', 'Data is required');
end

if ~isnumeric(data) || ndims(data) > 2
    error('MEG:SaturatedChannels:InvalidInput', ...
        'data must be a 2D numeric matrix');
end

if nargin < 2
    options = struct();
end

% Set default options
if ~isfield(options, 'saturation_threshold')
    options.saturation_threshold = 1e-10;  % Tesla
end

if ~isfield(options, 'saturation_percentage')
    options.saturation_percentage = 1.0;  % 1% of samples
end

if ~isfield(options, 'exclude_saturated')
    options.exclude_saturated = true;
end

if ~isfield(options, 'verbose')
    options.verbose = true;
end

[n_channels, n_samples] = size(data);

% Initialize saturation_info structure
saturation_info = struct();
saturation_info.has_saturated = false;
saturation_info.n_saturated = 0;
saturation_info.saturated_channels = [];
saturation_info.saturation_details = {};
saturation_info.excluded = false;
saturation_info.remaining_channels = 1:n_channels;

% Detect saturation for each channel
saturated_channels = [];
saturation_details = {};

for ch = 1:n_channels
    channel_data = data(ch, :);
    
    % Find samples at or above saturation threshold
    saturated_mask = abs(channel_data) >= options.saturation_threshold;
    n_saturated_samples = sum(saturated_mask);
    saturation_pct = 100 * n_saturated_samples / n_samples;
    
    % Check if channel exceeds saturation percentage threshold
    if saturation_pct >= options.saturation_percentage
        saturated_channels = [saturated_channels, ch];
        
        % Collect detailed information
        detail = struct();
        detail.channel = ch;
        detail.n_saturated_samples = n_saturated_samples;
        detail.saturation_percentage = saturation_pct;
        detail.max_value = max(abs(channel_data));
        detail.saturated_indices = find(saturated_mask);
        
        % Find contiguous saturated segments
        if n_saturated_samples > 0
            sat_indices = find(saturated_mask);
            segments = [];
            seg_start = sat_indices(1);
            
            for i = 2:length(sat_indices)
                if sat_indices(i) ~= sat_indices(i-1) + 1
                    seg_end = sat_indices(i-1);
                    segments = [segments; seg_start, seg_end];
                    seg_start = sat_indices(i);
                end
            end
            segments = [segments; seg_start, sat_indices(end)];
            detail.saturated_segments = segments;
        else
            detail.saturated_segments = [];
        end
        
        saturation_details{end+1} = detail;
    end
end

% Update saturation_info
if ~isempty(saturated_channels)
    saturation_info.has_saturated = true;
    saturation_info.n_saturated = length(saturated_channels);
    saturation_info.saturated_channels = saturated_channels;
    saturation_info.saturation_details = saturation_details;
    
    % Display warning and details
    if options.verbose
        warning('MEG:SaturatedChannels:Detected', ...
            'Detected %d saturated channels (%.1f%% of total channels)', ...
            length(saturated_channels), 100 * length(saturated_channels) / n_channels);
        
        fprintf('\nSaturated Channel Details:\n');
        fprintf('%-10s %-15s %-15s %-15s %-20s\n', ...
            'Channel', 'N_Saturated', 'Percentage', 'Max_Value', 'N_Segments');
        fprintf('%s\n', repmat('-', 1, 80));
        
        for i = 1:length(saturation_details)
            detail = saturation_details{i};
            fprintf('%-10d %-15d %-15.2f%% %-15.3e %-20d\n', ...
                detail.channel, ...
                detail.n_saturated_samples, ...
                detail.saturation_percentage, ...
                detail.max_value, ...
                size(detail.saturated_segments, 1));
        end
        fprintf('\n');
    end
end

% Handle saturated channels
if options.exclude_saturated && saturation_info.has_saturated
    % Exclude saturated channels
    good_channels = setdiff(1:n_channels, saturated_channels);
    data_clean = data(good_channels, :);
    
    saturation_info.excluded = true;
    saturation_info.remaining_channels = good_channels;
    
    if options.verbose
        fprintf('Excluded %d saturated channels from data\n', length(saturated_channels));
        fprintf('Remaining channels: %d / %d\n', length(good_channels), n_channels);
        fprintf('Saturated channel IDs: %s\n\n', mat2str(saturated_channels));
    end
else
    % Keep all channels
    data_clean = data;
    
    if saturation_info.has_saturated && options.verbose
        fprintf('Saturated channels detected but not excluded (exclude_saturated = false)\n');
        fprintf('Saturated channel IDs: %s\n\n', mat2str(saturated_channels));
    end
end

end
