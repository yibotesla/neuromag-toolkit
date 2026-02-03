function results = process_mission2(file_path, config, varargin)
% PROCESS_MISSION2 任务2（人类听觉数据）的完整处理流程
%
% 语法:
%   results = process_mission2(file_path, config)
%   results = process_mission2(file_path, config, 'Name', Value, ...)
%
% 输入参数:
%   file_path - 包含人类听觉数据的LVM文件路径
%               如果为'demo'，则生成合成的听觉响应数据用于测试
%   config - 配置结构体（来自config_template）
%
% 可选的名称-值对参数:
%   'PlotResults' - 是否绘制结果图（默认值: true）
%   'SaveResults' - 是否将结果保存到文件（默认值: false）
%   'OutputDir' - 结果输出目录（默认值: 'outputs/mission2'）
%   'Verbose' - 显示进度消息（默认值: true）
%
% 输出参数:
%   results - 包含以下字段的结构体:
%       .raw_data - 原始MEGData对象
%       .preprocessed - 预处理后的数据
%       .aef_filtered - AEF数据（低通滤波）
%       .assr_filtered - ASSR数据（带通滤波）
%       .trigger_indices - 检测到的触发位置
%       .aef_trials - AEF试次数据（TrialData对象）
%       .assr_trials - ASSR试次数据（TrialData对象）
%       .aef_grand_average - AEF的总平均
%       .assr_grand_average - ASSR的总平均
%       .aef_convergence - AEF的收敛分析
%       .assr_convergence - ASSR的收敛分析
%       .bad_channels - 坏通道列表
%
% 说明:
%   实现完整的任务2处理流程:
%   1. 加载LVM文件（或生成合成数据）
%   2. 预处理（直流去除、坏通道检测）
%   3. 使用参考传感器应用自适应滤波
%   4. 分为两个处理分支:
%      - AEF: 30Hz低通滤波
%      - ASSR: 89±2Hz带通滤波
%   5. 检测触发信号
%   6. 提取时程（试次）
%   7. 计算总平均
%   8. 执行收敛分析
%   9. 可视化结果
%
% 需求: 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5
%
% 示例:
%   config = config_template();
%   results = process_mission2('Mission2/data_1.lvm', config);
%   
%   % 使用合成数据的演示模式
%   results = process_mission2('demo', config);

% 解析输入参数
p = inputParser;
addRequired(p, 'file_path', @(x) ischar(x) || isstring(x));
addRequired(p, 'config', @isstruct);
addParameter(p, 'PlotResults', true, @islogical);
addParameter(p, 'SaveResults', false, @islogical);
addParameter(p, 'OutputDir', 'outputs/mission2', @ischar);
addParameter(p, 'Verbose', true, @islogical);
addParameter(p, 'UseRealDataProcessing', [], @(x) isempty(x) || islogical(x));
addParameter(p, 'DataDuration', [], @(x) isempty(x) || (isnumeric(x) && x > 0));
parse(p, file_path, config, varargin{:});

plot_results = p.Results.PlotResults;
save_results = p.Results.SaveResults;
output_dir = p.Results.OutputDir;
verbose = p.Results.Verbose;

% 确定是否使用真实数据处理流程
if isempty(p.Results.UseRealDataProcessing)
    use_real_data = isfield(config, 'opm_preprocessing') && ...
                    isfield(config.opm_preprocessing, 'use_real_data') && ...
                    config.opm_preprocessing.use_real_data;
else
    use_real_data = p.Results.UseRealDataProcessing;
end

% 数据时长限制
if isempty(p.Results.DataDuration)
    if isfield(config, 'mission2') && isfield(config.mission2, 'data_duration')
        data_duration = config.mission2.data_duration;
    else
        data_duration = inf;  % 使用全部数据
    end
else
    data_duration = p.Results.DataDuration;
end

% 初始化结果结构体
results = struct();

%% 步骤1: 加载数据
if verbose
    fprintf('=== 任务2: 人类听觉响应处理 ===\n');
    fprintf('步骤1: 加载数据...\n');
end

if strcmpi(file_path, 'demo')
    % 生成用于演示的合成数据
    if verbose
        fprintf('  生成合成的听觉响应数据...\n');
    end
    raw_data = generate_synthetic_mission2_data(config);
    use_real_data = false;  % demo模式不使用真实数据处理
