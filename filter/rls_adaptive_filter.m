function [data_filtered, weights, error_signal] = rls_adaptive_filter(meg_data, ref_data, params)
% RLS_ADAPTIVE_FILTER 用于噪声消除的递归最小二乘(RLS)自适应滤波
%
% 语法:
%   [data_filtered, weights, error_signal] = rls_adaptive_filter(meg_data, ref_data, params)
%
% 输入参数:
%   meg_data - N_channels × N_samples 矩阵，主MEG通道数据 (d(n))
%   ref_data - N_ref × N_samples 矩阵，参考传感器数据 (x(n))
%   params - 结构体，包含以下字段:
%       .lambda - 遗忘因子，范围 [0.99, 1.0]，默认值 0.995
%       .filter_order - 滤波器阶数（抽头数），默认值 10
%       .delta - P矩阵的初始化参数，默认值 1.0
%
% 输出参数:
%   data_filtered - N_channels × N_samples 矩阵，滤波后的MEG数据（误差信号 e(n)）
%   weights - filter_order × N_ref × N_channels 数组，每个通道的最终滤波器权重
%   error_signal - N_channels × N_samples 矩阵，误差信号（与data_filtered相同）
%
% 说明:
%   实现用于噪声消除的RLS自适应滤波算法。
%   RLS通过使用时变步长提供比LMS更快的收敛速度。
%   算法更新:
%       k(n) = P(n-1) * x(n) / (lambda + x(n)^T * P(n-1) * x(n))  [卡尔曼增益]
%       e(n) = d(n) - W(n-1)^T * x(n)                              [误差]
%       W(n) = W(n-1) + k(n) * e(n)                                [权重更新]
%       P(n) = (P(n-1) - k(n) * x(n)^T * P(n-1)) / lambda         [协方差更新]
%
% 需求: 3.1, 3.3
%
% 示例:
%   params.lambda = 0.995;
%   params.filter_order = 10;
%   params.delta = 1.0;
%   [filtered, weights, error] = rls_adaptive_filter(meg_data, ref_data, params);

% 解析输入参数
if nargin < 3
    params = struct();
end

if ~isfield(params, 'lambda')
    params.lambda = 0.995;
end

if ~isfield(params, 'filter_order')
    params.filter_order = 10;
end

if ~isfield(params, 'delta')
    params.delta = 1.0;
end

% 获取数据维度
[n_meg_channels, n_samples] = size(meg_data);
[n_ref_channels, n_ref_samples] = size(ref_data);

% 验证输入参数
if n_samples ~= n_ref_samples
    error('MEG:RLS:DimensionMismatch', ...
        'MEG data and reference data must have the same number of samples');
end

if params.filter_order > n_samples
    error('MEG:RLS:InvalidFilterOrder', ...
        'Filter order (%d) cannot exceed number of samples (%d)', ...
        params.filter_order, n_samples);
end

if params.lambda < 0.99 || params.lambda > 1.0
    error('MEG:RLS:InvalidForgettingFactor', ...
        'Forgetting factor lambda must be in range [0.99, 1.0], got %.6f', ...
        params.lambda);
end

if params.delta <= 0
    error('MEG:RLS:InvalidDelta', ...
        'Delta must be positive, got %.6f', params.delta);
end

% 初始化输出
data_filtered = zeros(n_meg_channels, n_samples);
weights = zeros(params.filter_order, n_ref_channels, n_meg_channels);
error_signal = zeros(n_meg_channels, n_samples);

% 独立处理每个MEG通道
for ch = 1:n_meg_channels
    % 初始化该通道的滤波器权重
    filter_length = params.filter_order * n_ref_channels;
    w = zeros(filter_length, 1);
    
    % 初始化逆相关矩阵P
    P = eye(filter_length) / params.delta;
    
    % RLS算法迭代
    for n = params.filter_order:n_samples
        % 构造参考输入向量 x(n)
        % 堆叠所有参考通道及其时间延迟
        x_n = zeros(filter_length, 1);
        for ref_ch = 1:n_ref_channels
            start_idx = (ref_ch - 1) * params.filter_order + 1;
            end_idx = ref_ch * params.filter_order;
            x_n(start_idx:end_idx) = ref_data(ref_ch, n:-1:n-params.filter_order+1)';
        end
        
        % 滤波器输出: y(n) = W^T * x(n)
        y_n = w' * x_n;
        
        % 误差信号: e(n) = d(n) - y(n)
        e_n = meg_data(ch, n) - y_n;
        
        % 卡尔曼增益: k(n) = P(n-1) * x(n) / (lambda + x(n)^T * P(n-1) * x(n))
        P_x = P * x_n;
        denominator = params.lambda + x_n' * P_x;
        k = P_x / denominator;
        
        % 权重更新: W(n) = W(n-1) + k(n) * e(n)
        w = w + k * e_n;
        
        % 协方差更新: P(n) = (P(n-1) - k(n) * x(n)^T * P(n-1)) / lambda
        P = (P - k * x_n' * P) / params.lambda;
        
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
