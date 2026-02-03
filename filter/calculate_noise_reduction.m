function [noise_reduction_pct, power_before, power_after] = calculate_noise_reduction(data_before, data_after)
% CALCULATE_NOISE_REDUCTION 计算滤波后的噪声降低百分比
%
% 语法:
%   [noise_reduction_pct, power_before, power_after] = calculate_noise_reduction(data_before, data_after)
%
% 输入参数:
%   data_before - N_channels × N_samples 矩阵，滤波前的数据
%   data_after - N_channels × N_samples 矩阵，滤波后的数据
%
% 输出参数:
%   noise_reduction_pct - 1 × N_channels 向量，每个通道的噪声降低百分比
%   power_before - 1 × N_channels 向量，滤波前的信号功率
%   power_after - 1 × N_channels 向量，滤波后的信号功率
%
% 说明:
%   计算滤波实现的噪声降低:
%       noise_reduction_pct = 100 * (1 - power_after / power_before)
%   
%   功率计算为信号的均方值:
%       power = mean(signal.^2)
%
%   正百分比表示噪声降低（功率减少）。
%   有效的噪声降低百分比应为非负值。
%
% 需求: 3.5
%
% 示例:
%   [nr_pct, p_before, p_after] = calculate_noise_reduction(raw_data, filtered_data);
%   fprintf('平均噪声降低: %.2f%%\n', mean(nr_pct));

% 验证输入参数
if nargin < 2
    error('MEG:NoiseReduction:InsufficientInputs', ...
        'Both data_before and data_after are required');
end

[n_channels_before, n_samples_before] = size(data_before);
[n_channels_after, n_samples_after] = size(data_after);

if n_channels_before ~= n_channels_after
    error('MEG:NoiseReduction:ChannelMismatch', ...
        'Number of channels must match: before=%d, after=%d', ...
        n_channels_before, n_channels_after);
end

if n_samples_before ~= n_samples_after
    error('MEG:NoiseReduction:SampleMismatch', ...
        'Number of samples must match: before=%d, after=%d', ...
        n_samples_before, n_samples_after);
end

n_channels = n_channels_before;

% 初始化输出
power_before = zeros(1, n_channels);
power_after = zeros(1, n_channels);
noise_reduction_pct = zeros(1, n_channels);

% 计算每个通道的功率和噪声降低
for ch = 1:n_channels
    % 计算功率为均方值
    power_before(ch) = mean(data_before(ch, :).^2);
    power_after(ch) = mean(data_after(ch, :).^2);
    
    % 计算噪声降低百分比
    if power_before(ch) > 0
        noise_reduction_pct(ch) = 100 * (1 - power_after(ch) / power_before(ch));
    else
        % 如果滤波前功率为零，将噪声降低设为0
        % （无法从零功率信号中降低噪声）
        noise_reduction_pct(ch) = 0;
        warning('MEG:NoiseReduction:ZeroPowerBefore', ...
            'Channel %d has zero power before filtering', ch);
    end
end

% 如果噪声降低为负（功率增加）则发出警告
negative_channels = find(noise_reduction_pct < 0);
if ~isempty(negative_channels)
    warning('MEG:NoiseReduction:NegativeReduction', ...
        '%d channel(s) show negative noise reduction (power increased): %s', ...
        length(negative_channels), mat2str(negative_channels));
end

end
