# 输出结果说明（与作业题目对应）

本目录用于集中存放核心流程的输出结果与可视化。以下内容按作业题目中的任务与技术点对应整理。

---

## 最新测试运行结果（2026-02-03）

### Mission 1 结果

| 指标 | 数值 |
|------|------|
| 处理通道数 | 64 |
| 坏通道数 | 0 |
| 平均噪声降低 | 61.27% |
| SNR提升 | 2.63 dB |
| 17Hz峰值检测率 | 64/64 (100%) |
| 检测峰值频率 | 16.99 Hz |

### Mission 2 结果

| 指标 | 数值 |
|------|------|
| 处理通道数 | 64 |
| 坏通道数 | 0 |
| 检测触发数 | 10 |
| 提取试次数 | 10 |
| 平均噪声降低 | 68.95% |
| AEF收敛最小试次 | 10 (阈值 ≥ 0.90) |
| ASSR收敛最小试次 | 10 (阈值 ≥ 0.90) |

### FieldTrip 集成测试

| 功能 | 状态 |
|------|------|
| FieldTrip 版本 | d20ea86 |
| MEGData → FieldTrip 转换 | ✅ 通过 |
| TrialData → FieldTrip 转换 | ✅ 通过 |
| 单轴 grad 构建 (64 通道) | ✅ 通过 |
| 双轴 grad 构建 (128 通道) | ✅ 通过 |

---

## 任务1：17Hz模体数据（Mission 1）

**对应作业要求：** PSD、SNR、峰值检测、去噪与自适应滤波等（任务1核心要求）

**输出文件（默认位置：`outputs/mission1/`）：**
- `mission1_results.mat`：完整结果结构体（包含原始/预处理/滤波后数据与指标）
- `mission1_results.png` / `mission1_results.pdf`：主结果图（PSD与SNR对比）
- `channel_analysis.png` / `channel_analysis.pdf`：通道级SNR与峰值检测统计
- `spectral_comparison.png` / `spectral_comparison.pdf`：最佳通道频谱对比

**对应关系：**
- PSD计算 → `mission1_results.png/pdf`（频谱展示）
- SNR计算与提升 → `mission1_results.png/pdf`、`channel_analysis.png/pdf`
- 17Hz峰值检测 → `channel_analysis.png/pdf`
- 去噪/自适应滤波效果 → `spectral_comparison.png/pdf`

## 任务2：人类听觉数据（Mission 2）

**对应作业要求：** AEF/ASSR分支滤波、触发检测、试次提取、总平均、收敛分析等（任务2核心要求）

**输出文件（默认位置：`outputs/mission2/`）：**
- `mission2_results.mat`：完整结果结构体（AEF/ASSR数据、试次与收敛信息）
- `mission2_grand_averages.png` / `mission2_grand_averages.pdf`：AEF/ASSR总平均
- `mission2_psd_comparison.png` / `mission2_psd_comparison.pdf`：AEF/ASSR频谱对比
- `mission2_trial_examples.png/pdf`：试次示例（由演示脚本生成）
- `mission2_channel_analysis.png/pdf`：通道级统计（由演示脚本生成）

**对应关系：**
- AEF/ASSR分支滤波 → `mission2_grand_averages.png/pdf`
- 触发检测与试次提取 → `mission2_results.mat`
- 总平均与收敛分析 → `mission2_grand_averages.png/pdf`、`mission2_results.mat`
- 频域对比 → `mission2_psd_comparison.png/pdf`

---

## 生成方式

使用默认输出目录运行核心流程即可自动生成上述结果：
- 任务1：`process_mission1(..., 'SaveResults', true)`
- 任务2：`process_mission2(..., 'SaveResults', true)`

演示脚本会额外生成试次示例与通道级统计：
- `scripts/demos/demo_mission1.m`
- `scripts/demos/demo_mission2.m`

---

## 真实数据处理

处理真实OPM-MEG数据时，输出将保存到：
- Mission1：`outputs/mission1_real/`
- Mission2：`outputs/mission2_real/`

运行方式：
```matlab
demo_real_data  % 交互式演示
```
