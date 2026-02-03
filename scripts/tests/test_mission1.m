% test_mission1.m - Mission 1 快速验证脚本（不生成图/不写文件）
%
% 用法:
%   test_mission1

config = default_config();

results = process_mission1('demo', config, ...
    'PlotResults', false, ...
    'SaveResults', false, ...
    'Verbose', true);

% 基本断言（尽量轻量，便于快速运行）
assert(isfield(results, 'snr_raw') && ~isempty(results.snr_raw), 'Missing snr_raw');
assert(isfield(results, 'snr_filtered') && ~isempty(results.snr_filtered), 'Missing snr_filtered');
assert(isfield(results, 'psd_raw') && isfield(results.psd_raw, 'frequencies'), 'Missing psd_raw');
assert(isfield(results, 'psd_filtered') && isfield(results.psd_filtered, 'frequencies'), 'Missing psd_filtered');

fprintf('test_mission1: PASS\n');

