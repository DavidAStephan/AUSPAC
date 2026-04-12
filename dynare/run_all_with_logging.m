%% run_all_with_logging.m
% Runs all scripts with output captured to log files using fopen/fprintf.
% The diary approach fails because dynare disrupts it.
% Instead: run dynare FIRST, then run each script that reads oo_/M_,
% capturing output via evalc().

cd('c:\Users\david\french_model\dynare');
addpath('C:\dynare\6.5\matlab');

%% ====================================================================
%  PHASE 1: Run all three Dynare models, save IRF structs to .mat files
%  ====================================================================
fprintf('=== PHASE 1: Running Dynare models ===\n');

% --- Regime 1: VAR-based ---
fprintf('Running au_pac_var...\n');
dynare au_pac_var noclearall nograph;
irfs_var = oo_.irfs;
params_var = M_.params;
save('saved_irfs_var.mat', 'irfs_var');
fprintf('  Saved irfs_var.\n');

% Clear dynare globals for next run
clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;

% --- Regime 2: Hybrid ---
fprintf('Running au_pac...\n');
dynare au_pac noclearall nograph;
irfs_hybrid = oo_.irfs;
save('saved_irfs_hybrid.mat', 'irfs_hybrid');
fprintf('  Saved irfs_hybrid.\n');

% Keep M_ and oo_ from au_pac for later scripts
M_saved = M_;
oo_saved = oo_;

clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;

% --- Regime 3: Full MCE ---
fprintf('Running au_pac_mce...\n');
dynare au_pac_mce noclearall nograph;
irfs_mce = oo_.irfs;
save('saved_irfs_mce.mat', 'irfs_mce');
fprintf('  Saved irfs_mce.\n');

% Restore au_pac workspace for scripts 2-4
clear M_ oo_ options_;
M_ = M_saved;
oo_ = oo_saved;
oo_.irfs = irfs_hybrid;  % ensure hybrid IRFs available

fprintf('=== PHASE 1 COMPLETE ===\n\n');

%% ====================================================================
%  PHASE 2: Generate three-regime comparison (from saved .mat files)
%  ====================================================================
fprintf('=== PHASE 2: Three-regime IRF tables ===\n');

load('saved_irfs_var.mat');
load('saved_irfs_hybrid.mat');
load('saved_irfs_mce.mat');

all_irfs = {irfs_var, irfs_hybrid, irfs_mce};
shock_name = 'eps_i';

