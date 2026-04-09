%% bayesian_estimate.m
% Bayesian estimation of the E-SAT structural VAR for Australia using
% Random-Walk Metropolis-Hastings MCMC.
%
% Following Section 3.1.2 of Banque de France WP #736:
%   - The core system (5 equations: AU IS, Taylor, AU Phillips, US IS, US Phillips)
%     is estimated jointly via Bayesian methods
%   - Anchor equations (LR rate, LR inflation x2) are calibrated separately
%   - Priors are adapted from Table 3.1.1 for Australian context
%
% The structural form is: A*Z_t = B*Z_{t-1} + eps_t,  eps_t ~ N(0, Sigma)
% We estimate the structural parameters and shock std devs.
%
% Parameters estimated (17 total):
%   Core dynamics (12):
%     delta, lambda_q, sigma_q          (AU IS curve)
%     lambda_i, alpha_i, beta_i         (Taylor rule)
%     lambda_pi, kappa_pi               (AU Phillips curve)
%     lambda_q_us                       (US IS, AR1)
%     lambda_pi_us, kappa_pi_us         (US Phillips curve)
%   Shock std devs (5):
%     sig_eps_q, sig_eps_i, sig_eps_pi, sig_eps_q_us, sig_eps_pi_us
%
% Calibrated (not estimated):
%     lambda_ibar, lambda_pibar, lambda_pibar_us, i_ss, pi_ss_au, pi_ss_us
%
% Requires: data.mat (from download_data.m)
% Output:   params_bayes.mat, posterior diagnostics and comparison plots

clear; clc;
fprintf('=== E-SAT Australia: Bayesian Estimation (MCMC) ===\n\n');

outdir = fileparts(mfilename('fullpath'));
if isempty(outdir), outdir = pwd; end

%% -----------------------------------------------------------------------
%  1. Load data
%  -----------------------------------------------------------------------
load(fullfile(outdir, 'data.mat'), 'data');

yhat_au  = data.au_ygap;
pi_au    = data.au_pi;
i_au     = data.au_irate;
yhat_us  = data.us_ygap;
pi_us    = data.us_pi;
ibar     = data.au_irate_bar;
pibar_au = data.au_pi_bar;
pibar_us = data.us_pi_bar;
qDates   = data.qDates;

% Steady states
i_ss     = data.i_bar;
pi_ss_au = data.pi_bar_au;
pi_ss_us = data.pi_bar_us;

% Calibrated anchor persistence (same as paper)
lambda_ibar    = 0.985;
lambda_pibar   = 0.93;
lambda_pibar_us = 0.93;

%% -----------------------------------------------------------------------
%  2. Construct estimation data matrix (deviations from anchors)
%  -----------------------------------------------------------------------
% Gap variables
pi_au_gap = pi_au - pibar_au;
pi_us_gap = pi_us - pibar_us;
i_gap     = i_au - ibar;

% Find valid sample (all non-NaN, need t and t-1)
valid = ~isnan(yhat_au) & ~isnan(pi_au) & ~isnan(i_au) & ...
        ~isnan(yhat_us) & ~isnan(pi_us) & ~isnan(ibar) & ...
        ~isnan(pibar_au) & ~isnan(pibar_us);
valid_idx = find(valid);
est_idx = valid_idx(valid_idx > 1);
est_idx = est_idx(ismember(est_idx-1, valid_idx));
T = length(est_idx);

fprintf('Estimation sample: %s to %s (%d obs)\n', ...
    datestr(qDates(est_idx(1))), datestr(qDates(est_idx(end))), T);

% Pack observables into matrices for the likelihood function
% Y_t = [yhat_au(t), i_gap(t), pi_au_gap(t), yhat_us(t), pi_us_gap(t)]
% X_t = [yhat_au(t-1), i_gap(t-1), pi_au_gap(t-1), yhat_us(t-1), pi_us_gap(t-1), yhat_us(t)]
%
% But it's cleaner to work with the full state vector approach.
% We observe 5 core variables; the 3 anchors + intercept are treated as known.

Y = zeros(T, 5);  % [yhat_au, i_gap, pi_au_gap, yhat_us, pi_us_gap] at time t
X = zeros(T, 5);  % same variables at time t-1
Z_contemp = zeros(T, 1);  % yhat_us(t) for the IS curve

