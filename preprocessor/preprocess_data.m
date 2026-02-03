function [data_clean, bad_channels] = preprocess_data(data_struct, options)
    % PREPROCESS_DATA 脑磁图数据的主预处理函数
    %
    % 语法:
    %   [data_clean, bad_channels] = preprocess_data(data_struct, options)
    %
    % 输入:
    %   data_struct - MEGData对象或包含以下字段的结构体:
    %       .meg_channels - 64×N的脑磁图数据矩阵
    %       .time - 1×N的时间向量
    %       .fs - 采样率
    %       .channel_labels - 通道标签(可选)
    %   options - (可选)包含预处理参数的结构体:
    %       .remove_dc - 是否去除直流分量(默认: true)
    %       .detect_bad - 是否检测坏通道(默认: true)
    %       .bad_threshold - 坏通道检测阈值(默认: 3.0)
    %       .saturation_threshold - 饱和检测阈值
    %       .flat_var_threshold - 平坦通道方差阈值
    %       .noise_std_threshold - 噪声检测阈值乘数
    %
    % 输出:
    %   data_clean - 包含预处理后数据的ProcessedData对象
    %   bad_channels - 1×M的坏通道索引向量
    %
    % 描述:
    %   对脑磁图数据应用预处理步骤:
    %   1. 去除直流分量(如果启用)
    %   2. 坏通道检测(如果启用)
    %
    % 需求: 1.3, 1.4
    %
    % 示例:
    %   [clean_data, bad_ch] = preprocess_data(meg_data);
    
    % 验证输入
    if nargin < 1
        error('MEG:Preprocessor:MissingInput', 'Data structure is required');
    end
    
    % 设置默认选项
    if nargin < 2 || isempty(options)
        options = struct();
    end
    
    if ~isfield(options, 'remove_dc')
        options.remove_dc = true;
    end
    
    if ~isfield(options, 'detect_bad')
        options.detect_bad = true;
    end

    if ~isfield(options, 'handle_missing')
        options.handle_missing = true;
    end

    if ~isfield(options, 'missing_method')
        options.missing_method = 'interpolate';
    end

    if ~isfield(options, 'missing_max_gap')
        options.missing_max_gap = 100;
    end

    if ~isfield(options, 'missing_verbose')
        options.missing_verbose = true;
    end
    
    % 从输入结构体中提取数据
    if isa(data_struct, 'MEGData')
        meg_data = data_struct.meg_channels;
        time_axis = data_struct.time;
        fs = data_struct.fs;
        if ~isempty(data_struct.channel_labels)
            channel_labels = data_struct.channel_labels;
        else
            channel_labels = arrayfun(@(i) sprintf('MEG%03d', i), 1:size(meg_data,1), 'UniformOutput', false)';
        end
    elseif isstruct(data_struct)
        meg_data = data_struct.meg_channels;
        time_axis = data_struct.time;
        fs = data_struct.fs;
        if isfield(data_struct, 'channel_labels') && ~isempty(data_struct.channel_labels)
            channel_labels = data_struct.channel_labels;
        else
            channel_labels = arrayfun(@(i) sprintf('MEG%03d', i), 1:size(meg_data,1), 'UniformOutput', false)';
        end
    else
        error('MEG:Preprocessor:InvalidInput', 'Input must be MEGData object or structure');
    end
    
    % 初始化输出
    data_clean = ProcessedData();
    data_clean.data = meg_data;
    data_clean.time = time_axis;
    data_clean.fs = fs;
    data_clean.channel_labels = channel_labels;
    bad_channels = [];
    
    % 步骤1: 去除直流分量
    if options.remove_dc
        data_clean.data = remove_dc(data_clean.data);
        data_clean = data_clean.add_processing_step('DC removal applied');
    end

    % 步骤1.5: 处理缺失数据（NaN）
    if options.handle_missing
        missing_options = struct(...
            'max_gap', options.missing_max_gap, ...
            'verbose', options.missing_verbose);
        [data_clean.data, missing_info] = handle_missing_data(...
            data_clean.data, options.missing_method, missing_options);
        if missing_info.has_missing
            data_clean = data_clean.add_processing_step(sprintf(...
                'Missing data handled (%s): %d NaN values in %d channels', ...
                options.missing_method, missing_info.n_missing, ...
                length(missing_info.missing_channels)));
        else
            data_clean = data_clean.add_processing_step('Missing data handled: no NaN values found');
        end
    end
    
    % 步骤2: 检测坏通道
    if options.detect_bad
        % 将相关选项传递给坏通道检测器
        detect_options = struct();
        if isfield(options, 'saturation_threshold')
            detect_options.saturation_threshold = options.saturation_threshold;
        end
        if isfield(options, 'flat_var_threshold')
            detect_options.flat_var_threshold = options.flat_var_threshold;
        end
        if isfield(options, 'noise_std_threshold')
            detect_options.noise_std_threshold = options.noise_std_threshold;
        end
        
        [bad_channels, bad_types] = detect_bad_channels(data_clean.data, detect_options);
        
        if ~isempty(bad_channels)
            log_msg = sprintf('Bad channel detection: found %d bad channels [%s]', ...
                length(bad_channels), num2str(bad_channels));
            data_clean = data_clean.add_processing_step(log_msg);
            
            % 记录每个坏通道的详细信息
            for i = 1:length(bad_channels)
                detail_msg = sprintf('  Channel %d (%s): %s', ...
                    bad_channels(i), ...
                    channel_labels{bad_channels(i)}, ...
                    bad_types{i});
                data_clean = data_clean.add_processing_step(detail_msg);
            end
        else
            data_clean = data_clean.add_processing_step('Bad channel detection: no bad channels found');
        end
    end
    
end
