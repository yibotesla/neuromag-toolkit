% TEST_PREPROCESSOR Unit tests for preprocessing module
%
% Tests the preprocessing functions:
%   - remove_dc
%   - detect_bad_channels
%   - preprocess_data

function tests = test_preprocessor
    tests = functiontests(localfunctions);
end

%% Test remove_dc function

function test_remove_dc_basic(testCase)
    % Test basic DC removal functionality
    
    % Create test data with known DC offset
    n_channels = 5;
    n_samples = 1000;
    dc_offsets = [1.0; -0.5; 2.0; 0.0; -1.5];
    
    % Generate data with DC offsets
    data_in = randn(n_channels, n_samples) * 0.1;
    data_in = data_in + dc_offsets;
    
    % Apply DC removal
    data_out = remove_dc(data_in);
    
    % Verify means are approximately zero
    channel_means = mean(data_out, 2);
    testCase.verifyLessThan(abs(channel_means), 1e-14, ...
        'Channel means should be approximately zero after DC removal');
end

function test_remove_dc_preserves_shape(testCase)
    % Test that DC removal preserves data shape
    
    n_channels = 10;
    n_samples = 500;
    data_in = randn(n_channels, n_samples);
    
    data_out = remove_dc(data_in);
    
    testCase.verifyEqual(size(data_out), size(data_in), ...
        'Output shape should match input shape');
end

function test_remove_dc_empty_input(testCase)
    % Test error handling for empty input
    
    testCase.verifyError(@() remove_dc([]), 'MEG:Preprocessor:EmptyInput');
end

%% Test detect_bad_channels function

function test_detect_bad_channels_saturated(testCase)
    % Test detection of saturated channels
    
    n_channels = 10;
    n_samples = 1000;
    
    % Create normal data
    data = randn(n_channels, n_samples) * 1e-12;
    
    % Make channels 3 and 7 saturated
    data(3, :) = 2e-10;  % Above default saturation threshold
    data(7, :) = -1.5e-10;
    
    % Detect bad channels
    [bad_channels, bad_types] = detect_bad_channels(data);
    
    % Verify saturated channels are detected
    testCase.verifyTrue(ismember(3, bad_channels), ...
        'Channel 3 should be detected as bad (saturated)');
    testCase.verifyTrue(ismember(7, bad_channels), ...
        'Channel 7 should be detected as bad (saturated)');
end

function test_detect_bad_channels_flat(testCase)
    % Test detection of flat channels
    
    n_channels = 10;
    n_samples = 1000;
    
    % Create normal data
    data = randn(n_channels, n_samples) * 1e-12;
    
    % Make channel 5 flat (constant value)
    data(5, :) = 1e-13;
    
    % Detect bad channels
    options = struct('flat_var_threshold', 1e-28);
    [bad_channels, bad_types] = detect_bad_channels(data, options);
    
    % Verify flat channel is detected
    testCase.verifyTrue(ismember(5, bad_channels), ...
        'Channel 5 should be detected as bad (flat)');
    testCase.verifyTrue(contains(bad_types{bad_channels == 5}, 'flat'), ...
        'Bad type should indicate flat channel');
end

function test_detect_bad_channels_noisy(testCase)
    % Test detection of excessively noisy channels
    
    n_channels = 10;
    n_samples = 1000;
    
    % Create normal data with consistent noise level
    data = randn(n_channels, n_samples) * 1e-13;
    
    % Make channel 8 very noisy
    data(8, :) = randn(1, n_samples) * 1e-11;  % 100x more noise
    
    % Detect bad channels
    options = struct('noise_std_threshold', 5.0);
    [bad_channels, bad_types] = detect_bad_channels(data, options);
    
    % Verify noisy channel is detected
    testCase.verifyTrue(ismember(8, bad_channels), ...
        'Channel 8 should be detected as bad (noisy)');
end

function test_detect_bad_channels_no_bad(testCase)
    % Test with clean data (no bad channels)
    
    n_channels = 10;
    n_samples = 1000;
    
    % Create clean data
    data = randn(n_channels, n_samples) * 1e-13;
    
    % Detect bad channels
    [bad_channels, ~] = detect_bad_channels(data);
    
    % Verify no bad channels detected
    testCase.verifyEmpty(bad_channels, ...
        'No bad channels should be detected in clean data');
end

%% Test preprocess_data function

function test_preprocess_data_with_struct(testCase)
    % Test preprocessing with structure input
    
    % Create test data structure
    n_channels = 64;
    n_samples = 1000;
    fs = 4800;
    
    data_struct = struct();
    data_struct.meg_channels = randn(n_channels, n_samples) * 1e-12 + 1e-12;  % Add DC
    data_struct.time = (0:n_samples-1) / fs;
    data_struct.fs = fs;
    
    % Preprocess
    [data_clean, bad_channels] = preprocess_data(data_struct);
    
    % Verify output is ProcessedData object
    testCase.verifyClass(data_clean, 'ProcessedData');
    
    % Verify DC was removed
    channel_means = mean(data_clean.data, 2);
    testCase.verifyLessThan(max(abs(channel_means)), 1e-14, ...
        'DC should be removed');
    
    % Verify processing log exists
    testCase.verifyNotEmpty(data_clean.processing_log, ...
        'Processing log should not be empty');
end

function test_preprocess_data_with_MEGData(testCase)
    % Test preprocessing with MEGData object input
    
    % Create MEGData object
    meg_obj = MEGData();
    meg_obj.meg_channels = randn(64, 1000) * 1e-12;
    meg_obj.time = (0:999) / 4800;
    meg_obj.fs = 4800;
    meg_obj = meg_obj.set_channel_labels();
    
    % Preprocess
    [data_clean, bad_channels] = preprocess_data(meg_obj);
    
    % Verify output
    testCase.verifyClass(data_clean, 'ProcessedData');
    testCase.verifyEqual(size(data_clean.data, 1), 64);
end

function test_preprocess_data_options(testCase)
    % Test preprocessing with custom options
    
    % Create test data
    data_struct = struct();
    data_struct.meg_channels = randn(10, 500) * 1e-12 + 5e-13;
    data_struct.time = (0:499) / 4800;
    data_struct.fs = 4800;
    
    % Preprocess with DC removal disabled
    options = struct('remove_dc', false, 'detect_bad', true);
    [data_clean, ~] = preprocess_data(data_struct, options);
    
    % Verify DC was NOT removed
    channel_means = mean(data_clean.data, 2);
    testCase.verifyGreaterThan(max(abs(channel_means)), 1e-14, ...
        'DC should not be removed when option is disabled');
end

function test_preprocess_data_detects_bad_channels(testCase)
    % Test that preprocessing detects bad channels
    
    % Create test data with a bad channel
    n_channels = 10;
    n_samples = 1000;
    
    data_struct = struct();
    data_struct.meg_channels = randn(n_channels, n_samples) * 1e-13;
    data_struct.meg_channels(5, :) = 2e-10;  % Saturated channel
    data_struct.time = (0:n_samples-1) / 4800;
    data_struct.fs = 4800;
    
    % Preprocess
    [data_clean, bad_channels] = preprocess_data(data_struct);
    
    % Verify bad channel was detected
    testCase.verifyTrue(ismember(5, bad_channels), ...
        'Saturated channel should be detected');
    
    % Verify it's logged
    log_str = strjoin(data_clean.processing_log, ' ');
    testCase.verifyTrue(contains(log_str, 'Bad channel'), ...
        'Processing log should mention bad channels');
end
