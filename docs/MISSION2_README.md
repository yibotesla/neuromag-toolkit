# 任务2：人类听觉响应处理

## 概述

任务2实现了一个完整的处理流程，用于从人类脑磁图（MEG）数据中提取听觉诱发场（AEF, Auditory Evoked Field）和听觉稳态响应（ASSR, Auditory Steady-State Response）。该流程包括双分支频率特定滤波、触发信号检测、时程提取、总平均和收敛性分析。

## 功能特性

### 双分支处理

流程将数据分为两个并行处理分支：

1. **AEF分支**：提取低频听觉诱发场
   - 30Hz低通滤波器
   - 捕获瞬态诱发响应（约100ms潜伏期）
   - 适用于分析事件相关场

2. **ASSR分支**：提取高频稳态响应
   - 89±2Hz带通滤波器
   - 捕获持续振荡响应
   - 适用于分析频率跟随响应

### 处理步骤

1. **数据加载**：加载LVM文件或生成合成数据
2. **预处理**：直流去除和坏通道检测
3. **自适应滤波**：使用参考传感器进行噪声消除
4. **频率特定滤波**：双分支AEF/ASSR分离
5. **触发信号检测**：识别刺激开始时间
6. **时程提取**：提取与触发信号对齐的试次
7. **总平均**：计算平均响应
8. **收敛性分析**：确定所需的最少试次数

## 使用方法

### 基本用法

```matlab
% 加载配置
config = config_template();

% 处理真实数据
results = process_mission2('path/to/data.lvm', config);

% 使用自定义设置处理
results = process_mission2('path/to/data.lvm', config, ...
    'PlotResults', true, ...
    'SaveResults', true, ...
    'OutputDir', 'outputs/mission2', ...
    'Verbose', true);
```

### 演示模式

```matlab
% 使用合成数据运行
demo_mission2;

% 或直接调用
results = process_mission2('demo', config);
```

### 快速测试

```matlab
% 运行快速验证测试
test_mission2_quick;

% 运行基本组件测试
test_mission2_basic;
```

## 配置

`config_template.m` 中的任务2关键参数：

```matlab
config.mission2.aef_cutoff = 30;              % Hz - AEF低通截止频率
config.mission2.assr_center = 89;             % Hz - ASSR带通中心频率
config.mission2.assr_bandwidth = 2;           % Hz - ASSR带通宽度（±2Hz）
config.mission2.trigger_threshold = 2.5;      % 触发信号检测阈值
config.mission2.min_trigger_interval = 0.5;   % 最小间隔（秒）
config.mission2.pre_time = 0.2;               % 触发前时间（秒）
config.mission2.post_time = 0.8;              % 触发后时间（秒）
config.mission2.convergence_threshold = 0.9;  % 相关系数阈值
```

## 输出结构

`results` 结构体包含：

```matlab
results.raw_data              % 原始MEGData对象
results.preprocessed          % 预处理后的数据
results.aef_filtered          % AEF滤波后的数据
results.assr_filtered         % ASSR滤波后的数据
results.trigger_indices       % 检测到的触发信号位置
results.aef_trials            % AEF TrialData对象
results.assr_trials           % ASSR TrialData对象
results.aef_grand_average     % AEF总平均（N_channels × N_samples）
results.assr_grand_average    % ASSR总平均（N_channels × N_samples）
results.aef_convergence       % AEF收敛性分析
results.assr_convergence      % ASSR收敛性分析
results.bad_channels          % 坏通道列表
results.noise_reduction       % 每个通道的噪声抑制（%）
```

### 收敛性分析结构

```matlab
convergence.n_trials          % 测试的试次数向量
convergence.correlation       % 相关系数
convergence.rmse              % 均方根误差值
convergence.min_trials        % 达到阈值所需的最少试次
convergence.threshold         % 使用的相关系数阈值
```

## 可视化

流程生成全面的可视化：

### 主结果图
- AEF总平均（选定通道）
- ASSR总平均（选定通道）
- AEF收敛曲线
- ASSR收敛曲线
- 触发信号检测图
- 最少试次比较

### 频谱分析图
- AEF滤波后数据PSD（0-50 Hz）
- ASSR滤波后数据PSD（70-110 Hz）

### 附加图（演示模式）
- 单个试次示例
- 多通道总平均
- 收敛性比较
- 逐通道峰值幅值
- 每个通道的噪声抑制

## 需求验证

任务2实现了以下需求：

