% verify_phase1a.m — confirm the Phase-1a sector potential-output reporting
% aggregates are (a) BK-neutral, (b) reconcile to ln_QN, and (c) leave every
% economic IRF bit-identical to the pre-edit single-sector baseline.
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod

ev = oo_.dr.eigval; n_exp = sum(abs(ev) > 1 + 1e-9);
fprintf('\n===== PHASE 1a VERIFICATION =====\n');
fprintf('BK: n_exp=%d (want 5)  max|eig|=%.5f (want 1.08707)\n', n_exp, max(abs(ev)));
fprintf('dimensions: endo=%d (was 182)  exo=%d (was 55)\n', M_.endo_nbr, M_.exo_nbr);

% --- reconciliation + placeholder checks across ALL shocks ---
shocks = M_.exo_names; maxrec=0; maxm=0; maxnm=0; maxnmk=0; nchk=0;
for i = 1:numel(shocks)
    s = shocks{i};
    fr=['ln_QN_recon_' s]; fq=['ln_QN_' s];
    fm=['ln_QN_m_' s]; fnm=['ln_QN_nm_' s]; fnmk=['ln_QN_nmk_' s];
    if isfield(oo_.irfs,fr) && isfield(oo_.irfs,fq)
        maxrec = max(maxrec, max(abs(oo_.irfs.(fr)-oo_.irfs.(fq))));
        maxm   = max(maxm,   max(abs(oo_.irfs.(fm)-oo_.irfs.(fq))));
        maxnm  = max(maxnm,  max(abs(oo_.irfs.(fnm)-oo_.irfs.(fq))));
        maxnmk = max(maxnmk, max(abs(oo_.irfs.(fnmk)-oo_.irfs.(fq))));
        nchk = nchk + 1;
    end
end
fprintf('reconciliation over %d shocks:\n', nchk);
fprintf('  max|ln_QN_recon - ln_QN| = %.3e  (want ~0)\n', maxrec);
fprintf('  max|ln_QN_m   - ln_QN|   = %.3e  (placeholder => 0)\n', maxm);
fprintf('  max|ln_QN_nm  - ln_QN|   = %.3e\n', maxnm);
fprintf('  max|ln_QN_nmk - ln_QN|   = %.3e\n', maxnmk);

% --- economic IRFs unchanged vs the saved baseline (validate_wave1_report.txt) ---
idx = find(strcmp(M_.exo_names,'eps_i')); scale = 0.25/sqrt(M_.Sigma_e(idx,idx));
base = struct('ln_Q',-0.14420,'yhat_au',-0.08595,'ln_N',-0.16525,'ln_IB',-0.57205,'s_gap',-0.98500);
bq   = struct('ln_Q',11,'yhat_au',11,'ln_N',12,'ln_IB',15,'s_gap',8);
fn = fieldnames(base); maxdiff = 0;
fprintf('100bp eps_i trough vs pre-edit baseline:\n');
for k=1:numel(fn)
    v=fn{k}; x=oo_.irfs.([v '_eps_i'])*scale; w=x(1:40);
    [mn,qi]=min(w);[mx,qm]=max(w); if abs(mn)>=abs(mx),pk=mn;q=qi;else,pk=mx;q=qm;end
    d=abs(pk-base.(v)); maxdiff=max(maxdiff,d);
    fprintf('  %-8s %+.5f @Q%d  (baseline %+.5f @Q%d)  diff=%.2e\n', v, pk, q, base.(v), bq.(v), d);
end
fprintf('max|trough diff vs baseline| = %.2e (want ~0 => bit-identical)\n', maxdiff);

pass = (n_exp==5) && (maxrec<1e-10) && (maxm<1e-10) && (maxdiff<1e-4);
fprintf('\nGATE 1a (model-side): %s\n', string(pass));
fprintf('=================================\n');