for k = 1:T
    t = est_idx(k);
    Y(k,:) = [yhat_au(t), i_gap(t), pi_au_gap(t), yhat_us(t), pi_us_gap(t)];
    X(k,:) = [yhat_au(t-1), i_gap(t-1), pi_au_gap(t-1), yhat_us(t-1), pi_us_gap(t-1)];
    Z_contemp(k) = yhat_us(t);  % contemporaneous US output gap in AU IS
end

%% -----------------------------------------------------------------------
%  3. Define parameter vector and priors
%  -----------------------------------------------------------------------
% Parameter ordering:
%  1: delta        AU-US output co-movement
%  2: lambda_q     AU IS persistence
%  3: sigma_q      AU IS real rate sensitivity
%  4: lambda_i     Taylor rule inertia
%  5: alpha_i      Taylor rule inflation response
%  6: beta_i       Taylor rule output gap response
%  7: lambda_pi    AU Phillips persistence
%  8: kappa_pi     AU Phillips slope
%  9: lambda_q_us  US IS persistence
% 10: lambda_pi_us US Phillips persistence
% 11: kappa_pi_us  US Phillips slope
% 12: sig_eps_q    Shock std: AU IS
% 13: sig_eps_i    Shock std: Taylor rule
% 14: sig_eps_pi   Shock std: AU Phillips
% 15: sig_eps_q_us Shock std: US IS
% 16: sig_eps_pi_us Shock std: US Phillips

npar = 16;
par_names = {'delta', 'lambda_q', 'sigma_q', 'lambda_i', 'alpha_i', 'beta_i', ...
             'lambda_pi', 'kappa_pi', 'lambda_q_us', 'lambda_pi_us', 'kappa_pi_us', ...
             'sig_eps_q', 'sig_eps_i', 'sig_eps_pi', 'sig_eps_q_us', 'sig_eps_pi_us'};

% Prior distributions (adapted from Table 3.1.1 for Australian context)
% Format: {name, distribution, param1, param2}
%   'N'  = Normal(mean, std)
%   'B'  = Beta(a, b) parameterized as Beta with mean=a/(a+b)
%   'G'  = Gamma(mean, std) -- shape/rate parameterization
%   'IG' = Inverse Gamma(scale, shape)
%
% We use mean/std parameterization and convert internally.

prior = struct();
prior.dist  = cell(npar,1);
prior.p1    = zeros(npar,1);  % mean (or location)
prior.p2    = zeros(npar,1);  % std (or scale)
prior.lb    = -inf(npar,1);   % lower bound
prior.ub    = inf(npar,1);    % upper bound

% 1: delta ~ N(0.2, 0.2) -- expect positive AU-US co-movement
prior.dist{1}='N'; prior.p1(1)=0.2;  prior.p2(1)=0.2;

% 2: lambda_q ~ B(0.5, 0.2) -- IS persistence, (0,1)
prior.dist{2}='B'; prior.p1(2)=0.5;  prior.p2(2)=0.2; prior.lb(2)=0.001; prior.ub(2)=0.999;

% 3: sigma_q ~ N(0.4, 0.2) -- real rate sensitivity (expect positive)
prior.dist{3}='N'; prior.p1(3)=0.4;  prior.p2(3)=0.2;

% 4: lambda_i ~ B(0.5, 0.15) -- Taylor rule inertia
prior.dist{4}='B'; prior.p1(4)=0.5;  prior.p2(4)=0.15; prior.lb(4)=0.001; prior.ub(4)=0.999;

% 5: alpha_i ~ N(1.5, 0.5) -- Taylor principle (should be > 1 for stability)
prior.dist{5}='N'; prior.p1(5)=1.5;  prior.p2(5)=0.5;

% 6: beta_i ~ G(0.5, 0.25) -- Taylor output gap response (positive)
prior.dist{6}='G'; prior.p1(6)=0.5;  prior.p2(6)=0.25; prior.lb(6)=0.001;

% 7: lambda_pi ~ B(0.5, 0.2) -- Phillips persistence
prior.dist{7}='B'; prior.p1(7)=0.5;  prior.p2(7)=0.2; prior.lb(7)=0.001; prior.ub(7)=0.999;

