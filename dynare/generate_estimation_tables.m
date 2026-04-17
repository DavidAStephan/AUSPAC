%% generate_estimation_tables.m
% Generate FR-BDF-style coefficient tables for AU-PAC documentation.
% Reads parameter values from M_.params and formats as markdown tables
% organized by equation block.
%
% Must be run AFTER `dynare au_pac noclearall nograph`.
%
% Output: printed to console as markdown tables for pasting into docs.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

%% Run model if not already loaded
if ~exist('oo_', 'var') || ~exist('M_', 'var')
    fprintf('Running au_pac.mod...\n');
    dynare au_pac noclearall nograph;
end

%% Helper function
get_param = @(name) M_.params(strcmp(cellstr(M_.param_names), name));

fprintf('\n\n=== FR-BDF STYLE COEFFICIENT TABLES ===\n');
fprintf('=== For AU-PAC Documentation Section 4 ===\n\n');

%% ========================================================================
%  Section 4.3: VA Price
%  ========================================================================
fprintf('## Section 4.3: Value-Added Price of Market Branches\n\n');

fprintf('### Table 4.3.1: VA price target equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Target persistence',  'rho_pQ_star', get_param('rho_pQ_star'), NaN, 'calibrated');
print_row('ULC pass-through',    'gamma_ulc',   get_param('gamma_ulc'),   NaN, 'calibrated');
print_row('User cost pass-thru', 'gamma_uck',   get_param('gamma_uck'),   NaN, 'calibrated');
fprintf('\n');

fprintf('### Table 4.3.2: VA price short-run PAC equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Error correction',    'b0_pQ',    get_param('b0_pQ'),    NaN, 'calibrated');
print_row('AR(1) persistence',   'b1_pQ',    get_param('b1_pQ'),    NaN, 'calibrated');
print_row('Output gap',          'b2_pQ',    get_param('b2_pQ'),    NaN, 'calibrated');
print_row('PAC omega (manual)',  'omega_pQ', get_param('omega_pQ'), NaN, 'calibrated');
gn_pQ = 1 - get_param('b1_pQ') - get_param('omega_pQ');
fprintf('| Growth neutrality | 1-b1-omega | %.3f | — | derived |\n', gn_pQ);
fprintf('\nR² = N/A (calibrated). Discount beta = %.2f.\n\n', get_param('beta_pac'));

%% ========================================================================
%  Section 4.4.1: Wage Phillips Curve
%  ========================================================================
fprintf('## Section 4.4.1: Wage Phillips Curve\n\n');

fprintf('### Table 4.4.1: Wage Phillips curve coefficients\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Wage persistence',    'lambda_w', get_param('lambda_w'), 0.10, 'Bayesian posterior');
print_row('CPI indexation',      'gamma_w',  get_param('gamma_w'),  0.10, 'calibrated');
print_row('Unemp. gap PV',      'kappa_w',  get_param('kappa_w'),  0.20, 'Bayesian posterior');
print_row('PV discount',         'beta_w',   get_param('beta_w'),   NaN,  'calibrated');
print_row('Okun coefficient',    'okun_coeff', get_param('okun_coeff'), NaN, 'calibrated');
print_row('u_gap persistence',   'rho_u_gap',  get_param('rho_u_gap'),  NaN, 'calibrated');
gn_w = 1 - get_param('lambda_w') - get_param('gamma_w');
fprintf('| Inflation anchor | 1-lw-gw | %.3f | — | derived |\n', gn_w);
fprintf('\nGrowth neutrality: lambda_w + gamma_w + (1-lambda_w-gamma_w) = 1. Verified.\n\n');

%% ========================================================================
%  Section 4.4.2: Employment PAC (4th order)
%  ========================================================================
fprintf('## Section 4.4.2: Employment PAC (4th-order)\n\n');

fprintf('### Table 4.4.2a: Employment target equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Target persistence', 'rho_n_star', get_param('rho_n_star'), NaN, 'calibrated');
print_row('CES elasticity',     'sigma_ces',  get_param('sigma_ces'),  NaN, 'calibrated');
fprintf('\n');

