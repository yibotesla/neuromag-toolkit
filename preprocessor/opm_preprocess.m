function [data_out, preprocess_info] = opm_preprocess(file_path, config, varargin)
%OPM_PREPROCESS 完整的OPM-MEG双轴数据预处理流程
%
% 语法:
%   [data_out, info] = opm_preprocess(file_path, config)
%   [data_out, info] = opm_preprocess(file_path, config, 'Name', Value, ...)
%
% 输入参数:
%   file_path - LVM文件路径
%   config    - 配置结构体（来自 default_config）
%
% 可选参数:
%   'Verbose'      - 是否显示进度信息（默认: true）
%   'UseFieldTrip' - 是否使用FieldTrip（默认: config.opm_preprocessing.use_fieldtrip）
%   'ReturnAxis'   - 返回的数据轴（'Z', 'Y', 'both'）（默认: 'Z'）
%
% 输出参数:
%   data_out       - MEGData对象，包含预处理后的数据
%   preprocess_info - 预处理信息结构体
%
% 处理流程:
%   1. 加载LVM原始数据（136通道 = 68 sensor × 2 axis）
%   2. 分离Y轴和Z轴数据
%   3. 基线校正
%   4. 实时增益校准（Y轴240Hz / Z轴320Hz参考信号）
%   5. 深度陷波滤波（去除校准信号）
%   6. 三轴参考传感器RLS自适应降噪
%   7. ZY双轴联合HFC（均匀场校正）
%   8. 最终滤波（工频陷波、高通、低通）
%
% 示例:
%   config = default_config();
%   config.opm_preprocessing.use_real_data = true;
%   [data, info] = opm_preprocess('Y:\Yibo\Tsinghua_homework\Mission1\data_1.lvm', config);
%
% 另见: load_lvm_data, real_time_calibration, deep_notch_filter

% 解析输入参数
p = inputParser;
addRequired(p, 'file_path', @(x) ischar(x) || isstring(x));
addRequired(p, 'config', @isstruct);
addParameter(p, 'Verbose', true, @islogical);
addParameter(p, 'UseFieldTrip', [], @(x) isempty(x) || islogical(x));
addParameter(p, 'ReturnAxis', 'Z', @(x) ismember(upper(x), {'Z', 'Y', 'BOTH'}));
parse(p, file_path, config, varargin{:});

verbose = p.Results.Verbose;
return_axis = upper(p.Results.ReturnAxis);

% 确定是否使用FieldTrip
if isempty(p.Results.UseFieldTrip)
    use_fieldtrip = config.opm_preprocessing.use_fieldtrip;
else
    use_fieldtrip = p.Results.UseFieldTrip;
end

% 初始化预处理信息
preprocess_info = struct();
preprocess_info.file_path = file_path;
preprocess_info.start_time = datetime('now');
preprocess_info.steps = {};

% 获取配置参数
Fs = config.data_loading.sampling_rate;
gain = config.data_loading.gain;
opm_cfg = config.opm_preprocessing;

if verbose
    fprintf('=== OPM-MEG 双轴数据预处理 ===\n');
    fprintf('文件: %s\n', file_path);
    fprintf('采样率: %d Hz\n', Fs);
end

%% 步骤1: 加载LVM原始数据
if verbose
    fprintf('\n步骤1: 加载LVM原始数据...\n');
end

data_NI = lvm_import(file_path, 0);
data_raw = data_NI.Segment1.data;
data_start = data_raw';
N_samples = size(data_start, 2);

% 提取同步和触发信号
if size(data_start, 1) >= 139
    sync = data_start(138, :) - data_start(138, 1);
    digi = data_start(139, :);
else
    sync = zeros(1, N_samples);
    digi = zeros(1, N_samples);
end

% 创建时间向量
t = 0:(1/Fs):((N_samples-1)/Fs);

preprocess_info.steps{end+1} = '加载LVM数据';
preprocess_info.n_samples = N_samples;
preprocess_info.duration_seconds = N_samples / Fs;

if verbose
    fprintf('  已加载 %d 个采样点 (%.2f 秒)\n', N_samples, N_samples/Fs);
