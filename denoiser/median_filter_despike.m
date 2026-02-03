function data_filtered = median_filter_despike(data, window_size, threshold)
% MEDIAN_FILTER_DESPIKE 使用中值滤波去除尖峰噪声
%
% 语法:
%   data_filtered = median_filter_despike(data, window_size, threshold)
%
% 输入参数:
%   data - N_channels × N_samples 的MEG数据矩阵
%   window_size - 中值滤波滑动窗口大小（默认值: 5）
%   threshold - 尖峰检测阈值，以标准差为单位（默认值: 3.0）
%
% 输出参数:
%   data_filtered - N_channels × N_samples 的去除尖峰后的数据矩阵
%
% 说明:
%   该函数通过以下步骤检测和去除尖峰噪声:
%   1. 计算信号的中值滤波版本
%   2. 检测信号偏离中值超过threshold*std的尖峰
%   3. 用中值滤波值替换检测到的尖峰
%
% 需求: 2.4
%
% 示例:
%   data_clean = median_filter_despike(meg_data, 5, 3.0);

% 输入验证
if nargin < 2 || isempty(window_size)
    window_size = 5;
end

if nargin < 3 || isempty(threshold)
    threshold = 3.0;
end

% 验证输入参数
if ~ismatrix(data)
    error('MEG:Denoiser:InvalidInput', 'Input data must be a 2D matrix');
end

if window_size < 3 || mod(window_size, 2) == 0
    error('MEG:Denoiser:InvalidWindowSize', 'Window size must be an odd number >= 3');
end

if threshold <= 0
    error('MEG:Denoiser:InvalidThreshold', 'Threshold must be positive');
end

% 获取数据维度
[n_channels, n_samples] = size(data);

% 初始化输出
data_filtered = data;

% 独立处理每个通道
for ch = 1:n_channels
    % 提取通道数据
    signal = data(ch, :);
    
    % 使用滑动窗口计算中值滤波版本
    median_signal = medfilt1(signal, window_size, 'truncate');
    
    % 计算残差（与中值的差异）
    residual = signal - median_signal;
    
    % 使用MAD（中位数绝对偏差）计算稳健标准差
    % MAD对异常值的鲁棒性比标准差更强
    mad_value = median(abs(residual - median(residual)));
    robust_std = 1.4826 * mad_value;  % 正态分布的缩放因子
    
    % 检测尖峰: 残差超过阈值的点
    spike_mask = abs(residual) > (threshold * robust_std);
    
    % 用中值滤波值替换尖峰
    signal(spike_mask) = median_signal(spike_mask);
    
    % 存储滤波后的信号
    data_filtered(ch, :) = signal;
end

end
