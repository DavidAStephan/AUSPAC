%% estimate_exports_tradingpartner.m — Phase 1 decision gate
% Re-estimate the AU export ECM with a PROPER cointegrating target:
%   ln_X ~ beta_x * ln_y_world + gamma_x * s_gap          (long run, both I(1)/trending)
%   dln_x = b0*(target - ln_X)(-1) + b1*dln_x(-1) + b2*yhat_us + b3*s_gap + b4*dln_pcom
% No HP filter: the error-correction term does the detrending (X reverts to a
% defined, trending fundamentals target). ln_y_world = log OECD real GDP index.
% Decision gate: does b1 drop to a non-oscillatory level (sqrt(b1) < ~0.85) WITH
% a valid cointegrating relationship (b0 sig. negative-feedback, sensible beta>0)?
clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));
D = load(fullfile(projectdir, 'data', 'trade_price_data.mat'));
E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));
W = readtable(fullfile(projectdir, 'data', 'fred_OECDNAEXKP01IXOBSAQ.csv'));
qkey = @(d) year(d)*10 + ceil(month(d)/3);

master_dates = D.vol_dates; T = numel(master_dates); mk = qkey(master_dates);
dln_x = D.dln_x; ln_X = log(D.x_vol)*100;

% world GDP (OECD real index) -> log*100, aligned by quarter
wk = qkey(datetime(W{:,1})); wln = log(W{:,2})*100;
ln_y_world = NaN(T,1);
for t=1:T, ix=find(wk==mk(t),1); if ~isempty(ix), ln_y_world(t)=wln(ix); end, end

est_start = M.meta.sample_start; n_est = numel(E.yhat_us);
est_dates = est_start + calquarters(0:n_est-1); ek = qkey(est_dates);
yhat_us_full = NaN(T,1);
for t=1:T, ix=find(ek==mk(t),1); if ~isempty(ix), yhat_us_full(t)=E.yhat_us(ix); end, end
twi_k = qkey(D.q_twi_dates); s_gap_full = NaN(T,1);
for t=1:T, ix=find(twi_k==mk(t),1); if ~isempty(ix), s_gap_full(t)=D.s_gap_proxy(ix); end, end
pcom_k = qkey(D.q_pcom_dates); dln_pcom_full = NaN(T,1);
for t=1:T, ix=find(pcom_k==mk(t),1); if ~isempty(ix), dln_pcom_full(t)=D.dln_pcom(ix); end, end
lag1 = @(x)[NaN; x(1:end-1)];

%% (a) Static cointegration regression: ln_X = c + beta*ln_y_world + gamma*s_gap
Xc = [ones(T,1), ln_y_world, s_gap_full]; yc = ln_X;
v = ~any(isnan([Xc yc]),2);
[bc,sec,tc,R2c,~,Nc] = ols_with_se(Xc(v,:), yc(v));
resid = NaN(T,1); resid(v) = yc(v) - Xc(v,:)*bc;
% Engle-Granger: ADF-style on residual via Delta r = rho*r(-1) + lags
dr = [NaN; diff(resid)];
egX = [resid, lag1(dr)]; egX = [ones(T,1) egX];
ve = ~any(isnan([egX dr]),2);
[beg,seeg,teg] = ols_with_se(egX(ve,:), dr(ve));
fprintf('=== (a) Static cointegration ln_X ~ ln_y_world + s_gap ===\n');
fprintf('  beta (world GDP) = %+.3f (t %.2f) | gamma (s_gap) = %+.3f (t %.2f) | R2=%.3f N=%d\n', ...
    bc(2),tc(2),bc(3),tc(3),R2c,Nc);
fprintf('  EG residual ADF t (rho on r(-1)) = %.2f  [more negative than ~-3.4 => cointegrated]\n', teg(2));
rr = resid; rl = lag1(resid); okr = ~isnan(rr) & ~isnan(rl);
fprintf('  resid AR(1) = %.3f\n', corr(rr(okr), rl(okr)));

%% (b) One-step ECM (Banerjee): recover b0,b1,beta,gamma
Xe = [ones(T,1), lag1(ln_X), lag1(ln_y_world), lag1(s_gap_full), lag1(dln_x), yhat_us_full, s_gap_full, dln_pcom_full];
ye = dln_x; vv = ~any(isnan([Xe ye]),2);
[b,se,ts,R2,~,N] = ols_with_se(Xe(vv,:), ye(vv));
nm={'const','lnX(-1)','lnYworld(-1)','sgap(-1)','dlnx(-1)','yhat_us','s_gap','dln_pcom'};
fprintf('\n=== (b) One-step ECM (no HP; cointegrating target) ===  N=%d R2=%.3f\n', N, R2);
for k=1:numel(nm), fprintf('   %-13s %+9.4f  (se %.4f, t %+5.2f)\n', nm{k}, b(k), se(k), ts(k)); end
phi = b(2); b0 = -phi; b1 = b(5);
beta_x = -b(3)/phi; gamma_x = -b(4)/phi;
fprintf('\n   b0_x (ECM speed)= %+.4f  (phi t=%.2f; sig. negative => error-correcting)\n', b0, ts(2));
fprintf('   b1_x (AR)       = %+.4f   [implied |lambda|=sqrt(b1)=%.3f]\n', b1, sqrt(max(b1,0)));
fprintf('   beta_x (LR world-GDP elast) = %+.3f   gamma_x (LR s_gap) = %+.3f\n', beta_x, gamma_x);
fprintf('\n   COMPARISON: old HP-spec b1_x=0.867 (|lambda|=0.931). wp1044 ref b1=0.30.\n');
fprintf('DONE.\n');
