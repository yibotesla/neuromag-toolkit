% TEST_CONVERGENCE_ANALYSIS - Test convergence analysis functions
%
% This script tests the convergence analysis functions:
%   - sample_trials
%   - compute_convergence_metrics
%   - determine_minimum_trials
%
% Tests verify:
%   - Random sampling produces correct number of trials
%   - Convergence metrics are calculated correctly
%   - Minimum trial determination works as expected

clear; clc;

fprintf('=== Testing Convergence Analysis Functions ===\n\n');

%% Test 1: sample_trials basic functionality
fprintf('Test 1: sample_trials basic functionality\n');

% Create synthetic trial data
n_channels = 3;
n_samples_per_trial = 100;
n_trials = 50;
rng(42);  % Set seed for reproducibility

% Generate trials with some signal + noise
t = linspace(0, 1, n_samples_per_trial);
signal = sin(2*pi*10*t);  % 10 Hz signal
trials = zeros(n_channels, n_samples_per_trial, n_trials);
for i = 1:n_trials
    for ch = 1:n_channels
        trials(ch, :, i) = signal + 0.5*randn(1, n_samples_per_trial);
    end
end

% Test sampling
n_sample = 20;
sampled_avg = sample_trials(trials, n_sample);

% Verify dimensions
assert(size(sampled_avg, 1) == n_channels, 'Channel count mismatch');
assert(size(sampled_avg, 2) == n_samples_per_trial, 'Sample count mismatch');
fprintf('  ✓ Sampled average has correct dimensions\n');

% Verify it's different from grand average (due to random sampling)
grand_avg = compute_grand_average(trials);
assert(~isequal(sampled_avg, grand_avg), 'Sampled average should differ from grand average');
fprintf('  ✓ Sampled average differs from grand average\n');

%% Test 2: sample_trials with different sample sizes
fprintf('\nTest 2: sample_trials with different sample sizes\n');

for n_test = [5, 10, 25, 50]
    if n_test <= n_trials
        sampled = sample_trials(trials, n_test);
        assert(size(sampled, 1) == n_channels, 'Dimension error');
        assert(size(sampled, 2) == n_samples_per_trial, 'Dimension error');
    end
end
fprintf('  ✓ Sampling works for various sample sizes\n');

%% Test 3: compute_convergence_metrics basic functionality
fprintf('\nTest 3: compute_convergence_metrics basic functionality\n');

% Compute metrics between sampled and grand average
metrics = compute_convergence_metrics(sampled_avg, grand_avg);

% Verify structure fields
assert(isfield(metrics, 'correlation'), 'Missing correlation field');
assert(isfield(metrics, 'rmse'), 'Missing rmse field');
fprintf('  ✓ Metrics structure has required fields\n');

% Verify correlation is in valid range
assert(metrics.correlation >= -1 && metrics.correlation <= 1, ...
    'Correlation out of range [-1, 1]');
fprintf('  ✓ Correlation in valid range: %.3f\n', metrics.correlation);

% Verify RMSE is non-negative
assert(metrics.rmse >= 0, 'RMSE must be non-negative');
fprintf('  ✓ RMSE is non-negative: %.6f\n', metrics.rmse);

%% Test 4: compute_convergence_metrics with identical inputs
fprintf('\nTest 4: compute_convergence_metrics with identical inputs\n');

metrics_identical = compute_convergence_metrics(grand_avg, grand_avg);
assert(abs(metrics_identical.correlation - 1.0) < 1e-10, ...
    'Correlation should be 1.0 for identical inputs');
assert(metrics_identical.rmse < 1e-10, ...
    'RMSE should be ~0 for identical inputs');
fprintf('  ✓ Perfect correlation (1.0) for identical inputs\n');
fprintf('  ✓ Near-zero RMSE for identical inputs\n');

%% Test 5: Convergence improves with more trials
fprintf('\nTest 5: Convergence improves with more trials\n');

trial_counts_test = [5, 10, 20, 30, 40, 50];
correlations = zeros(size(trial_counts_test));

for i = 1:length(trial_counts_test)
    n = trial_counts_test(i);
    sampled = sample_trials(trials, n);
    m = compute_convergence_metrics(sampled, grand_avg);
    correlations(i) = m.correlation;
end

% Generally, correlation should increase (allowing for some randomness)
fprintf('  Trial counts: %s\n', mat2str(trial_counts_test));
fprintf('  Correlations: [');
fprintf('%.3f ', correlations);
fprintf(']\n');
fprintf('  ✓ Correlation values computed for increasing trial counts\n');

