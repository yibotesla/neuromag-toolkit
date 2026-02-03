% test_export_functions - Test data and figure export functions
%
% This script tests:
% - save_processed_data function (MAT file export)
% - save_figures function (PNG and PDF export)
%
% Requirements: 7.5

%% Setup
fprintf('Testing Export Functions\n');
fprintf('========================\n\n');

% Create temporary output directory
output_dir = 'test_output';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Test 1: Save MEGData structure
fprintf('Test 1: Saving MEGData structure...\n');
meg_data = MEGData();
meg_data.fs = 4800;
meg_data.gain = 1e-12;
meg_data.meg_channels = randn(64, 1000);
meg_data.ref_channels = randn(3, 1000);
meg_data.stimulus = zeros(1, 1000);
meg_data.trigger = zeros(1, 1000);
meg_data.time = (0:999) / 4800;
meg_data = meg_data.set_channel_labels();
meg_data.bad_channels = [5, 12];

try
    save_processed_data(fullfile(output_dir, 'test_meg_data.mat'), 'meg_data', meg_data);
    fprintf('  ✓ MEGData saved successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 2: Save ProcessedData structure
fprintf('\nTest 2: Saving ProcessedData structure...\n');
proc_data = ProcessedData();
proc_data.data = randn(64, 1000);
proc_data.time = (0:999) / 4800;
proc_data.fs = 4800;
proc_data.channel_labels = meg_data.channel_labels;
proc_data = proc_data.add_processing_step('DC removal');
proc_data = proc_data.add_processing_step('Adaptive filtering');

try
    save_processed_data(fullfile(output_dir, 'test_processed_data.mat'), ...
        'processed', proc_data);
    fprintf('  ✓ ProcessedData saved successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 3: Save TrialData structure
fprintf('\nTest 3: Saving TrialData structure...\n');
trial_data = TrialData();
trial_data.trials = randn(64, 100, 50);  % 64 channels, 100 samples, 50 trials
trial_data.trial_times = linspace(-0.2, 0.8, 100);
trial_data.trigger_indices = 1000:2000:100000;
trial_data.fs = 4800;
trial_data.pre_time = 0.2;
trial_data.post_time = 0.8;

try
    save_processed_data(fullfile(output_dir, 'test_trial_data.mat'), ...
        'trials', trial_data);
    fprintf('  ✓ TrialData saved successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 4: Save AnalysisResults structure
fprintf('\nTest 4: Saving AnalysisResults structure...\n');
results = AnalysisResults();
results = results.set_psd(0:0.1:100, randn(1, 1001));
results = results.set_snr(17, 15.5);
results.grand_average = randn(64, 100);
results = results.set_convergence(10:10:100, 0.5:0.05:0.95);

try
    save_processed_data(fullfile(output_dir, 'test_analysis_results.mat'), ...
        'results', results);
    fprintf('  ✓ AnalysisResults saved successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 5: Save multiple structures
fprintf('\nTest 5: Saving multiple structures...\n');
try
    save_processed_data(fullfile(output_dir, 'test_multiple.mat'), ...
        'meg', meg_data, 'processed', proc_data, 'trials', trial_data, 'results', results);
    fprintf('  ✓ Multiple structures saved successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 6: Load and verify saved data
fprintf('\nTest 6: Loading and verifying saved data...\n');
try
    loaded = load(fullfile(output_dir, 'test_meg_data.mat'));
    assert(loaded.meg_data.fs == 4800, 'Sampling rate mismatch');
    assert(isequal(loaded.meg_data.bad_channels, [5, 12]), 'Bad channels mismatch');
    fprintf('  ✓ Data loaded and verified successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 7: Save figure as PNG
fprintf('\nTest 7: Saving figure as PNG...\n');
fig1 = figure('Visible', 'off');
plot(1:100, randn(1, 100));
title('Test Figure 1');
xlabel('Sample');
ylabel('Amplitude');

try
    save_figures(fullfile(output_dir, 'test_figure'), fig1, 'Format', 'png');
    assert(exist(fullfile(output_dir, 'test_figure.png'), 'file') == 2, 'PNG file not created');
    fprintf('  ✓ Figure saved as PNG successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 8: Save figure as PDF
fprintf('\nTest 8: Saving figure as PDF...\n');
try
    save_figures(fullfile(output_dir, 'test_figure_pdf'), fig1, 'Format', 'pdf');
    assert(exist(fullfile(output_dir, 'test_figure_pdf.pdf'), 'file') == 2, 'PDF file not created');
    fprintf('  ✓ Figure saved as PDF successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 9: Save figure as both PNG and PDF
fprintf('\nTest 9: Saving figure as both PNG and PDF...\n');
try
    save_figures(fullfile(output_dir, 'test_figure_both'), fig1, 'Format', 'both');
    assert(exist(fullfile(output_dir, 'test_figure_both.png'), 'file') == 2, 'PNG file not created');
    assert(exist(fullfile(output_dir, 'test_figure_both.pdf'), 'file') == 2, 'PDF file not created');
    fprintf('  ✓ Figure saved as both formats successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Test 10: Save multiple figures
fprintf('\nTest 10: Saving multiple figures...\n');
fig2 = figure('Visible', 'off');
imagesc(randn(10, 10));
title('Test Figure 2');
colorbar;

try
    save_figures(fullfile(output_dir, 'multi_fig'), [fig1, fig2], 'Format', 'png');
    assert(exist(fullfile(output_dir, 'multi_fig_1.png'), 'file') == 2, 'First PNG not created');
    assert(exist(fullfile(output_dir, 'multi_fig_2.png'), 'file') == 2, 'Second PNG not created');
    fprintf('  ✓ Multiple figures saved successfully\n');
catch ME
    fprintf('  ✗ Failed: %s\n', ME.message);
end

%% Cleanup
close(fig1);
close(fig2);

fprintf('\n========================\n');
fprintf('All export function tests completed!\n');
fprintf('Output files saved to: %s\n', output_dir);
