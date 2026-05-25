%% estimate_pac_blocks_ols.m  --  partial L2 OLS for 4 remaining PAC blocks
%
% Phase L2 step 2 (refactor/frbdf-replication-L2 branch).  Applies the
% same OLS-with-trend-regressor approach as the L2-pilot consumption
% block (estimate_consumption_pac_ols.m) to the 4 remaining PAC blocks:
%
%   - VA-price Phillips (pQ)   wp1044 Eq 16, trend = pi_Q_bar
%   - Employment (n)            wp1044 Eq 30, trend = dn_bar
%   - Business investment (ib)  wp1044 Eq 46, trends = dq_bar, dlog_rkb
%   - Housing investment (ih)   wp1044 Eq 37, trend = dlogIH_bar
%
% Each block uses a similar OLS spec to L2-pilot Spec 4:
%   Δy_t = α + β_0 yhat_au_{t-1} + β_1 Δy_{t-1} + β_3 yhat_au_t
%        + β_2 i_10y_{t-1} + β_PAC (block-specific trend)_{t-1} + ε_t
%
% where Δy is the relevant LHS for each block:
%   pQ: Δp_Q proxied by pi_au (CPI inflation; AUSPAC doesn't separate
%       VA-price from CPI in the data layer)
%   n:  Δn proxied by Δlog(au_employment)
%   ib: Δlog(au_gfcf_nondwelling) = dln_ib
%   ih: Δlog(au_gfcf_dwelling)
%
% For the business investment block, the growth-neutrality term has TWO
% components per wp1044 Eq 46: (Δq̄_{t-1} - σ_ces · Δlog(r̄_KB)_{t-1}).
% We include both as separate regressors and check whether the σ_ces
% restriction is consistent with the data.
%
% Compares each block's b_PAC posterior with the implied wp1044 derived
% form (1 - Σβ - ω), using calibrated ω from au_pac_bayesian.mod:
%   omega_pQ = 0.46
%   omega_n  = 0.30
%   omega_ib = 0.35
%   omega_ih = 0.30
%
% Inputs:
%   dynare/estimation_data.mat   (yhat_au, pi_au, i_au, i_10y, dln_ib, ...)
%   data/extended_dataset.csv    (au_employment, au_gfcf_dwelling, au_gfcf_nondwelling)
%   data/trend_series.mat        (dlog_qbar, dlog_rkb_bar, dlog_nbar, pi_Q_bar, dlog_IHbar)
% Outputs:
%   data/pac_blocks_ols.{mat,txt}

clear; clc;
fprintf('=== Partial L2: OLS for 4 remaining PAC blocks ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% Load
D = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
TS = load(fullfile(projectdir, 'data', 'trend_series.mat'));

% Aligned sample (1993Q2-2023Q3, 122 obs)
sample_idx = 2:123;
nObs = length(sample_idx);

% Common regressors from estimation_data.mat (already demeaned)
yhat_au  = D.yhat_au;
pi_au    = D.pi_au;
i_10y    = D.i_10y;
dln_ib   = D.dln_ib;       % already in estimation_data
dln_c    = D.dln_c;
dy_bar_gap = D.dy_bar_gap;

% Trend regressors from trend_series.mat, aligned to estimation_data sample.
% trend_series.mat uses supply_data dates 1990Q1-2024Q4 (140 obs); base_dates
% start 1993Q1 and we use rows 2:123.  Need to find the corresponding rows
% in supply dates.
supply_dates = TS.dates;
base_dates   = datetime(T_ext.date);
sample_base  = base_dates(sample_idx);

align_idx = nan(nObs, 1);
for i = 1:nObs
    m = find(year(supply_dates) == year(sample_base(i)) & ...
             quarter(supply_dates) == quarter(sample_base(i)), 1);
    if ~isempty(m), align_idx(i) = m; end
end

% Extract trend series in q/q PERCENT form (matches estimation_data scale)
% and demean (matches estimation_data convention).
extr = @(field) demean(extract_aligned(TS.(field), align_idx) * 100);

dq_bar     = extr('dlog_qbar');
dlog_rkb   = extr('dlog_rkb_bar');
dn_bar     = extr('dlog_nbar');
pi_Q_bar   = extr('pi_Q_bar');
dlogIH_bar = extr('dlog_IHbar');

% Additional LHS variables from extended_dataset.csv
au_employment  = T_ext.au_employment(sample_idx);
au_gfcf_dwell  = T_ext.au_gfcf_dwelling(sample_idx);

dln_n  = demean([NaN; diff(log(au_employment))] * 100);
dln_ih = demean([NaN; diff(log(au_gfcf_dwell))] * 100);

% CES sigma from ces_2026_calibration.mat
C = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));
sigma_ces = C.sigma;
fprintf('sigma_ces (CES capital-labour substitution) = %.4f\n', sigma_ces);

