%% run_pac_estimation.m
% PAC Iterative OLS estimation for AU-PAC model
% Step 2 of the FR-BDF two-step estimation procedure.
%
% Approach:
%   1. Run stoch_simul to get model-consistent simulated data
%   2. Load actual Australian data (observables)
%   3. For each PAC equation, estimate structural parameters by
%      reduced-form OLS since pac.estimate.iterative_ols requires
%      dseries which needs json=compute and full data for all vars.
%
% This script uses DIRECT OLS on each PAC equation, which is the
% same first iteration of the FR-BDF iterative OLS procedure.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fprintf('=== PAC Parameter Estimation (Reduced-Form OLS) ===\n');
fprintf('Timestamp: %s\n\n', datestr(now));

fid = fopen('pac_estimation_log.txt', 'w');
fprintf(fid, '=== PAC ESTIMATION RESULTS ===\n');
fprintf(fid, 'Timestamp: %s\n\n', datestr(now));

%% Load actual data
fprintf('Loading data...\n');
T_base = readtable('c:\Users\david\french_model\dataset.csv');
T_ext = readtable('c:\Users\david\french_model\data\extended_dataset.csv');
nQ = height(T_base);

% Construct observables (same as estimation_data.mat)
yhat_au = T_base.au_ygap;
pi_au   = T_base.au_pi;
i_au    = T_base.au_irate / 4;  % annualized -> quarterly
yhat_us = T_base.us_ygap;

% Derived variables
i_gap = i_au - T_base.i_bar;                     % interest rate gap
pi_au_gap = pi_au - T_base.pi_bar_au;            % inflation gap
u_gap = T_ext.au_urate - mean(T_ext.au_urate, 'omitnan');  % unemployment gap (demeaned)

% Consumption
cons = T_ext.au_consumption;
dln_c = [NaN; diff(log(cons))] * 100;
dln_c = dln_c - mean(dln_c, 'omitnan');  % demean

% Business investment (non-dwelling)
ib = T_ext.au_gfcf_nondwelling;
dln_ib = [NaN; diff(log(ib))] * 100;
dln_ib = dln_ib - mean(dln_ib, 'omitnan');

% Housing investment (dwelling)
ih = T_ext.au_gfcf_dwelling;
dln_ih = [NaN; diff(log(ih))] * 100;
dln_ih = dln_ih - mean(dln_ih, 'omitnan');

% Employment
emp = T_ext.au_employment;
dln_n = [NaN; diff(log(emp))] * 100;
dln_n = dln_n - mean(dln_n, 'omitnan');

% VA price (use GDP deflator inflation as proxy)
piQ = pi_au;  % GDP deflator ≈ VA price in gap model
piQ = piQ - mean(piQ, 'omitnan');

% Find valid sample (no NaN in key variables)
valid = ~isnan(yhat_au) & ~isnan(pi_au) & ~isnan(i_gap) & ...
        ~isnan(dln_c) & ~isnan(dln_ib) & ~isnan(dln_ih) & ~isnan(dln_n);
first_v = find(valid, 1, 'first') + 4;  % need 4 lags for employment PAC
last_v = find(valid, 1, 'last');
sample = first_v:last_v;
T = length(sample);
fprintf('Sample: obs %d to %d (%d quarters)\n\n', first_v, last_v, T);

%% =============================================================
% 1. VA PRICE PAC EQUATION (1st-order)
% =============================================================
% piQ(t) = b0_pQ * gap(-1) + b1_pQ * piQ(-1) + b2_pQ * yhat_au + eps
% (simplified: drop pac_expectation and pv_piQ_aux for direct OLS)

fprintf('--- 1. VA Price PAC (eq 44, 1st-order) ---\n');
y_pQ = piQ(sample);
X_pQ = [piQ(sample-1), yhat_au(sample)];
vnames_pQ = {'b1_pQ (AR1)', 'b2_pQ (output gap)'};

b_pQ = X_pQ \ y_pQ;
resid_pQ = y_pQ - X_pQ * b_pQ;
R2_pQ = 1 - var(resid_pQ) / var(y_pQ);

