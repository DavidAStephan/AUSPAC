%% estimate_consumption_pac_ols.m  --  partial L2 wp1044 consumption block
%
% Phase L2-pilot of the FR-BDF wp1044 replication (refactor/frbdf-replication-L2).
% Estimates the consumption PAC short-run equation via OLS in the spirit
% of wp1044 §3.5.1 Eq 35, treating the trend GDP growth as a fixed
% regressor rather than via the joint Bayesian Kalman filter.
%
% This is a partial-L2: it does iterative OLS on the consumption equation
% alone, matching wp1044's actual block-by-block estimation methodology
% (wp1044 §2.2 step 4), instead of the joint Bayesian MCMC used in L1.
%
% The L1.3a joint MCMC took 14 hours per run and was killed mid-run; this
% partial L2 takes ~10 seconds and gives directly-comparable coefficient
% estimates without the per-likelihood-eval Kalman cost.
%
% wp1044 Eq 35 in full reads:
%   Δc_t = β_0 (c*_{t-1} - c_{t-1}) + β_1 Δc_{t-1}
%        + PV²(y_H - ȳ)_{t|t-1}
%        + α_1 [PV(r_LH)_{t|t-1} - (PV(ī)_{t|t-1} - PV(π̄)_{t|t-1})]
%        + β_PAC Δȳ_{t-1}
%        + β_2 [Δ(log(W_H + TG_H) - p_C^VAT) - ỹ_t]
%        + β_3 (Δr_LH,t - (Δī_t - Δπ̄_t))
%        + β_4 δ_COVID
% The β_PAC term (boxed in TRENDS_COMPARISON.md §2.5) is what we focus on
% here.  We replace the PV terms with their lagged-data analogues for
% feasibility on a 10-obs dataset; that's an approximation but isolates
% the headline question: what does β_PAC look like estimated via OLS?
%
% Spec used here (simplified wp1044 Eq 35 for AU data):
%   Δc_t = β_0 (c*_{t-1} - c_{t-1})       % error-correction (approximated)
%        + β_1 Δc_{t-1}                    % lag
%        + β_2 i_au_{t-1}                  % real-rate proxy (i_au demeaned)
%        + β_3 yhat_au_t                   % output gap contemporaneous
%        + β_HtM (wt_H_real_gap_t - yhat_au_t)  % HtM channel (skipped for now;
%                                          % wt_H_real_gap not in obs file)
%        + β_PAC dy_bar_gap_{t-1}          % wp1044 growth-neutrality term
%        + ε_t
% where:
%   - All variables are sample-mean demeaned (consistent with the
%     estimation_data.mat from prepare_estimation_data.m).
%   - Δc_t = dln_c_t (the observable).
%   - c*_{t-1} - c_{t-1} is approximated as a function of yhat_au lags
%     (proxy for the long-run target gap; full ec term would need c_hat
%     reconstructed from the aux VAR).
%   - HtM channel skipped because wt_H_real_gap isn't in the 10-obs file
%     (lives in the model as an internal var_model state).
%
% Inputs: dynare/estimation_data.mat
% Output: data/consumption_pac_ols.txt (text report)
%         data/consumption_pac_ols.mat (coefficients + diagnostics)

clear; clc;
fprintf('=== Partial L2: consumption PAC via OLS ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
D = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));

dln_c        = D.dln_c;       % consumption growth, demeaned (quarterly %)
yhat_au      = D.yhat_au;     % output gap, demeaned
i_au         = D.i_au;        % policy rate, demeaned (quarterly %, /4 of annual)
pi_au        = D.pi_au;       % inflation, demeaned (quarterly %)
i_10y        = D.i_10y;       % 10y bond rate, demeaned (quarterly %)
dy_bar_gap   = D.dy_bar_gap;  % HP-trend GDP growth, demeaned

T = length(dln_c);
fprintf('Sample: %d observations\n\n', T);

% Real ex-post rate = i_au - pi_au (proxy for i_gap term)
real_rate = i_au - pi_au;

% Build lags
dln_c_L1    = lag1(dln_c);
yhat_au_L1  = lag1(yhat_au);
i_au_L1     = lag1(i_au);
real_rate_L1 = lag1(real_rate);
dy_bar_gap_L1 = lag1(dy_bar_gap);
i_10y_L1    = lag1(i_10y);

