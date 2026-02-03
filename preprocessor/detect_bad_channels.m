function [bad_channels, bad_types] = detect_bad_channels(data, options)
    % DETECT_BAD_CHANNELS 检测脑磁图数据中的坏通道
    %
    % 语法:
    %   [bad_channels, bad_types] = detect_bad_channels(data, options)
    %
    % 输入:
    %   data - N_channels × N_samples的脑磁图数据矩阵
    %   options - (可选)包含检测参数的结构体:
    %       .saturation_threshold - 饱和的最大绝对值(默认: 1e-10)
    %       .flat_var_threshold - 平坦通道的方差阈值(默认: 1e-28)
    %       .noise_std_threshold - 标准差阈值乘数(默认: 5.0)
    %
    % 输出:
    %   bad_channels - 1×M的坏通道索引向量
    %   bad_types - 1×M的单元数组,描述每个坏通道的问题类型
    %
    % 描述:
    %   检测三种类型的坏通道:
    %   1. 饱和通道 - 值达到或接近最大值的通道
    %   2. 平坦通道 - 方差非常低的通道
    %   3. 过度噪声通道 - 标准差 > 阈值 * 中位数标准差的通道
    %
    % 需求: 1.4
    %
    % 示例:
    %   [bad_ch, types] = detect_bad_channels(meg_data);
    %   fprintf('Found %d bad channels\n', length(bad_ch));
    
    % 验证输入
    if isempty(data)
        error('MEG:Preprocessor:EmptyInput', 'Input data is empty');
    end
    
    if ~isnumeric(data)
        error('MEG:Preprocessor:InvalidInput', 'Input data must be numeric');
    end
    
    % 设置默认选项
    if nargin < 2 || isempty(options)
        options = struct();
    end
    
    if ~isfield(options, 'saturation_threshold')
        options.saturation_threshold = 1e-10;  % 特斯拉(典型的脑磁图饱和水平)
    end
    
    if ~isfield(options, 'flat_var_threshold')
        options.flat_var_threshold = 1e-28;  % 非常小的方差阈值
    end
    
    if ~isfield(options, 'noise_std_threshold')
        options.noise_std_threshold = 5.0;  % 中位数标准差的乘数
    end
    
    [n_channels, n_samples] = size(data);
    
    % 初始化检测数组
    is_saturated = false(n_channels, 1);
    is_flat = false(n_channels, 1);
    is_noisy = false(n_channels, 1);
    
    % 计算每个通道的统计量
    channel_max = max(abs(data), [], 2);
    channel_var = var(data, 0, 2);
    channel_std = std(data, 0, 2);
    
    % 1. 检测饱和通道
    % 最大绝对值超过阈值的通道
    is_saturated = channel_max >= options.saturation_threshold;
    
    % 2. 检测平坦通道
    % 方差低于阈值的通道
    is_flat = channel_var < options.flat_var_threshold;
    
    % 3. 检测过度噪声通道
    % 标准差 > 阈值 * 中位数标准差的通道
    median_std = median(channel_std);
    if median_std > 0
        is_noisy = channel_std > (options.noise_std_threshold * median_std);
    end
    
    % 合并所有坏通道检测结果
    is_bad = is_saturated | is_flat | is_noisy;
    bad_channels = find(is_bad);
    
    % 为每个坏通道创建描述性标签
    bad_types = cell(1, length(bad_channels));
    for i = 1:length(bad_channels)
        ch_idx = bad_channels(i);
        types = {};
        
        if is_saturated(ch_idx)
            types{end+1} = 'saturated';
        end
        if is_flat(ch_idx)
            types{end+1} = 'flat';
        end
        if is_noisy(ch_idx)
            types{end+1} = 'noisy';
        end
        
        bad_types{i} = strjoin(types, '+');
    end
    
    % 转换为行向量
    bad_channels = bad_channels(:)';
    
end
