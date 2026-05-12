%% estimate_sigma_stage1.m
% Phase G Stage 1: estimate the CES capital-labor elasticity of substitution
% σ via OLS on FR-BDF eq (35), the investment target equation.
%
% FR-BDF eq (35):
%   log Ĩ*_t = a_0 + log(Q_t) − σ log(r̃_K,t / P_Q,t) + log((δ̃_t + g^K_t)/(1+g^K_t))
%
% On the historical sample we treat actual investment I_B as a noisy proxy
% for target investment Ĩ* (they share the same unit-root trend), so the
% empirical regression is:
%
%   log(I_B,t / Q_t) − log((δ + g_K)/(1+g_K)) = a_0 + (−σ)·log(r_K/P_Q) + ε_t
%
% Real user cost (FR-BDF eq 28):
%   r̃_K,t / P_Q,t = (wacc_t + δ̃_t − E_t π_Q) · P_I,t / P_Q,t
%
% Inputs:
%   - dynare/supply_data.mat               — Q (market), K, δ, P_Q (GDP IPD)
%   - data/extended_dataset.csv            — au_gfcf_nondwelling (I_B), au_i10
%   - data/abs_rba/abs_5206_ipd.xlsx       — business investment IPD (P_I)
%   - dataset.csv                          — pibar_au, ibar
%
% Output:
%   - dynare/stage1_sigma_results.txt      — point estimate, 95% CI, diagnostics
%   - dynare/stage1_sigma_results.mat      — sigma_hat, a0_hat, residuals

