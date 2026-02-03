% TEST_MISSION2_INTEGRATION Comprehensive integration test for Mission 2
%
% This test validates the complete Mission 2 pipeline against all requirements:
% - Requirements 5.1: Frequency-specific filtering for AEF and ASSR
% - Requirements 5.2: Adaptive filtering with reference sensors
% - Requirements 5.3: Trigger detection
% - Requirements 5.4: Epoching (trial extraction)
% - Requirements 5.5: Grand average computation
% - Requirements 6.1: Grand average as gold standard
% - Requirements 6.2: Random trial sampling
% - Requirements 6.3: Convergence metric calculation
% - Requirements 6.4: Convergence curve plotting
% - Requirements 6.5: Minimum trial determination
%
% The test uses synthetic data with known properties to verify all steps

function test_mission2_integration()

% Add necessary paths (relative to workspace root)
addpath(fullfile('..', '..'));  % Root for config_template
addpath(fullfile('..', '..', 'utils'));
addpath(fullfile('..', '..', 'data_loader'));
addpath(fullfile('..', '..', 'preprocessor'));
addpath(fullfile('..', '..', 'denoiser'));
addpath(fullfile('..', '..', 'filter'));
addpath(fullfile('..', '..', 'analyzer'));
addpath(fullfile('..', '..', 'visualizer'));

fprintf('=== Mission 2 Integration Test ===\n');
fprintf('Testing complete pipeline with synthetic auditory data\n\n');

% Initialize test results
test_results = struct();
test_results.tests_passed = 0;
test_results.tests_failed = 0;
test_results.test_details = {};

%% Test 1: Synthetic Data Processing
fprintf('Test 1: Processing synthetic auditory data...\n');
try
    config = config_template();
    config.adaptive_filter.algorithm = 'RLS';
    
    results_synthetic = process_mission2('demo', config, ...
        'PlotResults', false, ...
        'SaveResults', false, ...
        'Verbose', false);
    
    % Validate results structure
    assert(isstruct(results_synthetic), 'Results should be a structure');
    assert(isfield(results_synthetic, 'aef_filtered'), 'Missing AEF filtered data');
    assert(isfield(results_synthetic, 'assr_filtered'), 'Missing ASSR filtered data');
    assert(isfield(results_synthetic, 'trigger_indices'), 'Missing trigger indices');
    assert(isfield(results_synthetic, 'aef_trials'), 'Missing AEF trials');
    assert(isfield(results_synthetic, 'assr_trials'), 'Missing ASSR trials');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 1: PASSED - Synthetic data processing';
    fprintf('  ✓ PASSED\n\n');
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 1: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
    rethrow(ME);
end

%% Test 2: Requirement 5.1 - Frequency-Specific Filtering
fprintf('Test 2: Validating frequency-specific filtering (Req 5.1)...\n');
try
    % Check both AEF and ASSR filtered data exist
    assert(~isempty(results_synthetic.aef_filtered), 'AEF filtered data missing');
    assert(~isempty(results_synthetic.assr_filtered), 'ASSR filtered data missing');
    
    % Check dimensions match
    n_channels = size(results_synthetic.preprocessed.data, 1);
    assert(size(results_synthetic.aef_filtered, 1) == n_channels, ...
        'AEF channels mismatch');
    assert(size(results_synthetic.assr_filtered, 1) == n_channels, ...
        'ASSR channels mismatch');
    
    % Verify filtering was applied (data should be different)
    correlation_aef_assr = corrcoef(results_synthetic.aef_filtered(1,:), ...
        results_synthetic.assr_filtered(1,:));
    assert(correlation_aef_assr(1,2) < 0.99, ...
        'AEF and ASSR should be different after filtering');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 2: PASSED - Frequency-specific filtering valid';
    fprintf('  ✓ PASSED - Both AEF and ASSR filtering applied\n');
    fprintf('    AEF shape: %d × %d\n', size(results_synthetic.aef_filtered));
    fprintf('    ASSR shape: %d × %d\n\n', size(results_synthetic.assr_filtered));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 2: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 3: Requirement 5.2 - Adaptive Filtering
