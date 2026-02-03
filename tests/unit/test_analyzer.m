% TEST_ANALYZER - Unit tests for analyzer module functions
%
% Tests:
% - compute_psd: Power spectral density computation
% - calculate_snr: Signal-to-noise ratio calculation
% - detect_peak_at_frequency: Peak detection at target frequency
% - detect_triggers: Trigger signal detection
% - extract_epochs: Trial epoch extraction
% - compute_grand_average: Grand average computation
%
% Requirements: 2.1, 2.2, 2.3, 5.3, 5.4, 5.5, 6.1

function test_analyzer()
    % Run all test cases
    fprintf('\n=== Testing Analyzer Module ===\n\n');
    
    test_compute_psd_basic();
    test_compute_psd_multichannel();
    test_calculate_snr_basic();
    test_calculate_snr_multichannel();
    test_detect_peak_basic();
    test_detect_peak_no_peak();
    test_detect_peak_multichannel();
    test_detect_triggers_basic();
    test_detect_triggers_min_interval();
    test_extract_epochs_basic();
    test_extract_epochs_boundary();
    test_compute_grand_average_basic();
    
    fprintf('\n=== All Analyzer Tests Passed ===\n\n');
end

%% Test compute_psd - Basic functionality
function test_compute_psd_basic()
    fprintf('Test: compute_psd - Basic functionality\n');
    
    % Generate test signal
    fs = 4800;
    t = 0:1/fs:5-1/fs;
    signal = sin(2*pi*17*t) + 0.1*randn(size(t));
    
    % Compute PSD
    [frequencies, psd] = compute_psd(signal, fs);
    
    % Verify output format
    assert(isvector(frequencies), 'Frequencies should be a vector');
    assert(isvector(psd), 'PSD should be a vector');
    assert(length(frequencies) == length(psd), 'Frequencies and PSD should have same length');
    
    % Verify frequency range
    assert(frequencies(1) >= 0, 'Minimum frequency should be >= 0');
    assert(frequencies(end) <= fs/2 + 1, 'Maximum frequency should be <= fs/2');
    
    % Verify PSD is positive
    assert(all(psd > 0), 'PSD values should be positive');
    
    fprintf('  ✓ PASS\n');
end

%% Test compute_psd - Multi-channel
function test_compute_psd_multichannel()
    fprintf('Test: compute_psd - Multi-channel\n');
    
    % Generate multi-channel test signal
    fs = 4800;
    t = 0:1/fs:5-1/fs;
    n_channels = 3;
    signal = zeros(n_channels, length(t));
    for ch = 1:n_channels
        signal(ch, :) = sin(2*pi*17*t) + 0.1*randn(size(t));
    end
    
    % Compute PSD
    [frequencies, psd] = compute_psd(signal, fs);
    
    % Verify output format
    assert(isvector(frequencies), 'Frequencies should be a vector');
    assert(ismatrix(psd), 'PSD should be a matrix for multi-channel');
    assert(size(psd, 1) == n_channels, 'PSD should have n_channels rows');
    assert(size(psd, 2) == length(frequencies), 'PSD columns should match frequency length');
    
    % Verify all channels have positive PSD
    assert(all(psd(:) > 0), 'All PSD values should be positive');
    
    fprintf('  ✓ PASS\n');
end

%% Test calculate_snr - Basic functionality
function test_calculate_snr_basic()
    fprintf('Test: calculate_snr - Basic functionality\n');
    
    % Generate test signal with known frequency
    fs = 4800;
    t = 0:1/fs:10-1/fs;
    target_freq = 17;
    signal = sin(2*pi*target_freq*t) + 0.1*randn(size(t));
    
    % Calculate SNR
    [snr_db, signal_power, noise_power] = calculate_snr(signal, fs, target_freq);
    
    % Verify outputs
    assert(isscalar(snr_db), 'SNR should be scalar for single channel');
    assert(isscalar(signal_power), 'Signal power should be scalar');
    assert(isscalar(noise_power), 'Noise power should be scalar');
    
    % Verify SNR is positive (signal should be stronger than noise)
    assert(snr_db > 0, 'SNR should be positive for signal with noise');
    
    % Verify signal power > noise power
    assert(signal_power > noise_power, 'Signal power should exceed noise power');
    
    % Verify powers are positive
    assert(signal_power > 0, 'Signal power should be positive');
    assert(noise_power > 0, 'Noise power should be positive');
    
    fprintf('  ✓ PASS\n');
end

