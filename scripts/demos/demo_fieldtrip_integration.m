%% demo_fieldtrip_integration.m
% 演示如何使用FieldTrip工具箱进行高级MEG数据分析
%
% 本脚本展示：
% 1. FieldTrip初始化和数据格式转换
% 2. 使用ft_preprocessing进行预处理
% 3. 使用ft_denoise_hfc进行HFC降噪
% 4. 使用ft_timelockanalysis进行时间锁定分析
% 5. 使用ft_topoplotER进行脑地形图可视化
%
% 运行方式：
%   setup_paths  % 先设置基本路径
%   demo_fieldtrip_integration  % 运行本脚本
%
% 作者: Yibo
% 日期: 2026-02-03

%% 清理环境
clear; clc; close all;

fprintf('=== FieldTrip 集成演示 ===\n\n');

%% 步骤1: 初始化FieldTrip
fprintf('步骤1: 初始化FieldTrip...\n');

% 加载配置
config = default_config();

% 初始化FieldTrip
try
    fieldtrip_integration('init', config.paths.fieldtrip_path);
    [available, version] = fieldtrip_integration('check');
    
    if available
        fprintf('  FieldTrip已初始化，版本: %s\n', version);
    else
        error('FieldTrip初始化失败');
    end
catch ME
    fprintf('  错误: %s\n', ME.message);
    fprintf('  请确保FieldTrip路径正确配置在default_config.m中\n');
    return;
end

%% 步骤2: 生成模拟数据（或加载真实数据）
fprintf('\n步骤2: 准备测试数据...\n');

% 参数设置
fs = 1000;           % 采样率
duration = 10;       % 持续时间（秒）
n_channels = 64;     % 通道数
n_samples = fs * duration;
t = (0:n_samples-1) / fs;

% 生成模拟MEG数据
fprintf('  生成模拟MEG数据...\n');

% 1. 目标信号：17Hz正弦波 + 瞬态诱发响应
target_freq = 17;
target_signal = 1e-12 * sin(2*pi*target_freq*t);  % 17Hz信号

% 添加瞬态诱发响应（模拟AEF）
aef_latency = 0.1;  % 100ms潜伏期
aef_width = 0.05;   % 50ms宽度
aef_template = 2e-12 * exp(-((t - aef_latency).^2) / (2*aef_width^2));

% 2. 噪声：1/f噪声 + 工频干扰 + 高斯噪声
rng(42);  % 固定随机种子

% 生成通道数据
meg_data = zeros(n_channels, n_samples);

for ch = 1:n_channels
    % 空间分布（信号强度随通道变化）
    signal_weight = 0.5 + 0.5 * sin(2*pi*ch/n_channels);
    
    % 1/f噪声
    noise_1f = generate_1f_noise(n_samples, fs) * 5e-12;
    
    % 工频干扰
    noise_50hz = 3e-12 * sin(2*pi*50*t + rand*2*pi);
    noise_100hz = 1e-12 * sin(2*pi*100*t + rand*2*pi);
    
    % 高斯白噪声
    noise_white = 0.5e-12 * randn(1, n_samples);
    
    % 合成信号
    meg_data(ch,:) = signal_weight * (target_signal + aef_template) + ...
                     noise_1f + noise_50hz + noise_100hz + noise_white;
end

% 生成参考传感器数据（主要包含环境噪声）
ref_data = zeros(3, n_samples);
for r = 1:3
    ref_data(r,:) = 10e-12 * sin(2*pi*50*t + rand*2*pi) + ...
                    5e-12 * sin(2*pi*100*t + rand*2*pi) + ...
                    2e-12 * randn(1, n_samples);
end

% 生成触发信号（每2秒一个触发）
trigger = zeros(1, n_samples);
trigger_interval = 2 * fs;  % 2秒
trigger_indices = trigger_interval:trigger_interval:n_samples-fs;
trigger(trigger_indices) = 5;

fprintf('  数据大小: %d通道 × %d采样点\n', n_channels, n_samples);
fprintf('  触发点数: %d\n', length(trigger_indices));

%% 步骤3: 创建MEGData对象并转换为FieldTrip格式
fprintf('\n步骤3: 转换为FieldTrip格式...\n');

% 创建MEGData对象
meg_obj = MEGData();
meg_obj.meg_channels = meg_data;
meg_obj.ref_channels = ref_data;
meg_obj.trigger = trigger;
meg_obj.stimulus = zeros(1, n_samples);
meg_obj.fs = fs;
meg_obj.gain = 1;
meg_obj.time = t;
meg_obj = meg_obj.set_channel_labels();

