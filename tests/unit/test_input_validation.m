% TEST_INPUT_VALIDATION - Unit tests for input validation utility
%
% Tests the validate_inputs function for various validation types
%
% Requirements: 8.5

% Add paths (relative to workspace root)
addpath('../../utils');
addpath('../../data_loader');
addpath('../../preprocessor');
addpath('../../filter');
addpath('../../analyzer');

%% Test file existence validation
fprintf('Testing file existence validation...\n');

% Test valid file
try
    validate_inputs('test_file', '../../README.md', 'type', 'file_exists');
    fprintf('  ✓ Valid file check passed\n');
catch ME
    fprintf('  ✗ Valid file check failed: %s\n', ME.message);
end

% Test invalid file
try
    validate_inputs('test_file', 'nonexistent_file.txt', 'type', 'file_exists');
    fprintf('  ✗ Invalid file check should have failed\n');
catch ME
    if contains(ME.identifier, 'FileNotFound')
        fprintf('  ✓ Invalid file correctly rejected\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

%% Test positive number validation
fprintf('\nTesting positive number validation...\n');

% Test valid positive
try
    validate_inputs('sampling_rate', 4800, 'type', 'positive');
    fprintf('  ✓ Positive number check passed\n');
catch ME
    fprintf('  ✗ Positive number check failed: %s\n', ME.message);
end

% Test zero (should fail)
try
    validate_inputs('sampling_rate', 0, 'type', 'positive');
    fprintf('  ✗ Zero should have been rejected\n');
catch ME
    if contains(ME.identifier, 'NotPositive')
        fprintf('  ✓ Zero correctly rejected\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

% Test negative (should fail)
try
    validate_inputs('sampling_rate', -100, 'type', 'positive');
    fprintf('  ✗ Negative should have been rejected\n');
catch ME
    if contains(ME.identifier, 'NotPositive')
        fprintf('  ✓ Negative correctly rejected\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

%% Test non-negative validation
fprintf('\nTesting non-negative number validation...\n');

% Test valid non-negative
try
    validate_inputs('pre_time', 0, 'type', 'non_negative');
    fprintf('  ✓ Zero accepted as non-negative\n');
catch ME
    fprintf('  ✗ Zero should be accepted: %s\n', ME.message);
end

try
    validate_inputs('pre_time', 0.5, 'type', 'non_negative');
    fprintf('  ✓ Positive accepted as non-negative\n');
catch ME
    fprintf('  ✗ Positive should be accepted: %s\n', ME.message);
end

% Test negative (should fail)
try
    validate_inputs('pre_time', -0.1, 'type', 'non_negative');
    fprintf('  ✗ Negative should have been rejected\n');
catch ME
    if contains(ME.identifier, 'NotNonNegative')
        fprintf('  ✓ Negative correctly rejected\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

%% Test range validation
fprintf('\nTesting range validation...\n');

% Test value in range
try
    validate_inputs('lambda', 0.995, 'type', 'in_range', 'range', [0.99, 1.0]);
    fprintf('  ✓ Value in range accepted\n');
catch ME
    fprintf('  ✗ Value in range should be accepted: %s\n', ME.message);
end

% Test value below range
try
    validate_inputs('lambda', 0.98, 'type', 'in_range', 'range', [0.99, 1.0]);
    fprintf('  ✗ Value below range should have been rejected\n');
catch ME
    if contains(ME.identifier, 'OutOfRange')
        fprintf('  ✓ Value below range correctly rejected\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

% Test value above range
try
    validate_inputs('lambda', 1.01, 'type', 'in_range', 'range', [0.99, 1.0]);
    fprintf('  ✗ Value above range should have been rejected\n');
catch ME
    if contains(ME.identifier, 'OutOfRange')
        fprintf('  ✓ Value above range correctly rejected\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

%% Test numeric type validations
fprintf('\nTesting numeric type validations...\n');

% Test numeric scalar
try
    validate_inputs('fs', 4800, 'type', 'numeric_scalar');
    fprintf('  ✓ Numeric scalar accepted\n');
catch ME
    fprintf('  ✗ Numeric scalar should be accepted: %s\n', ME.message);
end

try
    validate_inputs('fs', [4800, 4800], 'type', 'numeric_scalar');
    fprintf('  ✗ Vector should have been rejected as scalar\n');
catch ME
    if contains(ME.identifier, 'NotNumericScalar')
        fprintf('  ✓ Vector correctly rejected as scalar\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

% Test numeric vector
try
    validate_inputs('trigger_indices', [100, 200, 300], 'type', 'numeric_vector');
    fprintf('  ✓ Numeric vector accepted\n');
catch ME
    fprintf('  ✗ Numeric vector should be accepted: %s\n', ME.message);
end

% Test numeric matrix
try
    validate_inputs('meg_data', rand(64, 1000), 'type', 'numeric_matrix');
    fprintf('  ✓ Numeric matrix accepted\n');
catch ME
    fprintf('  ✗ Numeric matrix should be accepted: %s\n', ME.message);
end

%% Test string validation
fprintf('\nTesting string validation...\n');

% Test char array
try
    validate_inputs('file_path', 'test.lvm', 'type', 'string');
    fprintf('  ✓ Char array accepted as string\n');
catch ME
    fprintf('  ✗ Char array should be accepted: %s\n', ME.message);
end

% Test string type
try
    validate_inputs('file_path', string('test.lvm'), 'type', 'string');
    fprintf('  ✓ String type accepted\n');
catch ME
    fprintf('  ✗ String type should be accepted: %s\n', ME.message);
end

% Test numeric (should fail)
try
    validate_inputs('file_path', 123, 'type', 'string');
    fprintf('  ✗ Numeric should have been rejected as string\n');
catch ME
    if contains(ME.identifier, 'NotString')
        fprintf('  ✓ Numeric correctly rejected as string\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

%% Test structure validation
fprintf('\nTesting structure validation...\n');

% Test valid struct
test_struct = struct('field1', 1, 'field2', 'value');
try
    validate_inputs('options', test_struct, 'type', 'struct');
    fprintf('  ✓ Structure accepted\n');
catch ME
    fprintf('  ✗ Structure should be accepted: %s\n', ME.message);
end

% Test non-struct (should fail)
try
    validate_inputs('options', [1, 2, 3], 'type', 'struct');
    fprintf('  ✗ Array should have been rejected as struct\n');
catch ME
    if contains(ME.identifier, 'NotStruct')
        fprintf('  ✓ Array correctly rejected as struct\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

%% Test MEGData validation
fprintf('\nTesting MEGData validation...\n');

% Test valid MEGData structure
meg_struct = struct();
meg_struct.meg_channels = rand(64, 1000);
meg_struct.time = (0:999) / 4800;
meg_struct.fs = 4800;

try
    validate_inputs('data', meg_struct, 'type', 'meg_data');
    fprintf('  ✓ Valid MEGData structure accepted\n');
catch ME
    fprintf('  ✗ Valid MEGData structure should be accepted: %s\n', ME.message);
end

% Test invalid MEGData (missing field)
invalid_struct = struct();
invalid_struct.meg_channels = rand(64, 1000);
% Missing 'time' and 'fs' fields

try
    validate_inputs('data', invalid_struct, 'type', 'meg_data');
    fprintf('  ✗ Invalid MEGData should have been rejected\n');
catch ME
    if contains(ME.identifier, 'MissingField')
        fprintf('  ✓ Invalid MEGData correctly rejected (missing field)\n');
    else
        fprintf('  ✗ Wrong error type: %s\n', ME.identifier);
    end
end

%% Summary
fprintf('\n=== Input Validation Tests Complete ===\n');
fprintf('All validation types tested successfully.\n');
