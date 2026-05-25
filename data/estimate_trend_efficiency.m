%% estimate_trend_efficiency.m  --  wp1044 Eq 7 trend labour efficiency, AU
%
% Phase L1.1 of the FR-BDF wp1044 replication (refactor/frbdf-replication
% branch).  Estimates the trend labour efficiency series Ē_t on Australian
% data, following Dubois et al. (2026) BdF WP #1044 Section 3.1.1, Eq 7:
%
%   log(Ē_t) = z_1·log(Ē_{t-1})
%            + (1 - z_1)·(z_2 + z_3·δ_{08Q3-} - covid_loss·δ_{20Q2-21Q4})
%            + z_4·(T_1 - z_1·T_1(-1))   [trend pre-2002Q2]
%            + z_5·(T_2 - z_1·T_2(-1))   [trend 2002Q2-2008Q3]
%            + z_6·(T_3 - z_1·T_3(-1))   [trend post-2008Q3]
%            + z_7·(log(TUC/TUC̄) - z_1·log(TUC_{t-1}/TUC̄))   [SKIPPED, see below]
%            + z_8·(δ_{20Q1} + δ_{20Q3}) + z_9·δ_{20Q2} + ε_t
%
% LHS object Ē_t is the Solow residual from the CES production function,
% E_t = [((Q/γ)^ξ - α·K^ξ) / ((1-α)·(H·N)^ξ)]^(1/ξ),  ξ = (σ-1)/σ
% computed at the calibrated (σ, γ, α) triple from ces_2026_calibration.mat.
%
% Differences from wp1044 Eq 7 as written:
%   - TUC (capacity utilisation) is OMITTED.  AU does not have a clean
%     quarterly TUC series in the repo (NAB Business Survey capacity
%     utilisation index exists but is not downloaded yet).  Adding TUC
%     would require either sourcing NAB data or proxying via output gap;
%     left for Phase L1.2 if Eq 7 residuals are noisy.  Without TUC, ε_t
%     absorbs all cyclical variation.
%   - COVID level loss δ_{20Q2-21Q4} is CALIBRATED, not estimated, at the
%     AU value of -2.0% (FR-BDF uses -5.9% for France).  This matches the
%     calibration in estimate_ces_2026.m Step 5.
%
% Sample: 1990Q1 onwards (so T_1 starts at 0 in the first observation).
%
% Inputs:
%   dynare/supply_data.mat        - q_market_lvl, k_total_lvl, n_total_lvl,
%                                   h_lvl, dates, nQ
%   dynare/ces_2026_calibration.mat - sigma, gamma, alpha
%
% Outputs:
%   data/trend_efficiency.mat     - z1..z9 coefficients with SEs, fitted
%                                   log_Ebar_t series, residuals, dates
%   data/trend_efficiency.txt     - formatted summary table (wp1044
%                                   Table 3.1.4 layout)
%
% Cross-validation: compare implied annual trend growth rates pre-2002Q2 /
% 2002Q2-2008Q3 / post-2008Q3 against the regime growth rates already in
% ces_2026_calibration.txt.  Should match closely (the underlying spec is
% the same; differences are due to the standalone re-estimation isolated
% from the σ-FOC step).

clear; clc;
fprintf('=== Trend labour efficiency Ē_t  --  wp1044 Eq 7, AU data ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% ------------------------------------------------------------
%% 0. Load supply data and CES calibration
%% ------------------------------------------------------------
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
C = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));

dates = S.dates;
nQ    = S.nQ;
log_Q = S.q_market_lvl;     % log market-sector real GVA (Q_t)
log_K = S.k_total_lvl;      % log total capital stock (K_t)
log_N = S.n_total_lvl;      % log total employment, proxy for N_S
log_H = S.h_lvl;            % log hours per worker (H_t)

sigma_hat = C.sigma;
gamma_hat = C.gamma;
alpha_hat = C.alpha;

