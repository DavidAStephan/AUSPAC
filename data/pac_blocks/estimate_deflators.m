%% estimate_deflators.m — single-equation OLS for AU deflators
%
% Estimates the following AR(1)+drivers equations:
%   pi_x = rho_px*pi_x(-1) + alpha_px*piQ + (1-rho_px-alpha_px)*pibar_au
%          + beta_px*s_gap + alpha_pcom*dln_pcom + eps_px
%   pi_m = rho_pm*pi_m(-1) + alpha_pm*piQ + beta_pm*s_gap + beta_pm_com*dln_pcom
%          + (1-rho_pm-alpha_pm)*pibar_au + eps_pm
%   pi_ib = rho_pib*pi_ib(-1) + alpha_pib*piQ + beta_pib_m*pi_m
%          + (1-rho_pib-alpha_pib-beta_pib_m)*pibar_au + eps_pib    (ECM dropped: no p*_IB)
%   pi_ih = rho_pih*pi_ih(-1) + alpha_pih*piQ + beta_pih_m*pi_m
%          + (1-rho_pih-alpha_pih-beta_pih_m)*pibar_au + eps_pih    (ECM dropped)
%   pi_g = rho_pg*pi_g(-1) + alpha_pg*(pi_w - dln_prod)
%          + (1-rho_pg-alpha_pg)*pibar_au + eps_pg
%
% All OLS use AU sample where data exists. ECM ECM_pib / ECM_pih terms left at
% wp1044 calibration (would need p*_IB / p*_IH structural targets — not in pipeline).

clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

D = load(fullfile(projectdir, 'data', 'trade_price_data.mat'));
E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));
L = load(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));

qkey = @(d) year(d)*10 + ceil(month(d)/3);

% Master sample: IPD dates (longest deflator sample, 1960..2025)
master = D.ipd_dates;
T = numel(master);
mk = qkey(master);

%% Demean trend
pi_x_full   = D.pi_x_obs;   % already % q/q
pi_m_full   = D.pi_m_obs;
pi_g_full   = D.pi_g_obs;
pi_ib_full  = D.pi_ib_obs;
pi_ih_full  = D.pi_ih_obs;
pi_q_full   = D.pi_q_obs;

% pibar_au = HP trend of consumer-price inflation. Use L2's pi_au_trend if
% sample matches; else use HP of pi_q_obs as a proxy.
pibar_proxy = hp_filter(pi_q_full, 1600);

% piQ from L2 (supply-based VA price); align to IPD master by qkey
piQ_full = NaN(T,1);
L_dates = L.dates;
lk = qkey(L_dates);
for t=1:T
    ix = find(lk==mk(t),1);
    if ~isempty(ix), piQ_full(t) = L.piQ(ix); end
end

% s_gap, dln_pcom aligned to master
twi_k = qkey(D.q_twi_dates);
s_gap_full = NaN(T,1);
for t=1:T
    ix = find(twi_k==mk(t),1);
    if ~isempty(ix), s_gap_full(t) = D.s_gap_proxy(ix); end
end
pcom_k = qkey(D.q_pcom_dates);
dln_pcom_full = NaN(T,1);
for t=1:T
    ix = find(pcom_k==mk(t),1);
    if ~isempty(ix), dln_pcom_full(t) = D.dln_pcom(ix); end
end

% pi_w from estimation_data
est_start = M.meta.sample_start;
n_est = numel(E.pi_w);
est_dates = est_start + calquarters(0:n_est-1);
ek = qkey(est_dates);
pi_w_full = NaN(T,1);
for t=1:T
    ix = find(ek==mk(t),1);
    if ~isempty(ix), pi_w_full(t) = E.pi_w(ix); end
end

% dln_prod — from supply data: log-diff of (q_total / n_total)
prod_lvl = S.q_total_lvl ./ S.n_total_lvl;
% supply_data dates: align by index — supply has 140 obs starting 1990Q1
% supply_data.dates exists?
if isfield(S,'dates')
    sk = qkey(S.dates);
else
    % Construct: starts 1990Q1
    sdates = datetime(1990,1,1) + calquarters(0:numel(prod_lvl)-1);
    sk = qkey(sdates);
end
dln_prod_arr = [NaN; diff(log(prod_lvl))*100];
dln_prod_full = NaN(T,1);
for t=1:T
    ix = find(sk==mk(t),1);
    if ~isempty(ix), dln_prod_full(t) = dln_prod_arr(ix); end
end

lag1 = @(x) [NaN; x(1:end-1)];

%% Helper: run a single deflator OLS
function [b,se,tstat,R2,N,names] = run_olseq(yvec, regs, regnames)
    valid = ~any(isnan([regs, yvec]),2);
    [b,se,tstat,R2,~,N] = ols_with_se(regs(valid,:), yvec(valid));
    names = regnames;
end

