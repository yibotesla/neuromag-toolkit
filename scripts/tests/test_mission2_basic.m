% test_mission2_basic.m - Mission 2 基础快速验证（不生成图/不写文件）
%
% 用法:
%   test_mission2_basic

config = default_config();

results = process_mission2('demo', config, ...
    'PlotResults', false, ...
    'SaveResults', false, ...
    'Verbose', true);

assert(isfield(results, 'aef_trials') && isa(results.aef_trials, 'TrialData'), 'Missing aef_trials');
assert(isfield(results, 'assr_trials') && isa(results.assr_trials, 'TrialData'), 'Missing assr_trials');
assert(isfield(results, 'aef_grand_average') && ~isempty(results.aef_grand_average), 'Missing aef_grand_average');
assert(isfield(results, 'assr_grand_average') && ~isempty(results.assr_grand_average), 'Missing assr_grand_average');
assert(isfield(results, 'trigger_indices') && ~isempty(results.trigger_indices), 'Missing trigger_indices');

fprintf('test_mission2_basic: PASS\n');

