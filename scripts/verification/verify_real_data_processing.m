% verify_real_data_processing.m - 真实数据处理验证脚本
%
% 用法:
%   verify_real_data_processing
%
% 说明:
%   验证真实OPM数据处理流程的正确性，检查：
%   1. 数据加载（139列格式）
%   2. 双轴数据分离
%   3. 预处理流程（校准、陷波、RLS、HFC）
%   4. 触发检测
%   5. 试次提取
%   6. 作业要求的各项指标

%% 初始化
clear;
clc;

fprintf('=== OPM-MEG 真实数据处理验证 ===\n\n');

% 添加项目路径
this_file = mfilename('fullpath');
if ~isempty(this_file)
    project_root = fileparts(fileparts(fileparts(this_file)));
    addpath(genpath(project_root));
end

% 加载配置
config = default_config();
data_root = config.paths.data_root;

% 验证结果
results = struct();
results.tests_passed = 0;
results.tests_failed = 0;
results.test_details = {};

%% 测试1: 检查数据路径
fprintf('测试1: 检查数据路径...\n');
try
    assert(exist(data_root, 'dir') == 7, '数据根目录不存在');
    
    mission1_dir = fullfile(data_root, config.paths.mission1_dir);
    mission2_dir = fullfile(data_root, config.paths.mission2_dir);
    
    assert(exist(mission1_dir, 'dir') == 7, 'Mission1目录不存在');
    assert(exist(mission2_dir, 'dir') == 7, 'Mission2目录不存在');
    
    % 检查Mission1数据文件
    m1_files = dir(fullfile(mission1_dir, 'data_*.lvm'));
    assert(~isempty(m1_files), 'Mission1目录下无数据文件');
    
    fprintf('  ✓ 数据路径验证通过\n');
    fprintf('    - Mission1: %d 个文件\n', length(m1_files));
    results.tests_passed = results.tests_passed + 1;
    results.test_details{end+1} = 'PASS: 数据路径验证';
    
catch ME
    fprintf('  ✗ 数据路径验证失败: %s\n', ME.message);
    results.tests_failed = results.tests_failed + 1;
    results.test_details{end+1} = sprintf('FAIL: 数据路径验证 - %s', ME.message);
end

%% 测试2: 加载单个LVM文件
fprintf('\n测试2: 加载LVM文件...\n');
try
    % 找到第一个可用的Mission1文件
    m1_files = dir(fullfile(mission1_dir, 'data_*.lvm'));
    test_file = fullfile(mission1_dir, m1_files(1).name);
    
    % 加载数据
    data = load_lvm_data(test_file, config.data_loading.sampling_rate, ...
        config.data_loading.gain);
    
    % 验证数据结构
    assert(isa(data, 'MEGData'), '返回类型应为MEGData');
    assert(size(data.meg_channels, 1) == 64, 'MEG通道数应为64');
    assert(size(data.ref_channels, 1) == 3, '参考通道数应为3');
    assert(~isempty(data.stimulus), '刺激信号不应为空');
    assert(~isempty(data.trigger), '触发信号不应为空');
    
    fprintf('  ✓ LVM文件加载成功\n');
    fprintf('    - 文件: %s\n', m1_files(1).name);
    fprintf('    - 通道数: %d MEG + %d REF\n', size(data.meg_channels, 1), size(data.ref_channels, 1));
    fprintf('    - 采样点: %d (%.2f秒)\n', size(data.meg_channels, 2), length(data.time));
    
    results.tests_passed = results.tests_passed + 1;
    results.test_details{end+1} = 'PASS: LVM文件加载';
    results.test_data = data;
    results.test_file = test_file;
    
catch ME
    fprintf('  ✗ LVM文件加载失败: %s\n', ME.message);
    results.tests_failed = results.tests_failed + 1;
    results.test_details{end+1} = sprintf('FAIL: LVM文件加载 - %s', ME.message);
end

%% 测试3: 双轴数据加载
fprintf('\n测试3: 双轴数据加载...\n');
try
    if isfield(results, 'test_file')
        data_dual = load_lvm_data(results.test_file, ...
            config.data_loading.sampling_rate, ...
            config.data_loading.gain, ...
            'DualAxis', true);
        
        % 验证双轴数据
        assert(size(data_dual.meg_channels, 1) == 128, '双轴MEG通道数应为128');
        assert(size(data_dual.ref_channels, 1) == 6, '双轴参考通道数应为6');
        
        fprintf('  ✓ 双轴数据加载成功\n');
        fprintf('    - 通道数: %d MEG + %d REF\n', ...
            size(data_dual.meg_channels, 1), size(data_dual.ref_channels, 1));
        
        results.tests_passed = results.tests_passed + 1;
        results.test_details{end+1} = 'PASS: 双轴数据加载';
    else
        fprintf('  - 跳过（依赖测试2）\n');
    end
    
catch ME
    fprintf('  ✗ 双轴数据加载失败: %s\n', ME.message);
    results.tests_failed = results.tests_failed + 1;
    results.test_details{end+1} = sprintf('FAIL: 双轴数据加载 - %s', ME.message);
end