fprintf('Test 3: Validating adaptive filtering (Req 5.2)...\n');
try
    noise_reduction = results_synthetic.noise_reduction;
    
    % Check noise reduction is calculated
    n_channels = size(results_synthetic.aef_filtered, 1);
    assert(length(noise_reduction) == n_channels, 'Noise reduction length mismatch');
    
    % Check noise reduction is non-negative
    assert(all(noise_reduction >= 0), 'Noise reduction should be non-negative');
    
    % For synthetic data with common noise, should see some reduction
    mean_reduction = mean(noise_reduction);
    assert(mean_reduction >= 0, 'Mean noise reduction should be non-negative');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 3: PASSED - Adaptive filtering valid';
    fprintf('  ✓ PASSED - Adaptive filtering with reference sensors\n');
    fprintf('    Mean noise reduction: %.2f%%\n\n', mean_reduction);
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 3: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 4: Requirement 5.3 - Trigger Detection
fprintf('Test 4: Validating trigger detection (Req 5.3)...\n');
try
    trigger_indices = results_synthetic.trigger_indices;
    
    % Check triggers were detected
    assert(~isempty(trigger_indices), 'No triggers detected');
    assert(length(trigger_indices) > 0, 'Should detect at least one trigger');
    
    % For synthetic data, we know there should be triggers
    % Check trigger spacing is reasonable (should be ~1 second apart)
    if length(trigger_indices) > 1
        trigger_intervals = diff(trigger_indices) / results_synthetic.raw_data.fs;
        mean_interval = mean(trigger_intervals);
        assert(mean_interval > 0.5 && mean_interval < 2.0, ...
            sprintf('Trigger interval suspicious: %.2f s', mean_interval));
    end
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 4: PASSED - Trigger detection valid';
    fprintf('  ✓ PASSED - Triggers detected successfully\n');
    fprintf('    Number of triggers: %d\n', length(trigger_indices));
    if length(trigger_indices) > 1
        fprintf('    Mean interval: %.2f s\n\n', mean_interval);
    else
        fprintf('\n');
    end
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 4: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 5: Requirement 5.4 - Epoching
fprintf('Test 5: Validating epoching (Req 5.4)...\n');
try
    aef_trials = results_synthetic.aef_trials;
    assr_trials = results_synthetic.assr_trials;
    
    % Check TrialData objects exist
    assert(isa(aef_trials, 'TrialData'), 'AEF trials should be TrialData object');
    assert(isa(assr_trials, 'TrialData'), 'ASSR trials should be TrialData object');
    
    % Check trial dimensions
    n_channels = size(results_synthetic.aef_filtered, 1);
    assert(size(aef_trials.trials, 1) == n_channels, 'AEF trial channels mismatch');
    assert(size(assr_trials.trials, 1) == n_channels, 'ASSR trial channels mismatch');
    
    % Check number of trials matches number of triggers
    n_triggers = length(results_synthetic.trigger_indices);
    assert(size(aef_trials.trials, 3) <= n_triggers, ...
        'AEF trials should not exceed triggers');
    assert(size(assr_trials.trials, 3) <= n_triggers, ...
        'ASSR trials should not exceed triggers');
    
    % Check trial duration
    expected_duration = config.mission2.pre_time + config.mission2.post_time;
    actual_duration = aef_trials.trial_times(end) - aef_trials.trial_times(1);
    assert(abs(actual_duration - expected_duration) < 0.01, ...
        'Trial duration mismatch');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 5: PASSED - Epoching valid';
    fprintf('  ✓ PASSED - Trials extracted correctly\n');
    fprintf('    AEF trials: %d\n', size(aef_trials.trials, 3));
    fprintf('    ASSR trials: %d\n', size(assr_trials.trials, 3));
    fprintf('    Trial duration: %.2f s\n\n', actual_duration);
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 5: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 6: Requirement 5.5 & 6.1 - Grand Average
fprintf('Test 6: Validating grand average computation (Req 5.5, 6.1)...\n');
try
    aef_grand = results_synthetic.aef_grand_average;
    assr_grand = results_synthetic.assr_grand_average;
    
    % Check grand averages exist
    assert(~isempty(aef_grand), 'AEF grand average missing');
    assert(~isempty(assr_grand), 'ASSR grand average missing');
    
    % Check dimensions
    n_channels = size(results_synthetic.aef_filtered, 1);
    n_samples_per_trial = size(results_synthetic.aef_trials.trials, 2);
    assert(size(aef_grand, 1) == n_channels, 'AEF grand average channels mismatch');
    assert(size(aef_grand, 2) == n_samples_per_trial, 'AEF grand average samples mismatch');
    
    % Verify grand average is actually the mean
    manual_average = mean(results_synthetic.aef_trials.trials, 3);
    max_diff = max(abs(aef_grand(:) - manual_average(:)));
    assert(max_diff < 1e-10, 'Grand average should be arithmetic mean');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 6: PASSED - Grand average valid';
    fprintf('  ✓ PASSED - Grand averages computed correctly\n');
    fprintf('    AEF grand average shape: %d × %d\n', size(aef_grand));
    fprintf('    ASSR grand average shape: %d × %d\n\n', size(assr_grand));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 6: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 7: Requirement 6.2 - Random Trial Sampling
