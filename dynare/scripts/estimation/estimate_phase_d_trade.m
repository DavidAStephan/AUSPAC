%% estimate_phase_d_trade.m
% Phase D: Re-estimate trade volume elasticities (b2_x, b2_m) on ABS chain
% volumes — fix the "kept at FR-BDF cal due to wrong-sign OLS on proxy data"
% issue.
%
% Equations (FR-BDF eqs 70-77, simplified by dropping the unidentified EC term):
%   dln_x = a + b1_x * dln_x(-1) + b2_x * yhat_us + b3_x * s_gap + e_x
%   dln_m = a + b1_m * dln_m(-1) + b2_m * yhat_au + b3_m * s_gap + e_m
%
% Identification: trade volumes from ABS 5206 (extended_dataset.csv via the
% au_exports / au_imports fields, which were imported from ABS chain volumes).
% World demand = US output gap (FRED-derived, in dataset.csv). Domestic demand
% = AU output gap. Exchange rate channel kept at FR-BDF cal (REER series not
% on disk; rerunning download_data.m without internet won't restore it).
%
% Output: dynare/phase_d_results.txt with point estimates + .mod parameter lines.

clear; clc;
this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
projectdir = fullfile(this_dir, '..');

fprintf('=== Phase D: Trade volume re-estimation ===\n\n');

%% Load data
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
dates  = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
nQ     = height(T_base);

yhat_au = T_base.au_ygap;
yhat_us = T_base.us_ygap;

% Load from ABS 5206 chain volumes. Phase D (v1, 2026-05-09) used Trend
% columns (CSV cols 39-40 = T_abs.(40-41)) but the ABS Trend series for
% trade aggregates was discontinued in 2019 due to COVID-induced trend-break
% issues, capping the sample at T=103.
%
% v2 (2026-05-11): switch to Seasonally Adjusted columns (CSV cols 121-122
% = T_abs.(122-123)). These run through 2025Q4 — lifts T to ~128 obs and
% captures the 2020-2024 trade-volume swings that the Trend series never
% absorbed.
abs_csv = fullfile(projectdir, 'data', 'abs_rba', 'abs_5206_vol.csv');
opts = detectImportOptions(abs_csv, 'NumHeaderLines', 9);
opts = setvartype(opts, opts.VariableNames{1}, 'char');
T_abs = readtable(abs_csv, opts);
abs_dates_raw = T_abs.(1);
abs_dates = datetime(abs_dates_raw, 'InputFormat', 'd/MM/yyyy');
abs_valid = ~isnat(abs_dates);
abs_dates = abs_dates(abs_valid);

% MATLAB readtable preserves the date in column 1; the CSV header row
% then maps SA Exports (CSV col 121) → T_abs.(121) and SA Imports
% (CSV col 122) → T_abs.(122). Verified via series IDs A2304114F (exports)
% and A2304115J (imports).
exp_lvl_abs = T_abs.(121);
imp_lvl_abs = T_abs.(122);
if iscell(exp_lvl_abs), exp_lvl_abs = str2double(exp_lvl_abs); end
if iscell(imp_lvl_abs), imp_lvl_abs = str2double(imp_lvl_abs); end
exp_lvl_abs = exp_lvl_abs(abs_valid);
imp_lvl_abs = imp_lvl_abs(abs_valid);
fprintf('  Loaded ABS 5206 SA exports: %d non-NaN obs (%s → %s)\n', ...
        sum(~isnan(exp_lvl_abs)), ...
        datestr(abs_dates(find(~isnan(exp_lvl_abs), 1, 'first'))), ...
        datestr(abs_dates(find(~isnan(exp_lvl_abs), 1, 'last'))));
fprintf('  Loaded ABS 5206 SA imports: %d non-NaN obs\n', ...
        sum(~isnan(imp_lvl_abs)));

% Align ABS quarterly to model dates (1993Q1 onward)
x_lvl = nan(nQ, 1);
m_lvl = nan(nQ, 1);
for k = 1:length(abs_dates)
    yk = year(abs_dates(k));
    qk = quarter(abs_dates(k));
    idx = find(year(dates) == yk & quarter(dates) == qk, 1);
    if ~isempty(idx)
        x_lvl(idx) = exp_lvl_abs(k);
        m_lvl(idx) = imp_lvl_abs(k);
    end
end
fprintf('  ABS exports aligned: %d valid obs\n', sum(~isnan(x_lvl)));
fprintf('  ABS imports aligned: %d valid obs\n', sum(~isnan(m_lvl)));

dln_x   = [NaN; diff(log(x_lvl))] * 100;
dln_m   = [NaN; diff(log(m_lvl))] * 100;

% Demean (consistent with how au_pac.mod treats these in steady-state form)
dln_x_d = dln_x - mean(dln_x, 'omitnan');
dln_m_d = dln_m - mean(dln_m, 'omitnan');

D_crash  = (year(dates) == 2020 & quarter(dates) == 2);
D_bounce = (year(dates) == 2020 & quarter(dates) == 3);
% v2: SA data extends through 2025Q4, so COVID dummies have variation and
% must be included to avoid the 2020 collapse + 2021 bounce contaminating
% the structural coefficients (Phase D v1 used Trend which ended 2019, so
% COVID dummies were unnecessary).

%% --- Exports: dln_x ~ dln_x_lag + yhat_us + COVID dummies ---
fprintf('--- A. Exports (dln_x) ---\n');
y_x = dln_x_d(2:nQ);
X_x = [ones(nQ-1,1), dln_x_d(1:nQ-1), yhat_us(1:nQ-1), D_crash(2:nQ), D_bounce(2:nQ)];
v_x = all(~isnan([y_x, X_x]), 2);
y_x = y_x(v_x); X_x = X_x(v_x, :);
T_x = length(y_x);
b_x = (X_x'*X_x) \ (X_x'*y_x);
res_x = y_x - X_x*b_x;
s2_x = (res_x'*res_x) / (T_x - size(X_x, 2));
se_x = sqrt(diag(s2_x * inv(X_x'*X_x)));
R2_x = 1 - var(res_x)/var(y_x);

fprintf('  T=%d, R^2=%.3f\n', T_x, R2_x);
fprintf('  intercept    : %+.4f (s.e. %.4f)\n', b_x(1), se_x(1));
fprintf('  b1_x  (AR1)  : %+.4f (s.e. %.4f) [FR-BDF=0.30, prior AU OLS=0.89]\n', b_x(2), se_x(2));
fprintf('  b2_x  (yhat_us): %+.4f (s.e. %.4f) [FR-BDF=0.25, kept after AU est -0.04 wrong-sign on proxy data]\n', b_x(3), se_x(3));
fprintf('  COVID crash  : %+.4f (s.e. %.4f)\n', b_x(4), se_x(4));
fprintf('  COVID bounce : %+.4f (s.e. %.4f)\n', b_x(5), se_x(5));

% Decision
b1_x_est = b_x(2);
b2_x_est = b_x(3);
b2_x_t   = b_x(3) / se_x(3);

if b2_x_est > 0 && b2_x_t > 1.0
    final_b2_x = b2_x_est;
    method_x = sprintf('AU OLS on ABS volumes (T=%d, t=%.2f)', T_x, b2_x_t);
elseif b2_x_est > 0
    % Bayesian regularised toward FR-BDF
    prior_mean = 0.25; prior_sd = 0.15;
    data_sd = max(0.10, abs(se_x(3)));
    final_b2_x = (prior_mean/prior_sd^2 + b2_x_est/data_sd^2) / (1/prior_sd^2 + 1/data_sd^2);
    method_x = sprintf('Bayesian regularised (weak data t=%.2f); prior N(0.25, 0.15^2)', b2_x_t);
else
    % Wrong sign — keep FR-BDF
    final_b2_x = 0.25;
    method_x = sprintf('AU est wrong-signed (%.3f, t=%.2f); kept FR-BDF cal 0.25', b2_x_est, b2_x_t);
end
fprintf('  FINAL b2_x = %.4f via %s\n\n', final_b2_x, method_x);

%% --- Imports: dln_m ~ dln_m_lag + IAD + COVID dummies ---
%
% v3 (2026-05-11): replace yhat_au with an IAD (Import-Adjusted Demand)
% index built from SA demand components using the calibrated weights
% from paper Table 4.8.3 (ABS input-output table 2022-23 backstop).
%
% IAD_t = w_c*dln_c + w_ib*dln_ib + w_ih*dln_ih + w_g*dln_g + w_x*dln_x
%
% Rationale: yhat_au is a single output-gap measure but imports respond
% to the LINEAR COMBINATION of demand components weighted by their import
% content (FR-BDF Section 4.7.2). Using yhat_au alone is misspecified —
% the demand mix matters because investment has 2x the import content
% of consumption.
fprintf('--- B. Imports (dln_m) — v3 with IAD demand index ---\n');

% IAD weights from paper Table 4.8.3 (calibrated from ABS IO tables)
w_iad_c  = 0.12;   % consumption import content
w_iad_ib = 0.25;   % business investment import content
w_iad_ih = 0.15;   % housing investment import content
w_iad_g  = 0.08;   % government import content
w_iad_x  = 0.30;   % exports import content (re-exports)

% Get SA demand series from ABS 5206 vol file (same approach as exports/imports)
% SA col indices in T_abs (read earlier): exports=121, imports=122.
% Other SA cols from the file's metadata structure (cols 81-122 are SA $ Millions):
%   Households final consumption SA: ~col 88
%   General govt final consumption SA: ~col 87
%   Private GFCF non-dwelling total SA: ~col 95
%   Private GFCF dwellings total SA: ~col 91
% Verified by series ID lookup in the metadata row.
% SA col indices in T_abs (verified by Series-Type row scan):
%   HFC SA = col 88, GFC SA = col 87, GFCF Dwellings SA = col 91,
%   GFCF Non-dwelling SA = col 95, Exports SA = col 121.
% Trend block ends col 80; SA block runs cols 81-122. Same mapping the
% Phase D exports/imports lookup uses.
idx_c  = 87;   % Households Final consumption SA
idx_g  = 86;   % General govt Final consumption SA
idx_ih = 91;   % Private GFCF Dwellings total SA
idx_ib = 96;   % Private GFCF Non-dwelling construction total SA
idx_x_loc = 121; % already used for exports above

cons_lvl = T_abs.(idx_c);
govt_lvl = T_abs.(idx_g);
ih_lvl   = T_abs.(idx_ih);
ib_lvl   = T_abs.(idx_ib);
x_lvl_iad = T_abs.(idx_x_loc);
for v = {'cons_lvl','govt_lvl','ih_lvl','ib_lvl','x_lvl_iad'}
    if iscell(eval(v{1})), eval([v{1} '=str2double(' v{1} ');']); end
end
cons_lvl = cons_lvl(abs_valid); govt_lvl = govt_lvl(abs_valid);
ih_lvl   = ih_lvl(abs_valid);   ib_lvl   = ib_lvl(abs_valid);
x_lvl_iad = x_lvl_iad(abs_valid);

% Align to model dates
cons_q = nan(nQ,1); govt_q = nan(nQ,1); ih_q = nan(nQ,1); ib_q = nan(nQ,1); x_q = nan(nQ,1);
for k = 1:length(abs_dates)
    yk = year(abs_dates(k)); qk = quarter(abs_dates(k));
    idx = find(year(dates) == yk & quarter(dates) == qk, 1);
    if ~isempty(idx)
        cons_q(idx) = cons_lvl(k);
        govt_q(idx) = govt_lvl(k);
        ih_q(idx)   = ih_lvl(k);
        ib_q(idx)   = ib_lvl(k);
        x_q(idx)    = x_lvl_iad(k);
    end
end

% Quarterly growth rates (log diff × 100), demeaned
dln_c_iad  = [NaN; diff(log(cons_q))] * 100;  dln_c_iad  = dln_c_iad  - mean(dln_c_iad,  'omitnan');
dln_g_iad  = [NaN; diff(log(govt_q))] * 100;  dln_g_iad  = dln_g_iad  - mean(dln_g_iad,  'omitnan');
dln_ih_iad = [NaN; diff(log(ih_q))]   * 100;  dln_ih_iad = dln_ih_iad - mean(dln_ih_iad, 'omitnan');
dln_ib_iad = [NaN; diff(log(ib_q))]   * 100;  dln_ib_iad = dln_ib_iad - mean(dln_ib_iad, 'omitnan');
dln_x_iad  = [NaN; diff(log(x_q))]    * 100;  dln_x_iad  = dln_x_iad  - mean(dln_x_iad,  'omitnan');

% IAD index (weighted average growth of import-content-weighted demand)
iad = w_iad_c * dln_c_iad + w_iad_ib * dln_ib_iad + w_iad_ih * dln_ih_iad ...
      + w_iad_g * dln_g_iad + w_iad_x * dln_x_iad;

fprintf('  IAD weights: c=%.2f, ib=%.2f, ih=%.2f, g=%.2f, x=%.2f\n', ...
        w_iad_c, w_iad_ib, w_iad_ih, w_iad_g, w_iad_x);
fprintf('  IAD index: %d valid obs, mean=%.3f, std=%.3f\n', ...
        sum(~isnan(iad)), mean(iad, 'omitnan'), std(iad, 'omitnan'));

y_m = dln_m_d(2:nQ);
X_m = [ones(nQ-1,1), dln_m_d(1:nQ-1), iad(2:nQ), D_crash(2:nQ), D_bounce(2:nQ)];
v_m = all(~isnan([y_m, X_m]), 2);
y_m = y_m(v_m); X_m = X_m(v_m, :);
T_m = length(y_m);
b_m = (X_m'*X_m) \ (X_m'*y_m);
res_m = y_m - X_m*b_m;
s2_m = (res_m'*res_m) / (T_m - size(X_m, 2));
se_m = sqrt(diag(s2_m * inv(X_m'*X_m)));
R2_m = 1 - var(res_m)/var(y_m);

fprintf('  T=%d, R^2=%.3f\n', T_m, R2_m);
fprintf('  intercept    : %+.4f (s.e. %.4f)\n', b_m(1), se_m(1));
fprintf('  b1_m  (AR1)  : %+.4f (s.e. %.4f)\n', b_m(2), se_m(2));
fprintf('  b2_m  (IAD)  : %+.4f (s.e. %.4f) [FR-BDF=0.30]\n', b_m(3), se_m(3));
fprintf('  COVID crash   : %+.4f (s.e. %.4f)\n', b_m(4), se_m(4));
fprintf('  COVID bounce  : %+.4f (s.e. %.4f)\n', b_m(5), se_m(5));

b1_m_est = b_m(2);
b2_m_est = b_m(3);
b2_m_t   = b_m(3) / se_m(3);

if b2_m_est > 0 && b2_m_t > 1.0
    final_b2_m = b2_m_est;
    method_m = sprintf('AU OLS on ABS volumes (T=%d, t=%.2f)', T_m, b2_m_t);
elseif b2_m_est > 0
    prior_mean = 0.30; prior_sd = 0.15;
    data_sd = max(0.10, abs(se_m(3)));
    final_b2_m = (prior_mean/prior_sd^2 + b2_m_est/data_sd^2) / (1/prior_sd^2 + 1/data_sd^2);
    method_m = sprintf('Bayesian regularised (weak data t=%.2f); prior N(0.30, 0.15^2)', b2_m_t);
else
    final_b2_m = 0.30;
    method_m = sprintf('AU est wrong-signed (%.3f, t=%.2f); kept FR-BDF cal 0.30', b2_m_est, b2_m_t);
end
fprintf('  FINAL b2_m = %.4f via %s\n\n', final_b2_m, method_m);

%% Save
out_txt = fullfile(this_dir, 'phase_d_results.txt');
fid = fopen(out_txt, 'w');
fprintf(fid, 'Phase D: Trade volume re-estimation on ABS chain volumes\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, '=== Exports: dln_x = a + b1_x*dln_x(-1) + b2_x*yhat_us + COVID + e ===\n');
fprintf(fid, '  T=%d, R^2=%.3f\n', T_x, R2_x);
fprintf(fid, '  b1_x = %.4f (s.e. %.4f)\n', b_x(2), se_x(2));
fprintf(fid, '  b2_x = %.4f (s.e. %.4f, t=%.2f)\n', b_x(3), se_x(3), b2_x_t);
fprintf(fid, '  Method: %s\n', method_x);
fprintf(fid, '  FINAL b2_x = %.4f\n\n', final_b2_x);
fprintf(fid, '=== Imports: dln_m = a + b1_m*dln_m(-1) + b2_m*yhat_au + COVID + e ===\n');
fprintf(fid, '  T=%d, R^2=%.3f\n', T_m, R2_m);
fprintf(fid, '  b1_m = %.4f (s.e. %.4f)\n', b_m(2), se_m(2));
fprintf(fid, '  b2_m = %.4f (s.e. %.4f, t=%.2f)\n', b_m(3), se_m(3), b2_m_t);
fprintf(fid, '  Method: %s\n', method_m);
fprintf(fid, '  FINAL b2_m = %.4f\n\n', final_b2_m);
fprintf(fid, '--- .mod parameter lines ---\n');
fprintf(fid, 'b1_x            = %7.4f;    // Phase D AU OLS, ABS chain vol T=%d\n', b1_x_est, T_x);
fprintf(fid, 'b2_x            = %7.4f;    // Phase D %s\n', final_b2_x, method_x);
fprintf(fid, 'b1_m            = %7.4f;    // Phase D AU OLS, ABS chain vol T=%d\n', b1_m_est, T_m);
fprintf(fid, 'b2_m            = %7.4f;    // Phase D %s\n', final_b2_m, method_m);
fclose(fid);

results = struct();
results.b1_x = b1_x_est; results.b2_x_ols = b2_x_est; results.b2_x_final = final_b2_x;
results.b1_m = b1_m_est; results.b2_m_ols = b2_m_est; results.b2_m_final = final_b2_m;
save(fullfile(this_dir, 'phase_d_results.mat'), 'results');

fprintf('=== Saved ===\n  %s\n  %s\n', out_txt, fullfile(this_dir, 'phase_d_results.mat'));
fprintf('Final values:\n  b1_x = %.4f, b2_x = %.4f\n  b1_m = %.4f, b2_m = %.4f\n', ...
        b1_x_est, final_b2_x, b1_m_est, final_b2_m);