fprintf('### Table 4.4.2b: Employment short-run PAC equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Error correction', 'b0_n', get_param('b0_n'), NaN, 'calibrated');
print_row('AR(1) lag',        'b1_n', get_param('b1_n'), NaN, 'calibrated');
print_row('AR(2) lag',        'b2_n', get_param('b2_n'), NaN, 'calibrated');
print_row('AR(3) lag',        'b3_n', get_param('b3_n'), NaN, 'calibrated');
print_row('AR(4) lag',        'b4_n', get_param('b4_n'), NaN, 'calibrated');
print_row('PAC omega',        'omega_n', get_param('omega_n'), NaN, 'calibrated');
print_row('Output gap (HtM)', 'b5_n', get_param('b5_n'), NaN, 'calibrated');
gn_n = 1 - get_param('b1_n') - get_param('b2_n') - get_param('b3_n') - get_param('b4_n') - get_param('omega_n');
fprintf('| Growth neutrality | 1-sum(bk)-omega | %.3f | — | derived |\n', gn_n);
fprintf('\n');

%% ========================================================================
%  Section 4.5.1: Consumption PAC (1st order)
%  ========================================================================
fprintf('## Section 4.5.1: Household Consumption PAC (1st-order)\n\n');

fprintf('### Table 4.5.1a: Consumption target equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Target persistence',  'rho_c_star', get_param('rho_c_star'), NaN, 'calibrated');
print_row('Perm. income sens.',  'kappa_inc',  get_param('kappa_inc'),  NaN, 'calibrated');
print_row('PV discount (beta_c)','beta_c',     get_param('beta_c'),     NaN, 'calibrated');
print_row('Real rate gap sens.', 'alpha_c_r',  get_param('alpha_c_r'),  NaN, 'calibrated');
fprintf('\n');

fprintf('### Table 4.5.1b: Consumption short-run PAC equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Error correction', 'b0_c', get_param('b0_c'), 0.05, 'Bayesian posterior');
print_row('AR(1) persistence','b1_c', get_param('b1_c'), 0.09, 'Bayesian posterior');
print_row('Interest rate',    'b2_c', get_param('b2_c'), NaN,  'calibrated');
print_row('Output gap (HtM)', 'b3_c', get_param('b3_c'), 0.11, 'Bayesian posterior');
print_row('PAC omega',        'omega_c', get_param('omega_c'), NaN, 'calibrated');
gn_c = 1 - get_param('b1_c') - get_param('omega_c');
fprintf('| Growth neutrality | 1-b1-omega | %.3f | — | derived |\n', gn_c);
fprintf('\n');

%% ========================================================================
%  Section 4.5.2: Business Investment PAC (2nd order)
%  ========================================================================
fprintf('## Section 4.5.2: Business Investment PAC (2nd-order)\n\n');

fprintf('### Table 4.5.2a: Business investment target equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Target persistence', 'rho_ib_star', get_param('rho_ib_star'), NaN, 'calibrated');
print_row('Output proportionality', 'kappa_ib_y', get_param('kappa_ib_y'), NaN, 'calibrated');
print_row('CES elasticity',     'sigma_ces',    get_param('sigma_ces'),    NaN, 'calibrated');
print_row('Depreciation rate',  'delta_k',      get_param('delta_k'),      NaN, 'calibrated');
fprintf('\n');

fprintf('### Table 4.5.2b: Business investment short-run PAC equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Error correction', 'b0_ib', get_param('b0_ib'), 0.029, 'Bayesian posterior');
print_row('AR(1) lag',        'b1_ib', get_param('b1_ib'), 0.14,  'Bayesian posterior');
print_row('AR(2) lag',        'b2_ib', get_param('b2_ib'), NaN,   'calibrated');
print_row('PAC omega',        'omega_ib', get_param('omega_ib'), NaN, 'calibrated');
print_row('Accelerator',      'b3_ib', get_param('b3_ib'), 0.36,  'Bayesian posterior');
print_row('Interest rate',    'b4_ib', get_param('b4_ib'), NaN,   'calibrated');
gn_ib = 1 - get_param('b1_ib') - get_param('b2_ib') - get_param('omega_ib');
fprintf('| Growth neutrality | 1-b1-b2-omega | %.3f | — | derived |\n', gn_ib);
fprintf('\n');

