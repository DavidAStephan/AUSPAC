function estimate_ces_supply()
%% estimate_ces_supply.m — Phase 5: CES production function parameters
%
% Estimates the supply-side parameters following the FR-BDF nonlinear
% approach (WP #736, Section 4.3, eq 38):
%
%   sigma_ces: CES elasticity via grid search on nonlinear price frontier
%   alpha_k  : CES distribution parameter from AU factor income shares
%   delta_k  : quarterly depreciation rate
%   gamma_ulc: ULC pass-through in VA price target (from CES dual)
%   gamma_uck: user cost pass-through in VA price target (from CES dual)
%
% FR-BDF approach (eq 38):
%   log(p*_Q) = const + 1/(1-sigma) * log[alpha^sigma * r_K^(1-sigma)
%                                        + (1-alpha)^sigma * w_tilde^(1-sigma)]
%   Grid search over sigma in [0.1, 1.5], pick sigma that minimizes SSR.
%   FR-BDF gets sigma = 0.53, R² = 0.97.
%
% AU implementation:
%   - Construct level indices from Kalman-smoothed growth rates
%   - log_pQ from cumsum(piQ), log_w from cumsum(pi_w), uc_k in levels
%   - Grid search over sigma and alpha jointly
%
% USAGE:
%   cd('c:\Users\david\french_model\dynare')
%   addpath('C:\dynare\6.5\matlab')
%   estimate_ces_supply
%
% PREREQUISITES:
%   - smoother_results.mat (from estimate_pac_smooth_driver)
%   - pass1_results.mat (from estimate_pac_smooth_driver)

fprintf('================================================================\n');
fprintf('  PHASE 5: CES SUPPLY ESTIMATION (FR-BDF NONLINEAR APPROACH)\n');
fprintf('================================================================\n\n');

moddir = fileparts(mfilename('fullpath'));
datadir = fullfile(moddir, '..', 'data');
logfile = fullfile(moddir, 'ces_estimation_log.txt');
fid = fopen(logfile, 'w');
logm = @(msg) fprintf_both(fid, msg);

logm('================================================================\n');
logm('  PHASE 5: CES SUPPLY ESTIMATION (FR-BDF NONLINEAR APPROACH)\n');
logm(sprintf('  %s\n', datestr(now)));
logm('================================================================\n\n');

%% =====================================================================
%  STEP 1: Load smoothed data and construct level indices
%  =====================================================================

logm('--- STEP 1: Construct level indices from smoothed data ---\n\n');

if ~exist(fullfile(moddir, 'smoother_results.mat'), 'file')
    error('smoother_results.mat not found. Run estimate_pac_smooth_driver first.');
end
load(fullfile(moddir, 'smoother_results.mat'), 'oo_smooth');
SV = oo_smooth.SmoothedVariables;

load(fullfile(moddir, 'pass1_results.mat'), 'M_');
get_param = @(name) M_.params(strcmp(name, M_.param_names));

T = length(SV.piQ);
logm(sprintf('  Smoother data: T = %d quarters\n', T));

% --- VA price level index (log) ---
% piQ is quarterly VA inflation in percentage points (mean ~0.64 = 0.64% per quarter)
% Cumulate to get log price index: log_pQ(t) = sum(piQ(1:t)) / 100
log_pQ = cumsum(SV.piQ) / 100;
logm(sprintf('  log_pQ: range [%.4f, %.4f], trend = %.4f/q\n', ...
    min(log_pQ), max(log_pQ), (log_pQ(end)-log_pQ(1))/(T-1)));

% --- Wage level index (log) ---
% pi_w is quarterly wage inflation in percentage points
log_w = cumsum(SV.pi_w) / 100;
logm(sprintf('  log_w:  range [%.4f, %.4f], trend = %.4f/q\n', ...
    min(log_w), max(log_w), (log_w(end)-log_w(1))/(T-1)));

% --- Efficiency-adjusted wage (log) ---
% w_tilde = W / (E*H) where E is labor-augmenting efficiency
% dln_prod = dln_tfp / (1-alpha_k) = productivity growth
% In our model dln_prod ≈ 0 (gap model, TFP near unit root with tiny shocks)
% So log_w_tilde ≈ log_w (efficiency is approximately flat)
log_prod = cumsum(SV.dln_prod) / 100;
log_w_tilde = log_w - log_prod;
logm(sprintf('  log_w_tilde ~ log_w (dln_prod std = %.6f, negligible)\n', std(SV.dln_prod)));

% --- User cost of capital (log level) ---
% uc_k = WACC + delta_k - (pi_ib - piQ) in quarterly percentage points
% This is already a level variable (like an interest rate), not a growth rate
% uc_k mean ≈ 1.46 qpp (~5.8% annual)
% For the CES price frontier, we need log(r_K) where r_K is the rental rate
% Normalize: r_K = uc_k / 100 (convert from percentage points to decimal)
log_rK = log(SV.uc_k / 100);
logm(sprintf('  uc_k: mean = %.4f qpp, std = %.4f\n', mean(SV.uc_k), std(SV.uc_k)));
logm(sprintf('  log_rK: mean = %.4f, std = %.4f\n', mean(log_rK), std(log_rK)));

% --- Also try using WACC directly ---
log_wacc = log(SV.wacc / 100);

% Verify: all series have variation?
logm(sprintf('\n  Variation check (std of demeaned log levels):\n'));
logm(sprintf('    log_pQ (detrended):     %.6f\n', std(detrend(log_pQ))));
logm(sprintf('    log_w_tilde (detrended): %.6f\n', std(detrend(log_w_tilde))));
logm(sprintf('    log_rK:                 %.6f\n', std(log_rK)));

%% =====================================================================
%  STEP 2: Capital share (alpha) from Australian data
%  =====================================================================
%  FR-BDF: alpha = 0.26 (CES distribution parameter from French accounts)
%  We'll also grid-search over alpha jointly with sigma

logm('\n--- STEP 2: Capital share (alpha) ---\n');

% Try FRED download for labor share
labor_share_file = fullfile(datadir, 'fred_LABSHPAUA156NRUG.csv');
alpha_from_data = NaN;

% Skip FRED download (known timeout on this network). Use literature values.
% To enable: uncomment the websave block below.
% if ~exist(labor_share_file, 'file')
%     url = 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=LABSHPAUA156NRUG';
%     opts = weboptions('Timeout', 15);
%     websave(labor_share_file, url, opts);
% end

if exist(labor_share_file, 'file')
    T_ls = readtable(labor_share_file);
    if width(T_ls) >= 2
        ls_vals = T_ls{:, 2};
        ls_vals = ls_vals(~isnan(ls_vals));
        if ~isempty(ls_vals)
            if mean(ls_vals) > 1, ls_vals = ls_vals / 100; end
            alpha_from_data = 1 - mean(ls_vals);
            logm(sprintf('  Labor share (Penn World Table, N=%d): %.4f\n', length(ls_vals), mean(ls_vals)));
            logm(sprintf('  Capital share alpha = %.4f\n', alpha_from_data));
        end
    end
end

if isnan(alpha_from_data)
    logm('  Labor share unavailable. Will estimate alpha from grid search.\n');
    % Use literature range for Australia
    % Koh et al. (2020): AU capital share 0.35-0.45 (high due to mining)
    alpha_from_data = 0.40;
    logm(sprintf('  Literature prior: alpha ~ %.2f (mining-heavy economy)\n', alpha_from_data));
end

%% =====================================================================
%  STEP 3: Nonlinear CES price frontier — Grid search
%  =====================================================================
%  FR-BDF eq 38 (CES unit cost dual, log form):
%
%    log(p_Q) = c + 1/(1-sigma) * log[ alpha^sigma * r_K^(1-sigma)
%                                      + (1-alpha)^sigma * w_tilde^(1-sigma) ]
%
%  Rearranging:
%    log(p_Q) = c + 1/(1-sigma) * log[ alpha^sigma * exp((1-sigma)*log_rK)
%                                      + (1-alpha)^sigma * exp((1-sigma)*log_w_tilde) ]
%
%  Grid search: for each (sigma, alpha), compute RHS and regress against log_pQ.
%  The "const" c absorbs the markup mu and normalizations.
%  sigma that minimizes SSR (or maximizes R²) is the estimate.

logm('\n--- STEP 3: Nonlinear CES price frontier (grid search) ---\n');
logm('  FR-BDF eq 38: grid search over sigma, concentrated out alpha\n\n');

% Grid for sigma
sigma_grid = 0.05:0.01:1.50;
n_sigma = length(sigma_grid);

% Grid for alpha (narrow range around prior)
alpha_grid = 0.15:0.01:0.55;
n_alpha = length(alpha_grid);

% Store results
SSR_grid = NaN(n_sigma, n_alpha);
R2_grid  = NaN(n_sigma, n_alpha);

% Use demeaned/detrended log_pQ to focus on cyclical comovement
% (The trend in log_pQ is dominated by steady-state inflation, not CES)
% Actually FR-BDF fits the level equation including trend.
% Include a linear time trend to absorb balanced-growth-path trends.
t_vec = (1:T)';

for i = 1:n_sigma
    sig = sigma_grid(i);
    if abs(sig - 1) < 0.02
        % Near Cobb-Douglas: use log-linear form (limit)
        % log(p_Q) = c + (1-alpha)*log_w_tilde + alpha*log_rK
        for j = 1:n_alpha
            alp = alpha_grid(j);
            RHS = (1-alp) * log_w_tilde + alp * log_rK;
            X = [ones(T,1), t_vec, RHS];
            b = (X'*X)\(X'*log_pQ);
            e = log_pQ - X*b;
            SSR_grid(i,j) = e'*e;
            R2_grid(i,j) = 1 - SSR_grid(i,j) / ((log_pQ-mean(log_pQ))'*(log_pQ-mean(log_pQ)));
        end
    else
        for j = 1:n_alpha
            alp = alpha_grid(j);
            % CES aggregator inside the log
            % Z(t) = alpha^sigma * r_K(t)^(1-sigma) + (1-alpha)^sigma * w_tilde(t)^(1-sigma)
            term_K = alp^sig * exp((1-sig) * log_rK);
            term_L = (1-alp)^sig * exp((1-sig) * log_w_tilde);
            Z = term_K + term_L;

            % Check for numerical issues
            if any(Z <= 0) || any(~isfinite(Z))
                continue;
            end

            ces_index = (1/(1-sig)) * log(Z);

            % Regress log_pQ on ces_index (with constant + trend)
            X = [ones(T,1), t_vec, ces_index];
            b = (X'*X)\(X'*log_pQ);
            e = log_pQ - X*b;
            SSR_grid(i,j) = e'*e;
            R2_grid(i,j) = 1 - SSR_grid(i,j) / ((log_pQ-mean(log_pQ))'*(log_pQ-mean(log_pQ)));
        end
    end
end

% Find the best (sigma, alpha)
[min_ssr, lin_idx] = min(SSR_grid(:));
[best_i, best_j] = ind2sub(size(SSR_grid), lin_idx);
sigma_best = sigma_grid(best_i);
alpha_best = alpha_grid(best_j);
R2_best = R2_grid(best_i, best_j);

logm(sprintf('  Grid search results:\n'));
logm(sprintf('    sigma grid: [%.2f, %.2f], %d points\n', sigma_grid(1), sigma_grid(end), n_sigma));
logm(sprintf('    alpha grid: [%.2f, %.2f], %d points\n', alpha_grid(1), alpha_grid(end), n_alpha));
logm(sprintf('\n    BEST FIT:\n'));
logm(sprintf('    sigma_ces = %.4f\n', sigma_best));
logm(sprintf('    alpha_k   = %.4f\n', alpha_best));
logm(sprintf('    R²        = %.6f\n', R2_best));
logm(sprintf('    SSR       = %.6f\n', min_ssr));

% Profile: R² as function of sigma (at best alpha)
logm(sprintf('\n  R² profile over sigma (at alpha = %.2f):\n', alpha_best));
logm(sprintf('    %-8s %10s\n', 'sigma', 'R²'));
profile_sigmas = [0.10:0.10:0.50, sigma_best, 0.53, 0.60:0.10:1.00, 1.20, 1.50];
profile_sigmas = unique(sort(profile_sigmas));
for k = 1:length(profile_sigmas)
    sig_k = profile_sigmas(k);
    [~, idx_k] = min(abs(sigma_grid - sig_k));
    r2_k = R2_grid(idx_k, best_j);
    marker = '';
    if abs(sig_k - sigma_best) < 0.005, marker = ' <-- BEST'; end
    if abs(sig_k - 0.53) < 0.005, marker = [marker ' (FR-BDF)']; end
    logm(sprintf('    %-8.2f %10.6f%s\n', sigma_grid(idx_k), r2_k, marker));
end

% Profile: R² as function of alpha (at best sigma)
logm(sprintf('\n  R² profile over alpha (at sigma = %.2f):\n', sigma_best));
logm(sprintf('    %-8s %10s\n', 'alpha', 'R²'));
profile_alphas = [0.20:0.05:0.50];
for k = 1:length(profile_alphas)
    alp_k = profile_alphas(k);
    [~, idx_k] = min(abs(alpha_grid - alp_k));
    r2_k = R2_grid(best_i, idx_k);
    marker = '';
    if abs(alp_k - alpha_best) < 0.01, marker = ' <-- BEST'; end
    logm(sprintf('    %-8.2f %10.6f%s\n', alpha_grid(idx_k), r2_k, marker));
end

%% =====================================================================
%  STEP 4: Robustness — Alternative CES formulations
%  =====================================================================

logm('\n--- STEP 4: Robustness checks ---\n');

% === 4a: Fix alpha at data-based value, search sigma only ===
[~, alpha_data_idx] = min(abs(alpha_grid - alpha_from_data));
[~, sigma_at_data_alpha] = min(SSR_grid(:, alpha_data_idx));
sigma_at_data_alpha = sigma_grid(sigma_at_data_alpha);
R2_at_data_alpha = max(R2_grid(:, alpha_data_idx));

logm(sprintf('  4a. Fix alpha = %.2f (data), best sigma = %.4f, R² = %.6f\n', ...
    alpha_grid(alpha_data_idx), sigma_at_data_alpha, R2_at_data_alpha));

% === 4b: Fix alpha = 0.33 (current AU-PAC), search sigma ===
[~, alpha_033_idx] = min(abs(alpha_grid - 0.33));
[~, sigma_at_033] = min(SSR_grid(:, alpha_033_idx));
sigma_at_033 = sigma_grid(sigma_at_033);
R2_at_033 = max(R2_grid(:, alpha_033_idx));

logm(sprintf('  4b. Fix alpha = 0.33 (current), best sigma = %.4f, R² = %.6f\n', ...
    sigma_at_033, R2_at_033));

% === 4c: Fix alpha = 0.26 (FR-BDF), search sigma ===
[~, alpha_026_idx] = min(abs(alpha_grid - 0.26));
[~, sigma_at_026] = min(SSR_grid(:, alpha_026_idx));
sigma_at_026 = sigma_grid(sigma_at_026);
R2_at_026 = max(R2_grid(:, alpha_026_idx));

logm(sprintf('  4c. Fix alpha = 0.26 (FR-BDF), best sigma = %.4f, R² = %.6f\n', ...
    sigma_at_026, R2_at_026));

% === 4d: Use WACC instead of uc_k for capital cost ===
SSR_wacc = NaN(n_sigma, 1);
for i = 1:n_sigma
    sig = sigma_grid(i);
    alp = alpha_best;
    if abs(sig - 1) < 0.02
        RHS = (1-alp) * log_w_tilde + alp * log_wacc;
        X = [ones(T,1), t_vec, RHS];
    else
        term_K = alp^sig * exp((1-sig) * log_wacc);
        term_L = (1-alp)^sig * exp((1-sig) * log_w_tilde);
        Z = term_K + term_L;
        if any(Z <= 0) || any(~isfinite(Z)), continue; end
        ces_index = (1/(1-sig)) * log(Z);
        X = [ones(T,1), t_vec, ces_index];
    end
    b = (X'*X)\(X'*log_pQ);
    e = log_pQ - X*b;
    SSR_wacc(i) = e'*e;
end
R2_wacc = 1 - SSR_wacc / ((log_pQ-mean(log_pQ))'*(log_pQ-mean(log_pQ)));
[~, wacc_best_i] = min(SSR_wacc);
sigma_wacc = sigma_grid(wacc_best_i);

logm(sprintf('  4d. Using WACC instead of uc_k: best sigma = %.4f, R² = %.6f\n', ...
    sigma_wacc, R2_wacc(wacc_best_i)));

%% =====================================================================
%  STEP 5: Derive gamma_ulc and gamma_uck from CES dual
%  =====================================================================
%  At the optimum (sigma, alpha), the CES cost shares are:
%    s_L = (1-alpha)^sigma * w_tilde^(1-sigma) / Z
%    s_K = alpha^sigma * r_K^(1-sigma) / Z
%  For the linearized growth-rate model:
%    gamma_ulc = mean(s_L) * (regression coefficient on ces_index)
%    gamma_uck = mean(s_K) * (regression coefficient on ces_index)
%  Or more directly from the structural equation.

logm('\n--- STEP 5: CES dual coefficients ---\n');

sig = sigma_best;
alp = alpha_best;
if abs(sig - 1) < 0.02
    % Cobb-Douglas
    gamma_ulc_est = 1 - alp;
    gamma_uck_est = alp;
    logm(sprintf('  Cobb-Douglas (sigma≈1): gamma_ulc = %.4f, gamma_uck = %.4f\n', ...
        gamma_ulc_est, gamma_uck_est));
else
    % Compute time-varying cost shares
    term_K = alp^sig * exp((1-sig) * log_rK);
    term_L = (1-alp)^sig * exp((1-sig) * log_w_tilde);
    Z = term_K + term_L;
    s_K = term_K ./ Z;  % capital cost share
    s_L = term_L ./ Z;  % labor cost share

    gamma_ulc_est = mean(s_L);
    gamma_uck_est = mean(s_K);

    logm(sprintf('  Time-varying cost shares at sigma=%.2f, alpha=%.2f:\n', sig, alp));
    logm(sprintf('    Labor share  s_L: mean=%.4f, range=[%.4f, %.4f]\n', ...
        mean(s_L), min(s_L), max(s_L)));
    logm(sprintf('    Capital share s_K: mean=%.4f, range=[%.4f, %.4f]\n', ...
        mean(s_K), min(s_K), max(s_K)));
end

% Scale gamma_ulc and gamma_uck for the growth-rate model
% In the level equation, the full pass-through is 1.0 (unit cost = unit cost)
% In the growth-rate equation with rho_pQ persistence, the pass-through is smaller
% gamma_ulc_growth = (1 - rho_pQ) * s_L / (s_L + s_K)
% But FR-BDF calibrates these directly. Let's use the cost shares scaled to
% match FR-BDF's convention: gamma_ulc + gamma_uck ≈ 0.18 (FR-BDF)
scale_FR = 0.18 / (gamma_ulc_est + gamma_uck_est);
gamma_ulc_scaled = gamma_ulc_est * scale_FR;
gamma_uck_scaled = gamma_uck_est * scale_FR;

logm(sprintf('\n  For growth-rate model (gamma_ulc + gamma_uck ~ 0.18):\n'));
logm(sprintf('    gamma_ulc = %.4f (FR-BDF: 0.12)\n', gamma_ulc_scaled));
logm(sprintf('    gamma_uck = %.4f (FR-BDF: 0.06)\n', gamma_uck_scaled));

% Also compute the "raw" pass-through from regressing piQ on dln_ulc and dln_uc_k
Y_pq = SV.piQ(5:end);
X_pq = [SV.piQ(4:end-1), SV.dln_ulc(5:end), SV.dln_uc_k(5:end), ones(T-4,1)];
b_pq = (X_pq'*X_pq)\(X_pq'*Y_pq);
e_pq = Y_pq - X_pq*b_pq;
R2_pq = 1 - (e_pq'*e_pq)/((Y_pq-mean(Y_pq))'*(Y_pq-mean(Y_pq)));
se_pq = sqrt(diag((e_pq'*e_pq)/(T-4-4) * inv(X_pq'*X_pq)));

logm(sprintf('\n  Direct regression: piQ = rho*piQ(-1) + g1*dln_ulc + g2*dln_uc_k + c\n'));
logm(sprintf('    rho_pQ    = %.4f (s.e. %.4f, t=%.2f)\n', b_pq(1), se_pq(1), b_pq(1)/se_pq(1)));
logm(sprintf('    gamma_ulc = %.4f (s.e. %.4f, t=%.2f)\n', b_pq(2), se_pq(2), b_pq(2)/se_pq(2)));
logm(sprintf('    gamma_uck = %.4f (s.e. %.4f, t=%.2f)\n', b_pq(3), se_pq(3), b_pq(3)/se_pq(3)));
logm(sprintf('    R² = %.4f\n', R2_pq));

%% =====================================================================
%  STEP 6: delta_k from data
%  =====================================================================

logm('\n--- STEP 6: Depreciation rate ---\n');

delta_k_est = 0.025;  % keep standard value
logm(sprintf('  delta_k = %.4f (standard DSGE value, ~10%% annual)\n', delta_k_est));
logm(sprintf('  Note: ABS 5204.0 Table 52 would give exact CFC/K ratio.\n'));

%% =====================================================================
%  SUMMARY
%  =====================================================================

logm('\n================================================================\n');
logm('  ESTIMATION SUMMARY — CES PRODUCTION FUNCTION\n');
logm('================================================================\n\n');

logm(sprintf('  %-15s %10s %10s %10s %s\n', 'Parameter', 'FR-BDF', 'AU-PAC old', 'AU est', 'Source'));
logm(sprintf('  %-15s %10s %10s %10s %s\n', '---------', '------', '----------', '------', '------'));
logm(sprintf('  %-15s %10.4f %10.4f %10.4f %s\n', 'sigma_ces', 0.53, 0.53, sigma_best, 'CES frontier grid search'));
logm(sprintf('  %-15s %10.4f %10.4f %10.4f %s\n', 'alpha_k', 0.26, 0.33, alpha_best, 'Joint grid search'));
logm(sprintf('  %-15s %10.4f %10.4f %10.4f %s\n', 'delta_k', 0.025, 0.025, delta_k_est, 'Standard'));
logm(sprintf('  %-15s %10.4f %10.4f %10.4f %s\n', 'gamma_ulc', 0.12, 0.12, gamma_ulc_scaled, 'CES cost shares'));
logm(sprintf('  %-15s %10.4f %10.4f %10.4f %s\n', 'gamma_uck', 0.06, 0.06, gamma_uck_scaled, 'CES cost shares'));
logm(sprintf('  %-15s %10s %10s %10.6f %s\n', 'R²', '0.97', '—', R2_best, 'Price frontier'));

% Sensitivity summary
logm(sprintf('\n  Sensitivity to alpha (at best sigma = %.2f):\n', sigma_best));
logm(sprintf('    alpha=0.26 (FR-BDF): sigma=%.2f, R²=%.6f\n', sigma_at_026, R2_at_026));
logm(sprintf('    alpha=0.33 (old):    sigma=%.2f, R²=%.6f\n', sigma_at_033, R2_at_033));
logm(sprintf('    alpha=%.2f (data):   sigma=%.2f, R²=%.6f\n', alpha_from_data, sigma_at_data_alpha, R2_at_data_alpha));
logm(sprintf('    alpha=%.2f (joint):  sigma=%.2f, R²=%.6f  <-- BEST\n', alpha_best, sigma_best, R2_best));

% Save results
results = struct();
results.sigma_ces = sigma_best;
results.alpha_k = alpha_best;
results.delta_k = delta_k_est;
results.gamma_ulc = gamma_ulc_scaled;
results.gamma_uck = gamma_uck_scaled;
results.R2 = R2_best;
results.R2_grid = R2_grid;
results.sigma_grid = sigma_grid;
results.alpha_grid = alpha_grid;
results.sigma_at_alpha_026 = sigma_at_026;
results.sigma_at_alpha_033 = sigma_at_033;
results.sigma_at_alpha_data = sigma_at_data_alpha;
results.gamma_ulc_raw = gamma_ulc_est;
results.gamma_uck_raw = gamma_uck_est;

save(fullfile(moddir, 'ces_estimation_results.mat'), 'results');
logm(sprintf('\n  Results saved to ces_estimation_results.mat\n'));

logm('\n================================================================\n');
logm('  PHASE 5 COMPLETE\n');
logm('================================================================\n');
fclose(fid);
fprintf('Log: %s\n', logfile);

end

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0
        fprintf(fid, msg);
    end
end
