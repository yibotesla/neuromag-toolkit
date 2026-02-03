function data_filtered = lowpass_filter(data, fs, cutoff_freq, filter_order)
% LOWPASS_FILTER 应用零相位低通FIR滤波器
%
% 语法:
%   data_filtered = lowpass_filter(data, fs, cutoff_freq, filter_order)
%
% 输入参数:
%   data - N_channels × N_samples 矩阵，输入数据
%   fs - 标量，采样频率 (Hz)
%   cutoff_freq - 标量，截止频率 (Hz)
%   filter_order - 标量，滤波器阶数（可选，默认值: 100）
%
% 输出参数:
%   data_filtered - N_channels × N_samples 矩阵，滤波后的数据
%
% 说明:
%   使用fir1设计和零相位滤波(filtfilt)应用低通FIR滤波器，以保持信号时序。
%   该滤波器衰减截止频率以上的频率分量。
%
% 需求: 4.1, 4.4, 4.5
%
% 示例:
%   % 使用30Hz截止频率滤波AEF信号
%   data_aef = lowpass_filter(meg_data, 4800, 30);

% 验证输入参数
if nargin < 3
    error('MEG:LowpassFilter:InsufficientInputs', ...
        'At least 3 inputs required: data, fs, cutoff_freq');
end

if nargin < 4
    filter_order = 200;  % 默认滤波器阶数（更高的阶数可获得更好的衰减）
end

if cutoff_freq <= 0 || cutoff_freq >= fs/2
    error('MEG:LowpassFilter:InvalidCutoff', ...
        'Cutoff frequency must be between 0 and Nyquist frequency (%.1f Hz)', fs/2);
end

if filter_order < 1 || mod(filter_order, 1) ~= 0
    error('MEG:LowpassFilter:InvalidOrder', ...
        'Filter order must be a positive integer');
end

% 获取数据维度
[n_channels, n_samples] = size(data);

% 检查数据长度是否足够用于滤波器
if n_samples < 3 * filter_order
    warning('MEG:LowpassFilter:ShortData', ...
        'Data length (%d) is short relative to filter order (%d). Results may be unreliable.', ...
        n_samples, filter_order);
end

% 使用fir1设计FIR低通滤波器
% 将截止频率归一化到奈奎斯特频率
wn = cutoff_freq / (fs/2);

% 设计滤波器（FIR类型）
b = fir1(filter_order, wn, 'low');

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
