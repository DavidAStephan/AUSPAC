% run_all_l2_ols.m — re-run all 5 Phase L2 iterative-OLS PAC block estimations
% against the updated data pipeline (K_market, new trend efficiency).
% Run from: cd ~/Documents/AUSPAC/data && matlab -batch run_all_l2_ols

addpath(fullfile(pwd, 'pac_blocks'));
addpath(fullfile(pwd, 'pac_helpers'));

fprintf('\n========== VA-PRICE (Eq 16) ==========\n');
run(fullfile('pac_blocks', 'estimate_pac_va_price.m'));

fprintf('\n========== EMPLOYMENT (Eq 30) ==========\n');
run(fullfile('pac_blocks', 'estimate_pac_employment.m'));

fprintf('\n========== CONSUMPTION (Eq 35) ==========\n');
run(fullfile('pac_blocks', 'estimate_pac_consumption.m'));

fprintf('\n========== HOUSING INV (Eq 37) ==========\n');
run(fullfile('pac_blocks', 'estimate_pac_housing_inv.m'));

fprintf('\n========== BUSINESS INV (Eq 46) ==========\n');
run(fullfile('pac_blocks', 'estimate_pac_business_inv.m'));

fprintf('\n========== ALL L2 OLS BLOCKS DONE ==========\n');
