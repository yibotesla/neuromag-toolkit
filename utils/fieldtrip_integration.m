function varargout = fieldtrip_integration(operation, varargin)
%FIELDTRIP_INTEGRATION FieldTrip工具箱集成模块
%
% 此函数提供与FieldTrip MEG分析工具箱的完整集成，包括：
%   - FieldTrip可用性检测
%   - 数据格式转换（MEGData/TrialData ↔ FieldTrip结构）
%   - grad传感器结构构建
%   - 辅助数据文件加载
%
% 语法:
%   [available, version] = fieldtrip_integration('check')
%   fieldtrip_integration('init', fieldtrip_path)
%   ft_data = fieldtrip_integration('to_fieldtrip', meg_data, config)
%   ft_data = fieldtrip_integration('trials_to_fieldtrip', trial_data, config)
%   meg_data = fieldtrip_integration('from_fieldtrip', ft_data, config)
%   grad = fieldtrip_integration('build_grad', config)
%   grad = fieldtrip_integration('build_dual_axis_grad', config)
%   layout = fieldtrip_integration('load_layout', config)
%   aux_data = fieldtrip_integration('load_auxiliary', filename, config)
%
% 操作:
%   'check'                - 检测FieldTrip是否可用，返回[available, version]
%   'init'                 - 初始化FieldTrip（添加路径并运行ft_defaults）
%   'to_fieldtrip'         - 将MEGData转换为FieldTrip数据结构
%   'trials_to_fieldtrip'  - 将TrialData转换为FieldTrip试次数据结构
%   'from_fieldtrip'       - 将FieldTrip数据结构转换回MEGData
%   'build_grad'           - 构建单轴grad传感器结构
%   'build_dual_axis_grad' - 构建双轴grad传感器结构
%   'load_layout'          - 加载传感器布局文件
%   'load_auxiliary'       - 加载辅助数据文件
%
% 示例:
%   % 检测FieldTrip
%   [available, ver] = fieldtrip_integration('check');
%   
%   % 初始化FieldTrip
%   config = default_config();
%   fieldtrip_integration('init', config.paths.fieldtrip_path);
%   
%   % 转换数据
%   ft_data = fieldtrip_integration('to_fieldtrip', meg_data, config);
%
% 另见: MEGData, TrialData, default_config

% 验证操作参数
if nargin < 1
    error('MEG:FieldTrip:InvalidOperation', ...
        'Operation parameter is required. Use ''check'', ''init'', etc.');
end

