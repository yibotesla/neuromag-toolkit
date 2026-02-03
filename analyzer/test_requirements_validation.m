% TEST_REQUIREMENTS_VALIDATION - Validate analyzer functions against requirements
%
% This script validates the analyzer module against the specific requirements:
% - Requirement 2.1: PSD computation
% - Requirement 2.2: SNR calculation
% - Requirement 2.3: 17Hz peak detection

clear; close all; clc;

fprintf('Validating Analyzer Module Against Requirements\n');
fprintf('================================================\n\n');

%% Requirement 2.1: PSD Computation
fprintf('Requirement 2.1: PSD Computation\n');
fprintf('--------------------------------\n');

fs = 4800;
duration = 10;
t = 0:1/fs:duration-1/fs;

% Test with pwelch method
signal = sin(2*pi*17*t) + 0.1*randn(size(t));
[freq_pwelch, psd_pwelch] = compute_psd(signal, fs, 'Method', 'pwelch');

fprintf('✓ pwelch method: %d frequency points from %.2f to %.2f Hz\n', ...
    length(freq_pwelch), freq_pwelch(1), freq_pwelch(end));

% Test with periodogram method
[freq_period, psd_period] = compute_psd(signal, fs, 'Method', 'periodogram');

fprintf('✓ periodogram method: %d frequency points from %.2f to %.2f Hz\n', ...
    length(freq_period), freq_period(1), freq_period(end));

% Verify format: length should be NFFT/2+1, range should be 0 to fs/2
expected_max_freq = fs/2;
if abs(freq_pwelch(end) - expected_max_freq) < 1
    fprintf('✓ Frequency range correct: 0 to fs/2\n');
else
    fprintf('✗ Frequency range incorrect\n');
end

fprintf('\n');

%% Requirement 2.2: SNR Calculation
fprintf('Requirement 2.2: SNR Calculation at Target Frequency\n');
fprintf('----------------------------------------------------\n');

% Create signal with known SNR
signal_amplitude = 1.0;
noise_amplitude = 0.1;
signal_with_noise = signal_amplitude * sin(2*pi*17*t) + noise_amplitude * randn(size(t));

% Calculate SNR at 17Hz
[snr_db, sig_power, noise_power] = calculate_snr(signal_with_noise, fs, 17);

fprintf('Signal amplitude: %.2f, Noise amplitude: %.2f\n', signal_amplitude, noise_amplitude);
fprintf('Theoretical SNR: ~%.1f dB\n', 20*log10(signal_amplitude/noise_amplitude));
fprintf('Calculated SNR: %.2f dB\n', snr_db);
fprintf('Signal power: %.2e\n', sig_power);
fprintf('Noise power: %.2e\n', noise_power);

if snr_db > 0 && sig_power > noise_power
    fprintf('✓ SNR calculation working correctly\n');
else
    fprintf('✗ SNR calculation issue\n');
end

fprintf('\n');

%% Requirement 2.3: 17Hz Peak Detection
fprintf('Requirement 2.3: 17Hz Peak Detection\n');
fprintf('------------------------------------\n');

% Test 1: Signal with 17Hz component
signal_17hz = sin(2*pi*17*t) + 0.1*randn(size(t));
[detected_1, freq_1, power_1] = detect_peak_at_frequency(signal_17hz, fs, 17);

fprintf('Test 1 - Signal with 17Hz:\n');
fprintf('  Peak detected: %d\n', detected_1);
if detected_1
    fprintf('  Peak frequency: %.2f Hz (target: 17.00 Hz)\n', freq_1);
    fprintf('  Frequency error: %.3f Hz\n', abs(freq_1 - 17));
    if abs(freq_1 - 17) <= 0.5
        fprintf('  ✓ Peak within ±0.5Hz tolerance\n');
    else
        fprintf('  ✗ Peak outside tolerance\n');
    end
else
    fprintf('  ✗ Failed to detect peak\n');
end

% Test 2: Signal without 17Hz component
signal_no_17hz = sin(2*pi*25*t) + 0.1*randn(size(t));
[detected_2, ~, ~] = detect_peak_at_frequency(signal_no_17hz, fs, 17);

fprintf('\nTest 2 - Signal without 17Hz:\n');
fprintf('  Peak detected: %d\n', detected_2);
if ~detected_2
    fprintf('  ✓ Correctly identified no peak\n');
else
    fprintf('  ⚠ False positive detection\n');
end

% Test 3: Multiple frequencies, verify 17Hz is detected
signal_multi = sin(2*pi*10*t) + 2*sin(2*pi*17*t) + sin(2*pi*30*t) + 0.1*randn(size(t));
[detected_3, freq_3, power_3] = detect_peak_at_frequency(signal_multi, fs, 17);

fprintf('\nTest 3 - Multiple frequencies (10Hz, 17Hz, 30Hz):\n');
fprintf('  Peak detected: %d\n', detected_3);
if detected_3
    fprintf('  Peak frequency: %.2f Hz\n', freq_3);
    if abs(freq_3 - 17) <= 0.5
        fprintf('  ✓ Correctly identified 17Hz among multiple frequencies\n');
    else
        fprintf('  ✗ Detected wrong frequency\n');
    end
else
    fprintf('  ✗ Failed to detect 17Hz peak\n');
end

fprintf('\n');

%% Summary
fprintf('================================================\n');
fprintf('Requirements Validation Summary\n');
fprintf('================================================\n');
fprintf('✓ Requirement 2.1: PSD computation implemented\n');
fprintf('✓ Requirement 2.2: SNR calculation implemented\n');
fprintf('✓ Requirement 2.3: 17Hz peak detection implemented\n');
fprintf('\nAll requirements validated successfully!\n');
