% TEST_CONVERGENCE_WITH_TRIALDATA - Test convergence analysis with TrialData structure
%
% This test verifies that convergence analysis functions work correctly
% with the TrialData class structure used in the MEG processing pipeline.

clear; clc;

% Add utils to path
addpath('../utils');

fprintf('=== Testing Convergence Analysis with TrialData Structure ===\n\n');

%% Setup: Create TrialData structure
fprintf('Setup: Creating TrialData structure...\n');

% Create synthetic data
fs = 4800;
n_channels = 64;
n_trials = 50;
pre_time = 0.2;
post_time = 1.3;
n_samples_per_trial = round((pre_time + post_time) * fs);

% Generate trials
rng(123);
trial_times = linspace(-pre_time, post_time, n_samples_per_trial);
trials = randn(n_channels, n_samples_per_trial, n_trials);

% Add a consistent evoked response
for i = 1:n_trials
    signal = sin(2*pi*10*trial_times);  % 10 Hz signal
    trials(:, :, i) = trials(:, :, i) + repmat(signal, n_channels, 1);
end

% Create TrialData object
trial_data = TrialData();
trial_data.trials = trials;
trial_data.trial_times = trial_times;
trial_data.trigger_indices = 1:n_trials;
trial_data.fs = fs;
trial_data.pre_time = pre_time;
trial_data.post_time = post_time;

fprintf('  ✓ TrialData structure created\n');
fprintf('    Channels: %d\n', trial_data.get_n_channels());
fprintf('    Trials: %d\n', trial_data.get_n_trials());

%% Test 1: Grand average with TrialData
fprintf('\nTest 1: Computing grand average from TrialData...\n');

grand_avg = compute_grand_average(trial_data.trials);
assert(size(grand_avg, 1) == n_channels, 'Channel count mismatch');
assert(size(grand_avg, 2) == n_samples_per_trial, 'Sample count mismatch');
fprintf('  ✓ Grand average computed successfully\n');

%% Test 2: Sample trials from TrialData
fprintf('\nTest 2: Sampling trials from TrialData...\n');

n_sample = 20;
sampled_avg = sample_trials(trial_data.trials, n_sample);
assert(size(sampled_avg, 1) == n_channels, 'Channel count mismatch');
assert(size(sampled_avg, 2) == n_samples_per_trial, 'Sample count mismatch');
fprintf('  ✓ Sampled average computed successfully\n');

%% Test 3: Compute convergence metrics
fprintf('\nTest 3: Computing convergence metrics...\n');

metrics = compute_convergence_metrics(sampled_avg, grand_avg);
assert(isfield(metrics, 'correlation'), 'Missing correlation field');
assert(isfield(metrics, 'rmse'), 'Missing rmse field');
assert(metrics.correlation >= -1 && metrics.correlation <= 1, 'Invalid correlation');
assert(metrics.rmse >= 0, 'Invalid RMSE');
fprintf('  ✓ Metrics computed: correlation=%.3f, RMSE=%.6f\n', ...
    metrics.correlation, metrics.rmse);

%% Test 4: Determine minimum trials
fprintf('\nTest 4: Determining minimum trials...\n');

trial_counts = [10, 20, 30, 40, 50];
[min_trials, conv_data] = determine_minimum_trials(trial_data.trials, 0.9, trial_counts, 5);
assert(min_trials > 0, 'Invalid minimum trials');
assert(min_trials <= n_trials, 'Minimum trials exceeds available trials');
fprintf('  ✓ Minimum trials determined: %d\n', min_trials);

%% Test 5: Verify convergence data structure
fprintf('\nTest 5: Verifying convergence data structure...\n');

assert(isequal(conv_data.n_trials, trial_counts), 'Trial counts mismatch');
assert(length(conv_data.correlation) == length(trial_counts), 'Length mismatch');
assert(all(conv_data.correlation >= -1 & conv_data.correlation <= 1), 'Invalid correlations');
assert(all(conv_data.rmse >= 0), 'Invalid RMSE values');
fprintf('  ✓ Convergence data structure valid\n');

%% Test 6: Integration with AnalysisResults
fprintf('\nTest 6: Integration with AnalysisResults structure...\n');

% Create AnalysisResults object
results = AnalysisResults();
results.grand_average = grand_avg;
results = results.set_convergence(conv_data.n_trials, conv_data.correlation);

assert(~isempty(results.grand_average), 'Grand average not stored');
assert(isequal(results.convergence.n_trials, conv_data.n_trials), 'Trial counts not stored');
assert(isequal(results.convergence.correlation, conv_data.correlation), 'Correlations not stored');
fprintf('  ✓ AnalysisResults integration successful\n');

%% Test 7: Complete workflow simulation
fprintf('\nTest 7: Simulating complete workflow...\n');

% Simulate Mission 2 workflow
fprintf('  Step 1: Extract epochs (simulated - already have trials)\n');
fprintf('  Step 2: Compute grand average\n');
workflow_grand_avg = compute_grand_average(trial_data.trials);

fprintf('  Step 3: Perform convergence analysis\n');
[workflow_min_trials, workflow_conv_data] = determine_minimum_trials(...
    trial_data.trials, 0.9, 10:10:50, 5);

fprintf('  Step 4: Store results\n');
workflow_results = AnalysisResults();
workflow_results.grand_average = workflow_grand_avg;
workflow_results = workflow_results.set_convergence(...
    workflow_conv_data.n_trials, workflow_conv_data.correlation);

fprintf('  ✓ Complete workflow executed successfully\n');
fprintf('    Minimum trials needed: %d out of %d\n', workflow_min_trials, n_trials);

%% Test 8: Verify with different channel subsets
fprintf('\nTest 8: Testing with channel subsets...\n');

% Test with single channel
single_channel_trials = trial_data.trials(1, :, :);
single_grand_avg = compute_grand_average(single_channel_trials);
assert(size(single_grand_avg, 1) == 1, 'Single channel test failed');
fprintf('  ✓ Single channel processing works\n');

% Test with subset of channels
subset_channels = trial_data.trials(1:10, :, :);
subset_grand_avg = compute_grand_average(subset_channels);
assert(size(subset_grand_avg, 1) == 10, 'Channel subset test failed');
fprintf('  ✓ Channel subset processing works\n');

%% Summary
fprintf('\n=== All Integration Tests Passed! ===\n');
fprintf('\nSummary:\n');
fprintf('  - TrialData structure compatibility: ✓\n');
fprintf('  - Grand average computation: ✓\n');
fprintf('  - Trial sampling: ✓\n');
fprintf('  - Convergence metrics: ✓\n');
fprintf('  - Minimum trial determination: ✓\n');
fprintf('  - AnalysisResults integration: ✓\n');
fprintf('  - Complete workflow: ✓\n');
fprintf('  - Channel subset handling: ✓\n');
fprintf('\nConvergence analysis is ready for Mission 2 integration!\n');
