function results = estimate_var_auxiliary(smoother_file, logfile)
%% estimate_var_auxiliary.m — OLS estimation of var_model auxiliary equations
%
% Estimates the 7 auxiliary equations in the enriched var_model from a
% COMBINATION of observed data (for E-SAT core states and directly observed
% auxiliary gaps) and smoother output (for unobserved auxiliary gaps).
%
% KEY INSIGHT: The Kalman smoother uses the var_model equations to impute
% unobserved auxiliary gaps, creating circularity if we estimate from
% smoothed data alone. Instead, we:
%   - Use OBSERVED data for E-SAT core states (yhat_au, i_gap, pi_gap, u_gap)
%   - Construct auxiliary gaps from OBSERVED levels (HP filter on consumption,
%     investment, employment) rather than model-internal smoothed states
%   - Only use smoother output for variables with no observable counterpart
%
% The 7 auxiliary equations determine the 12x12 companion matrix used by
% all 5 PAC models for h-vector computation.
%
% USAGE:
%   results = estimate_var_auxiliary()
%   results = estimate_var_auxiliary('smoother_results.mat', 'my_log.txt')

if nargin < 1 || isempty(smoother_file)
    smoother_file = 'smoother_results.mat';
end
if nargin < 2 || isempty(logfile)
    logfile = 'log_var_auxiliary_estimation.txt';
end

