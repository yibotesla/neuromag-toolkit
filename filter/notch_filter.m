function data_filtered = notch_filter(data, fs, notch_freqs, bandwidth, filter_order)
% NOTCH_FILTER 应用零相位陷波FIR滤波器
%
% 语法:
%   data_filtered = notch_filter(data, fs, notch_freqs, bandwidth, filter_order)
%
% 输入参数:
%   data - N_channels × N_samples 矩阵，输入数据
%   fs - 标量，采样频率 (Hz)
%   notch_freqs - 向量，要陷波的频率 (Hz)，例如 [50, 100, 150]
%   bandwidth - 标量，陷波带宽 (Hz)，默认值: 2 Hz
%   filter_order - 标量，滤波器阶数（可选，默认值: 100）
%
% 输出参数:
%   data_filtered - N_channels × N_samples 矩阵，滤波后的数据
%
% 说明:
%   应用陷波滤波器去除指定频率及其谐波的电源线干扰。使用FIR零点对在目标频率处
%   形成深陷波，并结合零相位滤波(filtfilt)保持信号时序。多个陷波按顺序应用。
%
% 需求: 4.3, 4.4, 4.5
%
% 示例:
%   % 去除50Hz电源线及其谐波
%   data_clean = notch_filter(meg_data, 4800, [50, 100, 150, 200, 250]);

% 验证输入参数
if nargin < 3
    error('MEG:NotchFilter:InsufficientInputs', ...
        'At least 3 inputs required: data, fs, notch_freqs');
end

if nargin < 4 || isempty(bandwidth)
    bandwidth = 2;  % 默认2 Hz带宽
end

if nargin < 5
    filter_order = 200;  % 默认滤波器阶数（更高的阶数可获得更好的陷波衰减）
end

if any(notch_freqs <= 0) || any(notch_freqs >= fs/2)
    error('MEG:NotchFilter:InvalidFreqs', ...
        'All notch frequencies must be between 0 and Nyquist frequency (%.1f Hz)', fs/2);
end

if bandwidth <= 0
    error('MEG:NotchFilter:InvalidBandwidth', ...
        'Bandwidth must be positive');
end

if filter_order < 1 || mod(filter_order, 1) ~= 0
    error('MEG:NotchFilter:InvalidOrder', ...
        'Filter order must be a positive integer');
end

% 获取数据维度
[n_channels, n_samples] = size(data);

% 检查数据长度是否足够用于滤波器
if n_samples < 3 * max(2, filter_order)
    warning('MEG:NotchFilter:ShortData', ...
        'Data length (%d) is short relative to filter order (%d). Results may be unreliable.', ...
        n_samples, filter_order);
end

% 从原始数据开始
data_filtered = data;

% 对每个频率应用陷波滤波器
for i = 1:length(notch_freqs)
    notch_freq = notch_freqs(i);
    
    % 计算阻带边缘
    low_freq = notch_freq - bandwidth/2;
    high_freq = notch_freq + bandwidth/2;
    
    % 如果陷波无效则跳过
    if low_freq <= 0 || high_freq >= fs/2
        warning('MEG:NotchFilter:SkippingFreq', ...
            'Skipping notch at %.1f Hz (out of valid range)', notch_freq);
        continue;
    end
    
    % 设计FIR带阻滤波器（使用Kaiser窗增强阻带衰减）
    design_bandwidth = max(bandwidth, 8);  % 保障阻带宽度以获得足够衰减
    design_order = max(filter_order, 2000);
    low_freq = notch_freq - design_bandwidth / 2;
    high_freq = notch_freq + design_bandwidth / 2;
    wn = [low_freq, high_freq] / (fs/2);
    window = kaiser(design_order + 1, 10);
    b = fir1(design_order, wn, 'stop', window);
    a = 1;
    
    % 对每个通道应用零相位滤波
    temp_filtered = zeros(n_channels, n_samples);
    for ch = 1:n_channels
        % 使用filtfilt进行零相位滤波
        % 通过前向和后向滤波保持时序
        temp_filtered(ch, :) = filtfilt(b, a, data_filtered(ch, :));
    end
    
    % 更新数据用于下一次迭代
    data_filtered = temp_filtered;
end

end
