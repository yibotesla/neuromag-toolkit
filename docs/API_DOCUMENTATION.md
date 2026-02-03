# MEG信号处理系统 - API文档

## 概述

本文档为MEG信号处理系统中的所有函数提供全面的API文档。每个函数都包括语法、输入/输出参数、描述、需求映射和使用示例。

## 目录

1. [数据加载模块](#数据加载模块)
2. [预处理模块](#预处理模块)
3. [去噪模块](#去噪模块)
4. [滤波模块](#滤波模块)
5. [分析模块](#分析模块)
6. [可视化模块](#可视化模块)
7. [工具函数](#工具函数)
8. [数据结构](#数据结构)

---

## 数据加载模块

### load_lvm_data

**目的：** 加载和解析LVM格式的MEG数据文件

**语法：**
```matlab
data_struct = load_lvm_data(file_path, sampling_rate, gain)
```

**输入：**
- `file_path`（字符串）：LVM文件路径
- `sampling_rate`（标量）：采样率（Hz）（例如，4800）
- `gain`（标量）：从V到T的增益转换因子（例如，2.7e-3）

**输出：**
- `data_struct`（MEGData对象）：包含：
  - `.meg_channels`：64×N矩阵，头部MEG通道数据
  - `.ref_channels`：3×N矩阵，参考传感器数据
  - `.stimulus`：1×N向量，刺激信号
  - `.trigger`：1×N向量，触发信号
  - `.time`：1×N向量，时间轴
  - `.fs`：采样率
  - `.gain`：增益系数
  - `.channel_labels`：64×1通道标签单元数组

**需求：** 1.1, 1.5

**示例：**
```matlab
data = load_lvm_data('data_1.lvm', 4800, 2.7e-3);
fprintf('从%d个MEG通道加载了%d个样本\n', size(data.meg_channels, 2), size(data.meg_channels, 1));
```


### identify_channels

**目的：** 从LVM数据中识别和分类通道类型

**语法：**
```matlab
[meg_idx, ref_idx, stim_idx, trig_idx, channel_labels] = identify_channels(n_cols)
```

**输入：**
- `n_cols`（标量）：LVM文件中的总列数（通常为68）

**输出：**
- `meg_idx`（向量）：MEG通道的索引（1-64）
- `ref_idx`（向量）：参考传感器通道的索引（65-67）
- `stim_idx`（标量）：刺激通道的索引
- `trig_idx`（标量）：触发通道的索引
- `channel_labels`（单元数组）：所有通道的标签

**需求：** 1.2

**示例：**
```matlab
[meg_idx, ref_idx, stim_idx, trig_idx, labels] = identify_channels(68);
fprintf('MEG通道：%d，参考通道：%d\n', length(meg_idx), length(ref_idx));
```

---

## 预处理模块

### preprocess_data

**目的：** MEG数据的主要预处理函数

**语法：**
```matlab
[data_clean, bad_channels] = preprocess_data(data_struct, options)
```

**输入：**
- `data_struct`（MEGData对象或结构体）：输入数据，包含字段：
  - `.meg_channels`：64×N MEG数据矩阵
  - `.time`：1×N时间向量
  - `.fs`：采样率
  - `.channel_labels`：通道标签（可选）
- `options`（结构体，可选）：预处理参数：
  - `.remove_dc`：是否去除直流偏移（默认：true）
  - `.detect_bad`：是否检测坏通道（默认：true）
  - `.bad_threshold`：坏通道检测阈值（默认：3.0）
  - `.saturation_threshold`：饱和检测阈值
  - `.flat_var_threshold`：平坦通道方差阈值
  - `.noise_std_threshold`：噪声检测阈值倍数

**输出：**
- `data_clean`（ProcessedData对象）：预处理后的数据
- `bad_channels`（向量）：坏通道的索引

**需求：** 1.3, 1.4

**示例：**
```matlab
options.remove_dc = true;
options.detect_bad = true;
options.bad_threshold = 3.0;
[clean_data, bad_ch] = preprocess_data(meg_data, options);
fprintf('检测到%d个坏通道：%s\n', length(bad_ch), mat2str(bad_ch));
```


### remove_dc

**目的：** 从MEG通道中去除直流偏移

**语法：**
```matlab
data_no_dc = remove_dc(data)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples MEG数据

**输出：**
- `data_no_dc`（矩阵）：去除直流偏移后的数据（均值 = 0）

**需求：** 1.3

**示例：**
```matlab
data_no_dc = remove_dc(meg_channels);
fprintf('去除直流偏移后的均值：%.2e\n', mean(data_no_dc(:)));
```

### detect_bad_channels

**目的：** 基于饱和、平坦和噪声检测坏通道

**语法：**
```matlab
[bad_channels, bad_types] = detect_bad_channels(data, options)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples MEG数据
- `options`（结构体，可选）：检测参数

**输出：**
- `bad_channels`（向量）：坏通道的索引
- `bad_types`（单元数组）：每个坏通道的问题类型

**需求：** 1.4

**示例：**
```matlab
[bad_ch, types] = detect_bad_channels(meg_data);
for i = 1:length(bad_ch)
    fprintf('通道%d：%s\n', bad_ch(i), types{i});
end
```

---

## 去噪模块

### median_filter_despike

**目的：** 使用中值滤波去除尖峰噪声

**语法：**
```matlab
data_filtered = median_filter_despike(data, window_size, threshold)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples MEG数据
- `window_size`（标量）：滑动窗口大小（默认：5，必须为奇数）
- `threshold`（标量）：标准差检测阈值（默认：3.0）

**输出：**
- `data_filtered`（矩阵）：去除尖峰后的数据

**需求：** 2.4

**示例：**
```matlab
data_clean = median_filter_despike(meg_data, 5, 3.0);
```


### wavelet_despike

**目的：** 使用小波阈值去除尖峰噪声

**语法：**
```matlab
data_filtered = wavelet_despike(data, wavelet_name, level)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples MEG数据
- `wavelet_name`（字符串）：小波族（默认：'db4'）
- `level`（标量）：分解层数（默认：5）

**输出：**
- `data_filtered`（矩阵）：去除尖峰后的数据

**需求：** 2.4

**示例：**
```matlab
data_clean = wavelet_despike(meg_data, 'db4', 5);
```

---

## 滤波模块

### lms_adaptive_filter

**目的：** 最小均方自适应滤波用于噪声消除

**语法：**
```matlab
[data_filtered, weights, error_signal] = lms_adaptive_filter(meg_data, ref_data, params)
```

**输入：**
- `meg_data`（矩阵）：N_channels × N_samples，主MEG数据（d(n)）
- `ref_data`（矩阵）：N_ref × N_samples，参考传感器数据（x(n)）
- `params`（结构体）：算法参数：
  - `.mu`：步长（学习率），默认0.01
  - `.filter_order`：滤波器阶数（抽头数），默认10

**输出：**
- `data_filtered`（矩阵）：滤波后的MEG数据（误差信号e(n)）
- `weights`（数组）：filter_order × N_ref × N_channels，最终滤波器权重
- `error_signal`（矩阵）：误差信号（与data_filtered相同）

**需求：** 3.1, 3.2

**示例：**
```matlab
params.mu = 0.01;
params.filter_order = 10;
[filtered, weights, error] = lms_adaptive_filter(meg_data, ref_data, params);
```


### rls_adaptive_filter

**目的：** 递归最小二乘自适应滤波用于噪声消除

**语法：**
```matlab
[data_filtered, weights, error_signal] = rls_adaptive_filter(meg_data, ref_data, params)
```

**输入：**
- `meg_data`（矩阵）：N_channels × N_samples，主MEG数据
- `ref_data`（矩阵）：N_ref × N_samples，参考传感器数据
- `params`（结构体）：算法参数：
  - `.lambda`：遗忘因子（默认：0.995，范围：0.99-1.0）
  - `.filter_order`：滤波器阶数（默认：10）
  - `.delta`：初始化参数（默认：1.0）

**输出：**
- `data_filtered`（矩阵）：滤波后的MEG数据
- `weights`（数组）：最终滤波器权重
- `error_signal`（矩阵）：误差信号

**需求：** 3.1, 3.3

**示例：**
```matlab
params.lambda = 0.995;
params.filter_order = 10;
params.delta = 1.0;
[filtered, weights, error] = rls_adaptive_filter(meg_data, ref_data, params);
```

### calculate_noise_reduction

**目的：** 计算降噪百分比

**语法：**
```matlab
noise_reduction = calculate_noise_reduction(data_before, data_after)
```

**输入：**
- `data_before`（矩阵）：滤波前的数据
- `data_after`（矩阵）：滤波后的数据

**输出：**
- `noise_reduction`（标量）：降噪百分比

**需求：** 3.5

**示例：**
```matlab
nr = calculate_noise_reduction(raw_data, filtered_data);
fprintf('降噪效果：%.1f%%\n', nr);
```


### lowpass_filter

**目的：** 应用零相位低通FIR滤波器

**语法：**
```matlab
data_filtered = lowpass_filter(data, fs, cutoff_freq, filter_order)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples输入数据
- `fs`（标量）：采样频率（Hz）
- `cutoff_freq`（标量）：截止频率（Hz）
- `filter_order`（标量）：滤波器阶数（可选，默认：100）

**输出：**
- `data_filtered`（矩阵）：滤波后的数据

**需求：** 4.1, 4.4, 4.5

**示例：**
```matlab
% 使用30Hz低通提取AEF
data_aef = lowpass_filter(meg_data, 4800, 30, 100);
```

### bandpass_filter

**目的：** 应用零相位带通FIR滤波器

**语法：**
```matlab
data_filtered = bandpass_filter(data, fs, center_freq, bandwidth, filter_order)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples输入数据
- `fs`（标量）：采样频率（Hz）
- `center_freq`（标量）：中心频率（Hz）
- `bandwidth`（标量）：带宽（Hz），中心频率±bandwidth/2
- `filter_order`（标量）：滤波器阶数（可选，默认：100）

**输出：**
- `data_filtered`（矩阵）：滤波后的数据

**需求：** 4.2, 4.4, 4.5

**示例：**
```matlab
% 在89Hz ± 2Hz提取ASSR
data_assr = bandpass_filter(meg_data, 4800, 89, 4, 100);
```


### notch_filter

**目的：** 应用陷波滤波器去除工频干扰

**语法：**
```matlab
data_filtered = notch_filter(data, fs, notch_freqs, bandwidth, filter_order)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples输入数据
- `fs`（标量）：采样频率（Hz）
- `notch_freqs`（向量）：要陷波的频率（Hz），例如[50, 100, 150, 200, 250]
- `bandwidth`（标量）：每个陷波的带宽（Hz），默认：2
- `filter_order`（标量）：滤波器阶数（可选，默认：100）

**输出：**
- `data_filtered`（矩阵）：滤波后的数据

**需求：** 4.3, 4.4, 4.5

**示例：**
```matlab
% 去除50Hz工频及其谐波
data_clean = notch_filter(meg_data, 4800, [50, 100, 150, 200, 250], 2, 100);
```

---

## 分析模块

### compute_psd

**目的：** 计算功率谱密度

**语法：**
```matlab
[psd, frequencies] = compute_psd(data, fs, nfft, window_type)
```

**输入：**
- `data`（向量或矩阵）：信号数据
- `fs`（标量）：采样率（Hz）
- `nfft`（标量）：FFT长度（默认：2048）
- `window_type`（字符串）：窗函数（默认：'hamming'）

**输出：**
- `psd`（向量或矩阵）：功率谱密度
- `frequencies`（向量）：频率向量（Hz）

**需求：** 2.1

**示例：**
```matlab
[psd, freq] = compute_psd(signal, 4800, 2048, 'hamming');
plot(freq, 10*log10(psd));
xlabel('频率（Hz）'); ylabel('功率（dB）');
```


### calculate_snr

**目的：** 计算目标频率处的信噪比

**语法：**
```matlab
[snr_db, signal_power, noise_power] = calculate_snr(psd, frequencies, target_freq, params)
```

**输入：**
- `psd`（向量）：功率谱密度
- `frequencies`（向量）：频率向量（Hz）
- `target_freq`（标量）：信噪比计算的目标频率（Hz）
- `params`（结构体，可选）：信号/噪声带宽参数

**输出：**
- `snr_db`（标量）：信噪比（dB）
- `signal_power`（标量）：信号功率
- `noise_power`（标量）：噪声功率

**需求：** 2.2

**示例：**
```matlab
[snr, sig_pwr, noise_pwr] = calculate_snr(psd, freq, 17);
fprintf('17Hz处的信噪比：%.1f dB\n', snr);
```

### detect_peak_at_frequency

**目的：** 在目标频率处检测功率谱密度峰值

**语法：**
```matlab
[has_peak, peak_freq, peak_power] = detect_peak_at_frequency(psd, frequencies, target_freq, tolerance)
```

**输入：**
- `psd`（向量）：功率谱密度
- `frequencies`（向量）：频率向量（Hz）
- `target_freq`（标量）：目标频率（Hz）
- `tolerance`（标量）：频率容差（Hz），默认：0.5

**输出：**
- `has_peak`（布尔值）：如果检测到峰值则为真
- `peak_freq`（标量）：检测到的峰值频率
- `peak_power`（标量）：峰值处的功率

**需求：** 2.3

**示例：**
```matlab
[has_peak, f_peak, p_peak] = detect_peak_at_frequency(psd, freq, 17, 0.5);
if has_peak
    fprintf('在%.2f Hz检测到峰值\n', f_peak);
end
```


### detect_triggers

**目的：** 检测触发信号中的触发事件

**语法：**
```matlab
trigger_indices = detect_triggers(trigger_signal, threshold, min_interval)
```

**输入：**
- `trigger_signal`（向量）：1×N触发信号
- `threshold`（标量）：检测阈值
- `min_interval`（标量）：触发之间的最小间隔（样本数）

**输出：**
- `trigger_indices`（向量）：检测到的触发索引

**需求：** 5.3

**示例：**
```matlab
fs = 4800;
min_interval_sec = 0.5;  % 触发之间最小500ms
min_interval = round(min_interval_sec * fs);
trigger_indices = detect_triggers(trigger_signal, 2.5, min_interval);
fprintf('检测到%d个触发\n', length(trigger_indices));
```

### extract_epochs

**目的：** 从连续数据中提取试次时程

**语法：**
```matlab
[trials, trial_times] = extract_epochs(data, trigger_indices, fs, pre_time, post_time)
```

**输入：**
- `data`（矩阵）：N_channels × N_samples，连续数据
- `trigger_indices`（向量）：触发点索引
- `fs`（标量）：采样率（Hz）
- `pre_time`（标量）：触发前时间（秒）
- `post_time`（标量）：触发后时间（秒）

**输出：**
- `trials`（数组）：N_channels × N_samples_per_trial × N_trials，时程数据
- `trial_times`（向量）：相对时间轴（秒）

**需求：** 5.4

**示例：**
```matlab
fs = 4800;
pre_time = 0.2;   % 触发前200ms
post_time = 1.3;  % 触发后1300ms
[trials, trial_times] = extract_epochs(data, trigger_indices, fs, pre_time, post_time);
fprintf('提取了%d个试次\n', size(trials, 3));
```


### compute_grand_average

**目的：** 计算跨试次的总平均

**语法：**
```matlab
grand_average = compute_grand_average(trials)
```

**输入：**
- `trials`（数组）：N_channels × N_samples_per_trial × N_trials

**输出：**
- `grand_average`（矩阵）：N_channels × N_samples_per_trial，平均响应

**需求：** 5.5, 6.1

**示例：**
```matlab
grand_avg = compute_grand_average(trials);
plot(trial_times, grand_avg(1, :));
xlabel('时间（秒）'); ylabel('幅度');
title('总平均 - 通道1');
```

### sample_trials

**目的：** 随机采样N个试次并计算平均

**语法：**
```matlab
sampled_avg = sample_trials(trials, n_trials)
```

**输入：**
- `trials`（数组）：N_channels × N_samples_per_trial × N_trials
- `n_trials`（标量）：要采样的试次数

**输出：**
- `sampled_avg`（矩阵）：N_channels × N_samples_per_trial，采样平均

**需求：** 6.2

**示例：**
```matlab
% 采样50个随机试次
avg_50 = sample_trials(trials, 50);
```

### compute_convergence_metrics

**目的：** 计算采样平均与总平均之间的收敛指标

**语法：**
```matlab
metrics = compute_convergence_metrics(sampled_avg, grand_average)
```

**输入：**
- `sampled_avg`（矩阵）：采样平均
- `grand_average`（矩阵）：总平均（金标准）

**输出：**
- `metrics`（结构体）：包含：
  - `.correlation`：相关系数
  - `.rmse`：均方根误差

**需求：** 6.3

**示例：**
```matlab
metrics = compute_convergence_metrics(avg_50, grand_avg);
fprintf('相关性：%.3f，RMSE：%.2e\n', metrics.correlation, metrics.rmse);
```


### determine_minimum_trials

**目的：** 找到稳定平均所需的最小试次数

**语法：**
```matlab
[min_trials, convergence_data] = determine_minimum_trials(trials, threshold, trial_counts, n_iterations)
```

**输入：**
- `trials`（数组）：N_channels × N_samples_per_trial × N_trials
- `threshold`（标量）：相关阈值（默认：0.9）
- `trial_counts`（向量）：要测试的试次数（默认：10:10:N_trials）
- `n_iterations`（标量）：随机采样迭代次数（默认：10）

**输出：**
- `min_trials`（标量）：所需的最小试次数
- `convergence_data`（结构体）：包含：
  - `.n_trials`：测试的试次数向量
  - `.correlation`：平均相关系数
  - `.correlation_std`：标准差
  - `.rmse`：平均RMSE值
  - `.rmse_std`：标准差

**需求：** 6.5

**示例：**
```matlab
[min_n, conv_data] = determine_minimum_trials(trials, 0.9);
fprintf('所需最小试次数：%d\n', min_n);
plot(conv_data.n_trials, conv_data.correlation);
xlabel('试次数'); ylabel('相关性');
```

---

## 可视化模块

### plot_psd

**目的：** 绘制功率谱密度

**语法：**
```matlab
fig = plot_psd(frequencies, power, 'Name', Value, ...)
```

**输入：**
- `frequencies`（向量）：频率向量（Hz）
- `power`（向量或矩阵）：功率谱密度

**可选名称-值对：**
- `'Title'`：图标题（默认：'Power Spectral Density'）
- `'XLabel'`：X轴标签（默认：'Frequency (Hz)'）
- `'YLabel'`：Y轴标签（默认：'Power (dB)'）
- `'Scale'`：'linear'或'dB'（默认：'dB'）
- `'FreqRange'`：[fmin fmax]显示的频率范围
- `'ChannelLabels'`：通道标签单元数组
- `'LineWidth'`：线宽（默认：1.5）

**输出：**
- `fig`（句柄）：图形句柄

**需求：** 7.1

**示例：**
```matlab
fig = plot_psd(freq, psd, 'Title', 'MEG通道1功率谱密度', 'FreqRange', [0 100]);
```


### plot_time_series

**目的：** 绘制时域信号

**语法：**
```matlab
fig = plot_time_series(time, data, 'Name', Value, ...)
```

**输入：**
- `time`（向量）：时间轴（秒）
- `data`（向量或矩阵）：信号数据

**可选名称-值对：**
- `'Title'`：图标题
- `'XLabel'`：X轴标签（默认：'Time (s)'）
- `'YLabel'`：Y轴标签（默认：'Amplitude'）
- `'ChannelLabels'`：通道标签单元数组
- `'ChannelIndices'`：要绘制的通道索引
- `'LineWidth'`：线宽

**输出：**
- `fig`（句柄）：图形句柄

**需求：** 7.2

**示例：**
```matlab
fig = plot_time_series(time, meg_data, 'ChannelIndices', 1:5, 'Title', '前5个通道');
```

### plot_averaged_response

**目的：** 绘制平均诱发响应

**语法：**
```matlab
fig = plot_averaged_response(trial_times, grand_average, 'Name', Value, ...)
```

**输入：**
- `trial_times`（向量）：相对时间轴（秒）
- `grand_average`（矩阵）：平均响应数据

**可选名称-值对：**
- `'Title'`：图标题
- `'ChannelIndices'`：要绘制的通道
- `'ShowTrigger'`：在t=0处标记触发点（默认：true）

**输出：**
- `fig`（句柄）：图形句柄

**需求：** 7.3

**示例：**
```matlab
fig = plot_averaged_response(trial_times, grand_avg, 'Title', 'AEF响应', 'ChannelIndices', 1);
```


### plot_convergence_curve

**目的：** 绘制收敛分析曲线

**语法：**
```matlab
fig = plot_convergence_curve(convergence_data, 'Name', Value, ...)
```

**输入：**
- `convergence_data`（结构体）：来自determine_minimum_trials的收敛数据

**可选名称-值对：**
- `'Title'`：图标题
- `'ShowThreshold'`：标记收敛阈值（默认：true）
- `'ShowErrorBars'`：显示标准差条（默认：true）

**输出：**
- `fig`（句柄）：图形句柄

**需求：** 7.4

**示例：**
```matlab
fig = plot_convergence_curve(conv_data, 'Title', 'AEF收敛分析');
```

---

## 工具函数

### save_processed_data

**目的：** 将处理后的数据保存到MAT文件

**语法：**
```matlab
save_processed_data(data, filename, output_dir)
```

**输入：**
- `data`（结构体或对象）：要保存的数据
- `filename`（字符串）：输出文件名
- `output_dir`（字符串）：输出目录（默认：'results'）

**需求：** 7.5

**示例：**
```matlab
save_processed_data(results, 'mission1_results.mat', 'outputs/mission1');
```

### save_figures

**目的：** 将图形保存到文件

**语法：**
```matlab
save_figures(fig_handles, filenames, output_dir, format)
```

**输入：**
- `fig_handles`（向量）：图形句柄
- `filenames`（单元数组）：输出文件名
- `output_dir`（字符串）：输出目录
- `format`（字符串）：文件格式（'png'、'pdf'、'fig'）

**需求：** 7.5

**示例：**
```matlab
save_figures([fig1, fig2], {'psd.png', 'timeseries.png'}, 'results', 'png');
```


### validate_inputs

**目的：** 验证函数输入

**语法：**
```matlab
validate_inputs(varargin)
```

**输入：**
- 用于验证的可变参数

**需求：** 8.5

**示例：**
```matlab
validate_inputs('data', data, 'numeric', 'matrix');
validate_inputs('fs', fs, 'numeric', 'scalar', 'positive');
```

### handle_missing_data

**目的：** 处理缺失数据（NaN值）

**语法：**
```matlab
[data_fixed, missing_mask] = handle_missing_data(data, method)
```

**输入：**
- `data`（矩阵）：可能包含NaN值的数据
- `method`（字符串）：处理方法（'interpolate'、'mark'、'remove'）

**输出：**
- `data_fixed`（矩阵）：处理缺失值后的数据
- `missing_mask`（逻辑）：缺失数据位置的掩码

**需求：** 8.2

**示例：**
```matlab
[data_clean, mask] = handle_missing_data(meg_data, 'interpolate');
fprintf('修复了%d个缺失样本\n', sum(mask(:)));
```

### handle_saturated_channels

**目的：** 处理饱和通道

**语法：**
```matlab
[data_fixed, saturated_channels] = handle_saturated_channels(data, threshold)
```

**输入：**
- `data`（矩阵）：MEG数据
- `threshold`（标量）：饱和阈值（默认：0.95）

**输出：**
- `data_fixed`（矩阵）：排除饱和通道后的数据
- `saturated_channels`（向量）：饱和通道的索引

**需求：** 8.3

**示例：**
```matlab
[data_clean, sat_ch] = handle_saturated_channels(meg_data, 0.95);
fprintf('排除了%d个饱和通道\n', length(sat_ch));
```


---

## 数据结构

### MEGData

**目的：** 原始MEG数据的容器

**属性：**
- `meg_channels`（矩阵）：64×N，头部MEG通道数据
- `ref_channels`（矩阵）：3×N，参考传感器数据
- `stimulus`（向量）：1×N，刺激信号
- `trigger`（向量）：1×N，触发信号
- `time`（向量）：1×N，时间轴
- `fs`（标量）：采样率
- `gain`（标量）：增益转换因子
- `channel_labels`（单元数组）：通道标签
- `bad_channels`（向量）：坏通道索引

**方法：**
- `set_channel_labels()`：生成通道标签
- `get_good_channels()`：获取好通道的索引

**示例：**
```matlab
data = MEGData();
data.meg_channels = raw_data(:, 1:64)';
data.fs = 4800;
data = data.set_channel_labels();
```

### ProcessedData

**目的：** 处理后MEG数据的容器

**属性：**
- `data`（矩阵）：N_channels × N_samples，处理后的数据
- `time`（向量）：时间轴
- `fs`（标量）：采样率
- `channel_labels`（单元数组）：通道标签
- `processing_log`（单元数组）：处理步骤

**方法：**
- `add_processing_step(step_description)`：将处理步骤添加到日志
- `get_processing_log()`：获取完整的处理日志

**示例：**
```matlab
proc_data = ProcessedData();
proc_data.data = filtered_data;
proc_data = proc_data.add_processing_step('在30Hz处低通滤波');
```


### TrialData

**目的：** 时程试次数据的容器

**属性：**
- `trials`（数组）：N_channels × N_samples_per_trial × N_trials
- `trial_times`（向量）：相对时间轴
- `trigger_indices`（向量）：原始触发索引
- `fs`（标量）：采样率
- `pre_time`（标量）：触发前时间
- `post_time`（标量）：触发后时间

**方法：**
- `get_trial(trial_index)`：获取特定试次
- `get_n_trials()`：获取试次数
- `get_trial_duration()`：获取试次持续时间

**示例：**
```matlab
trial_data = TrialData();
trial_data.trials = extracted_trials;
trial_data.trial_times = time_axis;
trial_data.fs = 4800;
n_trials = trial_data.get_n_trials();
```

### AnalysisResults

**目的：** 分析结果的容器

**属性：**
- `psd`（结构体）：功率谱密度结果，包含字段：
  - `.frequencies`：频率向量
  - `.power`：功率值
- `snr`（结构体）：信噪比结果，包含字段：
  - `.frequency`：目标频率
  - `.snr_db`：信噪比（dB）
  - `.signal_power`：信号功率
  - `.noise_power`：噪声功率
- `grand_average`（矩阵）：总平均响应
- `convergence`（结构体）：收敛分析结果

**方法：**
- `add_psd(frequencies, power)`：添加功率谱密度结果
- `add_snr(frequency, snr_db, signal_power, noise_power)`：添加信噪比结果
- `add_convergence(convergence_data)`：添加收敛结果

**示例：**
```matlab
results = AnalysisResults();
results = results.add_psd(freq, psd);
results = results.add_snr(17, snr_db, sig_pwr, noise_pwr);
```


---

## 高级处理函数

### process_mission1

**目的：** 任务1（模体数据）的完整处理流程

**语法：**
```matlab
results = process_mission1(file_path, config)
```

**输入：**
- `file_path`（字符串）：LVM文件路径
- `config`（结构体）：来自default_config()的配置

**输出：**
- `results`（结构体）：完整结果，包括功率谱密度、信噪比、图形

**需求：** 2.1, 2.2, 2.3, 2.4, 2.5

**示例：**
```matlab
config = default_config();
results = process_mission1('Mission1/data_1.lvm', config);
fprintf('17Hz处的信噪比：%.1f dB\n', results.snr.snr_db);
```

### process_mission2

**目的：** 任务2（人类听觉数据）的完整处理流程

**语法：**
```matlab
results = process_mission2(file_path, config)
```

**输入：**
- `file_path`（字符串）：LVM文件路径
- `config`（结构体）：来自default_config()的配置

**输出：**
- `results`（结构体）：完整结果，包括AEF、ASSR、收敛

**需求：** 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5

**示例：**
```matlab
config = default_config();
config.mission2.aef_cutoff = 40;  % 根据需要自定义
results = process_mission2('Mission2/auditory_data.lvm', config);
fprintf('AEF最小试次数：%d\n', results.aef.min_trials);
fprintf('ASSR最小试次数：%d\n', results.assr.min_trials);
```

---

## 配置

### default_config

**目的：** 获取综合默认配置

**语法：**
```matlab
config = default_config()
```

**输出：**
- `config`（结构体）：包含所有参数文档的完整配置

**示例：**
```matlab
config = default_config();
% 根据需要修改
config.preprocessing.bad_channel_threshold = 4.0;
config.adaptive_filter.algorithm = 'LMS';
config.filters.aef_cutoff = 40;
```

有关完整参数文档，请参见`default_config.m`。


---

## 错误处理

所有函数都实现了全面的错误处理，并提供信息丰富的错误消息：

### 错误消息格式

```matlab
error('MEG:ModuleName:ErrorType', '带有上下文的描述性消息');
```

### 常见错误类型

- **FileNotFound**：未找到LVM文件
- **InvalidInput**：无效的输入参数
- **DimensionMismatch**：数组维度不匹配
- **InvalidColumns**：LVM文件中的列数不正确
- **NoValidTrials**：时程提取后没有有效试次
- **ThresholdNotReached**：未达到收敛阈值

### 警告类型

- **TriggerNearEdge**：触发太接近数据边缘
- **TooManyBadChannels**：检测到过多坏通道
- **ShortData**：相对于滤波器阶数，数据长度较短

### 错误处理示例

```matlab
try
    data = load_lvm_data('data.lvm', 4800, 2.7e-3);
catch ME
    if strcmp(ME.identifier, 'MEG:DataLoader:FileNotFound')
        fprintf('未找到文件。请检查路径。\n');
    else
        rethrow(ME);
    end
end
```

---

## 测试

### 单元测试

位于`tests/unit/`：
- `test_data_loader.m`：数据加载测试
- `test_preprocessor.m`：预处理测试
- `test_denoiser.m`：去噪测试
- `test_analyzer.m`：分析测试

**运行所有单元测试：**
```matlab
runtests('tests/unit')
```

### 属性测试

位于`tests/property/`：
- 每个属性测试使用随机输入运行100+次迭代
- 测试验证设计文档中的正确性属性

**运行属性测试：**
```matlab
runtests('tests/property')
```

### 集成测试

位于`tests/integration/`：
- 端到端流程测试
- 错误处理集成测试

**运行集成测试：**
```matlab
runtests('tests/integration')
```

---

## 性能考虑

### 内存使用

- 大型数据集（4800Hz下300秒）需要约1.5GB RAM
- 对于非常长的记录使用块处理
- 不需要时清除中间变量

### 处理速度

- RLS比LMS更快但使用更多内存
- 多通道操作可使用并行处理
- FFT操作针对2的幂次长度进行优化ilter order affects computation time linearly

### 优化建议

```matlab
% 使用适当的滤波器阶数
config.filters.aef_order = 100;  % 良好的平衡

% 降低功率谱密度分辨率以加快计算
config.analysis.psd_nfft = 1024;  % 而不是2048

% 减少收敛迭代次数以加快分析
config.convergence.n_iterations = 50;  % 而不是100
```

---

## 版本历史

- **v1.0**（2024）：初始版本
  - 完整的任务1和任务2流程
  - 全面的错误处理
  - 完整的测试覆盖

---

## 支持和联系

如有问题、错误报告或功能请求，请联系开发团队。

## 许可证

[添加许可证信息]

---

*本API文档从函数头部自动生成，并与代码库一起维护。*
