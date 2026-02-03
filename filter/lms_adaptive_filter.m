function [data_filtered, weights, error_signal] = lms_adaptive_filter(meg_data, ref_data, params)
% LMS_ADAPTIVE_FILTER 用于噪声消除的最小均方(LMS)自适应滤波
%
% 语法:
%   [data_filtered, weights, error_signal] = lms_adaptive_filter(meg_data, ref_data, params)
%
% 输入参数:
%   meg_data - N_channels × N_samples 矩阵，主MEG通道数据 (d(n))
%   ref_data - N_ref × N_samples 矩阵，参考传感器数据 (x(n))
%   params - 结构体，包含以下字段:
%       .mu - 步长（学习率），默认值 0.01
%       .filter_order - 滤波器阶数（抽头数），默认值 10
%
% 输出参数:
%   data_filtered - N_channels × N_samples 矩阵，滤波后的MEG数据（误差信号 e(n)）
%   weights - filter_order × N_ref × N_channels 数组，每个通道的最终滤波器权重
%   error_signal - N_channels × N_samples 矩阵，误差信号（与data_filtered相同）
%
% 说明:
%   实现用于噪声消除的LMS自适应滤波算法。
%   对于每个MEG通道，算法最小化误差:
%       e(n) = d(n) - W^T * x(n)
%   其中W是自适应滤波器权重向量，通过以下方式更新:
%       W(n+1) = W(n) + mu * e(n) * x(n)
%
% 需求: 3.1, 3.2
%
% 示例:
%   params.mu = 0.01;
%   params.filter_order = 10;
%   [filtered, weights, error] = lms_adaptive_filter(meg_data, ref_data, params);

% 解析输入参数
if nargin < 3
    params = struct();
end

if ~isfield(params, 'mu')
    params.mu = 0.01;
end

if ~isfield(params, 'filter_order')
    params.filter_order = 10;
end

% 获取数据维度
[n_meg_channels, n_samples] = size(meg_data);
[n_ref_channels, n_ref_samples] = size(ref_data);

% 验证输入参数
if n_samples ~= n_ref_samples
    error('MEG:LMS:DimensionMismatch', ...
        'MEG data and reference data must have the same number of samples');
end

if params.filter_order > n_samples
    error('MEG:LMS:InvalidFilterOrder', ...
        'Filter order (%d) cannot exceed number of samples (%d)', ...
        params.filter_order, n_samples);
end

if params.mu <= 0
    error('MEG:LMS:InvalidStepSize', ...
        'Step size mu must be positive, got %.6f', params.mu);
end

% 初始化输出
data_filtered = zeros(n_meg_channels, n_samples);
weights = zeros(params.filter_order, n_ref_channels, n_meg_channels);
error_signal = zeros(n_meg_channels, n_samples);

% 独立处理每个MEG通道
for ch = 1:n_meg_channels
    % 初始化该通道的滤波器权重
    w = zeros(params.filter_order * n_ref_channels, 1);
    
    % LMS算法迭代
    for n = params.filter_order:n_samples
        % 构造参考输入向量 x(n)
        % 堆叠所有参考通道及其时间延迟
        x_n = zeros(params.filter_order * n_ref_channels, 1);
        for ref_ch = 1:n_ref_channels
            start_idx = (ref_ch - 1) * params.filter_order + 1;
            end_idx = ref_ch * params.filter_order;
            x_n(start_idx:end_idx) = ref_data(ref_ch, n:-1:n-params.filter_order+1)';
        end
        
        % 滤波器输出: y(n) = W^T * x(n)
        y_n = w' * x_n;
        
        % 误差信号: e(n) = d(n) - y(n)
        e_n = meg_data(ch, n) - y_n;
        
        % 权重更新: W(n+1) = W(n) + mu * e(n) * x(n)
        w = w + params.mu * e_n * x_n;
        
        % 存储误差信号（滤波输出）
        error_signal(ch, n) = e_n;
    end
    
    % 存储该通道的最终权重
    % 将权重重塑回 filter_order × n_ref_channels 格式
    for ref_ch = 1:n_ref_channels
        start_idx = (ref_ch - 1) * params.filter_order + 1;
        end_idx = ref_ch * params.filter_order;
        weights(:, ref_ch, ch) = w(start_idx:end_idx);
    end
    
    % 将误差信号复制到滤波数据
    data_filtered(ch, :) = error_signal(ch, :);
end

end
