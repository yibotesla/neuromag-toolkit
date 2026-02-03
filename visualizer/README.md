# 可视化器模块

本模块负责MEG信号处理的数据可视化和绘图。

## 函数

### 核心可视化函数

#### `plot_psd.m` - 绘制功率谱密度
绘制单通道或多通道的频率-功率曲线。

**语法:**
```matlab
fig = plot_psd(frequencies, power)
fig = plot_psd(frequencies, power, 'Name', Value, ...)
```

**主要特性**:
- 单通道或多通道绘图
- dB或线性刻度
- 频率范围选择
- 通道标签和图例

**示例:**
```matlab
[f, psd] = compute_psd(signal, 4800);
fig = plot_psd(f, psd, 'Title', 'MEG通道1', 'FreqRange', [0 100]);
```

#### `plot_time_series.m` - 绘制时域信号
绘制选定通道的信号幅度随时间变化。

**语法:**
```matlab
fig = plot_time_series(time, data)
fig = plot_time_series(time, data, 'Name', Value, ...)
```

**主要特性**:
- 单通道或多通道绘图
- 叠加或堆叠显示模式
- 通道选择
- 时间范围选择
- 自动通道标签

**示例:**
```matlab
% 堆叠多通道显示
fig = plot_time_series(time, meg_data, 'Channels', 1:4, 'Stacked', true);
```

#### `plot_averaged_response.m` - 绘制总平均波形
绘制带触发标记的总平均诱发响应。

**语法:**
```matlab
fig = plot_averaged_response(trial_times, grand_average)
fig = plot_averaged_response(trial_times, grand_average, 'Name', Value, ...)
```

**主要特性**:
- 触发点标记 (t=0)
- 单通道或多通道绘图
- 叠加或堆叠显示模式
- 可自定义触发标记

**示例:**
```matlab
fig = plot_averaged_response(trial_times, grand_avg, ...
    'Title', '听觉诱发场', 'Channels', 1:4);
```

#### `plot_convergence_curve.m` - 绘制收敛性分析
绘制相关系数随试次数的变化。

**语法:**
```matlab
fig = plot_convergence_curve(n_trials, correlation)
fig = plot_convergence_curve(n_trials, correlation, 'Name', Value, ...)
```

**主要特性**:
- 阈值线标记
- 最少试次检测和标记
- 可自定义阈值
- 清晰的收敛行为可视化

**示例:**
```matlab
fig = plot_convergence_curve(n_trials, corr, 'Threshold', 0.9);
```

## 测试和演示

### `test_visualizer.m`
所有可视化函数的综合测试套件。测试各种输入配置和边界情况。

**运行测试:**
```matlab
cd visualizer
test_visualizer
close all  % 关闭所有测试图形
```

### `demo_visualizer.m`
使用真实合成MEG数据的所有可视化功能的交互式演示。

**运行演示:**
```matlab
cd visualizer
demo_visualizer
```

## 常见使用模式

### 比较多个通道
```matlab
% PSD比较
[f, psd] = compute_psd(meg_data, fs);
plot_psd(f, psd(1:4, :), 'ChannelLabels', {'Ch1', 'Ch2', 'Ch3', 'Ch4'});

% 时间序列比较 (堆叠)
plot_time_series(time, meg_data, 'Channels', 1:8, 'Stacked', true);
```

### 聚焦特定频率/时间范围
```matlab
% 聚焦17Hz区域
plot_psd(f, psd, 'FreqRange', [10 25]);

% 聚焦刺激后时期
plot_averaged_response(trial_times, grand_avg, 'TimeRange', [0 0.5]);
```

### 创建出版质量图形
```matlab
fig = plot_psd(f, psd, ...
    'Title', '功率谱密度', ...
    'LineWidth', 2.0, ...
    'FreqRange', [0 150]);

% 导出到文件
saveas(fig, 'psd_figure.png');
saveas(fig, 'psd_figure.pdf');
```

## 需求

实现设计规范中的需求 7.1, 7.2, 7.3, 7.4。

## 依赖项

- MATLAB信号处理工具箱
- 分析器模块 (用于演示/测试中的compute_psd)

## 注意事项

- 所有绘图函数返回图形句柄以便进一步自定义
- 可以使用 'Figure' 参数在现有图形窗口中创建图形
- 所有函数包含全面的输入验证和错误处理
- 如果未提供通道标签，将自动生成
