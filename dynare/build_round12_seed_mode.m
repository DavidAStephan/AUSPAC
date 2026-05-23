%% build_round12_seed_mode.m
% Construct a 36-parameter mode file by extending the pre-Round-1.2 baseline
% mode file (34 params) with b_HtM and stderr eps_wtH at their recent
% posterior values (from the failed-but-informative 2026-05-22 follow-up MCMC).
%
% This lets us run MCMC with mode_compute=0 + mode_file=this so the sampler
% explores around the baseline Phillips-curve mode while still letting b_HtM
% and stderr eps_wtH adapt around their recent posterior centres.

clear; clc;

baseline_path = 'au_pac_bayesian.cached_pre_round12_2026-05-22/Output/au_pac_bayesian_mode.mat';
out_path      = 'au_pac_bayesian_seed_mode.mat';

old = load(baseline_path);
n_old = length(old.xparam1);
fprintf('Baseline: %d params\n', n_old);
assert(n_old == 34, 'Expected 34 params in baseline mode file, got %d', n_old);

% Dynare xparam1 ordering: shock SDs first (in estimated_params order), then
% structural parameters (in estimated_params order). Therefore in the new
% 36-param vector:
%   1-9   = old 1-9   (stderr eps_q ... eps_10y, unchanged)
%   10    = stderr eps_wtH (NEW, last shock SD in the block)
%   11-26 = old 10-25 (b0_pQ ... b5_n)
%   27-35 = old 26-34 (lambda_w ... b_ECM_pc)
%   36    = b_HtM (NEW, last structural param)

% Centres for the two new params (from the 2026-05-22 follow-up MCMC posterior)
b_HtM_centre    = 0.1344;
eps_wtH_centre  = 1.18;
b_HtM_sd        = 0.075;
eps_wtH_sd      = 0.08;

% Build new xparam1 (36x1)
xparam1 = nan(36, 1);
xparam1(1:9)   = old.xparam1(1:9);
xparam1(10)    = eps_wtH_centre;
xparam1(11:35) = old.xparam1(10:34);
xparam1(36)    = b_HtM_centre;

% Build new hh (36x36): insert row+col at position 10 (eps_wtH) and at the
% end (b_HtM, position 36). Carry forward all baseline 34x34 entries with
% the appropriate index shift.
hh = zeros(36, 36);
old_idx_to_new = [1:9, 11:35];  % maps old indices 1..34 -> new indices 1..9,11..35
for i = 1:34
    for j = 1:34
        hh(old_idx_to_new(i), old_idx_to_new(j)) = old.hh(i, j);
    end
end
hh(10, 10) = 1 / (eps_wtH_sd^2);
hh(36, 36) = 1 / (b_HtM_sd^2);

fval = old.fval;

% Dynare names shock SDs by the bare eps name (e.g. 'eps_q'), NOT 'SE_eps_q'.
old_names = old.parameter_names;
parameter_names = cell(36, 1);
parameter_names(1:9)   = old_names(1:9);
parameter_names{10}    = 'eps_wtH';
parameter_names(11:35) = old_names(10:34);
parameter_names{36}    = 'b_HtM';

% Sanity print
fprintf('New xparam1 (length %d):\n', length(xparam1));
for i = 1:length(parameter_names)
    fprintf('  %2d  %-20s = %+.4f\n', i, parameter_names{i}, xparam1(i));
end
fprintf('hh size: %dx%d, condition: %.2e\n', size(hh,1), size(hh,2), cond(hh));
fprintf('fval (carried from baseline mode): %.4f\n', fval);

save(out_path, 'xparam1', 'hh', 'fval', 'parameter_names');
fprintf('\nWrote %s\n', out_path);
