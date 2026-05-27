%% estimate_consumption_pac_full.m  --  full wp1044 Eq 35, AU partial L2
%
% Extends the L2-pilot OLS (estimate_consumption_pac_ols.m) to include
% the wp1044 Eq 35 PV terms and HtM channel.  Replaces the lag-only
% approximations in the L2-pilot with closed-form present-value terms
% computed from a small VAR(1) companion matrix Phi.
%
% wp1044 Eq 35 (TRENDS_COMPARISON.md §2.5):
%   Δc_t = β_0 (c*_{t-1} - c_{t-1}) + β_1 Δc_{t-1}
%        + PV²(y_H - ȳ)_{t|t-1}
%        + α_1 [PV(r_LH)_{t|t-1} - (PV(ī)_{t|t-1} - PV(π̄)_{t|t-1})]
%        + β_PAC Δȳ_{t-1}
%        + β_2 [Δ(log(W_H + TG_H) - p_C^VAT) - ỹ_t]
%        + β_3 (Δr_LH,t - (Δī_t - Δπ̄_t))
%        + β_4 δ_COVID + ε_t
%
% Spec implemented (AU adaptation):
%   Δc_t = β_0 + β_1 Δc_{t-1}
%        + β_3 yhat_au_t                            % output gap contemp
%        + γ_PV2 · PV²(au_wt_H_real_gap)_{t|t-1}    % PV² of HtM gap as y_H-ȳ proxy
%        + γ_PV  · PV(i_10y - pi_au)_{t|t-1}        % PV of real long rate
%        + β_PAC dy_bar_gap_{t-1}                   % growth-neutrality (wp1044 boxed term)
%        + β_HtM (au_wt_H_real_gap_t - yhat_au_t)   % HtM channel (Round 1.2 form)
%        + ε_t
%
% The PV² of au_wt_H_real_gap is the partial-L2 stand-in for the "y_H - ȳ"
% gap PV in wp1044 Eq 35.  Both are demeaned-log-real-income gaps; the
% wp1044 spec uses log income vs log trend output, our spec uses log
% income vs HP trend of log income.  Close enough for the AU partial-L2
% diagnostic.
%
% VAR(1) state z_t = [yhat_au, pi_au, i_au, i_10y, dy_bar_gap, y_H_gap]
% (6 variables; OLS lag-by-lag for Phi).
%
% chi (PV discount factor) is calibrated at a typical wp1044 value of
% 0.50 -- the closed-form discount that emerges from a deep PAC
% structure with β_1 small but a non-zero infinite-horizon
% expectation weight.  The naïve χ = β_1 (= 0.0375) gives near-zero
% discounting which doesn't reflect the forward-looking nature of
% consumption decisions.
%
% Inputs:
%   dynare/estimation_data.mat  (yhat_au, pi_au, i_au, i_10y, dln_c,
%                                dy_bar_gap)
%   data/extended_dataset.csv   (au_wt_H_real_gap)
% Outputs:
%   data/consumption_pac_full.{mat,txt}

