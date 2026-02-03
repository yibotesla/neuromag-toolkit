# 预处理器模块

本模块负责对MEG数据进行预处理操作。

## 函数

### 基础预处理
- `preprocess_data.m` - 主预处理函数
- `remove_dc.m` - 去除信号中的直流分量
- `detect_bad_channels.m` - 检测并标记坏通道

### OPM专用预处理
- `real_time_calibration.m` - 基于数字锁相放大的实时增益校准
- `deep_notch_filter.m` - 级联FIR带阻滤波器实现深度陷波

## 使用方法

### 基础预处理

```matlab
[data_clean, bad_channels] = preprocess_data(data_struct, options);
```

### 实时校准（OPM数据）

```matlab
% Y轴数据校准（240Hz参考信号）
[data_Y_cal, gains_Y] = real_time_calibration(data_Y, 4800, 240, 62400);

% Z轴数据校准（320Hz参考信号）
[data_Z_cal, gains_Z] = real_time_calibration(data_Z, 4800, 320, 55600);
```

### 深度陷波滤波（去除校准信号）

```matlab
% 去除240Hz和320Hz校准信号（6次级联）
data_clean = deep_notch_filter(data, 4800, [240, 320]);

% 自定义参数
opts.bandwidth = 8;      % 带宽 8 Hz
opts.n_cascade = 4;      % 4次级联
opts.filter_order = 400; % FIR阶数
data_clean = deep_notch_filter(data, 4800, [240, 320], opts);
```

## 需求

- 需求 1.3, 1.4: 基础预处理
- 需求 2.1, 2.2: 实时校准
- 需求 2.3: 深度陷波滤波
