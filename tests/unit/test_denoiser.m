% TEST_DENOISER Unit tests for denoiser module
%
% This script tests the spike noise removal functions

% Add paths
addpath('../../denoiser');

%% Test 1: median_filter_despike - Basic functionality
fprintf('Test 1: median_filter_despike - Basic functionality\n');

% Create a clean signal
t = linspace(0, 1, 1000);
clean_signal = sin(2*pi*10*t);

% Add spikes
signal_with_spikes = clean_signal;
spike_indices = [100, 300, 500, 700, 900];
signal_with_spikes(spike_indices) = signal_with_spikes(spike_indices) + 5;

% Apply median filter despike
data_in = signal_with_spikes;
data_out = median_filter_despike(data_in, 5, 3.0);

% Check that spikes are reduced
spike_amplitudes_before = abs(signal_with_spikes(spike_indices) - clean_signal(spike_indices));
spike_amplitudes_after = abs(data_out(spike_indices) - clean_signal(spike_indices));

if all(spike_amplitudes_after < spike_amplitudes_before)
    fprintf('  PASS: Spikes reduced\n');
else
    fprintf('  FAIL: Spikes not adequately reduced\n');
end

%% Test 2: median_filter_despike - Multi-channel
fprintf('Test 2: median_filter_despike - Multi-channel\n');

% Create multi-channel data
n_channels = 3;
n_samples = 1000;
data_multi = randn(n_channels, n_samples);

% Add spikes to each channel
for ch = 1:n_channels
    spike_idx = 100 + ch*100;
    data_multi(ch, spike_idx) = data_multi(ch, spike_idx) + 10;
end

% Apply filter
data_filtered = median_filter_despike(data_multi, 5, 3.0);

% Check dimensions preserved
if isequal(size(data_filtered), size(data_multi))
    fprintf('  PASS: Dimensions preserved\n');
else
    fprintf('  FAIL: Dimensions changed\n');
end

%% Test 3: wavelet_despike - Basic functionality
fprintf('Test 3: wavelet_despike - Basic functionality\n');

% Create a clean signal
t = linspace(0, 1, 1000);
clean_signal = sin(2*pi*10*t) + 0.5*sin(2*pi*20*t);

% Add spikes
signal_with_spikes = clean_signal;
spike_indices = [100, 300, 500, 700, 900];
signal_with_spikes(spike_indices) = signal_with_spikes(spike_indices) + 5;

% Apply wavelet despike
data_in = signal_with_spikes;
data_out = wavelet_despike(data_in, 'db4', 5, 'soft');

% Check that output has same length
if length(data_out) == length(data_in)
    fprintf('  PASS: Output length matches input\n');
else
    fprintf('  FAIL: Output length mismatch\n');
end

% Check that spikes are reduced
spike_amplitudes_before = abs(signal_with_spikes(spike_indices) - clean_signal(spike_indices));
spike_amplitudes_after = abs(data_out(spike_indices) - clean_signal(spike_indices));

if mean(spike_amplitudes_after) < mean(spike_amplitudes_before)
    fprintf('  PASS: Average spike amplitude reduced\n');
else
    fprintf('  FAIL: Spikes not adequately reduced\n');
end

%% Test 4: wavelet_despike - Multi-channel
fprintf('Test 4: wavelet_despike - Multi-channel\n');

% Create multi-channel data
n_channels = 3;
n_samples = 1000;
data_multi = randn(n_channels, n_samples);

% Add spikes
for ch = 1:n_channels
    spike_idx = 100 + ch*100;
    data_multi(ch, spike_idx) = data_multi(ch, spike_idx) + 10;
end

% Apply filter
data_filtered = wavelet_despike(data_multi, 'db4', 5, 'soft');

% Check dimensions preserved
if isequal(size(data_filtered), size(data_multi))
    fprintf('  PASS: Dimensions preserved\n');
else
    fprintf('  FAIL: Dimensions changed\n');
end

%% Test 5: Correlation preservation
fprintf('Test 5: Correlation preservation (median filter)\n');

% Create clean signal
t = linspace(0, 2, 2000);
clean_signal = sin(2*pi*5*t) + 0.3*randn(1, 2000);

% Add a few spikes
signal_with_spikes = clean_signal;
spike_indices = [200, 600, 1000, 1400, 1800];
signal_with_spikes(spike_indices) = signal_with_spikes(spike_indices) + 8;

% Apply median filter
data_filtered = median_filter_despike(signal_with_spikes, 5, 3.0);

% Compute correlation with clean signal
corr_coef = corrcoef(clean_signal, data_filtered);
correlation = corr_coef(1, 2);

fprintf('  Correlation with clean signal: %.4f\n', correlation);
if correlation > 0.90
    fprintf('  PASS: High correlation preserved (>0.90)\n');
else
    fprintf('  FAIL: Correlation too low\n');
end

%% Test 6: Error handling
fprintf('Test 6: Error handling\n');

try
    % Test invalid window size (even number)
    median_filter_despike(randn(1, 100), 4, 3.0);
    fprintf('  FAIL: Should have thrown error for even window size\n');
catch ME
    if contains(ME.identifier, 'InvalidWindowSize')
        fprintf('  PASS: Caught invalid window size error\n');
    else
        fprintf('  FAIL: Wrong error type\n');
    end
end

try
    % Test invalid threshold
    median_filter_despike(randn(1, 100), 5, -1);
    fprintf('  FAIL: Should have thrown error for negative threshold\n');
catch ME
    if contains(ME.identifier, 'InvalidThreshold')
        fprintf('  PASS: Caught invalid threshold error\n');
    else
        fprintf('  FAIL: Wrong error type\n');
    end
end

fprintf('\nAll denoiser tests completed.\n');
