%% run_phase2_estimation.m — Phase 2: Trade block + demand deflator estimation
%
% Downloads additional AU data (REER, commodity prices) and estimates:
%   1. Export ECM: 5 parameters (b0_x, b1_x, b2_x, b3_x, b4_x)
%   2. Import ECM: 4 parameters (b0_m, b1_m, b2_m, b3_m)
%   3. 6 demand deflator ECM equations: ~14 parameters
%
% Uses FRED for REER and commodity prices, existing data for the rest.
% Constructs export/import growth from available OECD national accounts data.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

logfile = 'log_phase2_estimation.txt';
fid = fopen(logfile, 'w');
lf = @(msg) fprintf(fid, msg);
lf('================================================================\n');
lf('  PHASE 2: TRADE + DEFLATOR ESTIMATION\n');
lf(sprintf('  %s\n', datestr(now)));
lf('================================================================\n\n');

%% ========================================================================
%  PART 1: Load and construct data
%  ========================================================================
lf('--- Loading existing data ---\n');

core = readtable('c:\Users\david\french_model\dataset.csv');
ext = readtable('c:\Users\david\french_model\data\extended_dataset.csv');
T = min(height(core), height(ext));

yhat_au = core.au_ygap(1:T);
pi_au = core.au_pi(1:T);        % GDP deflator inflation (quarterly %)
i_au = core.au_irate(1:T);
yhat_us = core.us_ygap(1:T);

i_ss = 1.0491; pi_ss = 0.625;
i_gap = i_au - i_ss;
pi_gap = pi_au - pi_ss;

% Extended data
urate = ext.au_urate(1:T);
pi_w = ext.au_pi_w(1:T);
cons = ext.au_consumption(1:T);
gfcf_nd = ext.au_gfcf_nondwelling(1:T);
gfcf_dw = ext.au_gfcf_dwelling(1:T);
exports_raw = ext.au_exports(1:T);
imports_raw = ext.au_imports(1:T);
i10y = ext.au_i10(1:T);

lf(sprintf('  Core data: T=%d\n', T));
lf(sprintf('  Exports available: %d non-NaN\n', sum(~isnan(exports_raw))));
lf(sprintf('  Imports available: %d non-NaN\n', sum(~isnan(imports_raw))));

%% Download REER and commodity prices from FRED
lf('\n--- Downloading additional FRED data ---\n');
datadir = 'c:\Users\david\french_model\data';

% Real Effective Exchange Rate (BIS broad, quarterly)
reer = download_fred_series('CCRETT01AUQ661N', 'AU REER (BIS broad)', datadir, core, T, fid);

% IMF All Commodity Price Index (quarterly average)
pcom_idx = download_fred_series('PALLFNFINDEXQ', 'IMF All Commodity Prices', datadir, core, T, fid);

% If REER failed, try alternative
if sum(~isnan(reer)) < 20
    lf('  Trying alternative REER series...\n');
    reer = download_fred_series('CCRETT02AUQ661N', 'AU REER narrow', datadir, core, T, fid);
end

%% Construct trade variables
lf('\n--- Constructing trade and deflator variables ---\n');

% Export/import volume growth
% If FRED data available, use it; otherwise construct proxy
dln_x = NaN(T, 1);
dln_m = NaN(T, 1);

if sum(~isnan(exports_raw)) > 20
    dln_x = [NaN; diff(log(exports_raw))] * 100;
    lf(sprintf('  dln_x from FRED export volumes: %d valid\n', sum(~isnan(dln_x))));
else
    % Proxy: use GDP growth + terms-of-trade proxy
    % Export volume ~ track world demand and commodity prices
    lf('  WARNING: Export volumes not available. Using proxy (GDP growth + yhat_us)\n');
    % Simple proxy: export growth tracks world demand
    dln_x(3:T) = 0.3 * yhat_us(3:T) + 0.15 * (pi_au(2:T-1) - pi_au(1:T-2));
end

if sum(~isnan(imports_raw)) > 20
    dln_m = [NaN; diff(log(imports_raw))] * 100;
    lf(sprintf('  dln_m from FRED import volumes: %d valid\n', sum(~isnan(dln_m))));
