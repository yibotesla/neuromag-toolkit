% TEST_VISUALIZER - Test visualization functions
%
% This script tests all visualization functions in the visualizer module
% to ensure they work correctly with various input configurations.

%% Setup
fprintf('Testing Visualizer Module\n');
fprintf('=========================\n\n');

% Generate synthetic test data
fs = 4800;  % Sampling rate
duration = 2;  % seconds
t = (0:1/fs:duration-1/fs)';
n_samples = length(t);
n_channels = 4;

% Create synthetic MEG signals
meg_data = zeros(n_channels, n_samples);
for ch = 1:n_channels
    % Mix of frequencies
    meg_data(ch, :) = sin(2*pi*17*t) + 0.5*sin(2*pi*50*t) + 0.2*randn(size(t));
end

%% Test 1: plot_psd
fprintf('Test 1: plot_psd\n');
try
    % Add path to analyzer module
    addpath('../analyzer');
    
    % Compute PSD
    [frequencies, power] = compute_psd(meg_data(1, :), fs);
    
    % Define channel labels
    channel_labels = {'Ch1', 'Ch2', 'Ch3', 'Ch4'};
    
    % Test single channel
    fig1 = plot_psd(frequencies, power, 'Title', 'Test: Single Channel PSD');
    fprintf('  ✓ Single channel PSD plot created\n');
    
    % Test multiple channels
    [frequencies, power_multi] = compute_psd(meg_data, fs);
    fig2 = plot_psd(frequencies, power_multi, ...
        'Title', 'Test: Multi-Channel PSD', ...
        'ChannelLabels', channel_labels, ...
        'FreqRange', [0 100]);
    fprintf('  ✓ Multi-channel PSD plot created\n');
    
    % Test linear scale
    fig3 = plot_psd(frequencies, power, ...
        'Title', 'Test: Linear Scale PSD', ...
        'Scale', 'linear');
    fprintf('  ✓ Linear scale PSD plot created\n');
    
    fprintf('  Test 1 PASSED\n\n');
catch ME
    fprintf('  ✗ Test 1 FAILED: %s\n\n', ME.message);
end

%% Test 2: plot_time_series
fprintf('Test 2: plot_time_series\n');
try
    % Test single channel
    fig4 = plot_time_series(t, meg_data(1, :), ...
        'Title', 'Test: Single Channel Time Series');
    fprintf('  ✓ Single channel time series plot created\n');
    
    % Test multiple channels (overlaid)
    fig5 = plot_time_series(t, meg_data, ...
        'Title', 'Test: Multi-Channel Time Series (Overlaid)', ...
        'Channels', 1:4, ...
        'ChannelLabels', channel_labels);
    fprintf('  ✓ Multi-channel overlaid time series plot created\n');
    
    % Test stacked channels
    fig6 = plot_time_series(t, meg_data, ...
        'Title', 'Test: Multi-Channel Time Series (Stacked)', ...
        'Channels', 1:4, ...
        'ChannelLabels', channel_labels, ...
        'Stacked', true);
    fprintf('  ✓ Stacked time series plot created\n');
    
    % Test time range selection
    fig7 = plot_time_series(t, meg_data, ...
        'Title', 'Test: Time Series with Range Selection', ...
        'Channels', 1:2, ...
        'TimeRange', [0.5 1.5]);
    fprintf('  ✓ Time range selection plot created\n');
    
    fprintf('  Test 2 PASSED\n\n');
catch ME
    fprintf('  ✗ Test 2 FAILED: %s\n\n', ME.message);
end

%% Test 3: plot_averaged_response
fprintf('Test 3: plot_averaged_response\n');
try
    % Create synthetic trial data
    trial_duration = 1.0;  % seconds
    trial_times = (-0.2:1/fs:0.8-1/fs)';  % -200ms to 800ms
    n_samples_trial = length(trial_times);
    
    % Simulate grand average (evoked response)
    grand_avg = zeros(n_channels, n_samples_trial);
    for ch = 1:n_channels
        % Simulate evoked response with peak around 100ms
        peak_time = 0.1;
        grand_avg(ch, :) = exp(-((trial_times - peak_time).^2) / (2*0.02^2)) + ...
            0.1*randn(size(trial_times));
    end
    
    % Test single channel
    fig8 = plot_averaged_response(trial_times, grand_avg(1, :), ...
        'Title', 'Test: Single Channel Grand Average');
    fprintf('  ✓ Single channel grand average plot created\n');
    
    % Test multiple channels (overlaid)
    fig9 = plot_averaged_response(trial_times, grand_avg, ...
        'Title', 'Test: Multi-Channel Grand Average (Overlaid)', ...
        'Channels', 1:4, ...
        'ChannelLabels', channel_labels);
    fprintf('  ✓ Multi-channel overlaid grand average plot created\n');
    
    % Test stacked channels
    fig10 = plot_averaged_response(trial_times, grand_avg, ...
        'Title', 'Test: Multi-Channel Grand Average (Stacked)', ...
        'Channels', 1:4, ...
        'ChannelLabels', channel_labels, ...
        'Stacked', true);
    fprintf('  ✓ Stacked grand average plot created\n');
    
    % Test without trigger marker
    fig11 = plot_averaged_response(trial_times, grand_avg(1, :), ...
        'Title', 'Test: Grand Average without Trigger Marker', ...
        'MarkTrigger', false);
    fprintf('  ✓ Grand average without trigger marker created\n');
    
    fprintf('  Test 3 PASSED\n\n');
catch ME
    fprintf('  ✗ Test 3 FAILED: %s\n\n', ME.message);
end

%% Test 4: plot_convergence_curve
fprintf('Test 4: plot_convergence_curve\n');
try
    % Create synthetic convergence data
    n_trials_vec = 10:10:200;
    % Simulate convergence curve (asymptotic approach to 1.0)
    correlation_vec = 1 - 0.5 * exp(-n_trials_vec / 50) + 0.05*randn(size(n_trials_vec));
    correlation_vec = min(correlation_vec, 1.0);  % Cap at 1.0
    correlation_vec = max(correlation_vec, 0.0);  % Floor at 0.0
    
    % Test basic convergence plot
    fig12 = plot_convergence_curve(n_trials_vec, correlation_vec, ...
        'Title', 'Test: Convergence Analysis');
    fprintf('  ✓ Basic convergence curve plot created\n');
    
    % Test with custom threshold
    fig13 = plot_convergence_curve(n_trials_vec, correlation_vec, ...
        'Title', 'Test: Convergence with Custom Threshold', ...
        'Threshold', 0.85);
    fprintf('  ✓ Convergence curve with custom threshold created\n');
    
    % Test without threshold markers
    fig14 = plot_convergence_curve(n_trials_vec, correlation_vec, ...
        'Title', 'Test: Convergence without Markers', ...
        'MarkThreshold', false, ...
        'MarkMinTrials', false);
    fprintf('  ✓ Convergence curve without markers created\n');
    
    fprintf('  Test 4 PASSED\n\n');
catch ME
    fprintf('  ✗ Test 4 FAILED: %s\n\n', ME.message);
end

%% Summary
fprintf('=========================\n');
fprintf('All Visualizer Tests Completed\n');
fprintf('Total figures created: %d\n', length(findall(0, 'Type', 'figure')));
fprintf('\nNote: Close all figures with: close all\n');