end

%% 步骤2: 分离Y轴和Z轴数据
if verbose
    fprintf('\n步骤2: 分离Y轴和Z轴数据...\n');
end

% 应用增益转换
data_scaled = data_start(2:end, :) * gain;

% Y轴数据在偶数通道 (2, 4, 6, ...)
channel_Y = 2:2:136;
data_Y = data_scaled(channel_Y, :);

% Z轴数据在奇数通道 (1, 3, 5, ...)
channel_Z = 1:2:136;
data_Z = data_scaled(channel_Z, :);

% 基线校正
data_Y = data_Y - data_Y(:, 1);
data_Z = data_Z - data_Z(:, 1);

preprocess_info.steps{end+1} = '双轴分离与基线校正';

if verbose
    fprintf('  Y轴通道: %d 个\n', size(data_Y, 1));
    fprintf('  Z轴通道: %d 个\n', size(data_Z, 1));
end

%% 步骤3: 实时增益校准
if verbose
    fprintf('\n步骤3: 实时增益校准...\n');
end

% Y轴校准 (240Hz参考信号)
if verbose
    fprintf('  Y轴校准 (参考频率: %d Hz)...\n', opm_cfg.ref_freq_Y);
end
data_cali_Y = real_time_calibration(data_Y, Fs, opm_cfg.ref_freq_Y, opm_cfg.target_peak_Y);

% Z轴校准 (320Hz参考信号)
if verbose
    fprintf('  Z轴校准 (参考频率: %d Hz)...\n', opm_cfg.ref_freq_Z);
end
data_cali_Z = real_time_calibration(data_Z, Fs, opm_cfg.ref_freq_Z, opm_cfg.target_peak_Z);

preprocess_info.steps{end+1} = '实时增益校准';

%% 步骤4: 深度陷波滤波（去除校准信号）
if verbose
    fprintf('\n步骤4: 深度陷波滤波...\n');
end

% Y轴 240Hz 陷波
if verbose
    fprintf('  Y轴 %d Hz 陷波滤波...\n', opm_cfg.ref_freq_Y);
end
data_notched_Y = deep_notch_filter(data_cali_Y, Fs, opm_cfg.ref_freq_Y, ...
    'Bandwidth', opm_cfg.notch_bandwidth, ...
    'Order', opm_cfg.notch_order, ...
    'Cascade', opm_cfg.notch_cascade);

% Z轴 320Hz 陷波
if verbose
    fprintf('  Z轴 %d Hz 陷波滤波...\n', opm_cfg.ref_freq_Z);
end
data_notched_Z = deep_notch_filter(data_cali_Z, Fs, opm_cfg.ref_freq_Z, ...
    'Bandwidth', opm_cfg.notch_bandwidth, ...
    'Order', opm_cfg.notch_order, ...
    'Cascade', opm_cfg.notch_cascade);

preprocess_info.steps{end+1} = '深度陷波滤波';

%% 步骤5: 通道重排（按layout映射）
if verbose
    fprintf('\n步骤5: 通道重排...\n');
end

layout_idx = opm_cfg.layout_idx;
channelBYlayout = 1:64;

% 合并Y轴和Z轴数据，创建双轴数据矩阵
% 奇数行是Z轴，偶数行是Y轴
data_combined = zeros(128, N_samples);
for i = 1:64
    data_combined(2*i-1, :) = data_notched_Z(channelBYlayout(i), :);
    data_combined(2*i, :) = data_notched_Y(channelBYlayout(i), :);
end

preprocess_info.steps{end+1} = '通道重排';

if verbose
    fprintf('  合并数据大小: %d 通道 × %d 时间点\n', size(data_combined, 1), size(data_combined, 2));
end

%% 步骤6: 三轴参考传感器RLS自适应降噪
if verbose
    fprintf('\n步骤6: 三轴参考传感器RLS自适应降噪...\n');
end