fprintf('  b1_pQ = %.4f (FR-BDF: 0.50)\n', b_pQ(1));
fprintf('  b2_pQ = %.4f (FR-BDF: 0.09)\n', b_pQ(2));
fprintf('  R2 = %.3f (FR-BDF: 0.40)\n', R2_pQ);
fprintf(fid, '1. VA Price PAC\n');
fprintf(fid, '  b1_pQ = %.6f  (AR1, FR-BDF: 0.50)\n', b_pQ(1));
fprintf(fid, '  b2_pQ = %.6f  (output gap, FR-BDF: 0.09)\n', b_pQ(2));
fprintf(fid, '  R2 = %.4f\n\n', R2_pQ);

%% =============================================================
% 2. EMPLOYMENT PAC (4th-order)
% =============================================================
% dln_n(t) = b1*dln_n(-1) + b2*dln_n(-2) + b3*dln_n(-3) + b4*dln_n(-4) + b5*yhat_au + eps

fprintf('\n--- 2. Employment PAC (eq 56, 4th-order) ---\n');
y_n = dln_n(sample);
X_n = [dln_n(sample-1), dln_n(sample-2), dln_n(sample-3), dln_n(sample-4), yhat_au(sample)];
vnames_n = {'b1_n (AR1)', 'b2_n (AR2)', 'b3_n (AR3)', 'b4_n (AR4)', 'b5_n (output gap)'};

b_n = X_n \ y_n;
resid_n = y_n - X_n * b_n;
R2_n = 1 - var(resid_n) / var(y_n);

fprintf('  b1_n = %.4f (FR-BDF: 0.87)\n', b_n(1));
fprintf('  b2_n = %.4f (FR-BDF: -0.30)\n', b_n(2));
fprintf('  b3_n = %.4f (FR-BDF: 0.17)\n', b_n(3));
fprintf('  b4_n = %.4f (added for AU)\n', b_n(4));
fprintf('  b5_n = %.4f (FR-BDF: 0.15)\n', b_n(5));
fprintf('  R2 = %.3f (FR-BDF: 0.92)\n', R2_n);
fprintf(fid, '2. Employment PAC\n');
for k=1:5; fprintf(fid, '  %s = %.6f\n', vnames_n{k}, b_n(k)); end
fprintf(fid, '  R2 = %.4f\n\n', R2_n);

%% =============================================================
% 3. CONSUMPTION PAC (1st-order)
% =============================================================
% dln_c(t) = b1*dln_c(-1) + b2*i_gap(-1) + b3*yhat_au + eps

fprintf('\n--- 3. Consumption PAC (eq 61, 1st-order) ---\n');
y_c = dln_c(sample);
X_c = [dln_c(sample-1), i_gap(sample-1), yhat_au(sample)];
vnames_c = {'b1_c (AR1)', 'b2_c (i_gap)', 'b3_c (output gap)'};

b_c = X_c \ y_c;
resid_c = y_c - X_c * b_c;
R2_c = 1 - var(resid_c) / var(y_c);

fprintf('  b1_c = %.4f (FR-BDF: -0.08)\n', b_c(1));
fprintf('  b2_c = %.4f (FR-BDF: -0.71)\n', b_c(2));
fprintf('  b3_c = %.4f (FR-BDF: 0.26)\n', b_c(3));
fprintf('  R2 = %.3f (FR-BDF: 0.54)\n', R2_c);
fprintf(fid, '3. Consumption PAC\n');
for k=1:3; fprintf(fid, '  %s = %.6f\n', vnames_c{k}, b_c(k)); end
fprintf(fid, '  R2 = %.4f\n\n', R2_c);

%% =============================================================
% 4. BUSINESS INVESTMENT PAC (2nd-order)
% =============================================================
% dln_ib(t) = b1*dln_ib(-1) + b2*dln_ib(-2) + b3*yhat_au + b4*i_gap(-1) + eps

