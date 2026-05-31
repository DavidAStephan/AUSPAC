%% estimate_trade_ecm_refit.m — does b1_x collapse under a *consistent* ECM detrend?
% The model defines dln_x = Delta(cyclical export level), and b1_x multiplies that
% cyclical growth. The original estimate_trade_exports.m used RAW dln_x (trend
% included) for the LHS/AR term while HP-detrending only the EC level — an
% inconsistency that loads the secular openness drift onto b1. Here we compare
% internally-consistent specifications. wp1044 builds the long run from
% fundamentals (no HP, no deterministic trend on the SR eq); we test that too.
clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));
D = load(fullfile(projectdir, 'data', 'trade_price_data.mat'));
E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));
qkey = @(d) year(d)*10 + ceil(month(d)/3);

master_dates = D.vol_dates; T = numel(master_dates); mk = qkey(master_dates);
dln_x = D.dln_x; ln_x = log(D.x_vol);
est_start = M.meta.sample_start; n_est = numel(E.yhat_us);
est_dates = est_start + calquarters(0:n_est-1); ek = qkey(est_dates);
yhat_us_full = NaN(T,1);
for t=1:T, ix=find(ek==mk(t),1); if ~isempty(ix), yhat_us_full(t)=E.yhat_us(ix); end, end
twi_k = qkey(D.q_twi_dates); s_gap_full = NaN(T,1);
for t=1:T, ix=find(twi_k==mk(t),1); if ~isempty(ix), s_gap_full(t)=D.s_gap_proxy(ix); end, end
pcom_k = qkey(D.q_pcom_dates); dln_pcom_full = NaN(T,1);
for t=1:T, ix=find(pcom_k==mk(t),1); if ~isempty(ix), dln_pcom_full(t)=D.dln_pcom(ix); end, end

lag1 = @(x)[NaN; x(1:end-1)];

% HP cyclical level (as original) and its consistent first difference (model's dln_x)
ln_x_trend   = hp_filter(ln_x, 1600);
x_cyc        = (ln_x - ln_x_trend)*100;     % cyclical export level (model ln_x_level)
dx_cyc       = [NaN; diff(x_cyc)];          % cyclical export growth (model dln_x)
trend_t      = (1:T)';

fprintf('mean(raw dln_x)=%.4f  std=%.4f  AR1(raw)=%.3f | mean(dx_cyc)=%.4f AR1(cyc)=%.3f\n', ...
    mean(dln_x,'omitnan'), std(dln_x,'omitnan'), ar1(dln_x), mean(dx_cyc,'omitnan'), ar1(dx_cyc));

specs = {};
% S0: ORIGINAL (HP level for EC; RAW dln_x for LHS & AR)  -> should reproduce 0.867
specs{end+1} = struct('name','S0 original (raw growth, HP-EC)','y',dln_x, ...
    'X',[ones(T,1), lag1(x_cyc), lag1(yhat_us_full), lag1(s_gap_full), lag1(dln_x), yhat_us_full, s_gap_full, dln_pcom_full], ...
    'cols',{{'const','x_cyc(-1)','yus(-1)','sgap(-1)','dlnx(-1)','yus','sgap','dpcom'}},'levcol',2,'arcol',5);
% S1: CONSISTENT CYCLICAL (model-faithful: dx_cyc for LHS & AR, x_cyc for EC)
specs{end+1} = struct('name','S1 consistent cyclical (model dln_x)','y',dx_cyc, ...
    'X',[ones(T,1), lag1(x_cyc), lag1(yhat_us_full), lag1(s_gap_full), lag1(dx_cyc), yhat_us_full, s_gap_full, dln_pcom_full], ...
    'cols',{{'const','x_cyc(-1)','yus(-1)','sgap(-1)','dxcyc(-1)','yus','sgap','dpcom'}},'levcol',2,'arcol',5);
% S2: demeaned raw growth (cheap trend removal)
ddm = dln_x - mean(dln_x,'omitnan');
specs{end+1} = struct('name','S2 demeaned raw growth','y',ddm, ...
    'X',[ones(T,1), lag1(x_cyc), lag1(yhat_us_full), lag1(s_gap_full), lag1(ddm), yhat_us_full, s_gap_full, dln_pcom_full], ...
    'cols',{{'const','x_cyc(-1)','yus(-1)','sgap(-1)','dlnxdm(-1)','yus','sgap','dpcom'}},'levcol',2,'arcol',5);
% S3: pure ECM on RAW level + deterministic trend in the LR (user's "X->defined target incl trend")
specs{end+1} = struct('name','S3 raw level ECM + linear trend','y',dln_x, ...
    'X',[ones(T,1), lag1(ln_x*100), trend_t, lag1(yhat_us_full), lag1(s_gap_full), lag1(dln_x), yhat_us_full, s_gap_full, dln_pcom_full], ...
    'cols',{{'const','lnx(-1)','t','yus(-1)','sgap(-1)','dlnx(-1)','yus','sgap','dpcom'}},'levcol',2,'arcol',6);

for s=1:numel(specs)
    sp=specs{s}; X=sp.X; y=sp.y; valid=~any(isnan([X y]),2);
    [b,se,ts,R2,~,N]=ols_with_se(X(valid,:),y(valid));
    b0=-b(sp.levcol); b1=b(sp.arcol);
    fprintf('\n== %s ==  (N=%d, R2=%.3f)\n', sp.name, N, R2);
    for k=1:numel(sp.cols), fprintf('   %-12s %+8.4f  (se %.4f, t %+5.2f)\n', sp.cols{k}, b(k), se(k), ts(k)); end
    fprintf('   --> b0_x(ECM speed)=%+.4f  b1_x(AR)=%+.4f  [implied |lambda|=sqrt(b1)=%.3f]\n', b0, b1, sqrt(max(b1,0)));
end
fprintf('\nDONE.\n');

function r=ar1(x), x=x(~isnan(x)); r=corr(x(2:end),x(1:end-1)); end
function trend = hp_filter(y, lambda)
    n=numel(y); valid=~isnan(y);
    if sum(valid)<4, trend=NaN(n,1); return; end
    yv=y(valid); m=numel(yv); I=speye(m);
    Dm=spdiags([ones(m,1),-2*ones(m,1),ones(m,1)],0:2,m-2,m);
    A=I+lambda*(Dm'*Dm); tv=A\yv; trend=NaN(n,1); trend(valid)=tv;
end
