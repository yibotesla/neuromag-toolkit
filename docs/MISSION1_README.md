# 任务1：模体数据处理

## 概述

任务1实现了一个完整的处理流程，用于从模体脑磁图（MEG）数据中提取17Hz正弦信号。该流程应用预处理、尖峰噪声去除和自适应滤波来提高信号质量并检测目标频率。

## 需求

本实现满足以下需求：
- **需求 2.1**：计算功率谱密度（PSD, Power Spectral Density）
- **需求 2.2**：计算17Hz处的信噪比（SNR, Signal-to-Noise Ratio）
- **需求 2.3**：在PSD中检测17Hz峰值
- **需求 2.4**：使用中值滤波或小波阈值去除尖峰噪声
- **需求 2.5**：应用自适应滤波进行宽带噪声抑制

## 文件

- `process_mission1.m` - 主处理流程函数
- `scripts/demos/demo_mission1.m` - 演示脚本（合成数据，生成 outputs/mission1/）
- `scripts/tests/test_mission1.m` - 快速验证脚本（不生成图/不写文件）

## 使用方法

### 快速开始（演示模式）

使用合成数据运行演示：

```matlab
demo_mission1
```

这将：
1. 生成带噪声的合成17Hz信号
2. 通过完整流程处理
3. 显示结果和可视化
4. 将输出保存到 `outputs/mission1/` 目录

### 处理真实数据

处理真实的LVM文件：

```matlab
config = default_config();
process_mission1('Mission1/data_12.lvm', config, 'SaveResults', true);
```

或直接使用函数：

```matlab
config = config_template();
results = process_mission1('Mission1/data_1.lvm', config);
```

### 运行测试

验证流程是否正常工作：

```matlab
test_mission1
```

这将运行自动化测试以验证：
- 17Hz峰值检测
- 信噪比改善
- 噪声抑制效果
- 所有处理步骤完成

## 处理流程

任务1流程包含以下步骤：

### 1. 数据加载
- 加载LVM文件或生成合成数据
- 提取64个MEG通道、3个参考传感器、刺激和触发信号
- 存储采样率和增益参数

### 2. 预处理
- 从所有MEG通道中去除直流分量
- 检测并标记坏通道（饱和、平坦或过度噪声）

### 3. 尖峰噪声去除
- 应用中值滤波（默认）或小波阈值
- 去除电子尖峰同时保持信号形状

### 4. 自适应滤波（HFC）
- 使用参考传感器（通道65-67）作为噪声参考
- 应用RLS（默认）或LMS自适应滤波
- 去除相关的宽带噪声

### 5. PSD计算
- 使用Welch方法计算功率谱密度
- 对原始数据和滤波后数据都进行计算

### 6. SNR计算
- 计算原始数据和滤波后数据在17Hz处的信噪比
- 测量17Hz周围±0.5Hz频带内的信号功率
- 测量相邻频带的噪声功率

### 7. 峰值检测
- 在滤波后的PSD中检测17Hz峰值
- 验证峰值在±0.5Hz容差范围内
- 报告各通道的检测率

### 8. 可视化
- 绘制原始和滤波后的PSD
- 比较滤波前后的SNR
- 显示每个通道的噪声抑制
- 显示逐通道分析

## 配置

可以在 `config_template.m` 中调整关键参数：

```matlab
config = config_template();

% 尖峰去除方法
config.despike.method = 'median';  % 或 'wavelet'
config.despike.median_window = 5;
config.despike.spike_threshold = 5.0;

% 自适应滤波
config.adaptive_filter.algorithm = 'RLS';  % 或 'LMS'
config.adaptive_filter.filter_order = 10;
config.adaptive_filter.lambda = 0.995;  % RLS遗忘因子
config.adaptive_filter.mu = 0.01;  % LMS步长

% 任务1特定参数
config.mission1.target_frequency = 17;  % Hz
```

## 输出

流程生成：

### 结果结构体
```matlab
results = struct(
    'raw_data',           % 原始MEGData对象
    'preprocessed',       % 预处理后的数据
    'despiked',          % 尖峰去除后的数据
    'filtered',          % 自适应滤波后的数据
    'psd_raw',           % 原始数据的PSD
    'psd_filtered',      % 滤波后数据的PSD
    'snr_raw',           % 17Hz处的SNR（原始）
    'snr_filtered',      % 17Hz处的SNR（滤波后）
    'peak_detected',     % 峰值检测结果
    'peak_freq',         % 检测到的峰值频率
    'noise_reduction',   % 每个通道的噪声抑制
    'bad_channels'       % 坏通道列表
);
```

### 保存的文件
当 `SaveResults` 为true时，以下文件将保存到输出目录：

- `outputs/mission1/mission1_results.mat` - 完整的结果结构体
- `outputs/mission1/mission1_results.png/pdf` - 主结果图（4个子图）
- `outputs/mission1/channel_analysis.png/pdf` - 逐通道SNR和峰值检测
- `outputs/mission1/spectral_comparison.png/pdf` - 最佳通道频谱分析

## 预期结果

使用合成数据时，典型结果为：

- **峰值检测**：100%的通道（64/64）
- **SNR改善**：2-4 dB
- **噪声抑制**：60-65%
- **峰值频率**：16.99 Hz（在目标值0.01 Hz范围内）
- **峰值显著性**：比相邻频率高>20 dB

## 性能

处理时间取决于：
- 数据时长（演示通常为10秒）
- 采样率（默认4800 Hz）
- 滤波器阶数（通常为5-10）
- 算法选择（RLS收敛更快但每个样本计算量更大）

10秒数据的典型处理时间：
- LMS：约5-10秒
- RLS：约10-20秒

## 故障排除

### 未检测到峰值
- 检查原始数据中是否存在17Hz信号
- 验证PSD在17Hz处是否显示能量
- 调整 `detect_peak_at_frequency` 中的 `MinPeakHeight` 参数

### SNR改善不佳
- 尝试不同的自适应滤波算法（LMS vs RLS）
- 调整滤波器阶数（更高=更多噪声抑制但更慢）
- 检查参考传感器质量

### 处理速度慢
- 减少测试数据时长
- 降低滤波器阶数
- 使用LMS代替RLS以加快处理速度

## 参考文档

- 输出文件与作业要求对齐：`outputs/README.md`、`docs/OUTPUTS.md`
- 项目结构：`docs/PROJECT_STRUCTURE.md`
- API 说明：`docs/API_DOCUMENTATION.md`

## 作者

MEG信号处理系统
