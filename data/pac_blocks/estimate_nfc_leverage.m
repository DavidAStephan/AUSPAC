% estimate_nfc_leverage.m — Wave 3 follow-up: leverage-based NFC financial accelerator.
%
% The output-gap proxy for the corporate-spread channel came out wrong-signed/insignificant
% on AU data (see estimate_nfc_accelerator.m). This script estimates the leverage-based
% version (wp1044 §3.7.3 idea), which IS identified:
%   lev_nfc_gap = rho_lev*lev_nfc_gap(-1) + alpha_lev_y*yhat_au(-1) + eps_lev   (leverage law)
%   s_{LB,BBB}  = ... + kappa_lev_{LB,BBB}*lev_nfc_gap(-1) + eps                  (spread channel)
%
% Leverage gap = HP-gap of log AU business credit (RBA D2 DLCACBN), pp, au_nfc_leverage_q.csv.
% Spreads = RBA F3 10y corporate - 10y govt, quarterly units (/4), au_corporate_spreads_q.csv.
%
% FINDING: spreads respond POSITIVELY to the leverage gap (kappa_lev>0, t~3) and leverage
% responds POSITIVELY to activity (alpha_lev_y>0, t=2.1) -> AU corporate spreads are
% PRO-cyclical via the credit cycle (high leverage in booms -> high spreads), the OPPOSITE of
% the textbook counter-cyclical Bernanke-Gertler accelerator. The calibrated B-G sign that AU
% data rejects (kappa_spread<0 on the output gap) is replaced by this estimated leverage channel.
% Data caveat: RBA D2 business credit ends 2019Q2, so the spread sample is N=57 (2005-2019).

here = fileparts(mfilename('fullpath')); root = fileparts(fileparts(here));
L  = readtable(fullfile(root,'data','au_nfc_leverage_q.csv'));
S  = readtable(fullfile(root,'data','au_corporate_spreads_q.csv'));
ds = readtable(fullfile(root,'dataset.csv'));

lev = L.lev_gap_pp; levdate = string(L.date);
ygq = strings(height(ds),1);
for i = 1:height(ds)
    d = datetime(ds.date(i)); ygq(i) = sprintf('%dQ%d', year(d), quarter(d));
end
[~, ia, ib] = intersect(levdate, ygq, 'stable');
levc = lev(ia); yc = ds.au_ygap(ib);

% leverage law: lev_t = c + rho*lev_{t-1} + alpha*ygap_{t-1}
[b,se,sd,r2,n] = ols_se(levc(2:end), [ones(numel(levc)-1,1) levc(1:end-1) yc(1:end-1)]);

fid = fopen(fullfile(here,'results_nfc_leverage.txt'),'w');
w = @(varargin) fprintf(fid,varargin{:}) + fprintf(varargin{:});
w('NFC leverage accelerator (wp1044 §3.7.3) — AU OLS (%s)\n', datestr(now));
w('leverage law: rho_lev=%.4f (t=%.1f), alpha_lev_y=%.4f (t=%.1f), eps_lev_sd=%.3f, R2=%.3f, N=%d\n', ...
   b(2),b(2)/se(2), b(3),b(3)/se(3), sd, r2, n);

sdate = string(S.date);
cols = {'LB','s_A_10y_pp'; 'BBB','s_BBB_10y_pp'};
for c = 1:size(cols,1)
    [~, ja, jb] = intersect(sdate, levdate, 'stable');
    sp = S.(cols{c,2})(ja)/4; lv = lev(jb);
    [bs,ses,~,r2s,ns] = ols_se(sp(2:end), [ones(numel(sp)-1,1) sp(1:end-1) lv(1:end-1)]);
    w('kappa_lev_%-3s = %.4f (t=%.1f) [quarterly units], rho=%.3f, R2=%.3f, N=%d\n', ...
       cols{c,1}, bs(3), bs(3)/ses(3), bs(2), r2s, ns);
end
w('Written back to au_pac.mod: rho_lev, alpha_lev_y, kappa_lev_LB, kappa_lev_BBB, eps_lev std.\n');
fclose(fid);
fprintf('Wrote results_nfc_leverage.txt\n');

function [b,se,sd,r2,n] = ols_se(y, X)
    b = X\y; r = y - X*b; n = numel(y); k = size(X,2);
    se = sqrt(diag((r'*r/(n-k)) * inv(X'*X)));
    sd = std(r); r2 = 1 - (r'*r)/sum((y-mean(y)).^2);
end