% Calibrated omega per block (from au_pac_bayesian.mod / parameter-values.inc)
omega = struct('pQ', 0.46, 'n', 0.30, 'ib', 0.35, 'ih', 0.30);

%% Block 1: VA-price Phillips
%   LHS: pi_au (CPI proxy for VA price -- AUSPAC doesn't have separate p_Q
%               observable; pi_au is the closest demand-side analog)
%   Trend: pi_Q_bar
fprintf('\n=== Block: VA-price Phillips (wp1044 Eq 16) ===\n');
[res_pQ] = run_pac_ols('pQ', pi_au, ...
    {'(intercept)', 'b0_pQ (yhat lag ECM proxy)', 'b1_pQ (pi_au lag)', ...
     'b2_pQ (yhat_au contemp)', 'i_10y lag', 'pi_Q_bar (trend)'}, ...
    [ones(nObs,1), lag1(yhat_au), lag1(pi_au), yhat_au, lag1(i_10y), lag1(pi_Q_bar)], ...
    omega.pQ);

%% Block 2: Employment
%   LHS: dln_n
%   Trend: dn_bar
fprintf('\n=== Block: Employment (wp1044 Eq 30) ===\n');
[res_n] = run_pac_ols('n', dln_n, ...
    {'(intercept)', 'b0_n (yhat lag ECM proxy)', 'b1_n (dln_n lag)', ...
     'b5_n (yhat_au contemp)', 'i_10y lag', 'dn_bar (trend)'}, ...
    [ones(nObs,1), lag1(yhat_au), lag1(dln_n), yhat_au, lag1(i_10y), lag1(dn_bar)], ...
    omega.n);

%% Block 3: Business investment
%   LHS: dln_ib
%   Trends: dq_bar AND dlog_rkb (per wp1044 Eq 46: dq_bar - sigma_ces*dlog_rkb)
fprintf('\n=== Block: Business investment (wp1044 Eq 46) ===\n');
% Option A: separate dq_bar and dlog_rkb regressors
fprintf('Spec A: separate dq_bar and dlog_rkb regressors\n');
[res_ib_sep] = run_pac_ols('ib_sep', dln_ib, ...
    {'(intercept)', 'b0_ib (yhat lag ECM proxy)', 'b1_ib (dln_ib lag)', ...
     'b3_ib (yhat_au contemp)', 'i_10y lag', 'dq_bar (trend mkt VA)', ...
     'dlog_rkb (trend real user cost)'}, ...
    [ones(nObs,1), lag1(yhat_au), lag1(dln_ib), yhat_au, lag1(i_10y), ...
     lag1(dq_bar), lag1(dlog_rkb)], ...
    omega.ib);

% Option B: wp1044-restricted form (dq_bar - sigma_ces*dlog_rkb)
fprintf('\nSpec B: wp1044 restricted (dq_bar - sigma_ces*dlog_rkb)\n');
combined = lag1(dq_bar) - sigma_ces * lag1(dlog_rkb);
[res_ib_comb] = run_pac_ols('ib_comb', dln_ib, ...
    {'(intercept)', 'b0_ib (yhat lag ECM proxy)', 'b1_ib (dln_ib lag)', ...
     'b3_ib (yhat_au contemp)', 'i_10y lag', '(dq_bar - sigma*dlog_rkb)'}, ...
    [ones(nObs,1), lag1(yhat_au), lag1(dln_ib), yhat_au, lag1(i_10y), combined], ...
    omega.ib);

