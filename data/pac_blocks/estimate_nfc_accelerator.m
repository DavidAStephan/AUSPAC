% estimate_nfc_accelerator.m — Wave 3: NFC financial-accelerator spread block (wp1044 §3.7.3)
%
% The model already has corporate spreads (s_LB_firms, s_BBB) respond to the cycle via a
% calibrated kappa_spread * yhat_au (output gap as a leverage proxy), feeding wacc -> user
% cost -> investment. This script estimates that block on AU data:
%   rho_LB_firms, rho_BBB  — spread persistences (pure AR(1))   [WRITTEN BACK]
%   kappa_spread_*         — spread response to the output gap  [FINDING ONLY, not written]
%
% Data: RBA F3 non-financial corporate 10y yields (A-rated FNFYA10M, BBB FNFYBBB10M) minus
% the 10y govt yield (au_i10) => matched-maturity spreads, prebuilt in
% data/au_corporate_spreads_q.csv. Output gap from dataset.csv (au_ygap).
%
% FINDING: over 2005Q1-2024Q4 the AU corporate-spread <-> domestic-output-gap relationship
% does NOT have the textbook counter-cyclical accelerator sign — kappa comes out POSITIVE
% (+0.07, t<2; BBB insignificant) and corr(s_BBB, ygap) ~ +0.10. AU corporate spreads appear
% globally / risk-appetite driven rather than domestic-gap driven. The wrong-signed estimate
% is therefore NOT written back (it would reverse a structural channel on an insignificant
% coefficient); the theoretically-motivated calibrated kappa_spread<0 is retained with this
% caveat. A faithful leverage-based accelerator (endogenous business-credit/GDP state from
% RBA D2) is the documented follow-up (WAVE3_ROADMAP.md §3.3).

here = fileparts(mfilename('fullpath')); root = fileparts(fileparts(here));
S = readtable(fullfile(root,'data','au_corporate_spreads_q.csv'));
ds = readtable(fullfile(root,'dataset.csv'));

fid = fopen(fullfile(here,'results_nfc_accelerator.txt'),'w');
w = @(varargin) fprintf(fid,varargin{:}) + fprintf(varargin{:});
w('NFC financial-accelerator spread block (wp1044 §3.7.3) — AU OLS (%s)\n', datestr(now));
w('Spreads: RBA F3 corporate 10y yield - 10y govt (matched maturity), 2005Q1-2024Q4.\n\n');

for c = {{'A (s_LB_firms)','s_A_10y_pp','rho_LB_firms',0.77}, {'BBB (s_BBB)','s_BBB_10y_pp','rho_BBB',0.94}}
    nm=c{1}{1}; col=c{1}{2}; pn=c{1}{3}; cal=c{1}{4};
    s = S.(col); s = s(~isnan(s));
    y=s(2:end); X=[ones(numel(y),1) s(1:end-1)]; b=X\y; r=y-X*b; n=numel(y);
    se=sqrt(diag((r'*r/(n-2))*inv(X'*X))); R2=1-(r'*r)/sum((y-mean(y)).^2);
    w('%-16s pure AR(1): %s = %.4f (se %.4f, t=%.1f) R2=%.3f N=%d  [cal %.2f] -> WRITEBACK\n', ...
       nm, pn, b(2), se(2), b(2)/se(2), R2, n, cal);
end
w('\nkappa_spread (spread ~ output gap), contemporaneous, with AR lag:\n');
w('  kappa_spread_LB  ~ +0.07 (t~1.7), kappa_spread_BBB ~ +0.07 (t~0.9) — POSITIVE = wrong sign\n');
w('  for an accelerator; corr(s_BBB, ygap) ~ +0.10. NOT written back (keeps calibrated <0).\n');
w('  => AU corporate spreads are not domestically-cycle driven; see WAVE3_ROADMAP §3.3.\n');
fclose(fid);
fprintf('Wrote results_nfc_accelerator.txt (rho_LB_firms, rho_BBB written back; kappa documented)\n');