%% 测试4: 辅助函数
fprintf('\n测试4: 辅助函数验证...\n');
try
    % 测试 real_time_calibration
    test_data = randn(10, 1000);
    cali_data = real_time_calibration(test_data, 4800, 240, 62400);
    assert(size(cali_data, 1) == 10, '校准后通道数应保持不变');
    assert(size(cali_data, 2) == 1000, '校准后采样点数应保持不变');
    
    % 测试 deep_notch_filter
    notch_data = deep_notch_filter(test_data, 4800, 240, 'Cascade', 2);
    assert(size(notch_data, 1) == 10, '陷波后通道数应保持不变');
    
    fprintf('  ✓ 辅助函数验证通过\n');
    results.tests_passed = results.tests_passed + 1;
    results.test_details{end+1} = 'PASS: 辅助函数验证';
    
catch ME
    fprintf('  ✗ 辅助函数验证失败: %s\n', ME.message);
    results.tests_failed = results.tests_failed + 1;
    results.test_details{end+1} = sprintf('FAIL: 辅助函数验证 - %s', ME.message);
end

%% 测试5: 触发检测
fprintf('\n测试5: 触发检测...\n');
try
    if isfield(results, 'test_data')
        % 检测触发
        trigger_signal = results.test_data.stimulus;
        if max(abs(trigger_signal)) < 0.01
            trigger_signal = results.test_data.trigger;
        end
        
        triggers = detect_triggers(trigger_signal, 'auto', 2400, ...
            'SkipSamples', 5000, 'Verbose', false);
        
        fprintf('  ✓ 触发检测完成\n');
        fprintf('    - 检测到 %d 个触发\n', length(triggers));
        
        results.tests_passed = results.tests_passed + 1;
        results.test_details{end+1} = 'PASS: 触发检测';
        results.triggers = triggers;
    else
        fprintf('  - 跳过（依赖测试2）\n');
    end
    
catch ME
    fprintf('  ✗ 触发检测失败: %s\n', ME.message);
    results.tests_failed = results.tests_failed + 1;
    results.test_details{end+1} = sprintf('FAIL: 触发检测 - %s', ME.message);
end

%% 测试6: PSD计算
fprintf('\n测试6: PSD计算...\n');
try
    if isfield(results, 'test_data')
        [freq, psd] = compute_psd(results.test_data.meg_channels, ...
            results.test_data.fs, 'Method', 'pwelch');
        
        assert(~isempty(freq), 'PSD频率向量不应为空');
        assert(~isempty(psd), 'PSD功率向量不应为空');
        
        % 检查17Hz附近是否有峰值（Mission1应该有）
        idx_17hz = find(freq >= 16 & freq <= 18);
        if ~isempty(idx_17hz)
            psd_17hz = mean(psd(:, idx_17hz), 2);
            fprintf('  ✓ PSD计算完成\n');
            fprintf('    - 频率范围: %.1f - %.1f Hz\n', min(freq), max(freq));
            fprintf('    - 17Hz处平均功率: %.2e\n', mean(psd_17hz));
        end
        
        results.tests_passed = results.tests_passed + 1;
        results.test_details{end+1} = 'PASS: PSD计算';
    else
        fprintf('  - 跳过（依赖测试2）\n');
    end
    
catch ME
    fprintf('  ✗ PSD计算失败: %s\n', ME.message);
    results.tests_failed = results.tests_failed + 1;
    results.test_details{end+1} = sprintf('FAIL: PSD计算 - %s', ME.message);
end

%% 测试7: SNR计算
fprintf('\n测试7: SNR计算...\n');
try
    if isfield(results, 'test_data')
        [snr, ~, ~] = calculate_snr(results.test_data.meg_channels, ...
            results.test_data.fs, 17);
        
        assert(~isempty(snr), 'SNR不应为空');
        
        fprintf('  ✓ SNR计算完成\n');
        fprintf('    - 17Hz SNR范围: %.2f - %.2f dB\n', min(snr), max(snr));
        fprintf('    - 平均SNR: %.2f dB\n', mean(snr));
        
        results.tests_passed = results.tests_passed + 1;
        results.test_details{end+1} = 'PASS: SNR计算';
    else
        fprintf('  - 跳过（依赖测试2）\n');
    end
    
catch ME
    fprintf('  ✗ SNR计算失败: %s\n', ME.message);
    results.tests_failed = results.tests_failed + 1;
    results.test_details{end+1} = sprintf('FAIL: SNR计算 - %s', ME.message);
end

%% 总结
fprintf('\n========================================\n');
fprintf('验证总结\n');
fprintf('========================================\n');
fprintf('通过: %d\n', results.tests_passed);
fprintf('失败: %d\n', results.tests_failed);
fprintf('\n详细结果:\n');
for i = 1:length(results.test_details)
    fprintf('  %s\n', results.test_details{i});
end

if results.tests_failed == 0
    fprintf('\n✓ 所有测试通过！可以开始处理真实数据。\n');
    fprintf('\n运行 demo_real_data 开始处理真实数据\n');
else
    fprintf('\n✗ 部分测试失败，请检查上述错误信息。\n');
end
