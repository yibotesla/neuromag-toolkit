% TEST_TRIGGER_EPOCHING - Test trigger detection, epoching, and grand average
%
% This script tests the basic functionality of:
% - detect_triggers.m
% - extract_epochs.m
% - compute_grand_average.m

clear; clc;

fprintf('=== Testing Trigger Detection, Epoching, and Grand Average ===\n\n');

%% Test 1: Trigger Detection
fprintf('Test 1: Trigger Detection\n');
fprintf('---------------------------\n');

% Create synthetic trigger signal
fs = 4800;  % Hz
duration = 10;  % seconds
t = 0:1/fs:duration-1/fs;
n_samples = length(t);

% Create trigger signal with known trigger times
trigger_times = [1.0, 2.5, 4.0, 6.0, 8.5];  % seconds
trigger_signal = zeros(1, n_samples);

for i = 1:length(trigger_times)
    trigger_idx = round(trigger_times(i) * fs);
    % Create a pulse lasting 50ms
    pulse_duration = round(0.05 * fs);
    trigger_signal(trigger_idx:min(trigger_idx+pulse_duration, n_samples)) = 5.0;
end

% Detect triggers
threshold = 2.5;
min_interval = round(0.5 * fs);  % 500ms minimum interval
detected_indices = detect_triggers(trigger_signal, threshold, min_interval);

% Convert to times
detected_times = detected_indices / fs;

fprintf('Expected trigger times: ');
fprintf('%.2f ', trigger_times);
fprintf('\n');
fprintf('Detected trigger times: ');
fprintf('%.2f ', detected_times);
fprintf('\n');
fprintf('Number of triggers detected: %d (expected: %d)\n', ...
    length(detected_indices), length(trigger_times));

% Check accuracy
if length(detected_indices) == length(trigger_times)
    max_error = max(abs(detected_times - trigger_times));
    fprintf('Maximum timing error: %.4f seconds (%.1f samples)\n', ...
        max_error, max_error * fs);
    if max_error < 0.01  % Less than 10ms error
        fprintf('✓ Trigger detection PASSED\n');
    else
        fprintf('✗ Trigger detection timing error too large\n');
    end
else
    fprintf('✗ Trigger detection count mismatch\n');
end

fprintf('\n');

%% Test 2: Epoch Extraction
fprintf('Test 2: Epoch Extraction\n');
fprintf('------------------------\n');

% Create synthetic multi-channel data with known responses
n_channels = 4;
data = randn(n_channels, n_samples) * 0.1;  % Background noise

% Add evoked responses at each trigger
response_duration = 1.0;  % seconds
response_samples = round(response_duration * fs);
response_template = sin(2*pi*10*(0:response_samples-1)/fs) .* ...
    exp(-(0:response_samples-1)/(0.3*fs));  % 10Hz damped sinusoid

for i = 1:length(trigger_times)
    trigger_idx = round(trigger_times(i) * fs);
    end_idx = min(trigger_idx + response_samples - 1, n_samples);
    actual_samples = end_idx - trigger_idx + 1;
    
    % Add response to all channels (with different amplitudes)
    for ch = 1:n_channels
        data(ch, trigger_idx:end_idx) = data(ch, trigger_idx:end_idx) + ...
            (ch * 0.5) * response_template(1:actual_samples);
    end
end

% Extract epochs
pre_time = 0.2;   % 200ms before trigger
post_time = 1.3;  % 1300ms after trigger
[trials, trial_times] = extract_epochs(data, detected_indices, fs, pre_time, post_time);

fprintf('Data dimensions: %d channels × %d samples\n', n_channels, n_samples);
fprintf('Number of triggers: %d\n', length(detected_indices));
fprintf('Epoch parameters: %.2fs pre, %.2fs post\n', pre_time, post_time);
fprintf('Expected epoch duration: %.2fs\n', pre_time + post_time);
fprintf('Trials dimensions: %d channels × %d samples × %d trials\n', ...
    size(trials, 1), size(trials, 2), size(trials, 3));
fprintf('Trial time axis: %.3f to %.3f seconds\n', ...
    trial_times(1), trial_times(end));

% Verify dimensions
expected_samples = round((pre_time + post_time) * fs) + 1;
if size(trials, 1) == n_channels && ...
   size(trials, 2) == expected_samples && ...
   size(trials, 3) == length(detected_indices)
    fprintf('✓ Epoch extraction dimensions PASSED\n');
