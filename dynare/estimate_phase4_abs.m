%% estimate_phase4_abs.m — Phase 4: Estimate deflator and trade parameters from ABS data
% Uses ABS 5206 IPDs, chain volumes, RPPI, and RBA mortgage rates to estimate
% the remaining ~70 calibrated parameters.
%
% Data source: abs_rba_dataset.mat (pre-processed by process_abs_rba_data.m)
% If mat file missing, falls back to CSV files (converted from xlsx).

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

datadir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'abs_rba');
fid = fopen('phase4_estimation_log.txt', 'w');
log_msg = @(msg) fprintf_both(fid, msg);

log_msg('================================================================\n');
log_msg(sprintf('  PHASE 4 ESTIMATION — ABS/RBA Data\n  %s\n', datestr(now)));
log_msg('================================================================\n\n');

%% Load existing model data
projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
nQ = height(T_base);
base_yq = [year(base_dates), quarter(base_dates)];

yhat_au = T_base.au_ygap;
pi_au = T_base.au_pi;
i_au = T_base.au_irate / 4;  % quarterly
ibar = T_base.i_bar;
i_gap = i_au - ibar;
pibar_au = T_base.pi_bar_au;

%% =====================================================================
%  LOAD ABS/RBA DATA from pre-processed mat file
%  =====================================================================
log_msg('--- Loading pre-processed ABS/RBA data ---\n');
matfile = fullfile(datadir, 'abs_rba_dataset.mat');

if ~exist(matfile, 'file')
    error('abs_rba_dataset.mat not found. Run process_abs_rba_data.m first.');
end

