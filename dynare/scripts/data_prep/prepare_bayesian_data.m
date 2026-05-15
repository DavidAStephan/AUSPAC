function prepare_bayesian_data()
%% prepare_bayesian_data.m
% Creates estimation_data.mat for Bayesian estimation WITHOUT demeaning.
% Variables are in model-consistent quarterly % units, centered around
% the model's steady state values (not sample means).
%
% Dynare's Kalman filter uses the model SS as the observation equation
% constant, so data should be in natural units.

fprintf('=== Preparing Bayesian estimation data (non-demeaned) ===\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
nQ = height(T_base);

% Variables in model-consistent units (quarterly %)
% NOTE: au_irate and au_i10 are ALREADY quarterly % — do NOT divide by 4
yhat_au = T_base.au_ygap;                % already quarterly % gap (SS=0)
pi_au   = T_base.au_pi;                  % quarterly % (SS=0.625)
i_au    = T_base.au_irate;               % already quarterly % (SS=1.0491)
yhat_us = T_base.us_ygap;                % quarterly % gap (SS=0)
pi_us   = T_base.us_pi;                  % quarterly % (SS=0.5)

% Wage inflation (pi_w): use ABS 6345 WPI Private+Public All industries SA
% (from supply_data.mat, originally extracted by prepare_supply_data.m via
% pick_sa_col on col 6 of abs_6345_wpi.xlsx). WPI starts 1997Q3 so we
% splice the early-period synthetic ULC growth (au_pi_w) onto the WPI
% growth series. This replaces dlog(CPI*emp_norm) with the cleanest AU
% wage-inflation measure for 1997Q3 onward while preserving the 1994+
% sample length.
supply = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
% supply.wpi_lvl is log(WPI); take diff(*100) for quarterly growth in %.
wpi_dlog = [NaN; diff(supply.wpi_lvl)] * 100;
% Align WPI to T_base dates by matching year/quarter.
wpi_aligned = nan(nQ, 1);
base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
for k = 1:length(supply.dates)
    yk = year(supply.dates(k)); qk = quarter(supply.dates(k));
    idx = find(year(base_dates) == yk & quarter(base_dates) == qk, 1);
    if ~isempty(idx) && ~isnan(wpi_dlog(k))
        wpi_aligned(idx) = wpi_dlog(k);
    end
end
pi_w_synth = T_ext.au_pi_w;       % legacy synthetic ULC growth
% Splice: WPI where available, synthetic ULC where WPI is missing
pi_w = wpi_aligned;
pi_w(isnan(pi_w)) = pi_w_synth(isnan(pi_w));
n_wpi   = sum(~isnan(wpi_aligned));
n_synth = sum(isnan(wpi_aligned) & ~isnan(pi_w_synth));
fprintf('  pi_w spliced: %d obs from ABS 6345 WPI SA + %d obs from synthetic ULC backfill\n', n_wpi, n_synth);
i_10y   = T_ext.au_i10 / 4;              % annualized -> quarterly (SS=1.3491)

cons    = T_ext.au_consumption;
dln_c   = [NaN; diff(log(cons))] * 100;  % quarterly growth % (SS=0)

gfcf_nd = T_ext.au_gfcf_nondwelling;
dln_ib  = [NaN; diff(log(gfcf_nd))] * 100; % quarterly growth % (SS=0)

% Trade volumes: ABS 5206 SA chain-volume measures (Phase D source).
% Imports: Series ID A2304115J; Exports: A2304114F (both SA, $m chain-vol).
% Pre-extracted to trade_volumes_sa.csv by build_trade_volumes_csv.py.
% Build qoq log-growth in %, align to T_base dates, demean to SS=0.
trade_csv = fullfile(projectdir, 'dynare', 'trade_volumes_sa.csv');
if isfile(trade_csv)
    Ttrade = readtable(trade_csv);
    trade_dates = datetime(Ttrade.date, 'InputFormat', 'yyyy-MM-dd');
    M_lvl = Ttrade.imports_sa;
    X_lvl = Ttrade.exports_sa;
    dln_m_full = [NaN; diff(log(M_lvl))] * 100;
    dln_x_full = [NaN; diff(log(X_lvl))] * 100;
    dln_m_aligned = nan(nQ, 1);
    dln_x_aligned = nan(nQ, 1);
    base_dates_dt = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
    for k = 1:length(trade_dates)
        yk = year(trade_dates(k)); qk = quarter(trade_dates(k));
        idx = find(year(base_dates_dt) == yk & quarter(base_dates_dt) == qk, 1);
        if ~isempty(idx)
            if ~isnan(dln_m_full(k)), dln_m_aligned(idx) = dln_m_full(k); end
            if ~isnan(dln_x_full(k)), dln_x_aligned(idx) = dln_x_full(k); end
        end
    end
    dln_m = dln_m_aligned;
    dln_x = dln_x_aligned;
    fprintf('  Loaded trade volumes from %s\n', trade_csv);
else
    error(['Missing trade_volumes_sa.csv. Run build_trade_volumes_csv.py ' ...
           'to extract ABS 5206 SA imports/exports volumes.']);
end

% Find valid sample (no NaN)
all_data = [yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y, ...
            dln_m, dln_x];
valid = all(~isnan(all_data), 2);
first_valid = find(valid, 1, 'first');
last_valid  = find(valid, 1, 'last');
sample_range = first_valid:last_valid;
nObs = length(sample_range);

fprintf('  Sample: obs %d to %d (%d quarters)\n', first_valid, last_valid, nObs);

% Extract sample (NO demeaning for rates/inflation — Kalman filter handles SS)
% For growth rates (dln_c, dln_ib): demean to match model SS=0
yhat_au = yhat_au(sample_range);  % gap, SS=0, no demean needed
pi_au   = pi_au(sample_range);    % level, SS=0.625, DO NOT demean
i_au    = i_au(sample_range);     % level, SS=1.0491, DO NOT demean
yhat_us = yhat_us(sample_range);  % gap, SS=0, no demean needed
pi_us   = pi_us(sample_range);    % level, SS=0.5, DO NOT demean
pi_w    = pi_w(sample_range);     % level, SS=0.625, DO NOT demean
i_10y   = i_10y(sample_range);    % level, SS=1.3491, DO NOT demean

dln_c_raw  = dln_c(sample_range);
dln_ib_raw = dln_ib(sample_range);
dln_m_raw  = dln_m(sample_range);
dln_x_raw  = dln_x(sample_range);

% Demean growth rates only (model SS = 0 for these).
% NB: by demeaning dln_m and dln_x independently we keep their *relative*
% deviation from each variable's own SS growth — the openness drift is
% absorbed in the demeaning. The model now identifies the LR elasticities
% beta_m/gamma_m/beta_x/gamma_x from the *cycle* around that demeaned trend.
dln_c  = dln_c_raw  - mean(dln_c_raw);
dln_ib = dln_ib_raw - mean(dln_ib_raw);
dln_m  = dln_m_raw  - mean(dln_m_raw);
dln_x  = dln_x_raw  - mean(dln_x_raw);

fprintf('  Variable means (non-demeaned):\n');
varnames = {'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', 'pi_w', ...
            'dln_c', 'dln_ib', 'i_10y', 'dln_m', 'dln_x'};
data_mat = [yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y, ...
            dln_m, dln_x];
for j = 1:length(varnames)
    v = data_mat(:, j);
    fprintf('  %-10s: mean=%.4f, std=%.4f\n', varnames{j}, mean(v), std(v));
end

% Save
outfile = fullfile(fileparts(mfilename('fullpath')), 'estimation_data.mat');
save(outfile, 'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
     'pi_w', 'dln_c', 'dln_ib', 'i_10y', 'dln_m', 'dln_x');
fprintf('\nSaved %d obs x 11 variables to %s\n', nObs, outfile);
fprintf('=== Bayesian data preparation complete ===\n');

end
