% Debug peak detection
clear; close all; clc;

% Generate test signal
fs = 4800;
duration = 10;
t = 0:1/fs:duration-1/fs;
signal_freq = 17;
signal = sin(2*pi*signal_freq*t) + 0.1*randn(size(t));

% Compute PSD
[frequencies, psd] = compute_psd(signal, fs);

% Define search region
target_freq = 17;
tolerance = 0.5;
search_bw = 2 * tolerance;
search_low = target_freq - search_bw/2;
search_high = target_freq + search_bw/2;

% Find indices in search region
search_idx = (frequencies >= search_low) & (frequencies <= search_high);

% Extract PSD in search region
psd_search = psd(search_idx);
freq_search = frequencies(search_idx);

fprintf('Search region: [%.2f, %.2f] Hz\n', search_low, search_high);
fprintf('Number of points in search region: %d\n', length(psd_search));
fprintf('Max PSD in search region: %.2e\n', max(psd_search));
fprintf('Mean PSD in search region: %.2e\n', mean(psd_search));
fprintf('Median PSD in search region: %.2e\n', median(psd_search));

% Try findpeaks with different parameters
min_peak_height = 2.0;
baseline = median(psd_search);

fprintf('\nTrying findpeaks with MinPeakHeight = %.2f * baseline = %.2e\n', ...
    min_peak_height, min_peak_height * baseline);

[peak_powers, peak_locs] = findpeaks(psd_search, ...
    'MinPeakHeight', min_peak_height * baseline);

fprintf('Number of peaks found: %d\n', length(peak_powers));

if ~isempty(peak_powers)
    fprintf('Peak powers: ');
    fprintf('%.2e ', peak_powers);
    fprintf('\n');
    fprintf('Peak frequencies: ');
    fprintf('%.2f ', freq_search(peak_locs));
    fprintf('\n');
end

% Try with lower threshold
fprintf('\nTrying with lower threshold (1.5x baseline):\n');
[peak_powers2, peak_locs2] = findpeaks(psd_search, ...
    'MinPeakHeight', 1.5 * baseline);
fprintf('Number of peaks found: %d\n', length(peak_powers2));

% Try without threshold
fprintf('\nTrying without MinPeakHeight:\n');
[peak_powers3, peak_locs3] = findpeaks(psd_search);
fprintf('Number of peaks found: %d\n', length(peak_powers3));

% Plot
figure;
subplot(2,1,1);
plot(frequencies, 10*log10(psd));
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('Full PSD');
grid on;
xlim([0 50]);

subplot(2,1,2);
plot(freq_search, 10*log10(psd_search), 'b-', 'LineWidth', 1.5);
hold on;
if ~isempty(peak_locs3)
    plot(freq_search(peak_locs3), 10*log10(peak_powers3), 'ro', 'MarkerSize', 8);
end
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('Search Region with Detected Peaks');
grid on;
legend('PSD', 'Peaks');
