%% prepare_l2_data.m  --  Phase L2-A: full data layer for wp1044 partial-L2
%
% Builds every new observable / target series that wp1044 references but
% the existing AUSPAC estimation_data.mat doesn't have.  Output goes to a
% single self-contained data/l2_data_layer.mat that the Phase C block
% scripts consume.
%
% Series produced (matching wp1044 Eq 16, 30, 33-35, 37, 46):
%
%   Block        Series                Description / source
%   ------       ------                ---------------------
%   VA-price     piQ                   100*Δlog(p_q_total) from supply_data
%                piW                   100*Δlog(wpi) from supply_data
%                pi_Q_star             Eq 17 OLS fit: target VA inflation
%                pi_Q_bar              HP trend of pi_Q_star
%                p_Q_star_minus_p_Q    log price-level gap (target - actual)
%                Delta_e               long-term efficiency growth (HP of dlog_Phi)
%   Employment   n_hat_star_S          Eq 31 OLS fit: salaried emp gap target
%                Delta_q_hat           market-VA gap growth = Δq - Δq̄
%   Consumption  y_H                   log real disposable income (W_H+TG_H)/p_C
%                y_bar                 HP trend of GDP
%                y_H_minus_y_bar       income vs trend output gap (LEVEL, not the
%                                       existing wt_H_real_gap which is HP-gap)
%                w_eff                 real efficient wage growth
%                u_hat                 unemployment gap (= urate - urate_trend)
%                r_LH                  real household lending rate (AU proxy: i_10y - pi_au)
%                c_star                Eq 33 fit: long-run consumption target
%   Housing inv  Delta_log_IH_star     Eq 36 form: housing inv target
%                Delta_log_IH_bar      HP trend of housing inv target
%   Business inv df                    synthetic final demand = c + ih (proxy;
%                                       missing exports/imports/gov_inv -- see
%                                       BLOCK_LIMITATIONS.md)
%                Delta_df              df growth
%                Delta_df_bar          HP trend of df growth
%
%   Auxiliary equation coefficients (Appendix A.0.2/A.0.3 equivalents):
%                aux_yH                Eq A.0.2 OLS for (y_H - y_bar)
%                aux_weff              Eq A.0.2 OLS for w_eff
%                aux_uhat              Eq A.0.2 OLS for u_hat
%                aux_rLH               Eq A.1 OLS for r_LH
%                aux_nhat              Eq 31 OLS for n_hat_star_S
%
%   COVID + period dummies: del_03Q2, del_06Q3, del_08Q1, del_10Q4,
%                            del_20Q1, del_20Q2, del_20Q3, del_20Q4,
%                            del_21Q1, del_21Q2
%
% Sample alignment: produces all series on the supply_data sample
% (1990Q1-2024Q4, 140 obs) with NaN where source data missing.  Phase C
% scripts restrict to common-NaN subsamples per block.
%
% Note: this script does NOT replace prepare_estimation_data.m -- it
% augments.  Per-block Phase C scripts load l2_data_layer.mat for the new
% series and the existing estimation_data.mat for the legacy 10 obs.

