function prepare_smoother_data()
%% prepare_smoother_data.m
% Creates a Dynare-compatible data file for calib_smoother.
%
% Dynare's calib_smoother requires observed data in a .m or .mat file
% where variable names match model endogenous variable names exactly.
% Data must be demeaned (model is in gap/deviation form with zero SS).
%
% Observables (9 variables matching au_pac.mod endogenous names):
%   yhat_au   — output gap (%)
%   pi_au     — CPI inflation (quarterly %)
%   i_au      — policy rate (quarterly %)
%   yhat_us   — US output gap (%)
%   pi_us     — US inflation (quarterly %)
%   dln_c     — consumption growth (demeaned quarterly %)
%   dln_ib    — business investment growth (demeaned quarterly %)
%   dln_ih    — housing investment growth (demeaned quarterly %)
%   dln_n     — employment growth (demeaned quarterly %)
%
% OUTPUT: smoother_data.m file in dynare/ directory

fprintf('=== Preparing smoother data for calib_smoother ===\n');

%% Load raw data
projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');  % up to repo root (post-cleanup fix)
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
nQ = height(T_base);

%% Construct observables (must match model variable names exactly)

% E-SAT core: already in gap form (zero mean at SS)
yhat_au = T_base.au_ygap;
pi_au   = T_base.au_pi;
i_au    = T_base.au_irate / 4;   % annualized -> quarterly
yhat_us = T_base.us_ygap;
pi_us   = T_base.us_pi;

% Demand block: log-differenced and demeaned
cons = T_ext.au_consumption;
dln_c = [NaN; diff(log(cons))] * 100;
dln_c = dln_c - mean(dln_c, 'omitnan');

ib = T_ext.au_gfcf_nondwelling;
dln_ib = [NaN; diff(log(ib))] * 100;
dln_ib = dln_ib - mean(dln_ib, 'omitnan');

ih = T_ext.au_gfcf_dwelling;
dln_ih = [NaN; diff(log(ih))] * 100;
dln_ih = dln_ih - mean(dln_ih, 'omitnan');

emp = T_ext.au_employment;
dln_n = [NaN; diff(log(emp))] * 100;
dln_n = dln_n - mean(dln_n, 'omitnan');

%% Demean the gap variables around the model's zero steady state
% yhat_au, yhat_us are already output gaps (mean ~ 0 by construction)
% pi_au, pi_us, i_au: the model treats these as deviations from trend.
% In au_pac.mod, pi_au = pibar_au + pi_au_gap. The observed pi_au
% includes the level. For calib_smoother, we need the TOTAL variable
% (not the gap), because the model has pi_au as an endogenous variable
% with steady state = pibar_au.
%
% However, the model's steady state for pi_au = pibar_au (0.625 qtr),
% i_au = ibar (~1.05 qtr). The Kalman filter subtracts the steady state
% internally when the model is linearized. So we provide the LEVEL data.

% For the growth variables (dln_c etc.), the model SS is 0 (gap model).
% We've already demeaned them.

%% Find valid sample (no NaN in any observable)
valid = ~isnan(yhat_au) & ~isnan(pi_au) & ~isnan(i_au) & ...
        ~isnan(yhat_us) & ~isnan(pi_us) & ...
        ~isnan(dln_c) & ~isnan(dln_ib) & ~isnan(dln_ih) & ~isnan(dln_n);

first_valid = find(valid, 1, 'first');
last_valid  = find(valid, 1, 'last');
T = last_valid - first_valid + 1;
fprintf('Valid sample: obs %d to %d (%d quarters)\n', first_valid, last_valid, T);

% Extract valid sample
idx = first_valid:last_valid;
yhat_au = yhat_au(idx);
pi_au   = pi_au(idx);
i_au    = i_au(idx);
yhat_us = yhat_us(idx);
pi_us   = pi_us(idx);
dln_c   = dln_c(idx);
dln_ib  = dln_ib(idx);
dln_ih  = dln_ih(idx);
dln_n   = dln_n(idx);

% Check for remaining NaN and replace with interpolation
varnames = {'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
            'dln_c', 'dln_ib', 'dln_ih', 'dln_n'};
vars = {yhat_au, pi_au, i_au, yhat_us, pi_us, dln_c, dln_ib, dln_ih, dln_n};

for k = 1:length(vars)
    nnan = sum(isnan(vars{k}));
    if nnan > 0
        fprintf('  WARNING: %s has %d NaN in valid sample, interpolating\n', varnames{k}, nnan);
        vars{k} = interp_nan(vars{k});
    end
end

yhat_au = vars{1}; pi_au = vars{2}; i_au = vars{3};
yhat_us = vars{4}; pi_us = vars{5};
dln_c = vars{6}; dln_ib = vars{7}; dln_ih = vars{8}; dln_n = vars{9};

%% Write Dynare-compatible .m data file
% Format: each variable as a column vector, plus 'initial_period' for dates
outfile = fullfile(pwd, 'smoother_data.m');  % write to caller's cwd (dynare/)
fid = fopen(outfile, 'w');

% Parse start date
base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
start_date = base_dates(first_valid);
start_year = year(start_date);
start_qtr  = quarter(start_date);

fprintf(fid, '%% smoother_data.m\n');
fprintf(fid, '%% Dynare-compatible data file for calib_smoother\n');
fprintf(fid, '%% Generated: %s\n', datestr(now));
fprintf(fid, '%% Sample: %dQ%d to %dQ%d (%d obs)\n\n', ...
    start_year, start_qtr, year(base_dates(last_valid)), quarter(base_dates(last_valid)), T);

% Write each variable
write_var(fid, 'yhat_au', yhat_au);
write_var(fid, 'pi_au', pi_au);
write_var(fid, 'i_au', i_au);
write_var(fid, 'yhat_us', yhat_us);
write_var(fid, 'pi_us', pi_us);
write_var(fid, 'dln_c', dln_c);
write_var(fid, 'dln_ib', dln_ib);
write_var(fid, 'dln_ih', dln_ih);
write_var(fid, 'dln_n', dln_n);

fclose(fid);
fprintf('Wrote %s (%d obs x 9 variables)\n', outfile, T);

%% Also save as .mat (Dynare accepts both)
save(fullfile(pwd, 'smoother_data.mat'), ...
    'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
    'dln_c', 'dln_ib', 'dln_ih', 'dln_n');
fprintf('Wrote smoother_data.mat\n');

fprintf('=== Smoother data preparation complete ===\n');

end

%% Helper: write variable to .m file
function write_var(fid, name, data)
    fprintf(fid, '%s = [\n', name);
    for t = 1:length(data)
        fprintf(fid, '  %.10f\n', data(t));
    end
    fprintf(fid, '];\n\n');
end

%% Helper: linear interpolation of NaN values
function y = interp_nan(x)
    y = x;
    nan_idx = isnan(x);
    if ~any(nan_idx), return; end
    ok_idx = find(~nan_idx);
    y(nan_idx) = interp1(ok_idx, x(ok_idx), find(nan_idx), 'linear', 'extrap');
end
