# 工具模块

本模块包含工具函数和数据结构。

## 数据结构

- `MEGData.m` - 核心MEG数据结构
- `ProcessedData.m` - 处理后的数据结构
- `TrialData.m` - 试次/时程数据结构
- `AnalysisResults.m` - 分析结果结构

## 工具函数

### FieldTrip集成

- `fieldtrip_integration.m` - FieldTrip工具箱集成模块

### 数据导出函数

- `save_processed_data.m` - 将MEG数据结构保存到MAT文件
- `save_figures.m` - 将MATLAB图形保存为PNG和PDF格式

## 使用方法

### 创建数据结构

```matlab
% 创建MEGData结构
meg_data = MEGData();
meg_data.fs = 4800;
meg_data.gain = 1e-12;
meg_data = meg_data.set_channel_labels();

% 创建ProcessedData结构
proc_data = ProcessedData();
proc_data.data = filtered_data;
proc_data.fs = 4800;
proc_data = proc_data.add_processing_step('带通滤波');

% 创建TrialData结构
trial_data = TrialData();
trial_data.trials = epoched_data;
trial_data.fs = 4800;

% 创建AnalysisResults结构
results = AnalysisResults();
results = results.set_psd(frequencies, power);
results = results.set_snr(17, snr_value);
```

### 将数据保存到MAT文件

```matlab
% 使用自定义名称保存单个结构
save_processed_data('output.mat', 'meg_data', meg_data);

% 保存多个结构
save_processed_data('results.mat', ...
    'raw', meg_data, ...
    'filtered', proc_data, ...
    'trials', trial_data, ...
    'analysis', results);

% 自动生成变量名
save_processed_data('data.mat', meg_data, proc_data);
```

### 保存图形

```matlab
% 将当前图形保存为PNG
save_figures('figure1', gcf, 'Format', 'png');

% 保存为PDF
save_figures('figure1', gcf, 'Format', 'pdf');

% 同时保存为PNG和PDF (默认)
save_figures('figure1', gcf);

% 使用自定义分辨率保存
save_figures('figure1', gcf, 'Format', 'png', 'Resolution', 600);

% 保存多个图形
fig1 = figure; plot(data1);
fig2 = figure; plot(data2);
save_figures('output', [fig1, fig2]);
% 创建: output_1.png, output_1.pdf, output_2.png, output_2.pdf

% 使用自定义文件名保存
save_figures({'fig_psd', 'fig_time'}, [fig1, fig2], 'Format', 'png');
```

### FieldTrip集成

```matlab
% 检测FieldTrip是否可用
[available, version] = fieldtrip_integration('check');

% 初始化FieldTrip
config = default_config();
fieldtrip_integration('init', config.paths.fieldtrip_path);

% 将MEGData转换为FieldTrip格式
ft_data = fieldtrip_integration('to_fieldtrip', meg_data, config);

% 将TrialData转换为FieldTrip格式
ft_trials = fieldtrip_integration('trials_to_fieldtrip', trial_data, config);

% 将FieldTrip数据转换回MEGData
meg_data = fieldtrip_integration('from_fieldtrip', ft_data, config);

% 构建单轴grad传感器结构
grad = fieldtrip_integration('build_grad', config);

% 构建双轴grad传感器结构（用于OPM双轴数据）
grad_dual = fieldtrip_integration('build_dual_axis_grad', config);

% 加载传感器布局文件
layout = fieldtrip_integration('load_layout', config);

% 加载辅助数据文件
aux_data = fieldtrip_integration('load_auxiliary', 'grad_transformed.mat', config);
```

#### 支持的操作

| 操作 | 说明 |
|------|------|
| `'check'` | 检测FieldTrip是否可用，返回[available, version] |
| `'init'` | 初始化FieldTrip（添加路径并运行ft_defaults） |
| `'to_fieldtrip'` | 将MEGData转换为FieldTrip数据结构 |
| `'trials_to_fieldtrip'` | 将TrialData转换为FieldTrip试次数据结构 |
| `'from_fieldtrip'` | 将FieldTrip数据结构转换回MEGData |
| `'build_grad'` | 构建单轴grad传感器结构 |
| `'build_dual_axis_grad'` | 构建双轴grad传感器结构 |
| `'load_layout'` | 加载传感器布局文件 |
| `'load_auxiliary'` | 加载辅助数据文件 |

#### 辅助数据文件

常用的辅助数据文件（存放在 `config.paths.auxiliary_data` 路径下）：

- `data_temp30s.mat` - FieldTrip数据模板
- `layout_zkzyopm.mat` - 传感器布局
- `grad_transformed.mat` - Z轴grad结构
- `grad_Y_transformed.mat` - Y轴grad结构