elseif use_real_data
    % 使用完整的OPM双轴预处理流程
    if verbose
        fprintf('  使用完整OPM预处理流程加载文件: %s\n', file_path);
    end
    [raw_data, preprocess_info] = opm_preprocess(file_path, config, ...
        'Verbose', verbose, 'ReturnAxis', 'Z');
    results.preprocess_info = preprocess_info;
else
    % 使用简化的数据加载流程
    if verbose
        fprintf('  加载文件: %s\n', file_path);
    end
    raw_data = load_lvm_data(file_path, ...
        config.data_loading.sampling_rate, ...
        config.data_loading.gain);
end

% 数据时长裁剪（如果指定了时长限制）
if ~isinf(data_duration) && data_duration > 0
    Fs = raw_data.fs;
    samples_to_keep = round(data_duration * Fs);
    total_samples = size(raw_data.meg_channels, 2);
    
    if samples_to_keep < total_samples
        if verbose
            fprintf('  裁剪数据到 %.1f 秒 (%d -> %d 采样点)\n', ...
                data_duration, total_samples, samples_to_keep);
        end
        raw_data.meg_channels = raw_data.meg_channels(:, 1:samples_to_keep);
        raw_data.ref_channels = raw_data.ref_channels(:, 1:samples_to_keep);
        raw_data.stimulus = raw_data.stimulus(1:samples_to_keep);
        raw_data.trigger = raw_data.trigger(1:samples_to_keep);
        raw_data.time = raw_data.time(1:samples_to_keep);
    end
end

results.raw_data = raw_data;

if verbose
    fprintf('  已加载 %d 个MEG通道, %d 个采样点 (%.2f 秒)\n', ...
        size(raw_data.meg_channels, 1), ...
        size(raw_data.meg_channels, 2), ...
        length(raw_data.time));
end

%% 步骤2: 预处理
if verbose
    fprintf('\n步骤2: 预处理...\n');
end

[preprocessed, bad_channels] = preprocess_data(raw_data, config.preprocessing);
results.preprocessed = preprocessed;
results.bad_channels = bad_channels;

if verbose
    if isempty(bad_channels)
        fprintf('  未检测到坏通道\n');
    else
        fprintf('  检测到 %d 个坏通道: %s\n', ...
            length(bad_channels), mat2str(bad_channels));
    end
end

%% 步骤3: 自适应滤波
if verbose
    fprintf('\n步骤3: 应用自适应滤波...\n');
end

% 使用参考传感器进行自适应噪声消除
if strcmpi(config.adaptive_filter.algorithm, 'LMS')
    [adaptive_filtered, weights, ~] = lms_adaptive_filter(...
        preprocessed.data, raw_data.ref_channels, config.adaptive_filter);
else
    [adaptive_filtered, weights, ~] = rls_adaptive_filter(...
        preprocessed.data, raw_data.ref_channels, config.adaptive_filter);
end

results.adaptive_filtered = adaptive_filtered;
results.filter_weights = weights;

% 计算噪声降低
noise_reduction = calculate_noise_reduction(preprocessed.data, adaptive_filtered);
results.noise_reduction = noise_reduction;

if verbose
    fprintf('  使用 %s 算法完成自适应滤波\n', ...
        config.adaptive_filter.algorithm);
    fprintf('  平均噪声降低: %.2f%%\n', mean(noise_reduction));
end

%% 步骤3.5: 工频陷波（可选）
data_for_filtering = adaptive_filtered;
if isfield(config, 'filters') && isfield(config.filters, 'notch_frequencies') ...
        && ~isempty(config.filters.notch_frequencies)
    if verbose
        fprintf('\n步骤3.5: 应用工频陷波...\n');
    end
    data_for_filtering = notch_filter(...
        adaptive_filtered, raw_data.fs, ...
        config.filters.notch_frequencies, ...
        config.filters.notch_bandwidth, ...
        config.filters.notch_order);
    if verbose
        fprintf('  陷波频率: %s Hz\n', mat2str(config.filters.notch_frequencies));
    end
end

%% 步骤4: 频率特定滤波（双分支处理）
if verbose
    fprintf('\n步骤4: 应用频率特定滤波...\n');
end

% 分支1: AEF - 30Hz低通滤波
if verbose
    fprintf('  AEF分支: 在 %d Hz 进行低通滤波...\n', ...
        config.mission2.aef_cutoff);
end
aef_filtered = lowpass_filter(data_for_filtering, raw_data.fs, ...
    config.mission2.aef_cutoff);
