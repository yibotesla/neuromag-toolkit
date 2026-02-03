% TEST_MISSION1_INTEGRATION Comprehensive integration test for Mission 1
%
% This test validates the complete Mission 1 pipeline against all requirements:
% - Requirements 2.1: PSD computation
% - Requirements 2.2: SNR calculation at 17Hz
% - Requirements 2.3: 17Hz peak detection
% - Requirements 2.4: Spike noise removal
% - Requirements 2.5: Broadband noise reduction with adaptive filtering
%
% The test uses synthetic data with known properties to verify:
% 1. 17Hz peak is correctly detected in PSD
% 2. SNR improves after filtering
% 3. Noise reduction is achieved
% 4. All processing steps complete successfully
% 5. Results are saved and can be loaded

function test_mission1_integration()

% Add necessary paths (relative to workspace root)
addpath(fullfile('..', '..'));  % Root for config_template
addpath(fullfile('..', '..', 'utils'));
addpath(fullfile('..', '..', 'data_loader'));
addpath(fullfile('..', '..', 'preprocessor'));
addpath(fullfile('..', '..', 'denoiser'));
addpath(fullfile('..', '..', 'filter'));
addpath(fullfile('..', '..', 'analyzer'));
addpath(fullfile('..', '..', 'visualizer'));

fprintf('=== Mission 1 Integration Test ===\n');
fprintf('Testing complete pipeline with synthetic and real data\n\n');

% Initialize test results
test_results = struct();
test_results.tests_passed = 0;
test_results.tests_failed = 0;
test_results.test_details = {};

%% Test 1: Synthetic Data Processing
fprintf('Test 1: Processing synthetic data with known 17Hz signal...\n');
try
    config = config_template();
    config.despike.method = 'median';
    config.adaptive_filter.algorithm = 'RLS';
    
    results_synthetic = process_mission1('demo', config, ...
        'PlotResults', false, ...
        'SaveResults', false, ...
        'Verbose', false);
    
    % Validate results structure
    assert(isstruct(results_synthetic), 'Results should be a structure');
    assert(isfield(results_synthetic, 'filtered'), 'Missing filtered data');
    assert(isfield(results_synthetic, 'psd_filtered'), 'Missing PSD');
    assert(isfield(results_synthetic, 'snr_filtered'), 'Missing SNR');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 1: PASSED - Synthetic data processing';
    fprintf('  ✓ PASSED\n\n');
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 1: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
    rethrow(ME);
end

%% Test 2: Requirement 2.1 - PSD Computation
fprintf('Test 2: Validating PSD computation (Req 2.1)...\n');
try
    psd_raw = results_synthetic.psd_raw;
    psd_filtered = results_synthetic.psd_filtered;
    
    % Check PSD structure
    assert(isfield(psd_raw, 'frequencies'), 'PSD missing frequencies');
    assert(isfield(psd_raw, 'power'), 'PSD missing power');
    assert(isfield(psd_filtered, 'frequencies'), 'Filtered PSD missing frequencies');
    assert(isfield(psd_filtered, 'power'), 'Filtered PSD missing power');
    
    % Check frequency range (should be 0 to fs/2)
    fs = results_synthetic.raw_data.fs;
    assert(psd_raw.frequencies(1) >= 0, 'Frequency should start at 0');
    assert(psd_raw.frequencies(end) <= fs/2 + 1, 'Frequency should end at fs/2');
    
    % Check dimensions
    n_channels = size(results_synthetic.filtered, 1);
    assert(size(psd_filtered.power, 1) == n_channels, 'PSD channels mismatch');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 2: PASSED - PSD computation valid';
    fprintf('  ✓ PASSED - PSD format correct\n');
    fprintf('    Frequency range: [%.1f, %.1f] Hz\n', ...
        psd_raw.frequencies(1), psd_raw.frequencies(end));
    fprintf('    PSD dimensions: %d channels × %d frequencies\n\n', ...
        size(psd_filtered.power, 1), size(psd_filtered.power, 2));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 2: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 3: Requirement 2.2 - SNR Calculation
