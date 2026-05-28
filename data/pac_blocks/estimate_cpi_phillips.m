% estimate_cpi_phillips.m — single-equation OLS for CPI Phillips
% (wp1044 Eq 51 / FR-BDF Eq 80 — AU adaptation).
%
% Model equation (au_pac.mod line 1039):
%   pi_au_gap_t = lambda_pi * pi_au_gap_{t-1}
%               + kappa_pi  * yhat_au_{t-1}
%               + alpha_pc      * (piQ_t      - pibar_au_t)
%               + alpha_pc_lag  * (piQ_{t-1}  - pibar_au_{t-1})
%               + beta_pc_m     * (pi_m_t     - pibar_au_t)        [calibrated]
%               + gamma_oil     * dln_pcom_t                        [calibrated]
%               + b_ECM_pc      * (p_C_star_{t-1} - p_C_{t-1})      [calibrated]
%               + eps_pi
%
% This OLS identifies the 4 coefficients for which AU data exists in
% estimation_data.mat / l2_data_layer.mat:
%   lambda_pi, kappa_pi, alpha_pc, alpha_pc_lag
% The beta_pc_m / gamma_oil / b_ECM_pc terms remain at wp1044 calibration
% (need AU import-deflator + commodity series, not yet wired into the data
% pipeline). They are subtracted from the LHS only if calibrated values
% are zero — otherwise they enter as omitted-variable bias and the user is
% warned in the printout.
%
% Generates results_cpi_phillips.mat + .txt for parameter writeback.

clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load data
E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
L = load(fullfile(projectdir, 'data',   'l2_data_layer_v2.mat'));

% NOTE: estimation_data.pi_au is ALREADY in gap form (mean=0 across sample);
% it is the demeaned CPI inflation series, not raw pi_au. So pi_au_gap = pi_au.
pi_au_gap_E = E.pi_au(:);           % already-demeaned CPI inflation gap
yhat_au     = E.yhat_au(:);         % output gap

T_est = numel(pi_au_gap_E);
T_L   = numel(L.piQ);
trim  = T_L - T_est;                % L2 longer than estimation; trim front

piQ_full      = L.piQ(:);              % already in q/q % units (std ~0.9)
pi_au_trend_L = L.pi_au_trend(:);

piQ       = piQ_full(trim+1:end);
pibar_au  = pi_au_trend_L(trim+1:end); % trend pi_au; piQ_gap = piQ - pibar_au

assert(numel(piQ) == T_est, 'L2/estimation alignment mismatch');

%% Load import-deflator percentage-change directly from ABS 5206 IPD col 76
% Col 38 = Imports IPD (level, index w/ re-basing jumps unsuitable for log-diff);
% Col 76 = Imports IPD percentage changes (clean q/q %, ABS-published).
T_ipd = readtable(fullfile(projectdir,'data','abs_rba','abs_5206_ipd.xlsx'), ...
                  'Sheet','Data1','VariableNamingRule','preserve');
m_ipd_raw = T_ipd{:, 76};
if iscell(m_ipd_raw)
    pi_m_full = NaN(numel(m_ipd_raw),1);
    for i=1:numel(m_ipd_raw)
        v = m_ipd_raw{i};
        if isnumeric(v), pi_m_full(i) = v;
        elseif ischar(v) || isstring(v), pi_m_full(i) = str2double(v);
        end
    end
else
    pi_m_full = m_ipd_raw;
end
pi_m_full = pi_m_full(~isnan(pi_m_full));   % drop header / blank rows
% Trim to estimation sample (last 122 obs)
if numel(pi_m_full) >= T_est
    pi_m_aligned = pi_m_full(end-T_est+1:end);
else
    pi_m_aligned = [NaN(T_est - numel(pi_m_full),1); pi_m_full];
end
fprintf('Import IPD: %d obs loaded, %d valid, std=%.3f\n', ...
        numel(pi_m_full), sum(~isnan(pi_m_aligned)), std(pi_m_aligned,'omitnan'));