results.aef_filtered = aef_filtered;

% 分支2: ASSR - 89±2Hz带通滤波
if verbose
    fprintf('  ASSR分支: 在 %d±%d Hz 进行带通滤波...\n', ...
        config.mission2.assr_center, config.mission2.assr_bandwidth);
end
% 带通滤波器期望总带宽（不是±），所以乘以2
assr_filtered = bandpass_filter(data_for_filtering, raw_data.fs, ...
    config.mission2.assr_center, config.mission2.assr_bandwidth * 2);
results.assr_filtered = assr_filtered;

if verbose
    fprintf('  频率特定滤波完成\n');
end

%% 步骤5: 触发检测
if verbose
    fprintf('\n步骤5: 检测触发信号...\n');
end

% 从触发通道检测触发信号
% 使用sync信号（stimulus）或digital trigger，取决于哪个有效
if max(abs(raw_data.stimulus)) > max(abs(raw_data.trigger))
    trigger_signal = raw_data.stimulus;
    if verbose
        fprintf('  使用 sync 信号检测触发\n');
    end
else
    trigger_signal = raw_data.trigger;
    if verbose
        fprintf('  使用 digital trigger 检测触发\n');
    end
end

% 获取触发检测参数
trigger_threshold = config.mission2.trigger_threshold;
min_interval = round(config.mission2.min_trigger_interval * raw_data.fs);

% 获取跳过采样数（如果配置了）
if isfield(config.mission2, 'skip_samples_after_trigger')
    skip_samples = config.mission2.skip_samples_after_trigger;
else
    skip_samples = min_interval;
end

trigger_indices = detect_triggers(trigger_signal, trigger_threshold, min_interval, ...
    'SkipSamples', skip_samples, 'Verbose', verbose);
results.trigger_indices = trigger_indices;

if verbose
    fprintf('  检测到 %d 个触发信号\n', length(trigger_indices));
    if length(trigger_indices) > 0
        trigger_times = trigger_indices / raw_data.fs;
        fprintf('  第一个触发在 %.2f s, 最后一个在 %.2f s\n', ...
            trigger_times(1), trigger_times(end));
    end
end

%% 步骤6: 提取时程（试次）
if verbose
    fprintf('\n步骤6: 提取时程...\n');
end

% 确保试次总长度为1秒
pre_time = config.mission2.pre_time;
post_time = config.mission2.post_time;
if abs((pre_time + post_time) - 1.0) > 1e-6
    if verbose
        warning('MEG:Mission2:EpochLength', ...
            '试次时长为 %.2f s，已调整为1.00 s 以满足作业要求。', pre_time + post_time);
    end
    if pre_time >= 1.0
        pre_time = 0.2;
        post_time = 0.8;
    else
        post_time = 1.0 - pre_time;
    end
end

% 提取AEF的时程
[aef_trials_data, aef_trial_times] = extract_epochs(...
    aef_filtered, trigger_indices, raw_data.fs, ...
    pre_time, post_time);

% 为AEF创建TrialData对象
aef_trials = TrialData();
aef_trials.trials = aef_trials_data;
aef_trials.trial_times = aef_trial_times;
aef_trials.trigger_indices = trigger_indices;
aef_trials.fs = raw_data.fs;
aef_trials.pre_time = pre_time;
aef_trials.post_time = post_time;
results.aef_trials = aef_trials;

% 提取ASSR的时程
[assr_trials_data, assr_trial_times] = extract_epochs(...
    assr_filtered, trigger_indices, raw_data.fs, ...
    pre_time, post_time);

% 为ASSR创建TrialData对象
assr_trials = TrialData();
assr_trials.trials = assr_trials_data;
assr_trials.trial_times = assr_trial_times;
assr_trials.trigger_indices = trigger_indices;
assr_trials.fs = raw_data.fs;
assr_trials.pre_time = pre_time;
assr_trials.post_time = post_time;
results.assr_trials = assr_trials;

if verbose
    fprintf('  为AEF提取了 %d 个试次\n', size(aef_trials_data, 3));
    fprintf('  为ASSR提取了 %d 个试次\n', size(assr_trials_data, 3));
    fprintf('  试次持续时间: %.2f s (%.2f s 前, %.2f s 后)\n', ...
        pre_time + post_time, pre_time, post_time);
end

%% 步骤7: 计算总平均
if verbose
    fprintf('\n步骤7: 计算总平均...\n');