%% Block 4: Housing investment
%   LHS: dln_ih
%   Trend: dlogIH_bar
fprintf('\n=== Block: Housing investment (wp1044 Eq 37) ===\n');
[res_ih] = run_pac_ols('ih', dln_ih, ...
    {'(intercept)', 'b0_ih (yhat lag ECM proxy)', 'b1_ih (dln_ih lag)', ...
     'b3_ih (yhat_au contemp)', 'i_10y lag', 'dlogIH_bar (trend)'}, ...
    [ones(nObs,1), lag1(yhat_au), lag1(dln_ih), yhat_au, lag1(i_10y), lag1(dlogIH_bar)], ...
    omega.ih);

%% Summary
fprintf('\n\n=== Summary: b_PAC (trend coefficient) across 5 PAC blocks ===\n');
fprintf('%-30s %12s %12s %12s\n', 'Block', 'b_PAC est', 'se', 't');
fprintf('%-30s %12s %12s %12s\n', '-----', '---------', '--', '-');

% Pull consumption result from L2-pilot Spec 4 for cross-comparison
pilot = load(fullfile(projectdir, 'data', 'consumption_pac_ols.mat'));
fprintf('%-30s %12.4f %12.4f %12s\n', 'consumption (L2-pilot Spec 4)', ...
    pilot.specs.spec4.coef(6), pilot.specs.spec4.se(6), ...
    sprintf('%.2f', pilot.specs.spec4.t(6)));
fprintf('%-30s %12.4f %12.4f %12.2f\n', 'VA-price Phillips (pQ)', ...
    res_pQ.b_PAC, res_pQ.se_b_PAC, res_pQ.t_b_PAC);
fprintf('%-30s %12.4f %12.4f %12.2f\n', 'employment (n)', ...
    res_n.b_PAC, res_n.se_b_PAC, res_n.t_b_PAC);
fprintf('%-30s %12.4f %12.4f %12.2f\n', 'business inv (ib, sep)', ...
    res_ib_sep.b_PAC, res_ib_sep.se_b_PAC, res_ib_sep.t_b_PAC);
fprintf('%-30s %12.4f %12.4f %12.2f\n', 'business inv (ib, comb)', ...
    res_ib_comb.b_PAC, res_ib_comb.se_b_PAC, res_ib_comb.t_b_PAC);
fprintf('%-30s %12.4f %12.4f %12.2f\n', 'housing inv (ih)', ...
    res_ih.b_PAC, res_ih.se_b_PAC, res_ih.t_b_PAC);

fprintf('\n=== Implied (1-Sum(beta)-omega) wp1044 derived form vs OLS estimate ===\n');
fprintf('%-30s %16s %14s\n', 'Block', '1-Σβ-ω wp1044', 'OLS b_PAC');
fprintf('%-30s %16s %14s\n', '-----', '------------', '---------');
fprintf('%-30s %16.4f %14.4f\n', 'pQ',         res_pQ.derived_coef,    res_pQ.b_PAC);
fprintf('%-30s %16.4f %14.4f\n', 'n',          res_n.derived_coef,     res_n.b_PAC);
fprintf('%-30s %16.4f %14.4f\n', 'ib (sep)',   res_ib_sep.derived_coef, res_ib_sep.b_PAC);
fprintf('%-30s %16.4f %14.4f\n', 'ih',         res_ih.derived_coef,    res_ih.b_PAC);

%% Save
out = struct();
out.method = 'partial L2 OLS, 4 PAC blocks (ib, ih, n, pQ)';
out.results = struct();
out.results.pQ      = res_pQ;
out.results.n       = res_n;
out.results.ib_sep  = res_ib_sep;
out.results.ib_comb = res_ib_comb;
out.results.ih      = res_ih;
out.sigma_ces = sigma_ces;
out.omega = omega;
save(fullfile(projectdir, 'data', 'pac_blocks_ols.mat'), '-struct', 'out');
fprintf('\nSaved data/pac_blocks_ols.mat\n');

