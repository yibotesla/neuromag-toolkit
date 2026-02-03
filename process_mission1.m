function results = process_mission1(file_path, config, varargin)
% PROCESS_MISSION1 任务1（幻影数据）的完整处理流程
%
% 语法:
%   results = process_mission1(file_path, config)
%   results = process_mission1(file_path, config, 'Name', Value, ...)
%
% 输入参数:
%   file_path - 包含幻影数据的LVM文件路径
%               如果为'demo'，则生成合成的17Hz信号用于测试
%   config - 配置结构体（来自config_template）
%
% 可选的名称-值对参数:
%   'PlotResults' - 是否绘制结果图（默认值: true）
%   'SaveResults' - 是否将结果保存到文件（默认值: false）
%   'OutputDir' - 结果输出目录（默认值: 'outputs/mission1'）
%   'Verbose' - 显示进度消息（默认值: true）
%
% 输出参数:
%   results - 包含以下字段的结构体:
%       .raw_data - 原始MEGData对象
%       .preprocessed - 预处理后的数据
%       .despiked - 去除尖峰噪声后的数据
%       .filtered - 自适应滤波后的数据
%       .psd_raw - 原始数据的功率谱密度
%       .psd_filtered - 滤波后数据的功率谱密度
%       .snr_raw - 原始数据在17Hz处的信噪比
%       .snr_filtered - 滤波后数据在17Hz处的信噪比
%       .peak_detected - 是否检测到17Hz峰值
%       .peak_freq - 检测到的峰值频率
%       .noise_reduction - 噪声降低百分比
%       .bad_channels - 坏通道列表
%
% 说明:
%   实现完整的任务1处理流程:
%   1. 加载LVM文件（或生成合成数据）
%   2. 预处理（直流去除、坏通道检测）
%   3. 去除尖峰噪声
%   4. 使用参考传感器应用自适应滤波（HFC）
%   5. 计算功率谱密度和17Hz处的信噪比
%   6. 检测17Hz峰值
%   7. 可视化结果
%
% 需求: 2.1, 2.2, 2.3, 2.4, 2.5
%
% 示例:
%   config = config_template();
%   results = process_mission1('Mission1/data_1.lvm', config);
%   
%   % 使用合成数据的演示模式
%   results = process_mission1('demo', config);

% 解析输入参数
p = inputParser;
addRequired(p, 'file_path', @(x) ischar(x) || isstring(x));
addRequired(p, 'config', @isstruct);
addParameter(p, 'PlotResults', true, @islogical);
addParameter(p, 'SaveResults', false, @islogical);
addParameter(p, 'OutputDir', 'outputs/mission1', @ischar);
addParameter(p, 'Verbose', true, @islogical);
addParameter(p, 'UseRealDataProcessing', [], @(x) isempty(x) || islogical(x));
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

% 初始化结果结构体
results = struct();

%% 步骤1: 加载数据
if verbose
    fprintf('=== 任务1: 幻影数据处理 ===\n');
    fprintf('步骤1: 加载数据...\n');
end

if strcmpi(file_path, 'demo')
    % 生成用于演示的合成数据
    if verbose
        fprintf('  生成合成的17Hz信号...\n');
    end
    raw_data = generate_synthetic_mission1_data(config);
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

%% 步骤3: 去除尖峰噪声
if verbose
    fprintf('\n步骤3: 去除尖峰噪声...\n');
end

if strcmpi(config.despike.method, 'median')
    despiked_data = median_filter_despike(preprocessed.data, ...
        config.despike.median_window, ...
        config.despike.spike_threshold);
else
    despiked_data = wavelet_despike(preprocessed.data, ...
        config.despike.wavelet_name, ...
        config.despike.wavelet_level);
end

results.despiked = despiked_data;

if verbose
    fprintf('  使用 %s 方法完成尖峰去除\n', config.despike.method);
end

%% 步骤4: 自适应滤波 (HFC)
if verbose
    fprintf('\n步骤4: 应用自适应滤波 (HFC)...\n');
end

% 使用参考传感器进行自适应噪声消除
if strcmpi(config.adaptive_filter.algorithm, 'LMS')
    [filtered_data, weights, ~] = lms_adaptive_filter(...
        despiked_data, raw_data.ref_channels, config.adaptive_filter);
else
    [filtered_data, weights, ~] = rls_adaptive_filter(...
        despiked_data, raw_data.ref_channels, config.adaptive_filter);
end

results.filtered = filtered_data;
results.filter_weights = weights;