else
    lf('  WARNING: Import volumes not available. Using consumption/investment proxy\n');
    % Import growth tracks domestic demand
    valid_c = ~isnan(cons);
    dc = [NaN; diff(log(cons))] * 100;
    dln_m(valid_c) = dc(valid_c) * 1.5;  % income elasticity of imports ~1.5
end

% Real effective exchange rate gap (log deviation from HP trend)
s_gap_data = NaN(T, 1);
if sum(~isnan(reer)) > 20
    valid_r = ~isnan(reer);
    ln_reer = log(reer);
    [reer_trend, ~] = hpfilter_local(ln_reer(valid_r), 1600);
    s_gap_data(valid_r) = (ln_reer(valid_r) - reer_trend) * 100;  % in %
    lf(sprintf('  s_gap from REER: %d valid, range [%.1f, %.1f]\n', ...
        sum(~isnan(s_gap_data)), min(s_gap_data(valid_r)), max(s_gap_data(valid_r))));
else
    lf('  WARNING: REER not available. s_gap set to zero.\n');
    s_gap_data = zeros(T, 1);
end

% Commodity price growth
dln_pcom = NaN(T, 1);
if sum(~isnan(pcom_idx)) > 20
    dln_pcom = [NaN; diff(log(pcom_idx))] * 100;
    lf(sprintf('  dln_pcom from IMF index: %d valid\n', sum(~isnan(dln_pcom))));
else
    lf('  WARNING: Commodity prices not available. dln_pcom set to zero.\n');
    dln_pcom = zeros(T, 1);
end

% Export/import gap (cumulative)
x_gap = NaN(T, 1);
m_gap = NaN(T, 1);
x_gap(1) = 0; m_gap(1) = 0;
for t = 2:T
    if ~isnan(dln_x(t)), x_gap(t) = x_gap(t-1) - dln_x(t);
    else, x_gap(t) = x_gap(t-1); end
    if ~isnan(dln_m(t)), m_gap(t) = m_gap(t-1) - dln_m(t);
    else, m_gap(t) = m_gap(t-1); end
end

% Import-adjusted demand (weighted domestic demand)
% iad = w_c*dln_c + w_ib*dln_ib + w_ih*dln_ih + w_g*dln_g + w_x*dln_x
% Simplified: use total domestic demand growth as proxy
dc = [NaN; diff(log(cons))] * 100;
dib = [NaN; diff(log(gfcf_nd))] * 100;
dih = [NaN; diff(log(gfcf_dw))] * 100;
iad = 0.20 * dc + 0.25 * dib + 0.25 * dih + 0.20 * dln_x;  % IAD weights
iad(isnan(iad)) = yhat_au(isnan(iad));  % fallback

% Demand deflator proxies
% piQ: VA price inflation — use GDP deflator inflation (au_pi)
piQ = pi_au;

% pi_m: import deflator — proxy from REER changes + commodity prices
% Depreciation (s_gap up) -> higher import prices; commodity prices pass through
pi_m_proxy = pi_ss + 0.5 * [NaN; diff(s_gap_data)] + 0.3 * dln_pcom;
pi_m_proxy(isnan(pi_m_proxy)) = pi_ss;

% pi_c: consumption deflator — try CPI from FRED cache
cpi_file = fullfile(datadir, 'fred_AUSCPIALLQINMEI.csv');
pi_c_proxy = NaN(T, 1);
if exist(cpi_file, 'file')
    try
        cpi_tbl = readtable(cpi_file);
        cpi_dates = datetime(cpi_tbl{:,1});
        cpi_vals = cpi_tbl{:,2};
        qDates_core = datetime(core.date, 'InputFormat', 'yyyy-MM-dd');
        cpi_aligned = align_quarterly(cpi_dates, cpi_vals, qDates_core(1:T));
        % Quarterly inflation = 100 * log(CPI_t/CPI_{t-1})
        pi_c_proxy = [NaN; diff(log(cpi_aligned))] * 100;
        lf(sprintf('  pi_c from CPI (AUSCPIALLQINMEI): %d valid\n', sum(~isnan(pi_c_proxy))));
    catch
        lf('  CPI file exists but failed to parse. Using GDP deflator as pi_c proxy.\n');
        pi_c_proxy = pi_au;
    end
