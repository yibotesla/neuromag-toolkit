% demo_real_data.m - 真实OPM-MEG数据处理演示脚本
%
% 用法:
%   demo_real_data
%
% 说明:
%   本脚本演示如何使用完整的OPM预处理流程处理真实数据：
%   - Mission1: 处理干模数据，验证17Hz信号检测和降噪效果
%   - Mission2: 处理人类听觉数据，提取AEF和ASSR响应
%
% 数据位置:
%   真实数据存放在 config.paths.data_root 指定的路径
%   默认: Y:\Yibo\Tsinghua_homework
%
% 前置条件:
%   1. 确保数据路径可访问
%   2. 如需FieldTrip功能，确保FieldTrip路径正确
%   3. 建议先运行 addpath(genpath(pwd)) 添加项目路径

%% 初始化
clear;
close all;
clc;

fprintf('=== OPM-MEG 真实数据处理演示 ===\n\n');

% 添加项目路径（如果需要）
if ~exist('default_config', 'file')
    this_file = mfilename('fullpath');
    project_root = fileparts(fileparts(fileparts(this_file)));
    addpath(genpath(project_root));
    fprintf('已添加项目路径: %s\n', project_root);
end

% 加载配置
config = default_config();

% 启用真实数据处理模式
config.opm_preprocessing.use_real_data = true;

% 检查数据路径
data_root = config.paths.data_root;
if ~exist(data_root, 'dir')
    error('数据路径不存在: %s\n请修改 config.paths.data_root', data_root);
end
fprintf('数据路径: %s\n\n', data_root);

%% 选择演示模式
fprintf('请选择演示模式:\n');
fprintf('  1 - Mission1: 干模数据处理（17Hz信号检测）\n');
fprintf('  2 - Mission2: 人类听觉数据处理（AEF/ASSR提取）\n');
fprintf('  3 - 两者都运行\n');
fprintf('  0 - 退出\n');

choice = input('请输入选择 [1/2/3/0]: ');

if isempty(choice) || choice == 0
    fprintf('已退出演示\n');
    return;
end

run_mission1 = (choice == 1 || choice == 3);
run_mission2 = (choice == 2 || choice == 3);

%% Mission1: 干模数据处理
if run_mission1
    fprintf('\n========================================\n');
    fprintf('Mission1: 干模数据处理\n');
    fprintf('========================================\n\n');
    
    % 列出Mission1数据文件
    mission1_dir = fullfile(data_root, config.paths.mission1_dir);
    lvm_files = dir(fullfile(mission1_dir, 'data_*.lvm'));
    
    if isempty(lvm_files)
        fprintf('警告: Mission1目录下未找到数据文件\n');
    else
        fprintf('找到 %d 个数据文件:\n', length(lvm_files));
        for i = 1:min(5, length(lvm_files))
            fprintf('  %s\n', lvm_files(i).name);
        end
        if length(lvm_files) > 5
            fprintf('  ... 及其他 %d 个文件\n', length(lvm_files) - 5);
        end
        
        % 选择要处理的文件
        fprintf('\n选择要处理的文件:\n');
        fprintf('  0 - 处理第一个文件 (data_1.lvm)\n');
        fprintf('  1-10 - 处理指定编号的文件\n');
        fprintf('  -1 - 跳过Mission1\n');
        
        file_choice = input('请输入选择: ');
        
        if isempty(file_choice) || file_choice == 0
            file_choice = 1;
        end
        
        if file_choice > 0 && file_choice <= length(lvm_files)
            % 查找对应的文件
            target_file = sprintf('data_%d.lvm', file_choice);
            file_idx = find(strcmp({lvm_files.name}, target_file), 1);
            
            if isempty(file_idx)
                % 如果精确匹配失败，使用索引
                file_idx = min(file_choice, length(lvm_files));
            end
            
            file_path = fullfile(mission1_dir, lvm_files(file_idx).name);
            fprintf('\n处理文件: %s\n', lvm_files(file_idx).name);
            
            % 输出目录
            out_dir = fullfile('outputs', 'mission1_real');
            if ~exist(out_dir, 'dir')
                mkdir(out_dir);
            end
            
            % 运行Mission1处理
            try
                tic;
                results_m1 = process_mission1(file_path, config, ...
                    'PlotResults', true, ...
                    'SaveResults', true, ...
                    'OutputDir', out_dir, ...
                    'Verbose', true, ...
                    'UseRealDataProcessing', true);
                elapsed = toc;
                
                fprintf('\n=== Mission1 处理完成 ===\n');
                fprintf('处理时间: %.2f 秒\n', elapsed);
                fprintf('结果保存到: %s\n', out_dir);
                
                % 显示关键指标
                fprintf('\n关键指标:\n');
                fprintf('  原始SNR (17Hz): %.2f dB\n', mean(results_m1.snr_raw));
                fprintf('  滤波后SNR (17Hz): %.2f dB\n', mean(results_m1.snr_filtered));
                fprintf('  SNR提升: %.2f dB\n', mean(results_m1.snr_filtered - results_m1.snr_raw));
                fprintf('  噪声降低: %.1f%%\n', mean(results_m1.noise_reduction));
                fprintf('  检测到17Hz峰值的通道: %d/%d\n', ...
                    sum(results_m1.peak_detected), length(results_m1.peak_detected));
                
            catch ME
                fprintf('Mission1处理失败: %s\n', ME.message);
                fprintf('错误位置: %s (行 %d)\n', ME.stack(1).name, ME.stack(1).line);
            end
        end
    end