% 转换为FieldTrip格式
ft_data_raw = fieldtrip_integration('to_fieldtrip', meg_obj, config);
fprintf('  FieldTrip数据结构已创建\n');
fprintf('  采样率: %d Hz\n', ft_data_raw.fsample);
fprintf('  通道数: %d\n', length(ft_data_raw.label));

%% 步骤4: 使用FieldTrip进行预处理
fprintf('\n步骤4: FieldTrip预处理...\n');

% 4.1 带通滤波
cfg = [];
cfg.bpfilter = 'yes';
cfg.bpfreq = [1 100];  % 1-100 Hz带通
cfg.bpfiltord = 4;
ft_data_bp = ft_preprocessing(cfg, ft_data_raw);
fprintf('  带通滤波完成 (1-100 Hz)\n');

% 4.2 工频陷波
cfg = [];
cfg.dftfilter = 'yes';
cfg.dftfreq = [50 100 150];  % 50Hz及其谐波
ft_data_notch = ft_preprocessing(cfg, ft_data_bp);
fprintf('  工频陷波完成 (50/100/150 Hz)\n');

%% 步骤5: 使用ft_denoise_hfc进行HFC降噪
fprintf('\n步骤5: FieldTrip HFC降噪...\n');

try
    % 检查ft_denoise_hfc是否可用
    if exist('ft_denoise_hfc', 'file') == 2
        cfg = [];
        cfg.updatesens = 'no';
        ft_data_hfc = ft_denoise_hfc(cfg, ft_data_notch);
        fprintf('  ft_denoise_hfc完成\n');
        use_hfc = true;
    else
        fprintf('  ft_denoise_hfc不可用，跳过HFC降噪\n');
        ft_data_hfc = ft_data_notch;
        use_hfc = false;
    end
catch ME
    fprintf('  HFC警告: %s\n', ME.message);
    fprintf('  继续使用陷波后数据\n');
    ft_data_hfc = ft_data_notch;
    use_hfc = false;
end

%% 步骤6: 时程分割（定义trials）
fprintf('\n步骤6: 时程分割...\n');

% 定义试次结构
cfg = [];
cfg.trl = zeros(length(trigger_indices), 4);
pre_samples = round(0.2 * fs);   % 200ms基线
post_samples = round(0.8 * fs);  % 800ms post-stimulus

for i = 1:length(trigger_indices)
    cfg.trl(i, 1) = trigger_indices(i) - pre_samples;  % 开始
    cfg.trl(i, 2) = trigger_indices(i) + post_samples; % 结束
    cfg.trl(i, 3) = -pre_samples;                      % offset
    cfg.trl(i, 4) = i;                                  % trial number
end

% 确保不超出数据范围
valid_trials = cfg.trl(:,1) > 0 & cfg.trl(:,2) <= n_samples;
cfg.trl = cfg.trl(valid_trials, :);

ft_data_epoched = ft_redefinetrial(cfg, ft_data_hfc);
fprintf('  分割完成，有效试次数: %d\n', length(ft_data_epoched.trial));

%% 步骤7: 时间锁定分析（总平均）
fprintf('\n步骤7: FieldTrip时间锁定分析...\n');

cfg = [];
cfg.keeptrials = 'no';  % 不保留单试次
ft_timelock = ft_timelockanalysis(cfg, ft_data_epoched);

fprintf('  总平均计算完成\n');
fprintf('  时间范围: %.3f - %.3f s\n', ft_timelock.time(1), ft_timelock.time(end));

%% 步骤8: 可视化结果
fprintf('\n步骤8: 生成可视化...\n');

% 创建输出目录
output_dir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'outputs', 'fieldtrip_demo');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 图1: 原始数据 vs FieldTrip处理后数据的PSD对比
figure('Position', [100, 100, 1200, 500]);

% 选择一个通道进行对比
ch_idx = 32;  % 中间通道

% 原始数据PSD
subplot(1,2,1);
[psd_raw, f_raw] = pwelch(meg_data(ch_idx,:), hamming(1024), 512, 1024, fs);
semilogy(f_raw, psd_raw, 'b', 'LineWidth', 1.5);
hold on;

% FieldTrip处理后PSD
data_processed = ft_data_hfc.trial{1}(ch_idx,:);
[psd_proc, f_proc] = pwelch(data_processed, hamming(1024), 512, 1024, fs);
semilogy(f_proc, psd_proc, 'r', 'LineWidth', 1.5);