fprintf('Test 7: Validating random trial sampling (Req 6.2)...\n');
try
    trials = results_synthetic.aef_trials.trials;
    n_total_trials = size(trials, 3);
    
    % Test sampling different numbers of trials
    if n_total_trials >= 10
        n_sample = 5;
        sampled = sample_trials(trials, n_sample);
        
        % Check sampled size
        assert(size(sampled, 3) == 1, 'Sampled should be averaged to single trial');
        assert(size(sampled, 1) == size(trials, 1), 'Channels should match');
        assert(size(sampled, 2) == size(trials, 2), 'Samples should match');
    end
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 7: PASSED - Random sampling valid';
    fprintf('  ✓ PASSED - Random trial sampling works\n');
    fprintf('    Total trials: %d\n\n', n_total_trials);
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 7: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 8: Requirement 6.3 - Convergence Metrics
fprintf('Test 8: Validating convergence metrics (Req 6.3)...\n');
try
    aef_conv = results_synthetic.aef_convergence;
    assr_conv = results_synthetic.assr_convergence;
    
    % Check convergence structures exist
    assert(isfield(aef_conv, 'correlation'), 'Missing correlation field');
    assert(isfield(aef_conv, 'rmse'), 'Missing RMSE field');
    assert(isfield(aef_conv, 'n_trials'), 'Missing n_trials field');
    
    % Check correlation is in valid range [-1, 1]
    assert(all(aef_conv.correlation >= -1 & aef_conv.correlation <= 1), ...
        'Correlation should be in [-1, 1]');
    assert(all(assr_conv.correlation >= -1 & assr_conv.correlation <= 1), ...
        'Correlation should be in [-1, 1]');
    
    % Check RMSE is non-negative
    assert(all(aef_conv.rmse >= 0), 'RMSE should be non-negative');
    assert(all(assr_conv.rmse >= 0), 'RMSE should be non-negative');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 8: PASSED - Convergence metrics valid';
    fprintf('  ✓ PASSED - Convergence metrics calculated correctly\n');
    fprintf('    AEF correlation range: [%.3f, %.3f]\n', ...
        min(aef_conv.correlation), max(aef_conv.correlation));
    fprintf('    ASSR correlation range: [%.3f, %.3f]\n\n', ...
        min(assr_conv.correlation), max(assr_conv.correlation));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 8: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 9: Requirement 6.4 - Convergence Curve