% 8: kappa_pi ~ G(0.1, 0.05) -- Phillips slope (positive)
prior.dist{8}='G'; prior.p1(8)=0.1;  prior.p2(8)=0.05; prior.lb(8)=0.001;

% 9: lambda_q_us ~ B(0.5, 0.2) -- US IS persistence
prior.dist{9}='B'; prior.p1(9)=0.5;  prior.p2(9)=0.2; prior.lb(9)=0.001; prior.ub(9)=0.999;

% 10: lambda_pi_us ~ B(0.5, 0.2) -- US Phillips persistence
prior.dist{10}='B'; prior.p1(10)=0.5; prior.p2(10)=0.2; prior.lb(10)=0.001; prior.ub(10)=0.999;

% 11: kappa_pi_us ~ G(0.05, 0.03) -- US Phillips slope
prior.dist{11}='G'; prior.p1(11)=0.05; prior.p2(11)=0.03; prior.lb(11)=0.001;

% 12-16: Shock std devs ~ IG(0.1, 2)  (Inverse Gamma)
for j = 12:16
    prior.dist{j}='IG'; prior.p1(j)=0.1; prior.p2(j)=2; prior.lb(j)=0.001;
end

%% -----------------------------------------------------------------------
%  4. Log-likelihood function
%  -----------------------------------------------------------------------
% The 5 core structural equations define residuals:
%   eps_q(t)    = yhat_au(t) - delta*yhat_us(t) - lambda_q*yhat_au(t-1)
%                 + sigma_q*(i_gap(t-1) - pi_au_gap(t-1))
%   eps_i(t)    = i_gap(t) - lambda_i*i_gap(t-1)
%                 - (1-lambda_i)*(alpha*pi_au_gap(t-1) + beta*yhat_au(t-1))
%   eps_pi(t)   = pi_au_gap(t) - lambda_pi*pi_au_gap(t-1) - kappa_pi*yhat_au(t-1)
%   eps_q_us(t) = yhat_us(t) - lambda_q_us*yhat_us(t-1)
%   eps_pi_us(t)= pi_us_gap(t) - lambda_pi_us*pi_us_gap(t-1) - kappa_pi_us*yhat_us(t-1)
%
% Each eps ~ N(0, sig_eps^2). Equations are block-recursive (US doesn't
% depend on AU, AU IS has contemporaneous yhat_us but US IS doesn't depend
% on AU), so the likelihood factors as a product of conditional normals.
%
% The A matrix is lower-triangular in our ordering if we put US equations
% first, but since A is sparse and simple, we can compute the Jacobian
% |det(A)| = 1 (all diagonal elements are 1, off-diags don't affect det
% except delta, but A is triangular with 1s on diagonal => det(A)=1).
% Actually det(A) = 1 since A has all 1s on diagonal and the only off-
% diagonal in the A matrix for the core 5x5 block is -delta in (1,4)
% position (AU IS depends on contemporaneous yhat_us). But the system is
% recursive: US equations don't depend on AU, so we can condition.
%
% Log-likelihood = sum over t of:
%   -0.5*log(2*pi) - log(sig_j) - 0.5*(eps_j(t)/sig_j)^2   for each eq j

% This function is defined at the bottom of the file.

%% -----------------------------------------------------------------------
%  5. Find posterior mode (optimization)
%  -----------------------------------------------------------------------
fprintf('\n--- Finding posterior mode ---\n');

% Start from OLS estimates
if exist(fullfile(outdir, 'params.mat'), 'file')
    ols = load(fullfile(outdir, 'params.mat'), 'params');
    p = ols.params;
    theta0 = [p.delta, p.lambda_q, p.sigma_q, p.lambda_i, p.alpha_i, p.beta_i, ...
              p.lambda_pi, max(p.kappa_pi, 0.01), p.lambda_q_us, ...
              p.lambda_pi_us, max(p.kappa_pi_us, 0.01), ...
              p.sigma_eps_q, p.sigma_eps_i, p.sigma_eps_pi, ...
              p.sigma_eps_q_us, p.sigma_eps_pi_us];
    fprintf('  Starting from OLS estimates\n');