else
    lf('  No CPI file found. Using GDP deflator as pi_c proxy.\n');
    pi_c_proxy = pi_au;
end

% pi_w already available; dln_prod = 0 (gap model)
dln_prod = zeros(T, 1);

lf('\n');

%% ========================================================================
%  PART 2: Estimate Trade Block
%  ========================================================================
lf('================================================================\n');
lf('  TRADE BLOCK ESTIMATION\n');
lf('================================================================\n\n');

% --- Export equation ---
% dln_x = b0_x*x_gap(-1) + b1_x*dln_x(-1) + b2_x*yhat_us + b3_x*s_gap + b4_x*dln_pcom
lf('--- Export equation ---\n');
lf('  dln_x = b0_x*x_gap(-1) + b1_x*dln_x(-1) + b2_x*yhat_us + b3_x*s_gap + b4_x*dln_pcom\n\n');

Y_x = dln_x(3:T);
X_x = [x_gap(2:T-1), dln_x(2:T-1), yhat_us(3:T), s_gap_data(3:T), dln_pcom(3:T)];
x_names = {'b0_x', 'b1_x', 'b2_x', 'b3_x', 'b4_x'};
x_cal = [0.05, 0.30, 0.25, 0.10, 0.15];

[x_est, x_se, x_R2, x_T] = ols_with_nan(Y_x, X_x);
print_ols_results(fid, x_names, x_est, x_se, x_cal, x_R2, x_T);

% ECM stability check
if ~isempty(x_est) && x_est(1) > 0
    lf('  WARNING: b0_x > 0 (unstable ECM). Keeping calibrated value.\n');
    x_est(1) = -abs(x_cal(1));
end

% --- Import equation ---
% dln_m = b0_m*m_gap(-1) + b1_m*dln_m(-1) + b2_m*iad + b3_m*s_gap
lf('\n--- Import equation ---\n');
lf('  dln_m = b0_m*m_gap(-1) + b1_m*dln_m(-1) + b2_m*iad + b3_m*s_gap\n\n');

Y_m = dln_m(3:T);
X_m = [m_gap(2:T-1), dln_m(2:T-1), iad(3:T), s_gap_data(3:T)];
m_names = {'b0_m', 'b1_m', 'b2_m', 'b3_m'};
m_cal = [0.06, 0.25, 0.30, -0.08];

[m_est, m_se, m_R2, m_T] = ols_with_nan(Y_m, X_m);
print_ols_results(fid, m_names, m_est, m_se, m_cal, m_R2, m_T);

if ~isempty(m_est) && m_est(1) > 0
    lf('  WARNING: b0_m > 0 (unstable ECM). Keeping calibrated value.\n');
    m_est(1) = -abs(m_cal(1));
end

%% ========================================================================
%  PART 3: Estimate Demand Deflator Equations
%  ========================================================================
lf('\n================================================================\n');
lf('  DEMAND DEFLATOR ESTIMATION\n');
lf('================================================================\n\n');

pibar = pi_ss;  % use model SS as inflation anchor

% --- Consumption deflator ---
% pi_c = rho*pi_c(-1) + alpha*piQ + beta_m*pi_m + (1-rho-alpha-beta_m)*pibar + eps
% Reparameterize: (pi_c - pibar) = rho*(pi_c(-1)-pibar) + alpha*(piQ-pibar) + beta_m*(pi_m-pibar)
lf('--- Consumption deflator (pi_c) ---\n');
lf('  Reparameterized gap form with growth neutrality constraint\n\n');

idx = 3:T;  % need lags
Y_pc = pi_c_proxy(idx) - pibar;
X_pc = [pi_c_proxy(idx-1) - pibar, piQ(idx) - pibar, pi_m_proxy(idx) - pibar];
pc_names = {'rho_pc', 'alpha_pc', 'beta_pc_m'};
pc_cal = [0.40, 0.30, 0.10];
[pc_est, pc_se, pc_R2, pc_T] = ols_with_nan(Y_pc, X_pc);
print_ols_results(fid, pc_names, pc_est, pc_se, pc_cal, pc_R2, pc_T);
check_growth_neutrality(fid, pc_est, pc_names);

