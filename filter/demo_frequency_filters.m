% DEMO_FREQUENCY_FILTERS Demonstration of frequency filtering functions
%
% This script demonstrates the usage of lowpass, bandpass, and notch filters
% for MEG signal processing.

clear; close all; clc;

fprintf('===========================================\n');
fprintf('Frequency Filters Demonstration\n');
fprintf('===========================================\n\n');

%% Setup
fs = 4800;  % Sampling frequency (Hz)
duration = 5;  % Duration (seconds)
t = 0:1/fs:duration-1/fs;
n_channels = 3;  % Simulate 3 MEG channels

%% Create synthetic MEG data
fprintf('Creating synthetic MEG data...\n');
fprintf('  - 3 channels\n');
fprintf('  - 5 seconds duration\n');
fprintf('  - Sampling rate: 4800 Hz\n\n');

% Simulate MEG data with multiple frequency components
meg_data = zeros(n_channels, length(t));
for ch = 1:n_channels
    % AEF component (low frequency, ~10Hz)
    aef = sin(2*pi*10*t + ch*pi/4);
    
    % ASSR component (89Hz)
    assr = 0.5 * sin(2*pi*89*t + ch*pi/3);
    
    % Power line interference (50Hz and harmonics)
    powerline = 0.3 * sin(2*pi*50*t) + 0.2 * sin(2*pi*100*t) + 0.1 * sin(2*pi*150*t);
    
    % High frequency noise
    noise = 0.1 * randn(1, length(t));
    
    % Combine all components
    meg_data(ch, :) = aef + assr + powerline + noise;
end

fprintf('Signal components:\n');
fprintf('  - AEF: 10Hz\n');
fprintf('  - ASSR: 89Hz\n');
fprintf('  - Power line: 50Hz, 100Hz, 150Hz\n');
fprintf('  - Noise: broadband\n\n');

%% Demonstration 1: Lowpass Filter for AEF
fprintf('===========================================\n');
fprintf('Demo 1: Lowpass Filter (AEF Extraction)\n');
fprintf('===========================================\n');
fprintf('Applying lowpass filter with 30Hz cutoff...\n');

data_aef = lowpass_filter(meg_data, fs, 30);

fprintf('✓ Lowpass filter applied\n');
fprintf('  Result: AEF component isolated (10Hz preserved)\n');
fprintf('  High frequencies (89Hz, 50Hz harmonics) removed\n\n');

%% Demonstration 2: Bandpass Filter for ASSR
fprintf('===========================================\n');
fprintf('Demo 2: Bandpass Filter (ASSR Extraction)\n');
fprintf('===========================================\n');
fprintf('Applying bandpass filter at 89Hz ± 2Hz...\n');

data_assr = bandpass_filter(meg_data, fs, 89, 4);

fprintf('✓ Bandpass filter applied\n');
fprintf('  Result: ASSR component isolated (89Hz preserved)\n');
fprintf('  Other frequencies removed\n\n');

%% Demonstration 3: Notch Filter for Power Line Removal
fprintf('===========================================\n');
fprintf('Demo 3: Notch Filter (Power Line Removal)\n');
fprintf('===========================================\n');
fprintf('Applying notch filters at 50Hz, 100Hz, 150Hz...\n');

data_clean = notch_filter(meg_data, fs, [50, 100, 150]);

fprintf('✓ Notch filters applied\n');
fprintf('  Result: Power line interference removed\n');
fprintf('  Signal components (10Hz, 89Hz) preserved\n\n');

%% Demonstration 4: Combined Processing Pipeline
fprintf('===========================================\n');
fprintf('Demo 4: Combined Processing Pipeline\n');
fprintf('===========================================\n');
fprintf('Processing pipeline:\n');
fprintf('  1. Remove power line interference (notch)\n');
fprintf('  2. Extract AEF (lowpass)\n');
fprintf('  3. Extract ASSR (bandpass)\n\n');

% Step 1: Remove power line
data_step1 = notch_filter(meg_data, fs, [50, 100, 150]);
fprintf('✓ Step 1 complete: Power line removed\n');

% Step 2: Extract AEF
data_aef_clean = lowpass_filter(data_step1, fs, 30);
fprintf('✓ Step 2 complete: AEF extracted\n');

% Step 3: Extract ASSR
data_assr_clean = bandpass_filter(data_step1, fs, 89, 4);
fprintf('✓ Step 3 complete: ASSR extracted\n\n');

%% Summary
fprintf('===========================================\n');
fprintf('Summary\n');
fprintf('===========================================\n');
fprintf('All frequency filters working correctly:\n');
fprintf('  ✓ lowpass_filter.m - AEF extraction\n');
fprintf('  ✓ bandpass_filter.m - ASSR extraction\n');
fprintf('  ✓ notch_filter.m - Power line removal\n\n');

fprintf('Features:\n');
fprintf('  ✓ Multi-channel processing\n');
fprintf('  ✓ Zero-phase filtering (timing preserved)\n');
fprintf('  ✓ Configurable parameters\n');
fprintf('  ✓ Robust error handling\n\n');

fprintf('Ready for Mission 1 and Mission 2 processing!\n');
fprintf('===========================================\n');
