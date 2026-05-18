%% sectoral_validation.m — Phase N: sectoral asset accounts validation
%
% Replicates FR-BDF Section 4.8.5: confirm that the sectoral wealth-to-GDP
% ratios (W_F/Y, W_G/Y, W_H/Y, W_N/Y) converge to their calibrated steady
% states under (a) zero shocks from off-SS initial conditions, and (b) a
% 100bp permanent term-premium shock stress test.
%
% Output:
%   sectoral_validation.png       — 4-panel convergence figure
%   sectoral_validation_stress.png — 4-panel term-premium stress test
%   sectoral_validation_log.txt    — convergence diagnostics
%
% SS values (from au_pac.mod):
%   w_F_ss = -2.80 (firms — net debtor)
%   w_G_ss = -1.60 (government — net debtor)
%   w_H_ss = -(w_F_ss + w_G_ss + w_N_ss) = 4.32 (households — net creditor)
%   w_N_ss = 0.08 (NPISH — small net creditor)

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

T_sim = 200;        % quarters for long-run convergence
fprintf('=== Phase N: sectoral asset accounts validation ===\n');
fprintf('Sim length: %d quarters\n\n', T_sim);

%% Compile model
fprintf('Compiling au_pac.mod...\n');
dynare au_pac noclearall nograph;

%% Locate sector wealth variables in DR ordering
endo_names = cellstr(M_.endo_names);
target_vars = {'w_F', 'w_G', 'w_H', 'w_N'};
target_lbls = {'Firms (w_F)', 'Government (w_G)', 'Households (w_H)', 'NPISH (w_N)'};
idx = zeros(length(target_vars), 1);
for k = 1:length(target_vars)
    f = find(strcmp(endo_names, target_vars{k}), 1);
    if isempty(f)
        warning('%s not in model', target_vars{k});
        idx(k) = NaN;
    else
        idx(k) = f;
    end
end

% SS values
ss_vals = oo_.dr.ys(idx);

%% Scenario A: convergence from off-SS initial state
% Perturb each sector's wealth by +20% of its SS value and simulate forward
% with zero shocks. Should monotonically converge back to SS.
fprintf('\n--- Scenario A: off-SS initial state, zero shocks ---\n');
y_dev = zeros(M_.endo_nbr, 1);
for k = 1:length(idx)
    if ~isnan(idx(k))
        y_dev(idx(k)) = 0.20 * ss_vals(k);   % 20% perturbation
    end
end

% Iterate decision rule forward
gx = oo_.dr.ghx;
order_var = oo_.dr.order_var;
state_var = oo_.dr.state_var;
y_dev_dr = y_dev(order_var);

Y_conv = zeros(M_.endo_nbr, T_sim);
y_prev = y_dev_dr;
for t = 1:T_sim
    y_state = y_prev(state_var);
    y_curr = gx * y_state;
    y_full = zeros(M_.endo_nbr, 1);
    for j = 1:M_.endo_nbr
        y_full(order_var(j)) = y_curr(j);
    end
    Y_conv(:, t) = oo_.dr.ys + y_full;
    y_prev = y_curr;
end

% Plot
fig1 = figure('Position', [50 50 1100 700], 'Visible', 'off');
for k = 1:length(target_vars)
    subplot(2, 2, k);
    if isnan(idx(k)), continue; end
    plot(1:T_sim, Y_conv(idx(k), :), 'b-', 'LineWidth', 1.6); hold on;
    plot([1 T_sim], [ss_vals(k) ss_vals(k)], 'r--', 'LineWidth', 1);
    title(sprintf('%s (SS = %.3f)', target_lbls{k}, ss_vals(k)), 'FontSize', 11);
    xlabel('Quarters'); ylabel('Wealth-to-GDP (quarterly GDP units)');
    grid on;
    % Report convergence half-life
    init_dev = Y_conv(idx(k), 1) - ss_vals(k);
    half_thresh = ss_vals(k) + 0.5 * init_dev;
    cross = find(sign(init_dev) * (Y_conv(idx(k), :) - half_thresh) <= 0, 1);
    if ~isempty(cross)
        fprintf('  %s: half-life = %d quarters (init dev = %+.3f)\n', ...
                target_lbls{k}, cross, init_dev);
    else
        fprintf('  %s: didn''t converge to half within %d quarters\n', target_lbls{k}, T_sim);
    end
end
sgtitle('Phase N: sectoral wealth-to-GDP convergence from off-SS (+20%) initial state', ...
    'FontSize', 12, 'FontWeight', 'bold');
print(fig1, 'sectoral_validation', '-dpng', '-r200');
close(fig1);
fprintf('  Saved: sectoral_validation.png\n');

%% Scenario B: 100bp persistent term-premium stress test
fprintf('\n--- Scenario B: 100bp persistent term-premium shock ---\n');
% Use stoch_simul IRFs (already in oo_.irfs after dynare run) but eps_tp
% needs scaling. stderr_eps_tp = 0.05 (model calibration); target = 0.25
% (100bp annualised).
shock = 'eps_tp';
scale = 0.25 / 0.05;
T_irf = 40;

fig2 = figure('Position', [50 50 1100 700], 'Visible', 'off');
for k = 1:length(target_vars)
    subplot(2, 2, k);
    field = [target_vars{k} '_' shock];
    if isfield(oo_.irfs, field)
        irf = oo_.irfs.(field) * scale;
        T_avail = min(T_irf, length(irf));
        plot(1:T_avail, irf(1:T_avail), 'b-', 'LineWidth', 1.6); hold on;
        plot([1 T_avail], [0 0], 'r--', 'LineWidth', 0.5);
        title(sprintf('Δ%s (100bp term-prem shock)', target_lbls{k}), 'FontSize', 11);
        xlabel('Quarters'); ylabel('Deviation from SS');
        grid on;
        fprintf('  Δ%s peak = %+.4f at Q%d (vs SS %+.3f)\n', ...
                target_lbls{k}, max(abs(irf(1:T_avail))) * sign(irf(find(abs(irf(1:T_avail))==max(abs(irf(1:T_avail))), 1))), ...
                find(abs(irf(1:T_avail))==max(abs(irf(1:T_avail))), 1), ss_vals(k));
    end
end
sgtitle('Phase N stress test: 100bp permanent term-premium shock on sectoral wealth', ...
    'FontSize', 12, 'FontWeight', 'bold');
print(fig2, 'sectoral_validation_stress', '-dpng', '-r200');
close(fig2);
fprintf('  Saved: sectoral_validation_stress.png\n');

%% Diagnostic summary
fid = fopen('sectoral_validation_log.txt', 'w');
fprintf(fid, 'Phase N sectoral asset accounts validation\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));
fprintf(fid, 'Calibrated SS values:\n');
for k = 1:length(target_vars)
    fprintf(fid, '  %s = %+.4f\n', target_vars{k}, ss_vals(k));
end
fprintf(fid, '\nScenario A: off-SS (+20%%) convergence half-lives (quarters)\n');
for k = 1:length(target_vars)
    if isnan(idx(k)), continue; end
    init_dev = Y_conv(idx(k), 1) - ss_vals(k);
    half_thresh = ss_vals(k) + 0.5 * init_dev;
    cross = find(sign(init_dev) * (Y_conv(idx(k), :) - half_thresh) <= 0, 1);
    if ~isempty(cross)
        fprintf(fid, '  %s: %d quarters\n', target_vars{k}, cross);
    else
        fprintf(fid, '  %s: > %d quarters\n', target_vars{k}, T_sim);
    end
end
fclose(fid);
fprintf('\n=== Phase N validation complete ===\n');
