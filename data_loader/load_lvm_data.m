function data_struct = load_lvm_data(file_path, sampling_rate, gain, varargin)
% LOAD_LVM_DATA 加载和解析LVM格式的脑磁图(MEG)数据文件
%
% 语法:
%   data_struct = load_lvm_data(file_path, sampling_rate, gain)
%   data_struct = load_lvm_data(file_path, sampling_rate, gain, 'Name', Value, ...)
%
% 输入参数:
%   file_path      - 字符串，LVM文件路径
%   sampling_rate  - 标量，采样率(Hz)（例如：4800）
%   gain           - 标量，从V到T的增益转换系数（例如：1e6 用于真实数据）
%
% 可选参数:
%   'DualAxis'     - 是否返回双轴数据（默认: false）
%   'ReturnRaw'    - 是否返回原始未分离数据（默认: false）
%   'ApplyGain'    - 是否应用增益转换（默认: true）
%
% 输出参数:
%   data_struct    - MEGData对象，包含以下字段:
%                    .meg_channels: 64×N矩阵（单轴）或 128×N矩阵（双轴），头部MEG通道数据
%                    .ref_channels: 3×N矩阵（单轴）或 6×N矩阵（双轴），参考传感器数据
%                    .stimulus: 1×N向量，刺激信号（sync通道）
%                    .trigger: 1×N向量，触发信号（digital通道）
%                    .time: 1×N向量，时间轴
%                    .fs: 采样率
%                    .gain: 增益系数
%                    .channel_labels: 通道标签
%
% 支持的数据格式:
%   - 68列格式: 简化格式（仅单轴Z数据）
%   - 139列格式: 完整OPM数据（136通道 = 68 sensor × 2 axis + 3 extra）
%
% 需求: 实现需求 1.1, 1.5
%
% 示例:
%   % 加载单轴数据（默认）
%   data = load_lvm_data('data_1.lvm', 4800, 1e6);
%
%   % 加载双轴数据
%   data = load_lvm_data('data_1.lvm', 4800, 1e6, 'DualAxis', true);
%
% 另见: identify_channels, lvm_import, opm_preprocess

% 解析输入参数
p = inputParser;
addRequired(p, 'file_path', @(x) ischar(x) || isstring(x));
addRequired(p, 'sampling_rate', @(x) isnumeric(x) && x > 0);
addRequired(p, 'gain', @(x) isnumeric(x) && x > 0);
addParameter(p, 'DualAxis', false, @islogical);
addParameter(p, 'ReturnRaw', false, @islogical);
addParameter(p, 'ApplyGain', true, @islogical);
parse(p, file_path, sampling_rate, gain, varargin{:});

dual_axis = p.Results.DualAxis;
return_raw = p.Results.ReturnRaw;
apply_gain = p.Results.ApplyGain;

% 检查文件是否存在
if ~exist(file_path, 'file')
    error('MEG:DataLoader:FileNotFound', ...
        'LVM file not found: %s\nPlease check the file path.', file_path);
end

% 调用lvm_import解析LVM文件
try
    raw_data = lvm_import(file_path, 0); % verbose=0 静默操作
catch ME
    error('MEG:DataLoader:ParseError', ...
        'Failed to parse LVM file: %s\nError: %s', file_path, ME.message);
end

% 从第一个数据段提取数据
if ~isfield(raw_data, 'Segment1')
    error('MEG:DataLoader:NoData', ...
        'No data segments found in LVM file: %s', file_path);
end

segment_data = raw_data.Segment1.data;
[n_samples, n_cols] = size(segment_data);

% 创建MEGData对象
data_struct = MEGData();

