%% run_phase3_estimation.m — Phase 3: Financial block + target equations
%
% Estimates:
%   Part A: Financial block (~10 params)
%     - Exchange rate UIP (rho_s, alpha_s)
%     - Mortgage rate pass-through (rho_lh, spread_lh)
%     - Housing price dynamics (rho_ph, alpha_ph_y, alpha_ph_r)
%     - Credit spread persistence (rho_COE, rho_LB_firms, rho_BBB)
%   Part B: Target equations (~8 estimable params)
%     - VA price target (rho_pQ_star, gamma_ulc, gamma_uck)
%     - Commodity price channel in exports (b4_x)
%     - Housing price Tobin's Q (kappa_ph)

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

logfile = 'log_phase3_estimation.txt';
fid = fopen(logfile, 'w');
lf = @(msg) fprintf(fid, msg);
lf('================================================================\n');
lf('  PHASE 3: FINANCIAL BLOCK + TARGET EQUATIONS\n');
lf(sprintf('  %s\n', datestr(now)));
lf('================================================================\n\n');

%% Load data
core = readtable('c:\Users\david\french_model\dataset.csv');
ext = readtable('c:\Users\david\french_model\data\extended_dataset.csv');
T = min(height(core), height(ext));
datadir = 'c:\Users\david\french_model\data';

yhat_au = core.au_ygap(1:T);
pi_au = core.au_pi(1:T);
i_au = core.au_irate(1:T);
yhat_us = core.us_ygap(1:T);
pi_us = core.us_pi(1:T);
i10y = ext.au_i10(1:T);

i_ss = 1.0491; pi_ss = 0.625; pi_us_ss = 0.5;
i_gap = i_au - i_ss;
pi_au_gap = pi_au - pi_ss;
pi_us_gap = pi_us - pi_us_ss;

% REER s_gap from Phase 2
reer = load_fred_cached('CCRETT01AUQ661N', datadir, core, T);
s_gap_data = NaN(T, 1);
if sum(~isnan(reer)) > 20
    valid = ~isnan(reer);
    [trend, ~] = hpf(log(reer(valid)), 1600);
    s_gap_data(valid) = (log(reer(valid)) - trend) * 100;
end
lf(sprintf('  s_gap: %d valid obs, range [%.1f, %.1f]\n', ...
    sum(~isnan(s_gap_data)), min(s_gap_data(~isnan(s_gap_data))), max(s_gap_data(~isnan(s_gap_data)))));

% Commodity price growth
pcom = load_fred_cached('PALLFNFINDEXQ', datadir, core, T);
dln_pcom = [NaN; diff(log(pcom))] * 100;

%% ========================================================================
%  PART A: FINANCIAL BLOCK
%  ========================================================================
lf('\n================================================================\n');
lf('  PART A: FINANCIAL BLOCK ESTIMATION\n');
lf('================================================================\n\n');

% --- A1: Exchange rate UIP ---
% s_gap = rho_s * s_gap(-1) - alpha_s * i_gap + alpha_s * (pi_au_gap - pi_us_gap)
lf('--- A1: Exchange rate (UIP with persistent deviations) ---\n');
lf('  s_gap(t) = rho_s*s_gap(t-1) - alpha_s*i_gap(t) + alpha_s*(pi_au_gap(t) - pi_us_gap(t))\n');
lf('  Constrained: same alpha_s on nominal and real rate differential\n\n');

% Reparameterize: s_gap = rho_s*s_gap(-1) + alpha_s*(-i_gap + pi_au_gap - pi_us_gap)
% = rho_s*s_gap(-1) + alpha_s*(real_rate_diff)
real_rate_diff = -i_gap + (pi_au_gap - pi_us_gap);

idx = 2:T;
Y_s = s_gap_data(idx);
X_s = [s_gap_data(idx-1), real_rate_diff(idx)];
s_names = {'rho_s', 'alpha_s'};
s_cal = [0.95, 0.15];
[s_est, s_se, s_R2, s_T] = ols_nan(Y_s, X_s);
print_results(fid, 'Exchange rate', s_names, s_est, s_se, s_cal, s_R2, s_T);

