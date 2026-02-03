function config = default_config()
    % default_config - MEG信号处理的综合默认配置
    %
    % 此函数返回一个配置结构体，包含MEG信号处理流程的所有可调参数。
    % 用户可以修改这些参数以根据其特定需求自定义处理工作流。
    %
    % 语法：
    %   config = default_config()
    %
    % 输出：
    %   config - 包含按处理模块组织的所有配置参数的结构体
    %
    % 使用示例：
    %   % 获取默认配置
    %   config = default_config();
    %   
    %   % 修改特定参数
    %   config.preprocessing.bad_channel_threshold = 4.0;
    %   config.adaptive_filter.algorithm = 'LMS';
    %   config.filters.aef_cutoff = 40;
    %   
    %   % 在处理流程中使用
    %   data = load_lvm_data('data.lvm', config.data_loading.sampling_rate, ...
    %                        config.data_loading.gain);
    %   [data_clean, bad_ch] = preprocess_data(data, config.preprocessing);
    %
    % 配置部分：
    %   - data_loading: 加载LVM文件的参数
    %   - preprocessing: 直流偏移去除和坏通道检测
    %   - despike: 尖峰噪声去除参数
    %   - adaptive_filter: LMS/RLS自适应滤波
    %   - filters: 频域滤波器（低通、带通、陷波）
    %   - trigger: 触发检测参数
    %   - epoching: 试次提取和对齐
    %   - analysis: 功率谱密度、信噪比和收敛分析
    %   - convergence: 收敛分析参数
    %   - visualization: 绘图和图形参数
    %   - output: 文件保存和导出选项
    %   - mission1: 任务1特定参数
    %   - mission2: 任务2特定参数
    %
    % 另见：config_template, process_mission1, process_mission2
    
    % 作者：MEG信号处理团队
    % 日期：2024
    % 版本：1.0
    
    config = struct();
    
    %% ========================================================================
    %  路径配置
    %  ========================================================================
    % 数据文件和外部工具的路径配置
    
    config.paths = struct();
    
    % data_root: 数据文件根目录
    % 默认：'Y:\Yibo\Tsinghua_homework'（真实数据位置）
    % 可修改为本地路径或网络路径
    config.paths.data_root = 'Y:\Yibo\Tsinghua_homework';
    
    % mission1_dir: Mission1数据子目录名
    % 默认：'Mission1'（包含 data_1.lvm 到 data_21.lvm）
    config.paths.mission1_dir = 'Mission1';
    
    % mission2_dir: Mission2数据子目录名
    % 默认：'Mission2'（包含人类听觉响应数据）
    config.paths.mission2_dir = 'Mission2';
    
    % auxiliary_data: 辅助数据文件路径（.mat文件）
    % 包含：data_temp30s.mat, layout_zkzyopm.mat, grad_transformed.mat 等
    config.paths.auxiliary_data = 'Y:\Yibo\Tsinghua_homework';
    
    % fieldtrip_path: FieldTrip工具箱路径
    % 默认：项目目录下的 fieldtrip 文件夹
    % 设置为空字符串禁用FieldTrip功能
    config.paths.fieldtrip_path = fullfile(fileparts(mfilename('fullpath')), 'fieldtrip');
    
    %% ========================================================================
    %  数据加载参数
    %  ========================================================================
    % 用于加载和解析LVM格式MEG数据文件的参数
    
    config.data_loading = struct();
    
    % sampling_rate: 数据采集采样率（Hz）
    % 默认：4800 Hz（OPM-MEG系统的典型值）
    config.data_loading.sampling_rate = 4800;
    
    % gain: 从电压（V）到磁场（T）的转换因子
    % 默认：1e6（真实OPM数据的标准增益）
    % 注意：原始代码使用1e6将V转换为fT级别
    config.data_loading.gain = 1e6;
    
    % n_meg_channels: 头部安装的MEG传感器通道数
    % 默认：64（LVM文件中的通道1-64）
    config.data_loading.n_meg_channels = 64;
    
    % n_ref_channels: 用于噪声消除的参考传感器通道数
    % 默认：3（LVM文件中的通道65-67）
    config.data_loading.n_ref_channels = 3;
    
    %% ========================================================================
    %  预处理参数
    %  ========================================================================
    % 用于初始数据清理和质量评估的参数
    
    config.preprocessing = struct();
    
    % remove_dc: 是否从MEG通道中去除直流偏移
    % 默认：true（推荐用于所有MEG数据）
    % 设置为false可能对调试或特定分析有用
    config.preprocessing.remove_dc = true;
    
    % detect_bad: 是否自动检测坏通道
    % 默认：true（推荐排除有问题的通道）
    config.preprocessing.detect_bad = true;
    
    % bad_channel_threshold: 噪声检测的标准差数
    % 默认：3.0（噪声 > 3个标准差的通道被标记为坏通道）
    % 增加到4.0或5.0以进行更宽松的检测
    % 减少到2.0以进行更严格的检测
    config.preprocessing.bad_channel_threshold = 3.0;
    
    % saturation_threshold: 检测饱和的最大值分数
    % 默认：0.95（达到最大值95%的通道被视为饱和）
    % 范围：0.9到0.99
    config.preprocessing.saturation_threshold = 0.95;
    
    % flat_channel_var_threshold: 平坦通道检测的方差阈值
    % 默认：1e-20（方差低于此值的通道被视为平坦）
    % 根据预期信号水平调整
    config.preprocessing.flat_channel_var_threshold = 1e-20;

    % handle_missing: 是否处理缺失数据（NaN）
    % 默认：true（推荐进行插值或标记）
    config.preprocessing.handle_missing = true;

    % missing_method: 缺失数据处理方法
    % 选项：'interpolate'、'mark'、'zero'、'remove'
    % 默认：'interpolate'
    config.preprocessing.missing_method = 'interpolate';

    % missing_max_gap: 最大插值间隙（样本数）
    % 默认：100
    config.preprocessing.missing_max_gap = 100;

    % missing_verbose: 是否输出缺失数据处理信息
    % 默认：true
    config.preprocessing.missing_verbose = true;
    
    %% ========================================================================
    %  OPM双轴预处理参数
    %  ========================================================================
    % OPM-MEG特有的双轴数据处理参数（用于真实数据）
    
    config.opm_preprocessing = struct();
    
    % use_dual_axis: 是否启用双轴(Y+Z)数据处理
    % 默认：true（真实OPM数据需要）
    % 设置为false使用简化的单轴处理
    config.opm_preprocessing.use_dual_axis = true;
    
    % use_real_data: 是否使用真实数据处理流程
    % 默认：false（使用合成数据演示）
    % 设置为true启用完整的OPM预处理流程
    config.opm_preprocessing.use_real_data = false;
    
    % --- 实时校准参数 ---
    % Y轴校准参考频率（Hz）
    config.opm_preprocessing.ref_freq_Y = 240;
    % Y轴目标峰值（用于增益校准）
    config.opm_preprocessing.target_peak_Y = 62400;
    % Z轴校准参考频率（Hz）
    config.opm_preprocessing.ref_freq_Z = 320;
    % Z轴目标峰值
    config.opm_preprocessing.target_peak_Z = 55600;
    
    % --- 深度陷波滤波参数 ---
    % notch_bandwidth: 陷波带宽（Hz）
    config.opm_preprocessing.notch_bandwidth = 10;
    % notch_order: FIR滤波器阶数
    config.opm_preprocessing.notch_order = 400;
    % notch_cascade: 级联次数（更多次数 = 更深抑制）
    config.opm_preprocessing.notch_cascade = 6;
    
    % --- 三轴参考传感器降噪参数 ---
    % ref_sensor_indices: 参考传感器索引（65, 66, 67号传感器）
    config.opm_preprocessing.ref_sensor_indices = [65, 66, 67];
    % rls_forgetting_factor: RLS遗忘因子
    config.opm_preprocessing.rls_forgetting_factor = 0.995;
    % rls_window_size: 协方差估计窗口大小
    config.opm_preprocessing.rls_window_size = 1024;
    % rls_min_samples: 开始降噪的最小样本数
    config.opm_preprocessing.rls_min_samples = 100;
    
    % --- HFC（均匀场校正）参数 ---
    % apply_hfc: 是否应用双轴联合HFC
    config.opm_preprocessing.apply_hfc = true;
    % hfc_method: HFC方法（'svd' 或 'projection'）
    config.opm_preprocessing.hfc_method = 'svd';
    
    % --- 传感器深度调整 ---
    % depth_adjustment: 传感器向头模外侧后退距离（mm）
    config.opm_preprocessing.depth_adjustment = 5.5;
    
    % --- 通道布局映射 ---
    % layout_idx: 探头在头盔上的位置与数据通道的对应表
    config.opm_preprocessing.layout_idx = [27 17 2 36 9 30 13 3 16 33 7 4 14 59 43 40 42 60 46 57 41 37 63 44 45 19 26 18 56 53 10 54 32 64 29 15 28 52 58 12 1 51 62 31 34 6 39 22 24 11 55 38 61 47 50 23 20 25 5 21 49 48 8 35];
    
    % --- FieldTrip集成 ---
    % use_fieldtrip: 是否使用FieldTrip进行高级处理
    config.opm_preprocessing.use_fieldtrip = true;
    % interactive_bad_channel: 是否交互式选择坏通道
    config.opm_preprocessing.interactive_bad_channel = false;
    
    %% ========================================================================
    %  尖峰噪声去除参数
    %  ========================================================================
    % 用于从MEG数据中去除瞬态尖峰伪影的参数
    
    config.despike = struct();
    
    % method: 尖峰去除算法
    % 选项：'median'（中值滤波）或'wavelet'（小波阈值）
    % 默认：'median'（对典型尖峰更快且更稳健）
    % 使用'wavelet'进行更复杂的去噪
    config.despike.method = 'median';
    
    % median_window: 中值滤波器的窗口大小（样本数）
    % 默认：5个样本（在4800 Hz时约1 ms）
    % 对于更宽的尖峰增加，对于更窄的尖峰减少
    % 范围：3到11（推荐奇数）
    config.despike.median_window = 5;
    
    % spike_threshold: 尖峰检测阈值（标准差）
    % 默认：5.0（距离中值 > 5个标准差的点被视为尖峰）
    % 增加以仅检测极端尖峰
    % 减少以检测更细微的伪影
    config.despike.spike_threshold = 5.0;
    
    % wavelet_name: 基于小波去噪的小波族
    % 默认：'db4'（Daubechies 4）
    % 其他选项：'sym4'、'coif3'、'haar'
    config.despike.wavelet_name = 'db4';
    
    % wavelet_level: 小波变换的分解层数
    % 默认：5（提供良好的时频分辨率）
    % 范围：3到7（更高 = 更多频带）
    config.despike.wavelet_level = 5;
    
    %% ========================================================================
    %  自适应滤波器参数
    %  ========================================================================
    % 使用参考传感器进行自适应噪声消除的参数
    
    config.adaptive_filter = struct();
    
    % algorithm: 自适应滤波算法
    % 选项：'LMS'（最小均方）或'RLS'（递归最小二乘）
    % 默认：'RLS'（收敛更快但计算成本更高）
    % 使用'LMS'以降低内存使用和更简单的实现
    config.adaptive_filter.algorithm = 'RLS';
    
    % filter_order: 滤波器抽头数（自适应滤波器长度）
    % 默认：10（性能和复杂性之间的良好平衡）
    % 对于更复杂的噪声模式增加（最多50）
    % 对于更快的处理减少（最少5）
    config.adaptive_filter.filter_order = 10;
    
    % mu: LMS算法的步长（学习率）
    % 默认：0.01（对典型MEG数据稳定收敛）
    % 范围：0.001到0.1
    % 较小的值 = 较慢但更稳定的收敛
    % 较大的值 = 较快但可能不稳定的收敛
    config.adaptive_filter.mu = 0.01;
    
    % lambda: RLS算法的遗忘因子
    % 默认：0.995（平衡跟踪和稳定性）
    % 范围：0.99到1.0
    % 接近1.0的值 = 更长的记忆，更适合平稳噪声
    % 接近0.99的值 = 更短的记忆，更适合非平稳噪声
    config.adaptive_filter.lambda = 0.995;
    
    % delta: RLS协方差矩阵的初始化参数
    % 默认：1.0（标准初始化）
    % 增加以进行更积极的初始自适应
    config.adaptive_filter.delta = 1.0;
    
    %% ========================================================================
    %  频率滤波器参数
    %  ========================================================================
    % 频域滤波（低通、带通、陷波）的参数
    
    config.filters = struct();
    
    % --- 低通滤波器（用于AEF提取） ---
    % aef_cutoff: 低通滤波器的截止频率（Hz）
    % 默认：30 Hz（捕获慢AEF成分）
    % 替代：40 Hz用于更宽的频率范围
    % 范围：20到50 Hz
    config.filters.aef_cutoff = 30;
    
    % aef_order: 低通滤波器的滤波器阶数
    % 默认：100（提供尖锐的过渡带）
    % 更高的阶数 = 更尖锐的截止但更多计算
    % 范围：50到200
    config.filters.aef_order = 100;
    
    % --- 带通滤波器（用于ASSR提取） ---
    % assr_center: 带通滤波器的中心频率（Hz）
    % 默认：89 Hz（听觉稳态响应频率）
    % 必须与刺激调制频率匹配
    config.filters.assr_center = 89;
    
    % assr_bandwidth: 带通滤波器的带宽（Hz）
    % 默认：2 Hz（±2 Hz表示通带为87-91 Hz）
    % 增加以捕获更宽的频率
    % 减少以进行更窄、更选择性的滤波
    % 范围：1到5 Hz
    config.filters.assr_bandwidth = 2;
    
    % assr_order: 带通滤波器的滤波器阶数
    % 默认：100（提供良好的频率选择性）
    % 范围：50到200
    config.filters.assr_order = 100;
    
    % --- 陷波滤波器（用于工频干扰去除） ---
    % notch_frequencies: 要陷波的频率（Hz）
    % 默认：[50, 100, 150, 200, 250]（50 Hz及其谐波）
    % 对于60 Hz地区，使用：[60, 120, 180, 240]
    config.filters.notch_frequencies = [50, 100, 150, 200, 250];
    
    % notch_bandwidth: 每个陷波的带宽（Hz）
    % 默认：2 Hz（去除每个陷波频率周围±1 Hz）
    % 增加以获得更宽的陷波（可能去除更多信号）
    % 范围：1到5 Hz
    config.filters.notch_bandwidth = 2;
    
    % notch_order: 陷波滤波器的滤波器阶数
    % 默认：100（提供深陷波）
    % 范围：50到200
    config.filters.notch_order = 100;
    
    %% ========================================================================
    %  触发检测参数
    %  ========================================================================
    % 从触发通道检测刺激开始时间的参数
    
    config.trigger = struct();
    
    % threshold: 触发信号的检测阈值
    % 默认：0.5（归一化，假设触发信号为0-1）
    % 根据实际触发信号幅度调整
    % 范围：0.1到0.9
    config.trigger.threshold = 0.5;
    
    % min_interval: 连续触发之间的最小时间（秒）
    % 默认：0.5秒（防止同一触发的双重检测）
    % 应小于实际刺激间隔
    % 范围：0.1到2.0秒
    config.trigger.min_interval = 0.5;
    
    % edge: 要检测的边沿类型
    % 选项：'rising'（低到高）或'falling'（高到低）
    % 默认：'rising'（触发信号最常见）
    config.trigger.edge = 'rising';
    
    %% ========================================================================
    %  时程提取参数
    %  ========================================================================
    % 在触发事件周围提取试次（时程）的参数
    
    config.epoching = struct();
    
    % pre_time: 触发前包含在时程中的时间（秒）
    % 默认：0.2秒（200 ms基线期）
    % 增加以捕获更早的活动
    % 范围：0.1到0.5秒
    config.epoching.pre_time = 0.2;
    
    % post_time: 触发后包含在时程中的时间（秒）
    % 默认：0.8秒（与pre_time=0.2一起形成1秒试次）
    % 根据预期响应持续时间调整
    % 范围：0.5到2.0秒
    config.epoching.post_time = 0.8;
    
    % baseline_correction: 是否对时程应用基线校正
    % 默认：true（去除刺激前基线）
    % 推荐用于诱发响应分析
    config.epoching.baseline_correction = true;
    
    % baseline_window: 基线计算的时间窗口（秒）
    % 默认：[-0.2, 0]（整个刺激前期）
    % 必须在pre_time范围内
    config.epoching.baseline_window = [-0.2, 0];
    
    %% ========================================================================
    %  分析参数
    %  ========================================================================
    % 信号分析（功率谱密度、信噪比等）的参数
    
    config.analysis = struct();
    
    % --- 功率谱密度（PSD） ---
    % psd_method: 功率谱密度计算方法
    % 选项：'pwelch'（Welch方法）或'periodogram'
    % 默认：'pwelch'（更稳健，减少方差）
    config.analysis.psd_method = 'pwelch';
    
    % psd_window: 功率谱密度计算的窗函数
    % 选项：'hamming'、'hann'、'blackman'、'rectangular'
    % 默认：'hamming'（良好的频率分辨率）
    config.analysis.psd_window = 'hamming';
    
    % psd_nfft: 功率谱密度计算的FFT长度
    % 默认：2048（提供良好的频率分辨率）
    % 增加以获得更精细的频率分辨率
    % 必须是2的幂次以提高效率
    config.analysis.psd_nfft = 2048;
    
    % psd_overlap: Welch方法的重叠分数
    % 默认：0.5（50%重叠，标准做法）
    % 范围：0到0.75
    config.analysis.psd_overlap = 0.5;
    
    % --- 信噪比（SNR） ---
    % snr_signal_bandwidth: 目标频率周围信号的带宽（Hz）
    % 默认：0.5 Hz（目标周围±0.25 Hz）
    % 范围：0.2到2.0 Hz
    config.analysis.snr_signal_bandwidth = 0.5;
    
    % snr_noise_bandwidth: 噪声估计的带宽（Hz）
    % 默认：2.0 Hz（更宽的频带以获得稳健的噪声估计）
    % 范围：1.0到5.0 Hz
    config.analysis.snr_noise_bandwidth = 2.0;
    
    % snr_noise_offset: 噪声估计与信号的频率偏移（Hz）
    % 默认：3.0 Hz（避免信号泄漏到噪声估计中）
    % 范围：2.0到10.0 Hz
    config.analysis.snr_noise_offset = 3.0;
    
    %% ========================================================================
    %  收敛分析参数
    %  ========================================================================
    % 确定所需最小试次数的参数
    
    config.convergence = struct();
    
    % threshold: 收敛标准的相关阈值
    % 默认：0.9（与总平均的90%相关性）
    % 增加以获得更严格的收敛（例如0.95）
    % 减少以获得更宽松的收敛（例如0.85）
    % 范围：0.8到0.99
    config.convergence.threshold = 0.9;
    
    % n_trials_range: 要测试的试次数范围
    % 默认：10:10:200（测试10、20、30、...、200个试次）
    % 根据可用试次总数调整
    config.convergence.n_trials_range = 10:10:200;
    
    % n_iterations: 每个试次数的随机采样迭代次数
    % 默认：100（提供稳健的统计）
    % 增加以获得更稳定的估计（较慢）
    % 减少以进行更快的分析（较不稳定）
    % 范围：50到500
    config.convergence.n_iterations = 100;
    
    %% ========================================================================
    %  可视化参数
    %  ========================================================================
    % 绘图和图形生成的参数
    
    config.visualization = struct();
    
    % figure_format: 保存图形的输出格式
    % 选项：'png'、'pdf'、'fig'、'eps'
    % 默认：'png'（良好质量，广泛兼容）
    config.visualization.figure_format = 'png';
    
    % figure_dpi: 光栅图形的分辨率（每英寸点数）
    % 默认：300（出版质量）
    % 使用150用于屏幕查看，600用于高质量打印
    config.visualization.figure_dpi = 300;
    
    % line_width: 绘制线条的宽度
    % 默认：1.5（良好的可见性）
    % 范围：0.5到3.0
    config.visualization.line_width = 1.5;
    
    % font_size: 轴标签和标题的字体大小
    % 默认：12点（可读）
    % 范围：8到16
    config.visualization.font_size = 12;
    
    %% ========================================================================
    %  输出参数
    %  ========================================================================
    % 保存结果和中间数据的参数
    
    config.output = struct();
    
    % save_intermediate: 是否保存中间处理结果
    % 默认：false（节省磁盘空间）
    % 设置为true用于调试或详细分析
    config.output.save_intermediate = false;
    
    % output_dir: 保存结果的目录
    % 默认：'results'（如果不存在则创建）
    % 可以是绝对路径或相对路径
    config.output.output_dir = 'results';
    
    % save_format: 保存处理数据的格式
    % 选项：'mat'（MATLAB格式）或'csv'（文本格式）
    % 默认：'mat'（保留数据结构）
    config.output.save_format = 'mat';
    
    %% ========================================================================
    %  任务1特定参数
    %  ========================================================================
    % 任务1（模体数据处理）特定的参数
    
    config.mission1 = struct();
    
    % target_frequency: 模体数据中的预期信号频率（Hz）
    % 默认：17 Hz（如任务1中指定）
    config.mission1.target_frequency = 17;
    
    % apply_hfc: 是否应用均匀场校正
    % 默认：true（推荐用于模体数据）
    % HFC使用参考传感器去除共模噪声
    config.mission1.apply_hfc = true;
    
    %% ========================================================================
    %  任务2特定参数
    %  ========================================================================
    % 任务2（人类听觉响应处理）特定的参数
    
    config.mission2 = struct();
    
    % process_aef: 是否提取和分析AEF成分
    % 默认：true（低频听觉诱发场）
    config.mission2.process_aef = true;
    
    % process_assr: 是否提取和分析ASSR成分
    % 默认：true（89 Hz听觉稳态响应）
    config.mission2.process_assr = true;
    
    % run_convergence: 是否执行收敛分析
    % 默认：true（确定最小试次数）
    config.mission2.run_convergence = true;
    
    % aef_cutoff: AEF提取的低通截止频率（Hz）
    % 默认：30 Hz（捕获慢诱发响应）
    config.mission2.aef_cutoff = 30;
    
    % assr_center: ASSR提取的带通中心频率（Hz）
    % 默认：89 Hz（匹配刺激调制频率）
    config.mission2.assr_center = 89;
    
    % assr_bandwidth: ASSR提取的带通带宽（Hz）
    % 默认：2 Hz（±2 Hz通带）
    config.mission2.assr_bandwidth = 2;
    
    % trigger_threshold: 触发检测的阈值
    % 默认：'auto'（自动计算为信号最大值的一半）
    % 也可以设置为具体数值
    config.mission2.trigger_threshold = 'auto';
    
    % skip_samples_after_trigger: 检测到trigger后跳过的采样点数
    % 默认：5000（防止重复检测，约1秒@4800Hz）
    config.mission2.skip_samples_after_trigger = 5000;
    
    % min_trigger_interval: 触发之间的最小间隔（秒）
    % 默认：1.0秒（防止双重检测，与刺激时长匹配）
    config.mission2.min_trigger_interval = 1.0;
    
    % pre_time: 时程中触发前的时间（秒）
    % 默认：0.2秒（基线期）
    config.mission2.pre_time = 0.2;
    
    % post_time: 时程中触发后的时间（秒）
    % 默认：1.3秒（覆盖1秒刺激+响应延迟）
    config.mission2.post_time = 1.3;
    
    % data_duration: 用于处理的数据时长（秒）
    % 默认：300秒（5分钟）
    % 设置为 Inf 使用全部数据
    config.mission2.data_duration = 300;
    
    % convergence_threshold: 收敛的相关阈值
    % 默认：0.9（90%相关标准）
    config.mission2.convergence_threshold = 0.9;
    
end
