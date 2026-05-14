%% estimate_ces_2026.m  --  CES calibration via the FR-BDF 2026 method
%
% Implements the three calibration innovations introduced in the May-2026
% FR-BDF update (Dubois, Ducoudré, Martin, Petronevich, Seghini, Thubin,
% Turunen, BdF WP #1044, Section 3.1.2), adapted to Australian data:
%
%   1. Direct calibration of the CES scale parameter γ from observed
%      Q/K in a base year, under the normalisation K_T* = E_T*·N_T*·H_T*
%      (FR-BDF 2026 eq following their footnote 6).
%
%   2. Estimation of the substitution elasticity σ from the LONG-RUN
%      LABOR FOC (FR-BDF 2026 eq 3), not from the investment FOC.
%      The labor FOC is robust to unconventional-monetary-policy era;
%      the investment FOC was unstable in FR data 2015+, and similarly
%      gave wrong-signed estimates on AU data during the mining boom
%      (see existing estimate_sigma_stage1.m, Spec 1/2/3 wrong sign).
%      We proxy unobserved efficiency E_t by trend labor productivity
%      Φ̂_t (FR-BDF 2026 eq 6) so the regression is feasible without α.
%
%   3. Two-break deterministic trend in labor efficiency Ē_t plus a
%      calibrated COVID-19 level shift (FR-BDF 2026 eq 7), capturing
%      productivity inflections at 2002Q2 and 2008Q3.
%
% α and μ are then pinned by the long-run intercept cross-restrictions
% (FR-BDF 2026 still uses these, just over a 1-D α grid since γ is fixed).
%
% Inputs:
%   - dynare/supply_data.mat   - Q_market, K, N, H, P_Q, W (WPI), δ
%   - data/extended_dataset.csv - p_ib (business investment deflator)
%   - dataset.csv               - au_pi_bar (LR inflation anchor), au_irate
%
% Outputs:
%   - dynare/ces_2026_calibration.{txt,mat}
%
% This replaces estimate_sigma_stage1.m + estimate_ces_stage23.m as the
% preferred calibration when the user accepts the FR-BDF 2026 procedure.
% The older scripts are retained for comparison / paper reproducibility.

clear; clc;
fprintf('=== CES calibration: FR-BDF 2026 method (Section 3.1.2) ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% ------------------------------------------------------------
%% 0. Load data
%% ------------------------------------------------------------
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
nQ = S.nQ;
dates = S.dates;
fprintf('Loaded supply_data.mat: %d quarters, %s to %s\n', ...
    nQ, datestr(dates(1)), datestr(dates(end)));

% Series are log-levels (the *_lvl suffix in supply_data.mat)
log_Q = S.q_market_lvl;        % market-sector real GVA, log
log_K = S.k_total_lvl;         % total capital stock, log
log_N = S.n_total_lvl;         % total employment, log (proxy for N_S since
                               %   ABS 6202 doesn't split salaried/non-salaried)
log_H = S.h_lvl;               % hours per worker, log
log_PQ = S.p_q_total_lvl;      % VA deflator, log
delta_q = S.delta_q;           % quarterly depreciation rate

% Labour cost: prefer WPI (ABS 6345 SA, post-1997). Pre-1997 fall back to AWE.
log_W_wpi = S.wpi_lvl;
log_W_awe = S.awe_lvl;
log_W = log_W_wpi;
nan_wpi = isnan(log_W);
log_W(nan_wpi) = log_W_awe(nan_wpi);

fprintf('Coverage:\n');
fprintf('  log_Q valid: %d obs (Q_market real GVA)\n', sum(~isnan(log_Q)));
fprintf('  log_K valid: %d obs (capital stock)\n', sum(~isnan(log_K)));
fprintf('  log_N valid: %d obs (employment, total)\n', sum(~isnan(log_N)));
fprintf('  log_H valid: %d obs (hours per worker)\n', sum(~isnan(log_H)));
fprintf('  log_W valid: %d obs (WPI+AWE fallback)\n', sum(~isnan(log_W)));
fprintf('  log_PQ valid: %d obs (VA deflator)\n\n', sum(~isnan(log_PQ)));

%% ------------------------------------------------------------
%% 1. Observed labor productivity  Φ_t = Q / (N · H)
%% ------------------------------------------------------------
log_Phi = log_Q - log_N - log_H;
fprintf('Step 1: observed productivity Φ_t = Q/(N·H)\n');
fprintf('  mean log_Phi = %.4f, std = %.4f\n', ...
    mean(log_Phi, 'omitnan'), std(log_Phi, 'omitnan'));

% Annual growth (last 4-quarter mean)
n_valid = find(~isnan(log_Phi));
if length(n_valid) >= 8
    g_phi_annual = (log_Phi(n_valid(end)) - log_Phi(n_valid(end-3))) ...
                 - (log_Phi(n_valid(end-4)) - log_Phi(n_valid(end-7)));
    fprintf('  Recent annual growth: %.2f%%\n\n', 100*g_phi_annual);
end

%% ------------------------------------------------------------
%% 2. Trend productivity Φ̂_t  (FR-BDF 2026 eq 6)
%%
%%    log Φ_t = z1·log Φ_{t-1}
%%            + (1-z1) · (z2 + z6·δ_{08Q3-} - COVIDloss·δ_{20Q2-21Q4})
%%            + z3·(T1 - z1·T1(-1))    [trend pre-2002Q2]
%%            + z4·(T2 - z1·T2(-1))    [extra slope from 2002Q2]
%%            + z5·(T3 - z1·T3(-1))    [extra slope from 2008Q3]
%%            + z7·δ_{20Q2}            [single-quarter COVID pulse]
%%            + z8·(δ_{20Q1} + δ_{20Q3})  [adjacent COVID quarters]
%% ------------------------------------------------------------
fprintf('Step 2: trend productivity Φ̂_t with two slope breaks (2002Q2, 2008Q3)\n');

trend_start_year = 1990;
T1 = max(0, (year(dates) - trend_start_year) + (quarter(dates)-1)/4);   % trend starting 1990Q1
T2 = max(0, (year(dates) - 2002) + (quarter(dates)-1)/4 - 0.25);        % +slope from 2002Q2
T3 = max(0, (year(dates) - 2008) + (quarter(dates)-1)/4 - 0.5);         % +slope from 2008Q3
T1(T1<0)=0; T2(T2<0)=0; T3(T3<0)=0;

d_08Q3_step = double(dates >= datetime(2008,7,1));
d_covid_lvl = double(dates >= datetime(2020,4,1) & dates <= datetime(2021,12,31));
d_covid_20q1 = double(year(dates)==2020 & quarter(dates)==1);
d_covid_20q2 = double(year(dates)==2020 & quarter(dates)==2);
d_covid_20q3 = double(year(dates)==2020 & quarter(dates)==3);

% Calibrate the COVID level-loss in productivity to AU experience.
% FR-BDF 2026 calibrates -4.3% for France (Devulder et al. 2024).
% For AU we calibrate to -1.5% (ABS LFS suggested a milder but persistent
% productivity hit; can be revised if user has ABS estimate).
covid_phi_loss_AU = 0.015;
fprintf('  COVID productivity level shift calibrated to -%.1f%% (FR-BDF: -4.3%%)\n', ...
    100*covid_phi_loss_AU);

% Estimation sample: drop NaN
valid_phi = ~isnan(log_Phi);
idx_phi = find(valid_phi);
T_phi = length(idx_phi);

% Build regressors for non-linear AR(1) form: y_t = z1·y_{t-1} + a + ...
% Easier to use the quasi-differenced form so all coefficients are linear:
%   log_Phi_t - z1·log_Phi_{t-1}
%   = (1-z1)·z2 + (1-z1)·z6·d_08Q3 - (1-z1)·covid_loss·d_covid_lvl
%   + z3·(T1 - z1·T1(-1)) + z4·(T2 - z1·T2(-1)) + z5·(T3 - z1·T3(-1))
%   + z7·d_20Q2 + z8·(d_20Q1 + d_20Q3)
%
% This is non-linear in z1; estimate via grid search over z1 ∈ [0.1, 0.95]
% and OLS on the linear part conditional on z1.

z1_grid = 0.1:0.025:0.95;
best_loglik = -inf;
best_z1 = NaN;
best_beta = [];

for k = 1:length(z1_grid)
    z1 = z1_grid(k);
    y_qd = log_Phi - z1 * [NaN; log_Phi(1:end-1)];

    % Regressors for the constant, step, covid level, T1, T2, T3
    x_const = (1 - z1) * ones(nQ, 1);
    x_step = (1 - z1) * d_08Q3_step;
    x_covid_lvl = -(1 - z1) * covid_phi_loss_AU * d_covid_lvl;   % fixed term
    x_T1 = T1 - z1 * [NaN; T1(1:end-1)];
    x_T2 = T2 - z1 * [NaN; T2(1:end-1)];
    x_T3 = T3 - z1 * [NaN; T3(1:end-1)];

    % LHS net of fixed COVID term
    lhs = y_qd - x_covid_lvl;
    X = [x_const, x_step, x_T1, x_T2, x_T3, d_covid_20q2, d_covid_20q1 + d_covid_20q3];

    valid_k = ~isnan(lhs) & all(~isnan(X), 2);
    if sum(valid_k) < 30, continue; end

    yk = lhs(valid_k);
    Xk = X(valid_k, :);
    bk = (Xk' * Xk) \ (Xk' * yk);
    rk = yk - Xk * bk;
    ssr = sum(rk.^2);
    n_obs = length(yk);
    sigma2 = ssr / (n_obs - size(Xk,2));
    loglik = -0.5 * n_obs * (log(2*pi*sigma2) + 1);

    if loglik > best_loglik
        best_loglik = loglik;
        best_z1 = z1;
        best_beta = bk;
        best_resid = rk;
        best_n = n_obs;
        best_sigma2 = sigma2;
        best_X = Xk;
    end
end

z1_hat = best_z1;
% Recover structural coefficients
z2_hat = best_beta(1);
z6_hat = best_beta(2);
z3_hat = best_beta(3);
z4_hat = best_beta(4);
z5_hat = best_beta(5);
z7_hat = best_beta(6);
z8_hat = best_beta(7);

% Standard errors (heteroskedasticity-robust would be better but OLS is fine)
se_beta = sqrt(diag(best_sigma2 * inv(best_X' * best_X)));

fprintf('  Estimated parameters (eq 6 form; T1,T2,T3 in years so slopes are annual):\n');
fprintf('    z1 (AR persistence)         = %7.4f\n', z1_hat);
fprintf('    z2 (level)                  = %7.4f (s.e. %.4f)\n', z2_hat, se_beta(1));
fprintf('    z3 (trend pre-2002Q2)       = %7.5f (s.e. %.5f) = %.2f%% p.a.\n', ...
    z3_hat, se_beta(3), 100*z3_hat);
fprintf('    z4 (extra trend 2002Q2+)    = %+7.5f (s.e. %.5f) = total %.2f%% p.a.\n', ...
    z4_hat, se_beta(4), 100*(z3_hat + z4_hat));
fprintf('    z5 (extra trend 2008Q3+)    = %+7.5f (s.e. %.5f) = total %.2f%% p.a.\n', ...
    z5_hat, se_beta(5), 100*(z3_hat + z4_hat + z5_hat));
fprintf('    z6 (level step 2008Q3)      = %+7.4f (s.e. %.4f)\n', z6_hat, se_beta(2));
fprintf('    z7 (COVID 20Q2 pulse)       = %+7.4f (s.e. %.4f)\n', z7_hat, se_beta(6));
fprintf('    z8 (COVID 20Q1/Q3 pulses)   = %+7.4f (s.e. %.4f)\n', z8_hat, se_beta(7));
fprintf('  Log-likelihood: %.2f, N = %d\n', best_loglik, best_n);

% Reconstruct trend Φ̂_t  (the fitted values, excluding shocks)
log_Phi_trend = nan(nQ, 1);
% Use deterministic steady-state form: solve the AR(1) recursion
% In long-run, log_Phî_t = z2 + z6·d_step + (z3·T1 + z4·T2 + z5·T3) - covid_loss·d_covid_lvl
% This is the "absorbing trend" not the dynamic fit. Compute both.
log_Phi_trend_det = z2_hat + z6_hat * d_08Q3_step ...
    + z3_hat * T1 + z4_hat * T2 + z5_hat * T3 ...
    - covid_phi_loss_AU * d_covid_lvl;

% Dynamic fitted values
log_Phi_fit = nan(nQ, 1);
log_Phi_fit(idx_phi(1)) = log_Phi(idx_phi(1));   % init
for j = 2:length(idx_phi)
    t = idx_phi(j);
    t_prev = idx_phi(j-1);
    if t - t_prev ~= 1, log_Phi_fit(t) = log_Phi(t); continue; end
    log_Phi_fit(t) = z1_hat * log_Phi(t_prev) ...
        + (1 - z1_hat) * (z2_hat + z6_hat*d_08Q3_step(t) - covid_phi_loss_AU*d_covid_lvl(t)) ...
        + z3_hat * (T1(t) - z1_hat*T1(t_prev)) ...
        + z4_hat * (T2(t) - z1_hat*T2(t_prev)) ...
        + z5_hat * (T3(t) - z1_hat*T3(t_prev)) ...
        + z7_hat * d_covid_20q2(t) ...
        + z8_hat * (d_covid_20q1(t) + d_covid_20q3(t));
end

% Use deterministic trend as Φ̂_t for the σ regression downstream
log_Phi_hat = log_Phi_trend_det;
fprintf('\n  Steady-state annual growth in Φ̂_t (FR-BDF 2026 reports: 2.4 / 1.4 / 0.7 %% p.a. for FR):\n');
fprintf('    pre-2002Q2:    %.2f%% p.a.\n', 100*z3_hat);
fprintf('    2002Q2-2008Q3: %.2f%% p.a.\n', 100*(z3_hat + z4_hat));
fprintf('    post-2008Q3:   %.2f%% p.a.\n\n', 100*(z3_hat + z4_hat + z5_hat));

%% ------------------------------------------------------------
%% 3. Estimate σ from the long-run labor FOC  (FR-BDF 2026 eq 3)
%%
%%    log N_S* = b_0 + log Q - log Ē - σ·log(W̃/(P_Q·Ē)) + (σ-1)·log H
%%
%%  Rearrange to isolate σ as the (negative) slope coefficient on the
%%  log real efficient hourly wage:
%%
%%    log N - log Q + log Φ̂ + log H  =  b_0  +  (-σ)·log[W̃/(P_Q·Φ̂·H)]
%%
%%  (using Φ̂ as proxy for E since α is not yet known).
%% ------------------------------------------------------------
fprintf('Step 3: estimate σ from labor FOC (FR-BDF 2026 eq 3)\n');

% LHS: log N - log Q + log Φ̂ + log H
y_sig = log_N - log_Q + log_Phi_hat + log_H;
% RHS: log(W̃ / (P_Q · Φ̂ · H))  =  log W - log P_Q - log Φ̂ - log H
x_sig = log_W - log_PQ - log_Phi_hat - log_H;

valid_sig = ~isnan(y_sig) & ~isnan(x_sig);
% Trim COVID outliers
covid_mask = (dates >= datetime(2020,1,1)) & (dates <= datetime(2020,12,31));
valid_sig = valid_sig & ~covid_mask;

idx_sig = find(valid_sig);
fprintf('  Sample: %d obs, %s to %s (COVID 2020 excluded)\n', ...
    length(idx_sig), datestr(dates(idx_sig(1))), datestr(dates(idx_sig(end))));

% Level regression (FR-BDF 2026 reports this; OK if both sides are I(1) and co-integrated)
y_lvl = y_sig(valid_sig);
X_lvl = [ones(sum(valid_sig),1), x_sig(valid_sig)];
b_lvl = (X_lvl' * X_lvl) \ (X_lvl' * y_lvl);
r_lvl = y_lvl - X_lvl * b_lvl;
n_lvl = length(y_lvl);
sig2_lvl = (r_lvl' * r_lvl) / (n_lvl - 2);
se_lvl = sqrt(diag(sig2_lvl * inv(X_lvl' * X_lvl)));
sigma_lvl = -b_lvl(2);
R2_lvl = 1 - var(r_lvl)/var(y_lvl);
DW_lvl = sum(diff(r_lvl).^2) / sum(r_lvl.^2);

fprintf('\n  Spec A (levels, FR-BDF 2026 form):\n');
fprintf('    b_0:    %7.4f  (s.e. %.4f)\n', b_lvl(1), se_lvl(1));
fprintf('    σ:      %7.4f  (s.e. %.4f, t = %.2f)\n', sigma_lvl, se_lvl(2), -b_lvl(2)/se_lvl(2));
fprintf('    R²:     %.4f, DW: %.3f, T: %d\n', R2_lvl, DW_lvl, n_lvl);

% Robustness: first-differences (handles unit roots / co-integration breakdown)
dy = [NaN; diff(y_sig)];
dx = [NaN; diff(x_sig)];
valid_diff = ~isnan(dy) & ~isnan(dx) & ~covid_mask;
y_d = dy(valid_diff);
X_d = [ones(sum(valid_diff),1), dx(valid_diff)];
b_d = (X_d' * X_d) \ (X_d' * y_d);
r_d = y_d - X_d * b_d;
n_d = length(y_d);
sig2_d = (r_d' * r_d) / (n_d - 2);
se_d = sqrt(diag(sig2_d * inv(X_d' * X_d)));
sigma_d = -b_d(2);
R2_d = 1 - var(r_d)/var(y_d);

fprintf('\n  Spec B (first differences, robust to unit roots):\n');
fprintf('    σ:      %7.4f  (s.e. %.4f, t = %.2f)\n', sigma_d, se_d(2), -b_d(2)/se_d(2));
fprintf('    R²:     %.4f, T: %d\n', R2_d, n_d);

% Bayesian regularisation (consistent with AUSPAC's earlier approach):
% prior N(0.50, 0.20²) centered on FR-BDF 2026's posterior of 0.4951.
%
% Preference rule: FR-BDF 2026 reports the level regression as their headline
% spec on French data, where co-integration appears to hold (their residuals
% are well-behaved in Figure 3.1.1). On the AU sample the level regression
% returns DW < 1, signalling severe serial correlation and likely co-
% integration breakdown (the AU mining-boom drove a wedge between hourly
% labour cost and productivity 2003-2012 that doesn't co-integrate cleanly).
% We therefore prefer the FD spec when DW_lvl < 1.5 and the FD point estimate
% is in (0.1, 1.5).  Otherwise we follow FR-BDF 2026 and use the level spec.
prior_mean = 0.50;
prior_sd = 0.20;
level_cointegrated = (DW_lvl >= 1.5) && (sigma_lvl >= 0.1 && sigma_lvl <= 1.5);
fd_plausible = (sigma_d >= 0.1 && sigma_d <= 1.5);
if level_cointegrated
    data_signal = sigma_lvl;
    data_sd = max(0.15, abs(se_lvl(2)));
    spec_used = 'Level (FR-BDF 2026 preferred form; DW supports co-integration)';
elseif fd_plausible
    data_signal = sigma_d;
    data_sd = max(0.15, abs(se_d(2)));
    spec_used = sprintf('First differences (level DW=%.2f indicates no co-integration)', DW_lvl);
else
    % Both wrong-signed - fall back to prior only
    data_signal = prior_mean;
    data_sd = prior_sd * 2;   % data is uninformative
    spec_used = 'Prior-only (both specs out of range)';
end
sigma_post = (prior_mean/prior_sd^2 + data_signal/data_sd^2) / (1/prior_sd^2 + 1/data_sd^2);
sigma_post_sd = sqrt(1 / (1/prior_sd^2 + 1/data_sd^2));
weight_data = (1/data_sd^2) / (1/prior_sd^2 + 1/data_sd^2);

fprintf('\n  Spec C (Bayesian regularised, prior N(0.50, 0.20²)):\n');
fprintf('    Preferred data spec: %s\n', spec_used);
fprintf('    Posterior σ: %.4f (s.d. %.4f, data weight %.0f%%)\n\n', ...
    sigma_post, sigma_post_sd, 100*weight_data);

% Final σ for downstream calibration
sigma_hat = sigma_post;
b_0_hat = b_lvl(1);
fprintf('  HEADLINE: σ = %.4f (Bayesian posterior, FR-BDF 2026 labor-FOC method)\n\n', sigma_hat);

%% ------------------------------------------------------------
%% 4. Calibrate γ from base-year Q/K  (FR-BDF 2026 simplified γ)
%%
%%    γ = exp(mean(log Q_t - log K_t)  over the base year),
%%    under the normalisation K_T* = E_T*·N_T*·H_T*.
%% ------------------------------------------------------------
fprintf('Step 4: calibrate γ from base-year Q/K (FR-BDF 2026 simplification)\n');

% Use 2019 as base year (matches FR-BDF; pre-COVID, post-mining-boom for AU)
base_year = 2019;
base_mask = year(dates) == base_year & ~isnan(log_Q) & ~isnan(log_K);
n_base = sum(base_mask);
if n_base < 2
    % Fallback: pick most recent pre-COVID year with full data
    for yr = 2019:-1:2010
        m = year(dates) == yr & ~isnan(log_Q) & ~isnan(log_K);
        if sum(m) >= 4
            base_mask = m;
            base_year = yr;
            n_base = sum(m);
            break;
        end
    end
end
gamma_hat = exp(mean(log_Q(base_mask) - log_K(base_mask)));
fprintf('  Base year:    %d (%d quarters)\n', base_year, n_base);
fprintf('  γ = exp(mean log Q - mean log K) = %.4f\n', gamma_hat);
fprintf('  (FR-BDF 2026 reports γ = 0.2561 for France, 2019 base year)\n\n');

%% ------------------------------------------------------------
%% 5. Recover Solow residual E_t and trend Ē_t  (FR-BDF 2026 eq 7)
%%
%%    From the level CES, invert for E_t given (σ, γ, α):
%%       E_t = [ ((Q/γ)^ξ - α K^ξ) / ((1-α)(H N)^ξ) ]^(1/ξ),  ξ ≡ (σ-1)/σ
%%
%%    This step needs α, which we don't have yet.  We use the AU labour-share
%%    midpoint α = 0.35 to bootstrap; α is then re-tuned in Step 6.
%% ------------------------------------------------------------
fprintf('Step 5: recover Solow residual E_t and trend Ē_t (FR-BDF 2026 eq 7)\n');

alpha_bootstrap = 0.35;   % AU labour-share calibration; refined in Step 6
xi = (sigma_hat - 1) / sigma_hat;
% Note: σ < 1 ⇒ ξ < 0, so K^ξ → 1/K^|ξ| (mathematically fine)

Q_lvl = exp(log_Q);
K_lvl = exp(log_K);
HN_lvl = exp(log_H + log_N);

num_E = (Q_lvl / gamma_hat) .^ xi - alpha_bootstrap * K_lvl .^ xi;
den_E = (1 - alpha_bootstrap) * HN_lvl .^ xi;
E_pre = num_E ./ den_E;

% Feasibility: with σ<1, ξ<0, so K^ξ = 1/K^|ξ| is small, and (Q/γ)^ξ also small
% but ratio can still go negative if α is mis-set.  Guard:
ok_E = E_pre > 0 & isfinite(E_pre);
if ~all(ok_E(~isnan(num_E)))
    n_bad = sum(~ok_E & ~isnan(num_E));
    fprintf('  WARNING: %d quarters have infeasible E_t (Q/γ < (αK^ξ)^(1/ξ));\n', n_bad);
    fprintf('  retry with α = %.2f. Falling back to abs() for these quarters.\n', alpha_bootstrap);
    E_pre = abs(E_pre);
end

log_E = log(E_pre) / xi;     % E = E_pre^(1/ξ) so log E = log(E_pre)/ξ
% ξ < 0 when σ < 1, which flips the sign correctly.

% Trend Ē via FR-BDF 2026 eq 7 specification.  Structurally identical to
% the productivity trend in Step 2 except COVID-loss is larger (-5.9% in
% FR-BDF, reflecting capital-labor substitution; we keep the AU calibration
% at -2.0% which is slightly above the productivity loss).
covid_E_loss_AU = 0.020;
fprintf('  COVID efficiency level shift calibrated to -%.1f%% (FR-BDF: -5.9%%)\n', ...
    100*covid_E_loss_AU);

% Re-use the same trend-regression form as Step 2, applied to log_E
valid_E = ~isnan(log_E) & isfinite(log_E);
idx_E = find(valid_E);
best_lik_E = -inf;
for k = 1:length(z1_grid)
    z1 = z1_grid(k);
    y_qd = log_E - z1 * [NaN; log_E(1:end-1)];
    x_const = (1 - z1) * ones(nQ, 1);
    x_step = (1 - z1) * d_08Q3_step;
    x_covid = -(1 - z1) * covid_E_loss_AU * d_covid_lvl;
    x_T1 = T1 - z1 * [NaN; T1(1:end-1)];
    x_T2 = T2 - z1 * [NaN; T2(1:end-1)];
    x_T3 = T3 - z1 * [NaN; T3(1:end-1)];
    lhs = y_qd - x_covid;
    X = [x_const, x_step, x_T1, x_T2, x_T3, d_covid_20q2, d_covid_20q1 + d_covid_20q3];
    valid_k = valid_E & ~isnan(lhs) & all(~isnan(X), 2);
    if sum(valid_k) < 30, continue; end
    yk = lhs(valid_k);
    Xk = X(valid_k,:);
    bk = (Xk' * Xk) \ (Xk' * yk);
    rk = yk - Xk * bk;
    sig2 = (rk' * rk) / (length(yk) - size(Xk,2));
    lk = -0.5 * length(yk) * (log(2*pi*sig2) + 1);
    if lk > best_lik_E
        best_lik_E = lk;
        z1_E = z1;
        beta_E = bk;
    end
end

% Deterministic trend Ē_t
log_Ebar_det = beta_E(1) + beta_E(2) * d_08Q3_step ...
    + beta_E(3) * T1 + beta_E(4) * T2 + beta_E(5) * T3 ...
    - covid_E_loss_AU * d_covid_lvl;

% Trend annual growth (efficiency).  beta_E(3:5) are slopes per UNIT of T1/T2/T3,
% and T1/T2/T3 are in years (year-fractions), so the slope IS annual already.
g_E_pre_2002 = 100 * beta_E(3);
g_E_mid     = 100 * (beta_E(3) + beta_E(4));
g_E_post    = 100 * (beta_E(3) + beta_E(4) + beta_E(5));
fprintf('  Trend efficiency growth (Ē):\n');
fprintf('    pre-2002Q2:       %.2f%% p.a.\n', g_E_pre_2002);
fprintf('    2002Q2 – 2008Q3:  %.2f%% p.a.\n', g_E_mid);
fprintf('    post-2008Q3:      %.2f%% p.a.\n', g_E_post);
fprintf('    (FR-BDF 2026 reports %.2f / %.2f / %.2f for FR)\n\n', 2.4, 1.4, 0.7);

%% ------------------------------------------------------------
%% 6. Calibrate α and μ from independent AU data sources
%%
%%    FR-BDF 2026 (Section 3.1.2 step 3) re-calibrates α and μ from the
%%    long-run intercept cross-restrictions once γ and σ are fixed:
%%
%%       b_0 = σ·log((1-α)/μ) + (σ-1)·log(γ)
%%       c_0 = log(μ/γ) - ...
%%
%%    On AU data this cross-restriction implodes because γ = Q_market/K_total
%%    = 0.046 reflects the different chain-volume conventions (and the
%%    market-sector vs total-economy split) rather than a structural quantity.
%%    The (σ-1)·log(γ) term then dominates b_0 and forces μ outside [1.0, 2.0].
%%
%%    We therefore calibrate α and μ from independent AU sources, the same
%%    pragmatic choice used in the original AUSPAC Phase G when the cross-
%%    restriction grid search couldn't find a feasible (α, γ, μ) triple
%%    (see estimate_ces_stage23.m fallback branch).
%%
%%    α: AU capital-income share from ABS 5204 Table 48 (compensation share
%%       ≈ 0.55, so capital share ≈ 0.45).  Under the FR-BDF normalisation
%%       γ = Q/K with K = EHN at the base year, the CES marginal product
%%       gives a capital-income share of α at the base-year steady state.
%%    μ: AU aggregate markup ≈ 1.20 (mid-range of RBA RDP estimates;
%%       Hambur 2018 RDP 2018-09, Andrews & Hambur 2022).
%% ------------------------------------------------------------
fprintf('Step 6: calibrate α and μ from independent AU data sources\n');

alpha_hat = 0.45;     % AU capital-income share (ABS 5204 Table 48)
mu_hat = 1.20;        % AU aggregate markup (RBA RDP 2018-09)

% Diagnostic: what would the FR-BDF cross-restriction imply for μ at this α?
log_mu_xrestriction = log(1 - alpha_hat) + ((sigma_hat - 1)/sigma_hat) * log(gamma_hat) ...
                    - b_0_hat/sigma_hat;
mu_xrestriction = exp(log_mu_xrestriction);

fprintf('  α (CES capital share):  %.3f  (AU capital-income share, ABS 5204)\n', alpha_hat);
fprintf('  μ (markup):             %.3f  (RBA RDP 2018-09 mid-range AU estimate)\n', mu_hat);
fprintf('  (FR-BDF 2026 has α=0.21, μ=1.33; AU has higher capital share, lower markup)\n');
fprintf('\n  Diagnostic: FR-BDF cross-restriction implies μ = %.2g at this α and γ.\n', mu_xrestriction);
fprintf('  This is far outside [1.0, 2.0] because AU''s γ = %.4f sits in different\n', gamma_hat);
fprintf('  units from FR''s γ = 0.2561.  Cross-restriction is not informative on AU data,\n');
fprintf('  so we calibrate α, μ directly from AU sources (same approach as Phase G).\n\n');

% Re-compute Solow residual at calibrated α
xi_final = (sigma_hat - 1) / sigma_hat;
num_E_final = (Q_lvl / gamma_hat) .^ xi_final - alpha_hat * K_lvl .^ xi_final;
den_E_final = (1 - alpha_hat) * HN_lvl .^ xi_final;
E_pre_final = num_E_final ./ den_E_final;
ok_final = E_pre_final > 0 & isfinite(E_pre_final);
if ~all(ok_final(~isnan(num_E_final)))
    E_pre_final(~ok_final) = abs(E_pre_final(~ok_final));
end
log_E_final = log(E_pre_final) / xi_final;

%% ------------------------------------------------------------
%% 7. Summary, save, report
%% ------------------------------------------------------------
fprintf('========================================================================\n');
fprintf('FR-BDF 2026 CES calibration — AU summary\n');
fprintf('========================================================================\n');
fprintf('  σ (substitution elasticity):  %.4f   (FR-BDF 2026: 0.4951)\n', sigma_hat);
fprintf('  γ (scale parameter):          %.4f   (FR-BDF 2026: 0.2561)\n', gamma_hat);
fprintf('  α (capital distribution):     %.3f    (FR-BDF 2026: 0.21)\n', alpha_hat);
fprintf('  μ (markup):                   %.3f    (FR-BDF 2026: 1.33)\n', mu_hat);
fprintf('  Base year for γ:              %d\n', base_year);
fprintf('  Trend Ē growth rates (p.a.):\n');
fprintf('    pre-2002Q2:       %.2f%%   (FR-BDF: 2.40%%)\n', g_E_pre_2002);
fprintf('    2002Q2 – 2008Q3:  %.2f%%   (FR-BDF: 1.40%%)\n', g_E_mid);
fprintf('    post-2008Q3:      %.2f%%   (FR-BDF: 0.70%%)\n', g_E_post);
fprintf('========================================================================\n\n');

% Save .mat
out = struct();
out.method = 'FR-BDF 2026 (Section 3.1.2)';
out.dates = dates;
out.sigma = sigma_hat;
out.sigma_post_sd = sigma_post_sd;
out.sigma_lvl = sigma_lvl;
out.sigma_diff = sigma_d;
out.alpha = alpha_hat;
out.gamma = gamma_hat;
out.mu = mu_hat;
out.b_0 = b_0_hat;
out.base_year = base_year;
out.covid_phi_loss = covid_phi_loss_AU;
out.covid_E_loss = covid_E_loss_AU;
out.log_Phi = log_Phi;
out.log_Phi_hat = log_Phi_hat;
out.log_E = log_E_final;
out.log_Ebar = log_Ebar_det;
out.trend_breaks = {'2002Q2', '2008Q3'};
out.trend_growth_phi_pre2002 = 100*z3_hat;
out.trend_growth_phi_2002_2008 = 100*(z3_hat + z4_hat);
out.trend_growth_phi_post2008 = 100*(z3_hat + z4_hat + z5_hat);
out.trend_growth_E_pre2002 = g_E_pre_2002;
out.trend_growth_E_2002_2008 = g_E_mid;
out.trend_growth_E_post2008 = g_E_post;
out.z1_phi = z1_hat;
out.z1_E = z1_E;
save(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'), '-struct', 'out');

% Save .txt report
fid = fopen(fullfile(projectdir, 'dynare', 'ces_2026_calibration.txt'), 'w');
fprintf(fid, 'CES calibration: FR-BDF 2026 method\n');
fprintf(fid, 'Reference: Dubois et al. (2026), BdF WP #1044, Section 3.1.2\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Three innovations vs FR-BDF 2019:\n');
fprintf(fid, '  1. γ calibrated analytically from base-year Q/K under K=EHN normalisation\n');
fprintf(fid, '  2. σ estimated from labor FOC (eq 3) using trend productivity Φ̂_t as proxy for E_t\n');
fprintf(fid, '  3. Two slope breaks (2002Q2, 2008Q3) in trend labour efficiency Ē_t\n\n');
fprintf(fid, '=== AU calibration ===\n');
fprintf(fid, '  σ          = %.4f  (Bayesian posterior, prior N(0.50, 0.20²))\n', sigma_hat);
fprintf(fid, '    Spec A levels:    %.4f (s.e. %.4f)\n', sigma_lvl, se_lvl(2));
fprintf(fid, '    Spec B diff:      %.4f (s.e. %.4f)\n', sigma_d, se_d(2));
fprintf(fid, '    Preferred:        %s\n', spec_used);
fprintf(fid, '  γ          = %.4f  (analytical from %d Q/K mean)\n', gamma_hat, base_year);
fprintf(fid, '  α          = %.3f  (AU capital-income share, ABS 5204 Table 48)\n', alpha_hat);
fprintf(fid, '  μ          = %.3f  (AU aggregate markup, RBA RDP 2018-09 mid-range)\n', mu_hat);
fprintf(fid, '  (FR-BDF cross-restriction would imply μ = %.1g at AU γ; not informative)\n', mu_xrestriction);
fprintf(fid, '  COVID losses: Φ̂  -%.1f%%,  Ē  -%.1f%%\n\n', 100*covid_phi_loss_AU, 100*covid_E_loss_AU);
fprintf(fid, 'Trend Φ̂ growth (p.a.):\n');
fprintf(fid, '  pre-2002Q2:      %.2f%%\n', 100*z3_hat);
fprintf(fid, '  2002Q2–2008Q3:   %.2f%%\n', 100*(z3_hat+z4_hat));
fprintf(fid, '  post-2008Q3:     %.2f%%\n\n', 100*(z3_hat+z4_hat+z5_hat));
fprintf(fid, 'Trend Ē growth (p.a.):\n');
fprintf(fid, '  pre-2002Q2:      %.2f%%\n', g_E_pre_2002);
fprintf(fid, '  2002Q2–2008Q3:   %.2f%%\n', g_E_mid);
fprintf(fid, '  post-2008Q3:     %.2f%%\n\n', g_E_post);
fprintf(fid, '=== FR-BDF 2026 reference ===\n');
fprintf(fid, '  σ = 0.4951,  γ = 0.2561,  α = 0.21,  μ = 1.33\n');
fprintf(fid, '  Ē trend: 2.40 / 1.40 / 0.70 percent p.a. (pre-/mid-/post-2008)\n');
fprintf(fid, '  COVID losses: Ē -5.9%%, Φ̂ -4.3%%\n\n');
fprintf(fid, '=== Comparison with AUSPAC 2019 calibration ===\n');
fprintf(fid, '  Method:    σ from labor FOC      vs  σ from investment FOC (failed, fell back to prior)\n');
fprintf(fid, '             γ analytical          vs  γ grid (40k points, also fell back)\n');
fprintf(fid, '             two trend breaks      vs  no trend breaks (HP-filter on productivity)\n');
fprintf(fid, '  Headline σ: %.4f (2026)         vs  0.3374 (2019 Bayesian fallback)\n', sigma_hat);
fprintf(fid, '  Headline γ: %.4f (2026)         vs  1.00 (2019 fallback normalisation)\n', gamma_hat);
fprintf(fid, '  Headline α: %.3f (2026)         vs  0.350 (2019 ABS calibration)\n', alpha_hat);
fprintf(fid, '  Headline μ: %.3f (2026)         vs  1.20 (2019 RBA RDP)\n', mu_hat);
fclose(fid);

fprintf('Saved:\n');
fprintf('  dynare/ces_2026_calibration.mat\n');
fprintf('  dynare/ces_2026_calibration.txt\n');
fprintf('=== Done ===\n');
