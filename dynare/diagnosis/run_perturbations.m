% run_perturbations.m — Step 3 of price-response diagnosis.
% Builds copies of au_pac_v2.mod with one parameter perturbed at a time,
% runs stoch_simul, saves the resulting IRFs into per-run .mat files.

clear; clc;
this_dir = fileparts(mfilename('fullpath'));
dyn_dir  = fileparts(this_dir);
cd(dyn_dir);
setup_dynare_path();
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'));

keep_vars = ['yhat_au pi_au pi_au_gap piQ pQ_level piQ_hat pi_c pi_m i_au i_gap u_gap '...
             'pv_u_gap pv_i_uip pv_r_lh_gap dln_pcom s_gap i_10y ln_Q dln_c dln_ib dln_ih dln_n pi_w'];

master = fileread('au_pac_v2.mod');
old_ss = regexp(master, 'stoch_simul\(.*?\)[^;]*;', 'match', 'once');
new_ss = sprintf('stoch_simul(order=1, irf=200, nograph, noprint) %s;', keep_vars);
master = strrep(master, old_ss, new_ss);

% Print baseline values for the parameters we will perturb
for nm = {'lambda_pi','kappa_pi','alpha_pc','beta_pc_m','gamma_oil', ...
          'lambda_w','kappa_w','gamma_w','gamma_ulc','b2_pQ','b0_pQ','b1_pQ', ...
          'lambda_i','beta_uip','rho_s','alpha_s'}
   pat = sprintf('\\<%s\\s*=\\s*([0-9eE+\\-.]+)', nm{1});
   m = regexp(master, pat, 'tokens');
   if isempty(m)
      fprintf('  baseline %-12s = NOT FOUND\n', nm{1});
   else
      % Print all occurrences (initial + posterior override)
      vals = strjoin(cellfun(@(c)c{1}, m, 'uni', 0), ', ');
      fprintf('  baseline %-12s = %s\n', nm{1}, vals);
   end
end

perturbs = {
   'baseline',       '',           'baseline posterior re-run';
   'alpha_pc_FR',    'alpha_pc = 0.71;',  'FR-BDF passthrough (0.17->0.71)';
   'kappa_pi_FR',    'kappa_pi = 0.08;',  'FR-BDF Phillips slope (0.037->0.08)';
   'kappa_pi_steep', 'kappa_pi = 0.20;',  'steep Phillips slope (->0.20)';
   'lambda_i_FR',    'lambda_i = 0.85;',  'FR-BDF Taylor smoothing (0.96->0.85)';
   'b2_pQ_hi',       'b2_pQ = 0.10;',     'VA-price output-gap slope (~0->0.10)';
   'kappa_w_steep',  'kappa_w = -0.30;',  'wage Phillips slope (-0.10->-0.30)';
   'gamma_ulc_hi',   'gamma_ulc = 0.50;', 'ULC pass-through (0.30->0.50)';
   'beta_uip_zero',  'beta_uip = 0.0;',   'kill forward-NPV UIP FX channel';
   'joint_FR',       sprintf('alpha_pc = 0.71;\nkappa_pi = 0.08;'), 'jointly alpha_pc + kappa_pi to FR-BDF';
};

shocks_anchor = 'shocks;';

results_dir = fullfile(this_dir, 'perturb_results');
if ~exist(results_dir, 'dir'); mkdir(results_dir); end
logfid = fopen(fullfile(results_dir, 'run.log'), 'w');

for k = 1:size(perturbs,1)
   tag = perturbs{k,1}; ovr_expr = perturbs{k,2}; desc = perturbs{k,3};
   fprintf(logfid, '\n=== %s : %s ===\n', tag, desc);
   fprintf('\n=== %s : %s ===\n', tag, desc);

   mod_txt = master;
   if isempty(ovr_expr)
      ovr = '';
   else
      ovr = sprintf('\n// PERTURB %s\n%s\n', tag, ovr_expr);
   end
   mod_txt = strrep(mod_txt, shocks_anchor, [ovr shocks_anchor]);

   mod_name = sprintf('au_pac_v2_perturb_%s', tag);
   mod_path = fullfile(dyn_dir, [mod_name '.mod']);
   fid = fopen(mod_path, 'w'); fprintf(fid, '%s', mod_txt); fclose(fid);

   t0 = tic;
   try
      % Reset Dynare globals so they don't leak between runs, but keep our state.
      evalin('base', 'clear M_ oo_ options_ dr_ estim_params_ bayestopt_; close all force;');
      evalin('base', sprintf('dynare %s noclearall', mod_name));
      oo_ = evalin('base', 'oo_');
      M_  = evalin('base', 'M_');
      out_mat = fullfile(results_dir, sprintf('irf_%s.mat', tag));
      save(out_mat, 'oo_', 'M_', '-v7');
      fprintf('  saved %s (%.1fs)\n', out_mat, toc(t0));
      fprintf(logfid, '  OK %.1fs -> %s\n', toc(t0), out_mat);
   catch ME
      fprintf('  FAILED: %s\n', ME.message);
      fprintf(logfid, '  FAILED: %s\n', ME.message);
   end
end
fclose(logfid);
fprintf('\nAll perturbations done. Results in %s\n', results_dir);