% 计算噪声降低
noise_reduction = calculate_noise_reduction(despiked_data, filtered_data);
results.noise_reduction = noise_reduction;

if verbose
    fprintf('  使用 %s 算法完成自适应滤波\n', ...
        config.adaptive_filter.algorithm);
    fprintf('  平均噪声降低: %.2f%%\n', mean(noise_reduction));
end

%% 步骤5: 计算功率谱密度
if verbose
    fprintf('\n步骤5: 计算功率谱密度...\n');
end

% 计算原始数据的功率谱密度（预处理和去尖峰后）
[freq_raw, psd_raw] = compute_psd(despiked_data, raw_data.fs, ...
    'Method', config.analysis.psd_method);

% 计算滤波后数据的功率谱密度
[freq_filtered, psd_filtered] = compute_psd(filtered_data, raw_data.fs, ...
    'Method', config.analysis.psd_method);

results.psd_raw = struct('frequencies', freq_raw, 'power', psd_raw);
results.psd_filtered = struct('frequencies', freq_filtered, 'power', psd_filtered);

if verbose
    fprintf('  使用 %s 方法计算功率谱密度\n', config.analysis.psd_method);
end

%% 步骤6: 计算17Hz处的信噪比
if verbose
    fprintf('\n步骤6: 计算17Hz处的信噪比...\n');
end

target_freq = config.mission1.target_frequency;

% 原始数据的信噪比
[snr_raw, sig_power_raw, noise_power_raw] = calculate_snr(...
    despiked_data, raw_data.fs, target_freq, ...
    'SignalBandwidth', config.analysis.snr_signal_bandwidth, ...
    'NoiseBandwidth', config.analysis.snr_noise_bandwidth, ...
    'NoiseOffset', config.analysis.snr_noise_offset);

% 滤波后数据的信噪比
[snr_filtered, sig_power_filtered, noise_power_filtered] = calculate_snr(...
    filtered_data, raw_data.fs, target_freq, ...
    'SignalBandwidth', config.analysis.snr_signal_bandwidth, ...
    'NoiseBandwidth', config.analysis.snr_noise_bandwidth, ...
    'NoiseOffset', config.analysis.snr_noise_offset);

results.snr_raw = snr_raw;
results.snr_filtered = snr_filtered;
results.signal_power_raw = sig_power_raw;
results.signal_power_filtered = sig_power_filtered;
results.noise_power_raw = noise_power_raw;
results.noise_power_filtered = noise_power_filtered;

if verbose
    fprintf('  原始数据在17Hz处的信噪比: %.2f dB (平均)\n', mean(snr_raw));
    fprintf('  滤波后数据在17Hz处的信噪比: %.2f dB (平均)\n', mean(snr_filtered));
    fprintf('  信噪比提升: %.2f dB\n', mean(snr_filtered - snr_raw));
end

%% 步骤7: 检测17Hz峰值
if verbose
    fprintf('\n步骤7: 检测17Hz峰值...\n');
end

[peak_detected, peak_freq, peak_power, peak_idx] = detect_peak_at_frequency(...
    filtered_data, raw_data.fs, target_freq, ...
    'Tolerance', 0.5, ...
    'MinPeakHeight', 2.0);

results.peak_detected = peak_detected;
results.peak_freq = peak_freq;
results.peak_power = peak_power;
results.peak_idx = peak_idx;

if verbose
    n_detected = sum(peak_detected);
    fprintf('  在 %d/%d 个通道中检测到17Hz峰值\n', ...
        n_detected, length(peak_detected));
    if n_detected > 0
        valid_freqs = peak_freq(peak_detected);
        fprintf('  平均检测频率: %.2f Hz\n', mean(valid_freqs));
    end
end

