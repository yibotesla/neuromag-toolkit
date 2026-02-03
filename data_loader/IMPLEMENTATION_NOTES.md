# 数据加载器模块 - 实现说明

## 已完成任务

### 任务 2.1: LVM文件解析器实现 ✓
**文件**: `data_loader/load_lvm_data.m`

**功能**:
- 使用现有的 `lvm_import` 函数解析LVM格式文件
- 从第一个数据段提取所有68列数据
- 验证文件存在性和数据格式
- 处理采样率和增益参数
- 返回结构正确的MEGData对象

**主要特性**:
- 全面的输入验证
- 带有错误ID的详细错误消息
- 自动生成时间轴
- 与MEGData类集成

**实现需求**: 1.1, 1.5

### 任务 2.2: 通道识别逻辑 ✓
**文件**: `data_loader/identify_channels.m`

**功能**:
- 识别并分离通道类型:
  - 通道 1-64: MEG头部通道
  - 通道 65-67: 参考传感器
  - 最后两列: 刺激信号和触发信号
- 生成适当的通道标签
- 处理68列和69列数据格式

**主要特性**:
- 灵活识别不同数据格式的通道
- 自动生成标签 (MEG001-MEG064, REF1-REF3, STIMULUS, TRIGGER)
- 清晰的关注点分离

**实现需求**: 1.2

## 测试

### 单元测试
**文件**: `tests/unit/test_data_loader.m`

所有测试成功通过:
- ✓ 68列数据的通道识别
- ✓ 69列数据的通道识别
- ✓ 无效输入的错误处理
- ✓ MEGData结构验证
- ✓ 通道标签生成

### 测试覆盖范围
- 输入验证 (文件路径、采样率、增益)
- 通道索引识别
- 标签生成
- 边界情况的错误处理
- MEGData对象初始化

## 使用示例

```matlab
% 添加路径
addpath('data_loader');
addpath('utils');

% 从LVM文件加载MEG数据
sampling_rate = 4800;  % Hz
gain = 2.7e-3;         % V到T的转换系数
data = load_lvm_data('path/to/data.lvm', sampling_rate, gain);

% 访问数据
meg_signals = data.meg_channels;  % 64×N 矩阵
ref_signals = data.ref_channels;  % 3×N 矩阵
stimulus = data.stimulus;         % 1×N 向量
trigger = data.trigger;           % 1×N 向量
time_axis = data.time;            % 1×N 向量
labels = data.channel_labels;     % 64×1 单元数组

% 检查采样率和增益
fs = data.fs;                     % 4800 Hz
g = data.gain;                    % 2.7e-3
```

## 数据结构

`load_lvm_data` 函数返回一个具有以下结构的 `MEGData` 对象:

```matlab
MEGData
  ├── meg_channels    [64×N double]  - 头部MEG传感器数据
  ├── ref_channels    [3×N double]   - 参考传感器数据
  ├── stimulus        [1×N double]   - 刺激信号
  ├── trigger         [1×N double]   - 触发信号
  ├── time            [1×N double]   - 时间轴 (秒)
  ├── fs              [scalar]       - 采样率 (Hz)
  ├── gain            [scalar]       - 增益系数 (V到T)
  ├── channel_labels  [64×1 cell]    - 通道标签
  └── bad_channels    [1×M double]   - 坏通道索引 (初始为空)
```

## 错误处理

实现包含健壮的错误处理:

1. **文件未找到**: `MEG:DataLoader:FileNotFound`
   - 当LVM文件不存在时抛出
   - 错误消息中包含文件路径

2. **无效输入**: `MEG:DataLoader:InvalidInput`
   - 验证file_path是字符串
   - 验证sampling_rate为正数
   - 验证gain为正数

3. **解析错误**: `MEG:DataLoader:ParseError`
   - 当lvm_import失败时抛出
   - 包含原始错误消息

4. **无数据**: `MEG:DataLoader:NoData`
   - 当LVM文件中未找到数据段时抛出

5. **无效列数**: `MEG:DataLoader:InvalidColumns`
   - 当数据不是68列时抛出
   - 报告实际找到的列数

## 与其他模块的集成

数据加载器模块与以下模块无缝集成:
- **预处理器(Preprocessor)**: 为预处理提供干净的MEGData结构
- **去噪器(Denoiser)**: 分离MEG通道和参考通道用于自适应滤波
- **分析器(Analyzer)**: 提供触发信号用于时程提取
- **可视化器(Visualizer)**: 提供时间轴和通道标签用于绘图

## 后续步骤

数据加载器模块已完成，可以与以下模块集成:
1. 预处理器模块 (任务 3) - 直流去除和坏通道检测
2. 去噪器模块 (任务 4) - 尖峰噪声去除
3. 自适应滤波器模块 (任务 5) - LMS/RLS滤波

## 注意事项

- 实现假设LVM文件包含恰好68列
- 对于68列数据，通道65-66是参考传感器 (不是65-67)
- 最后两列始终是刺激信号和触发信号
- 时间轴从0开始，以1/fs递增
- 坏通道初始化为空，将由预处理器填充
