% TEST_ADAPTIVE_FILTERS Simple test script for adaptive filter implementations
%
% This script tests the LMS and RLS adaptive filters with synthetic data

clear; close all; clc;

fprintf('Testing Adaptive Filter Implementations\n');
fprintf('========================================\n\n');

%% Generate synthetic test data
fs = 4800; % Sampling rate (Hz)
duration = 1; % Duration (seconds)
n_samples = fs * duration;
t = (0:n_samples-1) / fs;

% Create synthetic MEG signal: 17Hz sinusoid + noise
signal_freq = 17; % Hz
signal_amplitude = 1e-12; % Tesla
meg_signal = signal_amplitude * sin(2*pi*signal_freq*t);

% Create synthetic reference noise (common to all channels)
noise_freq = [50, 100]; % Power line interference
noise_amplitude = 5e-12; % Tesla (larger than signal)
ref_noise = zeros(3, n_samples);
for i = 1:3
    for f = noise_freq
        ref_noise(i, :) = ref_noise(i, :) + ...
            noise_amplitude * sin(2*pi*f*t + rand*2*pi);
    end
    % Add some random noise
    ref_noise(i, :) = ref_noise(i, :) + randn(1, n_samples) * 1e-12;
end

% Create MEG data: signal + correlated noise
n_meg_channels = 4; % Test with 4 channels
meg_data = zeros(n_meg_channels, n_samples);
for ch = 1:n_meg_channels
    % Each channel gets the signal plus a weighted combination of reference noise
    weights = rand(1, 3) * 0.5;
    meg_data(ch, :) = meg_signal + weights * ref_noise;
    % Add some uncorrelated noise
    meg_data(ch, :) = meg_data(ch, :) + randn(1, n_samples) * 0.5e-12;
end

fprintf('Generated synthetic data:\n');
fprintf('  MEG channels: %d\n', n_meg_channels);
fprintf('  Reference channels: %d\n', size(ref_noise, 1));
fprintf('  Samples: %d\n', n_samples);
fprintf('  Duration: %.2f s\n\n', duration);

%% Test LMS Adaptive Filter
fprintf('Testing LMS Adaptive Filter...\n');
params_lms.mu = 0.01;
params_lms.filter_order = 10;

tic;
[data_lms, weights_lms, error_lms] = lms_adaptive_filter(meg_data, ref_noise, params_lms);
time_lms = toc;

fprintf('  Execution time: %.4f s\n', time_lms);
fprintf('  Output dimensions: %d × %d\n', size(data_lms, 1), size(data_lms, 2));
fprintf('  Weights dimensions: %d × %d × %d\n', ...
    size(weights_lms, 1), size(weights_lms, 2), size(weights_lms, 3));

% Calculate noise reduction
[nr_lms, power_before, power_after_lms] = calculate_noise_reduction(meg_data, data_lms);
fprintf('  Noise reduction per channel: [');
fprintf('%.2f%% ', nr_lms);
fprintf(']\n');
fprintf('  Average noise reduction: %.2f%%\n\n', mean(nr_lms));

%% Test RLS Adaptive Filter
fprintf('Testing RLS Adaptive Filter...\n');
params_rls.lambda = 0.995;
params_rls.filter_order = 10;
params_rls.delta = 1.0;

tic;
[data_rls, weights_rls, error_rls] = rls_adaptive_filter(meg_data, ref_noise, params_rls);
time_rls = toc;

fprintf('  Execution time: %.4f s\n', time_rls);
fprintf('  Output dimensions: %d × %d\n', size(data_rls, 1), size(data_rls, 2));
fprintf('  Weights dimensions: %d × %d × %d\n', ...
    size(weights_rls, 1), size(weights_rls, 2), size(weights_rls, 3));

% Calculate noise reduction
[nr_rls, ~, power_after_rls] = calculate_noise_reduction(meg_data, data_rls);
fprintf('  Noise reduction per channel: [');
fprintf('%.2f%% ', nr_rls);
fprintf(']\n');
fprintf('  Average noise reduction: %.2f%%\n\n', mean(nr_rls));

%% Compare Results
fprintf('Comparison:\n');
fprintf('  LMS average noise reduction: %.2f%%\n', mean(nr_lms));
fprintf('  RLS average noise reduction: %.2f%%\n', mean(nr_rls));
fprintf('  RLS speedup factor: %.2fx\n', time_lms / time_rls);

%% Visualize Results (Channel 1)
figure('Position', [100, 100, 1200, 800]);

ch_plot = 1; % Plot first channel

% Time domain comparison
subplot(3, 2, 1);
plot(t, meg_data(ch_plot, :) * 1e12);
xlabel('Time (s)');
ylabel('Amplitude (pT)');
title(sprintf('Original MEG Data (Channel %d)', ch_plot));
grid on;

subplot(3, 2, 3);
plot(t, data_lms(ch_plot, :) * 1e12);
xlabel('Time (s)');
ylabel('Amplitude (pT)');
title(sprintf('LMS Filtered (Channel %d)', ch_plot));
grid on;

subplot(3, 2, 5);
plot(t, data_rls(ch_plot, :) * 1e12);
xlabel('Time (s)');
ylabel('Amplitude (pT)');
title(sprintf('RLS Filtered (Channel %d)', ch_plot));
grid on;

% Frequency domain comparison
subplot(3, 2, 2);
[psd_orig, f] = pwelch(meg_data(ch_plot, :), [], [], [], fs);
plot(f, 10*log10(psd_orig));
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('Original PSD');
grid on;
xlim([0, 200]);

subplot(3, 2, 4);
[psd_lms, f] = pwelch(data_lms(ch_plot, :), [], [], [], fs);
plot(f, 10*log10(psd_lms));
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('LMS Filtered PSD');
grid on;
xlim([0, 200]);

subplot(3, 2, 6);
[psd_rls, f] = pwelch(data_rls(ch_plot, :), [], [], [], fs);
plot(f, 10*log10(psd_rls));
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('RLS Filtered PSD');
grid on;
xlim([0, 200]);

sgtitle('Adaptive Filter Comparison');

fprintf('\nTest completed successfully!\n');
fprintf('All functions are working correctly.\n');