% 分发到对应的子函数
switch lower(operation)
    case 'check'
        [varargout{1:nargout}] = check_fieldtrip();
        
    case 'init'
        if nargin < 2
            error('MEG:FieldTrip:MissingPath', ...
                'FieldTrip path is required for ''init'' operation.');
        end
        init_fieldtrip(varargin{1});
        
    case 'to_fieldtrip'
        if nargin < 3
            error('MEG:FieldTrip:MissingArgs', ...
                '''to_fieldtrip'' requires meg_data and config arguments.');
        end
        varargout{1} = megdata_to_fieldtrip(varargin{1}, varargin{2});
        
    case 'trials_to_fieldtrip'
        if nargin < 3
            error('MEG:FieldTrip:MissingArgs', ...
                '''trials_to_fieldtrip'' requires trial_data and config arguments.');
        end
        varargout{1} = trialdata_to_fieldtrip(varargin{1}, varargin{2});
        
    case 'from_fieldtrip'
        if nargin < 3
            error('MEG:FieldTrip:MissingArgs', ...
                '''from_fieldtrip'' requires ft_data and config arguments.');
        end
        varargout{1} = fieldtrip_to_megdata(varargin{1}, varargin{2});
        
    case 'build_grad'
        if nargin < 2
            error('MEG:FieldTrip:MissingConfig', ...
                '''build_grad'' requires config argument.');
        end
        varargout{1} = build_grad_structure(varargin{1});
        
    case 'build_dual_axis_grad'
        if nargin < 2
            error('MEG:FieldTrip:MissingConfig', ...
                '''build_dual_axis_grad'' requires config argument.');
        end
        varargout{1} = build_dual_axis_grad(varargin{1});
        
    case 'load_layout'
        if nargin < 2
            error('MEG:FieldTrip:MissingConfig', ...
                '''load_layout'' requires config argument.');
        end
        varargout{1} = load_layout_file(varargin{1});
        
    case 'load_auxiliary'
        if nargin < 3
            error('MEG:FieldTrip:MissingArgs', ...
                '''load_auxiliary'' requires filename and config arguments.');
        end
        varargout{1} = load_auxiliary_file(varargin{1}, varargin{2});
        
    otherwise
        error('MEG:FieldTrip:UnknownOperation', ...
            'Unknown operation: %s. Valid operations: check, init, to_fieldtrip, from_fieldtrip, build_grad, load_layout, load_auxiliary', operation);
end

end

%% ========== 子函数实现 ==========

function [available, version] = check_fieldtrip()
%CHECK_FIELDTRIP 检测FieldTrip是否可用
%
% 返回:
%   available - 逻辑值，FieldTrip是否可用
%   version   - 字符串，FieldTrip版本（如果可用）

available = false;
version = '';

% 检查ft_defaults是否在路径中
if exist('ft_defaults', 'file') ~= 2
    return;
end

% 尝试获取版本信息
try
    % 调用ft_defaults确保FieldTrip正确初始化
    ft_defaults;
    available = true;
    
    % 尝试获取版本信息
    if exist('ft_version', 'file') == 2
        version = ft_version();
    else
        version = 'unknown';
    end
catch
    available = false;
    version = '';
end

end

function init_fieldtrip(fieldtrip_path)
%INIT_FIELDTRIP 初始化FieldTrip工具箱
%
% 输入:
%   fieldtrip_path - FieldTrip安装路径
%
% 说明:
%   使用FieldTrip官方推荐的初始化方式，只添加主目录，
%   然后调用ft_defaults让FieldTrip自动管理子目录。

% 验证路径
if isempty(fieldtrip_path)
    warning('MEG:FieldTrip:EmptyPath', ...
        'FieldTrip path is empty. FieldTrip will not be initialized.');
    return;
end

if ~exist(fieldtrip_path, 'dir')
    error('MEG:FieldTrip:PathNotFound', ...
        'FieldTrip path does not exist: %s', fieldtrip_path);
end

% 检查是否已经初始化
if exist('ft_defaults', 'file') == 2
    fprintf('FieldTrip已在路径中，跳过添加路径。\n');
else
    % 只添加FieldTrip主目录（官方推荐方式）
    addpath(fieldtrip_path);
    fprintf('已添加FieldTrip路径: %s\n', fieldtrip_path);
end

% 运行ft_defaults初始化（这会自动设置正确的子目录）
try
    ft_defaults;
    fprintf('FieldTrip初始化成功。\n');
catch ME
    error('MEG:FieldTrip:InitFailed', ...
        'Failed to initialize FieldTrip: %s', ME.message);
end

end

function ft_data = megdata_to_fieldtrip(meg_data, config)
%MEGDATA_TO_FIELDTRIP 将MEGData转换为FieldTrip数据结构
%
% 输入:
%   meg_data - MEGData对象
%   config   - 配置结构体
%
% 输出:
%   ft_data - FieldTrip兼容的数据结构

% 验证输入
if ~isa(meg_data, 'MEGData')
    error('MEG:FieldTrip:InvalidInput', ...
        'Input must be a MEGData object.');
end

% 检查FieldTrip是否可用
[available, ~] = check_fieldtrip();
if ~available
    error('MEG:FieldTrip:NotAvailable', ...
        'FieldTrip is not available. Please initialize it first.');
end

% 创建FieldTrip数据结构
ft_data = struct();

% 基本信息
ft_data.fsample = meg_data.fs;
ft_data.label = meg_data.channel_labels;

% 确保label是列向量
if size(ft_data.label, 1) == 1
    ft_data.label = ft_data.label';
end

% 时间轴
ft_data.time = {meg_data.time};

% 数据矩阵（FieldTrip格式：channels × samples）
ft_data.trial = {meg_data.meg_channels};

% 维度信息
ft_data.dimord = 'chan_time';

% 采样信息
ft_data.sampleinfo = [1, size(meg_data.meg_channels, 2)];

% 尝试添加grad结构
try
    ft_data.grad = build_grad_structure(config);
catch ME
    warning('MEG:FieldTrip:NoGrad', ...
        'Could not build grad structure: %s', ME.message);
end

% 配置信息
ft_data.cfg = struct();
ft_data.cfg.previous = [];
ft_data.cfg.version = [];

end

function ft_data = trialdata_to_fieldtrip(trial_data, config)
%TRIALDATA_TO_FIELDTRIP 将TrialData转换为FieldTrip试次数据结构
%
% 输入:
%   trial_data - TrialData对象
%   config     - 配置结构体
%
% 输出:
%   ft_data - FieldTrip兼容的试次数据结构

% 验证输入
if ~isa(trial_data, 'TrialData')
    error('MEG:FieldTrip:InvalidInput', ...
        'Input must be a TrialData object.');
end

% 检查FieldTrip是否可用
[available, ~] = check_fieldtrip();
if ~available
    error('MEG:FieldTrip:NotAvailable', ...
        'FieldTrip is not available. Please initialize it first.');
end

% 获取数据维度
n_channels = trial_data.get_n_channels();
n_trials = trial_data.get_n_trials();
n_samples = size(trial_data.trials, 2);

% 创建FieldTrip数据结构
ft_data = struct();

% 基本信息
ft_data.fsample = trial_data.fs;

% 生成通道标签
ft_data.label = cell(n_channels, 1);
for i = 1:n_channels
    ft_data.label{i} = sprintf('MEG%03d', i);
end

% 时间轴和试次数据
ft_data.time = cell(1, n_trials);
ft_data.trial = cell(1, n_trials);

for i = 1:n_trials
    ft_data.time{i} = trial_data.trial_times;
    ft_data.trial{i} = trial_data.trials(:, :, i);
end

% 维度信息
ft_data.dimord = 'rpt_chan_time';

% 采样信息
samples_per_trial = n_samples;
ft_data.sampleinfo = zeros(n_trials, 2);
for i = 1:n_trials
    ft_data.sampleinfo(i, :) = [(i-1)*samples_per_trial + 1, i*samples_per_trial];
end

% 事件时间（trigger偏移）
if ~isempty(trial_data.trigger_indices)
    ft_data.trialinfo = trial_data.trigger_indices(:);
end

% 尝试添加grad结构
try
    ft_data.grad = build_grad_structure(config);
catch ME
    warning('MEG:FieldTrip:NoGrad', ...
        'Could not build grad structure: %s', ME.message);
end

% 配置信息
ft_data.cfg = struct();
ft_data.cfg.trl = ft_data.sampleinfo;
ft_data.cfg.previous = [];

end

function meg_data = fieldtrip_to_megdata(ft_data, config)
%FIELDTRIP_TO_MEGDATA 将FieldTrip数据结构转换回MEGData
%
% 输入:
%   ft_data - FieldTrip数据结构
%   config  - 配置结构体
%
% 输出:
%   meg_data - MEGData对象

% 验证输入
if ~isstruct(ft_data)
    error('MEG:FieldTrip:InvalidInput', ...
        'Input must be a FieldTrip data structure.');
end

% 创建MEGData对象
meg_data = MEGData();

% 采样率
if isfield(ft_data, 'fsample')
    meg_data.fs = ft_data.fsample;
else
    meg_data.fs = config.data_loading.sampling_rate;
end

% 增益
meg_data.gain = config.data_loading.gain;

% 处理不同类型的FieldTrip数据
if isfield(ft_data, 'trial') && iscell(ft_data.trial)
    % 多试次数据 - 连接所有试次
    n_trials = length(ft_data.trial);
    
    if n_trials == 1
        % 单个试次或连续数据
        meg_data.meg_channels = ft_data.trial{1};
        meg_data.time = ft_data.time{1};
    else
        % 多试次 - 连接数据
        meg_data.meg_channels = cat(2, ft_data.trial{:});
        
        % 重建时间轴
        n_samples = size(meg_data.meg_channels, 2);
        meg_data.time = (0:n_samples-1) / meg_data.fs;
    end
elseif isfield(ft_data, 'avg')
    % 平均数据（来自ft_timelockanalysis）
    meg_data.meg_channels = ft_data.avg;
    meg_data.time = ft_data.time;
else
    error('MEG:FieldTrip:UnknownFormat', ...
        'Unknown FieldTrip data format.');
end

% 通道标签
if isfield(ft_data, 'label')
    n_labels = length(ft_data.label);
    meg_data.channel_labels = cell(n_labels, 1);
    for i = 1:n_labels
        meg_data.channel_labels{i} = ft_data.label{i};
    end
else
    meg_data = meg_data.set_channel_labels();
end

% 参考通道（如果可用）
if isfield(ft_data, 'ref_channels')
    meg_data.ref_channels = ft_data.ref_channels;
else
    meg_data.ref_channels = zeros(3, size(meg_data.meg_channels, 2));
end

% 刺激和触发信号（如果可用）
n_samples = size(meg_data.meg_channels, 2);
if isfield(ft_data, 'stimulus')
    meg_data.stimulus = ft_data.stimulus;
else
    meg_data.stimulus = zeros(1, n_samples);
end

if isfield(ft_data, 'trigger')
    meg_data.trigger = ft_data.trigger;
else
    meg_data.trigger = zeros(1, n_samples);
end

% 坏通道
if isfield(ft_data, 'cfg') && isfield(ft_data.cfg, 'badchannel')
    % 从标签转换为索引
    bad_labels = ft_data.cfg.badchannel;
    meg_data.bad_channels = find(ismember(meg_data.channel_labels, bad_labels));
else
    meg_data.bad_channels = [];
end

end

function grad = build_grad_structure(config)
%BUILD_GRAD_STRUCTURE 构建单轴grad传感器结构
%
% 输入:
%   config - 配置结构体
%
% 输出:
%   grad - FieldTrip兼容的grad结构

% 尝试从辅助文件加载grad
try
    grad_file = fullfile(config.paths.auxiliary_data, 'grad_transformed.mat');
    if exist(grad_file, 'file')
        loaded = load(grad_file);
        if isfield(loaded, 'grad_transformed')
            grad = loaded.grad_transformed;
            return;
        elseif isfield(loaded, 'grad')
            grad = loaded.grad;
            return;
        end
    end
catch
    % 继续使用默认构建
end

% 默认构建grad结构
n_channels = config.data_loading.n_meg_channels;  % 默认64

grad = struct();

% 通道标签
grad.label = cell(n_channels, 1);
for i = 1:n_channels
    grad.label{i} = sprintf('MEG%03d', i);
end

% 传感器位置（使用简化的球面布局）
% 假设传感器在半径为0.1m的球面上
grad.chanpos = zeros(n_channels, 3);
grad.chanori = zeros(n_channels, 3);
grad.coilpos = zeros(n_channels, 3);
grad.coilori = zeros(n_channels, 3);

% 获取layout_idx（如果可用）- 用于将物理传感器位置映射到数据通道
if isfield(config, 'opm_preprocessing') && isfield(config.opm_preprocessing, 'layout_idx')
    layout_idx = config.opm_preprocessing.layout_idx;
else
    layout_idx = 1:n_channels;
end

% 使用简化的8x8网格布局
radius = 0.1;  % 10 cm
for i = 1:n_channels
    % 使用layout_idx获取映射后的位置索引
    mapped_i = layout_idx(min(i, length(layout_idx)));
    
    % 计算网格位置（基于映射后的索引）
    row = floor((mapped_i-1) / 8) + 1;
    col = mod(mapped_i-1, 8) + 1;
    
    % 归一化到[-1, 1]范围
    theta = (col - 4.5) / 4 * pi/3;  % 方位角
    phi = (row - 4.5) / 4 * pi/4;    % 极角
    
    % 转换为笛卡尔坐标
    x = radius * sin(phi) * cos(theta);
    y = radius * sin(phi) * sin(theta);
    z = radius * cos(phi);
    
    grad.chanpos(i, :) = [x, y, z];
    grad.coilpos(i, :) = [x, y, z];
    
    % 方向指向球心（径向磁力计）
    grad.chanori(i, :) = -[x, y, z] / radius;
    grad.coilori(i, :) = -[x, y, z] / radius;
end

% 传感器类型（OPM磁力计）
grad.chantype = repmat({'megmag'}, n_channels, 1);
grad.chanunit = repmat({'T'}, n_channels, 1);

% 线圈到通道的映射（1:1映射）
grad.tra = eye(n_channels);

% 单位
grad.unit = 'm';

% 坐标系
grad.coordsys = 'ctf';

end

function grad = build_dual_axis_grad(config)
%BUILD_DUAL_AXIS_GRAD 构建双轴grad传感器结构
%
% 对于OPM-MEG双轴配置，每个物理传感器位置有两个测量方向（Y轴和Z轴）
%
% 输入:
%   config - 配置结构体
%
% 输出:
%   grad - FieldTrip兼容的双轴grad结构

% 尝试从辅助文件加载Y轴grad
try
    grad_y_file = fullfile(config.paths.auxiliary_data, 'grad_Y_transformed.mat');
    grad_z_file = fullfile(config.paths.auxiliary_data, 'grad_transformed.mat');
    
    if exist(grad_y_file, 'file') && exist(grad_z_file, 'file')
        loaded_y = load(grad_y_file);
        loaded_z = load(grad_z_file);
        
        % 合并Y轴和Z轴grad
        if isfield(loaded_y, 'grad_Y_transformed') && isfield(loaded_z, 'grad_transformed')
            grad_y = loaded_y.grad_Y_transformed;
            grad_z = loaded_z.grad_transformed;
            grad = merge_dual_axis_grad(grad_z, grad_y);
            return;
        end
    end
catch
    % 继续使用默认构建
end

% 默认构建双轴grad结构
n_sensors = 64;  % 物理传感器数量
n_channels = 128;  % 双轴通道数（64 × 2）

grad = struct();

% 通道标签（Z轴和Y轴交替）
grad.label = cell(n_channels, 1);
for i = 1:n_sensors
    grad.label{2*i-1} = sprintf('MEG%03d_Z', i);
    grad.label{2*i} = sprintf('MEG%03d_Y', i);
end

% 传感器位置
grad.chanpos = zeros(n_channels, 3);
grad.chanori = zeros(n_channels, 3);
grad.coilpos = zeros(n_channels, 3);
grad.coilori = zeros(n_channels, 3);

% 使用简化的8x8网格布局
radius = 0.1;  % 10 cm
depth_adjust = 0;

if isfield(config, 'opm_preprocessing') && isfield(config.opm_preprocessing, 'depth_adjustment')
    depth_adjust = config.opm_preprocessing.depth_adjustment / 1000;  % mm to m
end

for i = 1:n_sensors
    % 计算网格位置
    row = floor((i-1) / 8) + 1;
    col = mod(i-1, 8) + 1;
    
    % 归一化到[-1, 1]范围
    theta = (col - 4.5) / 4 * pi/3;  % 方位角
    phi = (row - 4.5) / 4 * pi/4;    % 极角
    
    % 转换为笛卡尔坐标（应用深度调整）
    r = radius + depth_adjust;
    x = r * sin(phi) * cos(theta);
    y = r * sin(phi) * sin(theta);
    z = r * cos(phi);
    
    pos = [x, y, z];
    
    % Z轴通道（径向方向）
    z_idx = 2*i - 1;
    grad.chanpos(z_idx, :) = pos;
    grad.coilpos(z_idx, :) = pos;
    grad.chanori(z_idx, :) = -pos / norm(pos);  % 指向球心
    grad.coilori(z_idx, :) = -pos / norm(pos);
    
    % Y轴通道（切向方向 - 垂直于径向）
    y_idx = 2*i;
    grad.chanpos(y_idx, :) = pos;
    grad.coilpos(y_idx, :) = pos;
    
    % 计算切向方向（与全局Y轴和径向的叉积）
    radial = pos / norm(pos);
    tangent = cross([0, 1, 0], radial);
    if norm(tangent) < 0.01
        tangent = cross([1, 0, 0], radial);
    end
    tangent = tangent / norm(tangent);
    
    grad.chanori(y_idx, :) = tangent;
    grad.coilori(y_idx, :) = tangent;
end

% 传感器类型（OPM磁力计）
grad.chantype = repmat({'megmag'}, n_channels, 1);
grad.chanunit = repmat({'T'}, n_channels, 1);

% 线圈到通道的映射（1:1映射）
grad.tra = eye(n_channels);

% 单位
grad.unit = 'm';

% 坐标系
grad.coordsys = 'ctf';

end

function grad = merge_dual_axis_grad(grad_z, grad_y)
%MERGE_DUAL_AXIS_GRAD 合并Z轴和Y轴grad结构
%
% 输入:
%   grad_z - Z轴grad结构
%   grad_y - Y轴grad结构
%
% 输出:
%   grad - 合并后的双轴grad结构

n_z = length(grad_z.label);
n_y = length(grad_y.label);
n_total = n_z + n_y;

grad = struct();

% 合并标签（Z轴在前，Y轴在后）
grad.label = cell(n_total, 1);
for i = 1:n_z
    grad.label{i} = [grad_z.label{i}, '_Z'];
end
for i = 1:n_y
    grad.label{n_z + i} = [grad_y.label{i}, '_Y'];
end

% 合并位置和方向
grad.chanpos = [grad_z.chanpos; grad_y.chanpos];
grad.chanori = [grad_z.chanori; grad_y.chanori];
grad.coilpos = [grad_z.coilpos; grad_y.coilpos];
grad.coilori = [grad_z.coilori; grad_y.coilori];

% 传感器类型
grad.chantype = [grad_z.chantype; grad_y.chantype];
grad.chanunit = [grad_z.chanunit; grad_y.chanunit];

% 转换矩阵
grad.tra = blkdiag(grad_z.tra, grad_y.tra);

% 单位和坐标系
grad.unit = grad_z.unit;
grad.coordsys = grad_z.coordsys;

end

function layout = load_layout_file(config)
%LOAD_LAYOUT_FILE 加载传感器布局文件
%
% 输入:
%   config - 配置结构体
%
% 输出:
%   layout - FieldTrip兼容的layout结构

% 尝试从辅助文件加载layout
layout_file = fullfile(config.paths.auxiliary_data, 'layout_zkzyopm.mat');

if exist(layout_file, 'file')
    loaded = load(layout_file);
    
    % 查找layout变量
    if isfield(loaded, 'layout')
        layout = loaded.layout;
        return;
    elseif isfield(loaded, 'lay')
        layout = loaded.lay;
        return;
    else
        % 尝试获取第一个结构体变量
        fields = fieldnames(loaded);
        for i = 1:length(fields)
            if isstruct(loaded.(fields{i})) && isfield(loaded.(fields{i}), 'pos')
                layout = loaded.(fields{i});
                return;
            end
        end
    end
end

% 如果无法加载，创建默认layout
warning('MEG:FieldTrip:NoLayout', ...
    'Could not load layout file: %s. Creating default layout.', layout_file);

layout = create_default_layout(config);

end

function layout = create_default_layout(config)
%CREATE_DEFAULT_LAYOUT 创建默认的传感器布局
%
% 输入:
%   config - 配置结构体
%
% 输出:
%   layout - 默认的layout结构

n_channels = config.data_loading.n_meg_channels;  % 默认64

layout = struct();

% 通道标签
layout.label = cell(n_channels, 1);
for i = 1:n_channels
    layout.label{i} = sprintf('MEG%03d', i);
end

% 2D位置（8x8网格）
layout.pos = zeros(n_channels, 2);
layout.width = zeros(n_channels, 1);
layout.height = zeros(n_channels, 1);

for i = 1:n_channels
    row = floor((i-1) / 8) + 1;
    col = mod(i-1, 8) + 1;
    
    % 归一化位置
    layout.pos(i, 1) = (col - 4.5) / 4;  % x
    layout.pos(i, 2) = (4.5 - row) / 4;  % y（翻转以便顶部为前）
    
    layout.width(i) = 0.1;
    layout.height(i) = 0.1;
end

% 轮廓（头部外轮廓）
theta = linspace(0, 2*pi, 100);
layout.outline = {[cos(theta)', sin(theta)']};

% 掩膜（用于topoplot）
layout.mask = {[cos(theta)', sin(theta)']};

end

function aux_data = load_auxiliary_file(filename, config)
%LOAD_AUXILIARY_FILE 加载辅助数据文件
%
% 输入:
%   filename - 文件名（不含路径）
%   config   - 配置结构体
%
% 输出:
%   aux_data - 加载的数据结构
%
% 常用辅助文件:
%   - 'data_temp30s.mat'      - FieldTrip数据模板
%   - 'layout_zkzyopm.mat'    - 传感器布局
%   - 'grad_transformed.mat'  - Z轴grad结构
%   - 'grad_Y_transformed.mat'- Y轴grad结构

% 构建完整路径
full_path = fullfile(config.paths.auxiliary_data, filename);

% 检查文件是否存在
if ~exist(full_path, 'file')
    error('MEG:FieldTrip:FileNotFound', ...
        'Auxiliary file not found: %s', full_path);
end

% 加载文件
try
    aux_data = load(full_path);
catch ME
    error('MEG:FieldTrip:LoadFailed', ...
        'Failed to load auxiliary file: %s\nError: %s', full_path, ME.message);
end

end
