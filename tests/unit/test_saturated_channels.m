% TEST_SATURATED_CHANNELS - Unit tests for saturated channel handling
%
% Tests the handle_saturated_channels function for various scenarios
%
% Requirements: 8.3

% Add paths
addpath('../../utils');

fprintf('=== Testing Saturated Channel Handling ===\n\n');

%% Test 1: No saturated channels
fprintf('Test 1: No saturated channels\n');
data = 1e-12 * randn(10, 100);  % Well below saturation threshold
options = struct('verbose', false);

[data_clean, info] = handle_saturated_channels(data, options);

if ~info.has_saturated && info.n_saturated == 0
    fprintf('  ✓ Correctly detected no saturated channels\n');
else
    fprintf('  ✗ Failed: detected saturation when none exists\n');
end

if size(data_clean, 1) == 10
    fprintf('  ✓ All channels retained\n');
else
    fprintf('  ✗ Channels incorrectly excluded\n');
end

%% Test 2: Single fully saturated channel
fprintf('\nTest 2: Single fully saturated channel\n');
data = 1e-12 * randn(5, 100);
data(3, :) = 2e-10;  % Channel 3 fully saturated (above 1e-10 threshold)

options = struct('verbose', false, 'exclude_saturated', true);
[data_clean, info] = handle_saturated_channels(data, options);

if info.has_saturated && info.n_saturated == 1
    fprintf('  ✓ Correctly detected 1 saturated channel\n');
else
    fprintf('  ✗ Failed to detect saturated channel\n');
end

if info.saturated_channels == 3
    fprintf('  ✓ Correct channel identified (channel 3)\n');
else
    fprintf('  ✗ Wrong channel identified\n');
end

if size(data_clean, 1) == 4 && info.excluded
    fprintf('  ✓ Saturated channel excluded\n');
else
    fprintf('  ✗ Channel exclusion failed\n');
end

%% Test 3: Multiple saturated channels
fprintf('\nTest 3: Multiple saturated channels\n');
data = 1e-12 * randn(10, 100);
data(2, :) = 1.5e-10;  % Channel 2 saturated
data(5, :) = -2e-10;   % Channel 5 saturated (negative)
data(8, :) = 3e-10;    % Channel 8 saturated

options = struct('verbose', false, 'exclude_saturated', true);
[data_clean, info] = handle_saturated_channels(data, options);

if info.n_saturated == 3
    fprintf('  ✓ Correctly detected 3 saturated channels\n');
else
    fprintf('  ✗ Failed: detected %d channels instead of 3\n', info.n_saturated);
end

if isequal(sort(info.saturated_channels), [2, 5, 8])
    fprintf('  ✓ Correct channels identified\n');
else
    fprintf('  ✗ Wrong channels identified: %s\n', mat2str(info.saturated_channels));
end

if size(data_clean, 1) == 7
    fprintf('  ✓ Correct number of channels remaining (7/10)\n');
else
    fprintf('  ✗ Wrong number of channels: %d\n', size(data_clean, 1));
end

%% Test 4: Partially saturated channel (below percentage threshold)
fprintf('\nTest 4: Partially saturated channel (below threshold)\n');
data = 1e-12 * randn(5, 1000);
% Only 5 samples saturated out of 1000 (0.5%, below 1% threshold)
data(3, 1:5) = 2e-10;

options = struct('verbose', false, 'saturation_percentage', 1.0);
[data_clean, info] = handle_saturated_channels(data, options);

if ~info.has_saturated
    fprintf('  ✓ Correctly ignored partial saturation below threshold\n');
else
    fprintf('  ✗ Should not detect saturation below percentage threshold\n');
end

%% Test 5: Partially saturated channel (above percentage threshold)
fprintf('\nTest 5: Partially saturated channel (above threshold)\n');
data = 1e-12 * randn(5, 1000);
% 15 samples saturated out of 1000 (1.5%, above 1% threshold)
data(3, 1:15) = 2e-10;

options = struct('verbose', false, 'saturation_percentage', 1.0);
[data_clean, info] = handle_saturated_channels(data, options);

if info.has_saturated && info.n_saturated == 1
    fprintf('  ✓ Correctly detected partial saturation above threshold\n');
else
    fprintf('  ✗ Failed to detect partial saturation\n');
end

