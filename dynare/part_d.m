% part_d.m — prove ln_QN permanent shift = -(1-alpha_k)*sigma_ces*sum(rw_gap)
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod;
options_.nograph=1; options_.noprint=1; options_.irf=2000;
ei=find(strcmp(M_.exo_names,'eps_i')); scale=0.25/sqrt(M_.Sigma_e(ei,ei));
ak  = M_.params(strcmp(M_.param_names,'alpha_k'));
sc  = M_.params(strcmp(M_.param_names,'sigma_ces'));
fprintf('alpha_k=%.3f  sigma_ces=%.3f  => coef -(1-ak)*sc = %.4f\n', ak, sc, -(1-ak)*sc);

vl={'ln_QN','yhat_au','rw_gap','dln_n_star_bar','dln_k','dln_tfp','dln_pop_bar','dln_ib','dln_y_star','ln_N_star'};
vl=vl(ismember(vl,M_.endo_names));
fprintf('vars present: %s\n', strjoin(vl,', '));
[~,oo_,options_,M_]=stoch_simul(M_,options_,oo_,vl);
G=struct(); for k=1:numel(vl), G.(vl{k})=oo_.irfs.([vl{k} '_eps_i'])(:)*scale; end
cum=@(nm) (isfield(G,nm) && ~isempty(G.(nm)))*0 + (isfield(G,nm))*0; % noop

S=@(nm) sum(G.(nm));
fprintf('\n-- cumulative sums over 2000Q (should pin the permanent ln_QN) --\n');
for nm={'dln_ib','dln_k','dln_tfp','dln_pop_bar','dln_n_star_bar','rw_gap','dln_y_star'}
  v=nm{1}; if isfield(G,v)&&~isempty(G.(v)), fprintf('   sum(%-14s)=%+10.5f\n', v, sum(G.(v))); end
end
predict = -(1-ak)*sc*sum(G.rw_gap);
fprintf('\n   ln_QN(2000)            = %+10.5f\n', G.ln_QN(end));
fprintf('   -(1-ak)*sc*sum(rw_gap) = %+10.5f   <-- prediction\n', predict);
fprintf('   alpha_k*sum(dln_k)     = %+10.5f   (capital channel, should ~0)\n', ak*sum(G.dln_k));
fprintf('   (1-ak)*sum(dln_pop_bar)= %+10.5f   (should be 0 for eps_i)\n', (1-ak)*sum(G.dln_pop_bar));
fprintf('   yhat_au(2000)          = %+10.5f   (gap, should ~0)\n', G.yhat_au(end));

fprintf('\n-- convergence of ln_QN and rw_gap --\n');
for q=[40 100 200 500 1000 2000]
  fprintf('   Q%-5d ln_QN=%+8.4f  rw_gap=%+8.4f  cum(rw_gap)=%+8.4f\n', q, G.ln_QN(q), G.rw_gap(q), sum(G.rw_gap(1:q)));
end
fprintf('DONE.\n');
