%% long_run_convergence.m
%
% Generates FR-BDF Fig 5.1.1 equivalent: unconditional simulation showing
% AU-PAC's convergence to its balanced growth path from off-steady-state
% initial conditions.
%
% Method: takes the Hybrid model (au_pac.mod), perturbs three key initial
% conditions (output gap +5pp, real wage gap +5pp, housing price gap +20pp
% to mirror plausible AU starting conditions in 1994), simulates 200
% quarters of model dynamics with all shocks set to zero, and plots
% convergence of the key state variables.
%
% Output:
%   - long_run_convergence.png (12-panel grid)
%   - long_run_convergence.mat (simulated paths)
%
% Run from <repo>/dynare in MATLAB:
%   >> long_run_convergence
%
% Requires the Hybrid model to compile and produce a valid decision rule
% (BK rank satisfied). Reads from oo_.dr after `dynare au_pac noclearall`.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

T_sim = 200;        % quarters
N_inits = 3;        % three perturbation scenarios

fprintf('=== AU-PAC long-run convergence simulation ===\n');
fprintf('Sample length: %d quarters\n\n', T_sim);

%% Run Hybrid model to get the decision rule
fprintf('--- Compiling Hybrid model (au_pac.mod) ---\n');
dynare au_pac noclearall nograph;

%% Endogenous indices for variables of interest
labels = {'yhat_au', 'pi_au', 'piQ', 'dln_c', 'dln_ib', 'dln_ih', ...
          'dln_n', 'pi_w', 's_gap', 'i_au', 'i_10y', 'u_gap'};
plot_labels = {'Output gap (%)', 'CPI inflation (qpp)', ...
               'VA price infl. (qpp)', 'Consumption growth', ...
               'Business inv. growth', 'Housing inv. growth', ...
               'Employment growth', 'Wage inflation (qpp)', ...
               'Exchange rate gap', 'Policy rate (qpp)', ...
               '10Y yield (qpp)', 'Unemployment gap (pp)'};

% Map variable names to oo_.dr indices
endo_names = cellstr(M_.endo_names);
idx = zeros(length(labels), 1);
for i = 1:length(labels)
    found = find(strcmp(endo_names, labels{i}), 1);
    if isempty(found)
        warning('Variable %s not found in model', labels{i});
        idx(i) = NaN;
    else
        idx(i) = found;
    end
end

%% Decision rule structure (state-space form)
% y_t = ys + gx*(y_{t-1} - ys) + gu*u_t
% Where ys = oo_.dr.ys, gx = oo_.dr.ghx, gu = oo_.dr.ghu
ys = oo_.dr.ys;          % steady-state values
gx = oo_.dr.ghx;          % state transition matrix
gu = oo_.dr.ghu;          % shock loading matrix
state_var = oo_.dr.state_var;  % indices of pre-determined state vars
order_var = oo_.dr.order_var;   % DR ordering -> declaration ordering

n_endo = length(ys);
n_states = length(state_var);
n_shocks = size(gu, 2);

fprintf('  Endogenous variables: %d (states: %d, shocks: %d)\n', ...
    n_endo, n_states, n_shocks);

%% Three perturbation scenarios
scenarios = struct();

% Scenario 1: positive output gap shock to initial state (boom start)
scenarios(1).name = 'Output gap +5pp (boom-start)';
scenarios(1).perturb = struct();
scenarios(1).perturb.yhat_au = 5.0;
scenarios(1).perturb.dln_c = 0.5;
scenarios(1).perturb.u_gap = -1.0;

% Scenario 2: cost-push initial state (high VA inflation start)
scenarios(2).name = 'VA price gap +2pp (cost-push start)';
scenarios(2).perturb = struct();
scenarios(2).perturb.piQ = 2.0;
scenarios(2).perturb.pi_au = 1.5;
scenarios(2).perturb.pi_w = 1.5;

% Scenario 3: housing investment gap (housing-cycle start)
scenarios(3).name = 'Housing investment gap (housing-cycle start)';
scenarios(3).perturb = struct();
scenarios(3).perturb.dln_ih = 1.5;
scenarios(3).perturb.s_gap = 5.0;

%% Simulate each scenario
all_sims = cell(N_inits, 1);
for s = 1:N_inits
    fprintf('\n--- Scenario %d: %s ---\n', s, scenarios(s).name);

    % Build initial state deviation
    y_dev = zeros(n_endo, 1);
    pf = scenarios(s).perturb;
    pnames = fieldnames(pf);
    for k = 1:length(pnames)
        nm = pnames{k};
        ix = find(strcmp(endo_names, nm), 1);
        if ~isempty(ix)
            y_dev(ix) = pf.(nm);
        end
    end

    % Project to DR ordering
    y_dev_dr = y_dev(order_var);

    % Iterate decision rule with zero shocks
    Y = zeros(n_endo, T_sim);
    y_prev = y_dev_dr;
    for t = 1:T_sim
        y_state = y_prev(state_var);
        y_curr = gx * y_state;   % gu * 0 = 0
        Y(:, t) = ys + y_curr;
        y_prev = y_curr;
    end

    % Translate back to declaration order for output
    Y_out = zeros(size(Y));
    for j = 1:n_endo
        Y_out(order_var(j), :) = Y(j, :);
    end
    all_sims{s} = Y_out;
    fprintf('  Done.\n');
end

%% Plot 12-panel grid
fig = figure('Position', [20 20 1500 1000], 'Color', 'w', 'Visible', 'off');

colors = {[0 0.447 0.741], [0.850 0.325 0.098], [0.466 0.674 0.188]};
styles = {'-', '--', '-.'};
widths = [1.6, 1.6, 1.6];

for j = 1:length(labels)
    subplot(3, 4, j);
    hold on;
    if isnan(idx(j))
        title(['NOT FOUND: ' labels{j}], 'FontSize', 9);
        axis off;
        continue;
    end

    for s = 1:N_inits
        Y_out = all_sims{s};
        path = Y_out(idx(j), :);
        % Deviation from steady state for cleaner plots
        ss_val = ys(idx(j));
        plot(1:T_sim, path - ss_val, ...
            'Color', colors{s}, ...
            'LineStyle', styles{s}, ...
            'LineWidth', widths(s));
    end
    plot([1 T_sim], [0 0], 'k:', 'LineWidth', 0.5);

    title(plot_labels{j}, 'FontSize', 10);
    xlabel('Quarters', 'FontSize', 8);
    ylabel('Deviation from SS', 'FontSize', 8);
    grid on;
    set(gca, 'FontSize', 8);
    xlim([1 T_sim]);
    if j == 1
        legend({scenarios.name}, 'Location', 'best', 'FontSize', 7);
    end
end

sgtitle('AU-PAC long-run convergence to balanced growth path', ...
    'FontSize', 13, 'FontWeight', 'bold');

print(fig, 'long_run_convergence', '-dpng', '-r200');
fprintf('\n=== Saved: long_run_convergence.png ===\n');
close(fig);

%% Save simulated paths for later inspection
save('long_run_convergence.mat', 'all_sims', 'scenarios', 'labels', ...
     'plot_labels', 'idx', 'ys', 'T_sim');
fprintf('=== Saved: long_run_convergence.mat ===\n');
