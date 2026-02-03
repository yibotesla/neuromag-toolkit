% verify_setup.m - 项目结构与核心数据结构快速验证（可选）
%
% 用法:
%   verify_setup
%
% 说明:
% - 会自动定位项目根目录并 addpath 必要模块
% - 检查关键目录存在、配置可加载、核心数据结构可用

fprintf('=== MEG Signal Processing System - Setup Verification ===\n\n');

% 尽量从脚本位置定位根目录（scripts/verification/verify_setup.m -> 根目录）
this_file = mfilename('fullpath');
if isempty(this_file)
    root_dir = pwd;
else
    root_dir = fileparts(fileparts(fileparts(this_file)));
end

% Add paths（按需添加，避免无差别 genpath 造成路径污染）
addpath(fullfile(root_dir, 'utils'));
addpath(fullfile(root_dir, 'data_loader'));
addpath(fullfile(root_dir, 'preprocessor'));
addpath(fullfile(root_dir, 'denoiser'));
addpath(fullfile(root_dir, 'filter'));
addpath(fullfile(root_dir, 'analyzer'));
addpath(fullfile(root_dir, 'visualizer'));

fprintf('1. Checking directory structure...\n');
dirs = { ...
    'data_loader', 'preprocessor', 'denoiser', 'filter', ...
    'analyzer', 'visualizer', 'utils', ...
    fullfile('tests', 'unit'), fullfile('tests', 'property'), fullfile('tests', 'integration'), ...
    'docs', 'outputs', 'scripts' ...
    };

all_exist = true;
for i = 1:length(dirs)
    d = fullfile(root_dir, dirs{i});
    if exist(d, 'dir') == 7
        fprintf('   ✓ %s\n', dirs{i});
    else
        fprintf('   ✗ %s (MISSING)\n', dirs{i});
        all_exist = false;
    end
end

fprintf('\n2. Checking configuration file...\n');
cfg_path = fullfile(root_dir, 'config_template.m');
if exist(cfg_path, 'file') == 2
    fprintf('   ✓ config_template.m\n');
    try
        config = config_template(); %#ok<NASGU>
        fprintf('   ✓ Configuration loads successfully\n');
    catch ME
        fprintf('   ✗ Error loading configuration: %s\n', ME.message);
        all_exist = false;
    end
else
    fprintf('   ✗ config_template.m (MISSING)\n');
    all_exist = false;
end

fprintf('\n3. Testing data structures...\n');

% Test MEGData
try
    meg_data = MEGData();
    meg_data = meg_data.set_channel_labels();
    assert(length(meg_data.channel_labels) == 64, 'MEGData should have 64 channel labels');
    assert(strcmp(meg_data.channel_labels{1}, 'MEG001'), 'First label should be MEG001');
    fprintf('   ✓ MEGData class works correctly\n');
catch ME
    fprintf('   ✗ MEGData error: %s\n', ME.message);
    all_exist = false;
end

% Test ProcessedData
try
    proc_data = ProcessedData();
    proc_data = proc_data.add_processing_step('Test step');
    assert(length(proc_data.processing_log) == 1, 'Processing log should have 1 entry');
    fprintf('   ✓ ProcessedData class works correctly\n');
catch ME
    fprintf('   ✗ ProcessedData error: %s\n', ME.message);
    all_exist = false;
end

% Test TrialData
try
    trial_data = TrialData();
    assert(trial_data.get_n_trials() == 0, 'Empty TrialData should have 0 trials');
    trial_data.trials = rand(64, 100, 50);
    assert(trial_data.get_n_trials() == 50, 'TrialData should have 50 trials');
    assert(trial_data.get_n_channels() == 64, 'TrialData should have 64 channels');
    fprintf('   ✓ TrialData class works correctly\n');
catch ME
    fprintf('   ✗ TrialData error: %s\n', ME.message);
    all_exist = false;
end

% Test AnalysisResults
try
    results = AnalysisResults();
    results = results.set_psd(0:0.1:100, rand(1, 1001));
    results = results.set_snr(17, 15.5);
    results = results.set_convergence(10:10:100, rand(1, 10));
    assert(results.snr.frequency == 17, 'SNR frequency should be 17');
    fprintf('   ✓ AnalysisResults class works correctly\n');
catch ME
    fprintf('   ✗ AnalysisResults error: %s\n', ME.message);
    all_exist = false;
end

fprintf('\n=== Verification Complete ===\n');
if all_exist
    fprintf('✓ All checks passed! Project setup is complete.\n');
else
    fprintf('✗ Some checks failed. Please review the errors above.\n');
end

