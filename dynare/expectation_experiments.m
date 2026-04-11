%% expectation_experiments.m — Stage 11c: Expectation regime comparison
% Compares monetary policy transmission under different expectation assumptions.
% Replicates FR-BDF paper Section 6 key experiment.
%
% Three regimes:
%   1. Backward-looking: omega params = 0 (pure error correction + AR lags)
%   2. Hybrid: posterior mode values (current calibration)
%   3. Forward-looking: omega params = 0.65 (agents more forward-looking)
%
% Usage: run from c:\Users\david\french_model\dynare\ after running au_pac.mod

clear; clc;
addpath('C:\dynare\6.5\matlab');

fprintf('=== Expectation Regime Experiments ===\n\n');

%% Define regimes
% Current (hybrid) omega values from posterior estimation
omega_hybrid = struct('omega_pQ', 0.46, 'omega_n', 0.30, ...
                      'omega_c', 0.369, 'omega_ib', 0.35, 'omega_ih', 0.30);

regime_names = {'Backward-looking', 'Hybrid (posterior)', 'Forward-looking'};
omega_values = {
    struct('omega_pQ', 0.00, 'omega_n', 0.00, 'omega_c', 0.00, 'omega_ib', 0.00, 'omega_ih', 0.00)
    omega_hybrid
    struct('omega_pQ', 0.65, 'omega_n', 0.55, 'omega_c', 0.65, 'omega_ib', 0.60, 'omega_ih', 0.55)
};

%% Variables and shock to examine
shock_name = 'eps_i';
vars_to_plot = {'yhat_au', 'pi_au', 'dln_c', 'dln_ib', 'dln_ih', 'pi_w'};
var_labels   = {'Output gap', 'Inflation', 'Consumption growth', ...
                'Business inv. growth', 'Housing inv. growth', 'Wage inflation'};
nVars = length(vars_to_plot);
nRegimes = length(regime_names);

%% Run each regime
% We modify parameters in the Dynare workspace and re-solve
colors = {'b', 'k', 'r'};
styles = {'--', '-', '-.'};

% First run Dynare to get the baseline workspace
fprintf('Running baseline Dynare model...\n');
dynare au_pac noclearall;
T = options_.irf;

% Store IRFs for each regime
irfs_all = cell(nRegimes, 1);

for r = 1:nRegimes
    fprintf('\n--- Regime %d: %s ---\n', r, regime_names{r});
    ov = omega_values{r};

    % Save current parameter values
    param_names_omega = fieldnames(ov);

    % Set omega parameters
    for p = 1:length(param_names_omega)
        pname = param_names_omega{p};
        pval = ov.(pname);
        idx = find(strcmp(M_.param_names, pname));
        if ~isempty(idx)
            M_.params(idx) = pval;
            fprintf('  %s = %.3f\n', pname, pval);
        else
            fprintf('  WARNING: parameter %s not found\n', pname);
        end
    end

    % Re-solve the model with new parameters
    try
        [dr, info] = resol(0, M_, options_, oo_);
        if info(1) == 0
            oo_.dr = dr;
            fprintf('  Model solved successfully.\n');
        else
            fprintf('  WARNING: Model solution failed (info=%d). Skipping.\n', info(1));
            continue;
        end
    catch ME
        fprintf('  ERROR: %s\n', ME.message);
        continue;
    end

    % Compute IRFs manually
    nVar = M_.endo_nbr;
    nExo = M_.exo_nbr;
    shock_idx = find(strcmp(M_.exo_names, shock_name));

    % Shock vector: 1 s.d. shock
    e = zeros(nExo, 1);
    shock_size = sqrt(M_.Sigma_e(shock_idx, shock_idx));
    e(shock_idx) = shock_size;

    % Simulate IRFs using decision rule
    irfs_regime = struct();
    y = zeros(nVar, T+1);

    % State-space: y_t = dr.ghx * y_{t-1}(state) + dr.ghu * e_t
    state_idx = oo_.dr.state_var;
    nState = length(state_idx);

    % Impact period
    y_state = zeros(nState, 1);
    for t = 1:T
        if t == 1
            y(:, t) = oo_.dr.ghu * e;
        else
            y_state = y(oo_.dr.order_var(state_idx), t-1);
            y(:, t) = oo_.dr.ghx * y_state;
        end
    end

    % Map back to declaration order
    for j = 1:nVars
        var_idx = find(strcmp(M_.endo_names, vars_to_plot{j}));
        if ~isempty(var_idx)
            dr_idx = find(oo_.dr.order_var == var_idx);
            irfs_regime.(vars_to_plot{j}) = y(dr_idx, 1:T);
        end
    end

    irfs_all{r} = irfs_regime;

    % Print peak responses
    for j = 1:nVars
        irf_j = irfs_regime.(vars_to_plot{j});
        [peak_val, peak_q] = max(abs(irf_j));
        peak_sign = sign(irf_j(peak_q));
        fprintf('  %-25s peak=%.4f at Q%d\n', var_labels{j}, peak_sign*peak_val, peak_q);
    end
end

%% Restore hybrid (baseline) parameters
ov = omega_values{2};
param_names_omega = fieldnames(ov);
for p = 1:length(param_names_omega)
    pname = param_names_omega{p};
    idx = find(strcmp(M_.param_names, pname));
    if ~isempty(idx)
        M_.params(idx) = ov.(pname);
    end
end
[dr, ~] = resol(0, M_, options_, oo_);
oo_.dr = dr;
fprintf('\nRestored hybrid parameters.\n');

%% Plot comparison
fprintf('\nGenerating comparison plots...\n');

fig = figure('Position', [100 100 1200 800], 'Visible', 'off');
for j = 1:nVars
    subplot(2, 3, j);
    hold on;
    for r = 1:nRegimes
        if ~isempty(irfs_all{r})
            plot(1:T, irfs_all{r}.(vars_to_plot{j}), ...
                [colors{r} styles{r}], 'LineWidth', 1.5);
        end
    end
    plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.5);
    title(var_labels{j}, 'FontSize', 10);
    xlabel('Quarters');
    ylabel('% deviation');
    xlim([1 min(T, 30)]);
    grid on;
    if j == 1
        legend(regime_names{:}, 'Location', 'best', 'FontSize', 7);
    end
    hold off;
end

sgtitle('Monetary Policy Transmission: Expectation Regimes', 'FontSize', 14);
saveas(fig, 'au_pac_expectation_comparison.png');
fprintf('Saved: au_pac_expectation_comparison.png\n');
close(fig);

fprintf('\n=== Expectation experiments complete ===\n');
fprintf('Key finding from FR-BDF: forward-looking expectations AMPLIFY transmission.\n');
fprintf('Check whether AU model shows same pattern.\n');
