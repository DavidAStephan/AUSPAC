%% estimate_auxiliary_bayesian.m
% Phase B: Bayesian estimation of E-SAT auxiliary equation coefficients.
%
% The 22 auxiliary coefficients in au_pac.mod were carried over from FR-BDF
% because the previous Kalman-smoother-based equation-by-equation OLS produced
% implausible signs and magnitudes (multicollinearity in smoothed E-SAT state).
% This script re-estimates them using *observable* AU data with weakly
% informative Normal priors centred on FR-BDF values. Bayesian shrinkage handles
% the multicollinearity: where the data identify a coefficient, the posterior
% updates away from the prior; where they don't, the posterior stays near it.
%
% Auxiliary equations (FR-BDF Tables 4.4.4, 4.5.7, 4.6.3-4, 4.6.11-12, 4.6.16):
%
%   X_hat_t = rho_X * X_hat_{t-1}
%             + a_X_y * yhat_{t-1}
%             + a_X_i * i_gap_{t-1}
%             + a_X_pi * pi_gap_{t-1}
%             + a_X_u * u_gap_{t-1}
%             + d_covid * D_covid_t
%             + epsilon_t
%
% where X_hat is each PAC target gap (piQ, n, c, ib, rKB, ih), and the COVID
% pulses (2020Q2/Q3) are absorbed by dummies as in the PAC structural step.
%
% Method: Normal-Normal Bayesian linear regression with OLS sigma^2 plug-in.
%   - Prior: beta ~ N(beta_0, V_0), V_0 diagonal with sd_j = max(|beta_0_j|/2, 0.03).
%   - Posterior: beta | y ~ N(V_n*(V_0^{-1}*beta_0 + X'y/s2), V_n)
%     where V_n = (V_0^{-1} + X'X/s2)^{-1}.
%   - Reports posterior mean, 90% credible interval, and OLS comparator.
%
% OUTPUT:
%   dynare/auxiliary_bayesian_results.txt   — summary table
%   dynare/auxiliary_bayesian_results.mat   — posterior moments per equation
%   Console: ready-to-paste .mod parameter block lines.
%
% USAGE: run from the dynare/ directory in MATLAB R2019a+.
%   >> cd /path/to/AUSPAC/dynare
%   >> estimate_auxiliary_bayesian

clear; clc;
this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
projectdir = fullfile(this_dir, '..');

fprintf('=== Phase B: Bayesian estimation of E-SAT auxiliary coefficients ===\n\n');

%% 1. Load observable AU data
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
assert(height(T_base) == height(T_ext), 'Datasets must align by date.');
dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
nQ = height(T_base);
fprintf('Loaded %d quarters (%s to %s)\n', nQ, datestr(dates(1)), datestr(dates(end)));

%% 2. Build E-SAT state regressors (lagged in regressions)
yhat_au  = T_base.au_ygap;                      % output gap (already a gap, %)
pi_au    = T_base.au_pi;                        % CPI inflation (quarterly %)
i_au     = T_base.au_irate / 4;                 % cash rate (quarterly %)
ibar     = T_base.i_bar / 4;                    % i steady-state anchor
pibar_au = T_base.pi_bar_au;                    % pi anchor (= 0.625 quarterly)

i_gap    = i_au  - ibar;                        % real-rate gap proxy
pi_gap   = pi_au - pibar_au;                    % inflation gap

u_rate   = T_ext.au_urate;
u_gap    = u_rate - hp_trend(u_rate, 1600);     % unemployment gap (%)

i_10y    = T_ext.au_i10 / 4;                    % 10y bond yield (quarterly %)

%% 3. Build target-gap proxies via HP-filter detrending of log levels
piQ_hat  = pi_au - mean(pi_au, 'omitnan');      % VA price growth gap (CPI proxy)

% Employment level: log + HP filter
n_hat    = 100 * (log(T_ext.au_employment) - hp_trend(log(T_ext.au_employment), 1600));

% Consumption level
c_hat    = 100 * (log(T_ext.au_consumption) - hp_trend(log(T_ext.au_consumption), 1600));

% Business investment (non-dwelling GFCF)
ib_hat   = 100 * (log(T_ext.au_gfcf_nondwelling) - hp_trend(log(T_ext.au_gfcf_nondwelling), 1600));

% Housing investment (dwelling GFCF)
ih_hat   = 100 * (log(T_ext.au_gfcf_dwelling)    - hp_trend(log(T_ext.au_gfcf_dwelling), 1600));

% User cost gap (rKB): real long rate proxy + depreciation, detrended
%   rKB ≈ i_10y_real + delta_k where delta_k = 0.025 quarterly.
%   Following FR-BDF, rKB_hat is the gap from steady-state user cost.
delta_k_q = 0.025;
rKB_level = i_10y - pi_au + 100 * delta_k_q;
rKB_hat   = rKB_level - hp_trend(rKB_level, 1600);

%% 4. COVID pulse dummies (2020Q2 lockdown crash, 2020Q3 rebound)
D_crash  = (year(dates) == 2020 & quarter(dates) == 2);
D_bounce = (year(dates) == 2020 & quarter(dates) == 3);

%% 5. Equation-by-equation Bayesian regression
% Each entry of `eqs`:
%   .name       — display name
%   .y          — LHS target (length nQ)
%   .X_names    — regressor names (in order: lag of LHS, yhat, i_gap, pi_gap, u_gap, [optional])
%   .X_cols     — corresponding regressor columns (lagged where indicated)
%   .prior_mean — Normal prior means (current au_pac.mod values)
%   .prior_sd   — Normal prior sds (max(|prior|/2, 0.03))
%   .param_names— Dynare parameter names for output
%
% Convention: regressors enter at lag 1 (FR-BDF auxiliary structure).
%   X_t = [X_hat(t-1), yhat(t-1), i_gap(t-1), pi_gap(t-1), u_gap(t-1), D_crash, D_bounce]

eqs = struct([]);

% ----- VA price (FR-BDF Table 4.4.4) -----
eqs(end+1).name        = 'VA price (pv_pQ_aux)';
eqs(end).y             = piQ_hat;
eqs(end).X_lags        = {piQ_hat, yhat_au, i_gap, pi_gap, u_gap};
eqs(end).param_names   = {'rho_pQ_aux','a_pQ_y','a_pQ_i','a_pQ_pi','a_pQ_u'};
eqs(end).prior_mean    = [0.70, 0.03, -0.02, 0.01, -0.01];   % current au_pac.mod
eqs(end).status        = {'FR-BDF cal','FR-BDF cal','FR-BDF cal','FR-BDF cal','FR-BDF cal'};

% ----- Employment (FR-BDF Table 4.5.7, eq 57) -----
eqs(end+1).name        = 'Employment (pv_n_aux)';
eqs(end).y             = n_hat;
eqs(end).X_lags        = {n_hat, yhat_au, i_gap, pi_gap, u_gap};
eqs(end).param_names   = {'rho_n_aux','a_n_y','a_n_i','a_n_pi','a_n_u'};
eqs(end).prior_mean    = [0.56, 0.12, -0.03, 0.05, -0.02];   % rho is AU smoother est
eqs(end).status        = {'AU smoother','FR-BDF cal','FR-BDF cal','FR-BDF cal','FR-BDF cal'};

% ----- Consumption PV^2 (FR-BDF Table 4.6.4) -----
% Skip a_c_yh (yh data unavailable in extended_dataset) — keep current 0.10
eqs(end+1).name        = 'Consumption (pv_c_aux)';
eqs(end).y             = c_hat;
eqs(end).X_lags        = {c_hat, yhat_au, i_gap, pi_gap, u_gap};
eqs(end).param_names   = {'rho_c_aux','a_c_y','a_c_i','a_c_pi','a_c_u'};
eqs(end).prior_mean    = [0.71, 0.06, -0.04, 0.005, -0.03];
eqs(end).status        = {'AU smoother','FR-BDF cal','FR-BDF cal','FR-BDF cal','FR-BDF cal'};

% ----- Business investment (FR-BDF Table 4.6.11) -----
eqs(end+1).name        = 'Business inv (pv_ib_aux)';
eqs(end).y             = ib_hat;
eqs(end).X_lags        = {ib_hat, yhat_au, pi_gap, u_gap};
eqs(end).param_names   = {'rho_ib_aux','a_ib_y','a_ib_pi','a_ib_u'};
eqs(end).prior_mean    = [0.50, 0.05, 0.03, 0.00];
eqs(end).status        = {'AU smoother','AU smoother','FR-BDF cal','FR-BDF cal'};

% ----- User cost (FR-BDF Table 4.6.12) -----
eqs(end+1).name        = 'User cost (pv_rKB_aux)';
eqs(end).y             = rKB_hat;
eqs(end).X_lags        = {rKB_hat, i_gap};
eqs(end).param_names   = {'rho_rKB_aux','a_rKB_i'};
eqs(end).prior_mean    = [0.30, 0.24];
eqs(end).status        = {'FR-BDF cal','FR-BDF cal'};

% ----- Housing investment (FR-BDF Table 4.6.16) -----
eqs(end+1).name        = 'Housing inv (pv_ih_aux)';
eqs(end).y             = ih_hat;
eqs(end).X_lags        = {ih_hat, yhat_au, i_gap, pi_gap, u_gap};
eqs(end).param_names   = {'rho_ih_aux','a_ih_y','a_ih_i','a_ih_pi','a_ih_u'};
eqs(end).prior_mean    = [0.65, 0.10, -0.15, 0.05, 0.00];
eqs(end).status        = {'AU smoother','FR-BDF cal','FR-BDF cal','FR-BDF cal','FR-BDF cal'};

%% 6. Run Bayesian regressions
posterior = struct();
results_lines = {};
modblock_lines = {};
modblock_lines{end+1} = '// === Phase B: Bayesian estimation of E-SAT auxiliary coefficients ===';
modblock_lines{end+1} = '// Replaces FR-BDF calibration with AU posterior means.';
modblock_lines{end+1} = sprintf('// Generated by estimate_auxiliary_bayesian.m on %s', datestr(now, 'yyyy-mm-dd'));
modblock_lines{end+1} = '';

fprintf('\n%-30s %-12s %8s %8s %8s %8s %s\n', 'Parameter', 'Source', 'Prior', 'OLS', 'Post.mean', 'Post.sd', '[5%, 95%]');
fprintf('%s\n', repmat('-', 1, 105));

for k = 1:length(eqs)
    eq = eqs(k);
    fprintf('\n--- %s ---\n', eq.name);

    % Build regression matrix: lag all regressors by 1, add COVID dummies
    nReg = length(eq.X_lags);
    Xfull = zeros(nQ-1, nReg + 2);
    yfull = zeros(nQ-1, 1);
    for j = 1:nReg
        col = eq.X_lags{j};
        Xfull(:, j) = col(1:nQ-1);   % lagged regressor
    end
    yfull = eq.y(2:nQ);
    Xfull(:, nReg+1) = D_crash(2:nQ);
    Xfull(:, nReg+2) = D_bounce(2:nQ);

    % Drop rows with any NaN
    valid = all(~isnan([yfull, Xfull]), 2);
    y = yfull(valid);
    X = Xfull(valid, :);
    T = length(y);

    % Priors: structural coefficients only (not COVID dummies)
    beta_prior = [eq.prior_mean(:); 0; 0];
    sd_struct  = max(abs(eq.prior_mean(:))/2, 0.03);
    sd_covid   = [10; 10];   % flat prior on COVID
    V_diag     = [sd_struct.^2; sd_covid.^2];

    % OLS for sigma^2
    beta_ols = (X'*X) \ (X'*y);
    resid    = y - X*beta_ols;
    s2       = (resid'*resid) / (T - size(X,2));

    % Posterior moments
    Vinv = diag(1 ./ V_diag);
    V_n  = inv(Vinv + (X'*X) / s2);
    beta_n = V_n * (Vinv * beta_prior + (X'*y) / s2);
    sd_n   = sqrt(diag(V_n));

    % Store posterior for each structural coefficient
    for j = 1:nReg
        pname = eq.param_names{j};
        post_mean = beta_n(j);
        post_sd   = sd_n(j);
        ci_low    = post_mean - 1.645*post_sd;
        ci_high   = post_mean + 1.645*post_sd;

        posterior.(pname).mean   = post_mean;
        posterior.(pname).sd     = post_sd;
        posterior.(pname).ci_low = ci_low;
        posterior.(pname).ci_high= ci_high;
        posterior.(pname).ols    = beta_ols(j);
        posterior.(pname).prior  = eq.prior_mean(j);

        flag = '';
        % Sign-flip flag: if posterior CI excludes prior sign
        if sign(post_mean) ~= sign(eq.prior_mean(j)) && abs(eq.prior_mean(j)) > 1e-6
            flag = ' [sign-flip]';
        end

        fprintf('%-30s %-12s %8.3f %8.3f %8.3f %8.3f [%6.3f, %6.3f]%s\n', ...
            pname, eq.status{j}, eq.prior_mean(j), beta_ols(j), ...
            post_mean, post_sd, ci_low, ci_high, flag);

        results_lines{end+1} = sprintf('%s\t%s\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f', ...
            pname, eq.status{j}, eq.prior_mean(j), beta_ols(j), ...
            post_mean, post_sd, ci_low, ci_high);

        % Format .mod parameter line
        modblock_lines{end+1} = sprintf('%-15s = %7.3f;    // Bayesian posterior mean (Phase B); 90%% CI [%.3f, %.3f]; OLS=%.3f, FR-BDF=%.3f', ...
            pname, post_mean, ci_low, ci_high, beta_ols(j), eq.prior_mean(j));
    end

    fprintf('  COVID crash:  %+.3f  (s.d. %.3f)\n', beta_n(nReg+1), sd_n(nReg+1));
    fprintf('  COVID bounce: %+.3f  (s.d. %.3f)\n', beta_n(nReg+2), sd_n(nReg+2));
    fprintf('  R^2 (OLS): %.3f, T=%d\n', 1 - var(resid)/var(y), T);
end

%% 7. Save results
out_txt = fullfile(this_dir, 'auxiliary_bayesian_results.txt');
fid = fopen(out_txt, 'w');
fprintf(fid, 'Phase B: Bayesian estimation of E-SAT auxiliary coefficients\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'param\tstatus\tprior\tols\tpost_mean\tpost_sd\tci5\tci95\n');
for j = 1:length(results_lines), fprintf(fid, '%s\n', results_lines{j}); end
fprintf(fid, '\n\n--- .mod parameter block (paste into au_pac.mod / _var / _mce) ---\n\n');
for j = 1:length(modblock_lines), fprintf(fid, '%s\n', modblock_lines{j}); end
fclose(fid);

save(fullfile(this_dir, 'auxiliary_bayesian_results.mat'), 'posterior');

fprintf('\n=== Saved ===\n');
fprintf('  Summary: %s\n', out_txt);
fprintf('  Posterior struct: %s\n\n', fullfile(this_dir, 'auxiliary_bayesian_results.mat'));
fprintf('Next: paste the parameter block from auxiliary_bayesian_results.txt into\n');
fprintf('au_pac.mod, au_pac_var.mod, and au_pac_mce.mod (lines 810-861 in au_pac.mod).\n');
fprintf('Then run test_full_system.m to verify BK conditions and regenerate IRFs.\n');

%% ---------- helper: HP filter trend ----------
function trend = hp_trend(y, lambda)
% Hodrick-Prescott trend extraction. Handles NaN by interpolating, filtering,
% then re-introducing NaN at original locations.
    y = y(:);
    n = length(y);
    nanmask = isnan(y);
    if any(nanmask)
        valid_idx = find(~nanmask);
        y_filled  = interp1(valid_idx, y(valid_idx), 1:n, 'linear', 'extrap')';
    else
        y_filled = y;
    end

    % Construct second-difference matrix and solve (I + lambda*K'K) trend = y
    e = ones(n, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n-2, n);
    A  = speye(n) + lambda * (D2' * D2);
    trend = A \ y_filled;
    trend(nanmask) = NaN;
end