% 根据列数判断数据格式
if n_cols == 139
    % 完整OPM数据格式: 136通道 (68 sensor × 2 axis) + 3 extra (时间/sync/trigger)
    data_matrix = segment_data';  % 转置为 columns × samples
    
    % 应用增益（如果需要）
    if apply_gain
        data_scaled = data_matrix(2:137, :) * gain;  % 跳过第一列（时间）
    else
        data_scaled = data_matrix(2:137, :);
    end
    
    % 提取刺激和触发信号
    sync_signal = data_matrix(138, :) - data_matrix(138, 1);  % 基线校正
    digi_signal = data_matrix(139, :);
    
    if dual_axis
        % 返回双轴数据 (128 MEG通道 + 6 REF通道)
        % Y轴在偶数索引 (2, 4, 6, ...)，Z轴在奇数索引 (1, 3, 5, ...)
        channel_Y = 2:2:136;
        channel_Z = 1:2:136;
        
        % MEG通道 (1-64 of each axis)
        meg_Z = data_scaled(channel_Z(1:64), :);
        meg_Y = data_scaled(channel_Y(1:64), :);
        
        % 交错排列: Z1, Y1, Z2, Y2, ...
        data_struct.meg_channels = zeros(128, n_samples);
        for i = 1:64
            data_struct.meg_channels(2*i-1, :) = meg_Z(i, :);
            data_struct.meg_channels(2*i, :) = meg_Y(i, :);
        end
        
        % 参考通道 (sensor 65-67)
        ref_Z = data_scaled(channel_Z(65:67), :);
        ref_Y = data_scaled(channel_Y(65:67), :);
        data_struct.ref_channels = [ref_Z; ref_Y];  % 6×N
        
    else
        % 返回单轴数据（仅Z轴，兼容原有流程）
        channel_Z = 1:2:136;
        
        % MEG通道 (sensor 1-64 的Z轴)
        data_struct.meg_channels = data_scaled(channel_Z(1:64), :);
        
        % 参考通道 (sensor 65-67 的Z轴)
        data_struct.ref_channels = data_scaled(channel_Z(65:67), :);
    end
    
    data_struct.stimulus = sync_signal;
    data_struct.trigger = digi_signal;
    
elseif n_cols == 68
    % 简化格式（原有68列格式）
    [meg_idx, ref_idx, stim_idx, trig_idx, ~] = identify_channels(n_cols);
    
    % 应用增益
    if apply_gain
        data_struct.meg_channels = segment_data(:, meg_idx)' * gain;
        data_struct.ref_channels = segment_data(:, ref_idx)' * gain;
    else
        data_struct.meg_channels = segment_data(:, meg_idx)';
        data_struct.ref_channels = segment_data(:, ref_idx)';
    end
    
    data_struct.stimulus = segment_data(:, stim_idx)';
    data_struct.trigger = segment_data(:, trig_idx)';
    
else
    % 尝试自适应处理
    warning('MEG:DataLoader:UnexpectedColumns', ...
        'Unexpected column count: %d. Attempting adaptive parsing.', n_cols);
    
    % 假设前面的列是数据，最后几列是额外信号
    if n_cols > 68
        n_data_cols = n_cols - 3;  % 假设3列额外信号
        data_matrix = segment_data';
        
        if apply_gain
            data_scaled = data_matrix(1:n_data_cols, :) * gain;
        else
            data_scaled = data_matrix(1:n_data_cols, :);
        end
        
        % 简单分配
        n_meg = min(64, n_data_cols);
        data_struct.meg_channels = data_scaled(1:n_meg, :);
        
        if n_data_cols > 64
            n_ref = min(3, n_data_cols - 64);
            data_struct.ref_channels = data_scaled(65:64+n_ref, :);
        else
            data_struct.ref_channels = zeros(3, n_samples);
        end
        
        if n_cols >= n_data_cols + 2
            data_struct.stimulus = data_matrix(n_data_cols + 1, :);
            data_struct.trigger = data_matrix(n_data_cols + 2, :);
        else
            data_struct.stimulus = zeros(1, n_samples);
            data_struct.trigger = zeros(1, n_samples);
        end
    else
        error('MEG:DataLoader:InvalidColumns', ...
            'Cannot parse file with %d columns: %s', n_cols, file_path);
    end
end

% 基线校正（去除初始值）
data_struct.meg_channels = data_struct.meg_channels - data_struct.meg_channels(:, 1);
data_struct.ref_channels = data_struct.ref_channels - data_struct.ref_channels(:, 1);

% 存储采样率和增益
data_struct.fs = sampling_rate;
data_struct.gain = gain;

% 创建时间轴
data_struct.time = (0:n_samples-1) / sampling_rate;

% 生成通道标签
data_struct = data_struct.set_channel_labels();

% 初始化坏通道为空
data_struct.bad_channels = [];

end
