# 滤波器模块

本模块负责频域滤波和自适应滤波操作。

## 函数

### 自适应滤波
- `lms_adaptive_filter.m` - LMS (最小均方) 自适应滤波用于噪声消除
- `rls_adaptive_filter.m` - RLS (递归最小二乘) 自适应滤波用于噪声消除
- `calculate_noise_reduction.m` - 计算滤波后的噪声降低百分比

### 频域滤波
- `lowpass_filter.m` - 用于AEF信号的低通滤波
- `bandpass_filter.m` - 用于ASSR信号的带通滤波
- `notch_filter.m` - 用于电源线干扰的陷波滤波

## 使用方法

### 自适应滤波
```matlab
% LMS自适应滤波
params.mu = 0.01;
params.filter_order = 10;
[data_filtered, weights, error] = lms_adaptive_filter(meg_data, ref_data, params);

% RLS自适应滤波
params.lambda = 0.995;
params.filter_order = 10;
params.delta = 1.0;
[data_filtered, weights, error] = rls_adaptive_filter(meg_data, ref_data, params);

% 计算噪声降低
[nr_pct, power_before, power_after] = calculate_noise_reduction(data_before, data_after);
```

### 频域滤波
```matlab
% 用于AEF的低通滤波器 (30Hz截止频率)
data_aef = lowpass_filter(meg_data, fs, 30);

% 用于ASSR的带通滤波器 (89Hz ± 2Hz)
data_assr = bandpass_filter(meg_data, fs, 89, 4);

% 用于电源线干扰的陷波滤波器
data_clean = notch_filter(meg_data, fs, [50, 100, 150, 200, 250]);
```

## 测试

运行 `test_adaptive_filters.m` 测试自适应滤波实现。
运行 `test_frequency_filters.m` 测试频域滤波实现。

## 需求

- 自适应滤波: 需求 3.1, 3.2, 3.3, 3.5
- 频域滤波: 需求 4.1, 4.2, 4.3, 4.4, 4.5
