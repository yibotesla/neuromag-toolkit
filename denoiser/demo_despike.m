% DEMO_DESPIKE Demonstration of spike noise removal functions
%
% This script demonstrates the median filter and wavelet despike functions
% on synthetic MEG-like data with artificial spikes

% Add path
addpath('../denoiser');

%% Create synthetic MEG-like signal
fprintf('Creating synthetic MEG signal with spikes...\n');

% Parameters
fs = 4800;  % Sampling rate (Hz)
duration = 2;  % Duration (seconds)
t = 0:1/fs:duration-1/fs;
n_samples = length(t);

% Create a realistic MEG signal: mixture of frequencies + noise
signal_clean = 0.5 * sin(2*pi*10*t) + ...  % 10 Hz component
               0.3 * sin(2*pi*17*t) + ...  % 17 Hz component (phantom signal)
               0.2 * sin(2*pi*50*t) + ...  % 50 Hz power line
               0.1 * randn(1, n_samples);  % Background noise

% Add spike noise at random locations
n_spikes = 20;
spike_indices = randperm(n_samples, n_spikes);
spike_amplitudes = 3 + 2*rand(1, n_spikes);  % Random amplitudes 3-5
signal_with_spikes = signal_clean;
signal_with_spikes(spike_indices) = signal_with_spikes(spike_indices) + spike_amplitudes;

%% Apply median filter despike
fprintf('Applying median filter despike...\n');
signal_median = median_filter_despike(signal_with_spikes, 5, 3.0);

%% Apply wavelet despike
fprintf('Applying wavelet despike...\n');
signal_wavelet = wavelet_despike(signal_with_spikes, 'db4', 5, 'soft');

%% Compute metrics
fprintf('\nPerformance Metrics:\n');

% Correlation with clean signal
corr_median = corrcoef(signal_clean, signal_median);
corr_wavelet = corrcoef(signal_clean, signal_wavelet);

fprintf('  Median filter correlation: %.4f\n', corr_median(1,2));
fprintf('  Wavelet filter correlation: %.4f\n', corr_wavelet(1,2));

% RMSE
rmse_before = sqrt(mean((signal_with_spikes - signal_clean).^2));
rmse_median = sqrt(mean((signal_median - signal_clean).^2));
rmse_wavelet = sqrt(mean((signal_wavelet - signal_clean).^2));

fprintf('  RMSE before: %.4f\n', rmse_before);
fprintf('  RMSE median: %.4f\n', rmse_median);
fprintf('  RMSE wavelet: %.4f\n', rmse_wavelet);

% Spike reduction at spike locations
spike_error_before = mean(abs(signal_with_spikes(spike_indices) - signal_clean(spike_indices)));
spike_error_median = mean(abs(signal_median(spike_indices) - signal_clean(spike_indices)));
spike_error_wavelet = mean(abs(signal_wavelet(spike_indices) - signal_clean(spike_indices)));

fprintf('  Mean spike error before: %.4f\n', spike_error_before);
fprintf('  Mean spike error median: %.4f\n', spike_error_median);
fprintf('  Mean spike error wavelet: %.4f\n', spike_error_wavelet);

%% Visualization
fprintf('\nGenerating visualization...\n');

figure('Position', [100, 100, 1200, 800]);

% Plot 1: Original with spikes
subplot(4,1,1);
plot(t, signal_with_spikes, 'b');
hold on;
plot(t(spike_indices), signal_with_spikes(spike_indices), 'ro', 'MarkerSize', 8);
hold off;
title('Original Signal with Spikes');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Signal', 'Spikes');
grid on;

% Plot 2: Median filter result
subplot(4,1,2);
plot(t, signal_median, 'g', 'LineWidth', 1.5);
hold on;
plot(t, signal_clean, 'k--', 'LineWidth', 1);
hold off;
title('Median Filter Despike Result');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Filtered', 'Clean');
grid on;

% Plot 3: Wavelet result
subplot(4,1,3);
plot(t, signal_wavelet, 'm', 'LineWidth', 1.5);
hold on;
plot(t, signal_clean, 'k--', 'LineWidth', 1);
hold off;
title('Wavelet Despike Result');
xlabel('Time (s)');
ylabel('Amplitude');
legend('Filtered', 'Clean');
grid on;

% Plot 4: Comparison at spike locations
subplot(4,1,4);
zoom_start = spike_indices(1) - 50;
zoom_end = spike_indices(1) + 50;
zoom_range = zoom_start:zoom_end;
plot(t(zoom_range), signal_with_spikes(zoom_range), 'b', 'LineWidth', 1);
hold on;
plot(t(zoom_range), signal_median(zoom_range), 'g', 'LineWidth', 1.5);
plot(t(zoom_range), signal_wavelet(zoom_range), 'm', 'LineWidth', 1.5);
plot(t(zoom_range), signal_clean(zoom_range), 'k--', 'LineWidth', 1);
hold off;
title('Zoomed View at First Spike');
xlabel('Time (s)');
ylabel('Amplitude');
legend('With Spikes', 'Median', 'Wavelet', 'Clean');
grid on;

fprintf('Demo complete!\n');
