% DEMO_VISUALIZER - Demonstration of visualization functions
%
% This script demonstrates the visualization capabilities of the MEG
% signal processing system with realistic examples.

%% Setup
fprintf('MEG Signal Processing - Visualization Demo\n');
fprintf('==========================================\n\n');

% Add paths
addpath('../analyzer');
addpath('../utils');

% Generate realistic synthetic MEG data
fs = 4800;  % Sampling rate (Hz)
duration = 10;  % seconds
t = (0:1/fs:duration-1/fs)';
n_samples = length(t);
n_channels = 8;

fprintf('Generating synthetic MEG data...\n');
fprintf('  Sampling rate: %d Hz\n', fs);
fprintf('  Duration: %.1f seconds\n', duration);
fprintf('  Channels: %d\n\n', n_channels);

%% Generate synthetic signals with different characteristics
meg_data = zeros(n_channels, n_samples);

% Channel 1-2: Strong 17Hz signal (phantom simulation)
for ch = 1:2
    meg_data(ch, :) = 2*sin(2*pi*17*t) + 0.5*sin(2*pi*50*t) + 0.3*randn(size(t));
end

% Channel 3-4: Weak 17Hz signal with more noise
for ch = 3:4
    meg_data(ch, :) = 0.5*sin(2*pi*17*t) + 0.8*sin(2*pi*50*t) + 0.5*randn(size(t));
end

% Channel 5-6: 89Hz ASSR signal
for ch = 5:6
    meg_data(ch, :) = 1.5*sin(2*pi*89*t) + 0.3*sin(2*pi*50*t) + 0.4*randn(size(t));
end

% Channel 7-8: Mixed signals
for ch = 7:8
    meg_data(ch, :) = sin(2*pi*17*t) + 0.8*sin(2*pi*89*t) + 0.5*randn(size(t));
end

%% Demo 1: Power Spectral Density Visualization
fprintf('Demo 1: Power Spectral Density (PSD)\n');
fprintf('------------------------------------\n');

% Compute PSD for all channels
[frequencies, power] = compute_psd(meg_data, fs);

% Create channel labels
channel_labels = cell(n_channels, 1);
for ch = 1:n_channels
    channel_labels{ch} = sprintf('MEG-%02d', ch);
end

% Plot 1: Single channel PSD (Channel 1 - strong 17Hz)
figure('Position', [100 100 800 500]);
plot_psd(frequencies, power(1, :), ...
    'Title', 'PSD: Channel 1 (Strong 17Hz Signal)', ...
    'FreqRange', [0 150]);
fprintf('  Created: Single channel PSD plot\n');

% Plot 2: Multi-channel PSD comparison (Channels 1-4)
figure('Position', [150 150 800 500]);
plot_psd(frequencies, power(1:4, :), ...
    'Title', 'PSD Comparison: Channels 1-4 (17Hz Signal)', ...
    'ChannelLabels', channel_labels(1:4), ...
    'FreqRange', [0 150]);
fprintf('  Created: Multi-channel PSD comparison\n');

% Plot 3: ASSR channels (Channels 5-6)
figure('Position', [200 200 800 500]);
plot_psd(frequencies, power(5:6, :), ...
    'Title', 'PSD: Channels 5-6 (89Hz ASSR Signal)', ...
    'ChannelLabels', channel_labels(5:6), ...
    'FreqRange', [70 110]);
fprintf('  Created: ASSR channel PSD plot\n\n');

%% Demo 2: Time-Domain Signal Visualization
fprintf('Demo 2: Time-Domain Signals\n');
fprintf('---------------------------\n');

% Plot 4: Single channel time series (2 seconds)
figure('Position', [250 250 900 400]);
time_range = [0 2];
plot_time_series(t, meg_data(1, :), ...
    'Title', 'Time Series: Channel 1 (2 seconds)', ...
    'TimeRange', time_range);
fprintf('  Created: Single channel time series\n');

% Plot 5: Multi-channel overlaid (Channels 1-4)
figure('Position', [300 300 900 500]);
plot_time_series(t, meg_data(1:4, :), ...
    'Title', 'Time Series: Channels 1-4 (Overlaid)', ...
    'Channels', 1:4, ...
    'ChannelLabels', channel_labels(1:4), ...
    'TimeRange', [0 1]);
