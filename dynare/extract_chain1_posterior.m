%% extract_chain1_posterior.m
% Extracts posterior means + standard deviations from the L1.3a chain 1
% (au_pac_bayesian/metropolis/au_pac_bayesian_mh1_blck1.mat) for comparison
% with the partial-L2 OLS estimates and the cached round12 baseline.
%
% Output:
%   - stdout: table of posterior summaries
%   - data/l13a_chain1_posterior.mat: struct with names + posterior moments

clear; clc;
fprintf('=== Extracting L1.3a chain 1 posterior ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

% Load chain 1 directly
f_chain = fullfile(projectdir, 'dynare', 'au_pac_bayesian', ...
    'metropolis', 'au_pac_bayesian_mh1_blck1.mat');
assert(isfile(f_chain), 'Chain 1 file missing: %s', f_chain);
C = load(f_chain);
fprintf('Loaded chain 1: fields = ');
disp(fieldnames(C)');

% Chain matrix x2 (Dynare convention): rows = draws, cols = params
if isfield(C, 'x2')
    X = C.x2;
elseif isfield(C, 'X')
    X = C.X;
else
    error('Could not find chain matrix in mh1_blck1.mat');
end

[ndraws, nparam] = size(X);
fprintf('Chain dimensions: %d draws x %d params\n', ndraws, nparam);

% Param name lookup -- from metropolis.log + L1.3a estimated_params order.
% Order matches what Dynare estimation block writes (alphabetical inside
% each prior_pdf category? or as declared?  Use the order from
% estimated_params block declaration.)
%
% The estimated_params block has:
%   1   b0_pQ        (beta)
%   2   b1_pQ        (beta)
%   3   b2_pQ        (normal)
%   4   b0_c         (beta)
%   5   b1_c         (beta)
%   6   b2_c         (normal)
%   7   b3_c         (normal)
%   8   b0_ib        (beta)
%   9   b1_ib        (beta)
%   10  b3_ib        (normal)
%   11  b0_ih        (beta)
%   12  b1_ih        (beta)
%   13  b3_ih        (normal)
%   14  b0_n         (beta)
%   15  b1_n         (beta)
%   16  b5_n         (normal)
%   17  lambda_w     (beta)
%   18  gamma_w      (beta)
%   19  kappa_w      (normal)
%   20  alpha_pc     (beta)
%   21  kappa_pi     (normal)
%   22  lambda_pi    (beta)
%   23  a_pQ_w       (normal)
%   24  alpha_pc_lag (normal)
%   25  b_ECM_pc     (beta)
%   26  b_PAC_c      (normal)  <- L1.3a NEW
%   27  stderr eps_q
%   28  stderr eps_i
%   29  stderr eps_pi
%   30  stderr eps_c
%   31  stderr eps_ib
%   32  stderr eps_ih
%   33  stderr eps_n
%   34  stderr eps_w
%   35  stderr eps_10y
% Dynare stores chain matrix x2 with SHOCK STDERRS FIRST, then deep params,
% NOT in the order they appear in the estimated_params block.
% Verified by matching chain column means to the mode values in
% /tmp/l13a_mcmc.out RESULTS FROM POSTERIOR ESTIMATION section.
param_names = { ...
    'stderr_eps_q', 'stderr_eps_i', 'stderr_eps_pi', ...
    'stderr_eps_c', 'stderr_eps_ib', 'stderr_eps_ih', ...
    'stderr_eps_n', 'stderr_eps_w', 'stderr_eps_10y', ...
    'b0_pQ', 'b1_pQ', 'b2_pQ', ...
    'b0_c', 'b1_c', 'b2_c', 'b3_c', ...
    'b0_ib', 'b1_ib', 'b3_ib', ...
    'b0_ih', 'b1_ih', 'b3_ih', ...
    'b0_n', 'b1_n', 'b5_n', ...
    'lambda_w', 'gamma_w', 'kappa_w', ...
    'alpha_pc', 'kappa_pi', 'lambda_pi', 'a_pQ_w', ...
    'alpha_pc_lag', 'b_ECM_pc', 'b_PAC_c'};

assert(length(param_names) == nparam, ...
    'Param name list length (%d) ~= chain dimension (%d)', ...
    length(param_names), nparam);

% Posterior summaries
post_mean  = mean(X, 1)';
post_sd    = std(X, 0, 1)';
post_med   = median(X, 1)';
% Quantile via sort (avoid Statistics Toolbox dependency)
Xs = sort(X, 1);
i05 = max(1, round(0.05 * ndraws));
i95 = min(ndraws, round(0.95 * ndraws));
post_p05 = Xs(i05, :)';
post_p95 = Xs(i95, :)';

% Print table
fprintf('\n%-15s %10s %10s %10s %10s\n', 'Parameter', 'mean', 'sd', 'q5', 'q95');
fprintf('%-15s %10s %10s %10s %10s\n', '---------', '----', '--', '--', '---');
for j = 1:nparam
    fprintf('%-15s %10.4f %10.4f %10.4f %10.4f\n', param_names{j}, ...
        post_mean(j), post_sd(j), post_p05(j), post_p95(j));
end

% Save
out = struct();
out.param_names = param_names;
out.post_mean = post_mean;
out.post_sd = post_sd;
out.post_median = post_med;
out.post_q05 = post_p05;
out.post_q95 = post_p95;
out.ndraws = ndraws;
out.note = 'L1.3a chain 1 only (chain 2 killed at 1.3 hr in); 20k draws, 44% acceptance';
out.source = f_chain;
save(fullfile(projectdir, 'data', 'l13a_chain1_posterior.mat'), '-struct', 'out');
fprintf('\nSaved data/l13a_chain1_posterior.mat\n');