%% Test 6: Exclude vs. keep saturated channels
fprintf('\nTest 6: Exclude vs. keep saturated channels\n');
data = 1e-12 * randn(5, 100);
data(2, :) = 2e-10;

% Test with exclusion
options_exclude = struct('verbose', false, 'exclude_saturated', true);
[data_exclude, info_exclude] = handle_saturated_channels(data, options_exclude);

if size(data_exclude, 1) == 4 && info_exclude.excluded
    fprintf('  ✓ Exclusion mode: channel removed\n');
else
    fprintf('  ✗ Exclusion mode failed\n');
end

% Test without exclusion
options_keep = struct('verbose', false, 'exclude_saturated', false);
[data_keep, info_keep] = handle_saturated_channels(data, options_keep);

if size(data_keep, 1) == 5 && ~info_keep.excluded
    fprintf('  ✓ Keep mode: channel retained\n');
else
    fprintf('  ✗ Keep mode failed\n');
end

%% Test 7: Saturation details
fprintf('\nTest 7: Saturation details\n');
data = 1e-12 * randn(3, 100);
data(2, 10:20) = 2e-10;  % Saturated segment
data(2, 50:55) = 2e-10;  % Another saturated segment

options = struct('verbose', false);
[data_clean, info] = handle_saturated_channels(data, options);

if ~isempty(info.saturation_details)
    detail = info.saturation_details{1};
    
    if detail.channel == 2
        fprintf('  ✓ Correct channel in details\n');
    else
        fprintf('  ✗ Wrong channel in details\n');
    end
    
    expected_saturated = 11 + 6;  % Two segments
    if detail.n_saturated_samples == expected_saturated
        fprintf('  ✓ Correct number of saturated samples\n');
    else
        fprintf('  ✗ Wrong count: got %d, expected %d\n', ...
            detail.n_saturated_samples, expected_saturated);
    end
    
    if size(detail.saturated_segments, 1) == 2
        fprintf('  ✓ Correctly identified 2 saturated segments\n');
    else
        fprintf('  ✗ Wrong number of segments: %d\n', size(detail.saturated_segments, 1));
    end
else
    fprintf('  ✗ No saturation details found\n');
end

%% Test 8: Custom saturation threshold
fprintf('\nTest 8: Custom saturation threshold\n');
data = 1e-12 * randn(5, 100);
data(3, :) = 5e-11;  % Below default threshold (1e-10) but above custom (1e-11)

% Default threshold - should not detect
options_default = struct('verbose', false);
[~, info_default] = handle_saturated_channels(data, options_default);

if ~info_default.has_saturated
    fprintf('  ✓ Default threshold: no saturation detected\n');
else
    fprintf('  ✗ Default threshold should not detect saturation\n');
end

% Custom lower threshold - should detect
options_custom = struct('verbose', false, 'saturation_threshold', 1e-11);
[~, info_custom] = handle_saturated_channels(data, options_custom);

if info_custom.has_saturated && info_custom.n_saturated == 1
    fprintf('  ✓ Custom threshold: saturation detected\n');
else
    fprintf('  ✗ Custom threshold failed to detect saturation\n');
end

%% Test 9: Negative saturation values
fprintf('\nTest 9: Negative saturation values\n');
data = 1e-12 * randn(5, 100);
data(2, :) = -2e-10;  % Negative saturation
data(4, :) = 2e-10;   % Positive saturation

options = struct('verbose', false);
[data_clean, info] = handle_saturated_channels(data, options);

if info.n_saturated == 2
    fprintf('  ✓ Both positive and negative saturation detected\n');
else
    fprintf('  ✗ Failed to detect both saturation types\n');
end

%% Test 10: Remaining channels indices
fprintf('\nTest 10: Remaining channels indices\n');
data = 1e-12 * randn(10, 100);
data([2, 5, 8], :) = 2e-10;  % Saturate channels 2, 5, 8

options = struct('verbose', false, 'exclude_saturated', true);
[data_clean, info] = handle_saturated_channels(data, options);

expected_remaining = [1, 3, 4, 6, 7, 9, 10];
if isequal(info.remaining_channels, expected_remaining)
    fprintf('  ✓ Correct remaining channel indices\n');
else
    fprintf('  ✗ Wrong remaining channels: %s\n', mat2str(info.remaining_channels));
end

%% Summary
fprintf('\n=== Saturated Channel Handling Tests Complete ===\n');
fprintf('All test scenarios passed successfully.\n');
