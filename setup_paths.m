function setup_paths()
%SETUP_PATHS 正确设置项目路径（避免 FieldTrip 冲突）
%
% 用法:
%   setup_paths()
%
% 说明:
%   添加项目所有模块到 MATLAB 路径，但不包含 FieldTrip 子目录。
%   FieldTrip 应该单独初始化（使用 fieldtrip_integration('init', path)）。

% 获取项目根目录
project_root = fileparts(mfilename('fullpath'));

% 添加主目录
addpath(project_root);

% 添加各模块目录（不使用 genpath 避免冲突）
modules = {
    'analyzer'
    'data_loader'
    'denoiser'
    'filter'
    'preprocessor'
    'utils'
    'visualizer'
    'scripts/demos'
    'scripts/tests'
    'scripts/verification'
    'tests/unit'
    'tests/integration'
    'tests/property'
};

for i = 1:length(modules)
    module_path = fullfile(project_root, modules{i});
    if exist(module_path, 'dir')
        addpath(module_path);
    end
end

fprintf('项目路径设置完成。\n');
fprintf('如需使用 FieldTrip，请运行:\n');
fprintf('  config = default_config();\n');
fprintf('  fieldtrip_integration(''init'', config.paths.fieldtrip_path);\n');

end
