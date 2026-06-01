% verify_phase2.m — Phase-2 mining supply block gate.
% (1) BK still holds (n_exp=5); (2) ln_QN_recon == ln_QN (potential aggregation closes);
% (3) COMMODITY shock (eps_pcom) ratchets mining potential ln_QN_m up persistently;
% (4) MONETARY shock (eps_i) leaves ln_QN_m ~ 0 at all horizons (mining is supply/price-driven,
%     near rate-insensitive) and the aggregate ln_Q monetary response is DAMPENED vs single-sector.
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod

ev=oo_.dr.eigval; n_exp=sum(abs(ev)>1+1e-9); H=numel(oo_.irfs.ln_Q_eps_i);
fprintf('\n===== PHASE 2 VERIFICATION (H=%d) =====\n',H);
fprintf('BK: n_exp=%d (want 5)  max|eig|=%.5f  | endo=%d exo=%d\n', n_exp, max(abs(ev)), M_.endo_nbr, M_.exo_nbr);

% reconciliation: aggregate potential = weighted sector potentials
mr=0;
for i=1:numel(M_.exo_names)
  s=M_.exo_names{i}; f=@(v)oo_.irfs.([v '_' s]);
  if isfield(oo_.irfs,['ln_QN_recon_' s]), mr=max(mr,max(abs(f('ln_QN_recon')-f('ln_QN')))); end
end
fprintf('max|ln_QN_recon - ln_QN| over shocks = %.2e (want ~0; potential aggregation closes)\n', mr);

prof=@(v,s) [max(abs(oo_.irfs.([v '_' s])(1:40))), oo_.irfs.([v '_' s])(40), oo_.irfs.([v '_' s])(end)];

fprintf('\n[3] COMMODITY shock eps_pcom (1 s.d.):  var  peak|Q1-40|   Q40        Q200\n');
for v={'dln_ib_m','ln_K_m','ln_QN_m','ln_Q_m','pcom_gap','ln_Q'}
  p=prof(v{1},'eps_pcom'); fprintf('    %-9s  %+.4f   %+.4f   %+.4f\n', v{1}, p(1),p(2),p(3));
end
qnm_pcom_q200 = oo_.irfs.ln_QN_m_eps_pcom(end);
qnm_pcom_pk   = max(abs(oo_.irfs.ln_QN_m_eps_pcom(1:40)));
fprintf('    -> mining potential persistence |Q200|/|peak| = %.2f  (ratchet: stays elevated)\n', abs(qnm_pcom_q200)/qnm_pcom_pk);

% monetary: scale eps_i to 100bp
idx=find(strcmp(M_.exo_names,'eps_i')); sc=0.25/sqrt(M_.Sigma_e(idx,idx));
fprintf('\n[4] MONETARY shock eps_i (100bp):  var   peak|Q1-40|   Q40        Q200\n');
for v={'ln_QN_m','ln_Q_m','dln_ib_m','ln_Q','yhat_au'}
  x=oo_.irfs.([v{1} '_eps_i'])*sc; w=x(1:40); [mn,~]=min(w); [mx,~]=max(w);
  pk=mn; if abs(mx)>abs(mn), pk=mx; end
  fprintf('    %-9s  %+.5f   %+.5f   %+.5f\n', v{1}, pk, x(40), x(end));
end
qnm_i_pk = max(abs(oo_.irfs.ln_QN_m_eps_i*sc));
fprintf('    -> mining potential |peak| to 100bp = %.2e  (want ~0: mining near rate-insensitive)\n', qnm_i_pk);

% headline falsifiable contrast
fprintf('\nFALSIFIABLE: ln_QN_m responds to COMMODITY (peak %.4f) but NOT MONETARY (peak %.2e); ratio %.0fx\n', ...
        qnm_pcom_pk, qnm_i_pk, qnm_pcom_pk/max(qnm_i_pk,1e-12));
lnq_i = oo_.irfs.ln_Q_eps_i*sc; [tr,q]=min(lnq_i(1:40));
fprintf('aggregate ln_Q trough to 100bp = %+.5f @Q%d  (Phase-1b single-sector was -0.144%%; expect DAMPENED ~x0.88)\n', tr, q);

pass = (n_exp==5) && (mr<1e-8) && (qnm_i_pk < 0.01*qnm_pcom_pk);
fprintf('\nGATE 2 (BK + reconciliation + commodity-ratchet >> monetary on mining potential): %s\n', string(pass));
fprintf('=========================================\n');
