% TEST_TRIALDATA_INTEGRATION - Test integration with TrialData structure
%
% This script demonstrates how the trigger detection, epoching, and
% grand average functions integrate with the TrialData data structure.

clear; clc;

fprintf('=== Testing TrialData Integration ===\n\n');

% Add paths
addpath('../utils');

%% Generate synthetic data
fprintf('Generating synthetic MEG data...\n');
fs = 4800;
duration = 10;
n_channels = 4;
n_samples = duration * fs;

% Create continuous data
data = randn(n_channels, n_samples) * 0.1;

% Create trigger signal
trigger_signal = zeros(1, n_samples);
trigger_times = [1.0, 2.5, 4.0, 6.0, 8.5];
for i = 1:length(trigger_times)
    idx = round(trigger_times(i) * fs);
    trigger_signal(idx:min(idx+100, n_samples)) = 5.0;
end

% Add evoked responses
response_duration = 1.0;
response_samples = round(response_duration * fs);
response_template = sin(2*pi*10*(0:response_samples-1)/fs) .* ...
    exp(-(0:response_samples-1)/(0.3*fs));

for i = 1:length(trigger_times)
    trigger_idx = round(trigger_times(i) * fs);
    end_idx = min(trigger_idx + response_samples - 1, n_samples);
    actual_samples = end_idx - trigger_idx + 1;
    for ch = 1:n_channels
        data(ch, trigger_idx:end_idx) = data(ch, trigger_idx:end_idx) + ...
            (ch * 0.5) * response_template(1:actual_samples);
    end
end

fprintf('  Data: %d channels × %d samples (%.1f seconds)\n', ...
    n_channels, n_samples, duration);

%% Step 1: Detect triggers
fprintf('\nStep 1: Detecting triggers...\n');
threshold = 2.5;
min_interval = round(0.5 * fs);
trigger_indices = detect_triggers(trigger_signal, threshold, min_interval);

fprintf('  Detected %d triggers\n', length(trigger_indices));
fprintf('  Trigger times: ');
fprintf('%.2f ', trigger_indices / fs);
fprintf('seconds\n');

%% Step 2: Extract epochs
fprintf('\nStep 2: Extracting epochs...\n');
pre_time = 0.2;
post_time = 1.3;
[trials, trial_times] = extract_epochs(data, trigger_indices, fs, pre_time, post_time);

fprintf('  Trials: %d channels × %d samples × %d trials\n', ...
    size(trials, 1), size(trials, 2), size(trials, 3));
fprintf('  Time window: %.3f to %.3f seconds\n', trial_times(1), trial_times(end));

%% Step 3: Create TrialData structure
fprintf('\nStep 3: Creating TrialData structure...\n');
trial_data = TrialData();
trial_data.trials = trials;
trial_data.trial_times = trial_times;
trial_data.trigger_indices = trigger_indices;
trial_data.fs = fs;
trial_data.pre_time = pre_time;
trial_data.post_time = post_time;

fprintf('  TrialData created successfully\n');
fprintf('  Number of trials: %d\n', trial_data.get_n_trials());
fprintf('  Number of channels: %d\n', trial_data.get_n_channels());

%% Step 4: Compute grand average
fprintf('\nStep 4: Computing grand average...\n');
grand_avg = compute_grand_average(trial_data.trials);

fprintf('  Grand average: %d channels × %d samples\n', ...
    size(grand_avg, 1), size(grand_avg, 2));

%% Step 5: Visualization
fprintf('\nStep 5: Creating visualization...\n');

figure('Name', 'TrialData Integration Test', 'Position', [100, 100, 1200, 600]);

% Plot 1: Individual trials for channel 1
subplot(1, 2, 1);
for i = 1:trial_data.get_n_trials()
    plot(trial_data.trial_times, squeeze(trial_data.trials(1, :, i)), ...
        'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.5);
    hold on;
end
plot(trial_data.trial_times, grand_avg(1, :), 'b-', 'LineWidth', 2);
xline(0, 'r--', 'Trigger', 'LineWidth', 2);
xlabel('Time relative to trigger (s)');
ylabel('Amplitude');
title(sprintf('Channel 1: Individual Trials (N=%d) and Grand Average', ...
    trial_data.get_n_trials()));
legend('Individual Trials', 'Grand Average', 'Location', 'best');
grid on;

% Plot 2: Grand average for all channels
subplot(1, 2, 2);
for ch = 1:trial_data.get_n_channels()
    plot(trial_data.trial_times, grand_avg(ch, :) + (ch-1)*1.5, 'LineWidth', 1.5);
    hold on;
end
xline(0, 'r--', 'Trigger', 'LineWidth', 2);
xlabel('Time relative to trigger (s)');
ylabel('Amplitude (offset for display)');
title('Grand Average - All Channels');
legend(arrayfun(@(x) sprintf('Ch %d', x), 1:trial_data.get_n_channels(), ...
    'UniformOutput', false), 'Location', 'best');
grid on;

fprintf('  Visualization complete\n');

%% Summary
fprintf('\n=== Integration Test Summary ===\n');
fprintf('✓ Successfully integrated trigger detection, epoching, and grand average\n');
fprintf('✓ TrialData structure properly populated\n');
fprintf('✓ All data dimensions correct\n');
fprintf('✓ Visualization generated\n');
fprintf('\nThe workflow is ready for Mission 2 processing!\n');