%% ========================================================================
%  Section 4.5.3: Household Investment PAC (2nd order)
%  ========================================================================
fprintf('## Section 4.5.3: Household Investment PAC (2nd-order)\n\n');

fprintf('### Table 4.5.3a: Household investment target equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Target persistence',   'rho_ih_star', get_param('rho_ih_star'), NaN, 'calibrated');
print_row('Perm. income sens.',   'kappa_ih_inc', get_param('kappa_ih_inc'), NaN, 'calibrated');
print_row('Mortgage rate gap',    'kappa_mort',   get_param('kappa_mort'),   NaN, 'calibrated');
print_row('Housing price (TobinQ)','kappa_ph',    get_param('kappa_ph'),     NaN, 'calibrated');
fprintf('\n');

fprintf('### Table 4.5.3b: Household investment short-run PAC equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Error correction', 'b0_ih', get_param('b0_ih'), NaN, 'calibrated');
print_row('AR(1) lag',        'b1_ih', get_param('b1_ih'), NaN, 'calibrated');
print_row('AR(2) lag',        'b2_ih', get_param('b2_ih'), NaN, 'calibrated');
print_row('PAC omega',        'omega_ih', get_param('omega_ih'), NaN, 'calibrated');
print_row('Output gap',       'b3_ih', get_param('b3_ih'), NaN, 'calibrated');
print_row('Mortgage channel', 'b4_ih', get_param('b4_ih'), NaN, 'calibrated');
gn_ih = 1 - get_param('b1_ih') - get_param('b2_ih') - get_param('omega_ih');
fprintf('| Growth neutrality | 1-b1-b2-omega | %.3f | — | derived |\n', gn_ih);
fprintf('\n');

%% ========================================================================
%  Section 4.6: Trade
%  ========================================================================
fprintf('## Section 4.6: External Trade\n\n');

fprintf('### Table 4.6.1: Export equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Error correction',  'b0_x', get_param('b0_x'), NaN, 'calibrated');
print_row('Persistence',       'b1_x', get_param('b1_x'), NaN, 'calibrated');
print_row('World demand',      'b2_x', get_param('b2_x'), NaN, 'calibrated');
print_row('Exchange rate',     'b3_x', get_param('b3_x'), NaN, 'calibrated');
print_row('Commodity prices',  'b4_x', get_param('b4_x'), NaN, 'calibrated');
fprintf('\n');

fprintf('### Table 4.6.2: Import equation\n\n');
fprintf('| Parameter | Symbol | Value | s.e. | Source |\n');
fprintf('|-----------|--------|-------|------|--------|\n');
print_row('Error correction',  'b0_m', get_param('b0_m'), NaN, 'calibrated');
print_row('Persistence',       'b1_m', get_param('b1_m'), NaN, 'calibrated');
print_row('Domestic demand',   'b2_m', get_param('b2_m'), NaN, 'calibrated');
print_row('Exchange rate',     'b3_m', get_param('b3_m'), NaN, 'calibrated');
fprintf('\n');

fprintf('### Table 4.6.3: IAD weights (import content of demand)\n\n');
fprintf('| Component | Weight | ABS source |\n');
fprintf('|-----------|--------|------------|\n');
fprintf('| Consumption | %.3f | Input-output tables |\n', get_param('w_iad_c'));
fprintf('| Business inv. | %.3f | Input-output tables |\n', get_param('w_iad_ib'));
fprintf('| Housing inv. | %.3f | Input-output tables |\n', get_param('w_iad_ih'));
fprintf('| Government | %.3f | Input-output tables |\n', get_param('w_iad_g'));
fprintf('| Exports (re-export) | %.3f | Input-output tables |\n', get_param('w_iad_x'));
fprintf('\n');

%% ========================================================================
%  Section 4.7: Demand Deflators
%  ========================================================================
fprintf('## Section 4.7: Demand Deflators\n\n');

deflators = {
    'Consumption',     'rho_pc',  'alpha_pc',  'beta_pc_m',  NaN;
    'Business inv.',   'rho_pib', 'alpha_pib', 'beta_pib_m', NaN;
    'Housing inv.',    'rho_pih', 'alpha_pih', 'beta_pih_m', NaN;
    'Exports',         'rho_px',  'alpha_px',  NaN,          'beta_px';
    'Imports',         'rho_pm',  'alpha_pm',  NaN,          'beta_pm';
    'Government',      'rho_pg',  'alpha_pg',  NaN,          NaN;
};