end

%% Mission2: 人类听觉数据处理
if run_mission2
    fprintf('\n========================================\n');
    fprintf('Mission2: 人类听觉数据处理\n');
    fprintf('========================================\n\n');
    
    % 列出Mission2数据文件
    mission2_dir = fullfile(data_root, config.paths.mission2_dir);
    lvm_files = dir(fullfile(mission2_dir, 'data_*.lvm'));
    
    if isempty(lvm_files)
        fprintf('警告: Mission2目录下未找到数据文件\n');
    else
        fprintf('找到 %d 个数据文件:\n', length(lvm_files));
        for i = 1:length(lvm_files)
            fprintf('  %s\n', lvm_files(i).name);
        end
        
        % 使用第一个文件
        file_path = fullfile(mission2_dir, lvm_files(1).name);
        fprintf('\n处理文件: %s\n', lvm_files(1).name);
        
        % 输出目录
        out_dir = fullfile('outputs', 'mission2_real');
        if ~exist(out_dir, 'dir')
            mkdir(out_dir);
        end
        
        % 配置数据时长（可选裁剪）
        fprintf('\n数据处理选项:\n');
        fprintf('  0 - 使用全部数据\n');
        fprintf('  N - 使用前N秒数据（建议: 60-300）\n');
        
        duration_choice = input('请输入选择 [默认300]: ');
        if isempty(duration_choice)
            duration_choice = 300;
        end
        
        if duration_choice > 0
            config.mission2.data_duration = duration_choice;
        else
            config.mission2.data_duration = inf;
        end
        
        % 运行Mission2处理
        try
            tic;
            results_m2 = process_mission2(file_path, config, ...
                'PlotResults', true, ...
                'SaveResults', true, ...
                'OutputDir', out_dir, ...
                'Verbose', true, ...
                'UseRealDataProcessing', true);
            elapsed = toc;
            
            fprintf('\n=== Mission2 处理完成 ===\n');
            fprintf('处理时间: %.2f 秒\n', elapsed);
            fprintf('结果保存到: %s\n', out_dir);
            
            % 显示关键指标
            fprintf('\n关键指标:\n');
            fprintf('  检测到的触发数: %d\n', length(results_m2.trigger_indices));
            fprintf('  AEF试次数: %d\n', results_m2.aef_trials.get_n_trials());
            fprintf('  ASSR试次数: %d\n', results_m2.assr_trials.get_n_trials());
            fprintf('  AEF收敛所需最少试次: %d\n', results_m2.aef_convergence.min_trials);
            fprintf('  ASSR收敛所需最少试次: %d\n', results_m2.assr_convergence.min_trials);
            fprintf('  噪声降低: %.1f%%\n', mean(results_m2.noise_reduction));
            
        catch ME
            fprintf('Mission2处理失败: %s\n', ME.message);
            fprintf('错误位置: %s (行 %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
end

%% 总结
fprintf('\n========================================\n');
fprintf('演示完成\n');
fprintf('========================================\n');
fprintf('\n输出目录:\n');
if run_mission1
    fprintf('  Mission1: outputs/mission1_real/\n');
end
if run_mission2
    fprintf('  Mission2: outputs/mission2_real/\n');
end
fprintf('\n如需调整处理参数，请修改 default_config.m 或在调用时传入自定义配置\n');