- **需求 5.1**：AEF和ASSR的频率特定滤波
- **需求 5.2**：使用参考传感器的自适应滤波
- **需求 5.3**：从刺激通道检测触发信号
- **需求 5.4**：与触发信号对齐的1秒试次时程提取
- **需求 5.5**：总平均计算
- **需求 6.1**：总平均作为金标准
- **需求 6.2**：随机试次采样
- **需求 6.3**：收敛性指标计算
- **需求 6.4**：收敛曲线绘制
- **需求 6.5**：最少试次确定

## 性能

### 典型处理时间（标准工作站）

- 20秒数据：约30秒处理时间
- 60秒数据：约2-3分钟处理时间
- 收敛性分析：每个分支约10-20秒

### 优化建议

1. 使用LMS代替RLS以加快自适应滤波速度
2. 降低滤波器阶数以提高速度（权衡衰减效果）
3. 减少收敛性分析迭代次数以进行快速测试
4. 批量处理时跳过绘图

```matlab
% 快速配置
config.adaptive_filter.algorithm = 'LMS';
config.adaptive_filter.filter_order = 5;

% 快速处理
results = process_mission2(file_path, config, ...
    'PlotResults', false, ...
    'Verbose', false);
```

## 文件

### 主脚本
- `process_mission2.m` - 主处理流程
- `scripts/demos/demo_mission2.m` - 带可视化的演示脚本（合成数据，生成 outputs/mission2/）
- `scripts/tests/test_mission2_quick.m` - 更快的验证（降低部分耗时项）
- `scripts/tests/test_mission2_basic.m` - 基础快速验证

### 依赖项
- `data_loader/` - LVM文件解析
- `preprocessor/` - 数据预处理
- `filter/` - 频率滤波（低通、带通）
- `analyzer/` - 触发信号检测、时程提取、平均、收敛性
- `visualizer/` - 绘图函数
- `utils/` - 数据结构（MEGData、TrialData等）

## 故障排除

### 常见问题

1. **"未检测到触发信号"**
   - 检查触发阈值：`config.mission2.trigger_threshold`
   - 验证触发通道是否有信号
   - 如果触发信号过于接近，调整最小间隔

2. **"提取的试次太少"**
   - 检查数据时长是否足够
   - 验证触发信号是否过于接近数据边界
   - 调整前/后时间窗口

3. **"未达到收敛阈值"**
   - 对于噪声数据或试次较少，这是正常的
   - 降低阈值或增加试次数
   - 检查数据质量

4. **"处理速度太慢"**
   - 切换到LMS算法
   - 降低滤波器阶数
   - 减少测试数据时长

### 错误消息

- **"触发信号X过于接近数据边界"**：正常警告，该试次被跳过
- **"未达到相关系数阈值"**：增加试次或降低阈值
- **"试次不足"**：数据中需要更多触发信号

## 示例

### 示例1：使用自定义滤波处理

```matlab
config = config_template();
config.mission2.aef_cutoff = 40;  % 更宽的AEF带宽
config.mission2.assr_center = 80;  % 不同的ASSR频率

results = process_mission2('data.lvm', config);
```

### 示例2：批量处理

```matlab
files = {'data1.lvm', 'data2.lvm', 'data3.lvm'};
config = config_template();

for i = 1:length(files)
    results{i} = process_mission2(files{i}, config, ...
        'PlotResults', false, ...
        'SaveResults', true, ...
        'OutputDir', sprintf('results_%d', i));
end
```

### 示例3：比较不同阈值

```matlab
thresholds = [0.85, 0.90, 0.95];
config = config_template();

for i = 1:length(thresholds)
    config.mission2.convergence_threshold = thresholds(i);
    results{i} = process_mission2('demo', config, 'PlotResults', false);
    fprintf('阈值 %.2f: AEF最少=%d, ASSR最少=%d\n', ...
        thresholds(i), ...
        results{i}.aef_convergence.min_trials, ...
        results{i}.assr_convergence.min_trials);
end
```

## 参考文档

- 输出文件与作业要求对齐：`outputs/README.md`、`docs/OUTPUTS.md`
- 项目结构：`docs/PROJECT_STRUCTURE.md`
- API 说明：`docs/API_DOCUMENTATION.md`

## 未来增强

任务2的潜在改进：

1. AEF/ASSR的源定位
2. 时频分析
3. 响应的统计检验
4. 多受试者总平均
5. 自动伪迹剔除
6. 实时处理模式

## 注意事项

- 合成数据生成器创建真实的AEF和ASSR响应用于测试
- 收敛性分析使用随机采样来估计稳定性
- AEF和ASSR独立处理以便比较
- 流程设计用于处理具有各种噪声水平的真实人类听觉数据
