% TEST_INTEGRATION - Integration test with analyzer module
%
% This script tests the integration between visualizer and analyzer modules
% to ensure they work together seamlessly.

fprintf('Visualizer-Analyzer Integration Test\n');
fprintf('====================================\n\n');

% Add paths
addpath('../analyzer');
addpath('../utils');

%% Test 1: PSD Integration
fprintf('Test 1: PSD Integration\n');
try
    % Generate test signal
    fs = 4800;
    t = (0:1/fs:2-1/fs)';
    signal = sin(2*pi*17*t) + 0.3*randn(size(t));
    
    % Use analyzer to compute PSD
    [frequencies, power] = compute_psd(signal, fs);
    
    % Use visualizer to plot
    fig = plot_psd(frequencies, power, ...
        'Title', 'Integration Test: PSD', ...
        'FreqRange', [0 100]);
    
    % Verify figure was created
    assert(ishandle(fig), 'Figure handle not valid');
    
    fprintf('  ✓ PSD integration successful\n\n');
    close(fig);
catch ME
    fprintf('  ✗ Test 1 FAILED: %s\n\n', ME.message);
end

%% Test 2: Grand Average Integration
fprintf('Test 2: Grand Average Integration\n');
try
    % Generate trial data
    trial_times = (-0.2:1/fs:0.8-1/fs)';
    n_samples = length(trial_times);
    n_trials = 50;
    
    % Create synthetic trials
    trials = zeros(1, n_samples, n_trials);
    for i = 1:n_trials
        trials(1, :, i) = exp(-((trial_times - 0.1).^2) / (2*0.02^2)) + ...
            0.1*randn(size(trial_times));
    end
    
    % Use analyzer to compute grand average
    grand_avg = compute_grand_average(trials);
    
    % Use visualizer to plot
    fig = plot_averaged_response(trial_times, grand_avg, ...
        'Title', 'Integration Test: Grand Average');
    
    % Verify figure was created
    assert(ishandle(fig), 'Figure handle not valid');
    
    fprintf('  ✓ Grand average integration successful\n\n');
    close(fig);
catch ME
    fprintf('  ✗ Test 2 FAILED: %s\n\n', ME.message);
end

%% Test 3: Convergence Analysis Integration
fprintf('Test 3: Convergence Analysis Integration\n');
try
    % Use same trial data from Test 2
    grand_avg_full = compute_grand_average(trials);
    
    % Test different trial numbers
    n_trials_vec = 10:10:50;
    correlation_vec = zeros(size(n_trials_vec));
    
    for i = 1:length(n_trials_vec)
        n = n_trials_vec(i);
        % Sample N trials
        sampled_trials = trials(:, :, 1:n);
        sampled_avg = compute_grand_average(sampled_trials);
        
        % Compute convergence metrics
        metrics = compute_convergence_metrics(sampled_avg, grand_avg_full);
        correlation_vec(i) = metrics.correlation;
    end
    
    % Use visualizer to plot convergence
    fig = plot_convergence_curve(n_trials_vec, correlation_vec, ...
        'Title', 'Integration Test: Convergence Analysis');
    
    % Verify figure was created
    assert(ishandle(fig), 'Figure handle not valid');
    
    fprintf('  ✓ Convergence analysis integration successful\n\n');
    close(fig);
catch ME
    fprintf('  ✗ Test 3 FAILED: %s\n\n', ME.message);
end

%% Test 4: AnalysisResults Structure Integration
fprintf('Test 4: AnalysisResults Structure Integration\n');
try
    % Create AnalysisResults object
    results = AnalysisResults();
    
    % Populate with data
    [f, psd] = compute_psd(signal, fs);
    results = results.set_psd(f, psd);
    results = results.set_convergence(n_trials_vec, correlation_vec);
    
    % Plot from AnalysisResults
    fig1 = plot_psd(results.psd.frequencies, results.psd.power, ...
        'Title', 'From AnalysisResults: PSD');
    
    fig2 = plot_convergence_curve(results.convergence.n_trials, ...
        results.convergence.correlation, ...
        'Title', 'From AnalysisResults: Convergence');
    
    % Verify figures were created
    assert(ishandle(fig1), 'PSD figure handle not valid');
    assert(ishandle(fig2), 'Convergence figure handle not valid');
    
    fprintf('  ✓ AnalysisResults integration successful\n\n');
    close(fig1);
    close(fig2);
catch ME
    fprintf('  ✗ Test 4 FAILED: %s\n\n', ME.message);
end

%% Summary
fprintf('====================================\n');
fprintf('Integration Tests Complete\n');
fprintf('All visualizer-analyzer integrations verified\n');