else
    % Fallback starting values
    theta0 = [0.2, 0.5, 0.3, 0.8, 1.5, 0.3, 0.5, 0.08, 0.9, 0.35, 0.04, ...
              0.5, 0.1, 0.3, 0.6, 0.2];
    fprintf('  Starting from default values\n');
end

% Enforce bounds on starting values
for j = 1:npar
    theta0(j) = max(theta0(j), prior.lb(j) + 1e-4);
    if isfinite(prior.ub(j))
        theta0(j) = min(theta0(j), prior.ub(j) - 1e-4);
    end
end

% Negative log-posterior for optimization
neg_log_post = @(theta) -log_posterior(theta, Y, X, Z_contemp, T, prior);

% Optimize using fminsearch (no toolbox needed)
options = optimset('Display', 'iter', 'MaxIter', 5000, 'MaxFunEvals', 50000, ...
                   'TolFun', 1e-8, 'TolX', 1e-8);
[theta_mode, fval] = fminsearch(neg_log_post, theta0, options);

% Enforce bounds on mode
for j = 1:npar
    theta_mode(j) = max(theta_mode(j), prior.lb(j) + 1e-4);
    if isfinite(prior.ub(j))
        theta_mode(j) = min(theta_mode(j), prior.ub(j) - 1e-4);
    end
end

fprintf('\nPosterior mode found. Log-posterior = %.2f\n', -fval);
fprintf('\nMode estimates:\n');
for j = 1:npar
    fprintf('  %-15s = %8.4f\n', par_names{j}, theta_mode(j));
end

%% -----------------------------------------------------------------------
%  6. Compute Hessian at mode for MCMC proposal
%  -----------------------------------------------------------------------
fprintf('\n--- Computing Hessian at mode ---\n');
H_num = numerical_hessian(neg_log_post, theta_mode, npar);