% --- Business investment deflator ---
lf('\n--- Business investment deflator (pi_ib) ---\n');
lf('  SKIPPED: No separate investment deflator data. Using GDP deflator as LHS\n');
lf('  and VA price (= GDP deflator) as RHS creates tautology. Keep calibrated.\n\n');
pib_names = {'rho_pib', 'alpha_pib', 'beta_pib_m'};
pib_cal = [0.35, 0.25, 0.12];
pib_est = []; pib_se = []; pib_R2 = NaN; pib_T = 0;

% --- Housing investment deflator ---
lf('\n--- Housing investment deflator (pi_ih) ---\n');
lf('  SKIPPED: Same tautology issue. Keep calibrated.\n\n');
pih_names = {'rho_pih', 'alpha_pih', 'beta_pih_m'};
pih_cal = [0.45, 0.25, 0.08];
pih_est = []; pih_se = []; pih_R2 = NaN; pih_T = 0;

% --- Export deflator ---
lf('\n--- Export deflator (pi_x) ---\n');
lf('  SKIPPED: No separate export deflator data. Keep calibrated.\n\n');
px_names = {'rho_px', 'alpha_px', 'beta_px', 'alpha_pcom'};
px_cal = [0.30, 0.20, -0.05, 0.10];
px_est = []; px_se = []; px_R2 = NaN; px_T = 0;

% --- Import deflator ---
lf('\n--- Import deflator (pi_m) ---\n');
lf('  Exchange rate pass-through + commodity prices\n\n');
% For import deflator, use the proxy we constructed
Y_pm = pi_m_proxy(idx) - pibar;
X_pm = [pi_m_proxy(idx-1) - pibar, piQ(idx) - pibar, s_gap_data(idx), dln_pcom(idx)];
pm_names = {'rho_pm', 'alpha_pm', 'beta_pm', 'beta_pm_com'};
pm_cal = [0.30, 0.15, 0.08, 0.05];
[pm_est, pm_se, pm_R2, pm_T] = ols_with_nan(Y_pm, X_pm);
print_ols_results(fid, pm_names, pm_est, pm_se, pm_cal, pm_R2, pm_T);

% --- Government deflator ---
lf('\n--- Government deflator (pi_g) ---\n');
lf('  Driven by public sector wages (pi_w - dln_prod)\n\n');
eff_wage = pi_w - dln_prod;  % efficient wage inflation
Y_pg = pi_au(idx) - pibar;  % proxy
X_pg = [pi_au(idx-1) - pibar, eff_wage(idx) - pibar];
pg_names = {'rho_pg', 'alpha_pg'};
pg_cal = [0.50, 0.30];
[pg_est, pg_se, pg_R2, pg_T] = ols_with_nan(Y_pg, X_pg);
print_ols_results(fid, pg_names, pg_est, pg_se, pg_cal, pg_R2, pg_T);

% --- Commodity price AR ---
lf('\n--- Commodity price AR(1) ---\n');
lf('  dln_pcom = rho_pcom*dln_pcom(-1) + alpha*yhat_us\n\n');
Y_pcom = dln_pcom(3:T);
X_pcom = [dln_pcom(2:T-1), yhat_us(3:T)];
pcom_names = {'rho_pcom', 'pcom_us'};
pcom_cal = [0.85, 0.10];
[pcom_est, pcom_se, pcom_R2, pcom_T] = ols_with_nan(Y_pcom, X_pcom);
print_ols_results(fid, pcom_names, pcom_est, pcom_se, pcom_cal, pcom_R2, pcom_T);

%% ========================================================================
%  PART 4: Parameter update block
%  ========================================================================
lf('\n================================================================\n');
lf('  PARAMETER UPDATE BLOCK (copy to .mod files)\n');
lf('================================================================\n\n');

lf(sprintf('%% Phase 2 estimates from AU data (%s)\n\n', datestr(now, 'yyyy-mm-dd')));

% Trade block
lf('%% Export equation (ECM)\n');
if ~isempty(x_est)
    for k = 1:length(x_names)
        lf(sprintf('%-18s = %+.6f;  %% (s.e. %.4f) was %.3f\n', ...
            x_names{k}, x_est(k), x_se(k), x_cal(k)));
    end
end