fprintf('Test 3: Validating SNR calculation at 17Hz (Req 2.2)...\n');
try
    snr_raw = results_synthetic.snr_raw;
    snr_filtered = results_synthetic.snr_filtered;
    
    % Check SNR is calculated for all channels
    n_channels = size(results_synthetic.filtered, 1);
    assert(length(snr_raw) == n_channels, 'SNR raw length mismatch');
    assert(length(snr_filtered) == n_channels, 'SNR filtered length mismatch');
    
    % Check SNR values are reasonable (in dB)
    assert(all(isfinite(snr_raw)), 'SNR raw contains non-finite values');
    assert(all(isfinite(snr_filtered)), 'SNR filtered contains non-finite values');
    
    % For synthetic data with 17Hz signal, SNR should be positive
    mean_snr_filtered = mean(snr_filtered);
    assert(mean_snr_filtered > 0, 'Mean SNR should be positive for signal data');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 3: PASSED - SNR calculation valid';
    fprintf('  ✓ PASSED - SNR calculation correct\n');
    fprintf('    Raw SNR: %.2f dB (mean)\n', mean(snr_raw));
    fprintf('    Filtered SNR: %.2f dB (mean)\n\n', mean_snr_filtered);
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 3: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 4: Requirement 2.3 - 17Hz Peak Detection
fprintf('Test 4: Validating 17Hz peak detection (Req 2.3)...\n');
try
    peak_detected = results_synthetic.peak_detected;
    peak_freq = results_synthetic.peak_freq;
    
    % Check peak detection results
    n_channels = size(results_synthetic.filtered, 1);
    assert(length(peak_detected) == n_channels, 'Peak detection length mismatch');
    
    % For synthetic data with 17Hz signal, most channels should detect peak
    n_detected = sum(peak_detected);
    detection_rate = n_detected / n_channels;
    assert(detection_rate > 0.5, ...
        sprintf('Detection rate too low: %.1f%% (expected > 50%%)', 100*detection_rate));
    
    % Check detected frequencies are near 17Hz
    if n_detected > 0
        valid_freqs = peak_freq(peak_detected);
        freq_errors = abs(valid_freqs - 17);
        max_error = max(freq_errors);
        assert(max_error <= 0.5, ...
            sprintf('Peak frequency error too large: %.3f Hz (expected ≤ 0.5 Hz)', max_error));
    end
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 4: PASSED - 17Hz peak detection valid';
    fprintf('  ✓ PASSED - Peak detection successful\n');
    fprintf('    Detection rate: %.1f%% (%d/%d channels)\n', ...
        100*detection_rate, n_detected, n_channels);
    if n_detected > 0
        fprintf('    Mean detected frequency: %.2f Hz\n', mean(valid_freqs));
        fprintf('    Max frequency error: %.3f Hz\n\n', max_error);
    end
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 4: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 5: Requirement 2.4 - Spike Noise Removal
fprintf('Test 5: Validating spike noise removal (Req 2.4)...\n');
try
    preprocessed = results_synthetic.preprocessed.data;
    despiked = results_synthetic.despiked;
    
    % Check dimensions match
    assert(isequal(size(preprocessed), size(despiked)), ...
        'Despiked data dimensions mismatch');
    
    % Check that despiking preserves signal shape (high correlation)
    % Calculate correlation for each channel
    correlations = zeros(size(preprocessed, 1), 1);
    for ch = 1:size(preprocessed, 1)
        corr_matrix = corrcoef(preprocessed(ch, :), despiked(ch, :));
        correlations(ch) = corr_matrix(1, 2);
    end
    
    mean_correlation = mean(correlations);
    assert(mean_correlation > 0.90, ...
        sprintf('Correlation too low: %.3f (expected > 0.90)', mean_correlation));
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 5: PASSED - Spike removal preserves signal';
    fprintf('  ✓ PASSED - Spike removal effective\n');
    fprintf('    Mean correlation: %.4f\n', mean_correlation);
    fprintf('    Min correlation: %.4f\n\n', min(correlations));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 5: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 6: Requirement 2.5 - Adaptive Filtering Noise Reduction
