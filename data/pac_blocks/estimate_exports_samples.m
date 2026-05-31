%% estimate_exports_samples.m — is b1_x a boom-era artifact or stable across samples?
clc; projectdir='/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir,'data','pac_helpers'));
D=load(fullfile(projectdir,'data','trade_price_data.mat'));
E=load(fullfile(projectdir,'dynare','estimation_data.mat'));
M=load(fullfile(projectdir,'dynare','estimation_meta.mat'));
qkey=@(d) year(d)*10+ceil(month(d)/3); lag1=@(x)[NaN; x(1:end-1)];
md=D.vol_dates; T=numel(md); mk=qkey(md); dln_x=D.dln_x; ln_X=log(D.x_vol)*100;
es=M.meta.sample_start; ne=numel(E.yhat_us); ed=es+calquarters(0:ne-1); ek=qkey(ed);
yus=NaN(T,1); for t=1:T, ix=find(ek==mk(t),1); if ~isempty(ix), yus(t)=E.yhat_us(ix); end, end
tk=qkey(D.q_twi_dates); sg=NaN(T,1); for t=1:T, ix=find(tk==mk(t),1); if ~isempty(ix), sg(t)=D.s_gap_proxy(ix); end, end
pk=qkey(D.q_pcom_dates); dpc=NaN(T,1); for t=1:T, ix=find(pk==mk(t),1); if ~isempty(ix), dpc(t)=D.dln_pcom(ix); end, end
trend=hp_trend(ln_X,1600); xc=ln_X-trend; dxc=[NaN;diff(xc)];
yr=year(md);
samples={'1993-2019 (full ECM)',[1993 2019]; '1993-2007 (pre-GFC/boom)',[1993 2007]; ...
  '2008-2019 (post-GFC)',[2008 2019]; '2003-2015 (mining boom core)',[2003 2015]; ...
  '1993-2019 excl 2008-09 GFC',[1993 2019]};
fprintf('\n%-30s  N   rawAR1(dxc)   ECM b1_x   |lambda|\n','sample');
for s=1:size(samples,1)
  rng=samples{s,2}; in= yr>=rng(1)&yr<=rng(2);
  if s==5, in=in & ~(yr>=2008&yr<=2009); end
  X=[ones(T,1), lag1(xc), lag1(dxc), yus, sg, dpc]; ye=dxc;
  vv=~any(isnan([X ye]),2) & in;
  [b,~,~,~,~,N]=ols_with_se(X(vv,:),ye(vv));
  dd=dxc; dl=lag1(dxc); ok=~isnan(dd)&~isnan(dl)&in; ar=corr(dd(ok),dl(ok));
  fprintf('%-30s  %3d   %6.3f      %6.3f    %5.3f\n', samples{s,1}, N, ar, b(3), sqrt(max(b(3),0)));
end
fprintf('\nDONE.\n');
function tr=hp_trend(y,lam)
  n=numel(y); v=~isnan(y); yv=y(v); m=numel(yv); I=speye(m);
  Dm=spdiags([ones(m,1),-2*ones(m,1),ones(m,1)],0:2,m-2,m); A=I+lam*(Dm'*Dm);
  tv=A\yv; tr=NaN(n,1); tr(v)=tv;
end
