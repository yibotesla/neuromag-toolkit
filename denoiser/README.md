# 去噪器模块

本模块负责噪声去除操作。

## 函数

- `median_filter_despike.m` - 使用中值滤波去除尖峰噪声
- `wavelet_despike.m` - 使用小波阈值去除尖峰噪声
- `adaptive_filter.m` - 自适应噪声消除 (LMS/RLS)

## 使用方法

```matlab
data_filtered = adaptive_filter(meg_data, ref_data, algorithm, params);
```

## 需求

实现需求 2.4, 2.5, 3.1, 3.2, 3.3, 3.5