% 参考传感器索引
ref_idx = opm_cfg.ref_sensor_indices;  % [65, 66, 67]
n_ref_z = length(ref_idx);
n_ref_y = length(ref_idx);
n_ref_total = n_ref_z + n_ref_y;  % 6个参考通道
n_meg_dual = size(data_combined, 1);

% 从原始数据中获取参考传感器数据
ref_data = zeros(n_ref_total, N_samples);
for i = 1:n_ref_z
    ref_data(i, :) = data_notched_Z(ref_idx(i), :);
end
for i = 1:n_ref_y
    ref_data(n_ref_z + i, :) = data_notched_Y(ref_idx(i), :);
end

% RLS参数
lambda = opm_cfg.rls_forgetting_factor;
min_samples = opm_cfg.rls_min_samples;

% 初始化
beta = zeros(n_ref_total + 1, n_meg_dual);
P_matrix = 1000 * eye(n_ref_total + 1);
data_denoised = zeros(n_meg_dual, N_samples);

if verbose
    fprintf('  使用 %d 个参考通道 (3个Z轴 + 3个Y轴)\n', n_ref_total);
    fprintf('  RLS遗忘因子: %.4f\n', lambda);
end

% RLS自适应滤波
for n = 1:N_samples
    current_ref = [1; ref_data(:, n)];
    current_meg = data_combined(:, n);
    
    if n >= min_samples
        K = P_matrix * current_ref / (lambda + current_ref' * P_matrix * current_ref);
        prediction_error = current_meg - beta' * current_ref;
        beta = beta + K * prediction_error';
        P_matrix = (P_matrix - K * current_ref' * P_matrix) / lambda;
        
        noise_prediction = beta' * current_ref;
        data_denoised(:, n) = current_meg - noise_prediction;
    else
        data_denoised(:, n) = current_meg;
        
        if n == min_samples
            % 初始化回归系数
            X_initial = zeros(min_samples, n_ref_total + 1);
            Y_initial = zeros(min_samples, n_meg_dual);
            for k = 1:min_samples
                X_initial(k, :) = [1; ref_data(:, k)]';
                Y_initial(k, :) = data_combined(:, k)';
            end
            beta = X_initial \ Y_initial;
        end
    end
end

% 计算降噪效果
power_before = mean(var(data_combined, 0, 2));
power_after = mean(var(data_denoised, 0, 2));
noise_reduction_rls = 100 * (1 - power_after / power_before);

preprocess_info.steps{end+1} = 'RLS自适应降噪';
preprocess_info.rls_noise_reduction = noise_reduction_rls;

if verbose
    fprintf('  RLS降噪完成，噪声降低: %.1f%%\n', noise_reduction_rls);
end

%% 步骤7: ZY双轴联合HFC降噪
if opm_cfg.apply_hfc
    if verbose
        fprintf('\n步骤7: ZY双轴联合HFC降噪...\n');
    end
    
    [data_hfc, hfc_info] = apply_dual_axis_hfc(data_denoised, verbose);
    
    preprocess_info.steps{end+1} = 'HFC降噪';
    preprocess_info.hfc_noise_reduction = hfc_info.noise_reduction;
    
    if verbose
        fprintf('  HFC降噪完成，噪声降低: %.1f%%\n', hfc_info.noise_reduction);
    end
else
    data_hfc = data_denoised;
    if verbose
        fprintf('\n步骤7: 跳过HFC降噪（已禁用）\n');
    end
end

%% 步骤8: 最终滤波（工频陷波）
if verbose
    fprintf('\n步骤8: 最终滤波...\n');
end

% 工频陷波
notch_freqs = config.filters.notch_frequencies;
data_final = data_hfc;

for freq = notch_freqs
    if freq < Fs/2  % 确保频率在奈奎斯特频率以下
        data_final = apply_notch_filter(data_final, Fs, freq, 2);
    end
end

preprocess_info.steps{end+1} = '工频陷波滤波';

if verbose
    fprintf('  工频陷波完成 (%s Hz)\n', mat2str(notch_freqs));
end

%% 构建输出数据结构
if verbose
    fprintf('\n构建输出数据结构...\n');
end

data_out = MEGData();
data_out.fs = Fs;
data_out.gain = gain;
data_out.time = t;

% 根据返回轴类型提取数据
switch return_axis
    case 'Z'
        % 提取Z轴通道（奇数行）
        z_indices = 1:2:128;
        data_out.meg_channels = data_final(z_indices(1:64), :);
        data_out.ref_channels = ref_data(1:3, :);  % Z轴参考
        
    case 'Y'
        % 提取Y轴通道（偶数行）
        y_indices = 2:2:128;
        data_out.meg_channels = data_final(y_indices(1:64), :);
        data_out.ref_channels = ref_data(4:6, :);  % Y轴参考
        
    case 'BOTH'
        % 返回全部128通道
        data_out.meg_channels = data_final;
        data_out.ref_channels = ref_data;
end

% 设置刺激和触发信号
data_out.stimulus = sync;
data_out.trigger = digi;

% 设置通道标签
data_out = data_out.set_channel_labels();

% 初始化坏通道
data_out.bad_channels = [];

% 记录完成信息
preprocess_info.end_time = datetime('now');
preprocess_info.processing_time = preprocess_info.end_time - preprocess_info.start_time;
preprocess_info.return_axis = return_axis;

if verbose
    fprintf('\n=== 预处理完成 ===\n');
    fprintf('输出通道数: %d\n', size(data_out.meg_channels, 1));
    fprintf('处理时间: %s\n', char(preprocess_info.processing_time));
end

end

%% ========== 辅助函数 ==========

function [data_hfc, info] = apply_dual_axis_hfc(data, verbose)
%APPLY_DUAL_AXIS_HFC 应用ZY双轴联合HFC降噪
%
% 使用SVD构建投影矩阵，消除双轴方向的均匀场分量

n_channels = size(data, 1);
info = struct();

% 构建方向矩阵
% 对于双轴数据，奇数行是Z轴，偶数行是Y轴
% 使用单位向量近似方向
z_indices = 1:2:n_channels;
y_indices = 2:2:n_channels;

% 创建方向矩阵
Ori_z = zeros(n_channels, 3);
Ori_y = zeros(n_channels, 3);

% 简化：假设Z轴方向为法向(0,0,1)，Y轴方向为(0,1,0)
for i = 1:length(z_indices)
    Ori_z(z_indices(i), :) = [0, 0, 1];
    Ori_z(y_indices(i), :) = [0, 0, 1];
    Ori_y(z_indices(i), :) = [0, 1, 0];
    Ori_y(y_indices(i), :) = [0, 1, 0];
end

% 合并方向矩阵
N_combined = [Ori_z'; Ori_y']';

% SVD分解
[U, S, ~] = svd(N_combined, 'econ');

% 确定有效秩
sv = diag(S);
tol = max(size(N_combined)) * eps(max(sv));
rank_N = sum(sv > tol);

if rank_N > 0
    % 构建投影矩阵
    U_reduced = U(:, 1:rank_N);
    P = eye(n_channels) - U_reduced * U_reduced';
    
    % 应用投影
    data_hfc = P * data;
    
    % 计算降噪效果
    power_before = mean(var(data, 0, 2));
    power_after = mean(var(data_hfc, 0, 2));
    info.noise_reduction = 100 * (1 - power_after / power_before);
else
    data_hfc = data;
    info.noise_reduction = 0;
    if verbose
        fprintf('  警告：方向矩阵秩为0，跳过HFC\n');
    end
end

info.rank = rank_N;
info.projection_matrix = P;

end

function data_filtered = apply_notch_filter(data, fs, freq, bandwidth)
%APPLY_NOTCH_FILTER 应用简单的陷波滤波器

% 设计IIR陷波滤波器
wo = freq / (fs/2);
bw = bandwidth / (fs/2);

if wo >= 1
    data_filtered = data;
    return;
end

[b, a] = iirnotch(wo, bw);

% 应用滤波
n_channels = size(data, 1);
data_filtered = zeros(size(data));

for ch = 1:n_channels
    data_filtered(ch, :) = filtfilt(b, a, data(ch, :));
end

end
