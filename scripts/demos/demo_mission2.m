% demo_mission2.m - Mission 2 演示脚本（生成 outputs/mission2/ 下的示例输出）
%
% 用法:
%   demo_mission2
%
% 说明:
% - 使用合成数据（process_mission2('demo', ...)）运行完整流程
% - 保存主流程输出（mission2_results.*）并额外生成试次示例与通道级统计图

% 建议：确保已 addpath(genpath(pwd)) 或将项目加入 MATLAB Path
config = default_config();

out_dir = fullfile('outputs', 'mission2');
if exist(out_dir, 'dir') ~= 7
    mkdir(out_dir);
end

% 运行主流程（使用合成数据）
results = process_mission2('demo', config, ...
    'PlotResults', true, ...
    'SaveResults', true, ...
    'OutputDir', out_dir, ...
    'Verbose', true);

%% 额外输出1：试次示例（AEF/ASSR）
try
    fig = figure('Name', 'Mission 2 - Trial Examples', 'Position', [120, 120, 1400, 600]);
    tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

    % AEF trials: 选取单通道的前若干试次
    nexttile;
    aef_trials = results.aef_trials.trials;
    aef_t = results.aef_trials.trial_times;
    n_show = min(10, size(aef_trials, 3));
    ch = 1;
    data_plot = squeeze(aef_trials(ch, :, 1:n_show)); % N_samples × N_show
    plot_time_series(aef_t, data_plot', ...
        'Title', sprintf('AEF Trials (Ch %d, First %d)', ch, n_show), ...
        'XLabel', 'Time (s)', ...
        'YLabel', 'Amplitude (T)', ...
        'Figure', fig);
    xline(0, 'r--', 'LineWidth', 2, 'Label', 'Trigger');
    grid on;

    % ASSR trials
    nexttile;
    assr_trials = results.assr_trials.trials;
    assr_t = results.assr_trials.trial_times;
    n_show = min(10, size(assr_trials, 3));
    ch = 1;
    data_plot = squeeze(assr_trials(ch, :, 1:n_show));
    plot_time_series(assr_t, data_plot', ...
        'Title', sprintf('ASSR Trials (Ch %d, First %d)', ch, n_show), ...
        'XLabel', 'Time (s)', ...
        'YLabel', 'Amplitude (T)', ...
        'Figure', fig);
    xline(0, 'r--', 'LineWidth', 2, 'Label', 'Trigger');
    grid on;

    save_figures(fullfile(out_dir, 'mission2_trial_examples'), fig);
catch ME
    warning('demo_mission2:trial_examples_failed', ...
        '试次示例图生成失败: %s', ME.message);
end

%% 额外输出2：通道级统计（简单幅度指标）
try
    aef_ga = results.aef_grand_average;
    assr_ga = results.assr_grand_average;
    aef_t = results.aef_trials.trial_times(:);
    assr_t = results.assr_trials.trial_times(:);

    % 取 trigger 后窗口内 RMS 作为通道级指标（示例用途）
    aef_win = aef_t >= 0 & aef_t <= min(0.3, max(aef_t));
    assr_win = assr_t >= 0 & assr_t <= min(0.3, max(assr_t));
    aef_rms = sqrt(mean(aef_ga(:, aef_win).^2, 2));
    assr_rms = sqrt(mean(assr_ga(:, assr_win).^2, 2));

    fig = figure('Name', 'Mission 2 - Channel Analysis', 'Position', [150, 150, 1200, 500]);
    tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

    nexttile;
    bar(aef_rms);
    xlabel('Channel');
    ylabel('RMS (T)');
    title('AEF Grand Average RMS (0~0.3s)');
    grid on;

    nexttile;
    bar(assr_rms);
    xlabel('Channel');
    ylabel('RMS (T)');
    title('ASSR Grand Average RMS (0~0.3s)');
    grid on;

    save_figures(fullfile(out_dir, 'mission2_channel_analysis'), fig);
catch ME
    warning('demo_mission2:channel_analysis_failed', ...
        '通道级统计图生成失败: %s', ME.message);
end

fprintf('demo_mission2 完成。输出目录: %s\n', out_dir);

