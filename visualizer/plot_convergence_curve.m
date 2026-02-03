function fig = plot_convergence_curve(n_trials, correlation, varargin)
% PLOT_CONVERGENCE_CURVE Plot convergence analysis results
%
% Syntax:
%   fig = plot_convergence_curve(n_trials, correlation)
%   fig = plot_convergence_curve(n_trials, correlation, 'Name', Value, ...)
%
% Inputs:
%   n_trials - Vector of trial numbers tested
%   correlation - Vector of correlation coefficients corresponding to n_trials
%
% Optional Name-Value Pairs:
%   'Title' - Plot title (default: 'Convergence Analysis')
%   'XLabel' - X-axis label (default: 'Number of Trials')
%   'YLabel' - Y-axis label (default: 'Correlation Coefficient')
%   'Threshold' - Correlation threshold to mark (default: 0.9)
%   'MinTrials' - Minimum trial number where threshold is reached (default: auto-detect)
%   'MarkThreshold' - true/false, mark threshold line (default: true)
%   'MarkMinTrials' - true/false, mark minimum trials point (default: true)
%   'ThresholdColor' - Color for threshold line (default: 'r')
%   'LineWidth' - Line width for main curve (default: 2.0)
%   'MarkerSize' - Size of data point markers (default: 6)
%   'Figure' - Existing figure handle to plot in (default: create new)
%
% Outputs:
%   fig - Figure handle
%
% Example:
%   fig = plot_convergence_curve(n_trials, corr, 'Threshold', 0.9);
%
% Requirements: 7.4

% Parse inputs
p = inputParser;
addRequired(p, 'n_trials', @(x) isnumeric(x) && isvector(x));
addRequired(p, 'correlation', @(x) isnumeric(x) && isvector(x));
addParameter(p, 'Title', 'Convergence Analysis', @ischar);
addParameter(p, 'XLabel', 'Number of Trials', @ischar);
addParameter(p, 'YLabel', 'Correlation Coefficient', @ischar);
addParameter(p, 'Threshold', 0.9, @(x) isscalar(x) && x >= -1 && x <= 1);
addParameter(p, 'MinTrials', [], @(x) isempty(x) || (isscalar(x) && x > 0));
addParameter(p, 'MarkThreshold', true, @islogical);
addParameter(p, 'MarkMinTrials', true, @islogical);
addParameter(p, 'ThresholdColor', 'r', @(x) ischar(x) || isnumeric(x));
addParameter(p, 'LineWidth', 2.0, @(x) isscalar(x) && x > 0);
addParameter(p, 'MarkerSize', 6, @(x) isscalar(x) && x > 0);
addParameter(p, 'Figure', [], @(x) isempty(x) || ishandle(x));
parse(p, n_trials, correlation, varargin{:});

title_str = p.Results.Title;
xlabel_str = p.Results.XLabel;
ylabel_str = p.Results.YLabel;
threshold = p.Results.Threshold;
min_trials = p.Results.MinTrials;
mark_threshold = p.Results.MarkThreshold;
mark_min_trials = p.Results.MarkMinTrials;
threshold_color = p.Results.ThresholdColor;
line_width = p.Results.LineWidth;
marker_size = p.Results.MarkerSize;
fig_handle = p.Results.Figure;

% Ensure vectors are column vectors
n_trials = n_trials(:);
correlation = correlation(:);

% Validate dimensions match
if length(n_trials) ~= length(correlation)
    error('MEG:PlotConvergenceCurve:DimensionMismatch', ...
        'Length of n_trials (%d) must match length of correlation (%d)', ...
        length(n_trials), length(correlation));
end

% Validate correlation values are in valid range
if any(correlation < -1) || any(correlation > 1)
    warning('MEG:PlotConvergenceCurve:InvalidCorrelation', ...
        'Some correlation values are outside [-1, 1] range');
end

% Auto-detect minimum trials if not provided
if isempty(min_trials) && mark_min_trials
    % Find first point where correlation >= threshold
    idx = find(correlation >= threshold, 1, 'first');
    if ~isempty(idx)
        min_trials = n_trials(idx);
    else
        % Threshold not reached
        min_trials = [];
        mark_min_trials = false;
    end
end

% Create or use existing figure
if isempty(fig_handle)
    fig = figure('Name', 'Convergence Curve', 'NumberTitle', 'off');
else
    fig = fig_handle;
    figure(fig);
end

% Plot convergence curve
hold on;

% Plot main curve with markers
plot(n_trials, correlation, '-o', 'LineWidth', line_width, ...
    'MarkerSize', marker_size, 'MarkerFaceColor', 'b', ...
    'DisplayName', 'Correlation vs. Trials');

% Mark threshold line
if mark_threshold
    xlim_vals = xlim;
    plot([xlim_vals(1), xlim_vals(2)], [threshold, threshold], '--', ...
        'Color', threshold_color, 'LineWidth', 1.5, ...
        'DisplayName', sprintf('Threshold (%.2f)', threshold));
end

% Mark minimum trials point
if mark_min_trials && ~isempty(min_trials)
    % Find the correlation value at min_trials
    idx = find(n_trials == min_trials, 1);
    if ~isempty(idx)
        corr_at_min = correlation(idx);
        plot(min_trials, corr_at_min, 'ro', 'MarkerSize', marker_size + 4, ...
            'MarkerFaceColor', 'r', 'LineWidth', 2, ...
            'DisplayName', sprintf('Min Trials = %d', min_trials));
        
        % Add vertical line to x-axis
        ylim_vals = ylim;
        plot([min_trials, min_trials], [ylim_vals(1), corr_at_min], ':', ...
            'Color', threshold_color, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    end
end

hold off;

% Add labels and title
xlabel(xlabel_str, 'FontSize', 12, 'FontWeight', 'bold');
ylabel(ylabel_str, 'FontSize', 12, 'FontWeight', 'bold');
title(title_str, 'FontSize', 14, 'FontWeight', 'bold');

% Add grid
grid on;

% Add legend (southeast to avoid overlap with curve)
legend('Location', 'southeast');

% Set y-axis limits to show full correlation range
ylim([-0.1, 1.1]);

% Improve appearance
set(gca, 'FontSize', 10);
box on;

% Ensure x-axis starts at 0 or minimum trial number
xlim([0, max(n_trials) * 1.05]);

end