fid = fopen(logfile, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  VAR-MODEL AUXILIARY EQUATION ESTIMATION (OLS)\n');
fprintf(fid, '  Method: Observable proxy gaps + E-SAT core from data\n');
fprintf(fid, '  %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');

%% ========================================================================
%  Load and construct data
%  ========================================================================
fprintf(fid, '--- Loading data ---\n');

% Core dataset: yhat_au, pi_au, i_au (quarterly)
core = readtable('c:\Users\david\french_model\dataset.csv');
% Extended dataset: consumption, GFCF, employment, unemployment, wages, i10y
ext = readtable('c:\Users\david\french_model\data\extended_dataset.csv');

T_core = height(core);
T_ext = height(ext);
T = min(T_core, T_ext);

yhat_au = core.au_ygap(1:T);
pi_au = core.au_pi(1:T);
i_au = core.au_irate(1:T);

% Steady-state values (from model calibration)
i_ss = 1.0491;   % quarterly
pi_ss = 0.625;   % quarterly (2.5% annual)

% E-SAT core state variables (OBSERVED)
i_gap = i_au - i_ss;          % interest rate gap
pi_gap = pi_au - pi_ss;       % inflation gap

% Unemployment gap (from observed unemployment rate)
urate = ext.au_urate(1:T);
u_mean = mean(urate(~isnan(urate)));
u_gap = urate - u_mean;

fprintf(fid, '  Core data: T=%d, yhat range [%.2f, %.2f]\n', T, min(yhat_au), max(yhat_au));
fprintf(fid, '  i_ss=%.4f, pi_ss=%.4f, u_mean=%.2f\n\n', i_ss, pi_ss, u_mean);

%% ========================================================================
%  Construct auxiliary gap variables from OBSERVED data (HP filter)
%  ========================================================================
fprintf(fid, '--- Constructing auxiliary gaps from observed data ---\n');

% HP filter parameters (quarterly: lambda=1600)
hp_lambda = 1600;

% --- n_hat: employment gap ---
emp = ext.au_employment(1:T);
valid_emp = ~isnan(emp);
n_hat_obs = NaN(T, 1);
if sum(valid_emp) > 20
    [~, emp_trend] = hpfilter(log(emp(valid_emp)), hp_lambda);
    n_hat_obs(valid_emp) = log(emp(valid_emp)) - emp_trend;
    n_hat_obs = n_hat_obs * 100;  % convert to percentage
end

% --- c_hat: consumption gap ---
cons = ext.au_consumption(1:T);
valid_c = ~isnan(cons);
c_hat_obs = NaN(T, 1);
if sum(valid_c) > 20
    [~, c_trend] = hpfilter(log(cons(valid_c)), hp_lambda);
    c_hat_obs(valid_c) = log(cons(valid_c)) - c_trend;
    c_hat_obs = c_hat_obs * 100;
end

% --- ib_hat: business investment gap (non-dwelling GFCF) ---
gfcf_nd = ext.au_gfcf_nondwelling(1:T);
valid_ib = ~isnan(gfcf_nd);
ib_hat_obs = NaN(T, 1);
if sum(valid_ib) > 20
    [~, ib_trend] = hpfilter(log(gfcf_nd(valid_ib)), hp_lambda);
    ib_hat_obs(valid_ib) = log(gfcf_nd(valid_ib)) - ib_trend;
    ib_hat_obs = ib_hat_obs * 100;
end

% --- ih_hat: housing investment gap (dwelling GFCF) ---
gfcf_dw = ext.au_gfcf_dwelling(1:T);
valid_ih = ~isnan(gfcf_dw);
ih_hat_obs = NaN(T, 1);
if sum(valid_ih) > 20
    [~, ih_trend] = hpfilter(log(gfcf_dw(valid_ih)), hp_lambda);
    ih_hat_obs(valid_ih) = log(gfcf_dw(valid_ih)) - ih_trend;
    ih_hat_obs = ih_hat_obs * 100;
end

% --- piQ_hat: VA price target gap ---
% Proxy: CPI inflation deviation from HP trend
valid_pi = ~isnan(pi_au);
piQ_hat_obs = NaN(T, 1);
if sum(valid_pi) > 20
    [~, pi_trend] = hpfilter(pi_au(valid_pi), hp_lambda);
    piQ_hat_obs(valid_pi) = pi_au(valid_pi) - pi_trend;
end

% --- yh_ratio_hat: household income-to-output ratio gap ---
% Proxy: (consumption + housing inv) / output gap proxy
% Simple approximation: weighted combination of consumption and housing gaps
% Or use smoothed data for this one (no direct observable)
yh_hat_obs = NaN(T, 1);
if all(~isnan(c_hat_obs(valid_c))) && all(~isnan(ih_hat_obs(valid_ih)))
    % Use 0.8*consumption + 0.2*housing as income proxy
    overlap = valid_c & valid_ih;
    yh_hat_obs(overlap) = 0.8 * c_hat_obs(overlap) + 0.2 * ih_hat_obs(overlap);
end

% --- rKB_hat: user cost gap ---
% Proxy: interest rate gap * WACC multiplier
rKB_hat_obs = 4.45 * i_gap;  % FR-BDF: rKB = 4.45*(i-i_bar)

% Report data availability
fprintf(fid, '  n_hat:     %d valid obs (employment gap, HP filter)\n', sum(~isnan(n_hat_obs)));
fprintf(fid, '  c_hat:     %d valid obs (consumption gap, HP filter)\n', sum(~isnan(c_hat_obs)));
fprintf(fid, '  ib_hat:    %d valid obs (business inv gap, HP filter)\n', sum(~isnan(ib_hat_obs)));
fprintf(fid, '  ih_hat:    %d valid obs (housing inv gap, HP filter)\n', sum(~isnan(ih_hat_obs)));
fprintf(fid, '  piQ_hat:   %d valid obs (VA price gap, HP filter)\n', sum(~isnan(piQ_hat_obs)));
fprintf(fid, '  yh_hat:    %d valid obs (income ratio, composite proxy)\n', sum(~isnan(yh_hat_obs)));
fprintf(fid, '  rKB_hat:   %d valid obs (user cost, 4.45*i_gap)\n\n', sum(~isnan(rKB_hat_obs)));

%% ========================================================================
%  Define and estimate 7 auxiliary equations
%  ========================================================================

% FR-BDF calibrated values for comparison
cal = struct();
cal.rho_pQ_aux=0.70; cal.a_pQ_y=0.03; cal.a_pQ_i=-0.02; cal.a_pQ_pi=0.01; cal.a_pQ_u=-0.05;
cal.rho_n_aux=0.67; cal.a_n_y=0.12; cal.a_n_i=-0.03; cal.a_n_pi=0.05; cal.a_n_u=-0.04;
cal.rho_yh_aux=0.92; cal.a_yh_y=0.08; cal.a_yh_u=-0.10;
cal.rho_c_aux=0.60; cal.a_c_y=0.06; cal.a_c_i=-0.04; cal.a_c_pi=0.005; cal.a_c_u=-0.03; cal.a_c_yh=0.39;
cal.rho_ib_aux=0.59; cal.a_ib_y=0.15; cal.a_ib_pi=0.04; cal.a_ib_u=-0.02;
cal.rho_rKB_aux=0.30; cal.a_rKB_i=0.24;
cal.rho_ih_aux=0.71; cal.a_ih_y=0.08; cal.a_ih_i=-0.08; cal.a_ih_pi=0.05; cal.a_ih_u=-0.03;

% Equation specifications: {name, LHS_data, {RHS_data...}, {param_names...}}
equations = {
    'var_pQ', piQ_hat_obs, {piQ_hat_obs, yhat_au, i_gap, pi_gap, u_gap}, ...
        {'rho_pQ_aux', 'a_pQ_y', 'a_pQ_i', 'a_pQ_pi', 'a_pQ_u'};

    'var_n', n_hat_obs, {n_hat_obs, yhat_au, i_gap, pi_gap, u_gap}, ...
        {'rho_n_aux', 'a_n_y', 'a_n_i', 'a_n_pi', 'a_n_u'};

    'var_yh', yh_hat_obs, {yh_hat_obs, yhat_au, u_gap}, ...
        {'rho_yh_aux', 'a_yh_y', 'a_yh_u'};

    'var_c', c_hat_obs, {c_hat_obs, yhat_au, i_gap, pi_gap, u_gap, yh_hat_obs}, ...
        {'rho_c_aux', 'a_c_y', 'a_c_i', 'a_c_pi', 'a_c_u', 'a_c_yh'};

    'var_ib', ib_hat_obs, {ib_hat_obs, yhat_au, pi_gap, u_gap}, ...
        {'rho_ib_aux', 'a_ib_y', 'a_ib_pi', 'a_ib_u'};

    'var_rKB', rKB_hat_obs, {rKB_hat_obs, i_gap}, ...
        {'rho_rKB_aux', 'a_rKB_i'};

    'var_ih', ih_hat_obs, {ih_hat_obs, yhat_au, i_gap, pi_gap, u_gap}, ...
        {'rho_ih_aux', 'a_ih_y', 'a_ih_i', 'a_ih_pi', 'a_ih_u'};
};

nEqs = size(equations, 1);
results = struct();
results.equations = cell(nEqs, 1);

fprintf(fid, '================================================================\n');
fprintf(fid, '  OLS ESTIMATION RESULTS (observable proxy gaps)\n');
fprintf(fid, '================================================================\n\n');

for eq = 1:nEqs
    eq_name = equations{eq, 1};
    lhs_data = equations{eq, 2};
    rhs_data = equations{eq, 3};
    param_names = equations{eq, 4};
    nParams = length(param_names);

    fprintf(fid, '--- Equation: %s ---\n', eq_name);

    % Build Y and X (lagged)
    Y = lhs_data(2:end);
    X = zeros(T-1, nParams);
    for k = 1:nParams
        X(:, k) = rhs_data{k}(1:end-1);
    end

    % Remove rows with any NaN
    ok = ~any(isnan([Y, X]), 2);
    Y_est = Y(ok);
    X_est = X(ok, :);
    T_eff = length(Y_est);

    if T_eff < nParams + 5
        fprintf(fid, '  SKIPPED: only %d valid obs (need %d)\n\n', T_eff, nParams+5);
        % Keep calibrated values
        for k = 1:nParams
            results.(param_names{k}) = cal.(param_names{k});
            results.([param_names{k} '_se']) = NaN;
        end
        continue;
    end

    % OLS
    beta = X_est \ Y_est;
    resid = Y_est - X_est * beta;
    SSR = resid' * resid;
    SST = (Y_est - mean(Y_est))' * (Y_est - mean(Y_est));
    R2 = 1 - SSR / SST;
    sigma2 = SSR / (T_eff - nParams);
    se = sqrt(diag(sigma2 * inv(X_est' * X_est)));
    t_stats = beta ./ se;
    dw = sum(diff(resid).^2) / SSR;

    % Stability: cap AR coefficient
    if abs(beta(1)) > 0.95
        fprintf(fid, '  NOTE: AR coeff %.4f capped at 0.95\n', beta(1));
        beta(1) = sign(beta(1)) * 0.95;
    end

    % Print results
    fprintf(fid, '  %-18s %10s %10s %8s %10s\n', 'Parameter', 'AU est.', 'Std.Err', 't-stat', 'FR-BDF');
    fprintf(fid, '  %s\n', repmat('-', 1, 58));

    for k = 1:nParams
        pname = param_names{k};
        cal_val = cal.(pname);
        sig = '';
        if abs(t_stats(k)) > 2.576, sig = '***';
        elseif abs(t_stats(k)) > 1.960, sig = '**';
        elseif abs(t_stats(k)) > 1.645, sig = '*';
        end
        fprintf(fid, '  %-18s %+10.4f %10.4f %7.2f%-3s %+10.4f\n', ...
            pname, beta(k), se(k), t_stats(k), sig, cal_val);

        results.(pname) = beta(k);
        results.([pname '_se']) = se(k);
    end

    fprintf(fid, '  R2=%.4f, SSR=%.2f, sigma=%.4f, DW=%.2f, T=%d\n\n', ...
        R2, SSR, sqrt(sigma2), dw, T_eff);

    eq_result = struct('name', eq_name, 'param_names', {param_names}, ...
        'beta', beta, 'se', se, 'R2', R2, 'SSR', SSR, 'DW', dw, 'T', T_eff);
    results.equations{eq} = eq_result;
end

%% ========================================================================
%  Summary comparison table
%  ========================================================================
fprintf(fid, '================================================================\n');
fprintf(fid, '  SUMMARY: FR-BDF (calibrated) vs AU (estimated)\n');
fprintf(fid, '================================================================\n\n');

fprintf(fid, '%-18s %12s %12s %10s\n', 'Parameter', 'FR-BDF', 'AU estimate', 'Change');
fprintf(fid, '%s\n', repmat('-', 1, 54));

all_params = fieldnames(cal);
for k = 1:length(all_params)
    pname = all_params{k};
    if isfield(results, pname) && ~isnan(results.(pname))
        fprintf(fid, '%-18s %+12.4f %+12.4f %+10.4f\n', ...
            pname, cal.(pname), results.(pname), results.(pname) - cal.(pname));
    end
end

%% ========================================================================
%  Parameter update block for .mod files
%  ========================================================================
fprintf(fid, '\n================================================================\n');
fprintf(fid, '  PARAMETER UPDATE BLOCK (copy to .mod files)\n');
fprintf(fid, '================================================================\n\n');

fprintf(fid, '%% Estimated from AU observed data (%s)\n', datestr(now, 'yyyy-mm-dd'));
for eq = 1:nEqs
    eq_res = results.equations{eq};
    if ~isempty(eq_res)
        fprintf(fid, '%% %s (R2=%.3f, T=%d)\n', eq_res.name, eq_res.R2, eq_res.T);
        for k = 1:length(eq_res.param_names)
            pname = eq_res.param_names{k};
            if isfield(results, pname) && ~isnan(results.(pname))
                fprintf(fid, '%-18s = %+.6f;  %% (s.e. %.4f)\n', ...
                    pname, results.(pname), results.([pname '_se']));
            end
        end
        fprintf(fid, '\n');
    end
end

fprintf(fid, '\n  COMPLETED: %s\n', datestr(now));
fclose(fid);
fprintf('\n=== var_model auxiliary estimation complete (observable proxies) ===\n');
end

%% HP filter (built-in if unavailable)
function [trend, cycle] = hpfilter(y, lambda)
    T = length(y);
    % Build penalty matrix
    e = ones(T, 1);
    D = spdiags([e -2*e e], 0:2, T-2, T);
    % Solve: min (y-trend)^2 + lambda*(D*trend)^2
    trend = (speye(T) + lambda * (D' * D)) \ y;
    cycle = y - trend;
end
