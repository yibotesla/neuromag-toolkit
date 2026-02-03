function data_filtered = wavelet_despike(data, wavelet_name, level, threshold_method)
% WAVELET_DESPIKE 使用小波阈值去除尖峰噪声
%
% 语法:
%   data_filtered = wavelet_despike(data, wavelet_name, level, threshold_method)
%
% 输入参数:
%   data - N_channels × N_samples 的MEG数据矩阵
%   wavelet_name - 使用的小波族（默认值: 'db4' - Daubechies 4）
%   level - 分解层数（默认值: 5）
%   threshold_method - 阈值方法: 'soft'（软阈值）或'hard'（硬阈值）（默认值: 'soft'）
%
% 输出参数:
%   data_filtered - N_channels × N_samples 的去除尖峰后的数据矩阵
%
% 说明:
%   该函数使用小波分解去除尖峰噪声:
%   1. 使用离散小波变换(DWT)分解信号
%   2. 对高频细节系数应用阈值处理
%   3. 从阈值处理后的系数重构信号
%
%   尖峰噪声在细节系数中表现为高幅值系数。通过对这些系数进行阈值处理，
%   我们可以去除尖峰，同时保留底层信号结构。
%
% 需求: 2.4
%
% 示例:
%   data_clean = wavelet_despike(meg_data, 'db4', 5, 'soft');

% 输入验证
if nargin < 2 || isempty(wavelet_name)
    wavelet_name = 'db4';
end

if nargin < 3 || isempty(level)
    level = 5;
end

if nargin < 4 || isempty(threshold_method)
    threshold_method = 'soft';
end

% 验证输入参数
if ~ismatrix(data)
    error('MEG:Denoiser:InvalidInput', 'Input data must be a 2D matrix');
end

if ~ismember(threshold_method, {'soft', 'hard'})
    error('MEG:Denoiser:InvalidMethod', 'Threshold method must be ''soft'' or ''hard''');
end

% 获取数据维度
[n_channels, n_samples] = size(data);

% 初始化输出
data_filtered = zeros(n_channels, n_samples);

% 独立处理每个通道
for ch = 1:n_channels
    % 提取通道数据
    signal = data(ch, :);
    
    % 执行小波分解
    [C, L] = wavedec(signal, level, wavelet_name);
    
    % 从最精细尺度的细节系数估计噪声标准差
    detail_1 = detcoef(C, L, 1);
    sigma = median(abs(detail_1)) / 0.6745;
    
    % 通用阈值
    thr = sigma * sqrt(2 * log(length(signal)));
    
    % 对每一层的细节系数进行阈值处理
    % 我们对所有细节层(D1到Dlevel)进行阈值处理，但保留近似层(A)
    for lev = 1:level
        % 获取系数向量中该细节层的索引
        if lev == 1
            % 第一个细节层
            start_idx = L(1) + 1;
            end_idx = L(1) + L(2);
        else
            % 后续细节层
            start_idx = sum(L(1:lev)) + 1;
            end_idx = sum(L(1:lev+1));
        end
        
        % 提取该层的细节系数
        detail_coeffs = C(start_idx:end_idx);
        
        % 应用阈值处理
        if strcmp(threshold_method, 'soft')
            % 软阈值: 将系数向零收缩
            detail_coeffs_thr = sign(detail_coeffs) .* max(abs(detail_coeffs) - thr, 0);
        else
            % 硬阈值: 保留或清零系数
            detail_coeffs_thr = detail_coeffs .* (abs(detail_coeffs) > thr);
        end
        
        % 替换C中的系数
        C(start_idx:end_idx) = detail_coeffs_thr;
    end
    
    % 从阈值处理后的系数重构信号
    signal_filtered = waverec(C, L, wavelet_name);
    
    % 存储滤波后的信号（确保与输入长度相同）
    data_filtered(ch, :) = signal_filtered(1:n_samples);
end

end