fprintf('  Created: Multi-channel overlaid time series\n');

% Plot 6: Stacked multi-channel display
figure('Position', [350 350 900 600]);
plot_time_series(t, meg_data, ...
    'Title', 'Time Series: All Channels (Stacked)', ...
    'Channels', 1:8, ...
    'ChannelLabels', channel_labels, ...
    'Stacked', true, ...
    'TimeRange', [0 1]);
fprintf('  Created: Stacked multi-channel time series\n\n');

%% Demo 3: Grand Average Response Visualization
fprintf('Demo 3: Grand Average Response\n');
fprintf('------------------------------\n');

% Generate synthetic trial data (evoked response)
trial_times = (-0.2:1/fs:0.8-1/fs)';  % -200ms to 800ms
n_samples_trial = length(trial_times);
n_trials = 100;

% Simulate evoked response with realistic characteristics
grand_avg = zeros(n_channels, n_samples_trial);
for ch = 1:n_channels
    % Early component (N100) around 100ms
    n100 = -2 * exp(-((trial_times - 0.1).^2) / (2*0.015^2));
    
    % Late component (P200) around 200ms
    p200 = 1.5 * exp(-((trial_times - 0.2).^2) / (2*0.025^2));
    
    % Add channel-specific variation
    grand_avg(ch, :) = (n100 + p200) * (0.8 + 0.4*rand()) + 0.05*randn(size(trial_times));
end

% Plot 7: Single channel grand average
figure('Position', [400 400 800 500]);
plot_averaged_response(trial_times, grand_avg(1, :), ...
    'Title', 'Grand Average: Channel 1 (Auditory Evoked Field)');
fprintf('  Created: Single channel grand average\n');

% Plot 8: Multi-channel overlaid grand average
figure('Position', [450 450 800 500]);
plot_averaged_response(trial_times, grand_avg(1:4, :), ...
    'Title', 'Grand Average: Channels 1-4 (Overlaid)', ...
    'Channels', 1:4, ...
    'ChannelLabels', channel_labels(1:4));
fprintf('  Created: Multi-channel overlaid grand average\n');

% Plot 9: Stacked grand average
figure('Position', [500 500 800 600]);
plot_averaged_response(trial_times, grand_avg, ...
    'Title', 'Grand Average: All Channels (Stacked)', ...
    'Channels', 1:8, ...
    'ChannelLabels', channel_labels, ...
    'Stacked', true);
fprintf('  Created: Stacked grand average\n\n');

%% Demo 4: Convergence Analysis Visualization
fprintf('Demo 4: Convergence Analysis\n');
fprintf('----------------------------\n');

% Simulate convergence analysis results
n_trials_vec = 10:10:200;
n_points = length(n_trials_vec);

% Realistic convergence curve (asymptotic approach)
correlation_vec = 1 - 0.6 * exp(-n_trials_vec / 60) + 0.03*randn(size(n_trials_vec));
correlation_vec = min(correlation_vec, 1.0);
correlation_vec = max(correlation_vec, 0.0);

% Plot 10: Convergence curve with default threshold (0.9)
figure('Position', [550 550 800 500]);
plot_convergence_curve(n_trials_vec, correlation_vec, ...
    'Title', 'Convergence Analysis: Correlation vs. Number of Trials');
fprintf('  Created: Convergence curve with threshold\n');

% Plot 11: Convergence curve with custom threshold
figure('Position', [600 600 800 500]);
plot_convergence_curve(n_trials_vec, correlation_vec, ...
    'Title', 'Convergence Analysis: Custom Threshold (0.85)', ...
    'Threshold', 0.85);
fprintf('  Created: Convergence curve with custom threshold\n\n');

%% Summary
fprintf('==========================================\n');
fprintf('Demo Complete!\n');
fprintf('Total figures created: %d\n', length(findall(0, 'Type', 'figure')));
fprintf('\nAll visualization functions demonstrated:\n');
fprintf('  - plot_psd: Power spectral density plots\n');
fprintf('  - plot_time_series: Time-domain signal plots\n');
fprintf('  - plot_averaged_response: Grand average waveforms\n');
fprintf('  - plot_convergence_curve: Convergence analysis\n');
fprintf('\nClose all figures with: close all\n');
