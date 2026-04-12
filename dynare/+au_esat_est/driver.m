%
% Status : main Dynare file
%
% Warning : this file is generated automatically by Dynare
%           from model file (.mod)

tic0 = tic;
% Define global variables.
global M_ options_ oo_ estim_params_ bayestopt_ dataset_ dataset_info estimation_info
options_ = [];
M_.fname = 'au_esat_est';
M_.dynare_version = '6.5';
oo_.dynare_version = '6.5';
options_.dynare_version = '6.5';
%
% Some global variables initialization
%
global_initialization;
options_.nograph = true;
M_.exo_names = cell(5,1);
M_.exo_names_tex = cell(5,1);
M_.exo_names_long = cell(5,1);
M_.exo_names(1) = {'eps_q'};
M_.exo_names_tex(1) = {'eps\_q'};
M_.exo_names_long(1) = {'eps_q'};
M_.exo_names(2) = {'eps_i'};
M_.exo_names_tex(2) = {'eps\_i'};
M_.exo_names_long(2) = {'eps_i'};
M_.exo_names(3) = {'eps_pi'};
M_.exo_names_tex(3) = {'eps\_pi'};
M_.exo_names_long(3) = {'eps_pi'};
M_.exo_names(4) = {'eps_q_us'};
M_.exo_names_tex(4) = {'eps\_q\_us'};
M_.exo_names_long(4) = {'eps_q_us'};
M_.exo_names(5) = {'eps_pi_us'};
M_.exo_names_tex(5) = {'eps\_pi\_us'};
M_.exo_names_long(5) = {'eps_pi_us'};
M_.endo_names = cell(5,1);
M_.endo_names_tex = cell(5,1);
M_.endo_names_long = cell(5,1);
M_.endo_names(1) = {'yhat_au'};
M_.endo_names_tex(1) = {'yhat\_au'};
M_.endo_names_long(1) = {'yhat_au'};
M_.endo_names(2) = {'i_gap'};
M_.endo_names_tex(2) = {'i\_gap'};
M_.endo_names_long(2) = {'i_gap'};
M_.endo_names(3) = {'pi_au_gap'};
M_.endo_names_tex(3) = {'pi\_au\_gap'};
M_.endo_names_long(3) = {'pi_au_gap'};
M_.endo_names(4) = {'yhat_us'};
M_.endo_names_tex(4) = {'yhat\_us'};
M_.endo_names_long(4) = {'yhat_us'};
M_.endo_names(5) = {'pi_us_gap'};
M_.endo_names_tex(5) = {'pi\_us\_gap'};
M_.endo_names_long(5) = {'pi_us_gap'};
M_.endo_partitions = struct();
M_.param_names = cell(11,1);
M_.param_names_tex = cell(11,1);
M_.param_names_long = cell(11,1);
M_.param_names(1) = {'lambda_q'};
M_.param_names_tex(1) = {'lambda\_q'};
M_.param_names_long(1) = {'lambda_q'};
M_.param_names(2) = {'sigma_q'};
M_.param_names_tex(2) = {'sigma\_q'};
M_.param_names_long(2) = {'sigma_q'};
M_.param_names(3) = {'delta'};
M_.param_names_tex(3) = {'delta'};
M_.param_names_long(3) = {'delta'};
M_.param_names(4) = {'lambda_i'};
M_.param_names_tex(4) = {'lambda\_i'};
M_.param_names_long(4) = {'lambda_i'};
M_.param_names(5) = {'alpha_i'};
M_.param_names_tex(5) = {'alpha\_i'};
M_.param_names_long(5) = {'alpha_i'};
M_.param_names(6) = {'beta_i'};
M_.param_names_tex(6) = {'beta\_i'};
M_.param_names_long(6) = {'beta_i'};
M_.param_names(7) = {'lambda_pi'};
M_.param_names_tex(7) = {'lambda\_pi'};
M_.param_names_long(7) = {'lambda_pi'};
M_.param_names(8) = {'kappa_pi'};
M_.param_names_tex(8) = {'kappa\_pi'};
M_.param_names_long(8) = {'kappa_pi'};
M_.param_names(9) = {'lambda_q_us'};
M_.param_names_tex(9) = {'lambda\_q\_us'};
M_.param_names_long(9) = {'lambda_q_us'};
M_.param_names(10) = {'lambda_pi_us'};
M_.param_names_tex(10) = {'lambda\_pi\_us'};
M_.param_names_long(10) = {'lambda_pi_us'};
M_.param_names(11) = {'kappa_pi_us'};
M_.param_names_tex(11) = {'kappa\_pi\_us'};
M_.param_names_long(11) = {'kappa_pi_us'};
M_.param_partitions = struct();
M_.exo_det_nbr = 0;
M_.exo_nbr = 5;
M_.endo_nbr = 5;
M_.param_nbr = 11;
M_.orig_endo_nbr = 5;
M_.aux_vars = [];
options_.varobs = cell(5, 1);
options_.varobs(1)  = {'yhat_au'};
options_.varobs(2)  = {'pi_au_gap'};
options_.varobs(3)  = {'i_gap'};
options_.varobs(4)  = {'yhat_us'};
options_.varobs(5)  = {'pi_us_gap'};
options_.varobs_id = [ 1 3 2 4 5  ];
M_.Sigma_e = zeros(5, 5);
M_.Correlation_matrix = eye(5, 5);
M_.H = 0;
M_.Correlation_matrix_ME = 1;
M_.sigma_e_is_diagonal = true;
M_.det_shocks = [];
M_.surprise_shocks = [];
M_.learnt_shocks = [];
M_.learnt_endval = [];
M_.heteroskedastic_shocks.Qvalue_orig = [];
M_.heteroskedastic_shocks.Qscale_orig = [];
M_.matched_irfs = {};
M_.matched_irfs_weights = {};
options_.linear = false;
options_.block = false;
options_.bytecode = false;
options_.use_dll = false;
options_.ramsey_policy = false;
options_.discretionary_policy = false;
M_.nonzero_hessian_eqs = [];
M_.hessian_eq_zero = isempty(M_.nonzero_hessian_eqs);
M_.eq_nbr = 5;
M_.ramsey_orig_eq_nbr = 0;
M_.ramsey_orig_endo_nbr = 0;
M_.set_auxiliary_variables = exist(['./+' M_.fname '/set_auxiliary_variables.m'], 'file') == 2;
M_.epilogue_names = {};
M_.epilogue_var_list_ = {};
M_.orig_maximum_endo_lag = 1;
M_.orig_maximum_endo_lead = 0;
M_.orig_maximum_exo_lag = 0;
M_.orig_maximum_exo_lead = 0;
M_.orig_maximum_exo_det_lag = 0;
M_.orig_maximum_exo_det_lead = 0;
M_.orig_maximum_lag = 1;
M_.orig_maximum_lead = 0;
M_.orig_maximum_lag_with_diffs_expanded = 1;
M_.lead_lag_incidence = [
 1 6;
 2 7;
 3 8;
 4 9;
 5 10;]';