end

% 计算AEF的总平均
aef_grand_average = compute_grand_average(aef_trials_data);
results.aef_grand_average = aef_grand_average;

% 计算ASSR的总平均
assr_grand_average = compute_grand_average(assr_trials_data);
results.assr_grand_average = assr_grand_average;

if verbose
    fprintf('  已计算AEF和ASSR的总平均\n');
end

%% 步骤8: 收敛分析
if verbose
    fprintf('\n步骤8: 执行收敛分析...\n');
end

% AEF的收敛分析
if verbose
    fprintf('  分析AEF收敛...\n');
end
aef_convergence = perform_convergence_analysis(...
    aef_trials_data, aef_grand_average, config.mission2.convergence_threshold);
results.aef_convergence = aef_convergence;

if verbose
    fprintf('    AEF的最小试次数: %d (相关性 >= %.2f)\n', ...
        aef_convergence.min_trials, config.mission2.convergence_threshold);
end

% ASSR的收敛分析
if verbose
    fprintf('  分析ASSR收敛...\n');
end
assr_convergence = perform_convergence_analysis(...
    assr_trials_data, assr_grand_average, config.mission2.convergence_threshold);
results.assr_convergence = assr_convergence;

if verbose
    fprintf('    ASSR的最小试次数: %d (相关性 >= %.2f)\n', ...
        assr_convergence.min_trials, config.mission2.convergence_threshold);
end

