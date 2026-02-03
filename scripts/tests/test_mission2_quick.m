% test_mission2_quick.m - Mission 2 更快的验证（降低部分耗时项）
%
% 用法:
%   test_mission2_quick

config = default_config();

% 尽量减少演示合成数据规模（若配置项存在则调整；不存在则保持默认）
if isfield(config, 'mission2') && isfield(config.mission2, 'n_trials')
    config.mission2.n_trials = min(config.mission2.n_trials, 30);
end

results = process_mission2('demo', config, ...
    'PlotResults', false, ...
    'SaveResults', false, ...
    'Verbose', true);

assert(isfield(results, 'aef_convergence') && isfield(results.aef_convergence, 'min_trials'), 'Missing aef_convergence');
assert(isfield(results, 'assr_convergence') && isfield(results.assr_convergence, 'min_trials'), 'Missing assr_convergence');

fprintf('test_mission2_quick: PASS\n');