%% Test calculate_snr - Multi-channel
function test_calculate_snr_multichannel()
    fprintf('Test: calculate_snr - Multi-channel\n');
    
    % Generate multi-channel test signal
    fs = 4800;
    t = 0:1/fs:10-1/fs;
    target_freq = 17;
    n_channels = 3;
    signal = zeros(n_channels, length(t));
    for ch = 1:n_channels
        signal(ch, :) = sin(2*pi*target_freq*t) + 0.1*randn(size(t));
    end
    
    % Calculate SNR
    [snr_db, signal_power, noise_power] = calculate_snr(signal, fs, target_freq);
    
    % Verify outputs
    assert(length(snr_db) == n_channels, 'SNR should be vector for multi-channel');
    assert(length(signal_power) == n_channels, 'Signal power should be vector');
    assert(length(noise_power) == n_channels, 'Noise power should be vector');
    
    % Verify all SNRs are positive
    assert(all(snr_db > 0), 'All SNRs should be positive');
    
    % Verify all signal powers > noise powers
    assert(all(signal_power > noise_power), 'All signal powers should exceed noise powers');
    
    fprintf('  ✓ PASS\n');
end

%% Test detect_peak_at_frequency - Basic functionality
function test_detect_peak_basic()
    fprintf('Test: detect_peak_at_frequency - Basic functionality\n');
    
    % Generate test signal with 17Hz component
    fs = 4800;
    t = 0:1/fs:10-1/fs;
    target_freq = 17;
    signal = sin(2*pi*target_freq*t) + 0.1*randn(size(t));
    
    % Detect peak
    [peak_detected, peak_freq, peak_power, peak_idx] = ...
        detect_peak_at_frequency(signal, fs, target_freq);
    
    % Verify outputs
    assert(islogical(peak_detected), 'peak_detected should be logical');
    assert(peak_detected, 'Peak should be detected');
    
    % Verify peak frequency is close to target
    assert(abs(peak_freq - target_freq) <= 0.5, ...
        'Peak frequency should be within ±0.5Hz of target');
    
    % Verify peak power is positive
    assert(peak_power > 0, 'Peak power should be positive');
    
    % Verify peak index is valid
    assert(peak_idx > 0 && peak_idx <= 4097, 'Peak index should be valid');
    
    fprintf('  ✓ PASS\n');
end

%% Test detect_peak_at_frequency - No peak present
function test_detect_peak_no_peak()
    fprintf('Test: detect_peak_at_frequency - No peak present\n');
    
    % Generate test signal without 17Hz component
    fs = 4800;
    t = 0:1/fs:10-1/fs;
    target_freq = 17;
    signal = sin(2*pi*50*t) + 0.1*randn(size(t));  % 50Hz, not 17Hz
    
    % Detect peak
    [peak_detected, peak_freq, peak_power, peak_idx] = ...
        detect_peak_at_frequency(signal, fs, target_freq);
    
    % Verify no peak detected
    assert(~peak_detected, 'No peak should be detected');
    
    % Verify outputs are NaN when no peak
    assert(isnan(peak_freq), 'Peak frequency should be NaN when no peak');
    assert(isnan(peak_power), 'Peak power should be NaN when no peak');
    assert(isnan(peak_idx), 'Peak index should be NaN when no peak');
    
    fprintf('  ✓ PASS\n');
end

%% Test detect_peak_at_frequency - Multi-channel
function test_detect_peak_multichannel()
    fprintf('Test: detect_peak_at_frequency - Multi-channel\n');
    
    % Generate multi-channel test signal
    fs = 4800;
    t = 0:1/fs:10-1/fs;
    target_freq = 17;
    n_channels = 3;
    signal = zeros(n_channels, length(t));
    for ch = 1:n_channels
        signal(ch, :) = sin(2*pi*target_freq*t) + 0.1*randn(size(t));
    end
    
    % Detect peaks
    [peak_detected, peak_freq, peak_power, peak_idx] = ...
        detect_peak_at_frequency(signal, fs, target_freq);
    
    % Verify outputs
    assert(length(peak_detected) == n_channels, 'peak_detected should be vector');
    assert(all(peak_detected), 'All channels should detect peaks');
    
    % Verify all peak frequencies are close to target
    assert(all(abs(peak_freq - target_freq) <= 0.5), ...
        'All peak frequencies should be within ±0.5Hz of target');
    
    % Verify all peak powers are positive
    assert(all(peak_power > 0), 'All peak powers should be positive');
    
    fprintf('  ✓ PASS\n');
end

%% Test detect_triggers - Basic functionality
function test_detect_triggers_basic()
    fprintf('Test: detect_triggers - Basic functionality\n');
    
    % Generate test trigger signal
    fs = 4800;
    duration = 5;
    n_samples = duration * fs;
    trigger_signal = zeros(1, n_samples);
    
    % Create triggers at known times
    trigger_times = [1.0, 2.0, 3.0, 4.0];  % seconds
    for i = 1:length(trigger_times)
        idx = round(trigger_times(i) * fs);
        trigger_signal(idx:min(idx+100, n_samples)) = 5.0;
    end
    
    % Detect triggers
    threshold = 2.5;
    min_interval = round(0.5 * fs);
    detected_indices = detect_triggers(trigger_signal, threshold, min_interval);
    
    % Verify correct number detected
    assert(length(detected_indices) == length(trigger_times), ...
        'Should detect correct number of triggers');
    
    % Verify timing accuracy (within 5 samples)
    detected_times = detected_indices / fs;
    max_error = max(abs(detected_times - trigger_times));
    assert(max_error < 5/fs, 'Trigger timing should be accurate within 5 samples');
    
    fprintf('  ✓ PASS\n');