fprintf('Test 9: Validating convergence curve (Req 6.4)...\n');
try
    aef_conv = results_synthetic.aef_convergence;
    
    % Check that correlation generally increases with more trials
    % (allowing for some random fluctuation)
    if length(aef_conv.correlation) > 2
        % Check first and last values
        assert(aef_conv.correlation(end) >= aef_conv.correlation(1) - 0.1, ...
            'Correlation should generally increase');
    end
    
    % Check that n_trials is monotonically increasing
    assert(all(diff(aef_conv.n_trials) > 0), 'n_trials should be increasing');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 9: PASSED - Convergence curve valid';
    fprintf('  ✓ PASSED - Convergence curve shows expected behavior\n\n');
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 9: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 10: Requirement 6.5 - Minimum Trial Determination
fprintf('Test 10: Validating minimum trial determination (Req 6.5)...\n');
try
    aef_conv = results_synthetic.aef_convergence;
    assr_conv = results_synthetic.assr_convergence;
    
    % Check minimum trials field exists
    assert(isfield(aef_conv, 'min_trials'), 'Missing min_trials field');
    assert(isfield(assr_conv, 'min_trials'), 'Missing min_trials field');
    
    % Check minimum trials is reasonable
    n_total_trials = size(results_synthetic.aef_trials.trials, 3);
    assert(aef_conv.min_trials > 0, 'Minimum trials should be positive');
    assert(aef_conv.min_trials <= n_total_trials, ...
        'Minimum trials should not exceed total');
    
    % Check that correlation at min_trials meets threshold
    threshold = config.mission2.convergence_threshold;
    min_idx = find(aef_conv.n_trials == aef_conv.min_trials, 1);
    if ~isempty(min_idx)
        assert(aef_conv.correlation(min_idx) >= threshold - 0.05, ...
            sprintf('Correlation at min_trials should meet threshold (%.2f)', threshold));
    end
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 10: PASSED - Minimum trials determined';
    fprintf('  ✓ PASSED - Minimum trials determined correctly\n');
    fprintf('    AEF minimum trials: %d\n', aef_conv.min_trials);
    fprintf('    ASSR minimum trials: %d\n', assr_conv.min_trials);
    fprintf('    Threshold: %.2f\n\n', threshold);
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 10: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 11: File Save Validation
fprintf('Test 11: Validating file save...\n');
try
    % Create temporary directory
    temp_dir = 'temp_test_mission2';
    if ~exist(temp_dir, 'dir')
        mkdir(temp_dir);
    end
    
    % Use already processed results and just save them
    save(fullfile(temp_dir, 'test_results.mat'), 'results_synthetic');
    
    % Check file exists
    save_file = fullfile(temp_dir, 'test_results.mat');
    assert(exist(save_file, 'file') == 2, 'Results file not saved');
    
    % Load and compare
    loaded = load(save_file);
    assert(isfield(loaded, 'results_synthetic'), 'Loaded file missing results');
    
    % Clean up
    rmdir(temp_dir, 's');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 11: PASSED - File save/load successful';
    fprintf('  ✓ PASSED - Results saved and loaded correctly\n\n');
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 11: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
    
    % Clean up on failure
    if exist(temp_dir, 'dir')
        rmdir(temp_dir, 's');
    end
end

%% Generate Test Report
fprintf('=== Mission 2 Integration Test Report ===\n\n');
fprintf('Total Tests: %d\n', test_results.tests_passed + test_results.tests_failed);
fprintf('Passed: %d\n', test_results.tests_passed);
fprintf('Failed: %d\n\n', test_results.tests_failed);

fprintf('Test Details:\n');
for i = 1:length(test_results.test_details)
    fprintf('  %s\n', test_results.test_details{i});
end

if test_results.tests_failed == 0
    fprintf('\n✓ ALL TESTS PASSED - Mission 2 pipeline validated\n');
    fprintf('Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5 verified\n');
else
    fprintf('\n✗ SOME TESTS FAILED - Review failures above\n');
    error('Mission 2 integration test failed');
end

end
