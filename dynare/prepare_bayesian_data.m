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

pi_w    = T_ext.au_pi_w;                 % quarterly % (SS=0.625)
i_10y   = T_ext.au_i10 / 4;              % annualized -> quarterly (SS=1.3491)

cons    = T_ext.au_consumption;
dln_c   = [NaN; diff(log(cons))] * 100;  % quarterly growth % (SS=0)

gfcf_nd = T_ext.au_gfcf_nondwelling;
dln_ib  = [NaN; diff(log(gfcf_nd))] * 100; % quarterly growth % (SS=0)

% Find valid sample (no NaN)
all_data = [yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y];
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

% Demean growth rates only (model SS = 0 for these)
dln_c  = dln_c_raw  - mean(dln_c_raw);
dln_ib = dln_ib_raw - mean(dln_ib_raw);

fprintf('  Variable means (non-demeaned):\n');
varnames = {'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', 'pi_w', 'dln_c', 'dln_ib', 'i_10y'};
data_mat = [yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y];
for j = 1:length(varnames)
    v = data_mat(:, j);
    fprintf('  %-10s: mean=%.4f, std=%.4f\n', varnames{j}, mean(v), std(v));
end

% Save
outfile = fullfile(fileparts(mfilename('fullpath')), 'estimation_data.mat');
save(outfile, 'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
     'pi_w', 'dln_c', 'dln_ib', 'i_10y');
fprintf('\nSaved %d obs x 9 variables to %s\n', nObs, outfile);
fprintf('=== Bayesian data preparation complete ===\n');

end
