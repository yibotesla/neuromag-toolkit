% DEMO_CONVERGENCE_ANALYSIS - Demonstration of convergence analysis workflow
%
% This script demonstrates how to use the convergence analysis functions
% to determine the minimum number of trials needed for a stable average.
%
% Workflow:
%   1. Generate synthetic trial data
%   2. Compute grand average
%   3. Perform convergence analysis
%   4. Visualize results

clear; clc; close all;

fprintf('=== Convergence Analysis Demonstration ===\n\n');

%% Step 1: Generate synthetic trial data
fprintf('Step 1: Generating synthetic trial data...\n');

% Parameters
fs = 4800;  % Sampling rate (Hz)
n_channels = 64;  % Number of MEG channels
n_trials = 100;  % Total number of trials
pre_time = 0.2;  % Time before trigger (s)
post_time = 1.3;  % Time after trigger (s)

% Time axis
n_samples_per_trial = round((pre_time + post_time) * fs);
trial_times = linspace(-pre_time, post_time, n_samples_per_trial);

% Generate synthetic evoked response (AEF-like)
% M100 component: peak at ~100ms
t_peak = 0.1;  % 100ms after trigger
sigma = 0.02;  % Width of Gaussian
aef_response = exp(-((trial_times - t_peak).^2) / (2*sigma^2));

% Create trials with signal + noise
rng(42);  % For reproducibility
trials = zeros(n_channels, n_samples_per_trial, n_trials);

for trial = 1:n_trials
    for ch = 1:n_channels
        % Each channel has the same evoked response + independent noise
        signal = aef_response;
        noise = 0.5 * randn(1, n_samples_per_trial);
        trials(ch, :, trial) = signal + noise;
    end
end

fprintf('  Generated %d trials with %d channels\n', n_trials, n_channels);
fprintf('  Trial duration: %.1f seconds\n', pre_time + post_time);
fprintf('  Samples per trial: %d\n', n_samples_per_trial);

%% Step 2: Compute grand average
fprintf('\nStep 2: Computing grand average...\n');

grand_avg = compute_grand_average(trials);
fprintf('  Grand average computed from all %d trials\n', n_trials);

%% Step 3: Perform convergence analysis
fprintf('\nStep 3: Performing convergence analysis...\n');

% Define trial counts to test
trial_counts = [5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100];
threshold = 0.9;  % Correlation threshold
n_iterations = 20;  % Number of random samples per trial count

fprintf('  Testing trial counts: %s\n', mat2str(trial_counts));
fprintf('  Correlation threshold: %.2f\n', threshold);
fprintf('  Iterations per trial count: %d\n', n_iterations);

% Determine minimum trials
tic;
[min_trials, conv_data] = determine_minimum_trials(trials, threshold, trial_counts, n_iterations);
elapsed = toc;

fprintf('  Analysis completed in %.2f seconds\n', elapsed);
fprintf('  Minimum trials needed: %d\n', min_trials);

%% Step 4: Visualize results
fprintf('\nStep 4: Visualizing results...\n');

figure('Name', 'Convergence Analysis Demo', 'Position', [100, 100, 1200, 800]);