xlabel('频率 (Hz)');
ylabel('功率谱密度 (T^2/Hz)');
title(sprintf('通道 %d PSD对比', ch_idx));
legend('原始数据', 'FieldTrip处理后');
xlim([0 200]);
grid on;

% 总平均波形
subplot(1,2,2);
plot(ft_timelock.time * 1000, ft_timelock.avg(ch_idx,:) * 1e12, 'LineWidth', 2);
xlabel('时间 (ms)');
ylabel('幅度 (pT)');
title(sprintf('通道 %d 总平均响应 (FieldTrip)', ch_idx));
xline(0, '--r', 'Trigger');
grid on;

saveas(gcf, fullfile(output_dir, 'fieldtrip_psd_comparison.png'));
saveas(gcf, fullfile(output_dir, 'fieldtrip_psd_comparison.pdf'));
fprintf('  保存: fieldtrip_psd_comparison.png\n');

% 图2: 多通道总平均
figure('Position', [100, 100, 1000, 600]);

% 选择5个代表性通道
channels_to_plot = [1, 16, 32, 48, 64];
colors = lines(length(channels_to_plot));

for i = 1:length(channels_to_plot)
    ch = channels_to_plot(i);
    plot(ft_timelock.time * 1000, ft_timelock.avg(ch,:) * 1e12, ...
         'Color', colors(i,:), 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Ch %d', ch));
    hold on;
end

xlabel('时间 (ms)');
ylabel('幅度 (pT)');
title('FieldTrip 时间锁定分析 - 多通道总平均');
xline(0, '--k', 'Trigger', 'LineWidth', 1.5);
legend('Location', 'best');
grid on;

saveas(gcf, fullfile(output_dir, 'fieldtrip_timelock.png'));
saveas(gcf, fullfile(output_dir, 'fieldtrip_timelock.pdf'));
fprintf('  保存: fieldtrip_timelock.png\n');

% 图3: 尝试脑地形图（如果布局文件可用）
figure('Position', [100, 100, 800, 700]);

try
    % 尝试创建简单的2D通道布局
    cfg = [];
    cfg.layout = 'ordered';
    cfg.rows = 8;
    cfg.columns = 8;
    layout = ft_prepare_layout(cfg, ft_timelock);
    
    % 绘制特定时间点的地形图
    cfg = [];
    cfg.xlim = [0.08 0.12];  % 80-120ms时间窗
    cfg.layout = layout;
    cfg.colorbar = 'yes';
    cfg.comment = 'xlim';
    cfg.commentpos = 'title';
    
    ft_topoplotER(cfg, ft_timelock);
    title(sprintf('FieldTrip脑地形图 (80-120ms)'));
    
    saveas(gcf, fullfile(output_dir, 'fieldtrip_topoplot.png'));
    fprintf('  保存: fieldtrip_topoplot.png\n');
catch ME
    fprintf('  脑地形图生成失败: %s\n', ME.message);
    
    % 替代：绘制通道热力图
    imagesc(ft_timelock.time * 1000, 1:n_channels, ft_timelock.avg * 1e12);
    colorbar;
    xlabel('时间 (ms)');
    ylabel('通道');
    title('FieldTrip 总平均热力图');
    
    saveas(gcf, fullfile(output_dir, 'fieldtrip_heatmap.png'));
    fprintf('  保存: fieldtrip_heatmap.png (替代图)\n');
end

% 图4: 与自定义实现对比
figure('Position', [100, 100, 1200, 800]);

% 使用自定义实现处理
fprintf('\n对比: 自定义实现 vs FieldTrip...\n');

% 自定义低通滤波
custom_lp = lowpass_filter(meg_data, fs, 100, 100);

% 自定义陷波
custom_notch = notch_filter(custom_lp, fs, 50, 2);
custom_notch = notch_filter(custom_notch, fs, 100, 2);

% 自定义时程提取和平均
pre_samples = round(0.2 * fs);
post_samples = round(0.8 * fs);
trial_length = pre_samples + post_samples + 1;
n_valid_trials = sum(valid_trials);
custom_trials = zeros(n_channels, trial_length, n_valid_trials);

valid_idx = trigger_indices(valid_trials);
for i = 1:n_valid_trials
    idx = valid_idx(i);
    custom_trials(:,:,i) = custom_notch(:, idx-pre_samples:idx+post_samples);
end

custom_avg = mean(custom_trials, 3);
custom_time = (-pre_samples:post_samples) / fs;

% 绘制对比
subplot(2,2,1);
plot(custom_time * 1000, custom_avg(ch_idx,:) * 1e12, 'b', 'LineWidth', 1.5);
xlabel('时间 (ms)');
ylabel('幅度 (pT)');
title('自定义实现 - 总平均');
xline(0, '--r');
grid on;

subplot(2,2,2);
plot(ft_timelock.time * 1000, ft_timelock.avg(ch_idx,:) * 1e12, 'r', 'LineWidth', 1.5);
xlabel('时间 (ms)');
ylabel('幅度 (pT)');
title('FieldTrip - 总平均');
xline(0, '--r');
grid on;

subplot(2,2,3);
hold on;
plot(custom_time * 1000, custom_avg(ch_idx,:) * 1e12, 'b', 'LineWidth', 1.5, 'DisplayName', '自定义');
plot(ft_timelock.time * 1000, ft_timelock.avg(ch_idx,:) * 1e12, 'r--', 'LineWidth', 1.5, 'DisplayName', 'FieldTrip');
xlabel('时间 (ms)');
ylabel('幅度 (pT)');
title(sprintf('对比 - 通道 %d', ch_idx));
legend('Location', 'best');
xline(0, '--k');
grid on;

subplot(2,2,4);
% 计算相关系数
% 需要对齐时间轴
[~, idx_start] = min(abs(ft_timelock.time - custom_time(1)));
[~, idx_end] = min(abs(ft_timelock.time - custom_time(end)));
ft_aligned = ft_timelock.avg(ch_idx, idx_start:idx_end);

if length(ft_aligned) == length(custom_avg(ch_idx,:))
    corr_coef = corrcoef(custom_avg(ch_idx,:), ft_aligned);
    corr_val = corr_coef(1,2);
else
    % 插值对齐
    ft_interp = interp1(ft_timelock.time, ft_timelock.avg(ch_idx,:), custom_time, 'linear', 'extrap');
    corr_coef = corrcoef(custom_avg(ch_idx,:), ft_interp);
    corr_val = corr_coef(1,2);
end

bar([1, 2], [1, corr_val]);
set(gca, 'XTickLabel', {'完美相关', '实际相关'});
ylabel('相关系数');
title(sprintf('自定义 vs FieldTrip 相关性: r = %.4f', corr_val));
ylim([0 1.1]);

saveas(gcf, fullfile(output_dir, 'fieldtrip_vs_custom.png'));
saveas(gcf, fullfile(output_dir, 'fieldtrip_vs_custom.pdf'));
fprintf('  保存: fieldtrip_vs_custom.png\n');

%% 总结
fprintf('\n=== FieldTrip集成演示完成 ===\n');
fprintf('输出目录: %s\n', output_dir);
fprintf('\n生成的文件:\n');
files = dir(fullfile(output_dir, '*.png'));
for i = 1:length(files)
    fprintf('  - %s\n', files(i).name);
end

if use_hfc
    fprintf('\n注意: 已使用ft_denoise_hfc进行HFC降噪\n');
else
    fprintf('\n注意: ft_denoise_hfc未能使用，可能需要grad结构\n');
end

fprintf('\nFieldTrip主要优势:\n');
fprintf('  1. 标准化的数据格式和处理流程\n');
fprintf('  2. 丰富的可视化工具（topoplot等）\n');
fprintf('  3. 高级分析功能（源定位、连接性分析）\n');
fprintf('  4. 广泛的社区支持和文档\n');

%% 辅助函数
function noise = generate_1f_noise(n_samples, fs)
    % 生成1/f（粉红）噪声
    freqs = (0:n_samples-1) * fs / n_samples;
    freqs(1) = 1;  % 避免除以零
    
    % 1/f 频谱
    magnitude = 1 ./ sqrt(freqs);
    magnitude(1) = 0;  % DC分量为0
    
    % 随机相位
    phase = 2*pi*rand(1, n_samples);
    
    % 构建复数频谱
    spectrum = magnitude .* exp(1j * phase);
    
    % 确保共轭对称以获得实数输出
    spectrum(n_samples/2+2:end) = conj(spectrum(n_samples/2:-1:2));
    
    % IFFT获得时域信号
    noise = real(ifft(spectrum));
    
    % 归一化
    noise = noise / std(noise);
end
