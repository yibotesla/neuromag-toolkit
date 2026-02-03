# 数据导出实现总结

## 概述

本文档总结了MEG信号处理系统任务 11: 数据导出功能的实现。

## 已实现函数

### 1. save_processed_data.m

**用途**: 将MEG数据结构保存到MATLAB .mat文件

**特性**:
- 支持所有MEG数据结构 (MEGData, ProcessedData, TrialData, AnalysisResults)
- 灵活输入: 名称-值对或自动生成变量名
- 自动处理.mat扩展名
- 需要时创建目录
- 包含元数据 (保存日期、MATLAB版本、变量名)
- 对象到结构的转换以保证兼容性
- 全面的错误处理

**使用示例**:
```matlab
% 保存单个结构
save_processed_data('output.mat', 'meg_data', meg_data);

% 保存多个结构
save_processed_data('results.mat', ...
    'raw', meg_data, ...
    'filtered', proc_data, ...
    'trials', trial_data);

% 自动生成名称
save_processed_data('data.mat', meg_data, proc_data);
```

**验证需求**: 7.5

### 2. save_figures.m

**用途**: 将MATLAB图形保存为PNG和PDF格式

**特性**:
- 支持PNG和PDF格式 (单独或同时)
- PNG的可配置分辨率 (默认: 300 DPI)
- PDF的可配置纸张大小 (letter, A4, auto)
- 单个或多个图形处理
- 多个图形的自动文件名生成
- 高质量导出设置 (painters渲染器、白色背景)
- 需要时创建目录
- 全面的错误处理

**使用示例**:
```matlab
% 保存为PNG
save_figures('figure1', gcf, 'Format', 'png');

% 保存为PDF
save_figures('figure1', gcf, 'Format', 'pdf');

% 同时保存为两种格式 (默认)
save_figures('figure1', gcf);

% 自定义分辨率
save_figures('figure1', gcf, 'Format', 'png', 'Resolution', 600);

% 多个图形
save_figures('output', [fig1, fig2]);
% 创建: output_1.png, output_1.pdf, output_2.png, output_2.pdf

% 自定义文件名
save_figures({'fig1', 'fig2'}, [fig1, fig2], 'Format', 'png');
```

**验证需求**: 7.5

## 测试

### 测试覆盖

所有函数都经过了全面测试:

1. **单元测试** (test_export_functions.m):
   - MEGData结构导出/导入
   - ProcessedData结构导出/导入
   - TrialData结构导出/导入
   - AnalysisResults结构导出/导入
   - 多结构导出
   - 往返验证 (保存和加载)
   - PNG导出
   - PDF导出
   - 两种格式导出
   - 多图形导出

2. **集成演示** (demo_export.m):
   - 完整工作流演示
   - 真实MEG数据模拟
   - 处理流程集成
   - 分析结果生成
   - 多可视化导出
   - 文件验证

### 测试结果

所有测试成功通过:
- ✓ 10/10 单元测试通过
- ✓ 所有文件格式正确创建
- ✓ 通过往返测试验证数据完整性
- ✓ 集成演示成功完成

## 文件结构

```
utils/
├── save_processed_data.m      # MAT文件导出函数
├── save_figures.m             # 图形导出函数
├── test_export_functions.m    # 单元测试
├── demo_export.m              # 集成演示
├── EXPORT_IMPLEMENTATION.md   # 本文档
├── test_output/               # 测试输出目录
│   ├── *.mat                  # 测试MAT文件
│   ├── *.png                  # 测试PNG文件
│   └── *.pdf                  # 测试PDF文件
└── demo_output/               # 演示输出目录
    ├── meg_processing_results.mat
    ├── time_series.png
    ├── time_series.pdf
    ├── psd.png
    └── psd.pdf
```

## 关键设计决策

1. **对象到结构的转换**: 对象在保存前转换为结构以确保兼容性，并包含类信息以便可能的重建。

2. **元数据包含**: 每个保存的MAT文件包含元数据 (时间戳、MATLAB版本、变量名) 以便追溯。

3. **灵活的输入处理**: 支持名称-值对和位置参数以方便用户。

4. **自动目录创建**: 如果输出目录不存在，会自动创建。

5. **高质量图形导出**: 图形使用'painters'渲染器用于PDF中的矢量图形，PNG使用可配置的DPI。

6. **错误处理**: 全面的错误消息帮助用户快速诊断问题。

## 与MEG处理流程的集成

这些导出函数与现有的MEG处理流程无缝集成:

```matlab
% 加载数据
meg_data = load_lvm_data('data.lvm', 4800, 1e-12);

% 处理数据
[processed_data, bad_channels] = preprocess_data(meg_data);
filtered_data = bandpass_filter(processed_data.data, 4800, 87, 91);

% 分析数据
[psd_freq, psd_power] = compute_psd(filtered_data, 4800);
snr = calculate_snr(psd_power, psd_freq, 17);

% 创建结果结构
results = AnalysisResults();
results = results.set_psd(psd_freq, psd_power);
results = results.set_snr(17, snr);

% 保存所有内容
save_processed_data('results.mat', ...
    'raw', meg_data, ...
    'processed', processed_data, ...
    'analysis', results);

% 创建并保存可视化
fig1 = plot_psd(psd_freq, psd_power);
fig2 = plot_time_series(processed_data.data, processed_data.time);
save_figures('figures', [fig1, fig2], 'Format', 'both');
```

## 需求验证

**需求 7.5**: "当系统保存结果时，系统应当以MATLAB .mat格式导出处理后的数据，以PNG或PDF格式导出图形"

✓ **已验证**: 
- 实现了MAT文件导出，完全支持所有数据结构
- 实现了PNG导出，可配置分辨率
- 实现了PDF导出，可配置纸张大小
- 可以同时导出两种格式
- 所有功能已测试和验证

## 未来增强

未来版本的潜在改进:

1. **压缩选项**: 添加对压缩MAT文件的支持 (-v7.3带压缩)
2. **批量导出**: 添加导出整个分析会话的函数
3. **自定义元数据**: 允许用户添加自定义元数据字段
4. **图形模板**: 添加预定义图形样式以获得一致的输出
5. **导出预设**: 为常见导出场景添加预设配置
6. **进度报告**: 为大型导出添加进度条
7. **选择性导出**: 添加仅导出结构中特定字段的选项

## 结论

任务 11 已成功完成，两个子任务都已实现并经过全面测试。导出函数为保存MEG处理结果和可视化提供了健壮、灵活和用户友好的接口。
