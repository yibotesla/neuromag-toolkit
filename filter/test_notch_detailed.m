% TEST_NOTCH_DETAILED Detailed test of notch filter
clear; close all; clc;

fs = 4800;
duration = 2;
t = 0:1/fs:duration-1/fs;

% Create signal with 50Hz component
signal = sin(2*pi*50*t);

% Apply notch filter
filtered = notch_filter(signal, fs, 50, 2, 200);

% Compute FFT
N = length(signal);
fft_orig = fft(signal);
fft_filt = fft(filtered);
freq = (0:N-1) * fs / N;

% Plot
figure;
subplot(2,1,1);
plot(freq(1:N/2), 20*log10(abs(fft_orig(1:N/2))));
hold on;
plot(freq(1:N/2), 20*log10(abs(fft_filt(1:N/2))));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
legend('Original', 'Filtered');
title('Frequency Response');
grid on;
xlim([0 200]);

subplot(2,1,2);
plot(freq(1:N/2), 20*log10(abs(fft_filt(1:N/2)) ./ abs(fft_orig(1:N/2))));
xlabel('Frequency (Hz)');
ylabel('Attenuation (dB)');
title('Attenuation');
grid on;
xlim([40 60]);

% Find exact attenuation at 50Hz
[~, idx_50] = min(abs(freq - 50));
attenuation = 20*log10(abs(fft_filt(idx_50)) / abs(fft_orig(idx_50)));
fprintf('Attenuation at 50Hz: %.1f dB\n', attenuation);

% Check power
power_orig = sum(abs(fft_orig).^2) / N;
power_filt = sum(abs(fft_filt).^2) / N;
fprintf('Original power: %.6f\n', power_orig);
fprintf('Filtered power: %.6f\n', power_filt);
fprintf('Power reduction: %.1f%%\n', 100*(1 - power_filt/power_orig));
