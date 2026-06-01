%% prepare_supply_data_sector.m
% Industry-split Phase 0 (GATE 1a input): assemble NON-MINING-MARKET and
% MINING supply-side series and write them into supply_data_sector.mat, in
% the same log-level convention as prepare_supply_data.m / supply_data.mat,
% so estimate_ces_2026_sector.m can run the FR-BDF wp1044 CES procedure
% per-sector (spec §3.4 + §4.1).
%
% Sources (all already produced by the Phase-0 data tasks):
%   Q_mining, Q_nonmining_market : data/market_sector_gva_splits.csv
%       (FIXED build_market_sector_capital.py; SA $M chain-volume LEVELS.
%        q_nonmining_market = q_market - q_mining = q_total - mining - nonmarket,
%        i.e. the ~72% non-mining-MARKET branch, non-market already removed.)
%   K_mining, K_nonmining_market : data/market_sector_capital.csv
%       (annual chain-volume; K_mining = ABS 5204 T63 col 12;
%        K_nonmining_market = K_market - K_mining. Interpolated to quarterly
%        on the fiscal-year-Q2 convention, matching prepare_supply_data.m.)
%   N, H (mining + total)        : data/abs_rba/abs_labour_acct_q_mining_total_sa.csv
%       (ABS Labour Account quarterly SA; MEASURE M19=employment ('000 persons),
%        M28=hours actually worked ('000 hrs). IND B=mining, TOTAL=all industries.
%        Non-mining N = TOTAL - B; non-mining H/worker = non-mining hrs / non-mining emp.)
%   P_Q, W, delta_q              : reused from dynare/supply_data.mat
%       (NO sector VA deflator exists -- see Phase-0 download task FAIL. The
%        mining VA deflator is the AUD commodity price (handled in the model's
%        deflator block off dln_pcom), NOT a regressed series. For the CES
%        calibration we use the aggregate GDP IPD as the P_Q proxy for the
%        non-mining branch and FLAG it. This does not affect sigma_nm/gamma_nm:
%        sigma uses the real EFFICIENT wage W/(P_Q*Phi*H), and a level/scale
%        proxy in P_Q only shifts the intercept b_0, not the slope -sigma.)
%
% Output: dynare/supply_data_sector.mat
%   q_nm_lvl, k_nm_lvl, n_nm_lvl, h_nm_lvl, p_q_nm_lvl   (non-mining MARKET)
%   q_m_lvl,  k_m_lvl,  n_m_lvl,  h_m_lvl                 (mining)
%   + dates, nQ, delta_q, wpi_lvl, awe_lvl (carried for the wage proxy)
%   + diagnostic shares.

clear; clc;
fprintf('=== Industry-split Phase 0: per-sector supply-data preparation ===\n\n');

datadir    = fullfile(fileparts(mfilename('fullpath')));            % data/
absdir     = fullfile(datadir, 'abs_rba');
projectdir = fullfile(datadir, '..');

%% Master quarterly date grid: 1990Q1 .. 2025Q4
% (gva splits start 1974Q3, labour account 1994Q3; the non-mining CES sample
%  is driven by labour-account overlap >=120 quarters.)
qstart = datetime(1990, 1, 1);
qend   = datetime(2025, 10, 1);
dates_q = (qstart:calmonths(3):qend)';
nQ = length(dates_q);
fprintf('Master grid: %d quarters, %s to %s\n\n', nQ, ...
    datestr(dates_q(1)), datestr(dates_q(end)));

%% ------------------------------------------------------------
%% 1. Sector GVA (quarterly chain-volume SA $M levels) from the FIXED splits CSV
%% ------------------------------------------------------------
fprintf('1. Reading market_sector_gva_splits.csv (FIXED) ...\n');
G = readtable(fullfile(datadir, 'market_sector_gva_splits.csv'), ...
    'TextType', 'string');
% Date column is YYYY-MM-01 with quarter months 03/06/09/12.
gdates = datetime(G.date);
q_mining_full = G.q_mining;
q_nm_full     = G.q_nonmining_market;
q_total_full  = G.q_total;

q_mining = align_to_q(gdates, q_mining_full, dates_q);
q_nm     = align_to_q(gdates, q_nm_full,     dates_q);
q_total  = align_to_q(gdates, q_total_full,  dates_q);
fprintf('   q_mining          : %d valid obs (range $%.0f - $%.0fM)\n', ...
    sum(~isnan(q_mining)), min(q_mining), max(q_mining));
fprintf('   q_nonmining_market: %d valid obs (range $%.0f - $%.0fM)\n', ...
    sum(~isnan(q_nm)), min(q_nm), max(q_nm));

%% ------------------------------------------------------------
%% 2. Sector capital (annual chain-volume) -> quarterly (FY-Q2 interp)
%% ------------------------------------------------------------
fprintf('\n2. Reading market_sector_capital.csv ...\n');
C = readtable(fullfile(datadir, 'market_sector_capital.csv'));
% year column -> fiscal-year-end aligned at Q2 of that calendar year (matches
% prepare_supply_data.m interp_annual_q2 convention).
kyears = C.year;
k_mining_ann = C.k_mining;
k_nm_ann     = C.k_nonmining_market;

k_mining_q = interp_annual_q2(kyears, k_mining_ann, dates_q, nQ);
k_nm_q     = interp_annual_q2(kyears, k_nm_ann,     dates_q, nQ);
fprintf('   K_mining quarterly          : %d valid obs\n', sum(~isnan(k_mining_q)));
fprintf('   K_nonmining_market quarterly: %d valid obs\n', sum(~isnan(k_nm_q)));

%% ------------------------------------------------------------
%% 3. Sector labour (ABS Labour Account quarterly SA): N and H
%% ------------------------------------------------------------
fprintf('\n3. Reading abs_labour_acct_q_mining_total_sa.csv ...\n');
L = readtable(fullfile(absdir, 'abs_labour_acct_q_mining_total_sa.csv'), ...
    'TextType', 'string');
% TIME_PERIOD like "1994-Q3"; MEASURE M19 (emp, '000 persons), M28 (hrs, '000 hrs)
ldates = quarter_str_to_datetime(L.TIME_PERIOD);

% employment ('000 persons)
emp_m_full = pick_series(L, ldates, 'M19', 'B');
emp_t_full = pick_series(L, ldates, 'M19', 'TOTAL');
% hours ('000 hours actually worked)
hrs_m_full = pick_series(L, ldates, 'M28', 'B');
hrs_t_full = pick_series(L, ldates, 'M28', 'TOTAL');

uld = unique(ldates);
emp_m = align_to_q(uld, emp_m_full, dates_q);
emp_t = align_to_q(uld, emp_t_full, dates_q);
hrs_m = align_to_q(uld, hrs_m_full, dates_q);
hrs_t = align_to_q(uld, hrs_t_full, dates_q);

% Non-mining = TOTAL - mining (exact residual; the spec's "non-mining N ~ total"
% fallback is NOT needed because the Labour Account gives mining by division).
emp_nm = emp_t - emp_m;
hrs_nm = hrs_t - hrs_m;

% Hours PER WORKER (the H input to the CES; matches prepare_supply_data.m
% h_per_worker = total_hours / employed_persons).
h_m_pw  = hrs_m  ./ emp_m;
h_nm_pw = hrs_nm ./ emp_nm;

mining_emp_share = emp_m ./ emp_t;
mining_hrs_share = hrs_m ./ hrs_t;
fprintf('   mining employment: %d obs, share latest=%.4f mean=%.4f\n', ...
    sum(~isnan(emp_m)), mining_emp_share(find(~isnan(mining_emp_share),1,'last')), ...
    mean(mining_emp_share,'omitnan'));
fprintf('   mining hours     : %d obs, share latest=%.4f mean=%.4f\n', ...
    sum(~isnan(hrs_m)), mining_hrs_share(find(~isnan(mining_hrs_share),1,'last')), ...
    mean(mining_hrs_share,'omitnan'));

%% ------------------------------------------------------------
%% 4. VA deflator + wage proxies (reused from supply_data.mat)
%%    NO sector VA deflator -> use aggregate GDP IPD as P_Q proxy and FLAG.
%% ------------------------------------------------------------
fprintf('\n4. Loading P_Q / W / delta proxies from supply_data.mat ...\n');
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
% supply_data.mat is on the 1990Q1..2024Q4 grid; remap onto our grid by date.
p_q_proxy = remap_by_date(S.dates, S.p_q_total_lvl, dates_q);   % log GDP IPD
wpi_lvl   = remap_by_date(S.dates, S.wpi_lvl,        dates_q);   % log WPI (SA)
awe_lvl   = remap_by_date(S.dates, S.awe_lvl,        dates_q);   % log AWE (trend)
delta_q   = remap_by_date(S.dates, S.delta_q,        dates_q);
% extrapolate delta_q forward (flat) for 2025 quarters that supply_data lacks
last_delta = find(~isnan(delta_q), 1, 'last');
if ~isempty(last_delta)
    delta_q(last_delta+1:end) = delta_q(last_delta);
end
fprintf('   P_Q proxy (GDP IPD, log): %d valid obs  [FLAG: aggregate, not sector]\n', ...
    sum(~isnan(p_q_proxy)));
fprintf('   WPI (log) SA: %d obs;  AWE (log): %d obs;  delta_q: %d obs\n', ...
    sum(~isnan(wpi_lvl)), sum(~isnan(awe_lvl)), sum(~isnan(delta_q)));

%% ------------------------------------------------------------
%% 5. Build log-levels and assemble output struct
%% ------------------------------------------------------------
out = struct();
out.dates = dates_q;
out.nQ    = nQ;

% Non-mining MARKET branch
out.q_nm_lvl   = log(q_nm);
out.k_nm_lvl   = log(k_nm_q);
out.n_nm_lvl   = log(emp_nm);
out.h_nm_lvl   = log(h_nm_pw);
out.p_q_nm_lvl = p_q_proxy;          % FLAG: aggregate GDP IPD proxy

% Mining branch
out.q_m_lvl    = log(q_mining);
out.k_m_lvl    = log(k_mining_q);
out.n_m_lvl    = log(emp_m);
out.h_m_lvl    = log(h_m_pw);
out.p_q_m_lvl  = p_q_proxy;          % FLAG: mining deflator is commodity price; proxy only

% Shared wage / depreciation / diagnostics
out.wpi_lvl  = wpi_lvl;
out.awe_lvl  = awe_lvl;
out.delta_q  = delta_q;
out.mining_emp_share = mining_emp_share;
out.mining_hrs_share = mining_hrs_share;

% raw $-levels (handy for downstream gamma diagnostics)
out.q_nm_level = q_nm;  out.q_m_level = q_mining;
out.k_nm_level = k_nm_q; out.k_m_level = k_mining_q;
out.n_nm_level = emp_nm; out.n_m_level = emp_m;

%% ------------------------------------------------------------
%% 6. GATE-0 / sanity checks (report, do not abort the save)
%% ------------------------------------------------------------
fprintf('\n--- GATE-0 sanity (per-sector) ---\n');
% common-sample count for the non-mining CES (the binding sample)
common_nm = ~isnan(out.q_nm_lvl) & ~isnan(out.k_nm_lvl) & ...
            ~isnan(out.n_nm_lvl) & ~isnan(out.h_nm_lvl) & ...
            ~isnan(wpi_lvl) & ~isnan(p_q_proxy);
common_m  = ~isnan(out.q_m_lvl) & ~isnan(out.k_m_lvl) & ...
            ~isnan(out.n_m_lvl) & ~isnan(out.h_m_lvl);
fprintf('  non-mining common-sample quarters (Q,K,N,H,W,P_Q): %d\n', sum(common_nm));
fprintf('  mining common-sample quarters     (Q,K,N,H):       %d\n', sum(common_m));
fprintf('  q_mining>0 over valid: %d/%d\n', ...
    sum(q_mining(~isnan(q_mining))>0), sum(~isnan(q_mining)));
fprintf('  q_nonmining_market>0 over valid: %d/%d\n', ...
    sum(q_nm(~isnan(q_nm))>0), sum(~isnan(q_nm)));

% gamma diagnostics (2019 base, matches estimate_ces_2026)
b19 = year(dates_q)==2019;
g_nm = exp(mean(out.q_nm_lvl(b19 & common_nm) - out.k_nm_lvl(b19 & common_nm)));
g_m  = exp(mean(out.q_m_lvl(b19 & common_m)  - out.k_m_lvl(b19 & common_m)));
fprintf('  gamma_nm (Q_nm/K_nm, 2019) = %.4f\n', g_nm);
fprintf('  gamma_m  (Q_m /K_m , 2019) = %.4f\n', g_m);

savefile = fullfile(projectdir, 'dynare', 'supply_data_sector.mat');
save(savefile, '-struct', 'out');
fprintf('\nSaved to %s\n', savefile);
fprintf('=== Done ===\n');

%% ---------- helper functions ----------
function dt = quarter_str_to_datetime(s)
    s = string(s);
    dt = NaT(numel(s),1);
    for i = 1:numel(s)
        parts = split(s(i), '-Q');
        if numel(parts) == 2
            yr = str2double(parts(1));
            qq = str2double(parts(2));
            dt(i) = datetime(yr, (qq-1)*3 + 1, 1);
        end
    end
end

function v = pick_series(T, dts, measure, ind)
    % Return the OBS_VALUE for (MEASURE,IND) aligned to unique(dts).
    mask = (string(T.MEASURE) == measure) & (string(T.LABOURACCT_IND) == ind);
    md = dts(mask);
    mv = T.OBS_VALUE(mask);
    ud = unique(dts);
    v = nan(numel(ud),1);
    for i = 1:numel(ud)
        j = find(md == ud(i), 1);
        if ~isempty(j), v(i) = mv(j); end
    end
end

function v_q = align_to_q(d_in, v_in, dates_q)
    v_q = nan(length(dates_q),1);
    for i = 1:length(dates_q)
        yr = year(dates_q(i)); qq = quarter(dates_q(i));
        idx = year(d_in)==yr & quarter(d_in)==qq;
        if any(idx), v_q(i) = mean(v_in(idx),'omitnan'); end
    end
end

function k_q = interp_annual_q2(years_in, k_annual, dates_q, nQ)
    % Annual series aligned at fiscal-year Q2, linearly interpolated to quarterly
    % (identical convention to prepare_supply_data.m interp_annual_q2).
    k_q = nan(nQ,1);
    for i = 1:length(years_in)
        yr = years_in(i);
        idx = find(year(dates_q)==yr & quarter(dates_q)==2, 1);
        if ~isempty(idx) && ~isnan(k_annual(i)), k_q(idx) = k_annual(i); end
    end
    nan_idx = isnan(k_q);
    v_idx = find(~nan_idx);
    if length(v_idx) >= 2
        k_q(nan_idx) = interp1(v_idx, k_q(v_idx), find(nan_idx), 'linear', 'extrap');
    end
end

function v_out = remap_by_date(d_src, v_src, dates_q)
    v_out = nan(length(dates_q),1);
    for i = 1:length(dates_q)
        j = find(year(d_src)==year(dates_q(i)) & quarter(d_src)==quarter(dates_q(i)), 1);
        if ~isempty(j), v_out(i) = v_src(j); end
    end
end
