# 基于属性的测试

本目录包含基于属性的测试，这些测试通过大量随机生成的输入来验证通用属性。

## 测试文件

属性测试验证设计文档中的正确性属性：

- `test_property_lvm_parsing.m` - 属性 1: LVM解析完整性
- `test_property_channel_identification.m` - 属性 2: 通道识别
- `test_property_dc_removal.m` - 属性 3: 直流去除有效性
- `test_property_bad_channels.m` - 属性 4: 坏通道检测
- `test_property_psd.m` - 属性 6: 功率谱密度计算格式
- `test_property_snr.m` - 属性 7: 信噪比计算
- `test_property_spike_removal.m` - 属性 9: 尖峰去除保持性
- `test_property_lms.m` - 属性 12: 最小均方误差最小化
- `test_property_rls.m` - 属性 13: 递归最小二乘遗忘因子
- `test_property_filters.m` - 属性 15-19: 滤波器属性
- `test_property_triggers.m` - 属性 21: 触发信号检测
- `test_property_epoching.m` - 属性 22: 时程提取正确性
- `test_property_averaging.m` - 属性 23: 总平均
- `test_property_convergence.m` - 属性 24-27: 收敛分析
- `test_property_export.m` - 属性 28: 文件导出往返
- `test_property_robustness.m` - 属性 29-31: 鲁棒性

## 运行测试

```matlab
% 运行所有属性测试
runtests('tests/property')

% 运行特定属性测试
runtests('tests/property/test_property_dc_removal.m')
```

## 测试配置

每个属性测试至少运行100次迭代，使用随机生成的数据来验证该属性在所有有效输入上都成立。

## 属性测试格式

每个测试都标记有引用设计文档的注释：

```matlab
% Feature: meg-signal-processing, Property 3: DC Removal Effectiveness
% Validates: Requirements 1.3
```