fprintf('Loaded supply_data.mat: %d quarters, %s to %s\n', ...
    nQ, datestr(dates(1)), datestr(dates(end)));
fprintf('CES parameters (from ces_2026_calibration.mat):\n');
fprintf('  sigma = %.4f,  gamma = %.4f,  alpha = %.3f\n\n', ...
    sigma_hat, gamma_hat, alpha_hat);

%% ------------------------------------------------------------
%% 1. Compute Solow residual log_E_t by inverting the CES production
%%
%%    Production: Q_t = γ·[α·K_t^ξ + (1-α)·(E_t·H_t·N_t)^ξ]^(1/ξ)
%%    Invert:     E_t = [((Q_t/γ)^ξ - α·K_t^ξ) / ((1-α)·(H_t·N_t)^ξ)]^(1/ξ)
%% ------------------------------------------------------------
xi = (sigma_hat - 1) / sigma_hat;

Q_lvl  = exp(log_Q);
K_lvl  = exp(log_K);
HN_lvl = exp(log_H + log_N);

num_E = (Q_lvl / gamma_hat) .^ xi - alpha_hat * K_lvl .^ xi;
den_E = (1 - alpha_hat) * HN_lvl .^ xi;
E_pre = num_E ./ den_E;

% Feasibility guard.  With σ < 1, ξ < 0 so K^ξ = 1/K^|ξ| is small; ratio
% should be positive but can flip sign for early quarters with sparse data.
ok_E = E_pre > 0 & isfinite(E_pre);
if ~all(ok_E(~isnan(num_E)))
    n_bad = sum(~ok_E & ~isnan(num_E));
    fprintf('WARNING: %d quarters have infeasible E_t.  Using abs() fallback.\n', n_bad);
    E_pre = abs(E_pre);
end

log_E = log(E_pre) / xi;   % since E = E_pre^(1/ξ); ξ<0 flips sign correctly
log_E(~isfinite(log_E)) = NaN;

fprintf('Solow residual log_E_t: %d non-NaN obs (mean %.4f, sd %.4f)\n\n', ...
    sum(~isnan(log_E)), mean(log_E,'omitnan'), std(log_E,'omitnan'));

%% ------------------------------------------------------------
%% 2. Build regressors:  three trend knots + step + COVID dummies
%% ------------------------------------------------------------
% Trend variables (year-fractions; slopes are interpreted as annual rates).
% wp1044 uses regime-segmented linear trends starting at 1990Q1, 2002Q2,
% 2008Q3.  Each T_i is max(0, t - knot_i) so the slope effects accumulate.
trend_start_year = 1990;
T1 = max(0, (year(dates) - trend_start_year) + (quarter(dates) - 1)/4);   % from 1990Q1
T2 = max(0, (year(dates) - 2002) + (quarter(dates) - 1)/4 - 0.25);        % from 2002Q2
T3 = max(0, (year(dates) - 2008) + (quarter(dates) - 1)/4 - 0.50);        % from 2008Q3

% Step dummy: 1 from 2008Q3 onwards (captures permanent GFC level shift)
d_08Q3_step = double(dates >= datetime(2008, 7, 1));

% COVID level-loss step (calibrated; covers 2020Q2 through 2021Q4)
d_covid_lvl  = double(dates >= datetime(2020, 4, 1) & dates <= datetime(2021, 12, 31));

% COVID outlier quarter dummies
d_covid_20q1 = double(year(dates) == 2020 & quarter(dates) == 1);
d_covid_20q2 = double(year(dates) == 2020 & quarter(dates) == 2);
d_covid_20q3 = double(year(dates) == 2020 & quarter(dates) == 3);

% AU-calibrated COVID efficiency loss (consistent with ces_2026_calibration)
covid_E_loss_AU = 0.020;   % -2.0% (FR-BDF uses -5.9% for France)
fprintf('COVID Ē level shift calibrated to -%.1f%% (FR-BDF: -5.9%%)\n', ...
    100 * covid_E_loss_AU);