% --- A2: Mortgage rate pass-through ---
% i_lh = rho_lh * i_lh(-1) + (1-rho_lh) * (i_10y + spread_lh)
lf('\n--- A2: Mortgage rate pass-through ---\n');

% Try FRED for AU standard variable housing loan rate
% FRED: IR3TIB01AUM156N is 3-month rate (already used), not mortgage
% Try: IRLTLT01AUQ156N is 10Y (already have). Housing rate not on FRED.
% Use 10Y + fixed spread as proxy, estimate spread from i_10y dynamics

% Alternative: estimate from 10Y yield dynamics as proxy for lending rate
% i_lh ≈ i_10y + spread. Without separate mortgage data, estimate the
% AR coefficient from i_10y dynamics (which drive mortgage rate through pass-through)
lf('  No separate AU mortgage rate on FRED.\n');
lf('  Estimating pass-through from 10Y yield dynamics as proxy.\n\n');

% Convert 10Y yield to quarterly (it's annual in dataset)
i10_q = i10y / 4;  % convert to quarterly if needed
% Actually, check: i_au SS = 1.049 quarterly = 4.2% annual
% i_10y SS = 1.349 quarterly = 5.4% annual
% So i10y is already in quarterly terms in the model

% i_lh ≈ i_10y + spread. Estimate: delta_i_10 persistence
di10 = [NaN; diff(i10y)];
Y_lh = di10(3:T);
X_lh = [di10(2:T-1)];
lh_names = {'rho_di10 (proxy for rho_lh)'};
lh_cal = [0.88];
[lh_est, lh_se, lh_R2, lh_T] = ols_nan(Y_lh, X_lh);
print_results(fid, 'Mortgage proxy (10Y yield persistence)', lh_names, lh_est, lh_se, lh_cal, lh_R2, lh_T);

if ~isempty(lh_est) && lh_est(1) > 0 && lh_est(1) < 1
    rho_lh_est = lh_est(1);
else
    rho_lh_est = 0.88;  % keep calibrated
    lf('  Proxy estimate not usable, keeping rho_lh = 0.88\n');
end

% --- A3: Housing prices ---
% dln_ph = rho_ph*dln_ph(-1) + alpha_ph_y*yhat_au + alpha_ph_r*i_gap(-1)
lf('\n--- A3: Housing price dynamics ---\n');

% Try FRED for AU house prices
hp_idx = load_fred_cached('QAURHPUS', datadir, core, T);  % OECD real house prices
if sum(~isnan(hp_idx)) < 20
    hp_idx = load_fred_cached('QAURRPUS', datadir, core, T);  % alternative
end

dln_ph_data = NaN(T, 1);
if sum(~isnan(hp_idx)) > 20
    dln_ph_data = [NaN; diff(log(hp_idx))] * 100;
    lf(sprintf('  House prices from FRED: %d valid obs\n', sum(~isnan(dln_ph_data))));
else
    lf('  No AU house price data from FRED.\n');
    lf('  Using yhat_au as proxy for housing cycle (correlated with house prices).\n');
    % Can't estimate without housing price data. Try proxy approach:
    % In AU, house prices are highly correlated with output gap
    % Use a simulated proxy: dln_ph ≈ 0.5*yhat_au + noise
end

if sum(~isnan(dln_ph_data)) > 20
    Y_ph = dln_ph_data(3:T);
    X_ph = [dln_ph_data(2:T-1), yhat_au(3:T), i_gap(2:T-1)];
    ph_names = {'rho_ph', 'alpha_ph_y', 'alpha_ph_r'};
    ph_cal = [0.90, 0.15, -0.10];
    [ph_est, ph_se, ph_R2, ph_T] = ols_nan(Y_ph, X_ph);
    print_results(fid, 'Housing prices', ph_names, ph_est, ph_se, ph_cal, ph_R2, ph_T);
else
    lf('  SKIPPED: No housing price data. Keep calibrated (rho=0.90, alpha_y=0.15, alpha_r=-0.10)\n\n');
    ph_est = []; ph_se = []; ph_R2 = NaN; ph_T = 0;
    ph_names = {'rho_ph', 'alpha_ph_y', 'alpha_ph_r'};
    ph_cal = [0.90, 0.15, -0.10];
end

% --- A4: Credit spread persistence ---
lf('\n--- A4: Credit spread persistence ---\n');
lf('  AR(1) processes. No separate AU credit spread data from FRED.\n');
lf('  FR-BDF calibrations kept: rho_COE=0.92, rho_LB=0.77, rho_BBB=0.94\n');
lf('  These are institutional parameters that vary little across developed economies.\n\n');

%% ========================================================================
%  PART B: TARGET EQUATIONS
%  ========================================================================
lf('================================================================\n');
lf('  PART B: TARGET EQUATION ESTIMATION\n');
lf('================================================================\n\n');

% --- B1: VA price target ---
% piQ_star = rho * piQ_star(-1) + gamma_ulc * dln_ulc + gamma_uck * dln_uc_k + (1-rho-gamma_ulc)*pibar
% We can estimate this from: piQ ≈ pi_au (proxy), dln_ulc from ULC data
lf('--- B1: VA price target (CES dual, growth-rate form) ---\n');

ulc = ext.au_ulc(1:T);
dln_ulc = [NaN; diff(log(ulc))] * 100;  % quarterly ULC growth

% piQ_star_bar (trend target) — use HP trend of VA price inflation
piQ_obs = pi_au;  % proxy
valid_piQ = ~isnan(piQ_obs);
[piQ_trend, ~] = hpf(piQ_obs(valid_piQ), 1600);
piQ_star_proxy = NaN(T, 1);
piQ_star_proxy(valid_piQ) = piQ_trend;

% Estimate: piQ_star = rho*piQ_star(-1) + gamma_ulc*dln_ulc + (1-rho-gamma_ulc)*pibar
% Reparameterize gap form: (piQ_star - pibar) = rho*(piQ_star(-1)-pibar) + gamma_ulc*(dln_ulc-pibar)
idx_b = 3:T;
Y_pqs = piQ_star_proxy(idx_b) - pi_ss;
X_pqs = [piQ_star_proxy(idx_b-1) - pi_ss, dln_ulc(idx_b) - pi_ss];
pqs_names = {'rho_pQ_star', 'gamma_ulc'};
pqs_cal = [0.95, 0.12];
[pqs_est, pqs_se, pqs_R2, pqs_T] = ols_nan(Y_pqs, X_pqs);
print_results(fid, 'VA price target', pqs_names, pqs_est, pqs_se, pqs_cal, pqs_R2, pqs_T);

% --- B2: Consumption target sensitivity ---
% dln_c_star_bar involves kappa_inc * delta(pv_yh) + alpha_c_r * delta(real_rate_gap)
% These require model-internal variables (pv_yh). Use smoother if available.
lf('\n--- B2: Consumption target ---\n');
lf('  kappa_inc and alpha_c_r require model-internal PV variables.\n');
lf('  Estimation deferred to Bayesian framework (add to estimated_params).\n');
lf('  Current: kappa_inc=0.05, alpha_c_r=-0.95 (FR-BDF Table 4.6.14)\n\n');

% --- B3: Business investment target ---
% dln_ib_star_bar = kappa_ib_y * yhat_au - sigma_ces * dln_uc_k
% sigma_ces is structural (CES elasticity) — keep calibrated
% kappa_ib_y can be estimated from investment-output relationship
lf('--- B3: Business investment target ---\n');

gfcf_nd = ext.au_gfcf_nondwelling(1:T);
dln_ib = [NaN; diff(log(gfcf_nd))] * 100;
% HP trend of investment growth ≈ target growth
valid_ib = ~isnan(dln_ib);
if sum(valid_ib) > 20
    [ib_trend, ~] = hpf(dln_ib(valid_ib), 1600);
    ib_star_proxy = NaN(T, 1);
    ib_star_proxy(valid_ib) = ib_trend;

    % Regress trend investment growth on output gap
    Y_ibt = ib_star_proxy(3:T);
    X_ibt = [yhat_au(3:T)];
    ibt_names = {'kappa_ib_y'};
    ibt_cal = [0.06];
    [ibt_est, ibt_se, ibt_R2, ibt_T] = ols_nan(Y_ibt, X_ibt);
    print_results(fid, 'Business inv target (output sensitivity)', ibt_names, ibt_est, ibt_se, ibt_cal, ibt_R2, ibt_T);
else
    lf('  SKIPPED: Insufficient investment data\n\n');
    ibt_est = []; ibt_se = []; ibt_names = {'kappa_ib_y'}; ibt_cal = [0.06];
end

% --- B4: Housing investment target ---
lf('\n--- B4: Housing investment target ---\n');
lf('  kappa_mort and kappa_ih_inc require mortgage rates and PV variables.\n');
lf('  Estimation deferred. Current: kappa_mort=0.048, kappa_ih_inc=0.03, kappa_ph=0.03\n\n');

%% ========================================================================
%  Summary + parameter update block
%  ========================================================================
lf('================================================================\n');
lf('  PARAMETER UPDATE BLOCK\n');
lf('================================================================\n\n');

lf(sprintf('%% Phase 3 estimates from AU data (%s)\n\n', datestr(now, 'yyyy-mm-dd')));

% Exchange rate
lf('%% Exchange rate UIP\n');
if ~isempty(s_est)
    for k = 1:length(s_names)
        lf(sprintf('%-18s = %+.6f;  %% (s.e. %.4f) was %.3f\n', s_names{k}, s_est(k), s_se(k), s_cal(k)));
    end
    % Check: rho_s should be < 1, alpha_s should be > 0
    if s_est(1) >= 1
        lf('%% WARNING: rho_s >= 1, keep calibrated\n');
    end
    if s_est(2) < 0
        lf('%% WARNING: alpha_s < 0, keep calibrated\n');
    end
end

lf('\n%% Housing prices\n');
if ~isempty(ph_est)
    for k = 1:length(ph_names)
        lf(sprintf('%-18s = %+.6f;  %% (s.e. %.4f) was %.3f\n', ph_names{k}, ph_est(k), ph_se(k), ph_cal(k)));
    end
end

lf('\n%% VA price target\n');
if ~isempty(pqs_est)
    for k = 1:length(pqs_names)
        lf(sprintf('%-18s = %+.6f;  %% (s.e. %.4f) was %.3f\n', pqs_names{k}, pqs_est(k), pqs_se(k), pqs_cal(k)));
    end
end

lf('\n%% Business inv target\n');
if ~isempty(ibt_est)
    for k = 1:length(ibt_names)
        lf(sprintf('%-18s = %+.6f;  %% (s.e. %.4f) was %.3f\n', ibt_names{k}, ibt_est(k), ibt_se(k), ibt_cal(k)));
    end
end

%% Save
results = struct();
results.exchange = struct('names', {s_names}, 'est', s_est, 'se', s_se, 'R2', s_R2);
results.housing = struct('names', {ph_names}, 'est', ph_est, 'se', ph_se, 'R2', ph_R2);
results.va_target = struct('names', {pqs_names}, 'est', pqs_est, 'se', pqs_se, 'R2', pqs_R2);
results.ib_target = struct('names', {ibt_names}, 'est', ibt_est, 'se', ibt_se);

save('phase3_estimation_results.mat', 'results');

lf(sprintf('\n  PHASE 3 COMPLETE: %s\n', datestr(now)));
fclose(fid);
fprintf('\n=== Phase 3 complete. See log_phase3_estimation.txt ===\n');

%% ========================================================================
%  LOCAL FUNCTIONS
%  ========================================================================
function series = load_fred_cached(fred_id, datadir, core_table, T)
    series = NaN(T, 1);
    localfile = fullfile(datadir, ['fred_' fred_id '.csv']);
    % Try cached file first
    if exist(localfile, 'file')
        try
            tbl = readtable(localfile);
            if height(tbl) > 5 && width(tbl) >= 2
                raw_dates = datetime(tbl{:,1});
                raw_values = tbl{:,2};
                qDates = datetime(core_table.date, 'InputFormat', 'yyyy-MM-dd');
                series = align_q(raw_dates, raw_values, qDates(1:T));
                return;
            end
        catch, end
    end
    % Try download
    url = ['https://fred.stlouisfed.org/graph/fredgraph.csv?id=' fred_id];
    try
        [status, ~] = system(sprintf('curl -skL "%s" -o "%s"', url, localfile));
        if status == 0
            fchk = fopen(localfile,'r'); first=fgetl(fchk); fclose(fchk);
            if ~contains(first,'<!DOCTYPE') && ~contains(first,'<html')
                tbl = readtable(localfile);
                if height(tbl) > 5
                    raw_dates = datetime(tbl{:,1});
                    raw_values = tbl{:,2};
                    qDates = datetime(core_table.date, 'InputFormat', 'yyyy-MM-dd');
                    series = align_q(raw_dates, raw_values, qDates(1:T));
                end
            end
        end
    catch, end
end

function aligned = align_q(raw_dates, raw_values, target_qdates)
    nQ = length(target_qdates);
    aligned = NaN(nQ, 1);
    for q = 1:nQ
        idx = find(year(raw_dates)==year(target_qdates(q)) & ...
                   ceil(month(raw_dates)/3)==ceil(month(target_qdates(q))/3), 1);
        if ~isempty(idx), aligned(q) = raw_values(idx); end
    end
end

function [beta, se, R2, T_eff] = ols_nan(Y, X)
    ok = ~any(isnan([Y, X]), 2);
    Y = Y(ok); X = X(ok,:);
    T_eff = length(Y); nP = size(X,2);
    if T_eff < nP + 5, beta=[]; se=[]; R2=NaN; return; end
    beta = X \ Y;
    resid = Y - X*beta;
    SSR = resid'*resid;
    SST = (Y-mean(Y))'*(Y-mean(Y));
    R2 = 1 - SSR/max(SST,1e-12);
    sigma2 = SSR/(T_eff-nP);
    se = sqrt(diag(sigma2 * inv(X'*X)));
end

function print_results(fid, title, names, beta, se, cal, R2, T_eff)
    fprintf(fid, '  %s:\n', title);
    if isempty(beta), fprintf(fid, '  Estimation FAILED\n\n'); return; end
    fprintf(fid, '  %-20s %10s %10s %8s %10s\n', 'Parameter', 'AU est.', 'Std.Err', 't-stat', 'Calibrated');
    fprintf(fid, '  %s\n', repmat('-', 1, 60));
    for k = 1:length(names)
        t = beta(k)/max(se(k),1e-12);
        sig=''; if abs(t)>2.576, sig='***'; elseif abs(t)>1.96, sig='**'; elseif abs(t)>1.645, sig='*'; end
        fprintf(fid, '  %-20s %+10.4f %10.4f %7.2f%-3s %+10.4f\n', names{k}, beta(k), se(k), t, sig, cal(k));
    end
    fprintf(fid, '  R2=%.4f, T=%d\n\n', R2, T_eff);
end

function [trend, cycle] = hpf(y, lambda)
    T = length(y); e = ones(T,1);
    D = spdiags([e -2*e e], 0:2, T-2, T);
    trend = (speye(T) + lambda*(D'*D)) \ y;
    cycle = y - trend;
end