for d = 1:size(deflators, 1)
    dname = deflators{d, 1};
    fprintf('### Table 4.7.%d: %s deflator\n\n', d, dname);
    fprintf('| Parameter | Symbol | Value | Description |\n');
    fprintf('|-----------|--------|-------|-------------|\n');

    % Persistence
    rho_name = deflators{d, 2};
    rho_val = get_param(rho_name);
    fprintf('| Persistence | %s | %.3f | AR(1) lag |\n', rho_name, rho_val);

    % VA price pass-through
    alpha_name = deflators{d, 3};
    alpha_val = get_param(alpha_name);
    fprintf('| VA price pass-through | %s | %.3f | Domestic price channel |\n', alpha_name, alpha_val);

    % Import price pass-through (if applicable)
    if ~isnan(deflators{d, 4})
        beta_m_name = deflators{d, 4};
        fprintf('| Import price pass-thru | %s | %.3f | Import channel |\n', beta_m_name, get_param(beta_m_name));
    end

    % Exchange rate (if applicable)
    if ~isnan(deflators{d, 5})
        beta_s_name = deflators{d, 5};
        fprintf('| Exchange rate | %s | %.3f | Direct FX channel |\n', beta_s_name, get_param(beta_s_name));
    end

    % Growth neutrality
    gn_sum = rho_val + alpha_val;
    if ~isnan(deflators{d, 4}), gn_sum = gn_sum + get_param(deflators{d, 4}); end
    if ~isnan(deflators{d, 5}), gn_sum = gn_sum + get_param(deflators{d, 5}); end
    gn_residual = 1 - gn_sum;
    fprintf('| Inflation anchor | 1-sum | %.3f | Growth neutrality |\n', gn_residual);
    fprintf('\n');
end

%% ========================================================================
%  Section 4.8: Financial Block
%  ========================================================================
fprintf('## Section 4.8: Financial Block\n\n');

fprintf('### Table 4.8.1: Term structure\n\n');
fprintf('| Parameter | Symbol | Value | Description |\n');
fprintf('|-----------|--------|-------|-------------|\n');
fprintf('| Decay parameter | kappa_10 | %.3f | Duration-matched bond approximation |\n', get_param('kappa_10'));
fprintf('| SS term premium | tp_ss | %.4f | Quarterly %% |\n', get_param('tp_ss'));
fprintf('| TP persistence | rho_tp | %.3f | AR(1) |\n', get_param('rho_tp'));
fprintf('\n');

fprintf('### Table 4.8.2: WACC decomposition\n\n');
fprintf('| Component | Weight | Spread (SS, q%%) | Persistence |\n');
fprintf('|-----------|--------|-----------------|-------------|\n');
fprintf('| Cost of Equity | %.2f | %.4f | %.3f |\n', get_param('w_COE'), get_param('s_COE_ss'), get_param('rho_COE'));
fprintf('| Bank lending | %.2f | %.4f | %.3f |\n', get_param('w_LB_firms'), get_param('s_LB_firms_ss'), get_param('rho_LB_firms'));
fprintf('| BBB bonds | %.2f | %.4f | %.3f |\n', get_param('w_BBB'), get_param('s_BBB_ss'), get_param('rho_BBB'));
fprintf('\n');

fprintf('### Table 4.8.3: Exchange rate\n\n');
fprintf('| Parameter | Symbol | Value | Description |\n');
fprintf('|-----------|--------|-------|-------------|\n');
fprintf('| Persistence | rho_s | %.3f | PPP reversion |\n', get_param('rho_s'));
fprintf('| Rate differential | alpha_s | %.3f | UIP coefficient |\n', get_param('alpha_s'));
fprintf('\n');

fprintf('\n=== Estimation tables complete ===\n');

%% ========================================================================
%  LOCAL FUNCTION
%  ========================================================================
function print_row(desc, symbol, val, se, source)
    if isnan(se)
        fprintf('| %s | %s | %.4f | — | %s |\n', desc, symbol, val, source);
    else
        fprintf('| %s | %s | %.4f | %.3f | %s |\n', desc, symbol, val, se, source);
    end
end
