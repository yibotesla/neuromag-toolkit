% TEST_DATA_LOADER Unit tests for data loader module
%
% This script tests the load_lvm_data and identify_channels functions
%
% Requirements tested: 1.1, 1.2, 1.5

% Add necessary paths (relative to workspace root)
script_dir = fileparts(mfilename('fullpath'));
workspace_root = fileparts(fileparts(script_dir));
addpath(fullfile(workspace_root, 'data_loader'));
addpath(fullfile(workspace_root, 'utils'));

%% Test 1: identify_channels with 68 columns
fprintf('Test 1: identify_channels with 68 columns\n');
[meg_idx, ref_idx, stim_idx, trig_idx, labels] = identify_channels(68);

% Verify MEG channels are 1-64
assert(isequal(meg_idx, 1:64), 'MEG channels should be 1-64');
fprintf('  ✓ MEG channels correctly identified (1-64)\n');

% Verify reference channels
assert(length(ref_idx) >= 2 && length(ref_idx) <= 3, 'Reference channels should be 2-3');
fprintf('  ✓ Reference channels correctly identified\n');

% Verify stimulus and trigger indices
assert(stim_idx == 67 || stim_idx == 68, 'Stimulus index should be 67 or 68');
assert(trig_idx == 68 || trig_idx == 69, 'Trigger index should be 68 or 69');
fprintf('  ✓ Stimulus and trigger channels correctly identified\n');

% Verify labels
assert(length(labels) == 68, 'Should have 68 labels');
assert(strcmp(labels{1}, 'MEG001'), 'First label should be MEG001');
assert(strcmp(labels{64}, 'MEG064'), 'Last MEG label should be MEG064');
fprintf('  ✓ Channel labels correctly generated\n');

%% Test 2: identify_channels with 69 columns
fprintf('\nTest 2: identify_channels with 69 columns\n');
[meg_idx, ref_idx, stim_idx, trig_idx, labels] = identify_channels(69);

assert(isequal(meg_idx, 1:64), 'MEG channels should be 1-64');
assert(isequal(ref_idx, 65:67), 'Reference channels should be 65-67');
assert(stim_idx == 68, 'Stimulus should be channel 68');
assert(trig_idx == 69, 'Trigger should be channel 69');
fprintf('  ✓ All channels correctly identified for 69-column data\n');

%% Test 3: load_lvm_data error handling
fprintf('\nTest 3: Error handling\n');

% Test with non-existent file
try
    data = load_lvm_data('nonexistent_file.lvm', 4800, 2.7e-3);
    error('Should have thrown an error for non-existent file');
catch ME
    assert(contains(ME.identifier, 'FileNotFound'), 'Should throw FileNotFound error');
    fprintf('  ✓ Correctly handles non-existent file\n');
end

% Test with invalid sampling rate
try
    data = load_lvm_data('test.lvm', -100, 2.7e-3);
    error('Should have thrown an error for invalid sampling rate');
catch ME
    assert(contains(ME.identifier, 'InvalidInput'), 'Should throw InvalidInput error');
    fprintf('  ✓ Correctly validates sampling rate\n');
end

% Test with invalid gain
try
    data = load_lvm_data('test.lvm', 4800, 0);
    error('Should have thrown an error for invalid gain');
catch ME
    assert(contains(ME.identifier, 'InvalidInput'), 'Should throw InvalidInput error');
    fprintf('  ✓ Correctly validates gain parameter\n');
end

%% Test 4: MEGData structure validation
fprintf('\nTest 4: MEGData structure validation\n');

% Create a MEGData object
meg_data = MEGData();
assert(isempty(meg_data.meg_channels), 'Initial meg_channels should be empty');
assert(isempty(meg_data.ref_channels), 'Initial ref_channels should be empty');
assert(isempty(meg_data.bad_channels), 'Initial bad_channels should be empty');
fprintf('  ✓ MEGData object initializes correctly\n');

% Test set_channel_labels
meg_data = meg_data.set_channel_labels();
assert(length(meg_data.channel_labels) == 64, 'Should have 64 channel labels');
assert(strcmp(meg_data.channel_labels{1}, 'MEG001'), 'First label should be MEG001');
assert(strcmp(meg_data.channel_labels{64}, 'MEG064'), 'Last label should be MEG064');
fprintf('  ✓ Channel labels set correctly\n');

%% Summary
fprintf('\n========================================\n');
fprintf('All data loader tests passed!\n');
fprintf('========================================\n');
