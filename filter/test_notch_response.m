% TEST_NOTCH_RESPONSE Test the frequency response of the notch filter
clear; close all; clc;

fs = 4800;
notch_freq = 50;
bandwidth = 2;
filter_order = 200;

% Design the filter manually to check response
low_freq = notch_freq - bandwidth/2;
high_freq = notch_freq + bandwidth/2;
wn = [low_freq, high_freq] / (fs/2);
b = fir1(filter_order, wn, 'stop');
a = 1;

% Compute frequency response
[h, f] = freqz(b, a, 4096, fs);

% Plot
figure;
subplot(2,1,1);
plot(f, 20*log10(abs(h)));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Notch Filter Frequency Response');
grid on;
xlim([0 200]);
ylim([-80 5]);

subplot(2,1,2);
plot(f, 20*log10(abs(h)));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
title('Notch Filter Frequency Response (Zoomed)');
grid on;
xlim([45 55]);
ylim([-80 5]);

% Find attenuation at 50Hz
[~, idx] = min(abs(f - 50));
attenuation_50 = 20*log10(abs(h(idx)));
fprintf('Filter attenuation at 50Hz: %.1f dB\n', attenuation_50);

% Find -3dB bandwidth
h_db = 20*log10(abs(h));
notch_indices = find(h_db < -3);
if ~isempty(notch_indices)
    notch_freqs = f(notch_indices);
    notch_bw = max(notch_freqs) - min(notch_freqs);
    fprintf('Notch -3dB bandwidth: %.2f Hz\n', notch_bw);
end