% Subplot 1: Example trials and grand average
subplot(2, 3, 1);
plot(trial_times, squeeze(trials(1, :, 1:5)), 'Color', [0.7, 0.7, 0.7]);
hold on;
plot(trial_times, grand_avg(1, :), 'r-', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Amplitude');
title('Example Trials vs Grand Average (Channel 1)');
legend('Individual trials', '', '', '', '', 'Grand average', 'Location', 'best');
grid on;

% Subplot 2: Sampled averages with different N
subplot(2, 3, 2);
colors = lines(4);
n_test = [5, 10, 20, 50];
for i = 1:length(n_test)
    sampled = sample_trials(trials, n_test(i));
    plot(trial_times, sampled(1, :), 'Color', colors(i, :), 'LineWidth', 1.5);
    hold on;
end
plot(trial_times, grand_avg(1, :), 'k--', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Amplitude');
title('Sampled Averages vs Grand Average');
legend('N=5', 'N=10', 'N=20', 'N=50', 'Grand avg', 'Location', 'best');
grid on;

% Subplot 3: Correlation vs number of trials
subplot(2, 3, 4);
errorbar(conv_data.n_trials, conv_data.correlation, conv_data.correlation_std, ...
    'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
yline(threshold, 'r--', sprintf('Threshold = %.2f', threshold), 'LineWidth', 2);
xline(min_trials, 'g--', sprintf('Min trials = %d', min_trials), 'LineWidth', 2);
xlabel('Number of Trials');
ylabel('Correlation Coefficient');
title('Convergence: Correlation vs Trial Count');
grid on;
ylim([0.5, 1.05]);

% Subplot 4: RMSE vs number of trials
subplot(2, 3, 5);
errorbar(conv_data.n_trials, conv_data.rmse, conv_data.rmse_std, ...
    'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
xline(min_trials, 'g--', sprintf('Min trials = %d', min_trials), 'LineWidth', 2);
xlabel('Number of Trials');
ylabel('RMSE');
title('Convergence: RMSE vs Trial Count');
grid on;

% Subplot 5: Correlation improvement rate
subplot(2, 3, 6);
if length(conv_data.n_trials) > 1
    % Calculate rate of change
    delta_corr = diff(conv_data.correlation);
    delta_n = diff(conv_data.n_trials);
    rate = delta_corr ./ delta_n;
    
    plot(conv_data.n_trials(2:end), rate, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('Number of Trials');
    ylabel('Δ Correlation / Δ Trials');
    title('Rate of Convergence Improvement');
    grid on;
    yline(0, 'k--');
end

% Subplot 6: Summary statistics
subplot(2, 3, 3);
axis off;
text(0.1, 0.9, 'Convergence Analysis Summary', 'FontSize', 14, 'FontWeight', 'bold');
text(0.1, 0.75, sprintf('Total trials available: %d', n_trials), 'FontSize', 11);
text(0.1, 0.65, sprintf('Minimum trials needed: %d', min_trials), 'FontSize', 11);
text(0.1, 0.55, sprintf('Correlation threshold: %.2f', threshold), 'FontSize', 11);
text(0.1, 0.45, sprintf('Efficiency: %.1f%%', 100*min_trials/n_trials), 'FontSize', 11);
text(0.1, 0.35, sprintf('Analysis time: %.2f s', elapsed), 'FontSize', 11);

% Add interpretation
text(0.1, 0.20, 'Interpretation:', 'FontSize', 11, 'FontWeight', 'bold');
if min_trials < n_trials * 0.3
    interp = 'Excellent: Few trials needed';
elseif min_trials < n_trials * 0.5
    interp = 'Good: Moderate trials needed';
else
    interp = 'Fair: Many trials needed';
end
text(0.1, 0.10, interp, 'FontSize', 11, 'Color', 'b');

fprintf('  Visualization complete\n');

%% Step 5: Demonstrate metric calculation
fprintf('\nStep 5: Demonstrating metric calculation...\n');

% Sample different numbers of trials and compute metrics
test_n = [5, 10, 20, 50, 100];
fprintf('\n  Trial Count | Correlation | RMSE\n');
fprintf('  ------------|-------------|----------\n');

for n = test_n
    if n <= n_trials
        sampled = sample_trials(trials, n);
        metrics = compute_convergence_metrics(sampled, grand_avg);
        fprintf('  %11d | %11.4f | %10.6f\n', n, metrics.correlation, metrics.rmse);
    end
end

%% Summary
fprintf('\n=== Demonstration Complete ===\n');
fprintf('\nKey Findings:\n');
fprintf('  - With %d total trials, only %d trials are needed\n', n_trials, min_trials);
fprintf('  - This represents %.1f%% of the total trials\n', 100*min_trials/n_trials);
fprintf('  - Correlation improves from %.3f (N=5) to %.3f (N=%d)\n', ...
    conv_data.correlation(1), conv_data.correlation(end), n_trials);
fprintf('\nThe convergence analysis helps optimize experimental design by\n');
fprintf('determining the minimum number of trials needed for reliable results.\n');