lf('\n%% Import equation (ECM)\n');
if ~isempty(m_est)
    for k = 1:length(m_names)
        lf(sprintf('%-18s = %+.6f;  %% (s.e. %.4f) was %.3f\n', ...
            m_names{k}, m_est(k), m_se(k), m_cal(k)));
    end
end

% Deflator results
deflator_sets = {
    pc_names, pc_est, pc_se, pc_cal, 'Consumption deflator';
    pib_names, pib_est, pib_se, pib_cal, 'Business inv deflator';
    pih_names, pih_est, pih_se, pih_cal, 'Housing inv deflator';
    px_names, px_est, px_se, px_cal, 'Export deflator';
    pm_names, pm_est, pm_se, pm_cal, 'Import deflator';
    pg_names, pg_est, pg_se, pg_cal, 'Government deflator';
    pcom_names, pcom_est, pcom_se, pcom_cal, 'Commodity price AR';
};

for d = 1:size(deflator_sets, 1)
    names = deflator_sets{d, 1};
    est = deflator_sets{d, 2};
    se = deflator_sets{d, 3};
    cal = deflator_sets{d, 4};
    desc = deflator_sets{d, 5};

    lf(sprintf('\n%% %s\n', desc));
    if ~isempty(est)
        for k = 1:length(names)
            lf(sprintf('%-18s = %+.6f;  %% (s.e. %.4f) was %.3f\n', ...
                names{k}, est(k), se(k), cal(k)));
        end
    else
        lf('%% Estimation failed — keeping calibrated values\n');
    end
end

%% Save results
results = struct();
results.trade.x_names = x_names; results.trade.x_est = x_est; results.trade.x_se = x_se;
results.trade.m_names = m_names; results.trade.m_est = m_est; results.trade.m_se = m_se;
results.deflators.pc = struct('names', {pc_names}, 'est', pc_est, 'se', pc_se);
results.deflators.pib = struct('names', {pib_names}, 'est', pib_est, 'se', pib_se);
results.deflators.pih = struct('names', {pih_names}, 'est', pih_est, 'se', pih_se);
results.deflators.px = struct('names', {px_names}, 'est', px_est, 'se', px_se);
results.deflators.pm = struct('names', {pm_names}, 'est', pm_est, 'se', pm_se);
results.deflators.pg = struct('names', {pg_names}, 'est', pg_est, 'se', pg_se);
results.deflators.pcom = struct('names', {pcom_names}, 'est', pcom_est, 'se', pcom_se);

save('phase2_estimation_results.mat', 'results');

lf('\n================================================================\n');
lf(sprintf('  PHASE 2 COMPLETE: %s\n', datestr(now)));
lf('================================================================\n');
fclose(fid);

fprintf('\n=== Phase 2 estimation complete ===\n');
fprintf('  Log: %s\n', logfile);
fprintf('  Results: phase2_estimation_results.mat\n');

%% ========================================================================
%  LOCAL FUNCTIONS
%  ========================================================================

function series = download_fred_series(fred_id, desc, datadir, core_table, T, fid)
    % Download a FRED series and align to model sample
    series = NaN(T, 1);
    url = ['https://fred.stlouisfed.org/graph/fredgraph.csv?id=' fred_id];
    localfile = fullfile(datadir, ['fred_' fred_id '.csv']);

    fprintf(fid, '  Downloading %s (%s)... ', desc, fred_id);
    try
        % Try websave first
        opts = weboptions('Timeout', 30);
        websave(localfile, url, opts);
        tbl = readtable(localfile);
        if height(tbl) > 5 && width(tbl) >= 2
            raw_dates = datetime(tbl{:,1});
            raw_values = tbl{:,2};
            % Align to quarterly model dates
            qDates = datetime(core_table.date, 'InputFormat', 'yyyy-MM-dd');
            series = align_quarterly(raw_dates, raw_values, qDates(1:T));
            fprintf(fid, 'OK (%d obs, %d aligned)\n', height(tbl), sum(~isnan(series)));
            return;
        end
    catch
    end

    % Try curl fallback
    try
        [status, ~] = system(sprintf('curl -skL "%s" -o "%s"', url, localfile));
        if status == 0 && exist(localfile, 'file')
            fchk = fopen(localfile, 'r'); first = fgetl(fchk); fclose(fchk);
            if ~contains(first, '<!DOCTYPE') && ~contains(first, '<html')
                tbl = readtable(localfile);
                if height(tbl) > 5
                    raw_dates = datetime(tbl{:,1});
                    raw_values = tbl{:,2};
                    qDates = datetime(core_table.date, 'InputFormat', 'yyyy-MM-dd');
                    series = align_quarterly(raw_dates, raw_values, qDates(1:T));
                    fprintf(fid, 'OK via curl (%d aligned)\n', sum(~isnan(series)));
                    return;
                end
            end
        end
    catch
    end

    % Check if local file exists from previous download
    if exist(localfile, 'file')
        try
            tbl = readtable(localfile);
            if height(tbl) > 5 && width(tbl) >= 2
                raw_dates = datetime(tbl{:,1});
                raw_values = tbl{:,2};
                qDates = datetime(core_table.date, 'InputFormat', 'yyyy-MM-dd');
                series = align_quarterly(raw_dates, raw_values, qDates(1:T));
                fprintf(fid, 'CACHED (%d aligned)\n', sum(~isnan(series)));
                return;
            end
        catch
        end
    end

    fprintf(fid, 'FAILED\n');
