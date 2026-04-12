%% run_estimation_tables_v2.m
% Extract all parameter values to log file.
cd('c:\Users\david\french_model\dynare');
addpath('C:\dynare\6.5\matlab');

if ~exist('M_', 'var')
    dynare au_pac noclearall nograph;
end

get_p = @(name) M_.params(strcmp(cellstr(M_.param_names), name));

fid = fopen('log_estimation_tables_v2.txt', 'w');
fprintf(fid, '=== ALL PARAMETER VALUES ===\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

blocks = {
    'E-SAT', {'delta','lambda_q','sigma_q','lambda_i','alpha_i','beta_i','lambda_pi','kappa_pi','lambda_q_us','lambda_pi_us','kappa_pi_us','i_ss','pi_ss_au','pi_ss_us'};
    'VA Price PAC', {'b0_pQ','b1_pQ','b2_pQ','omega_pQ','rho_pQ_star','gamma_ulc','gamma_uck'};
    'Wage Phillips', {'lambda_w','gamma_w','kappa_w','beta_w','okun_coeff','rho_u_gap'};
    'Employment PAC', {'b0_n','b1_n','b2_n','b3_n','b4_n','omega_n','b5_n','rho_n_star'};
    'Consumption PAC', {'b0_c','b1_c','omega_c','b2_c','b3_c','rho_c_star','kappa_inc','beta_c','alpha_c_r'};
    'Business Inv PAC', {'b0_ib','b1_ib','b2_ib','omega_ib','b3_ib','b4_ib','rho_ib_star','kappa_ib_y','sigma_ces','delta_k'};
    'Household Inv PAC', {'b0_ih','b1_ih','b2_ih','omega_ih','b3_ih','b4_ih','rho_ih_star','kappa_mort','kappa_ph','kappa_ih_inc'};
    'Financial', {'kappa_10','tp_ss','rho_tp','rho_s','alpha_s','spread_ss','spread_lh'};
    'WACC', {'w_COE','w_LB_firms','w_BBB','s_COE_ss','s_LB_firms_ss','s_BBB_ss','rho_COE','rho_LB_firms','rho_BBB'};
    'Trade', {'b0_x','b1_x','b2_x','b3_x','b4_x','b0_m','b1_m','b2_m','b3_m'};
    'Deflators', {'rho_pc','alpha_pc','beta_pc_m','gamma_oil','rho_pib','alpha_pib','beta_pib_m','rho_pih','alpha_pih','beta_pih_m','rho_px','alpha_px','beta_px','alpha_pcom','rho_pm','alpha_pm','beta_pm','beta_pm_com','rho_pg','alpha_pg'};
    'GDP Weights', {'w_c','w_ib','w_ih','w_g','w_x','w_m'};
    'IAD Weights', {'w_iad_c','w_iad_ib','w_iad_ih','w_iad_g','w_iad_x'};
    'Other', {'lambda_dom','beta_pac','rho_pcom','alpha_k','rho_tfp','sigma_ces','rho_lh','rho_ph','alpha_ph_y','alpha_ph_r'};
};

for b = 1:size(blocks, 1)
    fprintf(fid, '\n## %s\n\n', blocks{b, 1});
    fprintf(fid, '| Parameter | Value |\n');
    fprintf(fid, '|-----------|-------|\n');
    plist = blocks{b, 2};
    for j = 1:length(plist)
        idx = find(strcmp(cellstr(M_.param_names), plist{j}));
        if ~isempty(idx)
            fprintf(fid, '| %s | %.6f |\n', plist{j}, M_.params(idx));
        else
            fprintf(fid, '| %s | NOT FOUND |\n', plist{j});
        end
    end
end

fclose(fid);
fprintf('Saved: log_estimation_tables_v2.txt\n');
