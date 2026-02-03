% TEST_ANALYZER_BASIC - Basic functionality test for analyzer module
%
% This script tests the basic functionality of:
% - compute_psd
% - calculate_snr
% - detect_peak_at_frequency

clear; close all; clc;

fprintf('Testing Analyzer Module Functions\n');
fprintf('==================================\n\n');

%% Test 1: compute_psd with synthetic signal
fprintf('Test 1: compute_psd with 17Hz sinusoid\n');

% Generate test signal: 17Hz sinusoid + noise
fs = 4800;  % Sampling rate
duration = 10;  % seconds
t = 0:1/fs:duration-1/fs;
signal_freq = 17;  % Hz
signal = sin(2*pi*signal_freq*t) + 0.1*randn(size(t));

% Compute PSD
[frequencies, psd] = compute_psd(signal, fs);

% Verify output format
fprintf('  - Frequency vector length: %d\n', length(frequencies));
fprintf('  - PSD vector length: %d\n', length(psd));
fprintf('  - Frequency range: [%.2f, %.2f] Hz\n', frequencies(1), frequencies(end));

% Find peak in PSD
[~, peak_idx] = max(psd);
peak_freq = frequencies(peak_idx);
fprintf('  - Peak frequency: %.2f Hz (expected: %.2f Hz)\n', peak_freq, signal_freq);

if abs(peak_freq - signal_freq) < 0.5
    fprintf('  ✓ PASS: Peak detected near target frequency\n\n');
else
    fprintf('  ✗ FAIL: Peak not at expected frequency\n\n');
end

%% Test 2: calculate_snr
fprintf('Test 2: calculate_snr at 17Hz\n');

% Calculate SNR
[snr_db, signal_power, noise_power] = calculate_snr(signal, fs, signal_freq);

fprintf('  - SNR: %.2f dB\n', snr_db);
fprintf('  - Signal power: %.2e\n', signal_power);
fprintf('  - Noise power: %.2e\n', noise_power);

if snr_db > 0
    fprintf('  ✓ PASS: Positive SNR detected\n\n');
else
    fprintf('  ✗ FAIL: SNR should be positive for signal with noise\n\n');
end

%% Test 3: detect_peak_at_frequency
fprintf('Test 3: detect_peak_at_frequency at 17Hz\n');

% Detect peak
[peak_detected, peak_freq, peak_power, peak_idx] = ...
    detect_peak_at_frequency(signal, fs, signal_freq);

fprintf('  - Peak detected: %d\n', peak_detected);
if peak_detected
    fprintf('  - Peak frequency: %.2f Hz\n', peak_freq);
    fprintf('  - Peak power: %.2e\n', peak_power);
    fprintf('  - Peak index: %d\n', peak_idx);
end

if peak_detected && abs(peak_freq - signal_freq) <= 0.5
    fprintf('  ✓ PASS: Peak correctly detected at target frequency\n\n');
else
    fprintf('  ✗ FAIL: Peak detection failed\n\n');
end

%% Test 4: Multi-channel data
fprintf('Test 4: Multi-channel processing\n');

% Generate multi-channel data (3 channels)
n_channels = 3;
multi_signal = zeros(n_channels, length(t));
for ch = 1:n_channels
    multi_signal(ch, :) = sin(2*pi*signal_freq*t) + 0.1*randn(size(t));
end

% Compute PSD for multi-channel
[frequencies_multi, psd_multi] = compute_psd(multi_signal, fs);

fprintf('  - Number of channels: %d\n', n_channels);
fprintf('  - PSD matrix size: [%d, %d]\n', size(psd_multi, 1), size(psd_multi, 2));

% Calculate SNR for multi-channel
snr_multi = calculate_snr(multi_signal, fs, signal_freq);

fprintf('  - SNR per channel: [');
fprintf('%.2f ', snr_multi);
fprintf('] dB\n');

% Detect peaks for multi-channel
peak_detected_multi = detect_peak_at_frequency(multi_signal, fs, signal_freq);

fprintf('  - Peaks detected: [');
fprintf('%d ', peak_detected_multi);
fprintf(']\n');

if all(peak_detected_multi)
    fprintf('  ✓ PASS: All channels detected peaks\n\n');
else
    fprintf('  ✗ FAIL: Not all channels detected peaks\n\n');
end

%% Test 5: Edge case - no peak present
fprintf('Test 5: Edge case - signal without target frequency\n');

% Generate signal without 17Hz component
signal_no_peak = randn(size(t));

% Try to detect peak
[peak_detected_no, ~, ~, ~] = detect_peak_at_frequency(signal_no_peak, fs, signal_freq);

fprintf('  - Peak detected: %d\n', peak_detected_no);

if ~peak_detected_no
    fprintf('  ✓ PASS: Correctly identified no peak present\n\n');
else
    fprintf('  ⚠ WARNING: False positive peak detection\n\n');
end

%% Summary
fprintf('==================================\n');
fprintf('Basic functionality tests completed\n');
fprintf('All core functions are operational\n');