%% Step 9: Visualization
if plot_results
    if verbose
        fprintf('\nStep 9: Generating visualizations...\n');
    end
    
    % Create main results figure
    fig1 = figure('Name', 'Mission 2 Results - Grand Averages', ...
        'Position', [100, 100, 1400, 800]);
    
    % Plot 1: AEF Grand Average (selected channels)
    subplot(2, 3, 1);
    selected_channels = 1:min(5, size(aef_grand_average, 1));
    plot_time_series(aef_trial_times, aef_grand_average(selected_channels, :), ...
        'Title', 'AEF Grand Average (Selected Channels)', ...
        'XLabel', 'Time (s)', ...
        'YLabel', 'Amplitude (T)', ...
        'Figure', fig1);
    xline(0, 'r--', 'LineWidth', 2, 'Label', 'Trigger');
    
    % Plot 2: ASSR Grand Average (selected channels)
    subplot(2, 3, 2);
    plot_time_series(assr_trial_times, assr_grand_average(selected_channels, :), ...
        'Title', 'ASSR Grand Average (Selected Channels)', ...
        'XLabel', 'Time (s)', ...
        'YLabel', 'Amplitude (T)', ...
        'Figure', fig1);
    xline(0, 'r--', 'LineWidth', 2, 'Label', 'Trigger');
    
    % Plot 3: AEF Convergence Curve
    subplot(2, 3, 4);
    plot_convergence_curve(aef_convergence.n_trials, aef_convergence.correlation, ...
        'Title', 'AEF Convergence Analysis', ...
        'Threshold', config.mission2.convergence_threshold, ...
        'MinTrials', aef_convergence.min_trials, ...
        'Figure', fig1);
    
    % Plot 4: ASSR Convergence Curve
    subplot(2, 3, 5);
    plot_convergence_curve(assr_convergence.n_trials, assr_convergence.correlation, ...
        'Title', 'ASSR Convergence Analysis', ...
        'Threshold', config.mission2.convergence_threshold, ...
        'MinTrials', assr_convergence.min_trials, ...
        'Figure', fig1);
    
    % Plot 5: Trigger Detection
    subplot(2, 3, 3);
    time_window = [0, min(10, length(raw_data.time))];  % First 10 seconds
    time_idx = raw_data.time >= time_window(1) & raw_data.time <= time_window(2);
    plot(raw_data.time(time_idx), raw_data.trigger(time_idx), 'b-', 'LineWidth', 1.5);
    hold on;
    trigger_times = trigger_indices / raw_data.fs;
    valid_triggers = trigger_times <= time_window(2);
    if any(valid_triggers)
        plot(trigger_times(valid_triggers), ...
            raw_data.trigger(trigger_indices(valid_triggers)), ...
            'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    end
    hold off;
    xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Trigger Signal', 'FontSize', 12, 'FontWeight', 'bold');
    title('Trigger Detection (First 10s)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Plot 6: Minimum Trials Comparison
    subplot(2, 3, 6);
    bar([aef_convergence.min_trials, assr_convergence.min_trials]);
    set(gca, 'XTickLabel', {'AEF', 'ASSR'});
    ylabel('Minimum Trials', 'FontSize', 12, 'FontWeight', 'bold');
    title('Minimum Trials for Convergence', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    results.figure_main = fig1;
    
    % Create PSD comparison figure
    fig2 = figure('Name', 'Mission 2 Results - Spectral Analysis', ...
        'Position', [150, 150, 1200, 500]);
    
    % Compute PSDs
    [freq_aef, psd_aef] = compute_psd(aef_filtered, raw_data.fs);
    [freq_assr, psd_assr] = compute_psd(assr_filtered, raw_data.fs);
    
    % Plot AEF PSD
    subplot(1, 2, 1);
    psd_aef_avg = mean(psd_aef, 1);
    plot_psd(freq_aef, psd_aef_avg, ...
        'Title', 'AEF Filtered Data PSD', ...
        'FreqRange', [0, 50], ...
        'Figure', fig2);
    
    % Plot ASSR PSD
    subplot(1, 2, 2);
    psd_assr_avg = mean(psd_assr, 1);
    plot_psd(freq_assr, psd_assr_avg, ...
        'Title', 'ASSR Filtered Data PSD', ...
        'FreqRange', [70, 110], ...
        'Figure', fig2);
    hold on;
    xline(config.mission2.assr_center, 'r--', 'LineWidth', 2, 'Label', '89Hz');
    hold off;
    
    results.figure_psd = fig2;
end

%% Step 10: Save Results
if save_results
    if verbose
        fprintf('\nStep 10: Saving results...\n');
    end
    
    % Create output directory if it doesn't exist
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % Save results structure
    save(fullfile(output_dir, 'mission2_results.mat'), 'results');
    
    % Save figures if they exist
    if plot_results
        if isfield(results, 'figure_main')
            saveas(results.figure_main, fullfile(output_dir, 'mission2_grand_averages.png'));
            saveas(results.figure_main, fullfile(output_dir, 'mission2_grand_averages.pdf'));
        end
        if isfield(results, 'figure_psd')
            saveas(results.figure_psd, fullfile(output_dir, 'mission2_psd_comparison.png'));
            saveas(results.figure_psd, fullfile(output_dir, 'mission2_psd_comparison.pdf'));
        end
    end
    
    if verbose
        fprintf('  Results saved to: %s\n', output_dir);
    end
end

%% Summary
if verbose
    fprintf('\n=== Mission 2 Processing Complete ===\n');
    fprintf('Summary:\n');
    fprintf('  - Processed %d channels\n', size(aef_filtered, 1));
    fprintf('  - Bad channels: %d\n', length(bad_channels));
    fprintf('  - Detected %d triggers\n', length(trigger_indices));
    fprintf('  - Extracted %d trials\n', size(aef_trials_data, 3));
    fprintf('  - AEF minimum trials: %d\n', aef_convergence.min_trials);
    fprintf('  - ASSR minimum trials: %d\n', assr_convergence.min_trials);
    fprintf('  - Average noise reduction: %.2f%%\n', mean(noise_reduction));
end

end


%% Helper Function: Perform Convergence Analysis
function convergence = perform_convergence_analysis(trials, grand_average, threshold)
% Perform convergence analysis to determine minimum trials needed
%
% Inputs:
%   trials - N_channels × N_samples_per_trial × N_trials
%   grand_average - N_channels × N_samples_per_trial
%   threshold - Correlation threshold (default: 0.9)
%
% Outputs:
%   convergence - struct with fields:
%       .n_trials - Vector of trial numbers tested
%       .correlation - Correlation coefficients
%       .rmse - RMSE values
%       .min_trials - Minimum trials to reach threshold

n_total_trials = size(trials, 3);

% Test different numbers of trials
trial_numbers = 10:10:n_total_trials;
trial_numbers = trial_numbers(trial_numbers <= n_total_trials);

% Ensure we test at least a few points
if isempty(trial_numbers)
    trial_numbers = min(10, n_total_trials);
end

n_tests = length(trial_numbers);
correlation = zeros(1, n_tests);
rmse = zeros(1, n_tests);

% Perform multiple samples for each trial number to reduce variance
n_samples_per_test = 10;

for i = 1:n_tests
    n_trials = trial_numbers(i);
    
    % Sample multiple times and average the metrics
    corr_samples = zeros(1, n_samples_per_test);
    rmse_samples = zeros(1, n_samples_per_test);
    
    for j = 1:n_samples_per_test
        sampled_avg = sample_trials(trials, n_trials);
        metrics = compute_convergence_metrics(sampled_avg, grand_average);
        corr_samples(j) = metrics.correlation;
        rmse_samples(j) = metrics.rmse;
    end
    
    correlation(i) = mean(corr_samples);
    rmse(i) = mean(rmse_samples);
end

% Determine minimum trials using the dedicated function
% Note: determine_minimum_trials expects (trials, threshold, trial_counts, n_iterations)
[min_trials, ~] = determine_minimum_trials(trials, threshold, trial_numbers, n_samples_per_test);

% Create output structure
convergence = struct();
convergence.n_trials = trial_numbers;
convergence.correlation = correlation;
convergence.rmse = rmse;
convergence.min_trials = min_trials;
convergence.threshold = threshold;

end


%% Helper Function: Generate Synthetic Mission 2 Data
function data = generate_synthetic_mission2_data(config)
% Generate synthetic human auditory response data for testing
%
% This creates a MEGData object with:
% - 64 MEG channels containing AEF and ASSR responses
% - 3 reference channels with correlated noise
% - Stimulus and trigger channels with periodic triggers

fs = config.data_loading.sampling_rate;
duration = 20;  % 20 seconds (reduced for faster processing)
t = 0:1/fs:duration-1/fs;
n_samples = length(t);

% Initialize MEGData object
data = MEGData();
data.fs = fs;
data.gain = config.data_loading.gain;
data.time = t;

% Generate trigger signal (every 1 second)
trigger_interval = 1.0;  % seconds
n_triggers = floor(duration / trigger_interval);
trigger_samples = round((1:n_triggers) * trigger_interval * fs);
trigger_samples = trigger_samples(trigger_samples <= n_samples);

data.trigger = zeros(1, n_samples);
data.trigger(trigger_samples) = 5.0;  % Trigger amplitude

% Generate stimulus signal (same as trigger)
data.stimulus = data.trigger;

% Generate broadband noise (correlated across channels)
common_noise = 5e-12 * randn(1, n_samples);  % 5 pT RMS

% Generate reference sensor data (mostly common noise)
data.ref_channels = zeros(3, n_samples);
for i = 1:3
    data.ref_channels(i, :) = common_noise + 1e-12 * randn(1, n_samples);
end

% Generate MEG channel data with AEF and ASSR responses
data.meg_channels = zeros(64, n_samples);

for ch = 1:64
    % Start with noise
    channel_data = 0.8 * common_noise + 2e-12 * randn(1, n_samples);
    
    % Add evoked responses at each trigger
    for trig_idx = 1:length(trigger_samples)
        trig_sample = trigger_samples(trig_idx);
        
        % AEF response (low frequency, ~100ms latency)
        aef_latency = round(0.1 * fs);  % 100ms
        aef_duration = round(0.3 * fs);  % 300ms duration
        aef_start = trig_sample + aef_latency;
        aef_end = min(aef_start + aef_duration, n_samples);
        
        if aef_end <= n_samples
            aef_time = (0:aef_end-aef_start) / fs;
            % Gaussian-modulated sine wave
            aef_response = 2e-12 * sin(2*pi*10*aef_time) .* ...
                exp(-((aef_time-0.15).^2)/(2*0.05^2));
            channel_data(aef_start:aef_end) = channel_data(aef_start:aef_end) + ...
                aef_response * (0.5 + 0.5*rand());
        end
        
        % ASSR response (89Hz, sustained)
        assr_duration = round(0.8 * fs);  % 800ms duration
        assr_start = trig_sample;
        assr_end = min(assr_start + assr_duration, n_samples);
        
        if assr_end <= n_samples
            assr_time = (0:assr_end-assr_start) / fs;
            % 89Hz oscillation with envelope
            assr_response = 1e-12 * sin(2*pi*89*assr_time) .* ...
                (1 - exp(-assr_time/0.1));
            channel_data(assr_start:assr_end) = channel_data(assr_start:assr_end) + ...
                assr_response * (0.5 + 0.5*rand());
        end
    end
    
    data.meg_channels(ch, :) = channel_data;
end

% Set channel labels
data = data.set_channel_labels();

% Initialize bad_channels
data.bad_channels = [];

end
