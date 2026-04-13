function db = prepare_pac_dseries_smooth(oo_smooth)
%% prepare_pac_dseries_smooth.m
% Constructs a Dynare dseries from Kalman-smoothed endogenous variables.
%
% Unlike prepare_pac_dseries.m (which recursively constructs auxiliary
% variables from observed data using calibrated parameters), this version
% uses oo_.SmoothedVariables from calib_smoother. The Kalman smoother
% extracts model-consistent values of ALL endogenous variables — including
% unobserved auxiliary gaps (c_hat, piQ_hat, pv_c_aux, etc.) — by
% inverting the full model structure given observed data.
%
% INPUT:
%   oo_smooth  struct  oo_ from the calib_smoother pass, containing
%                      oo_.SmoothedVariables with all endogenous vars
%
% OUTPUT:
%   db  [dseries]  Dataset for pac.estimate.iterative_ols / pac.estimate.nls
%
% REQUIRES: M_ global structure (from dynare au_pac pass).

global M_

fprintf('=== Constructing PAC dseries from Kalman-smoothed variables ===\n');

sv = oo_smooth.SmoothedVariables;

% Get the list of smoothed variable names
sv_fields = fieldnames(sv);
fprintf('  SmoothedVariables contains %d fields\n', length(sv_fields));

% Determine sample length from a known observed variable
T = length(sv.yhat_au);
fprintf('  Sample length: %d quarters\n', T);

%% Identify the start date from the smoother
% calib_smoother stores dates info; extract from the data we prepared
projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');

% Find first valid observation (same logic as prepare_smoother_data)
pi_au_raw = T_base.au_pi;
valid = ~isnan(T_base.au_ygap) & ~isnan(pi_au_raw) & ~isnan(T_base.au_irate);
first_valid = find(valid, 1, 'first');

% The smoother data starts at first_valid. But we need extra pre-sample
% for higher-order PAC equations (employment has 4th-order diff, needs 5 lags).
% Pad the beginning with one extra quarter of zeros (model SS = 0 for gap model).
% This ensures diff(ln_n_level(-4)) at est_start=1994Q2 can access 1993Q1 data.
n_pad = first_valid - 1;  % number of quarters before smoother start
if n_pad > 0
    fprintf('  Padding %d quarter(s) of zeros before smoother start (SS initialization)\n', n_pad);
end

% Start dseries at the very first date in the CSV (typically 1993Q1)
start_year = year(base_dates(1));
start_qtr  = quarter(base_dates(1));
start_date = dates(sprintf('%dQ%d', start_year, start_qtr));

fprintf('  Start date: %s (smoother data starts at obs %d)\n', char(start_date), first_valid);

%% Build variable list for the dseries
% We need all variables that appear in the 5 PAC equations plus
% the var_model state variables and PAC shocks (set to NaN).

% Variables to extract from SmoothedVariables
smooth_varnames = { ...
    'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
    'i_gap', 'pi_au_gap', 'u_gap', 'ibar', 'pibar_au', ...
    'y_gap_var', 'i_gap_var', 'pi_gap_var', 'u_gap_var', 'yhat_us_var', ...
    'piQ_hat', 'n_hat', 'yh_ratio_hat', 'c_hat', 'ib_hat', 'rKB_hat', 'ih_hat', ...
    'pv_piQ_aux', 'pv_n_aux', 'pv_c_aux', 'pv_ib_aux', 'pv_rKB_aux', 'pv_ih_aux', ...
    'pQ_level', 'ln_c_level', 'ln_ib_level', 'ln_ih_level', 'ln_n_level', ...
    'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'piQ', ...
    'dln_n_1', 'dln_n_2', 'dln_n_3', 'dln_ib_1', 'dln_ih_1', ...
    'pi_w', 'i_10y' };

% Shock variables (set to NaN for pac.estimate)
shock_varnames = { ...
    'eps_pQ', 'eps_c', 'eps_ib', 'eps_ih', 'eps_n', ...
    'eps_var_y', 'eps_var_i', 'eps_var_pi', 'eps_var_u', 'eps_var_yus', ...
    'eps_var_pQ', 'eps_var_n', 'eps_var_yh', 'eps_var_c', ...
    'eps_var_ib', 'eps_var_rKB', 'eps_var_ih' };

all_varnames = [smooth_varnames, shock_varnames];
T_total = T + n_pad;  % padded length
data_mat = zeros(T_total, length(all_varnames));

% Fill smoothed variables (offset by n_pad for zero-padding)
n_found = 0;
n_missing = 0;
for j = 1:length(smooth_varnames)
    vname = smooth_varnames{j};
    if isfield(sv, vname)
        data_mat(n_pad+1:end, j) = sv.(vname);
        n_found = n_found + 1;
    else
        fprintf('  WARNING: %s not in SmoothedVariables, using zeros\n', vname);
        n_missing = n_missing + 1;
    end
    % First n_pad rows remain zero (steady-state initialization)
end

% Fill shock variables with NaN (required by pac.estimate)
for j = 1:length(shock_varnames)
    data_mat(:, length(smooth_varnames) + j) = NaN;
end

fprintf('  Smoothed variables found: %d, missing: %d\n', n_found, n_missing);

%% Compare smoothed vs recursive auxiliary variables
% Log the differences for diagnostic purposes
fprintf('\n  --- Smoothed auxiliary variable statistics ---\n');
aux_vars = {'piQ_hat', 'c_hat', 'ib_hat', 'ih_hat', 'n_hat', 'rKB_hat', 'yh_ratio_hat'};
for k = 1:length(aux_vars)
    vname = aux_vars{k};
    if isfield(sv, vname)
        v = sv.(vname);
        fprintf('  %-18s  mean=%+.4f  std=%.4f  range=[%.3f, %.3f]\n', ...
            vname, mean(v), std(v), min(v), max(v));
    end
end

pv_vars = {'pv_piQ_aux', 'pv_c_aux', 'pv_ib_aux', 'pv_ih_aux', 'pv_n_aux', 'pv_rKB_aux'};
fprintf('\n  --- Smoothed backward correction terms ---\n');
for k = 1:length(pv_vars)
    vname = pv_vars{k};
    if isfield(sv, vname)
        v = sv.(vname);
        fprintf('  %-18s  mean=%+.4f  std=%.4f  range=[%.3f, %.3f]\n', ...
            vname, mean(v), std(v), min(v), max(v));
    end
end

%% Create dseries
db = dseries(data_mat, start_date, all_varnames);

fprintf('\n  dseries: %d variables x %d observations (incl. %d zero-padded)\n', ...
    length(all_varnames), T_total, n_pad);
fprintf('  Date range: %s to %s\n', char(db.dates(1)), char(db.dates(end)));
fprintf('=== Smoothed dseries construction complete ===\n');

end
