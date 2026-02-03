function fig = plot_psd(frequencies, power, varargin)
% PLOT_PSD Plot power spectral density
%
% Syntax:
%   fig = plot_psd(frequencies, power)
%   fig = plot_psd(frequencies, power, 'Name', Value, ...)
%
% Inputs:
%   frequencies - Frequency vector (Hz), length NFFT/2+1
%   power - Power spectral density
%           Can be vector (single channel) or matrix (multiple channels)
%           If matrix: size [n_channels, NFFT/2+1]
%
% Optional Name-Value Pairs:
%   'Title' - Plot title (default: 'Power Spectral Density')
%   'XLabel' - X-axis label (default: 'Frequency (Hz)')
%   'YLabel' - Y-axis label (default: 'Power (dB)')
%   'Scale' - 'linear' or 'dB' (default: 'dB')
%   'FreqRange' - [fmin fmax] frequency range to display (default: all)
%   'ChannelLabels' - Cell array of channel labels for legend
%   'LineWidth' - Line width (default: 1.5)
%   'Figure' - Existing figure handle to plot in (default: create new)
%
% Outputs:
%   fig - Figure handle
%
% Example:
%   [f, psd] = compute_psd(signal, 4800);
%   fig = plot_psd(f, psd, 'Title', 'MEG Channel 1 PSD');
%
% Requirements: 7.1

% Parse inputs
p = inputParser;
addRequired(p, 'frequencies', @(x) isnumeric(x) && isvector(x));
addRequired(p, 'power', @isnumeric);
addParameter(p, 'Title', 'Power Spectral Density', @ischar);
addParameter(p, 'XLabel', 'Frequency (Hz)', @ischar);
addParameter(p, 'YLabel', 'Power (dB)', @ischar);
addParameter(p, 'Scale', 'dB', @(x) ismember(x, {'linear', 'dB'}));
addParameter(p, 'FreqRange', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
addParameter(p, 'ChannelLabels', {}, @iscell);
addParameter(p, 'LineWidth', 1.5, @(x) isscalar(x) && x > 0);
addParameter(p, 'Figure', [], @(x) isempty(x) || ishandle(x));
parse(p, frequencies, power, varargin{:});

title_str = p.Results.Title;
xlabel_str = p.Results.XLabel;
ylabel_str = p.Results.YLabel;
scale = p.Results.Scale;
freq_range = p.Results.FreqRange;
channel_labels = p.Results.ChannelLabels;
line_width = p.Results.LineWidth;
fig_handle = p.Results.Figure;

% Ensure frequencies is column vector
frequencies = frequencies(:);

% Handle power dimensions
if isvector(power)
    power = power(:)';  % Ensure row vector
    n_channels = 1;
else
    n_channels = size(power, 1);
end

% Validate dimensions match
if length(frequencies) ~= size(power, 2)
    error('MEG:PlotPSD:DimensionMismatch', ...
        'Length of frequencies (%d) must match size of power (%d)', ...
        length(frequencies), size(power, 2));
end

% Convert to dB scale if requested
if strcmp(scale, 'dB')
    power_plot = 10 * log10(power);
else
    power_plot = power;
end

% Apply frequency range filter if specified
if ~isempty(freq_range)
    freq_idx = frequencies >= freq_range(1) & frequencies <= freq_range(2);
    frequencies = frequencies(freq_idx);
    power_plot = power_plot(:, freq_idx);
end

% Create or use existing figure
if isempty(fig_handle)
    fig = figure('Name', 'PSD Plot', 'NumberTitle', 'off');
else
    fig = fig_handle;
    figure(fig);
end

% Plot PSD
hold on;
for ch = 1:n_channels
    if n_channels == 1 || isempty(channel_labels)
        plot(frequencies, power_plot(ch, :), 'LineWidth', line_width);
    else
        if ch <= length(channel_labels)
            plot(frequencies, power_plot(ch, :), 'LineWidth', line_width, ...
                'DisplayName', channel_labels{ch});
        else
            plot(frequencies, power_plot(ch, :), 'LineWidth', line_width, ...
                'DisplayName', sprintf('Channel %d', ch));
        end
    end
end
hold off;

% Add labels and title
xlabel(xlabel_str, 'FontSize', 12, 'FontWeight', 'bold');
ylabel(ylabel_str, 'FontSize', 12, 'FontWeight', 'bold');
title(title_str, 'FontSize', 14, 'FontWeight', 'bold');

% Add grid
grid on;

% Add legend if multiple channels
if n_channels > 1 && ~isempty(channel_labels)
    legend('Location', 'northeast');
end

% Improve appearance
set(gca, 'FontSize', 10);
box on;

end
