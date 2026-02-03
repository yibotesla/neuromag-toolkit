function fig = plot_time_series(time, data, varargin)
% PLOT_TIME_SERIES Plot time-domain signals
%
% Syntax:
%   fig = plot_time_series(time, data)
%   fig = plot_time_series(time, data, 'Name', Value, ...)
%
% Inputs:
%   time - Time vector (seconds), length N_samples
%   data - Signal data
%          Can be vector (single channel) or matrix (multiple channels)
%          If matrix: size [n_channels, N_samples]
%
% Optional Name-Value Pairs:
%   'Title' - Plot title (default: 'Time-Domain Signal')
%   'XLabel' - X-axis label (default: 'Time (s)')
%   'YLabel' - Y-axis label (default: 'Amplitude')
%   'Channels' - Vector of channel indices to plot (default: all)
%   'ChannelLabels' - Cell array of channel labels for legend
%   'TimeRange' - [tmin tmax] time range to display (default: all)
%   'LineWidth' - Line width (default: 1.0)
%   'Stacked' - true/false, stack channels vertically (default: false)
%   'StackSpacing' - Spacing between stacked channels (default: auto)
%   'Figure' - Existing figure handle to plot in (default: create new)
%
% Outputs:
%   fig - Figure handle
%
% Example:
%   plot_time_series(time, meg_data, 'Channels', 1:4, 'Stacked', true);
%
% Requirements: 7.2

% Parse inputs
p = inputParser;
addRequired(p, 'time', @(x) isnumeric(x) && isvector(x));
addRequired(p, 'data', @isnumeric);
addParameter(p, 'Title', 'Time-Domain Signal', @ischar);
addParameter(p, 'XLabel', 'Time (s)', @ischar);
addParameter(p, 'YLabel', 'Amplitude', @ischar);
addParameter(p, 'Channels', [], @(x) isempty(x) || (isnumeric(x) && isvector(x)));
addParameter(p, 'ChannelLabels', {}, @iscell);
addParameter(p, 'TimeRange', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
addParameter(p, 'LineWidth', 1.0, @(x) isscalar(x) && x > 0);
addParameter(p, 'Stacked', false, @islogical);
addParameter(p, 'StackSpacing', [], @(x) isempty(x) || (isscalar(x) && x > 0));
addParameter(p, 'Figure', [], @(x) isempty(x) || ishandle(x));
parse(p, time, data, varargin{:});

title_str = p.Results.Title;
xlabel_str = p.Results.XLabel;
ylabel_str = p.Results.YLabel;
channels = p.Results.Channels;
channel_labels = p.Results.ChannelLabels;
time_range = p.Results.TimeRange;
line_width = p.Results.LineWidth;
stacked = p.Results.Stacked;
stack_spacing = p.Results.StackSpacing;
fig_handle = p.Results.Figure;

% Ensure time is column vector
time = time(:);

% Handle data dimensions
if isvector(data)
    data = data(:)';  % Ensure row vector
    n_channels_total = 1;
else
    n_channels_total = size(data, 1);
end

% Validate dimensions match
if length(time) ~= size(data, 2)
    error('MEG:PlotTimeSeries:DimensionMismatch', ...
        'Length of time (%d) must match size of data (%d)', ...
        length(time), size(data, 2));
end

% Select channels to plot
if isempty(channels)
    channels = 1:n_channels_total;
else
    % Validate channel indices
    if any(channels < 1) || any(channels > n_channels_total)
        error('MEG:PlotTimeSeries:InvalidChannels', ...
            'Channel indices must be between 1 and %d', n_channels_total);
    end
end

n_channels = length(channels);
data_plot = data(channels, :);

% Apply time range filter if specified
if ~isempty(time_range)
    time_idx = time >= time_range(1) & time <= time_range(2);
    time = time(time_idx);
    data_plot = data_plot(:, time_idx);
end

% Calculate stack spacing if needed
if stacked && isempty(stack_spacing)
    % Auto-calculate spacing based on signal range
    signal_range = max(data_plot(:)) - min(data_plot(:));
    stack_spacing = signal_range * 1.2;  % 20% extra spacing
end

% Create or use existing figure
if isempty(fig_handle)
    fig = figure('Name', 'Time Series Plot', 'NumberTitle', 'off');
else
    fig = fig_handle;
    figure(fig);
end

% Plot time series
hold on;
for ch = 1:n_channels
    ch_idx = channels(ch);
    
    % Apply vertical offset for stacked display
    if stacked
        offset = (n_channels - ch) * stack_spacing;
        signal = data_plot(ch, :) + offset;
    else
        signal = data_plot(ch, :);
    end
    
    % Determine label
    if ~isempty(channel_labels) && ch_idx <= length(channel_labels)
        label = channel_labels{ch_idx};
    else
        label = sprintf('Channel %d', ch_idx);
    end
    
    % Plot
    if n_channels == 1
        plot(time, signal, 'LineWidth', line_width);
    else
        plot(time, signal, 'LineWidth', line_width, 'DisplayName', label);
    end
end
hold off;

% Add labels and title
xlabel(xlabel_str, 'FontSize', 12, 'FontWeight', 'bold');
ylabel(ylabel_str, 'FontSize', 12, 'FontWeight', 'bold');
title(title_str, 'FontSize', 14, 'FontWeight', 'bold');

% Add grid
grid on;

% Add legend if multiple channels and not stacked
if n_channels > 1 && ~stacked
    legend('Location', 'northeast');
elseif n_channels > 1 && stacked
    % For stacked plots, add channel labels on the right
    ylim_vals = ylim;
    for ch = 1:n_channels
        ch_idx = channels(ch);
        offset = (n_channels - ch) * stack_spacing;
        
        if ~isempty(channel_labels) && ch_idx <= length(channel_labels)
            label = channel_labels{ch_idx};
        else
            label = sprintf('Ch %d', ch_idx);
        end
        
        % Add text label on the right side
        text(max(time), offset, ['  ' label], ...
            'VerticalAlignment', 'middle', 'FontSize', 9);
    end
end

% Improve appearance
set(gca, 'FontSize', 10);
box on;

end
