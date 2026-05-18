%% irf_three_regimes.m — IRFs under 3 expectation regimes
%
% Runs all 3 model versions and compares IRFs to monetary policy shock.
% ** 100bp annualized monetary tightening (0.25 quarterly pp) **
% Uses linear scaling (exact at order=1): IRF * (0.25 / stderr_eps_i)
% Output: tables for documentation + comparison plot.

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

%% Shock scaling: 100bp annualized = 0.25 quarterly pp
stderr_eps_i = 0.1105;   % Phase G posterior mean
target_shock = 0.25;
scale_factor = target_shock / stderr_eps_i;
fprintf('  Shock: 100bp annualized = %.3f qpp, scale = %.3f x (1 s.d.)\n\n', ...
    target_shock, scale_factor);

fprintf('================================================================\n');
fprintf('  IRF Comparison: 3 Expectation Regimes\n');
fprintf('================================================================\n\n');

%% Run VAR-based model (all backward)
fprintf('--- [1/3] VAR-based (au_pac_var.mod) ---\n');
dynare au_pac_var noclearall nograph;
irfs_var = oo_.irfs;
nfwd_var = sum(abs(oo_.dr.eigval) > 1);
fprintf('  Forward-looking vars: %d\n\n', nfwd_var);
clear M_ oo_ options_

%% Run Hybrid model (financial forward, PAC backward)
fprintf('--- [2/3] Hybrid (au_pac.mod) ---\n');
dynare au_pac noclearall nograph;
irfs_hyb = oo_.irfs;
nfwd_hyb = sum(abs(oo_.dr.eigval) > 1);
fprintf('  Forward-looking vars: %d\n\n', nfwd_hyb);
clear M_ oo_ options_

%% Run Full MCE model (all forward)
fprintf('--- [3/3] Full MCE (au_pac_mce.mod) ---\n');
dynare au_pac_mce noclearall nograph;
irfs_mce = oo_.irfs;
nfwd_mce = sum(abs(oo_.dr.eigval) > 1);
fprintf('  Forward-looking vars: %d\n\n', nfwd_mce);

%% Extract and compare IRFs
shock = 'eps_i';
vars = {'yhat_au', 'pi_au', 'piQ', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', ...
        'pi_w', 's_gap', 'i_10y', 'i_au'};
labels = {'Output gap', 'CPI inflation', 'VA price', 'Consumption', ...
          'Business inv.', 'Housing inv.', 'Employment', ...
          'Wage inflation', 'Exchange rate', '10Y yield', 'Policy rate'};

fprintf('================================================================\n');
fprintf('  Peak IRFs to 100bp annualized monetary tightening\n');
fprintf('================================================================\n');
fprintf('  %-18s  %10s  %10s  %10s\n', 'Variable', 'VAR-based', 'Hybrid', 'Full MCE');
fprintf('  %-18s  %10s  %10s  %10s\n', repmat('-',1,18), repmat('-',1,10), repmat('-',1,10), repmat('-',1,10));

peak_data = zeros(length(vars), 3);
peakq_data = zeros(length(vars), 3);

for j = 1:length(vars)
    f = [vars{j} '_' shock];
    peaks = [0 0 0];
    peakqs = [0 0 0];

    sources = {irfs_var, irfs_hyb, irfs_mce};
    for k = 1:3
        if isfield(sources{k}, f)
            irf_j = sources{k}.(f) * scale_factor;
            [pv, pq] = max(abs(irf_j));
            peaks(k) = sign(irf_j(pq)) * pv;
            peakqs(k) = pq;
        end
    end

    peak_data(j,:) = peaks;
    peakq_data(j,:) = peakqs;

    fprintf('  %-18s  %7.5f(Q%d) %7.5f(Q%d) %7.5f(Q%d)\n', ...
        labels{j}, peaks(1), peakqs(1), peaks(2), peakqs(2), peaks(3), peakqs(3));
end

%% Detailed paths for key variables
fprintf('\n================================================================\n');
fprintf('  Detailed IRF paths (Quarters 1-20)\n');
fprintf('================================================================\n');

key = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'piQ', 'pi_w', 'i_10y', 's_gap'};
klab = {'Output gap', 'Consumption', 'Business inv.', 'Housing inv.', ...
        'VA price', 'Wage inflation', '10Y yield', 'Exchange rate'};

for j = 1:length(key)
    f = [key{j} '_' shock];
    fprintf('\n  %s:\n', klab{j});
    fprintf('  %4s  %11s  %11s  %11s\n', 'Q', 'VAR', 'Hybrid', 'MCE');

    for q = [1 2 4 8 12 16 20]
        vals = [0 0 0];
        sources = {irfs_var, irfs_hyb, irfs_mce};
        for k = 1:3
            if isfield(sources{k}, f) && q <= length(sources{k}.(f))
                vals(k) = sources{k}.(f)(q) * scale_factor;
            end
        end
        fprintf('  %4d  %11.7f  %11.7f  %11.7f\n', q, vals(1), vals(2), vals(3));
    end
end

%% Summary statistics
fprintf('\n================================================================\n');
fprintf('  Summary\n');
fprintf('================================================================\n');
fprintf('  Forward-looking eigenvalues: VAR=%d, Hybrid=%d, MCE=%d\n', nfwd_var, nfwd_hyb, nfwd_mce);

% Compute ratios for key variables
key_idx = [1 4 5 6 3]; % yhat_au, dln_c, dln_ib, dln_ih, piQ
fprintf('\n  Ratio MCE/Hybrid (peak |response|):\n');
for j = key_idx
    if abs(peak_data(j,2)) > 1e-12
        r = abs(peak_data(j,3)) / abs(peak_data(j,2));
        fprintf('    %-18s: %.3f', labels{j}, r);
        if r < 0.95
            fprintf('  (MCE dampens)\n');
        elseif r > 1.05
            fprintf('  (MCE amplifies)\n');
        else
            fprintf('  (~same)\n');
        end
    end
end

fprintf('\n  Ratio Hybrid/VAR (peak |response|):\n');
for j = key_idx
    if abs(peak_data(j,1)) > 1e-12
        r = abs(peak_data(j,2)) / abs(peak_data(j,1));
        fprintf('    %-18s: %.3f', labels{j}, r);
        if r > 1.05
            fprintf('  (Hybrid amplifies)\n');
        elseif r < 0.95
            fprintf('  (Hybrid dampens)\n');
        else
            fprintf('  (~same)\n');
        end
    end
end

%% Plot comparison (paper Figure 6.2.2 style)
fig = figure('Position', [30 30 1500 1000], 'Visible', 'off');

plot_vars = {'yhat_au', 'piQ', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', ...
             'pi_w', 's_gap', 'i_10y'};
plot_labs = {'Output gap', 'VA price inflation', 'Consumption', ...
             'Business inv.', 'Housing inv.', 'Employment', ...
             'Wage inflation', 'Exchange rate', '10Y yield'};

for j = 1:length(plot_vars)
    subplot(3, 3, j);
    f = [plot_vars{j} '_' shock];

    sources = {irfs_var, irfs_hyb, irfs_mce};
    colors = {'b.-', 'r-', 'g--'};

    for k = 1:3
        if isfield(sources{k}, f)
            irf_j = sources{k}.(f) * scale_factor;
            T = length(irf_j);
            plot(1:T, irf_j, colors{k}, 'LineWidth', 1.2 + 0.3*(k-1)); hold on;
        end
    end
    plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.5);

    title(plot_labs{j}, 'FontSize', 10);
    xlabel('Quarters');
    ylabel('% dev.');
    if j == 1
        legend('VAR-based', 'Hybrid', 'Full MCE', 'Location', 'best', 'FontSize', 7);
    end
    grid on;
end

sgtitle('100bp Monetary Tightening: 3 Expectation Regimes (FR-BDF Fig. 6.2.2)', 'FontSize', 13);
saveas(fig, 'irf_three_regimes.png');
fprintf('\n  Saved: irf_three_regimes.png\n');
close(fig);

fprintf('\n=== 3-regime comparison complete ===\n');
