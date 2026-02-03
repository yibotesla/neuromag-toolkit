% test_roundtrip - Test round-trip property for data export/import
%
% This test validates Property 28 from the design document:
% "For any processed data saved to .mat format, loading the file should 
% recover data that is numerically equal to the original (within 
% floating-point precision)"
%
% Requirements: 7.5

fprintf('Testing Round-Trip Property (Property 28)\n');
fprintf('=========================================\n\n');

% Set tolerance for floating-point comparison
tol = 1e-10;

%% Test 1: MEGData round-trip
fprintf('Test 1: MEGData round-trip...\n');

% Create original data
orig_meg = MEGData();
orig_meg.fs = 4800;
orig_meg.gain = 1e-12;
orig_meg.meg_channels = randn(64, 1000);
orig_meg.ref_channels = randn(3, 1000);
orig_meg.stimulus = randn(1, 1000);
orig_meg.trigger = zeros(1, 1000);
orig_meg.trigger([100, 300, 500]) = 1;
orig_meg.time = (0:999) / 4800;
orig_meg = orig_meg.set_channel_labels();
orig_meg.bad_channels = [5, 12, 23];

% Save and load
temp_file = 'temp_roundtrip_test.mat';
save_processed_data(temp_file, 'meg_data', orig_meg);
loaded = load(temp_file);
loaded_meg = loaded.meg_data;

% Compare
assert(loaded_meg.fs == orig_meg.fs, 'Sampling rate mismatch');
assert(loaded_meg.gain == orig_meg.gain, 'Gain mismatch');
assert(max(abs(loaded_meg.meg_channels(:) - orig_meg.meg_channels(:))) < tol, ...
    'MEG channels data mismatch');
assert(max(abs(loaded_meg.ref_channels(:) - orig_meg.ref_channels(:))) < tol, ...
    'Reference channels data mismatch');
assert(max(abs(loaded_meg.stimulus(:) - orig_meg.stimulus(:))) < tol, ...
    'Stimulus data mismatch');
assert(max(abs(loaded_meg.trigger(:) - orig_meg.trigger(:))) < tol, ...
    'Trigger data mismatch');
assert(max(abs(loaded_meg.time(:) - orig_meg.time(:))) < tol, ...
    'Time axis mismatch');
assert(isequal(loaded_meg.bad_channels, orig_meg.bad_channels), ...
    'Bad channels mismatch');

fprintf('  ✓ MEGData round-trip successful (max error: %.2e)\n', ...
    max(abs(loaded_meg.meg_channels(:) - orig_meg.meg_channels(:))));

delete(temp_file);

%% Test 2: ProcessedData round-trip
fprintf('\nTest 2: ProcessedData round-trip...\n');

orig_proc = ProcessedData();
orig_proc.data = randn(64, 1000);
orig_proc.time = (0:999) / 4800;
orig_proc.fs = 4800;
orig_proc.channel_labels = orig_meg.channel_labels;
orig_proc = orig_proc.add_processing_step('Step 1');
orig_proc = orig_proc.add_processing_step('Step 2');

save_processed_data(temp_file, 'proc_data', orig_proc);
loaded = load(temp_file);
loaded_proc = loaded.proc_data;

assert(loaded_proc.fs == orig_proc.fs, 'Sampling rate mismatch');
assert(max(abs(loaded_proc.data(:) - orig_proc.data(:))) < tol, ...
    'Data mismatch');
assert(max(abs(loaded_proc.time(:) - orig_proc.time(:))) < tol, ...
    'Time axis mismatch');
assert(length(loaded_proc.processing_log) == length(orig_proc.processing_log), ...
    'Processing log length mismatch');

fprintf('  ✓ ProcessedData round-trip successful (max error: %.2e)\n', ...
    max(abs(loaded_proc.data(:) - orig_proc.data(:))));

delete(temp_file);

%% Test 3: TrialData round-trip
fprintf('\nTest 3: TrialData round-trip...\n');

orig_trial = TrialData();
orig_trial.trials = randn(64, 100, 50);
orig_trial.trial_times = linspace(-0.2, 0.8, 100);
orig_trial.trigger_indices = 1000:2000:100000;
orig_trial.fs = 4800;
orig_trial.pre_time = 0.2;
orig_trial.post_time = 0.8;

