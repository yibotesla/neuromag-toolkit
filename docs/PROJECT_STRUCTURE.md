# 项目结构说明

本文件用于快速理解当前工作目录的核心代码、脚本与结果输出位置。

## 一、核心目录

- `data_loader/`：LVM解析与通道识别
- `preprocessor/`：预处理（去直流、坏通道、缺失数据处理）
- `denoiser/`：尖峰噪声去除与自适应降噪
- `filter/`：低通/带通/陷波滤波器
- `analyzer/`：PSD、SNR、触发检测、试次提取、总平均、收敛分析
- `visualizer/`：可视化绘图
- `utils/`：数据结构、输入验证、导出工具
- `tests/`：单元/集成/性能测试套件
- `docs/`：项目说明文档与指南
- `scripts/`：演示、快速测试、验证脚本
- `outputs/`：统一输出目录（与作业题目对齐）

## 二、主要入口脚本

- `process_mission1.m`：任务1主流程
- `process_mission2.m`：任务2主流程
- `scripts/demos/demo_mission1.m` / `scripts/demos/demo_mission2.m`：演示脚本
- `scripts/tests/test_mission1.m` / `scripts/tests/test_mission2_basic.m` / `scripts/tests/test_mission2_quick.m`：快速验证
- `scripts/verification/verify_setup.m`：环境与结构快速检查（可选）

## 三、配置文件

- `default_config.m`：全量默认配置（推荐）
- `config_template.m`：简化模板配置

## 四、测试与验证

- `tests/unit/`：单元测试脚本（`test_*.m`）
- `tests/integration/`：集成/性能测试脚本
- `tests/property/`：属性测试说明（可选）

## 五、输出与中间结果

- `outputs/mission1/`、`outputs/mission2/`：流程运行输出
- `outputs/test_output/`：导出函数测试产物
- `outputs/temp_roundtrip_test.mat`：往返测试产物
