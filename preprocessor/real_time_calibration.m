function data_cali = real_time_calibration(data, Fs, refFreq, targetPeak, varargin)
%REAL_TIME_CALIBRATION OPM传感器实时增益校准
%
% 语法:
%   data_cali = real_time_calibration(data, Fs, refFreq, targetPeak)
%   data_cali = real_time_calibration(data, Fs, refFreq, targetPeak, 'Name', Value, ...)
%
% 输入参数:
%   data       - 输入数据矩阵 (N_channels × N_samples)
%   Fs         - 采样率 (Hz)
%   refFreq    - 参考信号频率 (Hz)，如240Hz(Y轴)或320Hz(Z轴)
%   targetPeak - 目标峰值幅度，用于增益归一化
%
% 可选参数:
%   'FIROrder'     - FIR滤波器阶数（默认: 100）
%   'LPCutoff'     - 低通滤波器截止频率（默认: 2 Hz）
%   'MinAmplitude' - 最小幅度阈值系数（默认: 0.01）
%
% 输出参数:
%   data_cali  - 校准后的数据矩阵
%
% 说明:
%   OPM传感器使用内部线圈发出已知频率的标定信号（Y轴240Hz，Z轴320Hz）
%   通过数字锁相放大器检测该信号的幅度，计算实时校准因子
%   然后将校准因子应用于原始数据，补偿增益变化
%
% 算法步骤:
%   1. 设计FIR带通滤波器，提取参考频率成分
%   2. 数字锁相放大（IQ解调）
%   3. 低通滤波提取直流分量（幅度包络）
%   4. 计算实时校准因子
%   5. 应用校准因子并补偿群延迟
%   6. 二次基线校正
%
% 示例:
%   % Y轴校准 (240Hz参考信号)
%   data_Y_cali = real_time_calibration(data_Y, 4800, 240, 62400);
%
%   % Z轴校准 (320Hz参考信号)
%   data_Z_cali = real_time_calibration(data_Z, 4800, 320, 55600);
%
% 另见: opm_preprocess, deep_notch_filter

% 解析输入参数
p = inputParser;
addRequired(p, 'data', @isnumeric);
addRequired(p, 'Fs', @(x) isscalar(x) && x > 0);
addRequired(p, 'refFreq', @(x) isscalar(x) && x > 0);
addRequired(p, 'targetPeak', @(x) isscalar(x) && x > 0);
addParameter(p, 'FIROrder', 100, @(x) isscalar(x) && x > 0);
addParameter(p, 'LPCutoff', 2, @(x) isscalar(x) && x > 0);
addParameter(p, 'MinAmplitude', 0.01, @(x) isscalar(x) && x > 0);
parse(p, data, Fs, refFreq, targetPeak, varargin{:});

fir_order = p.Results.FIROrder;
lp_cutoff = p.Results.LPCutoff;
min_amp_factor = p.Results.MinAmplitude;

% 获取数据维度
nChannels = size(data, 1);
N_samples = size(data, 2);

% 生成参考信号（正弦和余弦用于IQ解调）
t_signal = (0:N_samples-1) / Fs;
reference_sin = sin(2*pi*refFreq*t_signal);
reference_cos = cos(2*pi*refFreq*t_signal);

% 设计FIR带通滤波器
cutoff_freq = [refFreq-5, refFreq+5];
% 确保截止频率在有效范围内
cutoff_freq = max(cutoff_freq, 1);
cutoff_freq = min(cutoff_freq, Fs/2 - 1);
cutoff_norm = cutoff_freq / (Fs/2);

try
    b_fir = fir1(fir_order, cutoff_norm, 'bandpass');
catch
    % 如果带通设计失败，使用更简单的方法
    warning('FIR带通滤波器设计失败，使用替代方法');
    b_fir = ones(1, fir_order+1) / (fir_order+1);
end

% 设计低通滤波器（用于提取幅度包络）
lp_norm = lp_cutoff / (Fs/2);
lp_norm = min(lp_norm, 0.99);  % 确保归一化频率有效
[b_lp, a_lp] = butter(2, lp_norm);

% 初始化输出
data_cali = zeros(size(data));

% 最小幅度阈值
min_amplitude = targetPeak * min_amp_factor;

% 对每个通道进行校准
for ch = 1:nChannels
    % 应用FIR带通滤波器，提取参考频率成分
    filtered_signal = filter(b_fir, 1, data(ch, :));
    
    % 数字锁相放大（IQ解调）
    I_component = filtered_signal .* reference_sin;
    Q_component = filtered_signal .* reference_cos;
    
    % 低通滤波提取直流分量（幅度包络）
    I_smoothed = filtfilt(b_lp, a_lp, I_component);
    Q_smoothed = filtfilt(b_lp, a_lp, Q_component);
    
    % 计算测量幅度（IQ的模）
    measured_amplitude = 2 * sqrt(I_smoothed.^2 + Q_smoothed.^2);
    
    % 计算实时校准因子
    % 避免除以过小的值
    realtime_factors = targetPeak ./ max(measured_amplitude, min_amplitude);
    
    % 限制校准因子范围，防止异常值
    realtime_factors = min(realtime_factors, 10);  % 最大10倍增益
    realtime_factors = max(realtime_factors, 0.1); % 最小0.1倍增益
    
    % 补偿FIR滤波器的群延迟
    group_delay = floor(fir_order/2);
    if group_delay < length(realtime_factors)
        compensated_gain = [realtime_factors(group_delay+1:end), ...
                           realtime_factors(end)*ones(1, group_delay)];
    else
        compensated_gain = realtime_factors;
    end
    
    % 应用校准因子
    data_cali(ch, :) = data(ch, :) .* compensated_gain;
end

% 二次基线校正
initial_values = data_cali(:, 1);
data_cali = data_cali - initial_values;

end
