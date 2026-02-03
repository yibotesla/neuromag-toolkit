# 分析器模块

本模块负责信号分析操作。

## 函数

- `compute_psd.m` - 计算功率谱密度
- `calculate_snr.m` - 计算信噪比
- `detect_peak_at_frequency.m` - 检测目标频率处的频谱峰值
- `detect_triggers.m` - 检测触发信号 (✓ 已实现)
- `extract_epochs.m` - 从连续数据中提取试次时程 (✓ 已实现)
- `compute_grand_average.m` - 计算跨试次的总平均 (✓ 已实现)
- `sample_trials.m` - 随机采样N个试次并计算平均 (✓ 已实现)
- `compute_convergence_metrics.m` - 计算收敛性指标 (✓ 已实现)
- `determine_minimum_trials.m` - 确定稳定平均所需的最少试次 (✓ 已实现)

## 使用方法

### 触发检测
```matlab
% 检测触发信号中的触发点
threshold = 2.5;
min_interval = round(0.5 * fs);  % 触发点之间最小间隔500ms
trigger_indices = detect_triggers(trigger_signal, threshold, min_interval);
```

### 时程提取
```matlab
% 在触发点周围提取试次时程
pre_time = 0.2;   % 触发前200ms
post_time = 1.3;  % 触发后1300ms
[trials, trial_times] = extract_epochs(data, trigger_indices, fs, pre_time, post_time);
```

### 总平均
```matlab
% 计算所有试次的总平均
grand_avg = compute_grand_average(trials);
```

### 收敛性分析
```matlab
% 随机采样N个试次并计算平均
n_samples = 20;
sampled_avg = sample_trials(trials, n_samples);

% 计算收敛性指标
metrics = compute_convergence_metrics(sampled_avg, grand_avg);
fprintf('相关系数: %.3f, RMSE: %.3e\n', metrics.correlation, metrics.rmse);

% 确定稳定平均所需的最少试次
threshold = 0.9;  % 相关系数阈值
trial_counts = 10:10:100;  % 测试这些试次数
n_iterations = 10;  % 每个试次数的随机采样次数
[min_trials, conv_data] = determine_minimum_trials(trials, threshold, trial_counts, n_iterations);

% 绘制收敛曲线
figure;
errorbar(conv_data.n_trials, conv_data.correlation, conv_data.correlation_std, 'o-');
hold on;
yline(threshold, 'r--', sprintf('阈值 = %.1f', threshold));
xline(min_trials, 'g--', sprintf('最少试次 = %d', min_trials));
xlabel('试次数');
ylabel('相关系数');
title('收敛性分析');
grid on;
```

## 需求

实现需求 2.1, 2.2, 2.3, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5
