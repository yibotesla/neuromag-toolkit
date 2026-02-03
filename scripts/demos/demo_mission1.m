% demo_mission1.m - Mission 1 演示脚本（生成 outputs/mission1/ 下的示例输出）
%
% 用法:
%   demo_mission1
%
% 说明:
% - 使用合成数据（process_mission1('demo', ...)）运行完整流程
% - 保存主流程输出（mission1_results.*）并额外生成通道级统计与频谱对比图

% 建议：确保已 addpath(genpath(pwd)) 或将项目加入 MATLAB Path
config = default_config();

out_dir = fullfile('outputs', 'mission1');
if exist(out_dir, 'dir') ~= 7
    mkdir(out_dir);
end

% 运行主流程（使用合成数据）
results = process_mission1('demo', config, ...
    'PlotResults', true, ...
    'SaveResults', true, ...
    'OutputDir', out_dir, ...
    'Verbose', true);

%% 额外输出1：通道级 SNR 与峰值检测统计
try
    snr_raw = results.snr_raw(:);
    snr_filt = results.snr_filtered(:);
    peak_detected = results.peak_detected(:);

    fig = figure('Name', 'Mission 1 - Channel Analysis', 'Position', [120, 120, 1200, 500]);
    tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % SNR per channel
    nexttile;
    bar([snr_raw, snr_filt], 'grouped');
    xlabel('Channel');
    ylabel('SNR (dB)');
    title('SNR at 17Hz (Per Channel)');
    legend({'Raw', 'Filtered'}, 'Location', 'northeast');
    grid on;

    % Peak detection summary
    nexttile;
    bar(double(peak_detected));
    ylim([0, 1.2]);
    xlabel('Channel');
    ylabel('Detected (0/1)');
    title('17Hz Peak Detected (Per Channel)');
    grid on;

    save_figures(fullfile(out_dir, 'channel_analysis'), fig);
catch ME
    warning('demo_mission1:channel_analysis_failed', ...
        '通道级统计图生成失败: %s', ME.message);
end

%% 额外输出2：最佳通道频谱对比（Raw vs Filtered）
try
    % 选择滤波后 SNR 最高的通道作为“最佳通道”
    [~, best_ch] = max(results.snr_filtered(:));

    f_raw = results.psd_raw.frequencies;
    psd_raw = results.psd_raw.power(best_ch, :);
    f_filt = results.psd_filtered.frequencies;
    psd_filt = results.psd_filtered.power(best_ch, :);

    fig = figure('Name', 'Mission 1 - Spectral Comparison (Best Channel)', ...
        'Position', [150, 150, 900, 500]);
    plot(f_raw, 10*log10(psd_raw), 'LineWidth', 1.5);
    hold on;
    plot(f_filt, 10*log10(psd_filt), 'LineWidth', 1.5);
    xlim([0, 50]);
    xlabel('Frequency (Hz)');
    ylabel('Power (dB)');
    title(sprintf('Best Channel Spectral Comparison (Ch %d)', best_ch));
    legend({'Raw (Despiked)', 'Filtered (HFC)'}, 'Location', 'northeast');
    grid on;
    hold off;

    save_figures(fullfile(out_dir, 'spectral_comparison'), fig);
catch ME
    warning('demo_mission1:spectral_comparison_failed', ...
        '频谱对比图生成失败: %s', ME.message);
end

fprintf('demo_mission1 完成。输出目录: %s\n', out_dir);

