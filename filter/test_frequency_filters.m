% TEST_FREQUENCY_FILTERS Test frequency filtering functions
%
% This script tests the lowpass, bandpass, and notch filter implementations
% with synthetic data to verify basic functionality.

clear; close all; clc;

fprintf('Testing Frequency Filters\n');
fprintf('=========================\n\n');

%% Setup test parameters
fs = 4800;  % Sampling frequency (Hz)
duration = 2;  % Duration (seconds)
t = 0:1/fs:duration-1/fs;
n_samples = length(t);

%% Test 1: Lowpass Filter
fprintf('Test 1: Lowpass Filter\n');
fprintf('----------------------\n');

% Create test signal: 10Hz + 50Hz + 100Hz components
signal_lp = sin(2*pi*10*t) + 0.5*sin(2*pi*50*t) + 0.3*sin(2*pi*100*t);
signal_lp = signal_lp + 0.1*randn(size(t));  % Add noise

% Apply lowpass filter at 30Hz
try
    filtered_lp = lowpass_filter(signal_lp, fs, 30);
    fprintf('✓ Lowpass filter executed successfully\n');
    
    % Check output dimensions
    if isequal(size(filtered_lp), size(signal_lp))
        fprintf('✓ Output dimensions match input\n');
    else
        fprintf('✗ Output dimensions mismatch\n');
    end
    
    % Check that high frequencies are attenuated
    fft_orig = abs(fft(signal_lp));
    fft_filt = abs(fft(filtered_lp));
    freq_axis = (0:n_samples-1) * fs / n_samples;
    
    % Find power at 50Hz and 100Hz
    idx_50 = find(freq_axis >= 50, 1);
    idx_100 = find(freq_axis >= 100, 1);
    
    attenuation_50 = 20*log10(fft_filt(idx_50) / fft_orig(idx_50));
    attenuation_100 = 20*log10(fft_filt(idx_100) / fft_orig(idx_100));
    
    fprintf('  Attenuation at 50Hz: %.1f dB\n', attenuation_50);
    fprintf('  Attenuation at 100Hz: %.1f dB\n', attenuation_100);
    
    if attenuation_50 < -20 && attenuation_100 < -20
        fprintf('✓ High frequencies properly attenuated\n');
    else
        fprintf('⚠ Attenuation may be insufficient\n');
    end
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

fprintf('\n');

%% Test 2: Bandpass Filter
fprintf('Test 2: Bandpass Filter\n');
fprintf('-----------------------\n');

% Create test signal: 17Hz + 89Hz + 150Hz components
signal_bp = sin(2*pi*17*t) + sin(2*pi*89*t) + 0.5*sin(2*pi*150*t);
signal_bp = signal_bp + 0.1*randn(size(t));  % Add noise

% Apply bandpass filter at 89Hz ± 2Hz (87-91Hz)
try
    filtered_bp = bandpass_filter(signal_bp, fs, 89, 4);
    fprintf('✓ Bandpass filter executed successfully\n');
    
    % Check output dimensions
    if isequal(size(filtered_bp), size(signal_bp))
        fprintf('✓ Output dimensions match input\n');
    else
        fprintf('✗ Output dimensions mismatch\n');
    end
    
    % Check that out-of-band frequencies are attenuated
    fft_orig = abs(fft(signal_bp));
    fft_filt = abs(fft(filtered_bp));
    freq_axis = (0:n_samples-1) * fs / n_samples;
    
    % Find power at 17Hz, 89Hz, and 150Hz
    idx_17 = find(freq_axis >= 17, 1);
    idx_89 = find(freq_axis >= 89, 1);
    idx_150 = find(freq_axis >= 150, 1);
    
    attenuation_17 = 20*log10(fft_filt(idx_17) / fft_orig(idx_17));
    attenuation_89 = 20*log10(fft_filt(idx_89) / fft_orig(idx_89));
    attenuation_150 = 20*log10(fft_filt(idx_150) / fft_orig(idx_150));
    
    fprintf('  Attenuation at 17Hz: %.1f dB\n', attenuation_17);
    fprintf('  Attenuation at 89Hz: %.1f dB\n', attenuation_89);
    fprintf('  Attenuation at 150Hz: %.1f dB\n', attenuation_150);
    
    if attenuation_17 < -20 && attenuation_89 > -3 && attenuation_150 < -20
        fprintf('✓ Bandpass selectivity verified\n');
    else
        fprintf('⚠ Bandpass selectivity may be insufficient\n');
    end
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

fprintf('\n');

%% Test 3: Notch Filter
fprintf('Test 3: Notch Filter\n');
fprintf('--------------------\n');

