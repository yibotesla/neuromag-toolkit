# 错误处理快速参考

## 快速开始

```matlab
% 添加utils到路径
addpath('utils');

% 1. 验证输入
validate_inputs('file_path', path, 'type', 'file_exists');
validate_inputs('fs', 4800, 'type', 'positive');

% 2. 处理饱和通道
[clean_data, sat_info] = handle_saturated_channels(data);

% 3. 处理缺失数据
[clean_data, missing_info] = handle_missing_data(clean_data, 'interpolate');
```

## 常见验证模式

```matlab
% 文件存在
validate_inputs('file', path, 'type', 'file_exists');

% 正数
validate_inputs('fs', 4800, 'type', 'positive');

% 非负数
validate_inputs('pre_time', 0.2, 'type', 'non_negative');

% 在范围内
validate_inputs('lambda', 0.995, 'type', 'in_range', 'range', [0.99, 1.0]);

% 数值类型
validate_inputs('data', matrix, 'type', 'numeric_matrix');
validate_inputs('triggers', vector, 'type', 'numeric_vector');
validate_inputs('fs', scalar, 'type', 'numeric_scalar');

% 数据结构
validate_inputs('meg_data', data, 'type', 'meg_data');
```

## 缺失数据处理

```matlab
% 插值 (默认)
[clean, info] = handle_missing_data(data, 'interpolate');

% 带选项
opts.max_gap = 100;      % 最大插值采样点数
opts.verbose = true;     % 显示警告
[clean, info] = handle_missing_data(data, 'interpolate', opts);

% 其他方法
[clean, info] = handle_missing_data(data, 'mark');    % 仅检测
[clean, info] = handle_missing_data(data, 'zero');    % 用0替换
[clean, info] = handle_missing_data(data, 'remove');  % 删除采样点

% 检查结果
if info.has_missing
    fprintf('%d个NaN值在通道: %s\n', ...
        info.n_missing, mat2str(info.missing_channels));
end
```

## 饱和通道处理

```matlab
% 基本使用
[clean, info] = handle_saturated_channels(data);

% 带选项
opts.saturation_threshold = 1e-10;    % 特斯拉
opts.saturation_percentage = 1.0;     % 1%的采样点
opts.exclude_saturated = true;        % 删除通道
opts.verbose = true;                  % 显示详情
[clean, info] = handle_saturated_channels(data, opts);

% 检查结果
if info.has_saturated
    fprintf('排除的通道: %s\n', mat2str(info.saturated_channels));
    fprintf('剩余: %d/%d 通道\n', ...
        length(info.remaining_channels), size(data,1));
end
```

## 完整流程示例

```matlab
function [processed, log] = robust_pipeline(file_path)
    log = struct();
    
    % 验证
    validate_inputs('file_path', file_path, 'type', 'file_exists');
    
    % 加载
    data = load_lvm_data(file_path, 4800, 2.7e-3);
    
    % 处理饱和
    [meg, sat] = handle_saturated_channels(data.meg_channels);
    log.saturation = sat;
    
    % 处理缺失
    [meg, miss] = handle_missing_data(meg, 'interpolate');
    log.missing = miss;
    
    % 更新和预处理
    data.meg_channels = meg;
    [processed, bad] = preprocess_data(data);
    log.bad_channels = bad;
    
    % 摘要
    fprintf('饱和: %d, 缺失: %d, 坏通道: %d\n', ...
        sat.n_saturated, miss.n_missing, length(bad));
end
```

## 错误消息格式

```
MEG:<模块>:<错误类型>
<描述>
参数: <名称>
预期: <预期>
得到: <实际>
```

## 常见错误标识符

- `MEG:Validation:FileNotFound` - 文件不存在
- `MEG:Validation:NotPositive` - 值不是正数
- `MEG:Validation:OutOfRange` - 值超出范围
- `MEG:MissingData:NaNDetected` - 发现NaN值
- `MEG:SaturatedChannels:Detected` - 发现饱和通道

## 测试

```matlab
% 运行所有测试
run('tests/unit/test_input_validation.m');
run('tests/unit/test_missing_data.m');
run('tests/unit/test_saturated_channels.m');
run('tests/integration/test_error_handling_integration.m');
```

## 性能

- 大型数据集 (300秒 @ 4800Hz): 约1-2秒
- 验证: 可忽略的开销
- 内存高效: 最小化复制

## 另见

- `ERROR_HANDLING_GUIDE.md` - 详细文档
- `docs/TASK_14_IMPLEMENTATION_SUMMARY.md` - 实现细节
