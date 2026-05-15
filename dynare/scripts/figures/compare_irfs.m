%% compare_irfs.m — Stage 11a: IRF comparison script
% Runs stoch_simul on au_pac.mod and plots key IRFs to a monetary policy shock.
% Compares against FR-BDF paper benchmarks (Section 6).
%
% Usage: run from <repo>/dynare

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

fprintf('=== IRF Comparison: AUSPAC Model ===\n\n');

%% Run Dynare (model should already be solved from prior run)
% If not, uncomment:
% dynare au_pac noclearall

% Load results from most recent Dynare run
load('au_pac/Output/au_pac_results.mat');

%% Extract IRFs to monetary policy shock (eps_i)
% Dynare stores IRFs as: oo_.irfs.<var>_<shock>
shock_name = 'eps_i';
vars_to_plot = {'yhat_au', 'pi_au', 'i_au', 'dln_c', 'dln_ib', 'dln_ih', 'pi_w', 's_gap', 'piQ'};
var_labels   = {'Output gap', 'Inflation (CPI)', 'Policy rate', ...
                'Consumption growth', 'Business inv. growth', 'Housing inv. growth', ...
                'Wage inflation', 'Exchange rate gap', 'VA price inflation'};
nVars = length(vars_to_plot);

% Collect IRF data
T = length(oo_.irfs.([vars_to_plot{1} '_' shock_name]));
irf_data = zeros(T, nVars);
for j = 1:nVars
    field = [vars_to_plot{j} '_' shock_name];
    if isfield(oo_.irfs, field)
        irf_data(:, j) = oo_.irfs.(field);
    else
        fprintf('  WARNING: IRF for %s not found\n', field);
    end
end

%% Print key statistics
fprintf('--- IRF to 1 s.d. monetary policy shock (eps_i) ---\n');
fprintf('  Shock size: %.4f (quarterly rate)\n\n', M_.Sigma_e(strcmp(M_.exo_names, 'eps_i'), strcmp(M_.exo_names, 'eps_i'))^0.5);

for j = 1:nVars
    irf_j = irf_data(:, j);
    [peak_val, peak_q] = max(abs(irf_j));
    peak_sign = sign(irf_j(peak_q));
    fprintf('  %-25s  peak=%.4f at Q%d, impact=%.4f, Q4=%.4f, Q8=%.4f\n', ...
        var_labels{j}, peak_sign*peak_val, peak_q, irf_j(1), ...
        irf_j(min(4,T)), irf_j(min(8,T)));
end

%% FR-BDF Benchmarks (Section 6, approximate)
fprintf('\n--- FR-BDF Paper Benchmarks (100bp shock, France) ---\n');
fprintf('  Output gap:     trough -0.3%% to -0.5%% at Q4-6\n');
fprintf('  Inflation:      trough -0.1%% to -0.2%% at Q6-8\n');
fprintf('  Housing inv:    most rate-sensitive demand component\n');
fprintf('  Consumption:    least rate-sensitive demand component\n');
fprintf('  Forward expectations amplify monetary transmission\n');

%% Plot
fprintf('\nGenerating IRF plots...\n');

fig = figure('Position', [100 100 1200 800], 'Visible', 'off');

for j = 1:nVars
    subplot(3, 3, j);
    plot(1:T, irf_data(:, j), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(1:T, zeros(T,1), 'k--', 'LineWidth', 0.5);
    title(var_labels{j}, 'FontSize', 10);
    xlabel('Quarters');
    ylabel('% deviation');
    xlim([1 T]);
    grid on;
end

sgtitle('AUSPAC Model: IRFs to Monetary Policy Shock (eps\_i)', 'FontSize', 14);

% Save
saveas(fig, 'au_pac_irfs_monetary.png');
fprintf('Saved: au_pac_irfs_monetary.png\n');
close(fig);

%% Also compute IRFs to TFP shock (supply-side validation)
fprintf('\n--- IRF to TFP shock (eps_tfp) ---\n');
shock_name2 = 'eps_tfp';
vars_supply = {'dln_y_star', 'dln_tfp', 'dln_prod', 'dln_ulc', 'piQ', 'dln_n_star_bar', 'pi_w', 'yhat_au'};
labels_supply = {'Potential output growth', 'TFP growth', 'Productivity growth', ...
                 'ULC growth', 'VA price inflation', 'Empl. target growth', ...
                 'Wage inflation', 'Output gap'};

for j = 1:length(vars_supply)
    field = [vars_supply{j} '_' shock_name2];
    if isfield(oo_.irfs, field)
        irf_j = oo_.irfs.(field);
        [peak_val, peak_q] = max(abs(irf_j));
        peak_sign = sign(irf_j(peak_q));
        fprintf('  %-25s  peak=%.4f at Q%d, impact=%.4f\n', ...
            labels_supply{j}, peak_sign*peak_val, peak_q, irf_j(1));
    end
end

fig2 = figure('Position', [100 100 1200 600], 'Visible', 'off');
for j = 1:length(vars_supply)
    subplot(2, 4, j);
    field = [vars_supply{j} '_' shock_name2];
    if isfield(oo_.irfs, field)
        plot(1:T, oo_.irfs.(field), 'r-', 'LineWidth', 1.5);
    end
    hold on;
    plot(1:T, zeros(T,1), 'k--', 'LineWidth', 0.5);
    title(labels_supply{j}, 'FontSize', 9);
    xlabel('Quarters');
    xlim([1 T]);
    grid on;
end
sgtitle('AUSPAC Model: IRFs to TFP Shock (eps\_tfp)', 'FontSize', 14);
saveas(fig2, 'au_pac_irfs_tfp.png');
fprintf('Saved: au_pac_irfs_tfp.png\n');
close(fig2);

fprintf('\n=== IRF comparison complete ===\n');