% Create test signal: 17Hz + 50Hz + 100Hz + 150Hz components
signal_notch = sin(2*pi*17*t) + 0.8*sin(2*pi*50*t) + 0.6*sin(2*pi*100*t) + 0.4*sin(2*pi*150*t);
signal_notch = signal_notch + 0.1*randn(size(t));  % Add noise

% Apply notch filter at 50Hz and harmonics
try
    filtered_notch = notch_filter(signal_notch, fs, [50, 100, 150]);
    fprintf('✓ Notch filter executed successfully\n');
    
    % Check output dimensions
    if isequal(size(filtered_notch), size(signal_notch))
        fprintf('✓ Output dimensions match input\n');
    else
        fprintf('✗ Output dimensions mismatch\n');
    end
    
    % Check that notch frequencies are attenuated
    fft_orig = abs(fft(signal_notch));
    fft_filt = abs(fft(filtered_notch));
    freq_axis = (0:n_samples-1) * fs / n_samples;
    
    % Find power at 17Hz, 50Hz, 100Hz, and 150Hz
    idx_17 = find(freq_axis >= 17, 1);
    idx_50 = find(freq_axis >= 50, 1);
    idx_100 = find(freq_axis >= 100, 1);
    idx_150 = find(freq_axis >= 150, 1);
    
    attenuation_17 = 20*log10(fft_filt(idx_17) / fft_orig(idx_17));
    attenuation_50 = 20*log10(fft_filt(idx_50) / fft_orig(idx_50));
    attenuation_100 = 20*log10(fft_filt(idx_100) / fft_orig(idx_100));
    attenuation_150 = 20*log10(fft_filt(idx_150) / fft_orig(idx_150));
    
    fprintf('  Attenuation at 17Hz: %.1f dB\n', attenuation_17);
    fprintf('  Attenuation at 50Hz: %.1f dB\n', attenuation_50);
    fprintf('  Attenuation at 100Hz: %.1f dB\n', attenuation_100);
    fprintf('  Attenuation at 150Hz: %.1f dB\n', attenuation_150);
    
    if attenuation_17 > -3 && attenuation_50 < -20 && attenuation_100 < -20 && attenuation_150 < -20
        fprintf('✓ Notch frequencies properly attenuated\n');
    else
        fprintf('⚠ Notch attenuation may be insufficient\n');
    end
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

fprintf('\n');

%% Test 4: Multi-channel processing
fprintf('Test 4: Multi-channel Processing\n');
fprintf('---------------------------------\n');

% Create multi-channel test data
n_channels = 3;
signal_multi = zeros(n_channels, n_samples);
for ch = 1:n_channels
    signal_multi(ch, :) = sin(2*pi*10*t) + 0.5*sin(2*pi*50*t) + 0.1*randn(1, n_samples);
end

try
    filtered_multi = lowpass_filter(signal_multi, fs, 30);
    fprintf('✓ Multi-channel lowpass filter executed successfully\n');
    
    if size(filtered_multi, 1) == n_channels && size(filtered_multi, 2) == n_samples
        fprintf('✓ Multi-channel output dimensions correct\n');
    else
        fprintf('✗ Multi-channel output dimensions incorrect\n');
    end
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

fprintf('\n');

%% Test 5: Zero-phase filtering (timing preservation)
fprintf('Test 5: Zero-phase Filtering\n');
fprintf('-----------------------------\n');

% Create signal with known peak
peak_time = 0.5;  % Peak at 0.5 seconds
peak_idx = round(peak_time * fs);
signal_peak = zeros(1, n_samples);
signal_peak(peak_idx) = 1;
% Smooth it with a Gaussian
sigma = 0.01 * fs;
gaussian = exp(-((1:n_samples) - peak_idx).^2 / (2*sigma^2));
signal_peak = signal_peak + gaussian;

try
    filtered_peak = lowpass_filter(signal_peak, fs, 100);
    
    % Find peak in filtered signal
    [~, filtered_peak_idx] = max(filtered_peak);
    
    timing_error = abs(filtered_peak_idx - peak_idx);
    fprintf('  Original peak at sample: %d\n', peak_idx);
    fprintf('  Filtered peak at sample: %d\n', filtered_peak_idx);
    fprintf('  Timing error: %d samples (%.3f ms)\n', timing_error, timing_error/fs*1000);
    
    if timing_error <= 1
        fprintf('✓ Zero-phase filtering preserves timing\n');
    else
        fprintf('⚠ Timing preservation may be insufficient\n');
    end
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end

fprintf('\n');
fprintf('=========================\n');
fprintf('Testing Complete\n');
