# 集成测试

本目录包含验证完整处理流程的集成测试。

## 测试文件

集成测试验证端到端工作流：

- `test_mission1_pipeline.m` - 完整的任务1处理流程
- `test_mission2_pipeline.m` - 完整的任务2处理流程
- `test_full_workflow.m` - 从LVM文件到结果的完整工作流

## 运行测试

```matlab
% 运行所有集成测试
runtests('tests/integration')

% 运行特定集成测试
runtests('tests/integration/test_mission1_pipeline.m')
```

## 测试覆盖范围

集成测试验证：
- 完整的处理流程正确工作
- 数据在模块之间正确流动
- 所有中间输出都有效
- 最终结果满足需求
- 性能满足规范

## 测试数据

集成测试使用：
- 合成测试数据（生成的）
- 真实数据样本（如果可用）
- 边界情况场景