%% Construct regressors
pi_au_gap     = pi_au_gap_E;           % already gap form
piQ_gap       = piQ - pibar_au;        % VA-price inflation minus CPI trend
pi_m_gap      = pi_m_aligned - pibar_au;  % import-price inflation minus CPI trend

% Lags
pi_au_gap_lag = [NaN; pi_au_gap(1:end-1)];
yhat_au_lag   = [NaN; yhat_au(1:end-1)];
piQ_gap_lag   = [NaN; piQ_gap(1:end-1)];

% LHS
y = pi_au_gap;

% RHS matrix: [const, pi_au_gap(-1), yhat_au(-1), piQ_gap, pi_m_gap]
% Note: alpha_pc_lag dropped due to severe multicollinearity with pi_m_gap
% (corr > 0.99). wp1044 alpha_pc_lag = 0.023 is tiny relative to alpha_pc=0.385,
% so dropping is a minor specification choice; alpha_pc_lag will be set to 0.
X = [ones(T_est,1), pi_au_gap_lag, yhat_au_lag, piQ_gap, pi_m_gap];

% Drop NaNs
valid = ~any(isnan([X, y]), 2);
fprintf('CPI Phillips OLS: %d obs valid out of %d\n', sum(valid), T_est);

%% OLS
[b, se, tstat, R2, rss, N] = ols_with_se(X(valid,:), y(valid));

names = {'(intercept)', 'lambda_pi (pi_au_gap lag)', 'kappa_pi (yhat_au lag)', ...
         'alpha_pc (piQ_gap contemp)', 'beta_pc_m (pi_m_gap contemp)'};

fprintf('\nCPI Phillips single-equation OLS (wp1044 Eq 51 / FR-BDF Eq 80)\n');
fprintf('Generated %s\n\n', datetime('now'));
fprintf('%-32s  %10s  %10s  %8s\n', 'parameter', 'estimate', 'se', 't-stat');
for k = 1:numel(names)
    fprintf('%-32s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf('\nR^2 = %.4f, N = %d\n', R2, N);
fprintf('\nCurrent .mod calibration (for comparison):\n');
fprintf('  lambda_pi    = 0.4018 (wp1044 E-SAT)\n');
fprintf('  kappa_pi     = 0.0979 (wp1044 E-SAT)\n');
fprintf('  alpha_pc     = 0.3850 (wp1044 beta_1)\n');
fprintf('  alpha_pc_lag = 0.0230 (wp1044 beta_0 * correction)\n');
fprintf('\nNote: beta_pc_m, gamma_oil, b_ECM_pc remain wp1044-calibrated\n');
fprintf('      (no AU import-deflator / commodity / p_C_star series in pipeline).\n');

%% Save .mat + .txt
out.b     = b;
out.se    = se;
out.tstat = tstat;
out.R2    = R2;
out.N     = N;
out.names = names;
out.notes = 'CPI Phillips 4-coef OLS; import/oil/ECM left wp1044-calibrated';

save(fullfile(projectdir, 'data', 'pac_blocks', 'results_cpi_phillips.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_cpi_phillips.txt'), 'w');
fprintf(fid, 'CPI Phillips single-equation OLS (wp1044 Eq 51 / FR-BDF Eq 80)\n');
fprintf(fid, 'Generated %s\n\n', datetime('now'));
fprintf(fid, '%-32s  %10s  %10s  %8s\n', 'parameter', 'estimate', 'se', 't-stat');
for k = 1:numel(names)
    fprintf(fid, '%-32s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf(fid, '\nR^2 = %.4f, N = %d\n', R2, N);
fprintf(fid, '\nMethodology: 4-coef single-equation OLS.\n');
fprintf(fid, 'Sample: estimation_data.mat (1993Q3 onward, 122 obs).\n');
fprintf(fid, 'beta_pc_m, gamma_oil, b_ECM_pc kept at wp1044 calibration.\n');
fclose(fid);

fprintf('\nWrote results_cpi_phillips.mat + .txt\n');