% Text report
fid = fopen(fullfile(projectdir, 'data', 'pac_blocks_ols.txt'), 'w');
fprintf(fid, 'Partial L2 OLS for 4 remaining PAC blocks (ib, ih, n, pQ)\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
write_block(fid, 'VA-price Phillips (Eq 16)',     res_pQ);
write_block(fid, 'Employment (Eq 30)',            res_n);
write_block(fid, 'Business investment, sep (Eq 46)', res_ib_sep);
write_block(fid, 'Business investment, comb (Eq 46 wp1044-restricted)', res_ib_comb);
write_block(fid, 'Housing investment (Eq 37)',    res_ih);
fprintf(fid, '\nSummary of b_PAC (trend coefficient):\n');
fprintf(fid, '  consumption (L2-pilot Spec 4): %.4f  (se %.4f, t %.2f)\n', ...
    pilot.specs.spec4.coef(6), pilot.specs.spec4.se(6), pilot.specs.spec4.t(6));
fprintf(fid, '  VA-price Phillips:             %.4f  (se %.4f, t %.2f)\n', ...
    res_pQ.b_PAC, res_pQ.se_b_PAC, res_pQ.t_b_PAC);
fprintf(fid, '  Employment:                    %.4f  (se %.4f, t %.2f)\n', ...
    res_n.b_PAC, res_n.se_b_PAC, res_n.t_b_PAC);
fprintf(fid, '  Business inv (sep):            %.4f  (se %.4f, t %.2f)\n', ...
    res_ib_sep.b_PAC, res_ib_sep.se_b_PAC, res_ib_sep.t_b_PAC);
fprintf(fid, '  Business inv (combined):       %.4f  (se %.4f, t %.2f)\n', ...
    res_ib_comb.b_PAC, res_ib_comb.se_b_PAC, res_ib_comb.t_b_PAC);
fprintf(fid, '  Housing inv:                   %.4f  (se %.4f, t %.2f)\n', ...
    res_ih.b_PAC, res_ih.se_b_PAC, res_ih.t_b_PAC);
fclose(fid);
fprintf('Saved data/pac_blocks_ols.txt\n');

fprintf('\n=== Done. ===\n');

%% --- Helpers ---
function y = lag1(x)
    y = [NaN; x(1:end-1)];
end

function v = demean(x)
    v = x - mean(x, 'omitnan');
end

function v = extract_aligned(src, align_idx)
    v = nan(length(align_idx), 1);
    ok = ~isnan(align_idx);
    v(ok) = src(align_idx(ok));
end

function res = run_pac_ols(block_name, y, names, X, omega_calib)
%RUN_PAC_OLS Single-spec OLS for a PAC block.  Prints results and returns
%a struct.
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

    fprintf('%-32s %10s %10s %8s\n', 'Coefficient', 'estimate', 'se', 't');
    fprintf('%-32s %10s %10s %8s\n', '-----------', '--------', '--', '-');
    for j = 1:length(names)
        fprintf('%-32s %10.4f %10.4f %8.2f\n', names{j}, b(j), se(j), tstat(j));
    end
    fprintf('R² = %.4f, N = %d\n', R2, n);

    % wp1044 derived form: coefficient on trend = (1 - sum(b1..bk) - omega)
    % For these specs, "lag coefficients" = b at index 3 (the y lag, e.g. b1_pQ).
    % We use just b1 (single lag) for the derived form since the OLS spec
    % only has a single y lag; wp1044 has more lags for employment but
    % we're using a 1-lag spec for all blocks.
    b1 = b(3);   % LHS lag coefficient (b1_block)
    derived = 1 - b1 - omega_calib;

    % b_PAC is the LAST coefficient (the trend regressor)
    res.block_name   = block_name;
    res.coef         = b;
    res.se           = se;
    res.tstat        = tstat;
    res.R2           = R2;
    res.N            = n;
    res.names        = names;
    res.b_PAC        = b(end);
    res.se_b_PAC     = se(end);
    res.t_b_PAC      = tstat(end);
    res.derived_coef = derived;
    res.omega_calib  = omega_calib;
end

function write_block(fid, header, res)
    fprintf(fid, '%s\n', header);
    fprintf(fid, '%-32s %10s %10s %8s\n', 'Coefficient', 'estimate', 'se', 't');
    for j = 1:length(res.names)
        fprintf(fid, '%-32s %10.4f %10.4f %8.2f\n', res.names{j}, ...
            res.coef(j), res.se(j), res.tstat(j));
    end
    fprintf(fid, 'R^2 = %.4f, N = %d\n', res.R2, res.N);
    fprintf(fid, 'wp1044 derived (1 - b1 - omega): %.4f   OLS b_PAC: %.4f\n\n', ...
        res.derived_coef, res.b_PAC);
end