%% 步骤8: 可视化
if plot_results
    if verbose
        fprintf('\n步骤8: 生成可视化图形...\n');
    end
    
    % 创建包含子图的图形
    fig = figure('Name', 'Mission 1 Results', 'Position', [100, 100, 1200, 800]);
    
    % 图1: 原始数据功率谱密度（跨通道平均）
    subplot(2, 2, 1);
    psd_raw_avg = mean(psd_raw, 1);
    plot_psd(freq_raw, psd_raw_avg, ...
        'Title', 'Raw Data PSD (After Despiking)', ...
        'FreqRange', [0, 50], ...
        'Figure', fig);
    hold on;
    xline(target_freq, 'r--', 'LineWidth', 2, 'Label', '17Hz');
    hold off;
    
    % 图2: 滤波后数据功率谱密度（跨通道平均）
    subplot(2, 2, 2);
    psd_filtered_avg = mean(psd_filtered, 1);
    plot_psd(freq_filtered, psd_filtered_avg, ...
        'Title', 'Filtered Data PSD (After HFC)', ...
        'FreqRange', [0, 50], ...
        'Figure', fig);
    hold on;
    xline(target_freq, 'r--', 'LineWidth', 2, 'Label', '17Hz');
    hold off;
    
    % 图3: 信噪比对比
    subplot(2, 2, 3);
    bar([mean(snr_raw), mean(snr_filtered)]);
    set(gca, 'XTickLabel', {'Raw', 'Filtered'});
    ylabel('SNR (dB)', 'FontSize', 12, 'FontWeight', 'bold');
    title('SNR at 17Hz Comparison', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % 图4: 每个通道的噪声降低
    subplot(2, 2, 4);
    bar(noise_reduction);
    xlabel('Channel', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Noise Reduction (%)', 'FontSize', 12, 'FontWeight', 'bold');
    title('Noise Reduction per Channel', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    results.figure = fig;
end

%% 步骤9: 保存结果
if save_results
    if verbose
        fprintf('\n步骤9: 保存结果...\n');
    end
    
    % 如果输出目录不存在则创建
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % 保存结果结构体
    save(fullfile(output_dir, 'mission1_results.mat'), 'results');
    
    % 如果图形存在则保存
    if plot_results && isfield(results, 'figure')
        saveas(results.figure, fullfile(output_dir, 'mission1_results.png'));
        saveas(results.figure, fullfile(output_dir, 'mission1_results.pdf'));
    end
    
    if verbose
        fprintf('  结果已保存到: %s\n', output_dir);
    end
end

%% 总结
if verbose
    fprintf('\n=== 任务1处理完成 ===\n');
    fprintf('总结:\n');
    fprintf('  - 已处理 %d 个通道\n', size(filtered_data, 1));
    fprintf('  - 坏通道: %d 个\n', length(bad_channels));
    fprintf('  - 平均噪声降低: %.2f%%\n', mean(noise_reduction));
    fprintf('  - 信噪比提升: %.2f dB\n', mean(snr_filtered - snr_raw));
    fprintf('  - 在 %d/%d 个通道中检测到17Hz峰值\n', ...
        sum(peak_detected), length(peak_detected));
end

end


%% 辅助函数: 生成合成数据
function data = generate_synthetic_mission1_data(config)
% 生成用于测试的合成幻影数据
%
% 创建包含以下内容的MEGData对象:
% - 64个包含17Hz信号 + 噪声的MEG通道
% - 3个包含相关噪声的参考通道
% - 刺激和触发通道（零值）

fs = config.data_loading.sampling_rate;
duration = 10;  % 10秒（缩短以加快处理速度）
t = 0:1/fs:duration-1/fs;
n_samples = length(t);

% 初始化MEGData对象
data = MEGData();
data.fs = fs;
data.gain = config.data_loading.gain;
data.time = t;

% 生成17Hz信号
signal_17hz = 1e-12 * sin(2 * pi * 17 * t);  % 1 pT幅度

% 生成宽带噪声（跨通道相关）
common_noise = 5e-12 * randn(1, n_samples);  % 5 pT RMS

% 生成参考传感器数据（主要是共模噪声）
data.ref_channels = zeros(3, n_samples);
for i = 1:3
    data.ref_channels(i, :) = common_noise + 1e-12 * randn(1, n_samples);
end

% 生成MEG通道数据
data.meg_channels = zeros(64, n_samples);
for ch = 1:64
    % 每个通道包含:
    % - 17Hz信号（具有一定的空间变化）
    % - 共模噪声（与参考传感器相关）
    % - 独立噪声
    spatial_factor = 0.5 + 0.5 * rand();  % 改变信号强度
    data.meg_channels(ch, :) = spatial_factor * signal_17hz + ...
        0.8 * common_noise + ...
        2e-12 * randn(1, n_samples);
    
    % 向某些通道添加偶发尖峰
    if rand() < 0.3  % 30%的通道有尖峰
        n_spikes = randi([5, 15]);
        spike_locs = randi(n_samples, 1, n_spikes);
        data.meg_channels(ch, spike_locs) = data.meg_channels(ch, spike_locs) + ...
            20e-12 * randn(1, n_spikes);
    end
end

% 刺激和触发（幻影数据为零）
data.stimulus = zeros(1, n_samples);
data.trigger = zeros(1, n_samples);

% 设置通道标签
data = data.set_channel_labels();

% 初始化坏通道
data.bad_channels = [];

end
