function tests = test_data_structures()
    % test_data_structures - Unit tests for core data structures
    %
    % Tests MEGData, ProcessedData, TrialData, and AnalysisResults classes
    
    tests = functiontests(localfunctions);
end

function test_MEGData_creation(testCase)
    % Test MEGData object creation and initialization
    meg_data = MEGData();
    
    % Verify all fields are initialized
    verifyEmpty(testCase, meg_data.meg_channels);
    verifyEmpty(testCase, meg_data.ref_channels);
    verifyEmpty(testCase, meg_data.stimulus);
    verifyEmpty(testCase, meg_data.trigger);
    verifyEmpty(testCase, meg_data.time);
    verifyEmpty(testCase, meg_data.fs);
    verifyEmpty(testCase, meg_data.gain);
    verifyEmpty(testCase, meg_data.bad_channels);
    verifyEqual(testCase, length(meg_data.channel_labels), 64);
end

function test_MEGData_set_channel_labels(testCase)
    % Test channel label generation
    meg_data = MEGData();
    meg_data = meg_data.set_channel_labels();
    
    % Verify labels are generated correctly
    verifyEqual(testCase, meg_data.channel_labels{1}, 'MEG001');
    verifyEqual(testCase, meg_data.channel_labels{64}, 'MEG064');
end

function test_ProcessedData_creation(testCase)
    % Test ProcessedData object creation
    proc_data = ProcessedData();
    
    % Verify initialization
    verifyEmpty(testCase, proc_data.data);
    verifyEmpty(testCase, proc_data.time);
    verifyEmpty(testCase, proc_data.fs);
    verifyEmpty(testCase, proc_data.channel_labels);
    verifyEmpty(testCase, proc_data.processing_log);
end

function test_ProcessedData_add_processing_step(testCase)
    % Test adding processing steps to log
    proc_data = ProcessedData();
    proc_data = proc_data.add_processing_step('DC removal applied');
    
    % Verify log entry was added
    verifyEqual(testCase, length(proc_data.processing_log), 1);
    verifyTrue(testCase, contains(proc_data.processing_log{1}, 'DC removal applied'));
end

function test_TrialData_creation(testCase)
    % Test TrialData object creation
    trial_data = TrialData();
    
    % Verify initialization
    verifyEmpty(testCase, trial_data.trials);
    verifyEmpty(testCase, trial_data.trial_times);
    verifyEmpty(testCase, trial_data.trigger_indices);
    verifyEmpty(testCase, trial_data.fs);
    verifyEmpty(testCase, trial_data.pre_time);
    verifyEmpty(testCase, trial_data.post_time);
end

function test_TrialData_get_n_trials(testCase)
    % Test getting number of trials
    trial_data = TrialData();
    
    % Empty trials
    verifyEqual(testCase, trial_data.get_n_trials(), 0);
    
    % With data
    trial_data.trials = rand(64, 100, 50);  % 64 channels, 100 samples, 50 trials
    verifyEqual(testCase, trial_data.get_n_trials(), 50);
end

function test_TrialData_get_n_channels(testCase)
    % Test getting number of channels
    trial_data = TrialData();
    
    % Empty trials
    verifyEqual(testCase, trial_data.get_n_channels(), 0);
    
    % With data
    trial_data.trials = rand(64, 100, 50);
    verifyEqual(testCase, trial_data.get_n_channels(), 64);
end

function test_AnalysisResults_creation(testCase)
    % Test AnalysisResults object creation
    results = AnalysisResults();
    
    % Verify initialization
    verifyTrue(testCase, isstruct(results.psd));
    verifyTrue(testCase, isstruct(results.snr));
    verifyEmpty(testCase, results.grand_average);
    verifyTrue(testCase, isstruct(results.convergence));
end

function test_AnalysisResults_set_psd(testCase)
    % Test setting PSD results
    results = AnalysisResults();
    freqs = 0:0.1:100;
    power = rand(size(freqs));
    
    results = results.set_psd(freqs, power);
    
    % Verify PSD was set correctly
    verifyEqual(testCase, results.psd.frequencies, freqs);
    verifyEqual(testCase, results.psd.power, power);
end

function test_AnalysisResults_set_snr(testCase)
    % Test setting SNR results
    results = AnalysisResults();
    results = results.set_snr(17, 15.5);
    
    % Verify SNR was set correctly
    verifyEqual(testCase, results.snr.frequency, 17);
    verifyEqual(testCase, results.snr.snr_db, 15.5);
end

function test_AnalysisResults_set_convergence(testCase)
    % Test setting convergence results
    results = AnalysisResults();
    n_trials = 10:10:100;
    correlation = rand(size(n_trials));
    
    results = results.set_convergence(n_trials, correlation);
    
    % Verify convergence was set correctly
    verifyEqual(testCase, results.convergence.n_trials, n_trials);
    verifyEqual(testCase, results.convergence.correlation, correlation);
end
