function fig = plot_averaged_response(trial_times, grand_average, varargin)
% PLOT_AVERAGED_RESPONSE Plot grand average waveform
%
% Syntax:
%   fig = plot_averaged_response(trial_times, grand_average)
%   fig = plot_averaged_response(trial_times, grand_average, 'Name', Value, ...)
%
% Inputs:
%   trial_times - Time vector relative to trigger (seconds), length N_samples_per_trial
%   grand_average - Grand average data
%                   Can be vector (single channel) or matrix (multiple channels)
%                   If matrix: size [n_channels, N_samples_per_trial]
%
% Optional Name-Value Pairs:
%   'Title' - Plot title (default: 'Grand Average Response')
%   'XLabel' - X-axis label (default: 'Time relative to trigger (s)')
%   'YLabel' - Y-axis label (default: 'Amplitude')
%   'Channels' - Vector of channel indices to plot (default: all)
%   'ChannelLabels' - Cell array of channel labels for legend
%   'LineWidth' - Line width (default: 1.5)
%   'MarkTrigger' - true/false, mark trigger point at t=0 (default: true)
%   'TriggerColor' - Color for trigger line (default: 'r')
%   'TriggerLineStyle' - Line style for trigger (default: '--')
%   'Stacked' - true/false, stack channels vertically (default: false)
%   'StackSpacing' - Spacing between stacked channels (default: auto)
%   'Figure' - Existing figure handle to plot in (default: create new)
%
% Outputs:
%   fig - Figure handle
%
% Example:
%   fig = plot_averaged_response(trial_times, grand_avg, 'Channels', 1:4);
%
% Requirements: 7.3

% Parse inputs
p = inputParser;
addRequired(p, 'trial_times', @(x) isnumeric(x) && isvector(x));
addRequired(p, 'grand_average', @isnumeric);
addParameter(p, 'Title', 'Grand Average Response', @ischar);
addParameter(p, 'XLabel', 'Time relative to trigger (s)', @ischar);
addParameter(p, 'YLabel', 'Amplitude', @ischar);
addParameter(p, 'Channels', [], @(x) isempty(x) || (isnumeric(x) && isvector(x)));
addParameter(p, 'ChannelLabels', {}, @iscell);
addParameter(p, 'LineWidth', 1.5, @(x) isscalar(x) && x > 0);
addParameter(p, 'MarkTrigger', true, @islogical);
addParameter(p, 'TriggerColor', 'r', @(x) ischar(x) || isnumeric(x));
addParameter(p, 'TriggerLineStyle', '--', @ischar);
addParameter(p, 'Stacked', false, @islogical);
addParameter(p, 'StackSpacing', [], @(x) isempty(x) || (isscalar(x) && x > 0));
addParameter(p, 'Figure', [], @(x) isempty(x) || ishandle(x));
parse(p, trial_times, grand_average, varargin{:});

title_str = p.Results.Title;
xlabel_str = p.Results.XLabel;
ylabel_str = p.Results.YLabel;
channels = p.Results.Channels;
channel_labels = p.Results.ChannelLabels;
line_width = p.Results.LineWidth;
mark_trigger = p.Results.MarkTrigger;
trigger_color = p.Results.TriggerColor;
trigger_linestyle = p.Results.TriggerLineStyle;
stacked = p.Results.Stacked;
stack_spacing = p.Results.StackSpacing;
fig_handle = p.Results.Figure;

% Ensure trial_times is column vector
trial_times = trial_times(:);

% Handle grand_average dimensions
if isvector(grand_average)
    grand_average = grand_average(:)';  % Ensure row vector
    n_channels_total = 1;
else
    n_channels_total = size(grand_average, 1);
end

% Validate dimensions match
if length(trial_times) ~= size(grand_average, 2)
    error('MEG:PlotAveragedResponse:DimensionMismatch', ...
        'Length of trial_times (%d) must match size of grand_average (%d)', ...
        length(trial_times), size(grand_average, 2));
end

% Select channels to plot
if isempty(channels)
    channels = 1:n_channels_total;
else
    % Validate channel indices
    if any(channels < 1) || any(channels > n_channels_total)
        error('MEG:PlotAveragedResponse:InvalidChannels', ...
            'Channel indices must be between 1 and %d', n_channels_total);
    end
end

n_channels = length(channels);
data_plot = grand_average(channels, :);

% Calculate stack spacing if needed
if stacked && isempty(stack_spacing)
    % Auto-calculate spacing based on signal range
    signal_range = max(data_plot(:)) - min(data_plot(:));
    stack_spacing = signal_range * 1.2;  % 20% extra spacing
end

% Create or use existing figure
if isempty(fig_handle)
    fig = figure('Name', 'Grand Average Response', 'NumberTitle', 'off');
else
    fig = fig_handle;
    figure(fig);
end

% Plot grand average
hold on;

% Mark trigger point (t=0) first so it appears behind the data
if mark_trigger
    ylim_temp = [min(data_plot(:)), max(data_plot(:))];
    if stacked
        ylim_temp = [0, n_channels * stack_spacing];
    end
    plot([0 0], ylim_temp, trigger_linestyle, 'Color', trigger_color, ...
        'LineWidth', 1.5, 'DisplayName', 'Trigger (t=0)');
end

% Plot each channel
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
        plot(trial_times, signal, 'LineWidth', line_width);
    else
        plot(trial_times, signal, 'LineWidth', line_width, 'DisplayName', label);
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
elseif n_channels == 1 && mark_trigger
    legend('Location', 'northeast');
elseif n_channels > 1 && stacked
    % For stacked plots, add channel labels on the right
    for ch = 1:n_channels
        ch_idx = channels(ch);
        offset = (n_channels - ch) * stack_spacing;
        
        if ~isempty(channel_labels) && ch_idx <= length(channel_labels)
            label = channel_labels{ch_idx};
        else
            label = sprintf('Ch %d', ch_idx);
        end
        
        % Add text label on the right side
        text(max(trial_times), offset, ['  ' label], ...
            'VerticalAlignment', 'middle', 'FontSize', 9);
    end
end

% Improve appearance
set(gca, 'FontSize', 10);
box on;

% Adjust y-limits if stacked
if stacked
    ylim([-stack_spacing/2, (n_channels + 0.5) * stack_spacing]);
end

end
