%% estimate_exports_trendbreaks.m — does a piecewise-linear (broken) trend absorb
% the supply-capacity ramp and lower b1_x?  AU export volumes ramped in distinct
% mining/LNG capacity regimes; a single trend (or HP) leaves that as persistence
% in dln_x. We fit a continuous piecewise-linear trend with K data-driven slope
% breaks (basis [1, t, (t-tau)_+ ...]), detrend, and re-estimate the CYCLICAL ECM.
clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));
D = load(fullfile(projectdir, 'data', 'trade_price_data.mat'));
E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));
qkey = @(d) year(d)*10 + ceil(month(d)/3);

master_dates = D.vol_dates; T = numel(master_dates); mk = qkey(master_dates);
dln_x = D.dln_x; ln_X = log(D.x_vol)*100;
est_start = M.meta.sample_start; n_est = numel(E.yhat_us);
est_dates = est_start + calquarters(0:n_est-1); ek = qkey(est_dates);
yhat_us_full=NaN(T,1); for t=1:T, ix=find(ek==mk(t),1); if ~isempty(ix), yhat_us_full(t)=E.yhat_us(ix); end, end
twi_k=qkey(D.q_twi_dates); s_gap_full=NaN(T,1); for t=1:T, ix=find(twi_k==mk(t),1); if ~isempty(ix), s_gap_full(t)=D.s_gap_proxy(ix); end, end
pcom_k=qkey(D.q_pcom_dates); dln_pcom_full=NaN(T,1); for t=1:T, ix=find(pcom_k==mk(t),1); if ~isempty(ix), dln_pcom_full(t)=D.dln_pcom(ix); end, end
lag1=@(x)[NaN; x(1:end-1)];

% restrict trend fit to the ECM ESTIMATION window (mining era), so breaks can
% land on the 2009 iron-ore and 2015 LNG capacity ramps rather than 1960s history
ecm_valid = ~isnan(ln_X) & ~isnan(yhat_us_full) & ~isnan(s_gap_full) & ~isnan(dln_pcom_full);
idx = find(ecm_valid); s0=idx(1); s1=idx(end);
y = ln_X(s0:s1); tt=(1:numel(y))'; n=numel(y); dts=master_dates(s0:s1);
fprintf('Export-vol trend sample (ECM window): %s .. %s (n=%d)\n', datestr(dts(1),'yyyy-Qq'), datestr(dts(end),'yyyy-Qq'), n);

% --- grid-search continuous piecewise-linear trend, K breaks, min segment 8q ---
function [ssr,res,bks] = fitpw(y,tt,taus)
    X=[ones(numel(tt),1), tt];
    for j=1:numel(taus), X=[X, max(0, tt-taus(j))]; end
    b=X\y; res=y-X*b; ssr=res'*res; bks=taus;
end
minseg=8;
% K=0
[ssr0,res0]=fitpw(y,tt,[]);
% K=1
bestssr=inf; b1tau=[];
for a=minseg:(n-minseg), [s,~]=fitpw(y,tt,a); if s<bestssr, bestssr=s; b1tau=a; end, end
[~,res1]=fitpw(y,tt,b1tau);
% K=2
bestssr=inf; b2tau=[];
for a=minseg:(n-2*minseg), for c=(a+minseg):(n-minseg)
    [s,~]=fitpw(y,tt,[a c]); if s<bestssr, bestssr=s; b2tau=[a c]; end
end, end
[~,res2]=fitpw(y,tt,b2tau);
% K=3
bestssr=inf; b3tau=[];
for a=minseg:(n-3*minseg), for c=(a+minseg):(n-2*minseg), for e=(c+minseg):(n-minseg)
    [s,~]=fitpw(y,tt,[a c e]); if s<bestssr, bestssr=s; b3tau=[a c e]; end
end, end, end
[~,res3]=fitpw(y,tt,b3tau);
fprintf('break dates: K1 -> %s | K2 -> %s, %s | K3 -> %s, %s, %s\n', datestr(dts(b1tau),'yyyy-Qq'), ...
    datestr(dts(b2tau(1)),'yyyy-Qq'), datestr(dts(b2tau(2)),'yyyy-Qq'), ...
    datestr(dts(b3tau(1)),'yyyy-Qq'), datestr(dts(b3tau(2)),'yyyy-Qq'), datestr(dts(b3tau(3)),'yyyy-Qq'));
fprintf('trend R2: K0=%.3f K1=%.3f K2=%.3f K3=%.3f\n', 1-var(res0)/var(y), 1-var(res1)/var(y), 1-var(res2)/var(y), 1-var(res3)/var(y));

% map residuals back to full-length vectors
mkcyc=@(res)[nan(s0-1,1); res; nan(T-s1,1)];
cycs = {mkcyc(res0),'K0 linear'; mkcyc(res1),'K1 break'; mkcyc(res2),'K2 breaks'; mkcyc(res3),'K3 breaks'};

for c=1:size(cycs,1)
    xc = cycs{c,1}; dxc=[NaN; diff(xc)];
    Xe=[ones(T,1), lag1(xc), lag1(yhat_us_full), lag1(s_gap_full), lag1(dxc), yhat_us_full, s_gap_full, dln_pcom_full];
    ye=dxc; vv=~any(isnan([Xe ye]),2);
    [b,se,ts,R2,~,N]=ols_with_se(Xe(vv,:),ye(vv));
    b0=-b(2); b1=b(5);
    xcv=xc(vv); xcl=lag1(xc); xcl=xcl(vv); ar=corr(xcv,xcl);
    fprintf('\n== %s ==  N=%d R2=%.3f  cyc-level AR(1)=%.3f\n', cycs{c,2}, N, R2, ar);
    fprintf('   b0_x(ECM speed)=%+.4f (t %+.2f) | b1_x(AR)=%+.4f [|lambda|=sqrt(b1)=%.3f]\n', ...
        b0, ts(2), b1, sqrt(max(b1,0)));
end
fprintf('\nREF: HP-spec b1=0.867(|l|0.931); consistent-cyc 0.802; OECD-coint 0.742; wp1044 0.30.\nDONE.\n');