M_.nstatic = 0;
M_.nfwrd   = 0;
M_.npred   = 5;
M_.nboth   = 0;
M_.nsfwrd   = 0;
M_.nspred   = 5;
M_.ndynamic   = 5;
M_.dynamic_tmp_nbr = [0; 0; 0; 0; ];
M_.equations_tags = {
  1 , 'name' , 'yhat_au' ;
  2 , 'name' , 'i_gap' ;
  3 , 'name' , 'pi_au_gap' ;
  4 , 'name' , 'yhat_us' ;
  5 , 'name' , 'pi_us_gap' ;
};
M_.mapping.yhat_au.eqidx = [1 2 3 ];
M_.mapping.i_gap.eqidx = [1 2 ];
M_.mapping.pi_au_gap.eqidx = [1 2 3 ];
M_.mapping.yhat_us.eqidx = [1 4 5 ];
M_.mapping.pi_us_gap.eqidx = [5 ];
M_.mapping.eps_q.eqidx = [1 ];
M_.mapping.eps_i.eqidx = [2 ];
M_.mapping.eps_pi.eqidx = [3 ];
M_.mapping.eps_q_us.eqidx = [4 ];
M_.mapping.eps_pi_us.eqidx = [5 ];
M_.static_and_dynamic_models_differ = false;
M_.has_external_function = false;
M_.block_structure.time_recursive = true;
M_.block_structure.block(1).Simulation_Type = 1;
M_.block_structure.block(1).endo_nbr = 5;
M_.block_structure.block(1).mfs = 5;
M_.block_structure.block(1).equation = [ 2 3 4 5 1];
M_.block_structure.block(1).variable = [ 2 3 4 5 1];
M_.block_structure.block(1).is_linear = true;
M_.block_structure.block(1).NNZDerivatives = 6;
M_.block_structure.block(1).bytecode_jacob_cols_to_sparse = [1 2 3 4 5 6 7 8 9 10 ];
M_.block_structure.block(1).g1_sparse_rowval = int32([]);
M_.block_structure.block(1).g1_sparse_colval = int32([]);
M_.block_structure.block(1).g1_sparse_colptr = int32([]);
M_.block_structure.variable_reordered = [ 2 3 4 5 1];
M_.block_structure.equation_reordered = [ 2 3 4 5 1];
M_.block_structure.incidence(1).lead_lag = -1;
M_.block_structure.incidence(1).sparse_IM = [
 1 1;
 1 2;
 1 3;
 2 1;
 2 2;
 2 3;
 3 1;
 3 3;
 4 4;
 5 4;
 5 5;
];
M_.block_structure.incidence(2).lead_lag = 0;
M_.block_structure.incidence(2).sparse_IM = [
 1 1;
 1 4;
 2 2;
 3 3;
 4 4;
 5 5;
];
M_.block_structure.dyn_tmp_nbr = 0;
M_.state_var = [2 3 4 5 1 ];
M_.maximum_lag = 1;
M_.maximum_lead = 0;
M_.maximum_endo_lag = 1;
M_.maximum_endo_lead = 0;
oo_.steady_state = zeros(5, 1);
M_.maximum_exo_lag = 0;
M_.maximum_exo_lead = 0;
oo_.exo_steady_state = zeros(5, 1);
M_.params = NaN(11, 1);
M_.endo_trends = struct('deflator', cell(5, 1), 'log_deflator', cell(5, 1), 'growth_factor', cell(5, 1), 'log_growth_factor', cell(5, 1));
M_.NNZDerivatives = [22; 0; -1; ];
M_.dynamic_g1_sparse_rowval = int32([1 2 3 1 2 1 2 3 4 5 5 1 2 3 1 4 5 1 2 3 4 5 ]);
M_.dynamic_g1_sparse_colval = int32([1 1 1 2 2 3 3 3 4 4 5 6 7 8 9 9 10 16 17 18 19 20 ]);
M_.dynamic_g1_sparse_colptr = int32([1 4 6 9 11 12 13 14 15 17 18 18 18 18 18 18 19 20 21 22 23 ]);
M_.dynamic_g2_sparse_indices = int32([]);
M_.lhs = {
'yhat_au'; 
'i_gap'; 
'pi_au_gap'; 
'yhat_us'; 
'pi_us_gap'; 
};
M_.static_tmp_nbr = [0; 0; 0; 0; ];
M_.block_structure_stat.block(1).Simulation_Type = 3;
M_.block_structure_stat.block(1).endo_nbr = 1;
M_.block_structure_stat.block(1).mfs = 1;
M_.block_structure_stat.block(1).equation = [ 4];
M_.block_structure_stat.block(1).variable = [ 4];
M_.block_structure_stat.block(2).Simulation_Type = 3;
M_.block_structure_stat.block(2).endo_nbr = 1;
M_.block_structure_stat.block(2).mfs = 1;
M_.block_structure_stat.block(2).equation = [ 5];
M_.block_structure_stat.block(2).variable = [ 5];
M_.block_structure_stat.block(3).Simulation_Type = 6;
M_.block_structure_stat.block(3).endo_nbr = 3;
M_.block_structure_stat.block(3).mfs = 3;
M_.block_structure_stat.block(3).equation = [ 3 1 2];
M_.block_structure_stat.block(3).variable = [ 3 1 2];
M_.block_structure_stat.variable_reordered = [ 4 5 3 1 2];
M_.block_structure_stat.equation_reordered = [ 4 5 3 1 2];
M_.block_structure_stat.incidence.sparse_IM = [
 1 1;
 1 2;
 1 3;
 1 4;
 2 1;
 2 2;
 2 3;
 3 1;
 3 3;
 4 4;
 5 4;
 5 5;
];
M_.block_structure_stat.tmp_nbr = 0;
M_.block_structure_stat.block(1).g1_sparse_rowval = int32([1 ]);
M_.block_structure_stat.block(1).g1_sparse_colval = int32([1 ]);
M_.block_structure_stat.block(1).g1_sparse_colptr = int32([1 2 ]);
M_.block_structure_stat.block(2).g1_sparse_rowval = int32([1 ]);
M_.block_structure_stat.block(2).g1_sparse_colval = int32([1 ]);
M_.block_structure_stat.block(2).g1_sparse_colptr = int32([1 2 ]);
M_.block_structure_stat.block(3).g1_sparse_rowval = int32([1 2 3 1 2 3 2 3 ]);
M_.block_structure_stat.block(3).g1_sparse_colval = int32([1 1 1 2 2 2 3 3 ]);
M_.block_structure_stat.block(3).g1_sparse_colptr = int32([1 4 7 9 ]);
M_.static_g1_sparse_rowval = int32([1 2 3 1 2 1 2 3 1 4 5 5 ]);
M_.static_g1_sparse_colval = int32([1 1 1 2 2 3 3 3 4 4 4 5 ]);
M_.static_g1_sparse_colptr = int32([1 4 6 9 12 13 ]);
M_.params(1) = 0.88;
lambda_q = M_.params(1);
M_.params(2) = 0.08;
sigma_q = M_.params(2);
M_.params(4) = 0.88;
lambda_i = M_.params(4);
M_.params(5) = 0.40;
alpha_i = M_.params(5);
M_.params(6) = 0.15;
beta_i = M_.params(6);
M_.params(7) = 0.50;
lambda_pi = M_.params(7);
M_.params(8) = 0.08;
kappa_pi = M_.params(8);
M_.params(3) = 0.10;
delta = M_.params(3);
M_.params(9) = 0.95;
lambda_q_us = M_.params(9);
M_.params(10) = 0.50;
lambda_pi_us = M_.params(10);
M_.params(11) = 0.10;
kappa_pi_us = M_.params(11);
steady;
oo_.dr.eigval = check(M_,options_,oo_);
if isempty(estim_params_)
    estim_params_.var_exo = zeros(0, 10);
    estim_params_.var_endo = zeros(0, 10);
    estim_params_.corrx = zeros(0, 11);
    estim_params_.corrn = zeros(0, 11);
    estim_params_.param_vals = zeros(0, 10);