% Regressor matrix.  Drop first obs (NaN from lag).
%
% Spec 1: minimal wp1044-style with growth-neutrality term
%   Δc_t = α + β_1 Δc_{t-1} + β_3 yhat_au_t + β_PAC dy_bar_gap_{t-1} + ε_t
%
% This is the cleanest test of "does the trend treatment matter".
fprintf('--- Spec 1: minimal wp1044 with growth-neutrality term ---\n');
X1 = [ones(T,1), dln_c_L1, yhat_au, dy_bar_gap_L1];
y1 = dln_c;
[b1, se1, t1, R2_1, rss1, n1] = ols_with_se(X1, y1);
names1 = {'(intercept)', 'b1_c (dln_c lag)', 'b3_c (yhat_au)', 'b_PAC_c (dy_bar lag)'};
print_table(names1, b1, se1, t1);
fprintf('R^2 = %.4f, RSS = %.2f, N = %d\n\n', R2_1, rss1, n1);

% Spec 2: add interest rate channel
fprintf('--- Spec 2: + real-rate proxy ---\n');
X2 = [ones(T,1), dln_c_L1, yhat_au, real_rate_L1, dy_bar_gap_L1];
y2 = dln_c;
[b2, se2, t2, R2_2, rss2, n2] = ols_with_se(X2, y2);
names2 = {'(intercept)', 'b1_c (dln_c lag)', 'b3_c (yhat_au)', ...
          'b2_c (real_rate lag)', 'b_PAC_c (dy_bar lag)'};
print_table(names2, b2, se2, t2);
fprintf('R^2 = %.4f, RSS = %.2f, N = %d\n\n', R2_2, rss2, n2);

% Spec 3: ECM-style with error correction proxy (yhat_au_L1 as level proxy)
% Closer to AUSPAC's b0_c·(c_hat - ln_c_level) error-correction, which we
% approximate as b0_c·yhat_au_{t-1} (yhat_au is itself a gap from
% potential, so it carries the level info).
fprintf('--- Spec 3: with ECM proxy (yhat_au lag as level signal) ---\n');
X3 = [ones(T,1), yhat_au_L1, dln_c_L1, yhat_au, real_rate_L1, dy_bar_gap_L1];
y3 = dln_c;
[b3, se3, t3, R2_3, rss3, n3] = ols_with_se(X3, y3);
names3 = {'(intercept)', 'b0_c (ECM proxy, yhat lag)', 'b1_c (dln_c lag)', ...
          'b3_c (yhat_au)', 'b2_c (real_rate lag)', 'b_PAC_c (dy_bar lag)'};
print_table(names3, b3, se3, t3);
fprintf('R^2 = %.4f, RSS = %.2f, N = %d\n\n', R2_3, rss3, n3);

% Spec 4: with 10y bond rate (matches au_pac_bayesian.mod use of i_10y as
% the long-rate driver of consumption decisions; b3_c in the model is
% actually loading on yhat_au, not the rate, so we replace i_au with i_10y)
fprintf('--- Spec 4: with i_10y as long-rate channel ---\n');
X4 = [ones(T,1), yhat_au_L1, dln_c_L1, yhat_au, i_10y_L1, dy_bar_gap_L1];
y4 = dln_c;
[b4, se4, t4, R2_4, rss4, n4] = ols_with_se(X4, y4);
names4 = {'(intercept)', 'b0_c (ECM proxy)', 'b1_c (dln_c lag)', ...
          'b3_c (yhat_au)', 'b2_c (i_10y lag)', 'b_PAC_c (dy_bar lag)'};
print_table(names4, b4, se4, t4);
fprintf('R^2 = %.4f, RSS = %.2f, N = %d\n\n', R2_4, rss4, n4);

% Comparison with L1.3a chain 1
fprintf('--- Comparison with L1.3a chain 1 posterior ---\n');
chain_path = fullfile(projectdir, 'data', 'l13a_chain1_posterior.mat');
if isfile(chain_path)
    P = load(chain_path);
    idx_b_PAC = find(strcmp(P.param_names, 'b_PAC_c'));
    fprintf('L1.3a chain 1 b_PAC_c:   mean=%.4f, sd=%.4f, q5=%.4f, q95=%.4f\n', ...
        P.post_mean(idx_b_PAC), P.post_sd(idx_b_PAC), ...
        P.post_q05(idx_b_PAC), P.post_q95(idx_b_PAC));
    fprintf('Partial L2 OLS b_PAC_c:\n');
    fprintf('  Spec 1: est=%.4f, se=%.4f, t=%.2f\n', b1(end), se1(end), t1(end));
    fprintf('  Spec 2: est=%.4f, se=%.4f, t=%.2f\n', b2(end), se2(end), t2(end));
    fprintf('  Spec 3: est=%.4f, se=%.4f, t=%.2f\n', b3(end), se3(end), t3(end));
    fprintf('  Spec 4: est=%.4f, se=%.4f, t=%.2f\n', b4(end), se4(end), t4(end));
else
    fprintf('(L1.3a chain 1 file not found; run dynare/extract_chain1_posterior.m first)\n');
end