end

function aligned = align_quarterly(raw_dates, raw_values, target_qdates)
    nQ = length(target_qdates);
    aligned = NaN(nQ, 1);
    raw_yr = year(raw_dates);
    raw_mo = month(raw_dates);
    raw_qq = ceil(raw_mo / 3);
    tgt_yr = year(target_qdates);
    tgt_mo = month(target_qdates);
    tgt_qq = ceil(tgt_mo / 3);
    for q = 1:nQ
        idx = find(raw_yr == tgt_yr(q) & raw_qq == tgt_qq(q), 1, 'first');
        if ~isempty(idx)
            aligned(q) = raw_values(idx);
        end
    end
end

function [beta, se, R2, T_eff] = ols_with_nan(Y, X)
    % OLS with NaN removal
    ok = ~any(isnan([Y, X]), 2);
    Y = Y(ok);
    X = X(ok, :);
    T_eff = length(Y);
    nP = size(X, 2);

    if T_eff < nP + 5
        beta = []; se = []; R2 = NaN;
        return;
    end

    beta = X \ Y;
    resid = Y - X * beta;
    SSR = resid' * resid;
    SST = (Y - mean(Y))' * (Y - mean(Y));
    R2 = 1 - SSR / max(SST, 1e-12);
    sigma2 = SSR / (T_eff - nP);
    se = sqrt(diag(sigma2 * inv(X' * X)));
end

function print_ols_results(fid, names, beta, se, cal, R2, T_eff)
    if isempty(beta)
        fprintf(fid, '  Estimation FAILED (insufficient data)\n');
        return;
    end
    fprintf(fid, '  %-18s %10s %10s %8s %10s\n', 'Parameter', 'AU est.', 'Std.Err', 't-stat', 'Calibrated');
    fprintf(fid, '  %s\n', repmat('-', 1, 58));
    for k = 1:length(names)
        t = beta(k) / max(se(k), 1e-12);
        sig = '';
        if abs(t) > 2.576, sig = '***';
        elseif abs(t) > 1.960, sig = '**';
        elseif abs(t) > 1.645, sig = '*'; end
        fprintf(fid, '  %-18s %+10.4f %10.4f %7.2f%-3s %+10.4f\n', ...
            names{k}, beta(k), se(k), t, sig, cal(k));
    end
    fprintf(fid, '  R2=%.4f, T=%d\n', R2, T_eff);
end

function check_growth_neutrality(fid, beta, names)
    if isempty(beta), return; end
    coeff_sum = sum(beta);
    fprintf(fid, '  Growth neutrality: sum of coefficients = %.4f (should be < 1)\n', coeff_sum);
    if coeff_sum >= 1
        fprintf(fid, '  WARNING: Growth neutrality violated\n');
    end
end

function [trend, cycle] = hpfilter_local(y, lambda)
    T = length(y);
    e = ones(T, 1);
    D = spdiags([e -2*e e], 0:2, T-2, T);
    trend = (speye(T) + lambda * (D' * D)) \ y;
    cycle = y - trend;
end