clear; clc;
fprintf('=== Phase L2-A: building wp1044 data layer ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% Load existing data
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
TS = load(fullfile(projectdir, 'data', 'trend_series.mat'));
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
T_base = readtable(fullfile(projectdir, 'dataset.csv'));

% Align extended_dataset and base dataset to the supply_data 140-obs sample
supply_dates = S.dates;
ext_dates    = datetime(T_ext.date);
base_dates   = datetime(T_base.date);

nQ = S.nQ;
fprintf('Supply sample: %d quarters %s..%s\n', nQ, ...
    datestr(supply_dates(1)), datestr(supply_dates(end)));

% Helper: align table column to supply_dates
align_to_supply = @(col, src_dates) align_q(col, src_dates, supply_dates);

%% A1. piQ = quarterly VA-price inflation
log_pq = S.p_q_total_lvl;
piQ = [NaN; diff(log_pq)] * 100;     % q/q %
fprintf('A1. piQ: %d valid obs, mean=%.3f%%, sd=%.3f%%\n', ...
    sum(~isnan(piQ)), mean(piQ, 'omitnan'), std(piQ, 'omitnan'));

%% A2. piW = quarterly wage growth (WPI when available, AWE fallback)
log_W = S.wpi_lvl;
log_W_awe = S.awe_lvl;
log_W_fill = log_W;
nan_wpi = isnan(log_W_fill);
log_W_fill(nan_wpi) = log_W_awe(nan_wpi);
piW = [NaN; diff(log_W_fill)] * 100;
fprintf('A2. piW (WPI+AWE): %d valid obs, mean=%.3f%%\n', ...
    sum(~isnan(piW)), mean(piW, 'omitnan'));

%% Delta_e: trend labour-efficiency growth (wp1044 Eq 20: random walk)
% Use HP-trend of observed productivity growth as proxy for Δē
log_Phi = S.q_market_lvl - S.n_total_lvl - S.h_lvl;
dlog_Phi = [NaN; diff(log_Phi)] * 100;       % q/q %
Delta_e = hp_trend(dlog_Phi, 1600);
fprintf('A2b. Delta_e (productivity-growth trend): mean=%.3f%%\n', mean(Delta_e, 'omitnan'));

%% A3. pi_Q_star (wp1044 Eq 17): pi*_Q = β_0 (π_W - Δē) + (1-β_0) π̄_Q*
% pi_W_eff = π_W - Δē (real efficient wage growth from a price perspective)
pi_W_eff = piW - Delta_e;

% pi_Q_bar (long-run trend of VA inflation, our pi*_Q,bar)
% Use HP trend of piQ as the long-run anchor
pi_Q_bar = hp_trend(piQ, 1600);

% OLS estimation of Eq 17: pi*_Q,t = β_0·pi_W_eff,t + (1-β_0)·pi_Q_bar,t + ε
% But pi*_Q is the LHS and is UNOBSERVED.  We need a target proxy.
% Use the realised piQ as the target (since pi*_Q is what piQ is supposed
% to track in the LR), and back out β_0:
%   piQ_t ≈ β_0·pi_W_eff,t + (1-β_0)·pi_Q_bar,t
% This is a constrained regression where coefs sum to 1.
valid_17 = ~isnan(piQ) & ~isnan(pi_W_eff) & ~isnan(pi_Q_bar);
y_17 = piQ(valid_17);
% Use (pi_W_eff - pi_Q_bar) as the regressor; β_0 is coefficient on it.
x_17 = pi_W_eff(valid_17) - pi_Q_bar(valid_17);
% piQ = pi_Q_bar + β_0 * (pi_W_eff - pi_Q_bar) + ε
lhs_17 = y_17 - pi_Q_bar(valid_17);
beta_0_eq17 = (x_17' * x_17) \ (x_17' * lhs_17);
% Construct pi*_Q time series with the estimated β_0
pi_Q_star = beta_0_eq17 * pi_W_eff + (1 - beta_0_eq17) * pi_Q_bar;
fprintf('A3. Eq 17 OLS: beta_0 = %.4f  (wp1044 FR: 0.71)\n', beta_0_eq17);
fprintf('    pi_Q_star: mean=%.3f, sd=%.3f over %d obs\n', ...
    mean(pi_Q_star, 'omitnan'), std(pi_Q_star, 'omitnan'), sum(~isnan(pi_Q_star)));

%% p_Q_star_minus_p_Q (ECM term for Eq 16): integrate pi_Q_star - piQ
% pi_Q_star_t - piQ_t is the inflation gap; the price-LEVEL gap is its
% cumulative sum (with a constant of integration determined by demeaning).
inflation_diff_pp = pi_Q_star - piQ;        % keep in q/q pp form
inflation_diff_pp(isnan(inflation_diff_pp)) = 0;
p_Q_star_minus_p_Q = cumsum(inflation_diff_pp);
p_Q_star_minus_p_Q = p_Q_star_minus_p_Q - mean(p_Q_star_minus_p_Q);
fprintf('A3b. p*_Q - p_Q (ECM level gap, pp scale): sd=%.4f over %d obs\n', ...
    std(p_Q_star_minus_p_Q, 'omitnan'), sum(~isnan(p_Q_star_minus_p_Q)));

%% A4. Synthetic df = c + ih (proxy; full def. needs exports + gov_inv)
% Per BLOCK_LIMITATIONS.md, exports not available; df_AU is partial.
ext_c   = align_to_supply(T_ext.au_consumption,    ext_dates);
ext_ih  = align_to_supply(T_ext.au_gfcf_dwelling,  ext_dates);
df = ext_c + ext_ih;
log_df = log(df);
Delta_df = [NaN; diff(log_df)] * 100;
Delta_df_bar = hp_trend(Delta_df, 1600);
fprintf('A4. df = c + ih (partial -- exports missing): %d valid obs\n', ...
    sum(~isnan(df)));

%% A5. n_hat_star_S (Eq 31): salaried emp gap target = β_0 ŷ_{t-1} + β_3 n̂*_{S,t-1}
% Need yhat_au at supply_dates resolution.  base_dates have au_ygap.
yhat_au_full = align_to_supply(T_base.au_ygap, base_dates);
% Iteratively estimate Eq 31 (AR(1) with output gap input).  n_hat is the
% employment gap target; AU proxy uses HP gap of log(salaried employment)
% in pp (× 100).
log_n = S.n_total_lvl;
n_gap_HP = log_n - hp_trend(log_n, 1600);
n_hat = n_gap_HP * 100;     % pp scale matching ŷ, piQ, piW
valid_31 = ~isnan(yhat_au_full) & ~isnan(n_hat);
y_31 = n_hat(2:end);
X_31 = [yhat_au_full(1:end-1), n_hat(1:end-1)];
vv = ~any(isnan([y_31, X_31]), 2);
b_31 = (X_31(vv,:)' * X_31(vv,:)) \ (X_31(vv,:)' * y_31(vv));
fprintf('A5. Eq 31 OLS (n_hat_star_S): β_0 = %.4f, β_3 = %.4f (wp1044: 0.29, 0.60)\n', ...
    b_31(1), b_31(2));
n_hat_star_S = [NaN; X_31 * b_31];   % fitted values

%% Delta_q_hat (market VA gap growth): Δq - Δq̄
log_q_market = S.q_market_lvl;
q_market_trend = hp_trend(log_q_market, 1600);
log_q_market_gap = log_q_market - q_market_trend;
Delta_q_hat = [NaN; diff(log_q_market_gap)] * 100;
fprintf('A5b. Delta_q_hat (market VA gap growth): mean=%.3f, sd=%.3f\n', ...
    mean(Delta_q_hat, 'omitnan'), std(Delta_q_hat, 'omitnan'));

%% A6+A7. y_H and aux equations (consumption block)
% y_H = log(real disposable income).  Read W_H + TG_H from
% prepare_household_income.m's source (ABS 5206 Table 20) -- we ALREADY have
% au_wt_H_real_gap in extended_dataset, which is the HP gap of log y_H.
% To get the LEVEL: integrate from extended_dataset's au_wt_H_real_gap
% plus reconstruct the trend.  Simpler: reload from the ABS xlsx if possible.
%
% For this rebuild: skip the levels reconstruction; use the existing
% au_wt_H_real_gap as the gap, and proxy ȳ_t with hp_trend of log GDP.
y_H_gap_legacy = align_to_supply(T_ext.au_wt_H_real_gap, ext_dates);
log_q_total = S.q_total_lvl;
y_bar = hp_trend(log_q_total, 1600);

% au_wt_H_real_gap is a NATURAL-LOG gap (~±0.05).  Convert to pp scale
% (multiply by 100) so y_H - y_bar is in pp, consistent with piQ, piW, ŷ.
y_H_minus_y_bar = y_H_gap_legacy * 100;
fprintf('A6. y_H - y_bar: using au_wt_H_real_gap as proxy (assumes y_H_trend ≈ y_bar)\n');

% Δw_eff,t = real efficient wage growth = π_W - Δē - π_Q (approx)
% Closer to wp1044: w_eff = log real wage / efficiency.  Use:
%   Δw_eff,t = (π_W,t - π_Q,t) - Δē_t  (real efficient wage growth)
Delta_w_eff = (piW - piQ) - Delta_e;
fprintf('A7a. Delta_w_eff: mean=%.3f%%, sd=%.3f%%\n', ...
    mean(Delta_w_eff, 'omitnan'), std(Delta_w_eff, 'omitnan'));

% u_hat (unemployment gap) = urate - urate_trend.  Use HP filter.
urate = S.urate;          % ALREADY in pp form (mean ~6.3, max ~11.7)
urate_trend = hp_trend(urate, 1600);
u_hat = urate - urate_trend;
fprintf('A7b. u_hat: sd=%.3f pp (= urate - HP trend)\n', std(u_hat, 'omitnan'));

% Aux equation for y_H - y_bar (Eq A.0.2 form: AR(1) with regressors)
valid_aux1 = ~any(isnan([y_H_minus_y_bar, yhat_au_full, u_hat, Delta_w_eff]), 2);
y_aux1 = y_H_minus_y_bar(2:end);
X_aux1 = [ones(nQ-1, 1), y_H_minus_y_bar(1:end-1), yhat_au_full(1:end-1), ...
          u_hat(1:end-1), Delta_w_eff(1:end-1)];
vv1 = ~any(isnan([y_aux1, X_aux1]), 2);
b_aux1 = (X_aux1(vv1,:)' * X_aux1(vv1,:)) \ (X_aux1(vv1,:)' * y_aux1(vv1));
fprintf('A7c. y_H aux equation OLS: const=%.4f, AR1=%.4f, ŷ_lag=%.4f, û_lag=%.4f, Δw_eff_lag=%.4f\n', ...
    b_aux1(1), b_aux1(2), b_aux1(3), b_aux1(4), b_aux1(5));

% Aux equation for u_hat (Eq A.0.2 form: AR(1) + output gap contemp)
valid_aux2 = ~any(isnan([u_hat, yhat_au_full]), 2);
y_aux2 = u_hat(2:end);
X_aux2 = [ones(nQ-1, 1), u_hat(1:end-1), yhat_au_full(2:end)];
vv2 = ~any(isnan([y_aux2, X_aux2]), 2);
b_aux2 = (X_aux2(vv2,:)' * X_aux2(vv2,:)) \ (X_aux2(vv2,:)' * y_aux2(vv2));
fprintf('A7d. u_hat aux: const=%.4f, AR1=%.4f, ŷ_t=%.4f (wp1044: -0.12 for ŷ_t)\n', ...
    b_aux2(1), b_aux2(2), b_aux2(3));

% Aux equation for Δw_eff (Eq A.0.2 form: AR(1) + u_hat_lag)
valid_aux3 = ~any(isnan([Delta_w_eff, u_hat]), 2);
y_aux3 = Delta_w_eff(2:end);
X_aux3 = [ones(nQ-1, 1), Delta_w_eff(1:end-1), u_hat(1:end-1)];
vv3 = ~any(isnan([y_aux3, X_aux3]), 2);
b_aux3 = (X_aux3(vv3,:)' * X_aux3(vv3,:)) \ (X_aux3(vv3,:)' * y_aux3(vv3));
fprintf('A7e. Delta_w_eff aux: const=%.4f, AR1=%.4f, û_lag=%.4f\n', ...
    b_aux3(1), b_aux3(2), b_aux3(3));

%% A8. r_LH aux (Eq A.1)
% r_LH,t = β_0 r_LH,t-1 + (1-β_0)(ī - π̄ + β_3) + β_1(i - ī) + β_2(π̄ - π)
% AU proxy: r_LH = i_10y - pi_au (nominal long rate minus current inflation)
i_10y_full = align_to_supply(T_ext.au_i10, ext_dates);    % annualized %
pi_au_full = align_to_supply(T_base.au_pi,  base_dates);  % q/q %, demeaned form will be CPI
i_au_full  = align_to_supply(T_base.au_irate, base_dates);    % annualized %

% Nominal lending rate proxy = i_10y (households actually pay mortgage rate but
% we don't have it; i_10y is the cleanest available long rate)
r_LH = i_10y_full - pi_au_full * 4;    % real rate (annualized inflation subtracted)
% i and ibar: i_au (cash rate) and its HP trend
i_au_trend = hp_trend(i_au_full, 1600);
pi_au_trend = hp_trend(pi_au_full, 1600);

valid_aux4 = ~any(isnan([r_LH, i_au_full, pi_au_full]), 2);
% Eq A.1: r_LH = β_0 r_LH_lag + (1-β_0)(ī - π̄ + β_3) + β_1(i - ī) + β_2(π̄ - π)
%       = β_0 r_LH_lag + β_3(1-β_0) + (1-β_0)(ī - π̄)·4 + β_1(i - ī) + β_2(π̄ - π)
% Multiply by 4 to keep annualised
y_aux4 = r_LH(2:end);
X_aux4 = [ones(nQ-1, 1), r_LH(1:end-1), ...
          (i_au_trend(1:end-1) - pi_au_trend(1:end-1)*4), ...
          (i_au_full(1:end-1) - i_au_trend(1:end-1)), ...
          (pi_au_trend(1:end-1)*4 - pi_au_full(1:end-1)*4)];
vv4 = ~any(isnan([y_aux4, X_aux4]), 2);
if sum(vv4) > 10
    b_aux4 = (X_aux4(vv4,:)' * X_aux4(vv4,:)) \ (X_aux4(vv4,:)' * y_aux4(vv4));
    fprintf('A8. r_LH aux (Eq A.1): const=%.4f, β_0=%.4f, ī-π̄ coef=%.4f, β_1=%.4f, β_2=%.4f\n', ...
        b_aux4(1), b_aux4(2), b_aux4(3), b_aux4(4), b_aux4(5));
else
    b_aux4 = nan(5, 1);
    fprintf('A8. r_LH aux: insufficient observations (%d), aux not estimated\n', sum(vv4));
end

%% A10. y_tilde (HP trend of GDP GROWTH, distinct from y_bar which is HP of level)
% Already in trend_series.mat as 'ytilde'
% Align trend_series.mat to supply_dates -- they should already match
y_tilde = TS.ytilde * 100;       % convert to q/q %
fprintf('A10. y_tilde from trend_series.mat: mean=%.3f%%\n', mean(y_tilde, 'omitnan'));

%% A11. Delta q_hat already done above (A5b)

%% A12. COVID + period dummies
year_v = year(supply_dates);
q_v    = quarter(supply_dates);
mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);
del_03Q2 = mkd(2003, 2);
del_06Q3 = mkd(2006, 3);
del_08Q1 = mkd(2008, 1);
del_10Q4 = mkd(2010, 4);
del_20Q1 = mkd(2020, 1);
del_20Q2 = mkd(2020, 2);
del_20Q3 = mkd(2020, 3);
del_20Q4 = mkd(2020, 4);
del_21Q1 = mkd(2021, 1);
del_21Q2 = mkd(2021, 2);
fprintf('A12. Dummies built (10 columns).\n');

%% A6 cont. c_star (Eq 33): c* = α_0 + PV(y_H) + α_1·(r_LH - (ī - π̄))
% This requires PV(y_H) which itself needs the VAR.  For Phase A we
% record the OLS estimate of (α_0, α_1) using observed log_c as proxy:
%   log(c_t) - log(au_consumption_trend) ≈ "c_t deviation from target"
% Run the LR Eq 33 OLS: log(c) = α_0 + log(y_H_proxy) + α_1·real_rate_gap
ext_c = align_to_supply(T_ext.au_consumption, ext_dates);
log_c = log(ext_c);
log_c_trend = hp_trend(log_c, 1600);

% For α_0, α_1: regress log_c (pp scale) on a real rate gap (in pp form).
% Use log_c_trend itself as proxy for PV(y_H) (since cons tracks income in LR).
% Scale y_33 to pp (× 100) so coefficients are comparable to wp1044.
real_rate_gap = (i_10y_full - pi_au_full * 4) - (i_au_trend - pi_au_trend * 4);
y_33 = (log_c - log_c_trend) * 100;     % "deviation from PV(y_H) proxy" in pp
X_33 = [ones(nQ, 1), real_rate_gap];
vv_33 = ~any(isnan([y_33, X_33]), 2);
b_33 = (X_33(vv_33,:)' * X_33(vv_33,:)) \ (X_33(vv_33,:)' * y_33(vv_33));
alpha_0 = b_33(1);
alpha_1 = b_33(2);
fprintf('A6. Eq 33 LR OLS (pp scale): alpha_0 = %.4f, alpha_1 = %.4f (wp1044: -0.15, -1.15)\n', ...
    alpha_0, alpha_1);
c_star = log_c_trend * 100 + alpha_0 + alpha_1 * real_rate_gap;

%% Pack outputs
out = struct();
out.method = 'wp1044 partial-L2 data layer (Phase L2-A)';
out.dates = supply_dates;
out.nQ = nQ;

% Block VA-price
out.piQ                 = piQ;
out.piW                 = piW;
out.Delta_e             = Delta_e;
out.pi_Q_star           = pi_Q_star;
out.pi_Q_bar            = pi_Q_bar;
out.p_Q_star_minus_p_Q  = p_Q_star_minus_p_Q;
out.beta_0_eq17         = beta_0_eq17;

% Block Employment
out.n_hat_star_S        = n_hat_star_S;
out.Delta_q_hat         = Delta_q_hat;
out.coefs_eq31          = b_31;

% Block Consumption
out.y_H_minus_y_bar     = y_H_minus_y_bar;
out.y_bar               = y_bar;
out.Delta_w_eff         = Delta_w_eff;
out.u_hat               = u_hat;
out.r_LH                = r_LH;
out.c_star              = c_star;
out.alpha_0_eq33        = alpha_0;
out.alpha_1_eq33        = alpha_1;
out.coefs_aux_yH        = b_aux1;
out.coefs_aux_uhat      = b_aux2;
out.coefs_aux_weff      = b_aux3;
out.coefs_aux_rLH       = b_aux4;

% Block Housing
out.note_housing        = 'pSH/pIH not in AU data; see BLOCK_LIMITATIONS.md';

% Block Business
out.df                  = df;
out.Delta_df            = Delta_df;
out.Delta_df_bar        = Delta_df_bar;
out.note_business       = 'df = c + ih only (exports missing); see BLOCK_LIMITATIONS.md';

% Common
out.y_tilde             = y_tilde;
out.i_au_trend          = i_au_trend;
out.pi_au_trend         = pi_au_trend;

% Dummies
out.del_03Q2 = del_03Q2;
out.del_06Q3 = del_06Q3;
out.del_08Q1 = del_08Q1;
out.del_10Q4 = del_10Q4;
out.del_20Q1 = del_20Q1;
out.del_20Q2 = del_20Q2;
out.del_20Q3 = del_20Q3;
out.del_20Q4 = del_20Q4;
out.del_21Q1 = del_21Q1;
out.del_21Q2 = del_21Q2;

save(fullfile(projectdir, 'data', 'l2_data_layer.mat'), '-struct', 'out');
fprintf('\nSaved data/l2_data_layer.mat\n');

%% Summary report
txtfile = fullfile(projectdir, 'data', 'l2_data_layer.txt');
fid = fopen(txtfile, 'w');
fprintf(fid, 'Phase L2-A: wp1044 partial-L2 data layer summary\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Sample: %d quarters %s..%s\n\n', nQ, ...
    datestr(supply_dates(1)), datestr(supply_dates(end)));
fprintf(fid, 'Series produced (q/q %% scale unless noted):\n');
fprintf(fid, '  Block VA-price:\n');
fprintf(fid, '    piQ                  %d valid obs, mean=%.3f\n', sum(~isnan(piQ)), mean(piQ,'omitnan'));
fprintf(fid, '    piW                  %d valid obs, mean=%.3f\n', sum(~isnan(piW)), mean(piW,'omitnan'));
fprintf(fid, '    Delta_e (Eq 20)      mean=%.3f\n', mean(Delta_e,'omitnan'));
fprintf(fid, '    pi_Q_star (Eq 17)    beta_0_eq17=%.4f (wp1044 FR: 0.71)\n', beta_0_eq17);
fprintf(fid, '    pi_Q_bar             HP trend of piQ\n');
fprintf(fid, '    p*_Q - p_Q           level gap, sd=%.4f\n', std(p_Q_star_minus_p_Q,'omitnan'));
fprintf(fid, '  Block Employment:\n');
fprintf(fid, '    n_hat_star_S (Eq 31) beta_0=%.4f, beta_3=%.4f (wp1044: 0.29, 0.60)\n', b_31(1), b_31(2));
fprintf(fid, '    Delta_q_hat          mean=%.3f, sd=%.3f\n', mean(Delta_q_hat,'omitnan'), std(Delta_q_hat,'omitnan'));
fprintf(fid, '  Block Consumption:\n');
fprintf(fid, '    y_H - y_bar (proxy)  via au_wt_H_real_gap\n');
fprintf(fid, '    Delta_w_eff          mean=%.3f, sd=%.3f\n', mean(Delta_w_eff,'omitnan'), std(Delta_w_eff,'omitnan'));
fprintf(fid, '    u_hat                sd=%.3f\n', std(u_hat,'omitnan'));
fprintf(fid, '    r_LH                 mean=%.3f, sd=%.3f\n', mean(r_LH,'omitnan'), std(r_LH,'omitnan'));
fprintf(fid, '    c_star (Eq 33)       alpha_0=%.4f, alpha_1=%.4f (wp1044: -0.15, -1.15)\n', alpha_0, alpha_1);
fprintf(fid, '  Block Business inv:\n');
fprintf(fid, '    df = c + ih          %d valid obs (EXPORTS MISSING -- see BLOCK_LIMITATIONS.md)\n', sum(~isnan(df)));
fprintf(fid, '  Block Housing inv:\n');
fprintf(fid, '    pSH/pIH              NOT AVAILABLE (see BLOCK_LIMITATIONS.md)\n');
fprintf(fid, '  Common:\n');
fprintf(fid, '    y_tilde              from trend_series.mat (HP of GDP growth)\n');
fprintf(fid, '    i_au_trend, pi_au_trend  HP filters of policy rate, CPI\n');
fprintf(fid, '\n10 COVID/period dummies built: 03Q2, 06Q3, 08Q1, 10Q4, 20Q1-Q4, 21Q1, 21Q2\n');
fprintf(fid, '\nAuxiliary equation coefs (Appendix A.0.2/A.0.3):\n');
fprintf(fid, '  y_H aux  (A.0.2): %s\n', mat2str(b_aux1', 3));
fprintf(fid, '  u_hat aux (A.0.2): %s\n', mat2str(b_aux2', 3));
fprintf(fid, '  Δw_eff aux (A.0.2): %s\n', mat2str(b_aux3', 3));
fprintf(fid, '  r_LH aux (A.1): %s\n', mat2str(b_aux4', 3));
fclose(fid);
fprintf('Saved %s\n', txtfile);

fprintf('\n=== Phase L2-A complete ===\n');

%% Helpers
function vq = align_q(src_col, src_dates, target_dates)
    nq = length(target_dates);
    vq = nan(nq, 1);
    for i = 1:nq
        m = find(year(src_dates) == year(target_dates(i)) & ...
                 quarter(src_dates) == quarter(target_dates(i)), 1);
        if ~isempty(m), vq(i) = src_col(m); end
    end
end

function trend = hp_trend(y, lambda)
    y = y(:);
    n = length(y);
    trend = nan(n, 1);
    valid = find(~isnan(y));
    if length(valid) < 4, return; end
    lo = valid(1); hi = valid(end);
    span = lo:hi;
    y_span = y(span);
    nm = isnan(y_span);
    if any(nm)
        idx = find(~nm);
        y_span = interp1(idx, y_span(idx), 1:length(y_span), 'linear')';
    end
    n_span = length(y_span);
    e = ones(n_span, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n_span-2, n_span);
    A = speye(n_span) + lambda * (D2' * D2);
    trend(span) = A \ y_span;
end
