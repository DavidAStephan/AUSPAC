%% estimate_exports_fdgrowth.m — does adding a short-run FOREIGN-DEMAND GROWTH term
% (like imports' iad) lower b1_x?  Exports currently have only a (dead) contemp
% foreign GAP b2_x*yhat_us and no foreign-demand-growth driver, so b1 may be a
% catch-all. Test contemp + lagged dln_y_world (OECD real GDP growth).
clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));
D = load(fullfile(projectdir,'data','trade_price_data.mat'));
E = load(fullfile(projectdir,'dynare','estimation_data.mat'));
M = load(fullfile(projectdir,'dynare','estimation_meta.mat'));
W = readtable(fullfile(projectdir,'data','fred_OECDNAEXKP01IXOBSAQ.csv'));
qkey=@(d) year(d)*10+ceil(month(d)/3); lag1=@(x)[NaN; x(1:end-1)];
md=D.vol_dates; T=numel(md); mk=qkey(md); dln_x=D.dln_x; ln_X=log(D.x_vol)*100;
wk=qkey(datetime(W{:,1})); wln=log(W{:,2})*100;
ln_y_world=NaN(T,1); for t=1:T, ix=find(wk==mk(t),1); if ~isempty(ix), ln_y_world(t)=wln(ix); end, end
dln_y_world=[NaN; diff(ln_y_world)];
es=M.meta.sample_start; ne=numel(E.yhat_us); ed=es+calquarters(0:ne-1); ek=qkey(ed);
yus=NaN(T,1); for t=1:T, ix=find(ek==mk(t),1); if ~isempty(ix), yus(t)=E.yhat_us(ix); end, end
tk=qkey(D.q_twi_dates); sg=NaN(T,1); for t=1:T, ix=find(tk==mk(t),1); if ~isempty(ix), sg(t)=D.s_gap_proxy(ix); end, end
pk=qkey(D.q_pcom_dates); dpc=NaN(T,1); for t=1:T, ix=find(pk==mk(t),1); if ~isempty(ix), dpc(t)=D.dln_pcom(ix); end, end

% K2 piecewise-trend cyclical export (best-specified level from trend-break run)
ev=~isnan(ln_X)&~isnan(yus)&~isnan(sg)&~isnan(dpc); idx=find(ev); s0=idx(1); s1=idx(end);
y=ln_X(s0:s1); tt=(1:numel(y))'; n=numel(y);
fitpw=@(taus) deal_fit(y,tt,taus);
minseg=8; best=inf; bt=[];
for a=minseg:(n-2*minseg), for c=(a+minseg):(n-minseg)
  X=[ones(n,1),tt,max(0,tt-a),max(0,tt-c)]; r=y-X*(X\y); s=r'*r; if s<best,best=s;bt=[a c];end
end,end
Xb=[ones(n,1),tt,max(0,tt-bt(1)),max(0,tt-bt(2))]; resb=y-Xb*(Xb\y);
xc=[nan(s0-1,1);resb;nan(T-s1,1)]; dxc=[NaN;diff(xc)];

base=[ones(T,1), lag1(xc), lag1(yus), lag1(sg), lag1(dxc), yus, sg, dpc];
basenm={'const','xc(-1)','yus(-1)','sgap(-1)','dxc(-1)','yus','sgap','dpcom'};
variants={ 'A baseline (no fd-growth)', base, basenm; ...
  'B +dln_y_world contemp', [base, dln_y_world], [basenm,{'dlnYw'}]; ...
  'C +dln_y_world contemp+lag', [base, dln_y_world, lag1(dln_y_world)], [basenm,{'dlnYw','dlnYw(-1)'}]; ...
  'D +dlnYw, drop dead yus', [ones(T,1), lag1(xc), lag1(sg), lag1(dxc), sg, dpc, dln_y_world, lag1(dln_y_world)], ...
       {'const','xc(-1)','sgap(-1)','dxc(-1)','sgap','dpcom','dlnYw','dlnYw(-1)'} };

for vix=1:size(variants,1)
  X=variants{vix,2}; nm=variants{vix,3}; ye=dxc; vv=~any(isnan([X ye]),2);
  [b,se,ts,R2,~,N]=ols_with_se(X(vv,:),ye(vv));
  arc=find(strcmp(nm,'dxc(-1)')); b1=b(arc);
  fprintf('\n== %s ==  N=%d R2=%.3f\n', variants{vix,1}, N, R2);
  for k=1:numel(nm)
    star=''; if any(strcmp(nm{k},{'dlnYw','dlnYw(-1)','dxc(-1)'})), star=' <--'; end
    fprintf('   %-11s %+8.4f (t %+5.2f)%s\n', nm{k}, b(k), ts(k), star);
  end
  fprintf('   b1_x=%+.4f [|lambda|=%.3f]\n', b1, sqrt(max(b1,0)));
end
fprintf('\nDONE.\n');

function r = deal_fit(~,~,~), r=0; end
