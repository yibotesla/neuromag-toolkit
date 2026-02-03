# 数据加载器模块

本模块负责加载和解析LVM格式的脑磁图(MEG)数据文件。

## 函数

- `load_lvm_data.m` - 加载LVM文件并提取MEG数据的主函数
- `identify_channels.m` - 识别并分离MEG通道、参考通道、刺激信号和触发信号

## 使用方法

```matlab
data_struct = load_lvm_data(file_path, sampling_rate, gain);
```

## 需求

实现需求 1.1, 1.2, 1.5