save_processed_data(temp_file, 'trial_data', orig_trial);
loaded = load(temp_file);
loaded_trial = loaded.trial_data;

assert(loaded_trial.fs == orig_trial.fs, 'Sampling rate mismatch');
assert(loaded_trial.pre_time == orig_trial.pre_time, 'Pre-time mismatch');
assert(loaded_trial.post_time == orig_trial.post_time, 'Post-time mismatch');
assert(max(abs(loaded_trial.trials(:) - orig_trial.trials(:))) < tol, ...
    'Trials data mismatch');
assert(max(abs(loaded_trial.trial_times(:) - orig_trial.trial_times(:))) < tol, ...
    'Trial times mismatch');
assert(isequal(loaded_trial.trigger_indices, orig_trial.trigger_indices), ...
    'Trigger indices mismatch');

fprintf('  ✓ TrialData round-trip successful (max error: %.2e)\n', ...
    max(abs(loaded_trial.trials(:) - orig_trial.trials(:))));

delete(temp_file);

%% Test 4: AnalysisResults round-trip
fprintf('\nTest 4: AnalysisResults round-trip...\n');

orig_results = AnalysisResults();
orig_results = orig_results.set_psd(0:0.1:100, randn(1, 1001));
orig_results = orig_results.set_snr(17, 15.5);
orig_results.grand_average = randn(64, 100);
orig_results = orig_results.set_convergence(10:10:100, 0.5:0.05:0.95);

save_processed_data(temp_file, 'results', orig_results);
loaded = load(temp_file);
loaded_results = loaded.results;

assert(max(abs(loaded_results.psd.frequencies(:) - orig_results.psd.frequencies(:))) < tol, ...
    'PSD frequencies mismatch');
assert(max(abs(loaded_results.psd.power(:) - orig_results.psd.power(:))) < tol, ...
    'PSD power mismatch');
assert(loaded_results.snr.frequency == orig_results.snr.frequency, ...
    'SNR frequency mismatch');
assert(abs(loaded_results.snr.snr_db - orig_results.snr.snr_db) < tol, ...
    'SNR value mismatch');
assert(max(abs(loaded_results.grand_average(:) - orig_results.grand_average(:))) < tol, ...
    'Grand average mismatch');
assert(isequal(loaded_results.convergence.n_trials, orig_results.convergence.n_trials), ...
    'Convergence n_trials mismatch');
assert(max(abs(loaded_results.convergence.correlation(:) - orig_results.convergence.correlation(:))) < tol, ...
    'Convergence correlation mismatch');

fprintf('  ✓ AnalysisResults round-trip successful (max error: %.2e)\n', ...
    max(abs(loaded_results.grand_average(:) - orig_results.grand_average(:))));

delete(temp_file);

%% Test 5: Multiple structures round-trip
fprintf('\nTest 5: Multiple structures round-trip...\n');

save_processed_data(temp_file, ...
    'meg', orig_meg, ...
    'proc', orig_proc, ...
    'trial', orig_trial, ...
    'results', orig_results);

loaded = load(temp_file);

% Verify all structures are present
assert(isfield(loaded, 'meg'), 'MEG data not found');
assert(isfield(loaded, 'proc'), 'Processed data not found');
assert(isfield(loaded, 'trial'), 'Trial data not found');
assert(isfield(loaded, 'results'), 'Results not found');
assert(isfield(loaded, 'metadata'), 'Metadata not found');

% Spot check one value from each
assert(loaded.meg.fs == orig_meg.fs, 'MEG fs mismatch');
assert(loaded.proc.fs == orig_proc.fs, 'Proc fs mismatch');
assert(loaded.trial.fs == orig_trial.fs, 'Trial fs mismatch');
assert(loaded.results.snr.frequency == orig_results.snr.frequency, 'Results frequency mismatch');

fprintf('  ✓ Multiple structures round-trip successful\n');

delete(temp_file);

%% Summary
fprintf('\n=========================================\n');
fprintf('All round-trip tests passed!\n');
fprintf('Property 28 validated: Data integrity preserved through save/load cycle\n');
fprintf('Maximum numerical error: < %.2e (within floating-point precision)\n', tol);