% Save
out = struct();
out.method = 'partial L2 OLS consumption block (wp1044 simplified Eq 35)';
out.T = T;
out.specs = struct();
out.specs.spec1 = struct('names', {names1}, 'coef', b1, 'se', se1, 't', t1, 'R2', R2_1, 'N', n1);
out.specs.spec2 = struct('names', {names2}, 'coef', b2, 'se', se2, 't', t2, 'R2', R2_2, 'N', n2);
out.specs.spec3 = struct('names', {names3}, 'coef', b3, 'se', se3, 't', t3, 'R2', R2_3, 'N', n3);
out.specs.spec4 = struct('names', {names4}, 'coef', b4, 'se', se4, 't', t4, 'R2', R2_4, 'N', n4);
save(fullfile(projectdir, 'data', 'consumption_pac_ols.mat'), '-struct', 'out');
fprintf('\nSaved data/consumption_pac_ols.mat\n');

% Text report
fid = fopen(fullfile(projectdir, 'data', 'consumption_pac_ols.txt'), 'w');
fprintf(fid, 'Partial L2 OLS consumption block (wp1044-style)\n');
fprintf(fid, 'Generated %s\n', datestr(now));
fprintf(fid, 'Branch: refactor/frbdf-replication-L2\n\n');
fprintf(fid, 'Sample: %d obs (1993Q2-2023Q3, all variables demeaned)\n\n', T);
write_spec_to_fid(fid, 'Spec 1: minimal wp1044 with growth-neutrality term', names1, b1, se1, t1, R2_1, n1);
write_spec_to_fid(fid, 'Spec 2: + real-rate proxy',                          names2, b2, se2, t2, R2_2, n2);
write_spec_to_fid(fid, 'Spec 3: with ECM proxy (yhat_au lag as level)',      names3, b3, se3, t3, R2_3, n3);
write_spec_to_fid(fid, 'Spec 4: with i_10y as long-rate channel',            names4, b4, se4, t4, R2_4, n4);
if isfile(chain_path)
    fprintf(fid, 'Comparison with L1.3a chain 1 posterior (b_PAC_c):\n');
    P = load(chain_path);
    idx = find(strcmp(P.param_names, 'b_PAC_c'));
    fprintf(fid, '  L1.3a chain 1: mean=%.4f, sd=%.4f, q5=%.4f, q95=%.4f\n', ...
        P.post_mean(idx), P.post_sd(idx), P.post_q05(idx), P.post_q95(idx));
    fprintf(fid, '  Partial L2 OLS by spec:\n');
    fprintf(fid, '    Spec 1: est=%.4f, se=%.4f, t=%.2f\n', b1(end), se1(end), t1(end));
    fprintf(fid, '    Spec 2: est=%.4f, se=%.4f, t=%.2f\n', b2(end), se2(end), t2(end));
    fprintf(fid, '    Spec 3: est=%.4f, se=%.4f, t=%.2f\n', b3(end), se3(end), t3(end));
    fprintf(fid, '    Spec 4: est=%.4f, se=%.4f, t=%.2f\n', b4(end), se4(end), t4(end));
end
fclose(fid);
fprintf('Saved data/consumption_pac_ols.txt\n');

fprintf('\n=== Done. ===\n');

%% --- Helpers ---
function y = lag1(x)
    y = [NaN; x(1:end-1)];
end

function [b, se, tstat, R2, rss, n] = ols_with_se(X, y)
    valid = ~any(isnan([X, y]), 2);
    X = X(valid, :);
    y = y(valid);
    n = length(y);
    XtX = X' * X;
    b = XtX \ (X' * y);
    e = y - X * b;
    rss = e' * e;
    sigma2 = rss / (n - size(X, 2));
    se = sqrt(diag(sigma2 * inv(XtX)));
    tstat = b ./ se;
    ybar = mean(y);
    tss = (y - ybar)' * (y - ybar);
    R2 = 1 - rss / tss;
end

function print_table(names, b, se, t)
    fprintf('%-32s %10s %10s %8s\n', 'Coefficient', 'estimate', 'se', 't');
    fprintf('%-32s %10s %10s %8s\n', '-----------', '--------', '--', '-');
    for j = 1:length(names)
        fprintf('%-32s %10.4f %10.4f %8.2f\n', names{j}, b(j), se(j), t(j));
    end
end

function write_spec_to_fid(fid, header, names, b, se, t, R2, n)
    fprintf(fid, '%s\n', header);
    fprintf(fid, '%-32s %10s %10s %8s\n', 'Coefficient', 'estimate', 'se', 't');
    for j = 1:length(names)
        fprintf(fid, '%-32s %10.4f %10.4f %8.2f\n', names{j}, b(j), se(j), t(j));
    end
    fprintf(fid, 'R^2 = %.4f, N = %d\n\n', R2, n);
end