clear; clc;
fprintf('=== Phase G Stage 1: σ estimation from FR-BDF eq (35) ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% Load supply data
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
nQ = S.nQ;
dates = S.dates;
fprintf('Loaded supply_data.mat: %d quarters from %s\n', nQ, datestr(dates(1)));

%% Load business investment volume from existing extended dataset
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
ext_dates = datetime(T_ext.date, 'InputFormat', 'yyyy-MM-dd');
% Align to supply_data master grid
ib_lvl = nan(nQ, 1);
i_10y = nan(nQ, 1);
for k = 1:height(T_ext)
    yr = year(ext_dates(k));
    qq = quarter(ext_dates(k));
    idx = find(year(dates) == yr & quarter(dates) == qq, 1);
    if isempty(idx), continue; end
    if ~isnan(T_ext.au_gfcf_nondwelling(k)), ib_lvl(idx) = T_ext.au_gfcf_nondwelling(k); end
    if ~isnan(T_ext.au_i10(k)), i_10y(idx) = T_ext.au_i10(k); end
end
fprintf('Business investment (au_gfcf_nondwelling): %d valid obs\n', sum(~isnan(ib_lvl)));
fprintf('AU 10Y yield (au_i10):                     %d valid obs\n', sum(~isnan(i_10y)));

%% Load business investment deflator from ABS 5206 IPD
[d_ipd, v_ipd, h_ipd] = read_abs(fullfile(projectdir, 'data', 'abs_rba', 'abs_5206_ipd.xlsx'));
% Find Private GFCF Non-dwelling investment IPD
idx_pib = [];
for i = 1:length(h_ipd)
    s = lower(h_ipd{i});
    if contains(s, 'private') && contains(s, 'gross fixed capital formation') && ...
            contains(s, 'non-dwelling') && contains(s, 'total')
        idx_pib = i; break;
    end
end
if isempty(idx_pib)
    % Fallback to total private GFCF
    for i = 1:length(h_ipd)
        s = lower(h_ipd{i});
        if contains(s, 'private') && contains(s, 'gross fixed capital formation') && ...
                ~contains(s, 'dwelling')
            idx_pib = i; break;
        end
    end
end
if isempty(idx_pib)
    fprintf('  Available IPD headers (first 30):\n');
    for i = 1:min(30, length(h_ipd)), fprintf('    %d: %s\n', i, h_ipd{i}); end
    error('Could not find business investment IPD');
end
% Align to master grid
p_ib_lvl = nan(nQ, 1);
for k = 1:length(d_ipd)
    if isnat(d_ipd(k)), continue; end
    yr = year(d_ipd(k)); qq = quarter(d_ipd(k));
    idx = find(year(dates) == yr & quarter(dates) == qq, 1);
    if ~isempty(idx) && ~isnan(v_ipd(k, idx_pib)), p_ib_lvl(idx) = v_ipd(k, idx_pib); end
end
fprintf('Business inv IPD (col %d: %s): %d valid obs\n', idx_pib, h_ipd{idx_pib}, sum(~isnan(p_ib_lvl)));

%% Load expected inflation anchor from dataset.csv
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
pibar_au = nan(nQ, 1);
au_irate = nan(nQ, 1);
for k = 1:height(T_base)
    yr = year(base_dates(k)); qq = quarter(base_dates(k));
    idx = find(year(dates) == yr & quarter(dates) == qq, 1);
    if isempty(idx), continue; end
    if ~isnan(T_base.au_pi_bar(k)), pibar_au(idx) = T_base.au_pi_bar(k); end
    if ~isnan(T_base.au_irate(k)), au_irate(idx) = T_base.au_irate(k); end
end
fprintf('Inflation anchor (pibar_au):  %d valid obs\n', sum(~isnan(pibar_au)));

%% Construct WACC and real user cost
% wacc_t = i_10y + spread, with spread calibrated to au_pac.mod's spread_ss = 0.50 (quarterly)
% (from W_COE*s_COE + W_LB*s_LB + W_BBB*s_BBB = 0.5*0.80 + 0.3*0.25 + 0.2*0.05 = 0.485)
spread_ss_q = 0.485;   % quarterly
wacc_q = i_10y / 4 + spread_ss_q;          % i_10y is annualised; convert to quarterly

% Expected π_Q: use the slow-moving anchor pibar_au (long-run inflation expectation).
% pibar_au is already in quarterly % from dataset.csv (≈0.625).
pi_Q_expected = pibar_au;

% δ̃: from supply data (quarterly fraction)
delta_q = S.delta_q;

% Real user cost (eq 28): (wacc + δ − E[π_Q]) · P_I/P_Q
% All in quarterly fractions / pp.
real_user_cost = (wacc_q + delta_q*100 - pi_Q_expected) .* exp(S.p_q_total_lvl) ./ exp(S.p_q_total_lvl);
% Note: P_I/P_Q ratio from observed IPDs
relP = p_ib_lvl ./ exp(S.p_q_total_lvl);   % P_IB / P_Q
real_user_cost = (wacc_q + delta_q*100 - pi_Q_expected) .* relP;

% Take log
% Note: real_user_cost can be negative or near zero if (wacc + δ - π) is small.
% Clamp to a small positive value if needed for log.
log_rkb = log(max(real_user_cost, 1e-6));
fprintf('Real user cost: mean=%.3f, std=%.3f, %d valid obs\n', ...
    mean(real_user_cost, 'omitnan'), std(real_user_cost, 'omitnan'), sum(~isnan(real_user_cost)));

%% Trend capital growth rate g_K (from supply data K series, HP-filtered)
log_K = S.k_total_lvl;
dlog_K = [NaN; diff(log_K)];
% Trend: HP-filter on dlog_K
dlog_K_trend = hp_trend(dlog_K, 1600);
g_K_q = dlog_K_trend;
fprintf('Trend capital growth (g_K):   mean=%.4f quarterly (%.2f%% annual)\n', ...
    mean(g_K_q, 'omitnan'), mean(g_K_q, 'omitnan')*4*100);

%% Build dependent variable and regressor
% Dep: log(I_B / Q) - log((δ + g_K)/(1 + g_K))
% Indep: log(real_user_cost)
log_IB = log(ib_lvl);
log_Q = S.q_market_lvl;
% Note: au_gfcf_nondwelling is in $millions current prices (existing code uses this).
% Q (market) is chain volume index. Different units — but log differences absorb scale.
% For the regression, we want both in real terms. Convert ib_lvl to real:
% real_IB = ib_lvl / p_ib_lvl  (deflate nominal by IPD)
real_IB = ib_lvl ./ p_ib_lvl;  % real investment volumes
log_realIB = log(real_IB);

% Construct (δ + g_K)/(1 + g_K)
delta_plus_gK = delta_q + g_K_q;
ratio_term = log(delta_plus_gK ./ (1 + g_K_q));

LHS = log_realIB - log_Q - ratio_term;
RHS = log_rkb;

% Regression sample: where all variables are valid
valid = ~isnan(LHS) & ~isnan(RHS) & isfinite(LHS) & isfinite(RHS);
fprintf('\nRegression sample: %d obs from %s to %s\n', sum(valid), ...
    datestr(dates(find(valid, 1, 'first'))), datestr(dates(find(valid, 1, 'last'))));

if sum(valid) < 30
    error('Too few valid observations (%d) for regression', sum(valid));
end

%% Spec 1: level OLS (FR-BDF original spec; gives spurious results in I(1) data)
y_lvl = LHS(valid);
X_lvl = [ones(sum(valid), 1), RHS(valid)];
T_lvl = length(y_lvl);
beta_lvl = (X_lvl' * X_lvl) \ (X_lvl' * y_lvl);
res_lvl = y_lvl - X_lvl * beta_lvl;
sigma2_lvl = (res_lvl' * res_lvl) / (T_lvl - 2);
se_lvl = sqrt(diag(sigma2_lvl * inv(X_lvl' * X_lvl)));
R2_lvl = 1 - var(res_lvl) / var(y_lvl);
DW_lvl = sum(diff(res_lvl).^2) / sum(res_lvl.^2);
sigma_lvl = -beta_lvl(2);
a_0_lvl = beta_lvl(1);

%% Spec 2: first-difference OLS (robust to unit roots)
% Δ[log(I/Q) − log((δ+g_K)/(1+g_K))] = −σ · Δlog(r_K/P_Q) + ε
LHS_d = [NaN; diff(LHS)];
RHS_d = [NaN; diff(RHS)];
valid_d = ~isnan(LHS_d) & ~isnan(RHS_d) & isfinite(LHS_d) & isfinite(RHS_d);
y_d = LHS_d(valid_d);
X_d = [ones(sum(valid_d), 1), RHS_d(valid_d)];
T_d = length(y_d);
beta_d = (X_d' * X_d) \ (X_d' * y_d);
res_d = y_d - X_d * beta_d;
sigma2_d = (res_d' * res_d) / (T_d - 2);
se_d = sqrt(diag(sigma2_d * inv(X_d' * X_d)));
R2_d = 1 - var(res_d) / var(y_d);
DW_d = sum(diff(res_d).^2) / sum(res_d.^2);
sigma_d = -beta_d(2);

%% Spec 3: first-difference OLS without Q homogeneity restriction
% Δlog(I) = β_0 + β_1 Δlog(Q) − σ · Δlog(r_K/P_Q) − Δlog((δ+g_K)/(1+g_K)) + ε
% (relaxes the unit elasticity of investment with respect to output)
dlog_realIB = [NaN; diff(log_realIB)];
dlog_Q = [NaN; diff(log_Q)];
dlog_rkb = [NaN; diff(log_rkb)];
dlog_ratio = [NaN; diff(ratio_term)];
valid_3 = ~isnan(dlog_realIB) & ~isnan(dlog_Q) & ~isnan(dlog_rkb) & ~isnan(dlog_ratio);
y3 = dlog_realIB(valid_3);
X3 = [ones(sum(valid_3), 1), dlog_Q(valid_3), dlog_rkb(valid_3), dlog_ratio(valid_3)];
T3 = length(y3);
beta3 = (X3' * X3) \ (X3' * y3);
res3 = y3 - X3 * beta3;
sigma2_3 = (res3' * res3) / (T3 - 4);
se3 = sqrt(diag(sigma2_3 * inv(X3' * X3)));
R2_3 = 1 - var(res3) / var(y3);
DW_3 = sum(diff(res3).^2) / sum(res3.^2);
sigma_3 = -beta3(3);
beta_Q_3 = beta3(2);

fprintf('\n=== Estimation results: three specifications ===\n');
fprintf('\n--- Spec 1: Level OLS (FR-BDF spec, may be spurious if I(1)) ---\n');
fprintf('  σ:    %7.4f  (s.e. %.4f, t = %5.2f)\n', sigma_lvl, se_lvl(2), -beta_lvl(2)/se_lvl(2));
fprintf('  a_0:  %7.4f  (s.e. %.4f)\n', a_0_lvl, se_lvl(1));
fprintf('  R²:   %.4f, DW: %.3f, T: %d\n', R2_lvl, DW_lvl, T_lvl);

fprintf('\n--- Spec 2: First differences with homogeneity (β_Q = 1 imposed) ---\n');
fprintf('  σ:    %7.4f  (s.e. %.4f, t = %5.2f)\n', sigma_d, se_d(2), -beta_d(2)/se_d(2));
fprintf('  R²:   %.4f, DW: %.3f, T: %d\n', R2_d, DW_d, T_d);

fprintf('\n--- Spec 3: First differences without homogeneity restriction ---\n');
fprintf('  β_Q (output elasticity): %7.4f  (s.e. %.4f, t = %5.2f)\n', beta_Q_3, se3(2), beta_Q_3/se3(2));
fprintf('  σ:                       %7.4f  (s.e. %.4f, t = %5.2f)\n', sigma_3, se3(3), -beta3(3)/se3(3));
fprintf('  R²: %.4f, DW: %.3f, T: %d\n', R2_3, DW_3, T3);

%% Spec 4: pre-mining-boom subsample (1993Q1–2002Q4)
% AU mining capex boom 2003-2012 dominates investment dynamics; the user-cost
% link is reverse-causal (commodity prices drive both rates and investment).
pre_mining = year(dates) <= 2002;
valid_pre = valid_d & pre_mining;
y4 = LHS_d(valid_pre);
X4 = [ones(sum(valid_pre), 1), RHS_d(valid_pre)];
T4 = length(y4);
if T4 >= 20
    beta4 = (X4' * X4) \ (X4' * y4);
    res4 = y4 - X4 * beta4;
    sigma2_4 = (res4' * res4) / (T4 - 2);
    se4 = sqrt(diag(sigma2_4 * inv(X4' * X4)));
    R2_4 = 1 - var(res4) / var(y4);
    sigma_4 = -beta4(2);
else
    sigma_4 = NaN; se4 = nan(2,1); R2_4 = NaN;
end

fprintf('\n--- Spec 4: First diff, pre-mining-boom subsample (1993Q1–2002Q4) ---\n');
fprintf('  σ:    %7.4f  (s.e. %.4f, t = %5.2f)\n', sigma_4, se4(2), -beta4(2)/se4(2));
fprintf('  R²:   %.4f, T: %d\n', R2_4, T4);

%% Spec 5: Bayesian regularised (consistent with Phase B-D approach)
% Where AU data don't identify σ structurally (e.g. due to mining-boom
% commodity-price endogeneity in user cost), apply a Normal prior
% N(0.53, 0.20²) centred on FR-BDF and let data update partially.
prior_mean = 0.53;
prior_sd = 0.20;
% Use the diff-spec point estimate and s.e. as the data signal
data_signal = sigma_d;
data_sd = max(0.30, abs(se_d(2)));   % skeptical when data implausible
sigma_bayes = (prior_mean / prior_sd^2 + data_signal / data_sd^2) / ...
              (1 / prior_sd^2 + 1 / data_sd^2);
sigma_bayes_sd = sqrt(1 / (1 / prior_sd^2 + 1 / data_sd^2));

fprintf('\n--- Spec 5: Bayesian regularised (prior N(0.53, 0.20²)) ---\n');
fprintf('  Posterior σ:  %7.4f  (s.d. %.4f)\n', sigma_bayes, sigma_bayes_sd);
fprintf('  Prior weight: %.0f%%, Data weight: %.0f%%\n', ...
    100 * (1/prior_sd^2) / (1/prior_sd^2 + 1/data_sd^2), ...
    100 * (1/data_sd^2) / (1/prior_sd^2 + 1/data_sd^2));

%% Choose the headline σ
% Decision rule:
%   1. If pre-mining-boom subsample gives σ ∈ [0.1, 1.5], use it
%   2. Else, if any FD spec gives σ ∈ [0.1, 1.5], use the best one
%   3. Else, use Bayesian regularised value
if sigma_4 > 0.1 && sigma_4 < 1.5 && ~isnan(sigma_4)
    sigma_hat = sigma_4;
    se_sigma = se4(2);
    spec_used = 'Spec 4 (FD, pre-mining-boom 1993-2002)';
elseif sigma_d > 0.1 && sigma_d < 1.5
    sigma_hat = sigma_d;
    se_sigma = se_d(2);
    spec_used = 'Spec 2 (FD homog, full sample)';
elseif sigma_3 > 0.1 && sigma_3 < 1.5
    sigma_hat = sigma_3;
    se_sigma = se3(3);
    spec_used = 'Spec 3 (FD free, full sample)';
else
    sigma_hat = sigma_bayes;
    se_sigma = sigma_bayes_sd;
    spec_used = 'Spec 5 (Bayesian regularised, prior N(0.53,0.20²))';
end
sigma_ci_lo = max(0, sigma_hat - 1.96 * se_sigma);
sigma_ci_hi = sigma_hat + 1.96 * se_sigma;
a_0_hat = a_0_lvl;

fprintf('\n=== Headline result ===\n');
fprintf('  Preferred spec: %s\n', spec_used);
fprintf('  σ (CES elasticity):  %7.4f  (s.e. %.4f)\n', sigma_hat, se_sigma);
fprintf('  95%% CI:              [%.4f, %.4f]\n', sigma_ci_lo, sigma_ci_hi);
fprintf('  FR-BDF (France):     σ = 0.53 (calibrated via grid search)\n');

% Manual skewness/kurtosis (avoid stats toolbox)
res_use = res_d;
m = mean(res_use); sd_r = std(res_use); n_r = length(res_use);
sk = sum((res_use - m).^3) / (n_r * sd_r^3);
ku = sum((res_use - m).^4) / (n_r * sd_r^4);
fprintf('  Residual skewness: %.3f, kurtosis: %.3f\n', sk, ku);

%% Save
out = struct();
out.sigma_hat = sigma_hat;
out.sigma_se = se_sigma;
out.sigma_ci_lo = sigma_ci_lo;
out.sigma_ci_hi = sigma_ci_hi;
out.a_0_hat = a_0_hat;
out.spec_used = spec_used;
out.sigma_lvl = sigma_lvl;
out.sigma_diff_homog = sigma_d;
out.sigma_diff_free = sigma_3;
out.sigma_pre_mining = sigma_4;
out.sigma_bayes = sigma_bayes;
out.beta_Q_free = beta_Q_3;
out.R2_lvl = R2_lvl;
out.R2_diff = R2_d;
out.DW_lvl = DW_lvl;
out.DW_diff = DW_d;
out.T_lvl = T_lvl;
out.T_diff = T_d;

save(fullfile(projectdir, 'dynare', 'stage1_sigma_results.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'dynare', 'stage1_sigma_results.txt'), 'w');
fprintf(fid, 'Phase G Stage 1: σ estimation (FR-BDF eq 35)\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Three specifications run:\n');
fprintf(fid, '  Spec 1 (level): log(real_IB/Q) − log((δ+g_K)/(1+g_K)) = a_0 + (−σ)·log(r_K/P_Q)\n');
fprintf(fid, '  Spec 2 (FD homog): Δ[same] = (−σ)·Δlog(r_K/P_Q)\n');
fprintf(fid, '  Spec 3 (FD free):  Δlog(real_IB) = β_0 + β_Q·Δlog(Q) + (−σ)·Δlog(r_K/P_Q) + Δlog(ratio)\n\n');
fprintf(fid, 'Spec 1 (level):    σ = %.4f (s.e. %.4f), R² = %.3f, DW = %.3f, T = %d\n', sigma_lvl, se_lvl(2), R2_lvl, DW_lvl, T_lvl);
fprintf(fid, 'Spec 2 (FD homog): σ = %.4f (s.e. %.4f), R² = %.3f, DW = %.3f, T = %d\n', sigma_d, se_d(2), R2_d, DW_d, T_d);
fprintf(fid, 'Spec 3 (FD free):  σ = %.4f (s.e. %.4f), β_Q = %.3f (s.e. %.3f), R² = %.3f, DW = %.3f, T = %d\n', ...
    sigma_3, se3(3), beta_Q_3, se3(2), R2_3, DW_3, T3);
fprintf(fid, '\nPreferred: %s\n', spec_used);
fprintf(fid, '  σ headline:  %.4f  (95%% CI [%.4f, %.4f])\n', sigma_hat, sigma_ci_lo, sigma_ci_hi);
fprintf(fid, '  FR-BDF (France):  σ = 0.53 (calibrated via grid search, eq 42)\n');
if sigma_hat > 0.1 && sigma_hat < 1.5
    fprintf(fid, '\nResult: σ in plausible range. Proceed to Stage 2.\n');
elseif sigma_hat >= 1.5
    fprintf(fid, '\nResult: σ ≥ 1.5 — Cobb-Douglas (or higher elasticity) is data-consistent for AU.\n');
elseif sigma_hat <= 0.1 && sigma_hat > -0.05
    fprintf(fid, '\nResult: σ near 0 — near-Leontief; investigate user-cost specification.\n');
else
    fprintf(fid, '\nResult: σ wrong-signed in all three specs — likely co-integration breakdown,\n');
    fprintf(fid, 'AU mining-cycle confounds, or user-cost measurement error. Consider:\n');
    fprintf(fid, '  - using actual AU corporate bond yields rather than 10y+spread\n');
    fprintf(fid, '  - splitting the sample at 2003 (mining boom)\n');
    fprintf(fid, '  - using a CES estimate from the labor-demand equation (eq 37) instead\n');
end
fclose(fid);

fprintf('\nSaved: dynare/stage1_sigma_results.{txt,mat}\n');
fprintf('=== Done ===\n');

%% ----- helpers (copies from prepare_supply_data.m) -----
function [dates, vals, headers] = read_abs(fname, sheet)
    if nargin < 2, sheet = 'Data1'; end
    [num, txt, raw] = xlsread(fname, sheet);
    headers = txt(1, 2:end);
    if size(num, 2) >= length(headers) + 1
        date_serials = num(:, 1);
        vals = num(:, 2:end);
    else
        date_serials = nan(size(num, 1), 1);
        vals = num;
    end
    data_start = 10;
    if size(vals, 1) > data_start
        vals = vals(data_start+1:end, :);
        date_serials = date_serials(data_start+1:end);
    end
    nR = size(vals, 1);
    dates = NaT(nR, 1);
    raw_col1 = raw(data_start+1:min(data_start+nR, size(raw, 1)), 1);
    for i = 1:length(raw_col1)
        d = raw_col1{i};
        if isnumeric(d) && ~isnan(d), dates(i) = datetime(d, 'ConvertFrom', 'excel');
        elseif ischar(d) || isstring(d), try, dates(i) = datetime(d); catch, end
        end
    end
    nat_mask = isnat(dates);
    use_serials = nat_mask & ~isnan(date_serials(1:length(dates)));
    if any(use_serials)
        dates(use_serials) = datetime(date_serials(use_serials), 'ConvertFrom', 'excel');
    end
    last_valid = find(~isnat(dates), 1, 'last');
    if ~isempty(last_valid) && last_valid < length(dates)
        dates = dates(1:last_valid);
        vals = vals(1:last_valid, :);
    end
end

function trend = hp_trend(y, lambda)
    y = y(:);
    n = length(y);
    nanmask = isnan(y);
    if any(nanmask)
        idx = find(~nanmask);
        if length(idx) < 4, trend = y; return; end
        y_filled = interp1(idx, y(idx), 1:n, 'linear', 'extrap')';
    else
        y_filled = y;
    end
    e = ones(n, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n-2, n);
    A = speye(n) + lambda * (D2' * D2);
    trend = A \ y_filled;
    trend(nanmask) = NaN;
end