end

%% Test detect_triggers - Minimum interval constraint
function test_detect_triggers_min_interval()
    fprintf('Test: detect_triggers - Minimum interval constraint\n');
    
    % Generate test trigger signal with closely spaced triggers
    fs = 4800;
    duration = 5;
    n_samples = duration * fs;
    trigger_signal = zeros(1, n_samples);
    
    % Create triggers closer than minimum interval
    trigger_times = [1.0, 1.1, 1.2, 2.0, 2.05];  % seconds
    for i = 1:length(trigger_times)
        idx = round(trigger_times(i) * fs);
        trigger_signal(idx:min(idx+50, n_samples)) = 5.0;
    end
    
    % Detect triggers with 0.5s minimum interval
    threshold = 2.5;
    min_interval = round(0.5 * fs);
    detected_indices = detect_triggers(trigger_signal, threshold, min_interval);
    
    % Should only detect 2 triggers (1.0 and 2.0)
    assert(length(detected_indices) == 2, ...
        'Should filter out triggers within minimum interval');
    
    % Verify detected times
    detected_times = detected_indices / fs;
    assert(abs(detected_times(1) - 1.0) < 0.01, 'First trigger should be at 1.0s');
    assert(abs(detected_times(2) - 2.0) < 0.01, 'Second trigger should be at 2.0s');
    
    fprintf('  ✓ PASS\n');
end

%% Test extract_epochs - Basic functionality
function test_extract_epochs_basic()
    fprintf('Test: extract_epochs - Basic functionality\n');
    
    % Generate test data
    fs = 4800;
    n_channels = 4;
    duration = 10;
    n_samples = duration * fs;
    data = randn(n_channels, n_samples) * 0.1;
    
    % Create trigger indices
    trigger_indices = [fs*2, fs*4, fs*6, fs*8];  % At 2, 4, 6, 8 seconds
    
    % Extract epochs
    pre_time = 0.2;
    post_time = 1.3;
    [trials, trial_times] = extract_epochs(data, trigger_indices, fs, pre_time, post_time);
    
    % Verify dimensions
    expected_samples = round((pre_time + post_time) * fs) + 1;
    assert(size(trials, 1) == n_channels, 'Should have correct number of channels');
    assert(size(trials, 2) == expected_samples, 'Should have correct samples per trial');
    assert(size(trials, 3) == length(trigger_indices), 'Should have correct number of trials');
    
    % Verify time axis
    assert(abs(trial_times(1) - (-pre_time)) < 1e-6, 'Time axis should start at -pre_time');
    assert(abs(trial_times(end) - post_time) < 1e-6, 'Time axis should end at post_time');
    assert(length(trial_times) == expected_samples, 'Time axis should match trial length');
    
    fprintf('  ✓ PASS\n');
end

%% Test extract_epochs - Boundary handling
function test_extract_epochs_boundary()
    fprintf('Test: extract_epochs - Boundary handling\n');
    
    % Generate test data
    fs = 4800;
    n_channels = 2;
    duration = 5;
    n_samples = duration * fs;
    data = randn(n_channels, n_samples) * 0.1;
    
    % Create trigger indices including some near boundaries
    trigger_indices = [100, fs*2, n_samples-100];  % Too early, good, too late
    
    % Extract epochs
    pre_time = 0.5;
    post_time = 1.0;
    [trials, trial_times] = extract_epochs(data, trigger_indices, fs, pre_time, post_time);
    
    % Should only extract the middle trigger (others too close to edges)
    assert(size(trials, 3) == 1, 'Should skip triggers near boundaries');
    
    fprintf('  ✓ PASS\n');
end

%% Test compute_grand_average - Basic functionality
function test_compute_grand_average_basic()
    fprintf('Test: compute_grand_average - Basic functionality\n');
    
    % Generate test trials
    n_channels = 3;
    n_samples = 1000;
    n_trials = 10;
    trials = randn(n_channels, n_samples, n_trials);
    
    % Compute grand average
    grand_avg = compute_grand_average(trials);
    
    % Verify dimensions
    assert(size(grand_avg, 1) == n_channels, 'Should have correct number of channels');
    assert(size(grand_avg, 2) == n_samples, 'Should have correct number of samples');
    
    % Verify it's the mean
    manual_mean = mean(trials, 3);
    max_diff = max(abs(grand_avg(:) - manual_mean(:)));
    assert(max_diff < 1e-10, 'Grand average should equal mean across trials');
    
    % Verify each time point is averaged correctly
    for ch = 1:n_channels
        for t = 1:n_samples
            expected = mean(squeeze(trials(ch, t, :)));
            assert(abs(grand_avg(ch, t) - expected) < 1e-10, ...
                'Each time point should be averaged correctly');
        end
    end
    
    fprintf('  ✓ PASS\n');
end
