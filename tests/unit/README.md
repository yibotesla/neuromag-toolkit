# 单元测试

本目录包含针对各个函数和模块的单元测试。

## 测试文件

单元测试验证特定示例和边界情况：

- `test_data_loader.m` - 数据加载函数测试
- `test_preprocessor.m` - 预处理函数测试
- `test_adaptive_filter.m` - 自适应滤波测试
- `test_frequency_filter.m` - 频率滤波器测试
- `test_signal_analyzer.m` - 信号分析函数测试
- `test_epoch_extractor.m` - 时程提取函数测试

## 运行测试

```matlab
% 运行所有单元测试
runtests('tests/unit')

% 运行特定测试文件
runtests('tests/unit/test_data_loader.m')
```

## 测试覆盖范围

单元测试关注：
- 演示正确行为的特定示例
- 重要的边界情况（空输入、边界值）
- 错误条件和错误处理
- 组件之间的集成点
