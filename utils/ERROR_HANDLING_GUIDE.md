# 错误处理和鲁棒性指南

本文档描述了MEG信号处理系统中实现的错误处理和鲁棒性特性。

## 概述

系统实现了全面的错误处理，以确保对可能包含以下内容的真实数据进行鲁棒操作:
- 缺失值 (NaN)
- 饱和通道
- 无效输入参数
- 损坏或格式错误的数据文件

## 组件

### 1. 输入验证 (`validate_inputs.m`)

**用途**: 所有函数的标准化输入验证

**验证类型**:
- `file_exists` - 验证文件存在性
- `positive` - 确保正数值
- `non_negative` - 确保非负值
- `in_range` - 验证值在指定范围内
- `numeric_scalar` - 检查数值标量
- `numeric_vector` - 检查数值向量
- `numeric_matrix` - 检查2D数值矩阵
- `string` - 验证字符串或字符类型
- `struct` - 验证结构类型
- `meg_data` - 验证MEGData对象/结构
- `processed_data` - 验证ProcessedData对象
- `trial_data` - 验证TrialData对象

**使用示例**:
```matlab
% 验证文件存在
validate_inputs('file_path', path, 'type', 'file_exists');

% 验证正采样率
validate_inputs('sampling_rate', fs, 'type', 'positive');

% 验证参数在范围内
validate_inputs('lambda', 0.995, 'type', 'in_range', 'range', [0.99, 1.0]);
```

**错误消息**:
所有验证错误包括:
- 参数名称
- 预期类型/范围
- 接收到的实际值
- 建议的补救措施

### 2. 缺失数据处理 (`handle_missing_data.m`)

**用途**: 检测和处理MEG信号中的NaN值

**方法**:
1. **interpolate** (默认) - 缺失值的线性插值
   - 处理最多 `max_gap` 个采样点的间隙 (默认: 100)
   - 对边界情况使用前向/后向填充
   - 用零填充大间隙

2. **mark** - 检测并报告但不修改数据
   - 用于检查和手动处理

3. **zero** - 用零替换NaN
   - 简单但可能引入伪影

4. **remove** - 删除包含NaN的采样点
   - 减少数据长度
   - 确保不残留NaN值

**使用示例**:
```matlab
% 插值缺失数据
options.max_gap = 100;
options.verbose = true;
[clean_data, info] = handle_missing_data(data, 'interpolate', options);

% 检查结果
if info.has_missing
    fprintf('在%d个通道中发现%d个NaN值\n', ...
        info.n_missing, length(info.missing_channels));
    fprintf('缺失段:\n');
    for ch = info.missing_channels'
        segments = info.missing_segments{ch};
        fprintf('  通道 %d: %d 段\n', ch, size(segments, 1));
    end
end
```

**输出信息**:
- `has_missing` - 指示是否找到NaN的布尔值
- `n_missing` - NaN值的总数
- `missing_channels` - 有NaN的通道
- `missing_segments` - 每个间隙的 [起始, 结束] 索引
- `method_used` - 应用的方法

### 3. 饱和通道处理 (`handle_saturated_channels.m`)

**用途**: 检测、报告和排除饱和通道

**检测标准**:
- 绝对值超过 `saturation_threshold` (默认: 1e-10 T)
- 饱和采样点百分比超过 `saturation_percentage` (默认: 1%)

**使用示例**:
```matlab
% 检测并排除饱和通道
options.saturation_threshold = 1e-10;  % 特斯拉
options.saturation_percentage = 1.0;   % 1%的采样点
options.exclude_saturated = true;
options.verbose = true;

[clean_data, info] = handle_saturated_channels(data, options);

% 检查结果
if info.has_saturated
    fprintf('排除了%d个饱和通道: %s\n', ...
        info.n_saturated, mat2str(info.saturated_channels));
    fprintf('剩余: %d 个通道\n', length(info.remaining_channels));
    
    % 详细信息
    for i = 1:length(info.saturation_details)
        detail = info.saturation_details{i};
        fprintf('通道 %d: %.2f%% 饱和, 最大值: %.3e\n', ...
            detail.channel, detail.saturation_percentage, detail.max_value);
    end
end
```

**输出信息**:
- `has_saturated` - 指示是否找到饱和的布尔值
- `n_saturated` - 饱和通道数
- `saturated_channels` - 饱和通道的索引
- `saturation_details` - 每个通道的详细信息:
  - `n_saturated_samples` - 饱和采样点计数
  - `saturation_percentage` - 饱和百分比
  - `max_value` - 最大绝对值
  - `saturated_segments` - [起始, 结束] 索引