else
    fprintf('✗ Epoch extraction dimensions FAILED\n');
end

% Verify time axis
if abs(trial_times(1) - (-pre_time)) < 1e-6 && ...
   abs(trial_times(end) - post_time) < 1e-6
    fprintf('✓ Time axis alignment PASSED\n');
else
    fprintf('✗ Time axis alignment FAILED\n');
end

fprintf('\n');

%% Test 3: Grand Average
fprintf('Test 3: Grand Average Computation\n');
fprintf('----------------------------------\n');

% Compute grand average
grand_avg = compute_grand_average(trials);

fprintf('Grand average dimensions: %d channels × %d samples\n', ...
    size(grand_avg, 1), size(grand_avg, 2));

% Verify dimensions
if size(grand_avg, 1) == n_channels && size(grand_avg, 2) == size(trials, 2)
    fprintf('✓ Grand average dimensions PASSED\n');
else
    fprintf('✗ Grand average dimensions FAILED\n');
end

% Verify it's actually the mean
manual_mean = mean(trials, 3);
max_diff = max(abs(grand_avg(:) - manual_mean(:)));
fprintf('Maximum difference from manual mean: %.2e\n', max_diff);

if max_diff < 1e-10
    fprintf('✓ Grand average calculation PASSED\n');
else
    fprintf('✗ Grand average calculation FAILED\n');
end

fprintf('\n');

%% Test 4: Visualization
fprintf('Test 4: Visualization\n');
fprintf('---------------------\n');

figure('Name', 'Trigger Detection and Epoching Test', 'Position', [100, 100, 1200, 800]);

% Plot 1: Trigger signal
subplot(3, 2, 1);
plot(t, trigger_signal, 'b-', 'LineWidth', 1);
hold on;
plot(detected_times, threshold * ones(size(detected_times)), 'ro', ...
    'MarkerSize', 10, 'LineWidth', 2);
yline(threshold, 'r--', 'Threshold');
xlabel('Time (s)');
ylabel('Amplitude');
title('Trigger Signal Detection');
legend('Trigger Signal', 'Detected Triggers', 'Location', 'best');
grid on;

% Plot 2: Raw data with triggers
subplot(3, 2, 2);
plot(t, data(1, :), 'k-', 'LineWidth', 0.5);
hold on;
for i = 1:length(detected_times)
    xline(detected_times(i), 'r--', 'LineWidth', 1.5);
end
xlabel('Time (s)');
ylabel('Amplitude');
title('Raw Data (Channel 1) with Triggers');
grid on;

% Plot 3: Individual trials
subplot(3, 2, 3);
for i = 1:size(trials, 3)
    plot(trial_times, squeeze(trials(1, :, i)), 'Color', [0.7, 0.7, 0.7]);
    hold on;
end
xline(0, 'r--', 'Trigger', 'LineWidth', 2);
xlabel('Time relative to trigger (s)');
ylabel('Amplitude');
title(sprintf('Individual Trials (Channel 1, N=%d)', size(trials, 3)));
grid on;

% Plot 4: Grand average
subplot(3, 2, 4);
plot(trial_times, grand_avg(1, :), 'b-', 'LineWidth', 2);
hold on;
xline(0, 'r--', 'Trigger', 'LineWidth', 2);
xlabel('Time relative to trigger (s)');
ylabel('Amplitude');
title('Grand Average (Channel 1)');
grid on;

% Plot 5: All channels grand average
subplot(3, 2, 5:6);
for ch = 1:n_channels
    plot(trial_times, grand_avg(ch, :) + (ch-1)*2, 'LineWidth', 1.5);
    hold on;
end
xline(0, 'r--', 'Trigger', 'LineWidth', 2);
xlabel('Time relative to trigger (s)');
ylabel('Amplitude (offset for display)');
title('Grand Average - All Channels');
legend(arrayfun(@(x) sprintf('Ch %d', x), 1:n_channels, 'UniformOutput', false), ...
    'Location', 'best');
grid on;

fprintf('✓ Visualization complete\n');
fprintf('\n');

%% Summary
fprintf('=== Test Summary ===\n');
fprintf('All basic functionality tests completed.\n');
fprintf('Functions tested:\n');
fprintf('  - detect_triggers.m\n');
fprintf('  - extract_epochs.m\n');
fprintf('  - compute_grand_average.m\n');
fprintf('\nRequirements validated: 5.3, 5.4, 5.5, 6.1\n');