end
if ~isempty(find(estim_params_.param_vals(:,1)==1))
    error('Parameter lambda_q has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.param_vals = [estim_params_.param_vals; 1, NaN, (-Inf), Inf, 1, 0.88, 0.05, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.param_vals(:,1)==2))
    error('Parameter sigma_q has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.param_vals = [estim_params_.param_vals; 2, NaN, (-Inf), Inf, 2, 0.08, 0.03, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.param_vals(:,1)==4))
    error('Parameter lambda_i has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.param_vals = [estim_params_.param_vals; 4, NaN, (-Inf), Inf, 1, 0.88, 0.05, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.param_vals(:,1)==5))
    error('Parameter alpha_i has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.param_vals = [estim_params_.param_vals; 5, NaN, (-Inf), Inf, 2, 0.40, 0.15, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.param_vals(:,1)==6))
    error('Parameter beta_i has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.param_vals = [estim_params_.param_vals; 6, NaN, (-Inf), Inf, 2, 0.15, 0.08, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.param_vals(:,1)==7))
    error('Parameter lambda_pi has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.param_vals = [estim_params_.param_vals; 7, NaN, (-Inf), Inf, 1, 0.50, 0.15, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.param_vals(:,1)==8))
    error('Parameter kappa_pi has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.param_vals = [estim_params_.param_vals; 8, NaN, (-Inf), Inf, 2, 0.08, 0.04, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.var_exo(:,1)==1))
    error('The standard deviation for eps_q has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.var_exo = [estim_params_.var_exo; 1, NaN, (-Inf), Inf, 4, 0.50, Inf, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.var_exo(:,1)==2))
    error('The standard deviation for eps_i has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.var_exo = [estim_params_.var_exo; 2, NaN, (-Inf), Inf, 4, 0.08, Inf, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.var_exo(:,1)==3))
    error('The standard deviation for eps_pi has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.var_exo = [estim_params_.var_exo; 3, NaN, (-Inf), Inf, 4, 0.70, Inf, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.var_exo(:,1)==4))
    error('The standard deviation for eps_q_us has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.var_exo = [estim_params_.var_exo; 4, NaN, (-Inf), Inf, 4, 1.00, Inf, NaN, NaN, NaN ];
if ~isempty(find(estim_params_.var_exo(:,1)==5))
    error('The standard deviation for eps_pi_us has been specified twice in two concatenated ''estimated_params'' blocks. Depending on your intention, you may want to use the ''overwrite'' option or an ''estimated_params_remove'' block.')
end
estim_params_.var_exo = [estim_params_.var_exo; 5, NaN, (-Inf), Inf, 4, 0.30, Inf, NaN, NaN, NaN ];
options_.datafile = 'estimation_data.mat';
options_.first_obs = 1;
options_.mh_jscale = 0.4;
options_.mh_nblck = 2;
options_.mh_replic = 25000;
options_.mode_compute = 4;
options_.nobs = 122;
options_.nograph = true;
options_.presample = 4;
options_.order = 1;
var_list_ = {};
oo_recursive_=dynare_estimation(var_list_);


oo_.time = toc(tic0);
disp(['Total computing time : ' dynsec2hms(oo_.time) ]);
if ~exist([M_.dname filesep 'Output'],'dir')
    mkdir(M_.dname,'Output');
end
save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'oo_', 'M_', 'options_');
if exist('estim_params_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'estim_params_', '-append');
end
if exist('bayestopt_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'bayestopt_', '-append');
end
if exist('dataset_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'dataset_', '-append');
end
if exist('estimation_info', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'estimation_info', '-append');
end
if exist('dataset_info', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'dataset_info', '-append');
end
if exist('oo_recursive_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'oo_recursive_', '-append');
end
if exist('options_mom_', 'var') == 1
  save([M_.dname filesep 'Output' filesep 'au_esat_est_results.mat'], 'options_mom_', '-append');
end
if ~isempty(lastwarn)
  disp('Note: warning(s) encountered in MATLAB/Octave code')
end