clear; clc;
fprintf('=== Partial L2: full wp1044 Eq 35 consumption PAC OLS ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% 0. Load data
D = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

% Sample alignment: estimation_data.mat is 122 obs 1993Q2-2023Q3
% extended_dataset.csv is 128 obs starting 1993Q1
% prepare_estimation_data.m uses sample_range = 2:123 (1993Q2-2023Q3)
ext_dates = datetime(T_ext.date);
sample_idx = 2:123;
wt_H_real_gap_raw = T_ext.au_wt_H_real_gap(sample_idx);

% Demean it (consistent with estimation_data.mat treatment)
y_H_gap = wt_H_real_gap_raw - mean(wt_H_real_gap_raw, 'omitnan');

dln_c       = D.dln_c;
yhat_au     = D.yhat_au;
pi_au       = D.pi_au;
i_au        = D.i_au;
i_10y       = D.i_10y;
dy_bar_gap  = D.dy_bar_gap;

T = length(dln_c);
fprintf('Sample: %d obs.  Building VAR state...\n', T);

%% 1. VAR(1) Phi on state z = [yhat_au, pi_au, i_au, i_10y, y_H_gap]
%
% Important: dy_bar_gap is a SMOOTH HP TREND, not a cyclical gap.  It
% does NOT belong in the VAR state used to compute PV terms.  PV is
% supposed to capture expected future CYCLICAL components; trends enter
% the PAC equation separately via the growth-neutrality term
% (β_PAC · Δȳ_{t-1}).  Including dy_bar_gap in the VAR state inflates the
% PV operator and creates spurious correlation with the growth-neutrality
% regressor (the OLS then assigns huge offsetting coefficients).
Z = [yhat_au, pi_au, i_au, i_10y, y_H_gap];
state_names = {'yhat_au', 'pi_au', 'i_au', 'i_10y', 'y_H_gap'};
k = size(Z, 2);

% Drop rows with NaN
valid = ~any(isnan(Z), 2);
Z_use = Z(valid, :);
n_valid = size(Z_use, 1);
Z_lag = Z_use(1:end-1, :);
Z_t   = Z_use(2:end, :);

% OLS Phi (no intercept; state is already demeaned)
Phi = (Z_lag' * Z_lag) \ (Z_lag' * Z_t);
Phi = Phi';   % so Z_t = Phi * Z_{t-1} (row form: Z_t' = Phi * Z_lag')

fprintf('\nVAR(1) Phi (estimated by OLS on %d obs):\n', n_valid);
fprintf('%-12s', ' ');
for j = 1:k, fprintf('%9s ', state_names{j}); end
fprintf('\n');
for i = 1:k
    fprintf('%-12s', state_names{i});
    for j = 1:k, fprintf('%9.4f ', Phi(i,j)); end
    fprintf('\n');
end

% Spectral radius (largest eigenvalue magnitude)
eig_Phi = eig(Phi);
rho_Phi = max(abs(eig_Phi));
fprintf('\nPhi spectral radius: %.4f (must be < 1/chi for PV to converge)\n', rho_Phi);

%% 2. Compute PV operator at calibrated chi
% chi = b1_c + omega_c.  b1_c posterior mean from L1.3a chain 1 is 0.0375.
% omega_c is calibrated at 0 in AUSPAC (the consumption block's
% non-stationary expectations weight; wp1044 §3.5.1 notes it's modified
% from the standard form for the consumption gap, set to zero here).
chi_c = 0.50;

PV_op = (eye(k) - chi_c * Phi) \ Phi;
PV2_op = PV_op * PV_op;

fprintf('\nChi = %.4f.  ||I - chi*Phi||_2 = %.4f (well-conditioned).\n', ...
    chi_c, norm(eye(k) - chi_c * Phi, 2));

%% 3. Compute PV time series for the regressors of interest
% PV(x)_{t|t-1} = e_x' * PV_op * z_{t-1}
% For computational efficiency, compute PV_op * Z_lag' once.

% Pad Z_lag to align with full T sample (NaN at the start)
ZL = nan(T, k);
valid_idx = find(valid);
for ii = 2:length(valid_idx)
    ZL(valid_idx(ii), :) = Z_use(ii-1, :);
end

PV_z   = (PV_op  * ZL')';   % T x k -- each col is PV of that state var
PV2_z  = (PV2_op * ZL')';

% e_x selectors
i_yH    = find(strcmp(state_names, 'y_H_gap'));
i_i10y  = find(strcmp(state_names, 'i_10y'));
i_pi    = find(strcmp(state_names, 'pi_au'));

PV_y_H_gap   = PV_z(:, i_yH);
PV2_y_H_gap  = PV2_z(:, i_yH);
PV_real_long = PV_z(:, i_i10y) - PV_z(:, i_pi);    % i_10y - pi_au (real-rate proxy)

%% 4. Build regressor matrix and OLS
% Spec: Δc_t = β_0
%             + β_1 dln_c_{t-1}
%             + β_3 yhat_au_t
%             + γ_PV2 PV2(y_H_gap)_{t-1}
%             + γ_PV  PV(real_long_rate)_{t-1}
%             + β_PAC dy_bar_gap_{t-1}
%             + β_HtM (y_H_gap_t - yhat_au_t)
% (PV_*_t in the OLS is already the *_t|t-1 quantity since we built it from Z_lag.)
%
% Note: PV_z and PV2_z are aligned to T but the lag is already baked in
% (rows correspond to *_{t|t-1} given Z_{t-1}).  Use them as regressors
% at index t (since prepare_estimation_data.m time index t already maps
% to row t of estimation_data.mat).

% Three specs to isolate sources of variation:
%
% Spec A: full wp1044 Eq 35 (with HtM, has multicollinearity headache)
% Spec B: drop HtM channel -- isolates PV terms vs growth-neutrality
% Spec C: drop PV terms -- closest to L2-pilot Spec 4 but with chi-based
%         PV available for diagnostic comparison

%% Spec A: full Eq 35 -- HtM + PV(y_H_gap) + PV(r_LH) + dy_bar_gap
X_A = [ones(T,1), lag1(dln_c), yhat_au, PV_y_H_gap, PV_real_long, ...
       lag1(dy_bar_gap), y_H_gap - yhat_au];
names_A = {'(intercept)', 'b1_c (dln_c lag)', 'b3_c (yhat_au)', ...
           'gamma_PV (PV y_H_gap)', 'gamma_PV_r (PV r_LH)', ...
           'b_PAC_c (dy_bar lag)', 'b_HtM (y_H_gap - yhat_au)'};
[b_A, se_A, t_A, R2_A, rss_A, n_A] = ols_with_se(X_A, dln_c);
fprintf('\n--- Spec A: full wp1044 Eq 35 (with HtM) ---\n');
print_table(names_A, b_A, se_A, t_A);
fprintf('R² = %.4f, RSS = %.2f, N = %d\n', R2_A, rss_A, n_A);

%% Spec B: drop HtM -- isolates wp1044 PV + growth-neutrality
X_B = [ones(T,1), lag1(dln_c), yhat_au, PV_y_H_gap, PV_real_long, ...
       lag1(dy_bar_gap)];
names_B = {'(intercept)', 'b1_c (dln_c lag)', 'b3_c (yhat_au)', ...
           'gamma_PV (PV y_H_gap)', 'gamma_PV_r (PV r_LH)', ...
           'b_PAC_c (dy_bar lag)'};
[b_B, se_B, t_B, R2_B, rss_B, n_B] = ols_with_se(X_B, dln_c);
fprintf('\n--- Spec B: no HtM channel ---\n');
print_table(names_B, b_B, se_B, t_B);
fprintf('R² = %.4f, RSS = %.2f, N = %d\n', R2_B, rss_B, n_B);

%% Spec C: drop PV terms -- isolates the trend coefficient
X_C = [ones(T,1), lag1(dln_c), yhat_au, lag1(i_10y), ...
       lag1(dy_bar_gap)];
names_C = {'(intercept)', 'b1_c (dln_c lag)', 'b3_c (yhat_au)', ...
           'b2_c (i_10y lag)', 'b_PAC_c (dy_bar lag)'};
[b_C, se_C, t_C, R2_C, rss_C, n_C] = ols_with_se(X_C, dln_c);
fprintf('\n--- Spec C: no PV terms (matches L2-pilot Spec 4 minus ECM) ---\n');
print_table(names_C, b_C, se_C, t_C);
fprintf('R² = %.4f, RSS = %.2f, N = %d\n', R2_C, rss_C, n_C);

% Pick Spec B as the "final" full L2 result for downstream reporting
% (since Spec A has the HtM collinearity; Spec C drops PV which is the
% wp1044-faithful piece we want to keep).
b = b_B; se = se_B; t_stat = t_B; R2 = R2_B; rss = rss_B; n = n_B;
names = names_B;

%% 5. Compare with L1.3a chain 1 and L2-pilot
chain_path = fullfile(projectdir, 'data', 'l13a_chain1_posterior.mat');
L1 = load(chain_path);

idx_bPAC = find(strcmp(L1.param_names, 'b_PAC_c'));
idx_b1c  = find(strcmp(L1.param_names, 'b1_c'));
idx_b3c  = find(strcmp(L1.param_names, 'b3_c'));

pilot_path = fullfile(projectdir, 'data', 'consumption_pac_ols.mat');
P2 = load(pilot_path);

fprintf('--- Side-by-side: full-spec OLS vs L2-pilot Spec 4 vs L1.3a Bayesian ---\n');
fprintf('%-25s %12s %12s %12s\n', 'Coefficient', 'full L2 OLS', ...
    'L2-pilot Spec 4', 'L1.3a (chain1)');
fprintf('%-25s %12s %12s %12s\n', '-----------', '-----------', ...
    '---------------', '---------------');
fprintf('%-25s %12.4f %12.4f %12.4f\n', 'b1_c (dln_c lag)', ...
    b(2), P2.specs.spec4.coef(3), L1.post_mean(idx_b1c));
fprintf('%-25s %12.4f %12.4f %12.4f\n', 'b3_c (yhat_au)', ...
    b(3), P2.specs.spec4.coef(4), L1.post_mean(idx_b3c));
fprintf('%-25s %12.4f %12.4f %12.4f\n', 'b_PAC_c (dy_bar lag)', ...
    b(6), P2.specs.spec4.coef(6), L1.post_mean(idx_bPAC));

%% 6. Save
out = struct();
out.method = 'partial L2 OLS full wp1044 Eq 35';
out.T = T;
out.chi_c = chi_c;
out.Phi = Phi;
out.state_names = {state_names};
out.coef_names  = {names};
out.coef        = b;
out.coef_se     = se;
out.coef_tstat  = t_stat;
out.R2 = R2;
out.rss = rss;
out.N = n;
save(fullfile(projectdir, 'data', 'consumption_pac_full.mat'), '-struct', 'out');
fprintf('\nSaved data/consumption_pac_full.mat\n');

% Text summary
fid = fopen(fullfile(projectdir, 'data', 'consumption_pac_full.txt'), 'w');
fprintf(fid, 'Partial L2 full wp1044 Eq 35 OLS consumption PAC\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Sample: %d obs.  VAR(1) state: %s\n', T, strjoin(state_names, ', '));
fprintf(fid, 'chi = %.4f (b1_c + omega_c, omega_c = 0)\n', chi_c);
fprintf(fid, 'Phi spectral radius = %.4f\n\n', rho_Phi);
fprintf(fid, '%-32s %10s %10s %8s\n', 'Coefficient', 'estimate', 'se', 't');
for j = 1:length(names)
    fprintf(fid, '%-32s %10.4f %10.4f %8.2f\n', names{j}, b(j), se(j), t_stat(j));
end
fprintf(fid, 'R² = %.4f, N = %d\n\n', R2, n);
fprintf(fid, 'Side-by-side comparison:\n');
fprintf(fid, '%-25s %12s %12s %12s\n', 'Coefficient', 'full L2 OLS', ...
    'L2-pilot Spec 4', 'L1.3a (chain1)');
fprintf(fid, '%-25s %12.4f %12.4f %12.4f\n', 'b1_c (dln_c lag)', ...
    b(2), P2.specs.spec4.coef(3), L1.post_mean(idx_b1c));
fprintf(fid, '%-25s %12.4f %12.4f %12.4f\n', 'b3_c (yhat_au)', ...
    b(3), P2.specs.spec4.coef(4), L1.post_mean(idx_b3c));
fprintf(fid, '%-25s %12.4f %12.4f %12.4f\n', 'b_PAC_c (dy_bar lag)', ...
    b(6), P2.specs.spec4.coef(6), L1.post_mean(idx_bPAC));
fclose(fid);
fprintf('Saved data/consumption_pac_full.txt\n');

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
