function data_notched = deep_notch_filter(data, Fs, notch_freq, varargin)
%DEEP_NOTCH_FILTER 深度陷波滤波器（级联FIR实现高抑制度）
%
% 语法:
%   data_notched = deep_notch_filter(data, Fs, notch_freq)
%   data_notched = deep_notch_filter(data, Fs, notch_freq, 'Name', Value, ...)
%
% 输入参数:
%   data       - 输入数据矩阵 (N_channels × N_samples)
%   Fs         - 采样率 (Hz)
%   notch_freq - 陷波中心频率 (Hz)
%
% 可选参数:
%   'Bandwidth' - 陷波带宽 (Hz)（默认: 10）
%   'Order'     - FIR滤波器阶数（默认: 400）
%   'Cascade'   - 级联次数（默认: 6）
%
% 输出参数:
%   data_notched - 滤波后的数据矩阵
%
% 说明:
%   该函数用于深度抑制OPM校准信号（240Hz/320Hz）。
%   通过多次级联FIR带阻滤波器实现>60dB的抑制深度。
%   使用filtfilt进行零相位滤波，避免相位失真。
%
% 示例:
%   % 去除Y轴240Hz校准信号
%   data_Y_clean = deep_notch_filter(data_Y, 4800, 240);
%
%   % 去除Z轴320Hz校准信号，自定义参数
%   data_Z_clean = deep_notch_filter(data_Z, 4800, 320, ...
%       'Bandwidth', 15, 'Order', 500, 'Cascade', 8);
%
% 另见: opm_preprocess, real_time_calibration, notch_filter

% 解析输入参数
p = inputParser;
addRequired(p, 'data', @isnumeric);
addRequired(p, 'Fs', @(x) isscalar(x) && x > 0);
addRequired(p, 'notch_freq', @(x) isscalar(x) && x > 0);
addParameter(p, 'Bandwidth', 10, @(x) isscalar(x) && x > 0);
addParameter(p, 'Order', 400, @(x) isscalar(x) && x > 0 && mod(x, 2) == 0);
addParameter(p, 'Cascade', 6, @(x) isscalar(x) && x >= 1);
parse(p, data, Fs, notch_freq, varargin{:});

notch_bw = p.Results.Bandwidth;
fir_order = p.Results.Order;
n_cascade = p.Results.Cascade;

% 检查陷波频率是否有效
nyquist = Fs / 2;
if notch_freq >= nyquist
    warning('陷波频率 %.1f Hz 超过奈奎斯特频率 %.1f Hz，跳过滤波', notch_freq, nyquist);
    data_notched = data;
    return;
end

% 计算归一化频率
wn_low = (notch_freq - notch_bw/2) / nyquist;
wn_high = (notch_freq + notch_bw/2) / nyquist;

% 确保频率在有效范围内 (0, 1)
wn_low = max(wn_low, 0.001);
wn_high = min(wn_high, 0.999);

if wn_low >= wn_high
    warning('陷波带宽设置无效，跳过滤波');
    data_notched = data;
    return;
end

wn = [wn_low, wn_high];

% 设计FIR带阻滤波器
try
    b_notch = fir1(fir_order, wn, 'stop');
catch ME
    warning(ME.identifier, '%s', ME.message);
    warning('FIR带阻滤波器设计失败');
    data_notched = data;
    return;
end

% 获取数据维度
n_channels = size(data, 1);

% 初始化输出
data_notched = data;

% 级联滤波（多次应用以获得更深的抑制）
for cascade_idx = 1:n_cascade
    temp_data = zeros(size(data_notched));
    
    for ch = 1:n_channels
        % 使用filtfilt进行零相位滤波
        temp_data(ch, :) = filtfilt(b_notch, 1, data_notched(ch, :));
    end
    
    data_notched = temp_data;
end

end
