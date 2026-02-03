function config = config_template()
    % config_template - MEG信号处理的默认配置
    %
    % 返回：
    %   config - 包含所有处理参数的配置结构体
    %
    % 使用方法：
    %   config = config_template();
    %   % 根据需要修改参数
    %   config.preprocessing.remove_dc = false;
    %   % 传递给处理函数
    
    config = struct();
    
    %% 数据加载参数
    config.data_loading = struct();
    config.data_loading.sampling_rate = 4800;  % Hz
    config.data_loading.gain = 1e-12;  % V到T的转换因子
    config.data_loading.n_meg_channels = 64;
    config.data_loading.n_ref_channels = 3;
    
    %% 预处理参数
    config.preprocessing = struct();
    config.preprocessing.remove_dc = true;  % 去除直流分量
    config.preprocessing.detect_bad = true;  % 检测坏通道
    config.preprocessing.bad_channel_threshold = 3.0;  % 标准差
    config.preprocessing.saturation_threshold = 0.95;  % 最大值的分数
    config.preprocessing.flat_channel_var_threshold = 1e-20;  % 方差阈值
    config.preprocessing.handle_missing = true;  % 处理缺失数据（NaN）
    config.preprocessing.missing_method = 'interpolate';  % 'interpolate'/'mark'/'zero'/'remove'
    config.preprocessing.missing_max_gap = 100;  % 最大插值间隙（样本数）
    config.preprocessing.missing_verbose = true;  % 输出缺失数据处理信息
    
    %% 尖峰噪声去除参数
    config.despike = struct();
    config.despike.method = 'median';  % 'median'或'wavelet'
    config.despike.median_window = 5;  % 中值滤波器窗口大小（样本数）
    config.despike.spike_threshold = 5.0;  % 标准差
    config.despike.wavelet_name = 'db4';  % 小波方法的小波类型
    config.despike.wavelet_level = 5;  % 分解层数
    
    %% 自适应滤波器参数
    config.adaptive_filter = struct();
    config.adaptive_filter.algorithm = 'RLS';  % 'LMS'或'RLS'
    config.adaptive_filter.filter_order = 10;  % 滤波器阶数
    config.adaptive_filter.mu = 0.01;  % LMS步长
    config.adaptive_filter.lambda = 0.995;  % RLS遗忘因子（0.99-1.0）
    config.adaptive_filter.delta = 1.0;  % RLS初始化参数
    
    %% 频率滤波器参数
    config.filters = struct();
    
    % 低通滤波器（用于AEF）
    config.filters.aef_cutoff = 30;  % Hz
    config.filters.aef_order = 100;  % 滤波器阶数
    
    % 带通滤波器（用于ASSR）
    config.filters.assr_center = 89;  % Hz
    config.filters.assr_bandwidth = 2;  % Hz（±2Hz表示87-91Hz）
    config.filters.assr_order = 100;  % 滤波器阶数
    
    % 陷波滤波器（用于工频干扰）
    config.filters.notch_frequencies = [50, 100, 150, 200, 250];  % Hz
    config.filters.notch_bandwidth = 2;  % Hz
    config.filters.notch_order = 100;  % 滤波器阶数
    
    %% 触发检测参数
    config.trigger = struct();
    config.trigger.threshold = 0.5;  % 检测阈值（归一化）
    config.trigger.min_interval = 0.5;  % 触发之间的最小间隔（秒）
    config.trigger.edge = 'rising';  % 'rising'或'falling'
    
    %% 时程提取参数
    config.epoching = struct();
    config.epoching.pre_time = 0.2;  % 触发前时间（秒）
    config.epoching.post_time = 0.8;  % 触发后时间（秒）
    config.epoching.baseline_correction = true;  % 应用基线校正
    config.epoching.baseline_window = [-0.2, 0];  % 基线窗口（秒）
    
    %% 分析参数
    config.analysis = struct();
    
    % 功率谱密度计算
    config.analysis.psd_method = 'pwelch';  % 'pwelch'或'periodogram'
    config.analysis.psd_window = 'hamming';  % 窗口类型
    config.analysis.psd_nfft = 2048;  % FFT长度
    config.analysis.psd_overlap = 0.5;  % 重叠分数
    
    % 信噪比计算
    config.analysis.snr_signal_bandwidth = 0.5;  % 目标频率周围的Hz
    config.analysis.snr_noise_bandwidth = 2.0;  % 噪声估计的Hz
    config.analysis.snr_noise_offset = 3.0;  % 与信号的Hz偏移用于噪声
    
    % 收敛分析
    config.convergence = struct();
    config.convergence.threshold = 0.9;  % 相关阈值
    config.convergence.n_trials_range = 10:10:200;  % 要测试的试次数
    config.convergence.n_iterations = 100;  % 随机采样迭代次数
    
    %% 可视化参数
    config.visualization = struct();
    config.visualization.figure_format = 'png';  % 'png'、'pdf'、'fig'
    config.visualization.figure_dpi = 300;  % 分辨率
    config.visualization.line_width = 1.5;
    config.visualization.font_size = 12;
    
    %% 输出参数
    config.output = struct();
    config.output.save_intermediate = false;  % 保存中间结果
    config.output.output_dir = 'results';  % 输出目录
    config.output.save_format = 'mat';  % 'mat'或'csv'
    
    %% 任务特定参数
    config.mission1 = struct();
    config.mission1.target_frequency = 17;  % Hz
    config.mission1.apply_hfc = true;  % 应用均匀场校正
    
    config.mission2 = struct();
    config.mission2.process_aef = true;  % 处理AEF成分
    config.mission2.process_assr = true;  % 处理ASSR成分
    config.mission2.run_convergence = true;  % 运行收敛分析
    config.mission2.aef_cutoff = 30;  % Hz - AEF的低通截止频率
    config.mission2.assr_center = 89;  % Hz - ASSR的带通中心频率
    config.mission2.assr_bandwidth = 2;  % Hz - ASSR的带通带宽
    config.mission2.trigger_threshold = 2.5;  % 触发检测阈值
    config.mission2.min_trigger_interval = 0.5;  % 触发之间的最小间隔（秒）
    config.mission2.pre_time = 0.2;  % 触发前时间（秒）
    config.mission2.post_time = 0.8;  % 触发后时间（秒）
    config.mission2.convergence_threshold = 0.9;  % 收敛的相关阈值
    
end