%% pi_x OLS
% pi_x = rho_px*pi_x(-1) + alpha_px*piQ + (1-rho_px-alpha_px)*pibar
%        + beta_px*s_gap + alpha_pcom*dln_pcom
% Reform: pi_x - pibar = rho_px*(pi_x(-1) - pibar) + alpha_px*(piQ - pibar)
%                       + beta_px*s_gap + alpha_pcom*dln_pcom
yx = pi_x_full - pibar_proxy;
Xx = [lag1(yx), piQ_full - pibar_proxy, s_gap_full, dln_pcom_full];
namesX = {'pi_x(-1) gap', 'piQ gap', 's_gap', 'dln_pcom'};
[bx,sex,tx,R2x,Nx] = run_olseq_local(yx, Xx);
print_block('pi_x', bx, sex, tx, namesX, R2x, Nx, ...
    {'rho_px (0.21)', 'alpha_px (0.20)', 'beta_px (-0.05)', 'alpha_pcom (0.10)'});

%% pi_m OLS (aggregate; assigned to pi_m_ne)
ym = pi_m_full - pibar_proxy;
Xm = [lag1(ym), piQ_full - pibar_proxy, s_gap_full, dln_pcom_full];
namesM = {'pi_m(-1) gap', 'piQ gap', 's_gap', 'dln_pcom'};
[bm,sem,tm,R2m,Nm] = run_olseq_local(ym, Xm);
print_block('pi_m', bm, sem, tm, namesM, R2m, Nm, ...
    {'rho_pm (0.28)', 'alpha_pm (0.38)', 'beta_pm (0.09)', 'beta_pm_com (0.42)'});

%% pi_ib OLS (no ECM)
yib = pi_ib_full - pibar_proxy;
Xib = [lag1(yib), piQ_full - pibar_proxy, pi_m_full - pibar_proxy];
namesIB = {'pi_ib(-1) gap', 'piQ gap', 'pi_m gap'};
[bib,seib,tib,R2ib,Nib] = run_olseq_local(yib, Xib);
print_block('pi_ib', bib, seib, tib, namesIB, R2ib, Nib, ...
    {'rho_pib (0.70)', 'alpha_pib (0.19)', 'beta_pib_m (0.12)'});

%% pi_ih OLS (no ECM)
yih = pi_ih_full - pibar_proxy;
Xih = [lag1(yih), piQ_full - pibar_proxy, pi_m_full - pibar_proxy];
namesIH = {'pi_ih(-1) gap', 'piQ gap', 'pi_m gap'};
[bih,seih,tih,R2ih,Nih] = run_olseq_local(yih, Xih);
print_block('pi_ih', bih, seih, tih, namesIH, R2ih, Nih, ...
    {'rho_pih (0.49)', 'alpha_pih (0.40)', 'beta_pih_m (0.08)'});

%% pi_g OLS
% pi_g = rho_pg*pi_g(-1) + alpha_pg*(pi_w - dln_prod) + (1-rho_pg-alpha_pg)*pibar
% Reform: pi_g - pibar = rho_pg*(pi_g(-1)-pibar) + alpha_pg*(pi_w-dln_prod-pibar)
ulc = pi_w_full - dln_prod_full;
yg = pi_g_full - pibar_proxy;
Xg = [lag1(yg), ulc - pibar_proxy];
namesG = {'pi_g(-1) gap', 'ULC gap'};
[bg,seg,tg,R2g,Ng] = run_olseq_local(yg, Xg);
print_block('pi_g', bg, seg, tg, namesG, R2g, Ng, ...
    {'rho_pg (0.13)', 'alpha_pg (0.37)'});

%% Save
out.pi_x = struct('b',bx,'se',sex,'tstat',tx,'R2',R2x,'N',Nx);
out.pi_m = struct('b',bm,'se',sem,'tstat',tm,'R2',R2m,'N',Nm);
out.pi_ib = struct('b',bib,'se',seib,'tstat',tib,'R2',R2ib,'N',Nib);
out.pi_ih = struct('b',bih,'se',seih,'tstat',tih,'R2',R2ih,'N',Nih);
out.pi_g = struct('b',bg,'se',seg,'tstat',tg,'R2',R2g,'N',Ng);
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_deflators.mat'), '-struct', 'out');
fprintf('\nWrote results_deflators.mat\n');

%% local helpers
function [b,se,tstat,R2,N] = run_olseq_local(y, X)
    valid = ~any(isnan([X, y]),2);
    [b,se,tstat,R2,~,N] = ols_with_se(X(valid,:), y(valid));
end

function print_block(name, b, se, tstat, regnames, R2, N, structnames)
    fprintf('\n=== %s OLS ===\n', name);
    fprintf('%-20s  %10s  %10s  %8s  | maps to %s\n', 'regressor', 'estimate', 'se', 't', 'structural');
    for k=1:numel(regnames)
        fprintf('%-20s  %10.4f  %10.4f  %8.2f  | %s\n', regnames{k}, b(k), se(k), tstat(k), structnames{k});
    end
    fprintf('R^2 = %.4f, N = %d\n', R2, N);
end

function trend = hp_filter(y, lambda)
    n = numel(y); valid = ~isnan(y);
    if sum(valid) < 4, trend = NaN(n,1); return; end
    yv = y(valid); m = numel(yv);
    I = speye(m);
    D = spdiags([ones(m,1), -2*ones(m,1), ones(m,1)], 0:2, m-2, m);
    A = I + lambda * (D' * D);
    tv = A \ yv;
    trend = NaN(n,1); trend(valid) = tv;
end
