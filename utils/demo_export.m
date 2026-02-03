% demo_export - Demonstration of data and figure export functions
%
% This script demonstrates how to use save_processed_data and save_figures
% in a typical MEG signal processing workflow.
%
% Requirements: 7.5

%% Setup
fprintf('MEG Data Export Demo\n');
fprintf('====================\n\n');

% Create output directory
output_dir = 'demo_output';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Step 1: Create sample MEG data
fprintf('Step 1: Creating sample MEG data...\n');

% Simulate MEG data
fs = 4800;  % Sampling rate
duration = 10;  % seconds
n_samples = fs * duration;
time = (0:n_samples-1) / fs;

% Create MEGData structure
meg_data = MEGData();
meg_data.fs = fs;
meg_data.gain = 1e-12;
meg_data.time = time;

% Simulate 17Hz signal with noise (Mission 1 scenario)
signal_17hz = 0.5 * sin(2*pi*17*time);
noise = 0.1 * randn(64, n_samples);
meg_data.meg_channels = repmat(signal_17hz, 64, 1) + noise;

% Reference sensors
meg_data.ref_channels = 0.2 * randn(3, n_samples);

% Stimulus and trigger
meg_data.stimulus = zeros(1, n_samples);
meg_data.trigger = zeros(1, n_samples);
meg_data.trigger([1000, 3000, 5000, 7000, 9000]) = 1;  % 5 triggers

meg_data = meg_data.set_channel_labels();
meg_data.bad_channels = [];

fprintf('  Created MEGData with %d channels, %.1f seconds\n', ...
    size(meg_data.meg_channels, 1), duration);

%% Step 2: Process data
fprintf('\nStep 2: Processing data...\n');

proc_data = ProcessedData();
proc_data.data = meg_data.meg_channels;  % In real workflow, this would be filtered
proc_data.time = meg_data.time;
proc_data.fs = meg_data.fs;
proc_data.channel_labels = meg_data.channel_labels;
proc_data = proc_data.add_processing_step('DC removal');
proc_data = proc_data.add_processing_step('Bandpass filtering (15-19 Hz)');
proc_data = proc_data.add_processing_step('Adaptive noise cancellation');

fprintf('  Applied %d processing steps\n', length(proc_data.processing_log));

%% Step 3: Compute analysis results
fprintf('\nStep 3: Computing analysis results...\n');

% Compute PSD
[psd_power, psd_freq] = pwelch(meg_data.meg_channels(1,:), [], [], [], fs);

% Create AnalysisResults
results = AnalysisResults();
results = results.set_psd(psd_freq, psd_power);
results = results.set_snr(17, 12.5);  % Example SNR value

fprintf('  Computed PSD and SNR\n');

%% Step 4: Save all data to MAT file
fprintf('\nStep 4: Saving data to MAT file...\n');

save_processed_data(fullfile(output_dir, 'meg_processing_results.mat'), ...
    'raw_data', meg_data, ...
    'processed_data', proc_data, ...
    'analysis_results', results);

%% Step 5: Create and save visualizations
fprintf('\nStep 5: Creating and saving visualizations...\n');

% Figure 1: Time series
fig1 = figure('Position', [100, 100, 800, 400]);
plot(time, meg_data.meg_channels(1,:));
xlabel('Time (s)');
ylabel('Amplitude (T)');
title('MEG Channel 1 - Time Series');
grid on;

% Figure 2: Power Spectral Density
fig2 = figure('Position', [100, 100, 800, 400]);
plot(psd_freq, 10*log10(psd_power));
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('Power Spectral Density - Channel 1');
xlim([0 100]);
grid on;

% Save figures in both formats
save_figures(fullfile(output_dir, 'time_series'), fig1, 'Format', 'both', 'Resolution', 300);
save_figures(fullfile(output_dir, 'psd'), fig2, 'Format', 'both', 'Resolution', 300);

% Alternative: Save both figures at once
save_figures({fullfile(output_dir, 'fig_time'), fullfile(output_dir, 'fig_psd')}, ...
    [fig1, fig2], 'Format', 'png', 'Resolution', 600);

%% Step 6: Verify saved files
fprintf('\nStep 6: Verifying saved files...\n');

% Check MAT file
mat_file = fullfile(output_dir, 'meg_processing_results.mat');
if exist(mat_file, 'file')
    info = whos('-file', mat_file);
    fprintf('  MAT file contains %d variables:\n', length(info));
    for i = 1:length(info)
        fprintf('    - %s (%s)\n', info(i).name, info(i).class);
    end
end

% Check figure files
figure_files = {
    'time_series.png', 'time_series.pdf', ...
    'psd.png', 'psd.pdf', ...
    'fig_time.png', 'fig_psd.png'
};

fprintf('\n  Figure files created:\n');
for i = 1:length(figure_files)
    if exist(fullfile(output_dir, figure_files{i}), 'file')
        fprintf('    ✓ %s\n', figure_files{i});
    end
end

%% Cleanup
close(fig1);
close(fig2);

fprintf('\n====================\n');
fprintf('Demo completed successfully!\n');
fprintf('All files saved to: %s\n', output_dir);
fprintf('\nTo load the saved data:\n');
fprintf('  loaded = load(''%s'');\n', mat_file);