% Proposal covariance = scaled inverse Hessian
try
    prop_cov = inv(H_num);
    % Ensure positive definite
    [V, D] = eig(prop_cov);
    D = diag(max(diag(D), 1e-10));
    prop_cov = V * D * V';
    prop_cov = (prop_cov + prop_cov') / 2;
    fprintf('  Hessian-based proposal covariance computed\n');
catch
    fprintf('  Hessian inversion failed; using diagonal proposal\n');
    prop_cov = diag((0.01 * abs(theta_mode) + 1e-4).^2);
end

%% -----------------------------------------------------------------------
%  7. MCMC: Random-Walk Metropolis-Hastings
%  -----------------------------------------------------------------------
fprintf('\n--- Running MCMC (Metropolis-Hastings) ---\n');

ndraws   = 50000;   % total draws
nburn    = 10000;   % burn-in
scale    = 0.15;    % proposal scaling factor (tune for ~25% acceptance)

% Storage
draws    = zeros(ndraws, npar);
log_posts = zeros(ndraws, 1);
accepted = 0;

% Initialize at mode
theta_curr = theta_mode;
lp_curr    = log_posterior(theta_curr, Y, X, Z_contemp, T, prior);

% Cholesky of proposal covariance
L_prop = chol(scale^2 * prop_cov, 'lower');

fprintf('  Draws: %d (burn-in: %d)\n', ndraws, nburn);
fprintf('  Running...\n');

tic;
for d = 1:ndraws
    % Propose
    theta_prop = theta_curr + (L_prop * randn(npar, 1))';

    % Check bounds
    in_bounds = true;
    for j = 1:npar
        if theta_prop(j) <= prior.lb(j) || theta_prop(j) >= prior.ub(j)
            in_bounds = false;
            break;
        end
    end

    if in_bounds
        lp_prop = log_posterior(theta_prop, Y, X, Z_contemp, T, prior);

        % Accept/reject
        log_alpha = lp_prop - lp_curr;
        if log(rand) < log_alpha
            theta_curr = theta_prop;
            lp_curr = lp_prop;
            accepted = accepted + 1;
        end
    end

    draws(d, :) = theta_curr;
    log_posts(d) = lp_curr;

    if mod(d, 10000) == 0
        elapsed = toc;
        acc_rate = accepted / d;
        fprintf('    Draw %d/%d  acceptance: %.1f%%  time: %.1fs\n', ...
            d, ndraws, acc_rate*100, elapsed);
    end
end
elapsed = toc;

acc_rate = accepted / ndraws;
fprintf('  Done. Total time: %.1fs\n', elapsed);
fprintf('  Acceptance rate: %.1f%%\n', acc_rate*100);

if acc_rate < 0.15
    fprintf('  WARNING: Acceptance rate low. Consider increasing proposal scale.\n');
elseif acc_rate > 0.40
    fprintf('  WARNING: Acceptance rate high. Consider decreasing proposal scale.\n');
end

%% -----------------------------------------------------------------------
%  8. Posterior analysis
%  -----------------------------------------------------------------------
fprintf('\n--- Posterior Summary ---\n');

post_draws = draws(nburn+1:end, :);
npost = size(post_draws, 1);

post_mean = mean(post_draws);
post_std  = std(post_draws);
post_q10  = myquantile(post_draws, 0.10);
post_q90  = myquantile(post_draws, 0.90);

fprintf('%-15s %8s %8s %8s %8s %8s %8s\n', ...
    'Parameter', 'Prior_m', 'Mode', 'Mean', 'Std', '10%', '90%');
fprintf('%-15s %8s %8s %8s %8s %8s %8s\n', ...
    '---------', '-------', '----', '----', '---', '---', '---');
for j = 1:npar
    fprintf('%-15s %8.4f %8.4f %8.4f %8.4f %8.4f %8.4f\n', ...
        par_names{j}, prior.p1(j), theta_mode(j), ...
        post_mean(j), post_std(j), post_q10(j), post_q90(j));
end

%% -----------------------------------------------------------------------
%  9. Save Bayesian parameters (posterior means)
%  -----------------------------------------------------------------------
params = struct();
params.delta       = post_mean(1);
params.lambda_q    = post_mean(2);
params.sigma_q     = post_mean(3);
params.lambda_i    = post_mean(4);
params.alpha_i     = post_mean(5);
params.beta_i      = post_mean(6);
params.lambda_pi   = post_mean(7);
params.kappa_pi    = post_mean(8);
params.lambda_q_us = post_mean(9);
params.lambda_pi_us = post_mean(10);
params.kappa_pi_us  = post_mean(11);
params.sigma_eps_q     = post_mean(12);
params.sigma_eps_i     = post_mean(13);
params.sigma_eps_pi    = post_mean(14);
params.sigma_eps_q_us  = post_mean(15);
params.sigma_eps_pi_us = post_mean(16);

% Calibrated (not estimated)
params.lambda_ibar    = lambda_ibar;
params.lambda_pibar   = lambda_pibar;
params.lambda_pibar_us = lambda_pibar_us;
params.i_ss        = i_ss;
params.pi_ss_au    = pi_ss_au;
params.pi_ss_us    = pi_ss_us;
params.i_bar_annual = data.i_bar_annual;
params.pi_bar_au_annual = data.pi_bar_au_annual;
params.pi_bar_us_annual = data.pi_bar_us_annual;

% Save as params.mat (overwrites OLS version)
save(fullfile(outdir, 'params.mat'), 'params');
fprintf('\nBayesian posterior mean parameters saved to params.mat\n');

% Also save full MCMC output
mcmc = struct();
mcmc.draws = draws;
mcmc.log_posts = log_posts;
mcmc.post_draws = post_draws;
mcmc.theta_mode = theta_mode;
mcmc.acc_rate = acc_rate;
mcmc.ndraws = ndraws;
mcmc.nburn = nburn;
mcmc.par_names = par_names;
mcmc.prior = prior;
save(fullfile(outdir, 'mcmc_output.mat'), 'mcmc');
fprintf('Full MCMC output saved to mcmc_output.mat\n');

%% -----------------------------------------------------------------------
% 10. Diagnostic plots
%  -----------------------------------------------------------------------
fprintf('\n--- Generating diagnostic plots ---\n');

% --- Figure: Trace plots (selected parameters) ---
plot_idx = [1,2,3,5,7,8];  % delta, lambda_q, sigma_q, alpha_i, lambda_pi, kappa_pi
figure('Name', 'MCMC Trace Plots', 'Position', [50 50 1200 600]);
for k = 1:length(plot_idx)
    subplot(2,3,k);
    j = plot_idx(k);
    plot(draws(:,j), 'Color', [0.3 0.3 0.8 0.3], 'LineWidth', 0.5);
    hold on;
    yline(post_mean(j), 'r-', 'LineWidth', 1.5);
    yline(theta_mode(j), 'g--', 'LineWidth', 1.2);
    title(par_names{j}, 'Interpreter', 'none');
    xlabel('Draw');
    if k == 1
        legend('Chain', 'Post. mean', 'Mode', 'Location', 'best');
    end
end
sgtitle('MCMC Trace Plots', 'FontSize', 14);
saveas(gcf, fullfile(outdir, 'mcmc_traces.png'));
fprintf('  Saved: mcmc_traces.png\n');

% --- Figure: Prior vs Posterior (selected parameters) ---
figure('Name', 'Prior vs Posterior', 'Position', [100 100 1200 600]);
for k = 1:length(plot_idx)
    subplot(2,3,k);
    j = plot_idx(k);

    % Posterior histogram
    histogram(post_draws(:,j), 50, 'Normalization', 'pdf', ...
        'FaceColor', [0.3 0.3 0.8], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
    hold on;

    % Prior density
    xrange = linspace(myquantile(post_draws(:,j), 0.001), ...
                      myquantile(post_draws(:,j), 0.999), 200);
    prior_pdf = eval_prior_pdf(xrange, prior.dist{j}, prior.p1(j), prior.p2(j));
    plot(xrange, prior_pdf, 'k-', 'LineWidth', 1.5);

    xline(post_mean(j), 'r-', 'LineWidth', 1.5);
    xline(theta_mode(j), 'g--', 'LineWidth', 1.2);
    title(par_names{j}, 'Interpreter', 'none');
    if k == 1
        legend('Posterior', 'Prior', 'Post. mean', 'Mode', 'Location', 'best');
    end
end
sgtitle('Prior (black) vs Posterior (blue)', 'FontSize', 14);
saveas(gcf, fullfile(outdir, 'prior_vs_posterior.png'));
fprintf('  Saved: prior_vs_posterior.png\n');

% --- Comparison table: OLS vs Bayes vs France ---
fprintf('\n=== Comparison: OLS vs Bayesian vs France ===\n');
if exist(fullfile(outdir, 'params.mat'), 'file')
    fprintf('%-15s %10s %10s %10s\n', 'Parameter', 'OLS', 'Bayes', 'France*');
    fprintf('%-15s %10s %10s %10s\n', '---------', '---', '-----', '-------');
    % OLS values (from previous run)
    ols_vals = theta0;  % we started MCMC from OLS
    france_vals = [0.08, 0.73, 0.28, 0.92, 1.19, 0.09, 0.58, 0.08, 0.93, 0.35, 0.04, ...
                   0.34, 0.10, 0.26, 0.58, 0.19];
    for j = 1:min(npar, length(france_vals))
        fprintf('%-15s %10.4f %10.4f %10.4f\n', ...
            par_names{j}, ols_vals(j), post_mean(j), france_vals(j));
    end
    fprintf('* France: posterior means from WP #736, Table 3.1.1\n');
end

fprintf('\n=== Bayesian estimation complete ===\n');


%% =======================================================================
%  LOCAL FUNCTIONS
%  =======================================================================

function lp = log_posterior(theta, Y, X, Z_contemp, T, prior)
% Compute log-posterior = log-likelihood + log-prior
    ll = log_likelihood(theta, Y, X, Z_contemp, T);
    lpr = log_prior(theta, prior);
    lp = ll + lpr;
    if isnan(lp) || isinf(lp)
        lp = -1e15;
    end
end

function ll = log_likelihood(theta, Y, X, Z_contemp, T)
% Compute log-likelihood of the 5 core structural equations.
%
% Y(:,k) = observed variable k at time t
% X(:,k) = observed variable k at time t-1
% Y columns: [yhat_au, i_gap, pi_au_gap, yhat_us, pi_us_gap]
% X columns: same at t-1
% Z_contemp = yhat_us(t)  (contemporaneous for AU IS)

    delta      = theta(1);
    lambda_q   = theta(2);
    sigma_q    = theta(3);
    lambda_i   = theta(4);
    alpha_i    = theta(5);
    beta_i     = theta(6);
    lambda_pi  = theta(7);
    kappa_pi   = theta(8);
    lambda_q_us = theta(9);
    lambda_pi_us = theta(10);
    kappa_pi_us  = theta(11);
    sig_q      = theta(12);
    sig_i      = theta(13);
    sig_pi     = theta(14);
    sig_q_us   = theta(15);
    sig_pi_us  = theta(16);

    % Check positivity of std devs
    if sig_q <= 0 || sig_i <= 0 || sig_pi <= 0 || sig_q_us <= 0 || sig_pi_us <= 0
        ll = -1e15;
        return;
    end

    % Structural residuals for each equation
    % Eq 1 (AU IS): eps_q = yhat_au(t) - delta*yhat_us(t) - lambda_q*yhat_au(t-1)
    %               + sigma_q*(i_gap(t-1) - pi_au_gap(t-1))
    %   Note: real rate gap = i_gap - pi_au_gap = (i-ibar) - (pi_au-pibar_au)
    eps_q = Y(:,1) - delta*Z_contemp - lambda_q*X(:,1) ...
            + sigma_q*(X(:,2) - X(:,3));
    % Wait, the sign: the IS curve says yhat = ... - sigma_q*(real_rate_gap)
    % real_rate_gap = i - pi - ibar + pibar = i_gap - pi_gap
    % So: yhat_au(t) = delta*yhat_us(t) + lambda_q*yhat_au(t-1) - sigma_q*(i_gap(t-1) - pi_gap(t-1))
    % eps_q = yhat_au(t) - delta*yhat_us(t) - lambda_q*yhat_au(t-1) + sigma_q*(i_gap(t-1) - pi_gap(t-1))
    % That's correct above.

    % Eq 2 (Taylor): eps_i = i_gap(t) - lambda_i*i_gap(t-1)
    %                - (1-lambda_i)*(alpha*pi_au_gap(t-1) + beta*yhat_au(t-1))
    eps_i = Y(:,2) - lambda_i*X(:,2) ...
            - (1-lambda_i)*(alpha_i*X(:,3) + beta_i*X(:,1));

    % Eq 3 (AU Phillips): eps_pi = pi_au_gap(t) - lambda_pi*pi_au_gap(t-1) - kappa_pi*yhat_au(t-1)
    eps_pi = Y(:,3) - lambda_pi*X(:,3) - kappa_pi*X(:,1);

    % Eq 4 (US IS): eps_q_us = yhat_us(t) - lambda_q_us*yhat_us(t-1)
    eps_q_us = Y(:,4) - lambda_q_us*X(:,4);

    % Eq 5 (US Phillips): eps_pi_us = pi_us_gap(t) - lambda_pi_us*pi_us_gap(t-1) - kappa_pi_us*yhat_us(t-1)
    eps_pi_us = Y(:,5) - lambda_pi_us*X(:,5) - kappa_pi_us*X(:,4);

    % Log-likelihood (sum of 5 independent normals per observation)
    ll = -0.5*T*5*log(2*pi) ...
         - T*(log(sig_q) + log(sig_i) + log(sig_pi) + log(sig_q_us) + log(sig_pi_us)) ...
         - 0.5 * (sum(eps_q.^2)/sig_q^2 + sum(eps_i.^2)/sig_i^2 ...
                 + sum(eps_pi.^2)/sig_pi^2 + sum(eps_q_us.^2)/sig_q_us^2 ...
                 + sum(eps_pi_us.^2)/sig_pi_us^2);
end

function lpr = log_prior(theta, prior)
% Evaluate log-prior density at theta
    lpr = 0;
    npar = length(theta);
    for j = 1:npar
        x = theta(j);
        switch prior.dist{j}
            case 'N'  % Normal
                mu = prior.p1(j);
                sigma = prior.p2(j);
                lpr = lpr - 0.5*((x - mu)/sigma)^2 - log(sigma);

            case 'B'  % Beta (parameterized by mean, std)
                mu = prior.p1(j);
                sigma = prior.p2(j);
                % Convert to alpha, beta of Beta distribution
                if x <= 0 || x >= 1
                    lpr = -1e15; return;
                end
                v = sigma^2;
                a = mu * (mu*(1-mu)/v - 1);
                b = (1-mu) * (mu*(1-mu)/v - 1);
                if a <= 0 || b <= 0
                    a = 2; b = 2;  % fallback: uniform-ish
                end
                lpr = lpr + (a-1)*log(x) + (b-1)*log(1-x);
                % Note: ignoring normalizing constant (Beta function) since it's constant

            case 'G'  % Gamma (parameterized by mean, std)
                mu = prior.p1(j);
                sigma = prior.p2(j);
                if x <= 0
                    lpr = -1e15; return;
                end
                % shape k = (mu/sigma)^2, scale theta = sigma^2/mu
                k = (mu/sigma)^2;
                th = sigma^2/mu;
                lpr = lpr + (k-1)*log(x) - x/th;

            case 'IG'  % Inverse Gamma (scale, shape)
                s = prior.p1(j);  % scale
                nu = prior.p2(j);  % shape
                if x <= 0
                    lpr = -1e15; return;
                end
                lpr = lpr - (nu+1)*log(x) - nu*s^2/(2*x^2);
        end
    end
end

function H = numerical_hessian(f, x0, n)
% Compute numerical Hessian using central differences
    H = zeros(n, n);
    f0 = f(x0);
    h = max(abs(x0) * 1e-4, 1e-6);

    for i = 1:n
        for j = i:n
            x_pp = x0; x_pp(i) = x_pp(i) + h(i); x_pp(j) = x_pp(j) + h(j);
            x_pm = x0; x_pm(i) = x_pm(i) + h(i); x_pm(j) = x_pm(j) - h(j);
            x_mp = x0; x_mp(i) = x_mp(i) - h(i); x_mp(j) = x_mp(j) + h(j);
            x_mm = x0; x_mm(i) = x_mm(i) - h(i); x_mm(j) = x_mm(j) - h(j);

            H(i,j) = (f(x_pp) - f(x_pm) - f(x_mp) + f(x_mm)) / (4 * h(i) * h(j));
            H(j,i) = H(i,j);
        end
    end
end

function pdf = eval_prior_pdf(x, dist, p1, p2)
% Evaluate prior PDF at vector of points x
    pdf = zeros(size(x));
    switch dist
        case 'N'
            pdf = normpdf(x, p1, p2);
        case 'B'
            mu = p1; sigma = p2;
            v = sigma^2;
            a = mu * (mu*(1-mu)/v - 1);
            b = (1-mu) * (mu*(1-mu)/v - 1);
            if a > 0 && b > 0
                valid = x > 0 & x < 1;
                pdf(valid) = x(valid).^(a-1) .* (1-x(valid)).^(b-1);
                pdf = pdf / (sum(pdf) * (x(2)-x(1)) + eps);  % normalize
            end
        case 'G'
            mu = p1; sigma = p2;
            k = (mu/sigma)^2;
            th = sigma^2/mu;
            valid = x > 0;
            pdf(valid) = x(valid).^(k-1) .* exp(-x(valid)/th);
            pdf = pdf / (sum(pdf) * (x(2)-x(1)) + eps);
        case 'IG'
            s = p1; nu = p2;
            valid = x > 0;
            pdf(valid) = x(valid).^(-(nu+1)) .* exp(-nu*s^2./(2*x(valid).^2));
            pdf = pdf / (sum(pdf) * (x(2)-x(1)) + eps);
    end
end

function p = normpdf(x, mu, sigma)
% Normal PDF (avoid dependency on Statistics Toolbox)
    p = (1/(sigma*sqrt(2*pi))) * exp(-0.5*((x-mu)/sigma).^2);
end

function q = myquantile(X, p)
% Compute quantiles without Statistics Toolbox.
% X: matrix (nobs x nvar), p: scalar quantile (0-1)
% Returns row vector of quantiles for each column.
    [n, m] = size(X);
    q = zeros(1, m);
    for j = 1:m
        xs = sort(X(:,j));
        idx = p * (n - 1) + 1;
        lo = floor(idx); hi = ceil(idx);
        frac = idx - lo;
        lo = max(lo, 1); hi = min(hi, n);
        q(j) = xs(lo) * (1 - frac) + xs(hi) * frac;
    end
end