D = load(matfile);
log_msg(['  Loaded ', strrep(matfile, '\', '/'), '\n']);

% FIX: ABS dates in mat file have day/month swapped (MATLAB parsed dd/MM/yyyy
% format as MM/dd/yyyy). Detect and correct: if all months are January but days
% vary 1-12, the day field actually contains the real month.
if ~isempty(D.ipd_dates) && all(month(D.ipd_dates) == 1)
    log_msg('  Fixing IPD dates (day/month swap detected)\n');
    real_months = day(D.ipd_dates);
    D.ipd_dates = datetime(year(D.ipd_dates), real_months, ones(size(real_months)));
end
if ~isempty(D.vol_dates) && all(month(D.vol_dates) == 1)
    log_msg('  Fixing volume dates (day/month swap detected)\n');
    real_months = day(D.vol_dates);
    D.vol_dates = datetime(year(D.vol_dates), real_months, ones(size(real_months)));
end
if ~isempty(D.rppi_dates) && all(month(D.rppi_dates) == 1)
    log_msg('  Fixing RPPI dates (day/month swap detected)\n');
    real_months = day(D.rppi_dates);
    D.rppi_dates = datetime(year(D.rppi_dates), real_months, ones(size(real_months)));
end
% Housing rate dates: RBA CSV dates like '31/01/1959' parse correctly
% because day > 12 forces DD/MM/YYYY interpretation. No fix needed.

log_msg(sprintf('  IPD range: %s to %s\n', datestr(D.ipd_dates(1)), datestr(D.ipd_dates(end))));
log_msg(sprintf('  Vol range: %s to %s\n', datestr(D.vol_dates(1)), datestr(D.vol_dates(end))));
if ~isempty(D.rppi_dates)
    log_msg(sprintf('  RPPI range: %s to %s\n', datestr(D.rppi_dates(1)), datestr(D.rppi_dates(end))));
end

%% 1. IPD data — fix missing columns and align
log_msg('\n--- ABS 5206 IPD ---\n');
% D.ipd_names = {'ipd_c', 'ipd_ih', 'ipd_ib', 'ipd_x', 'ipd_m', 'ipd_g', 'ipd_gdp'}
% Columns 1-3 may be NaN (process_abs_rba_data.m failed to match headers).
% Known correct columns from diag_abs_data.m:
%   Col 7: Households consumption, Col 11: Dwellings, Col 15: Non-dwelling construction
%   Col 16: Machinery & equipment (we use 15+16 average or just 15 for 'ib')

% Check if consumption deflator is missing and fill from xlsx
ipd_file = fullfile(datadir, 'abs_5206_ipd.xlsx');
if all(isnan(D.ipd_data(:, 1))) && exist(ipd_file, 'file')
    log_msg('  ipd_c/ih/ib missing from mat file — reading from xlsx...\n');
    try
        [~, ~, raw_ipd] = xlsread(ipd_file, 'Data1');
        % Known column mapping
        col_map = [7, 11, 15, 37, 38, 6, 39];  % ipd_c, ih, ib, x, m, g, gdp

        % Find data start row
        data_start = 0;
        for r = 1:size(raw_ipd, 1)
            if ischar(raw_ipd{r, 1}) && contains(raw_ipd{r, 1}, 'Series ID')
                data_start = r + 1; break;
            end
        end
        nrows_ipd = size(raw_ipd, 1) - data_start + 1;

        % Extract dates using datenum (fast)
        ipd_datenums = nan(nrows_ipd, 1);
        for r = 1:nrows_ipd
            d = raw_ipd{data_start + r - 1, 1};
            if isnumeric(d) && d > 10000
                ipd_datenums(r) = d + datenum('1899-12-30');
            elseif ischar(d)
                try, ipd_datenums(r) = datenum(d, 'dd/mm/yyyy'); catch, end
            end
        end

        % Replace missing columns
        for k = 1:3  % ipd_c, ipd_ih, ipd_ib
            col = col_map(k);
            if col <= size(raw_ipd, 2)
                vals = nan(nrows_ipd, 1);
                for r = 1:nrows_ipd
                    v = raw_ipd{data_start + r - 1, col};
                    if isnumeric(v) && ~isnan(v), vals(r) = v; end
                end
                % Align by row count (same source, same dates)
                if nrows_ipd == size(D.ipd_data, 1)
                    D.ipd_data(:, k) = vals;
                end
            end
        end

        % Update dates from datenum (more reliable)
        valid_dn = ~isnan(ipd_datenums);
        if sum(valid_dn) == nrows_ipd
            dv = datevec(ipd_datenums);
            D.ipd_dates = datetime(dv(:,1), dv(:,2), dv(:,3));
        end

        log_msg(sprintf('  Filled ipd_c (%d obs), ipd_ih (%d), ipd_ib (%d)\n', ...
            sum(~isnan(D.ipd_data(:,1))), sum(~isnan(D.ipd_data(:,2))), sum(~isnan(D.ipd_data(:,3)))));
    catch ME
        log_msg(sprintf('  xlsread failed: %s\n', ME.message));
    end
end

ipd_yq = [year(D.ipd_dates), quarter(D.ipd_dates)];

% Compute q/q log-changes (deflator inflation)
pi_ipd = struct();
for k = 1:length(D.ipd_names)
    pi_ipd.(D.ipd_names{k}) = [NaN; diff(log(D.ipd_data(:, k)))] * 100;
end

% Align to model sample
for k = 1:length(D.ipd_names)
    fn = D.ipd_names{k};
    aligned = nan(nQ, 1);
    pi_series = pi_ipd.(fn);
    for t = 1:nQ
        match = find(ipd_yq(:,1) == base_yq(t,1) & ipd_yq(:,2) == base_yq(t,2));
        if ~isempty(match)
            aligned(t) = pi_series(match(1));
        end
    end
    pi_ipd.([fn '_aligned']) = aligned;
end

% Count alignment using GDP deflator (always available)
n_aligned_gdp = sum(~isnan(pi_ipd.ipd_gdp_aligned));
log_msg(sprintf('  IPD: %d source obs, %d aligned to model sample\n', ...
    size(D.ipd_data, 1), n_aligned_gdp));
for k = 1:length(D.ipd_names)
    fn = D.ipd_names{k};
    n_data = sum(~isnan(D.ipd_data(:, k)));
    n_align = sum(~isnan(pi_ipd.([fn '_aligned'])));
    log_msg(sprintf('    %s: %d source, %d aligned\n', fn, n_data, n_align));
end

%% 2. RPPI — housing price index
log_msg('\n--- ABS 6416 RPPI ---\n');
dln_ph = nan(nQ, 1);

if ~isempty(D.rppi_data) && ~isempty(D.rppi_dates)
    dln_ph_raw = [NaN; diff(log(D.rppi_data))] * 100;
    rppi_yq = [year(D.rppi_dates), quarter(D.rppi_dates)];

    for t = 1:nQ
        match = find(rppi_yq(:,1) == base_yq(t,1) & rppi_yq(:,2) == base_yq(t,2));
        if ~isempty(match)
            dln_ph(t) = dln_ph_raw(match(1));
        end
    end
    log_msg(sprintf('  RPPI: %d source obs, %d aligned (2003Q1-2021Q4)\n', ...
        length(D.rppi_data), sum(~isnan(dln_ph))));
else
    log_msg('  No RPPI data available\n');
end

%% 3. Mortgage rate
log_msg('\n--- RBA F5 mortgage rate ---\n');
i_lh_q = nan(nQ, 1);

if ~isempty(D.housing_rate) && ~isempty(D.housing_rate_dates)
    hr_yq = [year(D.housing_rate_dates), quarter(D.housing_rate_dates)];
    for t = 1:nQ
        match = find(hr_yq(:,1) == base_yq(t,1) & hr_yq(:,2) == base_yq(t,2));
        if ~isempty(match)
            i_lh_q(t) = D.housing_rate(match(end)) / 4;  % annualized -> quarterly
        end
    end
    log_msg(sprintf('  Mortgage rate: %d source obs, %d aligned, mean=%.3f q (%.1f%% ann)\n', ...
        length(D.housing_rate), sum(~isnan(i_lh_q)), nanmean_local(i_lh_q), nanmean_local(i_lh_q)*4));
    last_valid = find(~isnan(i_lh_q), 1, 'last');
    if ~isempty(last_valid)
        log_msg(sprintf('  Latest: %.3f q (%.2f%% ann) at %s\n', ...
            i_lh_q(last_valid), i_lh_q(last_valid)*4, datestr(base_dates(last_valid))));
    end
else
    log_msg('  No mortgage rate data available\n');
end

%% 4. Export/Import volumes
log_msg('\n--- ABS 5206 Chain Volumes ---\n');
dln_x = nan(nQ, 1);
dln_m = nan(nQ, 1);

if ~isempty(D.vol_data) && ~isempty(D.vol_dates)
    % D.vol_names = {'vol_x', 'vol_m', 'vol_c', 'vol_ih', 'vol_ib'}
    vol_yq = [year(D.vol_dates), quarter(D.vol_dates)];

    % Exports (col 1) and Imports (col 2)
    vol_x_raw = D.vol_data(:, 1);
    vol_m_raw = D.vol_data(:, 2);
    dln_x_raw = [NaN; diff(log(vol_x_raw))] * 100;
    dln_m_raw = [NaN; diff(log(vol_m_raw))] * 100;

    for t = 1:nQ
        match = find(vol_yq(:,1) == base_yq(t,1) & vol_yq(:,2) == base_yq(t,2));
        if ~isempty(match)
            dln_x(t) = dln_x_raw(match(1));
            dln_m(t) = dln_m_raw(match(1));
        end
    end
    log_msg(sprintf('  Volumes: %d source obs\n', size(D.vol_data, 1)));
    log_msg(sprintf('  Exports: %d aligned, mean=%.3f, std=%.3f\n', ...
        sum(~isnan(dln_x)), nanmean_local(dln_x), nanstd_local(dln_x)));
    log_msg(sprintf('  Imports: %d aligned, mean=%.3f, std=%.3f\n', ...
        sum(~isnan(dln_m)), nanmean_local(dln_m), nanstd_local(dln_m)));
else
    log_msg('  No volume data available\n');
end

%% =====================================================================
%  ESTIMATION
%  =====================================================================

log_msg('\n================================================================\n');
log_msg('  PARAMETER ESTIMATION\n');
log_msg('================================================================\n\n');

%% E1. Housing price equation (dln_ph = rho_ph * dln_ph(-1) + alpha_ph_y * yhat + alpha_ph_r * i_gap(-1))
log_msg('--- E1: Housing prices (eq_dln_ph) ---\n');
dln_ph_lag = [NaN; dln_ph(1:end-1)];
i_gap_lag = [NaN; i_gap(1:end-1)];
valid = ~isnan(dln_ph) & ~isnan(dln_ph_lag) & ~isnan(yhat_au) & ~isnan(i_gap_lag);

Y_ph = dln_ph(valid);
X_ph = [dln_ph_lag(valid), yhat_au(valid), i_gap_lag(valid)];

if length(Y_ph) > 10
    b_ph = X_ph \ Y_ph;
    resid = Y_ph - X_ph * b_ph;
    T_ph = length(Y_ph);
    se_ph = sqrt(diag((resid' * resid) / (T_ph - 3) * inv(X_ph' * X_ph)));
    R2_ph = 1 - (resid' * resid) / ((Y_ph - mean(Y_ph))' * (Y_ph - mean(Y_ph)));

    log_msg(sprintf('  rho_ph      = %.4f (s.e. %.4f)\n', b_ph(1), se_ph(1)));
    log_msg(sprintf('  alpha_ph_y  = %.4f (s.e. %.4f)\n', b_ph(2), se_ph(2)));
    log_msg(sprintf('  alpha_ph_r  = %.4f (s.e. %.4f)\n', b_ph(3), se_ph(3)));
    log_msg(sprintf('  R2=%.4f, T=%d\n', R2_ph, T_ph));
else
    log_msg('  Insufficient data for housing price estimation\n');
end

%% E2. Mortgage rate passthrough (i_lh = rho_lh * i_lh(-1) + (1-rho_lh) * (i_au + spread))
log_msg('\n--- E2: Mortgage rate passthrough ---\n');
i_lh_lag = [NaN; i_lh_q(1:end-1)];
valid_lh = ~isnan(i_lh_q) & ~isnan(i_lh_lag) & ~isnan(i_au);

Y_lh = i_lh_q(valid_lh);
X_lh = [i_lh_lag(valid_lh), i_au(valid_lh)];

if length(Y_lh) > 10
    b_lh = X_lh \ Y_lh;
    resid_lh = Y_lh - X_lh * b_lh;
    T_lh = length(Y_lh);
    se_lh = sqrt(diag((resid_lh' * resid_lh) / (T_lh - 2) * inv(X_lh' * X_lh)));
    R2_lh = 1 - (resid_lh' * resid_lh) / ((Y_lh - mean(Y_lh))' * (Y_lh - mean(Y_lh)));

    rho_lh = b_lh(1);
    pass_lh = b_lh(2);
    spread_implied = mean(Y_lh) - pass_lh / (1 - rho_lh) * mean(i_au(valid_lh));

    log_msg(sprintf('  rho_lh         = %.4f (s.e. %.4f) — mortgage rate persistence\n', rho_lh, se_lh(1)));
    log_msg(sprintf('  passthrough    = %.4f (s.e. %.4f) — policy rate passthrough\n', pass_lh, se_lh(2)));
    log_msg(sprintf('  implied spread = %.4f q (%.2f%% ann)\n', spread_implied, spread_implied*4));
    log_msg(sprintf('  R2=%.4f, T=%d\n', R2_lh, T_lh));
else
    log_msg('  Insufficient data for mortgage rate estimation\n');
end

%% E3. Component deflator regressions
log_msg('\n--- E3: Component deflators ---\n');
pi_gdp = pi_ipd.ipd_gdp_aligned;

deflator_specs = {
    'ipd_c',  'Consumption deflator',  0.50, 0.71;
    'ipd_x',  'Export deflator',       0.50, 0.34;
    'ipd_m',  'Import deflator',       0.50, 0.08;
    'ipd_ih', 'Housing deflator',      0.50, 0.50;
    'ipd_ib', 'Business inv deflator', 0.50, 0.50;
    'ipd_g',  'Government deflator',   0.50, 0.30;
};

deflator_results = struct();
for d = 1:size(deflator_specs, 1)
    fn = deflator_specs{d, 1};
    desc = deflator_specs{d, 2};
    pi_comp = pi_ipd.([fn '_aligned']);
    pi_comp_lag = [NaN; pi_comp(1:end-1)];
    valid_d = ~isnan(pi_comp) & ~isnan(pi_comp_lag) & ~isnan(pi_gdp);

    if sum(valid_d) > 10
        Y_d = pi_comp(valid_d);
        X_d = [pi_comp_lag(valid_d), pi_gdp(valid_d)];
        b_d = X_d \ Y_d;
        resid_d = Y_d - X_d * b_d;
        T_d = length(Y_d);
        se_d = sqrt(diag((resid_d' * resid_d) / (T_d - 2) * inv(X_d' * X_d)));
        R2_d = 1 - (resid_d' * resid_d) / ((Y_d - mean(Y_d))' * (Y_d - mean(Y_d)));

        log_msg(sprintf('  %s:\n', desc));
        log_msg(sprintf('    rho   = %.4f (s.e. %.4f)  [FR-BDF: %.2f]\n', b_d(1), se_d(1), deflator_specs{d, 3}));
        log_msg(sprintf('    alpha = %.4f (s.e. %.4f)  [FR-BDF: %.2f]\n', b_d(2), se_d(2), deflator_specs{d, 4}));
        log_msg(sprintf('    R2=%.4f, T=%d\n', R2_d, T_d));

        deflator_results.(fn) = struct('b', b_d, 'se', se_d, 'R2', R2_d, 'T', T_d);
    else
        log_msg(sprintf('  %s: insufficient data (%d obs)\n', desc, sum(valid_d)));
    end
end

%% E4. Trade volume equations
log_msg('\n--- E4: Trade volumes ---\n');

% Export volume: dln_x = rho_x * dln_x(-1) + b_x_yus * yhat_us + b_x_yau * yhat_au
yhat_us = T_base.us_ygap;
dln_x_lag = [NaN; dln_x(1:end-1)];
valid_x = ~isnan(dln_x) & ~isnan(dln_x_lag) & ~isnan(yhat_us) & ~isnan(yhat_au);

if sum(valid_x) > 10
    Y_x = dln_x(valid_x);
    X_x = [dln_x_lag(valid_x), yhat_us(valid_x), yhat_au(valid_x)];
    b_x = X_x \ Y_x;
    resid_x = Y_x - X_x * b_x;
    T_x = length(Y_x);
    se_x = sqrt(diag((resid_x' * resid_x) / (T_x - 3) * inv(X_x' * X_x)));

    log_msg(sprintf('  Export volume:\n'));
    log_msg(sprintf('    rho_x    = %.4f (s.e. %.4f)\n', b_x(1), se_x(1)));
    log_msg(sprintf('    b_x_yus  = %.4f (s.e. %.4f)\n', b_x(2), se_x(2)));
    log_msg(sprintf('    b_x_yau  = %.4f (s.e. %.4f)\n', b_x(3), se_x(3)));
    log_msg(sprintf('    R2=%.4f, T=%d\n', 1 - (resid_x'*resid_x)/((Y_x-mean(Y_x))'*(Y_x-mean(Y_x))), T_x));
else
    log_msg('  Export volume: insufficient data\n');
end

% Import volume: dln_m = rho_m * dln_m(-1) + b_m_y * yhat_au
dln_m_lag = [NaN; dln_m(1:end-1)];
valid_m = ~isnan(dln_m) & ~isnan(dln_m_lag) & ~isnan(yhat_au);

if sum(valid_m) > 10
    Y_m = dln_m(valid_m);
    X_m = [dln_m_lag(valid_m), yhat_au(valid_m)];
    b_m = X_m \ Y_m;
    resid_m = Y_m - X_m * b_m;
    T_m = length(Y_m);
    se_m = sqrt(diag((resid_m' * resid_m) / (T_m - 2) * inv(X_m' * X_m)));

    log_msg(sprintf('  Import volume:\n'));
    log_msg(sprintf('    rho_m    = %.4f (s.e. %.4f)\n', b_m(1), se_m(1)));
    log_msg(sprintf('    b_m_y    = %.4f (s.e. %.4f)\n', b_m(2), se_m(2)));
    log_msg(sprintf('    R2=%.4f, T=%d\n', 1 - (resid_m'*resid_m)/((Y_m-mean(Y_m))'*(Y_m-mean(Y_m))), T_m));
else
    log_msg('  Import volume: insufficient data\n');
end

%% E5. Housing price gap construction (for b_ph_ih)
log_msg('\n--- E5: Observed ph_gap construction ---\n');
valid_ph = ~isnan(dln_ph);
ph_gap_obs = [];
if sum(valid_ph) > 10
    % Demean dln_ph
    dln_ph_dm = dln_ph - nanmean_local(dln_ph);

    % Cumulate into ph_gap with 2% quarterly mean-reversion
    ph_gap_obs = zeros(nQ, 1);
    for t = 2:nQ
        if ~isnan(dln_ph_dm(t))
            ph_gap_obs(t) = 0.98 * ph_gap_obs(t-1) + dln_ph_dm(t);
        else
            ph_gap_obs(t) = 0.98 * ph_gap_obs(t-1);
        end
    end
    log_msg(sprintf('  ph_gap_obs: std=%.3f, range=[%.2f, %.2f]\n', ...
        std(ph_gap_obs(valid_ph)), min(ph_gap_obs(valid_ph)), max(ph_gap_obs(valid_ph))));

    % Now re-estimate b_ph_ih with observed ph_gap
    % Load household investment data
    ih = T_ext.au_gfcf_dwelling;
    dln_ih = [NaN; diff(log(ih))] * 100;
    dln_ih = dln_ih - nanmean_local(dln_ih);

    dln_ih_lag = [NaN; dln_ih(1:end-1)];
    ph_gap_lag = [NaN; ph_gap_obs(1:end-1)];
    valid_bph = ~isnan(dln_ih) & ~isnan(dln_ih_lag) & ~isnan(yhat_au) & ...
                ~isnan(ph_gap_lag) & ph_gap_lag ~= 0;

    if sum(valid_bph) > 10
        Y_bph = dln_ih(valid_bph);
        X_bph = [dln_ih_lag(valid_bph), yhat_au(valid_bph), ph_gap_lag(valid_bph)];
        b_bph = X_bph \ Y_bph;
        resid_bph = Y_bph - X_bph * b_bph;
        T_bph = length(Y_bph);
        se_bph = sqrt(diag((resid_bph' * resid_bph) / (T_bph - 3) * inv(X_bph' * X_bph)));

        log_msg(sprintf('  Housing inv with observed ph_gap:\n'));
        log_msg(sprintf('    AR1         = %.4f (s.e. %.4f)\n', b_bph(1), se_bph(1)));
        log_msg(sprintf('    output gap  = %.4f (s.e. %.4f)\n', b_bph(2), se_bph(2)));
        log_msg(sprintf('    b_ph_ih     = %.4f (s.e. %.4f)\n', b_bph(3), se_bph(3)));
        log_msg(sprintf('    t-stat(ph)  = %.2f\n', b_bph(3)/se_bph(3)));
    end
else
    log_msg('  Insufficient RPPI data for ph_gap construction\n');
end

%% Summary table
log_msg('\n================================================================\n');
log_msg('  PHASE 4 ESTIMATION SUMMARY\n');
log_msg('================================================================\n\n');
log_msg('  Parameter        | AU estimate | s.e.   | FR-BDF | Status\n');
log_msg('  -----------------+-------------+--------+--------+-------\n');

if exist('b_lh', 'var')
    log_msg(sprintf('  rho_lh           | %11.4f | %.4f | 0.95   | Mortgage persistence\n', b_lh(1), se_lh(1)));
    log_msg(sprintf('  pass_lh          | %11.4f | %.4f | 0.80   | Policy passthrough\n', b_lh(2), se_lh(2)));
end
if isfield(deflator_results, 'ipd_c')
    r = deflator_results.ipd_c;
    log_msg(sprintf('  rho_pc           | %11.4f | %.4f | 0.50   | Consumption deflator AR\n', r.b(1), r.se(1)));
    log_msg(sprintf('  alpha_pc         | %11.4f | %.4f | 0.71   | Consumption deflator loading\n', r.b(2), r.se(2)));
end
if isfield(deflator_results, 'ipd_x')
    r = deflator_results.ipd_x;
    log_msg(sprintf('  rho_px           | %11.4f | %.4f | 0.50   | Export deflator AR\n', r.b(1), r.se(1)));
    log_msg(sprintf('  alpha_px         | %11.4f | %.4f | 0.34   | Export deflator loading\n', r.b(2), r.se(2)));
end
if isfield(deflator_results, 'ipd_m')
    r = deflator_results.ipd_m;
    log_msg(sprintf('  rho_pm_abs       | %11.4f | %.4f | 0.50   | Import deflator AR\n', r.b(1), r.se(1)));
    log_msg(sprintf('  alpha_pm_abs     | %11.4f | %.4f | 0.08   | Import deflator loading\n', r.b(2), r.se(2)));
end
if isfield(deflator_results, 'ipd_ih')
    r = deflator_results.ipd_ih;
    log_msg(sprintf('  rho_pih          | %11.4f | %.4f | 0.50   | Housing deflator AR\n', r.b(1), r.se(1)));
    log_msg(sprintf('  alpha_pih        | %11.4f | %.4f | 0.50   | Housing deflator loading\n', r.b(2), r.se(2)));
end
if isfield(deflator_results, 'ipd_ib')
    r = deflator_results.ipd_ib;
    log_msg(sprintf('  rho_pib          | %11.4f | %.4f | 0.50   | Bus inv deflator AR\n', r.b(1), r.se(1)));
    log_msg(sprintf('  alpha_pib        | %11.4f | %.4f | 0.50   | Bus inv deflator loading\n', r.b(2), r.se(2)));
end
if isfield(deflator_results, 'ipd_g')
    r = deflator_results.ipd_g;
    log_msg(sprintf('  rho_pg_abs       | %11.4f | %.4f | 0.50   | Govt deflator AR\n', r.b(1), r.se(1)));
    log_msg(sprintf('  alpha_pg_abs     | %11.4f | %.4f | 0.30   | Govt deflator loading\n', r.b(2), r.se(2)));
end
if exist('b_x', 'var')
    log_msg(sprintf('  rho_x            | %11.4f | %.4f | 0.50   | Export volume AR\n', b_x(1), se_x(1)));
    log_msg(sprintf('  b_x_yus          | %11.4f | %.4f | 0.50   | Export foreign demand\n', b_x(2), se_x(2)));
end
if exist('b_m', 'var')
    log_msg(sprintf('  rho_m            | %11.4f | %.4f | 0.50   | Import volume AR\n', b_m(1), se_m(1)));
    log_msg(sprintf('  b_m_y            | %11.4f | %.4f | 1.50   | Import domestic demand\n', b_m(2), se_m(2)));
end
if exist('b_ph', 'var')
    log_msg(sprintf('  rho_ph           | %11.4f | %.4f | 0.85   | Housing price AR\n', b_ph(1), se_ph(1)));
    log_msg(sprintf('  alpha_ph_y       | %11.4f | %.4f | 0.10   | HP output gap\n', b_ph(2), se_ph(2)));
    log_msg(sprintf('  alpha_ph_r       | %11.4f | %.4f | -0.50  | HP interest rate\n', b_ph(3), se_ph(3)));
end
if exist('b_bph', 'var')
    log_msg(sprintf('  b_ph_ih (obs)    | %11.4f | %.4f | 0.32   | HP gap in housing inv\n', b_bph(3), se_bph(3)));
end
log_msg('\n');

%% Save results
save_vars = {'dln_ph', 'i_lh_q', 'dln_x', 'dln_m', 'pi_ipd', 'deflator_results'};
if ~isempty(ph_gap_obs), save_vars{end+1} = 'ph_gap_obs'; end
if exist('b_lh', 'var'), save_vars{end+1} = 'b_lh'; save_vars{end+1} = 'se_lh'; end
if exist('b_ph', 'var'), save_vars{end+1} = 'b_ph'; save_vars{end+1} = 'se_ph'; end
if exist('b_x', 'var'), save_vars{end+1} = 'b_x'; save_vars{end+1} = 'se_x'; end
if exist('b_m', 'var'), save_vars{end+1} = 'b_m'; save_vars{end+1} = 'se_m'; end
if exist('b_bph', 'var'), save_vars{end+1} = 'b_bph'; save_vars{end+1} = 'se_bph'; end
save('phase4_estimation_results.mat', save_vars{:});
log_msg(sprintf('  Results saved to phase4_estimation_results.mat\n'));
log_msg(sprintf('  Variables: %s\n', strjoin(save_vars, ', ')));

log_msg('\n================================================================\n');
log_msg('  PHASE 4 ESTIMATION COMPLETE\n');
log_msg('================================================================\n');

fclose(fid);

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0, fprintf(fid, msg); end
end

function m = nanmean_local(x)
    x = x(~isnan(x));
    m = mean(x);
end

function s = nanstd_local(x)
    x = x(~isnan(x));
    s = std(x);
end