% --- Write comparison table to file ---
fid = fopen('log_three_regime_tables.txt', 'w');
fprintf(fid, '=== THREE-REGIME IRF COMPARISON TABLES ===\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

% Table 1: Output gap and VA price inflation
fprintf(fid, '#### Table 6.2.1: Output gap and VA price inflation (annualized)\n\n');
fprintf(fid, '| Quarter | Output (VAR) | Output (Hyb) | Output (MCE) | piQ ann. (VAR) | piQ ann. (Hyb) | piQ ann. (MCE) |\n');
fprintf(fid, '|---------|-------------|-------------|-------------|---------------|---------------|---------------|\n');

quarters_table = [1, 2, 4, 8, 12, 20, 40];
for q = quarters_table
    vals = zeros(1, 6);
    for r = 1:3
        irf_y = all_irfs{r}.(['yhat_au_' shock_name]);
        irf_p = all_irfs{r}.(['piQ_' shock_name]);
        if q <= length(irf_y)
            vals(r) = irf_y(q);
            vals(r+3) = irf_p(q) * 4;  % annualized
        end
    end
    fprintf(fid, '| Q%d | %.6f | %.6f | %.6f | %.6f | %.6f | %.6f |\n', q, vals);
end

% Table 2: Peak responses
fprintf(fid, '\n#### Table 6.2.2: Peak IRF comparison\n\n');
fprintf(fid, '| Variable | Peak (VAR) | Qtr | Peak (Hyb) | Qtr | Peak (MCE) | Qtr |\n');
fprintf(fid, '|----------|-----------|-----|-----------|-----|-----------|-----|\n');

vars_all = {'yhat_au', 'pi_au', 'i_au', 'piQ', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'pi_w', 's_gap', 'i_10y'};
var_labels = {'Output gap', 'CPI inflation', 'Policy rate', 'VA price infl.', 'Consumption', ...
              'Business inv.', 'Housing inv.', 'Employment', 'Wage inflation', 'Exchange rate', '10Y yield'};

for v = 1:length(vars_all)
    field = [vars_all{v} '_' shock_name];
    fprintf(fid, '| %s ', var_labels{v});
    for r = 1:3
        if isfield(all_irfs{r}, field)
            irf_data = all_irfs{r}.(field);
            [peak_val, peak_q] = max(abs(irf_data));
            peak_sign = sign(irf_data(peak_q));
            fprintf(fid, '| %+.6f | Q%d ', peak_sign*peak_val, peak_q);
        else
            fprintf(fid, '| N/A | — ');
        end
    end
    fprintf(fid, '|\n');
end

fclose(fid);
fprintf('  Saved: log_three_regime_tables.txt\n');

% --- Generate plots (reuse from generate_three_regime_irfs.m logic) ---
T_plot = 40;
regime_names  = {'VAR-based', 'Hybrid', 'Full MCE'};
regime_colors = {[0 0.447 0.741], [0 0 0], [0.850 0.325 0.098]};
regime_styles = {'--', '-', '-.'};
regime_widths = [1.5, 2.0, 1.5];

fig1 = figure('Position', [100 100 1000 400], 'Color', 'w', 'Visible', 'off');
panel_vars = {'yhat_au', 'piQ'};
panel_titles = {'Output', 'VA price inflation'};
panel_ylabels = {'(deviation from baseline, in %)', '(annualized, deviation from baseline, in pp)'};
annualize_flag = [0, 1];

for p = 1:2
    subplot(1, 2, p);
    hold on;
    for r = 1:3
        field = [panel_vars{p} '_' shock_name];
        irf_data = all_irfs{r}.(field);
        T_use = min(T_plot, length(irf_data));
        y = irf_data(1:T_use);
        if annualize_flag(p), y = y * 4; end
        plot(1:T_use, y, 'Color', regime_colors{r}, 'LineStyle', regime_styles{r}, ...
            'LineWidth', regime_widths(r));
    end
    plot([1 T_plot], [0 0], 'k:', 'LineWidth', 0.5);
    xlabel('Quarters'); title({panel_titles{p}; panel_ylabels{p}});
    if p == 1, legend(regime_names, 'Location', 'best', 'FontSize', 9); end
    xlim([1 T_plot]); grid on;
    hold off;
end
sgtitle('Monetary policy responses under different types of expectations', 'FontSize', 13, 'FontWeight', 'bold');
print(fig1, 'three_regime_monetary_irf', '-dpng', '-r300');
close(fig1);
fprintf('  Saved: three_regime_monetary_irf.png\n');

fprintf('=== PHASE 2 COMPLETE ===\n\n');

%% ====================================================================
%  PHASE 3: h-vector extraction (au_pac already loaded via M_saved)
%  ====================================================================
fprintf('=== PHASE 3: h-vector extraction ===\n');

% Need to re-run au_pac to get oo_.pac populated
clear M_ oo_ options_;
dynare au_pac noclearall nograph;

fid = fopen('log_hvector_tables.txt', 'w');
fprintf(fid, '=== PAC h-VECTOR TABLES ===\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

pac_names  = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
pac_labels = {'VA Price (piQ)', 'Consumption (dln_c)', 'Business Inv. (dln_ib)', ...
              'Household Inv. (dln_ih)', 'Employment (dln_n)'};

% Summary table
fprintf(fid, '### Summary\n\n');
fprintf(fid, '| PAC equation | h_0 sum | h_1 sum | Total |\n');
fprintf(fid, '|---|---|---|---|\n');

for p = 1:length(pac_names)
    pname = pac_names{p};
    if isfield(oo_.pac, pname)
        pac_info = oo_.pac.(pname);
        h0_sum = 0; h1_sum = 0;
        if isfield(pac_info, 'h_v_0'), h0_sum = sum(pac_info.h_v_0); end
        if isfield(pac_info, 'h_v_1'), h1_sum = sum(pac_info.h_v_1); end
        fprintf(fid, '| %s | %.6f | %.6f | %.6f |\n', pac_labels{p}, h0_sum, h1_sum, h0_sum+h1_sum);
    else
        fprintf(fid, '| %s | NOT FOUND | — | — |\n', pac_labels{p});
    end
end

% Detailed per-equation
for p = 1:length(pac_names)
    pname = pac_names{p};
    fprintf(fid, '\n### %s\n\n', pac_labels{p});
    if ~isfield(oo_.pac, pname)
        fprintf(fid, 'NOT FOUND\n');
        continue;
    end
    pac_info = oo_.pac.(pname);

    if isfield(pac_info, 'h_v_0')
        h0 = pac_info.h_v_0;
        fprintf(fid, '**h_v_0** (%d elements): [', length(h0));
        fprintf(fid, '%.6f ', h0);
        fprintf(fid, ']\nSum: %.6f\n\n', sum(h0));
    end
    if isfield(pac_info, 'h_v_1')
        h1 = pac_info.h_v_1;
        fprintf(fid, '**h_v_1** (%d elements): [', length(h1));
        fprintf(fid, '%.6f ', h1);
        fprintf(fid, ']\nSum: %.6f\n\n', sum(h1));
    end
end

fclose(fid);
fprintf('  Saved: log_hvector_tables.txt\n');
fprintf('=== PHASE 3 COMPLETE ===\n\n');

%% ====================================================================
%  PHASE 4: Estimation tables
%  ====================================================================
fprintf('=== PHASE 4: Estimation tables ===\n');

get_param = @(name) M_.params(strcmp(cellstr(M_.param_names), name));

fid = fopen('log_estimation_tables.txt', 'w');
fprintf(fid, '=== PARAMETER VALUES FROM M_.params ===\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

% Print all key parameters organized by block
blocks = {
    'E-SAT', {'delta','lambda_q','sigma_q','lambda_i','alpha_i','beta_i','lambda_pi','kappa_pi','lambda_q_us','lambda_pi_us','kappa_pi_us','i_ss','pi_ss_au','pi_ss_us'};
    'VA Price PAC', {'b0_pQ','b1_pQ','b2_pQ','omega_pQ','rho_pQ_star','gamma_ulc','gamma_uck'};
    'Wage Phillips', {'lambda_w','gamma_w','kappa_w','beta_w','okun_coeff','rho_u_gap'};
    'Employment PAC', {'b0_n','b1_n','b2_n','b3_n','b4_n','omega_n','b5_n','rho_n_star'};
    'Consumption PAC', {'b0_c','b1_c','omega_c','b2_c','b3_c','rho_c_star','kappa_inc','beta_c','alpha_c_r'};
    'Business Inv PAC', {'b0_ib','b1_ib','b2_ib','omega_ib','b3_ib','b4_ib','rho_ib_star','kappa_ib_y','sigma_ces','delta_k'};
    'Household Inv PAC', {'b0_ih','b1_ih','b2_ih','omega_ih','b3_ih','b4_ih','rho_ih_star','kappa_mort','kappa_ph','kappa_ih_inc'};
    'Financial', {'kappa_10','tp_ss','rho_tp','rho_s','alpha_s','spread_ss','spread_lh','w_COE','w_LB_firms','w_BBB','s_COE_ss','s_LB_firms_ss','s_BBB_ss','rho_COE','rho_LB_firms','rho_BBB'};
    'Trade', {'b0_x','b1_x','b2_x','b3_x','b4_x','b0_m','b1_m','b2_m','b3_m'};
    'Deflators', {'rho_pc','alpha_pc','beta_pc_m','gamma_oil','rho_pib','alpha_pib','beta_pib_m','rho_pih','alpha_pih','beta_pih_m','rho_px','alpha_px','beta_px','alpha_pcom','rho_pm','alpha_pm','beta_pm','beta_pm_com','rho_pg','alpha_pg'};
    'GDP Weights', {'w_c','w_ib','w_ih','w_g','w_x','w_m'};
    'IAD Weights', {'w_iad_c','w_iad_ib','w_iad_ih','w_iad_g','w_iad_x'};
};

for b = 1:size(blocks, 1)
    block_name = blocks{b, 1};
    param_list = blocks{b, 2};
    fprintf(fid, '\n## %s\n\n', block_name);
    fprintf(fid, '| Parameter | Value |\n');
    fprintf(fid, '|-----------|-------|\n');
    for j = 1:length(param_list)
        pname = param_list{j};
        idx = find(strcmp(cellstr(M_.param_names), pname));
        if ~isempty(idx)
            fprintf(fid, '| %s | %.6f |\n', pname, M_.params(idx));
        else
            fprintf(fid, '| %s | NOT FOUND |\n', pname);
        end
    end
end

fclose(fid);
fprintf('  Saved: log_estimation_tables.txt\n');
fprintf('=== PHASE 4 COMPLETE ===\n\n');

%% ====================================================================
%  DONE
%  ====================================================================
fid = fopen('log_run_complete.txt', 'w');
fprintf(fid, 'ALL SCRIPTS COMPLETED SUCCESSFULLY\n');
fprintf(fid, 'Timestamp: %s\n\n', datestr(now));
fprintf(fid, 'Files generated:\n');
fprintf(fid, '  three_regime_monetary_irf.png\n');
fprintf(fid, '  log_three_regime_tables.txt\n');
fprintf(fid, '  log_hvector_tables.txt\n');
fprintf(fid, '  log_estimation_tables.txt\n');
fprintf(fid, '  contrib_piQ.png (from prior run)\n');
fprintf(fid, '  contrib_c.png (from prior run)\n');
fprintf(fid, '  contrib_ib.png (from prior run)\n');
fprintf(fid, '  contrib_ih.png (from prior run)\n');
fprintf(fid, '  contrib_n.png (from prior run)\n');
fclose(fid);
fprintf('=== ALL COMPLETE. Check log_run_complete.txt ===\n');