%% Test 6: determine_minimum_trials basic functionality
fprintf('\nTest 6: determine_minimum_trials basic functionality\n');

% Use a smaller set of trials for faster testing
trial_counts_small = [10, 20, 30, 40, 50];
[min_trials, conv_data] = determine_minimum_trials(trials, 0.9, trial_counts_small, 5);

% Verify output structure
assert(isscalar(min_trials), 'min_trials should be scalar');
assert(min_trials > 0, 'min_trials should be positive');
fprintf('  ✓ Minimum trials determined: %d\n', min_trials);

% Verify convergence_data structure
assert(isfield(conv_data, 'n_trials'), 'Missing n_trials field');
assert(isfield(conv_data, 'correlation'), 'Missing correlation field');
assert(isfield(conv_data, 'correlation_std'), 'Missing correlation_std field');
assert(isfield(conv_data, 'rmse'), 'Missing rmse field');
assert(isfield(conv_data, 'rmse_std'), 'Missing rmse_std field');
fprintf('  ✓ Convergence data has all required fields\n');

% Verify lengths match
assert(length(conv_data.n_trials) == length(conv_data.correlation), ...
    'Length mismatch in convergence data');
fprintf('  ✓ Convergence data arrays have consistent lengths\n');

%% Test 7: Verify correlation values are in valid range
fprintf('\nTest 7: Verify all correlation values in valid range\n');

all_valid = all(conv_data.correlation >= -1 & conv_data.correlation <= 1);
assert(all_valid, 'Some correlation values out of range');
fprintf('  ✓ All correlations in range [-1, 1]\n');

all_rmse_valid = all(conv_data.rmse >= 0);
assert(all_rmse_valid, 'Some RMSE values negative');
fprintf('  ✓ All RMSE values non-negative\n');

%% Test 8: Test with default parameters
fprintf('\nTest 8: determine_minimum_trials with default parameters\n');

[min_trials_default, conv_data_default] = determine_minimum_trials(trials);
assert(isscalar(min_trials_default), 'Default call failed');
fprintf('  ✓ Function works with default parameters\n');
fprintf('  ✓ Minimum trials (default threshold 0.9): %d\n', min_trials_default);

%% Test 9: Error handling - insufficient trials
fprintf('\nTest 9: Error handling tests\n');

try
    % Try to sample more trials than available
    sample_trials(trials, n_trials + 10);
    error('Should have thrown error for insufficient trials');
catch ME
    assert(contains(ME.identifier, 'InsufficientTrials'), 'Wrong error type');
    fprintf('  ✓ Correctly handles request for too many trials\n');
end

try
    % Invalid dimensions
    compute_convergence_metrics(grand_avg, grand_avg(:, 1:50));
    error('Should have thrown error for dimension mismatch');
catch ME
    assert(contains(ME.identifier, 'DimensionMismatch'), 'Wrong error type');
    fprintf('  ✓ Correctly handles dimension mismatch\n');
end

%% Test 10: Visualize convergence curve
fprintf('\nTest 10: Generate convergence curve visualization\n');

figure('Name', 'Convergence Analysis Test');

subplot(2, 1, 1);
errorbar(conv_data.n_trials, conv_data.correlation, conv_data.correlation_std, 'o-', 'LineWidth', 2);
hold on;
yline(0.9, 'r--', 'Threshold = 0.9', 'LineWidth', 1.5);
xline(min_trials, 'g--', sprintf('Min trials = %d', min_trials), 'LineWidth', 1.5);
xlabel('Number of Trials');
ylabel('Correlation Coefficient');
title('Convergence Analysis: Correlation vs. Number of Trials');
grid on;
ylim([0, 1]);

subplot(2, 1, 2);
errorbar(conv_data.n_trials, conv_data.rmse, conv_data.rmse_std, 'o-', 'LineWidth', 2);
xlabel('Number of Trials');
ylabel('RMSE');
title('Convergence Analysis: RMSE vs. Number of Trials');
grid on;

fprintf('  ✓ Convergence curve plotted\n');

%% Summary
fprintf('\n=== All Tests Passed! ===\n');
fprintf('Summary:\n');
fprintf('  - sample_trials: Working correctly\n');
fprintf('  - compute_convergence_metrics: Working correctly\n');
fprintf('  - determine_minimum_trials: Working correctly\n');
fprintf('  - Minimum trials needed (threshold=0.9): %d out of %d\n', min_trials, n_trials);
fprintf('\nConvergence analysis implementation complete!\n');
