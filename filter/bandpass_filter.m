function data_filtered = bandpass_filter(data, fs, center_freq, bandwidth, filter_order)
% BANDPASS_FILTER 应用零相位带通FIR滤波器
%
% 语法:
%   data_filtered = bandpass_filter(data, fs, center_freq, bandwidth, filter_order)
%
% 输入参数:
%   data - N_channels × N_samples 矩阵，输入数据
%   fs - 标量，采样频率 (Hz)
%   center_freq - 标量，中心频率 (Hz)
%   bandwidth - 标量，带宽 (Hz)，中心频率±bandwidth/2
%   filter_order - 标量，滤波器阶数（可选，默认值: 100）
%
% 输出参数:
%   data_filtered - N_channels × N_samples 矩阵，滤波后的数据
%
% 说明:
%   使用fir1设计和零相位滤波(filtfilt)应用带通FIR滤波器，以保持信号时序。
%   该滤波器通过[center_freq - bandwidth/2, center_freq + bandwidth/2]范围内的频率，
%   并衰减此范围外的频率。
%
% 需求: 4.2, 4.4, 4.5
%
% 示例:
%   % 在89Hz ± 2Hz滤波ASSR信号
%   data_assr = bandpass_filter(meg_data, 4800, 89, 4);

% 验证输入参数
if nargin < 4
    error('MEG:BandpassFilter:InsufficientInputs', ...
        'At least 4 inputs required: data, fs, center_freq, bandwidth');
end

if nargin < 5
    filter_order = 200;  % 默认滤波器阶数（更高的阶数可获得更好的衰减）
end

% 计算通带边缘
low_freq = center_freq - bandwidth/2;
high_freq = center_freq + bandwidth/2;

if low_freq <= 0
    error('MEG:BandpassFilter:InvalidLowFreq', ...
        'Lower frequency (%.2f Hz) must be positive', low_freq);
end

if high_freq >= fs/2
    error('MEG:BandpassFilter:InvalidHighFreq', ...
        'Upper frequency (%.2f Hz) must be below Nyquist frequency (%.1f Hz)', ...
        high_freq, fs/2);
end

if low_freq >= high_freq
    error('MEG:BandpassFilter:InvalidBand', ...
        'Lower frequency (%.2f Hz) must be less than upper frequency (%.2f Hz)', ...
        low_freq, high_freq);
end

if filter_order < 1 || mod(filter_order, 1) ~= 0
    error('MEG:BandpassFilter:InvalidOrder', ...
        'Filter order must be a positive integer');
end

% 获取数据维度
[n_channels, n_samples] = size(data);

% 检查数据长度是否足够用于滤波器
if n_samples < 3 * filter_order
    warning('MEG:BandpassFilter:ShortData', ...
        'Data length (%d) is short relative to filter order (%d). Results may be unreliable.', ...
        n_samples, filter_order);
end

% 使用fir1设计FIR带通滤波器
% 将频率归一化到奈奎斯特频率
wn = [low_freq, high_freq] / (fs/2);

% 设计滤波器（FIR类型）
b = fir1(filter_order, wn, 'bandpass');

% 验证这是FIR滤波器（分母应为[1]）
a = 1;

% 初始化输出
data_filtered = zeros(n_channels, n_samples);

% 对每个通道应用零相位滤波
for ch = 1:n_channels
    % 使用filtfilt进行零相位滤波
    % 通过前向和后向滤波保持时序
    data_filtered(ch, :) = filtfilt(b, a, data(ch, :));
end

end