- `excluded` - 是否排除了通道
- `remaining_channels` - 剩余通道的索引

## 与处理流程的集成

### 推荐的处理顺序

1. **加载数据**
   ```matlab
   data = load_lvm_data(file_path, fs, gain);
   ```

2. **处理饱和通道**
   ```matlab
   [data, sat_info] = handle_saturated_channels(data.meg_channels);
   ```

3. **处理缺失数据**
   ```matlab
   [data, missing_info] = handle_missing_data(data, 'interpolate');
   ```

4. **检测剩余坏通道**
   ```matlab
   [bad_channels, bad_types] = detect_bad_channels(data);
   ```

5. **继续处理**
   ```matlab
   [clean_data, ~] = preprocess_data(data_struct);
   ```

### 示例: 完整的错误鲁棒流程

```matlab
function [processed_data, error_log] = robust_meg_pipeline(file_path)
    % 初始化错误日志
    error_log = struct();
    
    % 1. 验证输入
    try
        validate_inputs('file_path', file_path, 'type', 'file_exists');
    catch ME
        error_log.file_validation = ME.message;
        error('文件验证失败: %s', ME.message);
    end
    
    % 2. 加载数据
    try
        data = load_lvm_data(file_path, 4800, 2.7e-3);
    catch ME
        error_log.data_loading = ME.message;
        error('数据加载失败: %s', ME.message);
    end
    
    % 3. 处理饱和通道
    sat_options = struct('exclude_saturated', true, 'verbose', true);
    [meg_data, sat_info] = handle_saturated_channels(data.meg_channels, sat_options);
    error_log.saturation = sat_info;
    
    if sat_info.n_saturated > 0
        warning('排除了 %d 个饱和通道', sat_info.n_saturated);
    end
    
    % 4. 处理缺失数据
    missing_options = struct('verbose', true);
    [meg_data, missing_info] = handle_missing_data(meg_data, 'interpolate', missing_options);
    error_log.missing_data = missing_info;
    
    if missing_info.has_missing
        warning('插值了 %d 个缺失值', missing_info.n_missing);
    end
    
    % 5. 更新数据结构
    data.meg_channels = meg_data;
    
    % 6. 预处理
    [processed_data, bad_channels] = preprocess_data(data);
    error_log.bad_channels = bad_channels;
    
    if ~isempty(bad_channels)
        warning('检测到 %d 个额外的坏通道', length(bad_channels));
    end
    
    % 7. 记录摘要
    fprintf('\n=== 处理摘要 ===\n');
    fprintf('饱和通道: %d\n', sat_info.n_saturated);
    fprintf('缺失值: %d\n', missing_info.n_missing);
    fprintf('坏通道: %d\n', length(bad_channels));
    fprintf('最终好通道: %d\n', size(processed_data.data, 1));
end
```

## 错误消息格式

所有错误消息遵循一致的格式:

```
MEG:<模块>:<错误类型>
<描述>
参数: <参数名称>
预期: <预期值或类型>
得到: <实际值>
建议: <补救建议>
```

示例:
```
MEG:Validation:OutOfRange
lambda必须在范围 [0.9900, 1.0000] 内，得到: 1.0500
参数: lambda
建议: 对RLS遗忘因子使用0.99到1.0之间的值
```

## 性能考虑

### 大型数据集
错误处理函数针对大型数据集进行了优化:
- **300秒 @ 4800 Hz** (1,440,000个采样点): 约1-2秒处理时间
- 使用向量化的内存高效操作
- 最小化数据复制

### 建议
1. **饱和检测**: 快速，O(n)复杂度
2. **缺失数据插值**: O(n*m)，其中m是间隙数
3. **输入验证**: 可忽略的开销

## 测试

提供了全面的测试:
- `tests/unit/test_input_validation.m` - 输入验证测试
- `tests/unit/test_missing_data.m` - 缺失数据处理测试
- `tests/unit/test_saturated_channels.m` - 饱和处理测试
- `tests/integration/test_error_handling_integration.m` - 集成测试

运行所有测试:
```matlab
run('tests/unit/test_input_validation.m');
run('tests/unit/test_missing_data.m');
run('tests/unit/test_saturated_channels.m');
run('tests/integration/test_error_handling_integration.m');
```

## 需求验证

此实现满足:
- **需求 8.2**: 使用插值的缺失数据处理
- **需求 8.3**: 饱和通道检测和排除
- **需求 8.5**: 带参数验证的详细错误消息

## 未来增强

潜在改进:
1. 高级插值方法 (样条、多项式)
2. 基于机器学习的坏通道检测
3. 基于数据统计的自动参数调整
4. 实时错误监控和报告
5. 与日志框架集成