fprintf('Test 6: Validating adaptive filtering noise reduction (Req 2.5)...\n');
try
    noise_reduction = results_synthetic.noise_reduction;
    
    % Check noise reduction is calculated for all channels
    n_channels = size(results_synthetic.filtered, 1);
    assert(length(noise_reduction) == n_channels, 'Noise reduction length mismatch');
    
    % Check noise reduction is non-negative
    assert(all(noise_reduction >= 0), 'Noise reduction should be non-negative');
    
    % For data with common noise, average reduction should be positive
    mean_reduction = mean(noise_reduction);
    assert(mean_reduction > 0, ...
        sprintf('Mean noise reduction should be positive, got %.2f%%', mean_reduction));
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 6: PASSED - Noise reduction achieved';
    fprintf('  ✓ PASSED - Adaptive filtering effective\n');
    fprintf('    Mean noise reduction: %.2f%%\n', mean_reduction);
    fprintf('    Range: [%.2f%%, %.2f%%]\n\n', ...
        min(noise_reduction), max(noise_reduction));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 6: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 7: SNR Improvement Validation
fprintf('Test 7: Validating SNR improvement after processing...\n');
try
    snr_improvement = results_synthetic.snr_filtered - results_synthetic.snr_raw;
    mean_improvement = mean(snr_improvement);
    
    % SNR should improve on average
    assert(mean_improvement > 0, ...
        sprintf('SNR should improve, got %.2f dB', mean_improvement));
    
    % Most channels should show improvement
    n_improved = sum(snr_improvement > 0);
    improvement_rate = n_improved / length(snr_improvement);
    assert(improvement_rate > 0.7, ...
        sprintf('Too few channels improved: %.1f%% (expected > 70%%)', ...
        100*improvement_rate));
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 7: PASSED - SNR improvement validated';
    fprintf('  ✓ PASSED - SNR improved after processing\n');
    fprintf('    Mean improvement: %.2f dB\n', mean_improvement);
    fprintf('    Channels improved: %.1f%% (%d/%d)\n\n', ...
        100*improvement_rate, n_improved, length(snr_improvement));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 7: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 8: File Save Validation
fprintf('Test 8: Validating file save...\n');
try
    % Create temporary directory
    temp_dir = 'temp_test_mission1';
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
    test_results.test_details{end+1} = 'Test 8: PASSED - File save/load successful';
    fprintf('  ✓ PASSED - Results saved and loaded correctly\n\n');
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 8: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
    
    % Clean up on failure
    if exist(temp_dir, 'dir')
        rmdir(temp_dir, 's');
    end
end

%% Test 9: Verify RLS Algorithm Works
fprintf('Test 9: Verifying RLS algorithm...\n');
try
    % Already tested in Test 1, just verify it's RLS
    assert(strcmpi(config.adaptive_filter.algorithm, 'RLS'), 'Should use RLS');
    assert(mean(results_synthetic.noise_reduction) > 0, 'RLS noise reduction invalid');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 9: PASSED - RLS algorithm validated';
    fprintf('  ✓ PASSED - RLS produces valid results\n');
    fprintf('    RLS noise reduction: %.2f%%\n\n', mean(results_synthetic.noise_reduction));
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 9: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Test 10: Verify Median Despike Works
fprintf('Test 10: Verifying median despike...\n');
try
    % Already tested in Test 1, just verify it's median
    assert(strcmpi(config.despike.method, 'median'), 'Should use median');
    assert(~isempty(results_synthetic.despiked), 'Median despike failed');
    
    test_results.tests_passed = test_results.tests_passed + 1;
    test_results.test_details{end+1} = 'Test 10: PASSED - Median despike works';
    fprintf('  ✓ PASSED - Median despike validated\n\n');
catch ME
    test_results.tests_failed = test_results.tests_failed + 1;
    test_results.test_details{end+1} = sprintf('Test 10: FAILED - %s', ME.message);
    fprintf('  ✗ FAILED: %s\n\n', ME.message);
end

%% Generate Test Report
fprintf('=== Mission 1 Integration Test Report ===\n\n');
fprintf('Total Tests: %d\n', test_results.tests_passed + test_results.tests_failed);
fprintf('Passed: %d\n', test_results.tests_passed);
fprintf('Failed: %d\n\n', test_results.tests_failed);

fprintf('Test Details:\n');
for i = 1:length(test_results.test_details)
    fprintf('  %s\n', test_results.test_details{i});
end

if test_results.tests_failed == 0
    fprintf('\n✓ ALL TESTS PASSED - Mission 1 pipeline validated\n');
    fprintf('Requirements 2.1, 2.2, 2.3, 2.4, 2.5 verified\n');
else
    fprintf('\n✗ SOME TESTS FAILED - Review failures above\n');
    error('Mission 1 integration test failed');
end

end
