function [meg_idx, ref_idx, stim_idx, trig_idx, labels] = identify_channels(n_columns)
% IDENTIFY_CHANNELS 识别和分离MEG、参考、刺激和触发通道
%
% 语法:
%   [meg_idx, ref_idx, stim_idx, trig_idx, labels] = identify_channels(n_columns)
%
% 输入参数:
%   n_columns  - 标量，数据中的总列数（应为68）
%
% 输出参数:
%   meg_idx    - 向量，MEG通道的索引（1-64）
%   ref_idx    - 向量，参考传感器通道的索引（65-67）
%   stim_idx   - 标量，刺激信号通道的索引（67或68）
%   trig_idx   - 标量，触发信号通道的索引（68或69）
%   labels     - 元胞数组，所有通道的标签
%
% 说明:
%   该函数根据MEG数据规范识别通道类型:
%   - 通道1-64: 头部MEG信号
%   - 通道65-67: 参考传感器
%   - 最后两个通道: 刺激和触发信号
%
% 需求: 实现需求 1.2
%
% 示例:
%   [meg, ref, stim, trig, labels] = identify_channels(68);
%
% 另见: load_lvm_data

% 验证输入参数
if nargin < 1
    error('MEG:ChannelIdentification:InvalidInput', ...
        'Number of columns must be provided');
end

if ~isnumeric(n_columns) || n_columns < 68
    error('MEG:ChannelIdentification:InvalidInput', ...
        'Expected at least 68 columns, got %d', n_columns);
end

% 根据规范定义通道索引
% 通道1-64: MEG头部通道
meg_idx = 1:64;

% 通道65-67: 参考传感器
ref_idx = 65:67;

% 最后两列是刺激和触发信号
% 如果恰好有68列:
%   第67列: 可能是最后一个参考传感器或刺激信号
%   第68列: 触发信号
% 如果有69列或更多:
%   第68列: 刺激信号
%   第69列: 触发信号

if n_columns == 68
    % 标准情况: 64 MEG + 3 参考 + 1 刺激 + 1 触发 = 69
    % 但如果只有68列，假设:
    % 64 MEG + 2 参考 + 1 刺激 + 1 触发
    % 或 64 MEG + 3 参考 + 1 合并的刺激/触发
    % 根据需求，最后两列是刺激和触发信号
    stim_idx = 67;
    trig_idx = 68;
    ref_idx = 65:66; % 这种情况下只有2个参考通道
elseif n_columns >= 69
    stim_idx = 68;
    trig_idx = 69;
else
    error('MEG:ChannelIdentification:InvalidColumns', ...
        'Unexpected number of columns: %d', n_columns);
end

% 创建通道标签
labels = cell(n_columns, 1);

% MEG通道标签 (MEG001 - MEG064)
for i = 1:64
    labels{i} = sprintf('MEG%03d', i);
end

% 参考传感器标签
for i = 1:length(ref_idx)
    labels{ref_idx(i)} = sprintf('REF%d', i);
end

% 刺激信号标签
labels{stim_idx} = 'STIMULUS';

% 触发信号标签
labels{trig_idx} = 'TRIGGER';

end