fprintf('\n--- 4. Business Investment PAC (eq 64, 2nd-order) ---\n');
y_ib = dln_ib(sample);
X_ib = [dln_ib(sample-1), dln_ib(sample-2), yhat_au(sample), i_gap(sample-1)];
vnames_ib = {'b1_ib (AR1)', 'b2_ib (AR2)', 'b3_ib (output gap)', 'b4_ib (i_gap)'};

b_ib = X_ib \ y_ib;
resid_ib = y_ib - X_ib * b_ib;
R2_ib = 1 - var(resid_ib) / var(y_ib);

fprintf('  b1_ib = %.4f (FR-BDF: 0.29)\n', b_ib(1));
fprintf('  b2_ib = %.4f (FR-BDF: 0.20)\n', b_ib(2));
fprintf('  b3_ib = %.4f (FR-BDF: 0.58)\n', b_ib(3));
fprintf('  b4_ib = %.4f (FR-BDF: via PV)\n', b_ib(4));
fprintf('  R2 = %.3f (FR-BDF: 0.52)\n', R2_ib);
fprintf(fid, '4. Business Investment PAC\n');
for k=1:4; fprintf(fid, '  %s = %.6f\n', vnames_ib{k}, b_ib(k)); end
fprintf(fid, '  R2 = %.4f\n\n', R2_ib);

%% =============================================================
% 5. HOUSEHOLD INVESTMENT PAC (2nd-order)
% =============================================================
% dln_ih(t) = b1*dln_ih(-1) + b2*dln_ih(-2) + b3*yhat_au + b4*i_gap(-1) + eps

fprintf('\n--- 5. Household Investment PAC (eq 67, 2nd-order) ---\n');
y_ih = dln_ih(sample);
X_ih = [dln_ih(sample-1), dln_ih(sample-2), yhat_au(sample), i_gap(sample-1)];
vnames_ih = {'b1_ih (AR1)', 'b2_ih (AR2)', 'b3_ih (output gap)', 'b4_ih (i_gap)'};

b_ih = X_ih \ y_ih;
resid_ih = y_ih - X_ih * b_ih;
R2_ih = 1 - var(resid_ih) / var(y_ih);

fprintf('  b1_ih = %.4f (FR-BDF: 0.62)\n', b_ih(1));
fprintf('  b2_ih = %.4f (added for AU)\n', b_ih(2));
fprintf('  b3_ih = %.4f (FR-BDF: 0.34)\n', b_ih(3));
fprintf('  b4_ih = %.4f (AU-specific mortgage)\n', b_ih(4));
fprintf('  R2 = %.3f (FR-BDF: 0.87)\n', R2_ih);
fprintf(fid, '5. Household Investment PAC\n');
for k=1:4; fprintf(fid, '  %s = %.6f\n', vnames_ih{k}, b_ih(k)); end
fprintf(fid, '  R2 = %.4f\n\n', R2_ih);

%% =============================================================
% SHOCK STANDARD DEVIATIONS
% =============================================================
fprintf(fid, '\n=== SHOCK STANDARD DEVIATIONS ===\n');
fprintf(fid, 'eps_pQ  stderr = %.4f\n', std(resid_pQ));
fprintf(fid, 'eps_n   stderr = %.4f\n', std(resid_n));
fprintf(fid, 'eps_c   stderr = %.4f\n', std(resid_c));
fprintf(fid, 'eps_ib  stderr = %.4f\n', std(resid_ib));
fprintf(fid, 'eps_ih  stderr = %.4f\n', std(resid_ih));

fprintf(fid, '\n=== SUMMARY ===\n');
fprintf(fid, 'These are REDUCED-FORM OLS estimates (first iteration).\n');
fprintf(fid, 'They capture AR dynamics and output gap sensitivity\n');
fprintf(fid, 'but do not account for pac_expectation or pv_X_aux terms.\n');
fprintf(fid, 'The EC speed (b0_X) and expectations share (omega_X) cannot\n');
fprintf(fid, 'be identified from reduced-form OLS alone — they require\n');
fprintf(fid, 'the full Dynare pac.estimate.iterative_ols with json=compute.\n');

fclose(fid);
fprintf('\n=== Results saved to pac_estimation_log.txt ===\n');