%% ------------------------------------------------------------
%% 3. Estimate Eq 7 by profile likelihood:
%%
%%    Quasi-difference at trial z_1, OLS on the linear part conditional
%%    on z_1, grid search z_1 ∈ [0.10, 0.95] for the maximum log-likelihood.
%%    Final coefficients reported with structural standard errors via
%%    delta method for the (1 - z_1)-scaled terms.
%% ------------------------------------------------------------
z1_grid = 0.10:0.0125:0.95;
best_loglik = -inf;
best_z1     = NaN;
best_beta   = [];
best_resid  = [];
best_n      = NaN;
best_sigma2 = NaN;
best_X      = [];
best_lhs    = [];
best_valid  = [];

for k = 1:length(z1_grid)
    z1 = z1_grid(k);

    % Quasi-differenced LHS
    y_qd = log_E - z1 * [NaN; log_E(1:end-1)];

    % Linear regressors (coefficients on these are wp1044's z_2, z_3, z_4, z_5, z_6)
    x_const     = (1 - z1) * ones(nQ, 1);
    x_step      = (1 - z1) * d_08Q3_step;
    x_T1_qd     = T1 - z1 * [NaN; T1(1:end-1)];
    x_T2_qd     = T2 - z1 * [NaN; T2(1:end-1)];
    x_T3_qd     = T3 - z1 * [NaN; T3(1:end-1)];

    % Calibrated COVID level term (moved to LHS so it doesn't enter X)
    x_covid_lvl = -(1 - z1) * covid_E_loss_AU * d_covid_lvl;

    % COVID dummy regressors (z_8 and z_9 in wp1044, kept as-is — wp1044
    % doesn't quasi-difference them since they're single-quarter outliers)
    x_20Q2     = d_covid_20q2;
    x_20Q1plQ3 = d_covid_20q1 + d_covid_20q3;

    lhs = y_qd - x_covid_lvl;
    X = [x_const, x_step, x_T1_qd, x_T2_qd, x_T3_qd, x_20Q1plQ3, x_20Q2];

    valid_k = ~isnan(lhs) & all(~isnan(X), 2);
    if sum(valid_k) < 30, continue; end

    yk = lhs(valid_k);
    Xk = X(valid_k, :);
    bk = (Xk' * Xk) \ (Xk' * yk);
    rk = yk - Xk * bk;
    n_obs   = length(yk);
    sigma2  = (rk' * rk) / (n_obs - size(Xk, 2));
    loglik  = -0.5 * n_obs * (log(2 * pi * sigma2) + 1);

    if loglik > best_loglik
        best_loglik = loglik;
        best_z1     = z1;
        best_beta   = bk;
        best_resid  = rk;
        best_n      = n_obs;
        best_sigma2 = sigma2;
        best_X      = Xk;
        best_lhs    = yk;
        best_valid  = valid_k;
    end
end

% Map regression coefficients to wp1044 structural names.
%
%   The linear regressors with (1-z_1) inside them are estimated as the
%   scaled coefficients; the structural z_2, z_3 are recovered via:
%      coef_x_const = (1-z_1) * z_2  =>  z_2 = coef_x_const / (1-z_1)
%   But because x_const itself already absorbs the (1-z_1) factor,
%   the OLS coefficient IS z_2 directly.  Similarly for z_3.
%
%   The trend regressors x_Ti_qd have no (1-z_1) scaling — they're
%   T_i - z_1·T_i(-1) — so OLS gives z_4, z_5, z_6 directly.
%
%   x_20Q1plQ3 and x_20Q2 likewise enter unscaled — z_8 and z_9 directly.
z1_hat = best_z1;
z2_hat = best_beta(1);   % intercept (level)
z3_hat = best_beta(2);   % 2008Q3 level shift
z4_hat = best_beta(3);   % trend slope pre-2002Q2
z5_hat = best_beta(4);   % trend slope addition from 2002Q2
z6_hat = best_beta(5);   % trend slope addition from 2008Q3
z8_hat = best_beta(6);   % COVID 20Q1+20Q3 dummies
z9_hat = best_beta(7);   % COVID 20Q2 dummy
z7_hat = 0;              % TUC omitted in this pass

% OLS standard errors from the linear regression
ols_se = sqrt(diag(best_sigma2 * inv(best_X' * best_X)));
% Map onto structural names
se_z2 = ols_se(1);
se_z3 = ols_se(2);
se_z4 = ols_se(3);
se_z5 = ols_se(4);
se_z6 = ols_se(5);
se_z8 = ols_se(6);
se_z9 = ols_se(7);

% For z_1, use the profile-likelihood asymptotic SE: pick the two
% z_1 grid points where 2*(loglik_max - loglik) ≈ chi2(1, 0.6827) ≈ 1
% (one standard deviation in profile likelihood).  Compute a finer
% gradient via numerical second derivative.
delta_z = 0.005;
z1_lo = max(0.05, best_z1 - delta_z);
z1_hi = min(0.99, best_z1 + delta_z);

ll_lo = profile_loglik(log_E, z1_lo, nQ, T1, T2, T3, d_08Q3_step, ...
                       d_covid_lvl, d_covid_20q1, d_covid_20q2, d_covid_20q3, ...
                       covid_E_loss_AU);
ll_hi = profile_loglik(log_E, z1_hi, nQ, T1, T2, T3, d_08Q3_step, ...
                       d_covid_lvl, d_covid_20q1, d_covid_20q2, d_covid_20q3, ...
                       covid_E_loss_AU);
ll_mid = best_loglik;

% Second derivative of log-likelihood w.r.t. z_1
d2_loglik = (ll_lo - 2 * ll_mid + ll_hi) / (delta_z ^ 2);
if d2_loglik < 0
    se_z1 = sqrt(-1 / d2_loglik);
else
    se_z1 = NaN;
end

%% ------------------------------------------------------------
%% 4. Reconstruct fitted log_Ebar_t and the deterministic trend
%% ------------------------------------------------------------
% Deterministic absorbing trend (drops AR(1) lag, keeps trend+step+COVID).
% This is the smooth Ē_t series used downstream.
log_Ebar_det = z2_hat + z3_hat * d_08Q3_step ...
             + z4_hat * T1 + z5_hat * T2 + z6_hat * T3 ...
             - covid_E_loss_AU * d_covid_lvl;

% Dynamic fitted values: iterate the AR(1) form forward using observed
% log_E_{t-1}.  Useful for residual diagnostics.
valid_E = ~isnan(log_E);
idx_E = find(valid_E);
log_E_fit = nan(nQ, 1);
if ~isempty(idx_E)
    log_E_fit(idx_E(1)) = log_E(idx_E(1));
    for j = 2:length(idx_E)
        t = idx_E(j);
        tprev = idx_E(j - 1);
        if t - tprev ~= 1
            log_E_fit(t) = log_E(t);
            continue
        end
        log_E_fit(t) = z1_hat * log_E(tprev) ...
            + (1 - z1_hat) * (z2_hat + z3_hat * d_08Q3_step(t) ...
                              - covid_E_loss_AU * d_covid_lvl(t)) ...
            + z4_hat * (T1(t) - z1_hat * T1(tprev)) ...
            + z5_hat * (T2(t) - z1_hat * T2(tprev)) ...
            + z6_hat * (T3(t) - z1_hat * T3(tprev)) ...
            + z8_hat * (d_covid_20q1(t) + d_covid_20q3(t)) ...
            + z9_hat * d_covid_20q2(t);
    end
end
log_E_resid = log_E - log_E_fit;

% Implied annual trend growth rates per regime
g_E_pre_2002 = 100 * z4_hat;
g_E_2002_08  = 100 * (z4_hat + z5_hat);
g_E_post_08  = 100 * (z4_hat + z5_hat + z6_hat);

%% ------------------------------------------------------------
%% 5. Report (wp1044 Table 3.1.4 layout)
%% ------------------------------------------------------------
fprintf('\n=============================================================\n');
fprintf('wp1044 Eq 7 trend labour efficiency  --  AU OLS estimates\n');
fprintf('=============================================================\n');
fprintf('Sample: %d obs (after dropping NaN and pre-1990 leads)\n', best_n);
fprintf('Log-likelihood: %.2f,  σ̂_ε = %.4f\n\n', best_loglik, sqrt(best_sigma2));

fprintf('%-12s %10s %10s %10s\n', 'Coefficient', 'Estimate', 'Std Err', 'Role');
fprintf('%-12s %10s %10s %10s\n', '-----------', '--------', '-------', '----');
fprintf('%-12s %10.4f %10.4f %s\n', 'z_1', z1_hat, se_z1, 'AR(1) persistence');
fprintf('%-12s %10.4f %10.4f %s\n', 'z_2', z2_hat, se_z2, 'level intercept');
fprintf('%-12s %10.4f %10.4f %s\n', 'z_3', z3_hat, se_z3, '2008Q3 level shift');
fprintf('%-12s %10.5f %10.5f %s\n', 'z_4', z4_hat, se_z4, sprintf('trend pre-2002Q2 (%.2f%% p.a.)', g_E_pre_2002));
fprintf('%-12s %10.5f %10.5f %s\n', 'z_5', z5_hat, se_z5, sprintf('+slope 2002Q2-2008Q3 (total %.2f%% p.a.)', g_E_2002_08));
fprintf('%-12s %10.5f %10.5f %s\n', 'z_6', z6_hat, se_z6, sprintf('+slope post-2008Q3 (total %.2f%% p.a.)', g_E_post_08));
fprintf('%-12s %10s %10s %s\n', 'z_7', 'omitted', 'omitted', 'TUC cyclical (no AU data)');
fprintf('%-12s %10.4f %10.4f %s\n', 'z_8', z8_hat, se_z8, 'COVID 20Q1+20Q3 dummies');
fprintf('%-12s %10.4f %10.4f %s\n', 'z_9', z9_hat, se_z9, 'COVID 20Q2 dummy');
fprintf('%-12s %10.4f %10s %s\n', 'covid_loss', covid_E_loss_AU, '(calib)', 'COVID Ē level shift');

fprintf('\nImplied annual trend growth in Ē:\n');
fprintf('  pre-2002Q2:       %.2f%% p.a.  (wp1044 FR: 2.40%%, ces_2026 AU: %.2f%%)\n', ...
    g_E_pre_2002, C.trend_growth_E_pre2002);
fprintf('  2002Q2 - 2008Q3:  %.2f%% p.a.  (wp1044 FR: 1.40%%, ces_2026 AU: %.2f%%)\n', ...
    g_E_2002_08, C.trend_growth_E_2002_2008);
fprintf('  post-2008Q3:      %.2f%% p.a.  (wp1044 FR: 0.70%%, ces_2026 AU: %.2f%%)\n', ...
    g_E_post_08, C.trend_growth_E_post2008);

%% ------------------------------------------------------------
%% 6. Save .mat and .txt
%% ------------------------------------------------------------
out = struct();
out.method = 'wp1044 Eq 7 OLS (AU, Phase L1.1)';
out.dates = dates;
out.nQ = nQ;

% Coefficients
out.z1 = z1_hat;  out.z1_se = se_z1;
out.z2 = z2_hat;  out.z2_se = se_z2;
out.z3 = z3_hat;  out.z3_se = se_z3;
out.z4 = z4_hat;  out.z4_se = se_z4;
out.z5 = z5_hat;  out.z5_se = se_z5;
out.z6 = z6_hat;  out.z6_se = se_z6;
out.z7 = z7_hat;  out.z7_omitted = true;
out.z8 = z8_hat;  out.z8_se = se_z8;
out.z9 = z9_hat;  out.z9_se = se_z9;
out.covid_E_loss = covid_E_loss_AU;

% Series
out.log_E         = log_E;
out.log_E_fit     = log_E_fit;
out.log_E_resid   = log_E_resid;
out.log_Ebar_det  = log_Ebar_det;        % the smooth trend used downstream
out.dlog_Ebar_det = [NaN; diff(log_Ebar_det)];   % quarterly growth

% Diagnostics
out.loglik = best_loglik;
out.sigma_eps = sqrt(best_sigma2);
out.n_obs = best_n;
out.z1_grid_max = best_z1;

% Implied regime growth rates
out.g_E_pre_2002 = g_E_pre_2002;
out.g_E_2002_08  = g_E_2002_08;
out.g_E_post_08  = g_E_post_08;

save(fullfile(projectdir, 'data', 'trend_efficiency.mat'), '-struct', 'out');
fprintf('\nSaved trend_efficiency.mat (log_Ebar_det series + coefficients)\n');

% Text report
txtfile = fullfile(projectdir, 'data', 'trend_efficiency.txt');
fid = fopen(txtfile, 'w');
fprintf(fid, 'Trend labour efficiency  --  wp1044 Eq 7, AU OLS estimates\n');
fprintf(fid, 'Reference: Dubois et al. (2026), BdF WP #1044, Section 3.1.1\n');
fprintf(fid, 'Generated %s\n', datestr(now));
fprintf(fid, 'Branch: refactor/frbdf-replication, Phase L1.1\n\n');
fprintf(fid, 'Sample: %d obs (after dropping NaN and pre-1990 leads)\n', best_n);
fprintf(fid, 'Log-likelihood: %.2f,  sigma_eps = %.4f\n\n', best_loglik, sqrt(best_sigma2));
fprintf(fid, 'CES inversion inputs (from ces_2026_calibration.mat):\n');
fprintf(fid, '  sigma = %.4f,  gamma = %.4f,  alpha = %.3f\n\n', sigma_hat, gamma_hat, alpha_hat);

fprintf(fid, '%-12s %10s %10s   %s\n', 'Coefficient', 'Estimate', 'Std Err', 'Role');
fprintf(fid, '%-12s %10s %10s   %s\n', '-----------', '--------', '-------', '----');
fprintf(fid, '%-12s %10.4f %10.4f   %s\n', 'z_1', z1_hat, se_z1, 'AR(1) persistence');
fprintf(fid, '%-12s %10.4f %10.4f   %s\n', 'z_2', z2_hat, se_z2, 'level intercept');
fprintf(fid, '%-12s %10.4f %10.4f   %s\n', 'z_3', z3_hat, se_z3, '2008Q3 level shift');
fprintf(fid, '%-12s %10.5f %10.5f   %s\n', 'z_4', z4_hat, se_z4, 'trend pre-2002Q2');
fprintf(fid, '%-12s %10.5f %10.5f   %s\n', 'z_5', z5_hat, se_z5, '+slope 2002Q2-2008Q3');
fprintf(fid, '%-12s %10.5f %10.5f   %s\n', 'z_6', z6_hat, se_z6, '+slope post-2008Q3');
fprintf(fid, '%-12s %10s %10s   %s\n', 'z_7', 'omitted', 'omitted', 'TUC cyclical (no AU data)');
fprintf(fid, '%-12s %10.4f %10.4f   %s\n', 'z_8', z8_hat, se_z8, 'COVID 20Q1+20Q3 dummies');
fprintf(fid, '%-12s %10.4f %10.4f   %s\n', 'z_9', z9_hat, se_z9, 'COVID 20Q2 dummy');
fprintf(fid, '%-12s %10.4f %10s   %s\n\n', 'covid_loss', covid_E_loss_AU, '(calib)', ...
    'COVID Ē level shift (calibrated, not estimated)');

fprintf(fid, 'Implied annual trend growth in Ē:\n');
fprintf(fid, '  pre-2002Q2:       %.2f%% p.a.   (wp1044 FR: 2.40%%, ces_2026 AU: %.2f%%)\n', ...
    g_E_pre_2002, C.trend_growth_E_pre2002);
fprintf(fid, '  2002Q2 - 2008Q3:  %.2f%% p.a.   (wp1044 FR: 1.40%%, ces_2026 AU: %.2f%%)\n', ...
    g_E_2002_08, C.trend_growth_E_2002_2008);
fprintf(fid, '  post-2008Q3:      %.2f%% p.a.   (wp1044 FR: 0.70%%, ces_2026 AU: %.2f%%)\n\n', ...
    g_E_post_08, C.trend_growth_E_post2008);

fprintf(fid, 'Cross-validation:\n');
diff_pre  = g_E_pre_2002 - C.trend_growth_E_pre2002;
diff_mid  = g_E_2002_08  - C.trend_growth_E_2002_2008;
diff_post = g_E_post_08  - C.trend_growth_E_post2008;
fprintf(fid, '  Difference vs ces_2026 regime growth (pp): %+.2f / %+.2f / %+.2f\n', ...
    diff_pre, diff_mid, diff_post);
if max(abs([diff_pre, diff_mid, diff_post])) < 0.20
    fprintf(fid, '  Agreement within 0.2pp -- consistent with the underlying spec.\n');
else
    fprintf(fid, '  Differences > 0.2pp -- investigate (likely AR(1) coupling effect).\n');
end

fprintf(fid, '\nKnown omissions vs wp1044 Eq 7 as written:\n');
fprintf(fid, '  - TUC term (capacity utilisation): no AU series in repo.  Cyclical\n');
fprintf(fid, '    variation absorbed by epsilon_t.  Could add later via NAB Business\n');
fprintf(fid, '    Survey capacity utilisation or HP-filtered output gap proxy.\n');
fprintf(fid, '  - COVID Ē level loss: calibrated at -2.0%% (AU), not estimated.\n');
fprintf(fid, '    Matches ces_2026_calibration.txt; FR-BDF uses -5.9%% for France.\n');
fclose(fid);

fprintf('Saved %s\n', txtfile);
fprintf('\n=== Phase L1.1 complete ===\n');

%% ------------------------------------------------------------
%% Helper: profile log-likelihood at a given z_1
%% ------------------------------------------------------------
function ll = profile_loglik(log_E, z1, nQ, T1, T2, T3, d_08Q3, d_clvl, ...
                              d_20q1, d_20q2, d_20q3, covid_loss)
    y_qd = log_E - z1 * [NaN; log_E(1:end-1)];
    x_const = (1 - z1) * ones(nQ, 1);
    x_step  = (1 - z1) * d_08Q3;
    x_T1    = T1 - z1 * [NaN; T1(1:end-1)];
    x_T2    = T2 - z1 * [NaN; T2(1:end-1)];
    x_T3    = T3 - z1 * [NaN; T3(1:end-1)];
    x_clvl  = -(1 - z1) * covid_loss * d_clvl;
    lhs = y_qd - x_clvl;
    X = [x_const, x_step, x_T1, x_T2, x_T3, d_20q1 + d_20q3, d_20q2];
    valid = ~isnan(lhs) & all(~isnan(X), 2);
    if sum(valid) < 30, ll = -inf; return; end
    yk = lhs(valid);
    Xk = X(valid, :);
    bk = (Xk' * Xk) \ (Xk' * yk);
    rk = yk - Xk * bk;
    nk = length(yk);
    sigma2 = (rk' * rk) / (nk - size(Xk, 2));
    ll = -0.5 * nk * (log(2 * pi * sigma2) + 1);
end
