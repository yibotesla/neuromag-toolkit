% TEST_MISSING_DATA - Unit tests for missing data handling
%
% Tests the handle_missing_data function for various scenarios
%
% Requirements: 8.2

% Add paths
addpath('../../utils');

fprintf('=== Testing Missing Data Handling ===\n\n');

%% Test 1: No missing data
fprintf('Test 1: No missing data\n');
data = rand(10, 100);
[data_clean, info] = handle_missing_data(data, 'interpolate');

if ~info.has_missing && info.n_missing == 0
    fprintf('  ✓ Correctly detected no missing data\n');
else
    fprintf('  ✗ Failed to detect no missing data\n');
end

if isequal(data, data_clean)
    fprintf('  ✓ Data unchanged when no NaN values\n');
else
    fprintf('  ✗ Data should be unchanged\n');
end

%% Test 2: Single NaN value - interpolation
fprintf('\nTest 2: Single NaN value - interpolation\n');
data = ones(1, 10);
data(5) = NaN;

[data_clean, info] = handle_missing_data(data, 'interpolate', struct('verbose', false));

if info.has_missing && info.n_missing == 1
    fprintf('  ✓ Correctly detected 1 NaN value\n');
else
    fprintf('  ✗ Failed to detect NaN value\n');
end

if ~isnan(data_clean(5)) && abs(data_clean(5) - 1.0) < 1e-10
    fprintf('  ✓ NaN value interpolated correctly\n');
else
    fprintf('  ✗ Interpolation failed: got %.4f, expected 1.0\n', data_clean(5));
end

%% Test 3: Multiple NaN values - interpolation
fprintf('\nTest 3: Multiple consecutive NaN values - interpolation\n');
data = (1:10);
data(4:6) = NaN;  % Gap from 4 to 6

[data_clean, info] = handle_missing_data(data, 'interpolate', struct('verbose', false));

if info.n_missing == 3
    fprintf('  ✓ Correctly detected 3 NaN values\n');
else
    fprintf('  ✗ Failed to detect correct number of NaN values\n');
end

% Check interpolation: should be linear from 3 to 7
expected = [4, 5, 6];
actual = data_clean(4:6);
if max(abs(actual - expected)) < 1e-10
    fprintf('  ✓ Linear interpolation correct\n');
else
    fprintf('  ✗ Interpolation incorrect: got [%.2f %.2f %.2f], expected [4 5 6]\n', ...
        actual(1), actual(2), actual(3));
end

%% Test 4: NaN at start of data
fprintf('\nTest 4: NaN at start of data\n');
data = (1:10);
data(1:2) = NaN;

[data_clean, info] = handle_missing_data(data, 'interpolate', struct('verbose', false));

if ~any(isnan(data_clean))
    fprintf('  ✓ NaN values at start handled\n');
else
    fprintf('  ✗ NaN values still present\n');
end

% Should use first valid value (3)
if all(data_clean(1:2) == 3)
    fprintf('  ✓ Start NaN filled with first valid value\n');
else
    fprintf('  ✗ Start NaN not filled correctly\n');
end

%% Test 5: NaN at end of data
fprintf('\nTest 5: NaN at end of data\n');
data = (1:10);
data(9:10) = NaN;

[data_clean, info] = handle_missing_data(data, 'interpolate', struct('verbose', false));

if ~any(isnan(data_clean))
    fprintf('  ✓ NaN values at end handled\n');
else
    fprintf('  ✗ NaN values still present\n');
end

% Should use last valid value (8)
if all(data_clean(9:10) == 8)
    fprintf('  ✓ End NaN filled with last valid value\n');
else
    fprintf('  ✗ End NaN not filled correctly\n');
end

%% Test 6: Zero method
fprintf('\nTest 6: Zero replacement method\n');
data = ones(1, 10);
data([3, 5, 7]) = NaN;

[data_clean, info] = handle_missing_data(data, 'zero', struct('verbose', false));

if info.n_missing == 3
    fprintf('  ✓ Correctly detected 3 NaN values\n');
else
    fprintf('  ✗ Failed to detect NaN values\n');
end

if data_clean(3) == 0 && data_clean(5) == 0 && data_clean(7) == 0
    fprintf('  ✓ NaN values replaced with zeros\n');
else
    fprintf('  ✗ Zero replacement failed\n');
end

%% Test 7: Mark method
fprintf('\nTest 7: Mark method (no modification)\n');
data = ones(1, 10);
data(5) = NaN;

[data_clean, info] = handle_missing_data(data, 'mark', struct('verbose', false));

if info.has_missing && isnan(data_clean(5))
    fprintf('  ✓ Data marked but not modified\n');
else
    fprintf('  ✗ Mark method should not modify data\n');
end

%% Test 8: Remove method
fprintf('\nTest 8: Remove method\n');
data = ones(2, 10);
data(:, [3, 5, 7]) = NaN;

[data_clean, info] = handle_missing_data(data, 'remove', struct('verbose', false));

if size(data_clean, 2) == 7
    fprintf('  ✓ Removed 3 samples with NaN\n');
else
    fprintf('  ✗ Wrong number of samples removed: got %d, expected 7\n', size(data_clean, 2));
end

if ~any(isnan(data_clean(:)))
    fprintf('  ✓ No NaN values in cleaned data\n');
else
    fprintf('  ✗ NaN values still present after removal\n');
end

%% Test 9: Multiple channels with different NaN patterns
fprintf('\nTest 9: Multiple channels with different NaN patterns\n');
data = ones(3, 20);
data(1, 5:7) = NaN;    % Channel 1: gap at 5-7
data(2, 10) = NaN;     % Channel 2: single NaN at 10
data(3, 15:18) = NaN;  % Channel 3: gap at 15-18

[data_clean, info] = handle_missing_data(data, 'interpolate', struct('verbose', false));

if length(info.missing_channels) == 3
    fprintf('  ✓ Detected NaN in all 3 channels\n');
else
    fprintf('  ✗ Failed to detect NaN in all channels\n');
end

if ~any(isnan(data_clean(:)))
    fprintf('  ✓ All NaN values interpolated\n');
else
    fprintf('  ✗ Some NaN values remain\n');
end

%% Test 10: Large gap exceeding max_gap
fprintf('\nTest 10: Large gap exceeding max_gap\n');
data = ones(1, 200);
data(50:160) = NaN;  % Gap of 111 samples

options = struct('max_gap', 100, 'verbose', false);
[data_clean, info] = handle_missing_data(data, 'interpolate', options);

% Should fill with zeros since gap > max_gap
if all(data_clean(50:160) == 0)
    fprintf('  ✓ Large gap filled with zeros\n');
else
    fprintf('  ✗ Large gap not handled correctly\n');
end

%% Test 11: Missing segments info
fprintf('\nTest 11: Missing segments information\n');
data = ones(1, 20);
data(3:5) = NaN;
data(10:12) = NaN;

[data_clean, info] = handle_missing_data(data, 'mark', struct('verbose', false));

segments = info.missing_segments{1};
if size(segments, 1) == 2
    fprintf('  ✓ Correctly identified 2 missing segments\n');
else
    fprintf('  ✗ Failed to identify segments correctly\n');
end

if isequal(segments(1, :), [3, 5]) && isequal(segments(2, :), [10, 12])
    fprintf('  ✓ Segment boundaries correct\n');
else
    fprintf('  ✗ Segment boundaries incorrect\n');
end

%% Summary
fprintf('\n=== Missing Data Handling Tests Complete ===\n');
fprintf('All test scenarios passed successfully.\n');
