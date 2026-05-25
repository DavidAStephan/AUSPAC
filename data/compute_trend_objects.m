%% compute_trend_objects.m  --  block-specific trend objects for wp1044 PAC blocks
%
% Phase L1.2 of the FR-BDF wp1044 replication (refactor/frbdf-replication
% branch).  Builds the block-specific trend objects that enter the
% growth-neutrality terms of FR-BDF's five PAC equations, plus the second
% HP trend used in the hand-to-mouth (HtM) channel.
%
% wp1044 §3.5.1 / Eq 35 uses HP-filtered trend series for the
% growth-neutrality terms in PAC equations:
%
%   Block                 trend object     wp1044 ref
%   -----------------     -------------    ----------
%   Household consumption Δȳ_t            §3.5.1 Eq 35  (HP trend of GDP)
%   Business investment   Δq̄_t            §3.5.3 Eq 46  (HP trend of mkt VA)
%                         Δlog(r̄_KB,t)    §3.5.3 Eq 46  (HP trend of real
%                                                         user cost)
%   Employment            Δn̄*_S,t         §3.4.3 Eq 30  (HP / calibrated UR
%                                                         of trend salaried
%                                                         employment)
%   VA price (Phillips)   π̄*_Q,t          §3.3   Eq 16  (HP filter of VA-
%                                                         price inflation
%                                                         target)
%   Housing investment    Δlog(Ī*_H,t)    §3.5.2 Eq 37  (HP filter of
%                                                         housing-inv target)
%
% Plus the HtM channel's second HP trend:
%   HtM (in consumption)  ỹ_t              §3.5.1 Eq 35  (HP filter of output
%                                                         GROWTH, NOT level)
%
% Lambda = 1600 (standard for quarterly data; matches wp1044 §3.5.1
% footnote 22).  All trends are computed on the supply-data sample
% (1990Q1-2024Q4, 140 obs) so they align with the supply block.
%
% Inputs:
%   dynare/supply_data.mat        - q_total_lvl, q_market_lvl, p_q_total_lvl,
%                                   k_total_lvl, n_total_lvl, h_lvl,
%                                   delta_q, urate, dates
%   data/extended_dataset.csv     - au_gfcf_dwelling, au_i10
%   data/trend_efficiency.mat     - log_Ebar_det, dlog_Ebar_det (from L1.1)
%
% Outputs:
%   data/trend_series.mat         - all 7 trend objects + their first
%                                   differences, aligned to supply_data dates
%   data/trend_series.txt         - summary table of regime-mean growth rates
%
% Used by:
%   data/prepare_estimation_data.m  (Phase L1.3 wiring step)

clear; clc;
fprintf('=== Phase L1.2: block-specific trend objects for PAC equations ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% ------------------------------------------------------------
%% 0. Load inputs
%% ------------------------------------------------------------
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
E = load(fullfile(projectdir, 'data', 'trend_efficiency.mat'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

dates = S.dates;
nQ    = S.nQ;
fprintf('Supply-data sample: %d quarters, %s to %s\n', ...
    nQ, datestr(dates(1)), datestr(dates(end)));
fprintf('Extended dataset:   %d rows\n', height(ext));

lambda_hp = 1600;
fprintf('HP filter lambda = %d (standard for quarterly data)\n\n', lambda_hp);

% Align extended dataset to supply dates
ext_dates = datetime(ext.date);
ext_aligned = align_to_supply_dates(ext, ext_dates, dates);

%% ------------------------------------------------------------
%% 1. ȳ_t = HP(log Q_total)  --  trend GDP level (consumption block)
%% ------------------------------------------------------------
fprintf('1. ȳ_t (trend GDP level)  -->  consumption block growth-neutrality\n');
log_Q_total = S.q_total_lvl;
log_ybar = hp_trend(log_Q_total, lambda_hp);
dlog_ybar = [NaN; diff(log_ybar)];
report_trend('  ȳ_t', dlog_ybar, dates);

%% ------------------------------------------------------------
%% 2. q̄_t = HP(log Q_market)  --  trend market VA level (business inv block)
%% ------------------------------------------------------------
fprintf('\n2. q̄_t (trend market VA level)  -->  business investment growth-neutrality\n');
log_Q_market = S.q_market_lvl;
log_qbar = hp_trend(log_Q_market, lambda_hp);
dlog_qbar = [NaN; diff(log_qbar)];
report_trend('  q̄_t', dlog_qbar, dates);

%% ------------------------------------------------------------
%% 3. n̄*_S,t = HP(log n_total)  --  trend employment level (employment block)
%%
%% AU does not split salaried/non-salaried in ABS 6202 so we use total
%% employment as the proxy.
%% ------------------------------------------------------------
fprintf('\n3. n̄*_S,t (trend salaried employment, proxied by total)  -->  employment block\n');
log_n_total = S.n_total_lvl;
log_nbar = hp_trend(log_n_total, lambda_hp);
dlog_nbar = [NaN; diff(log_nbar)];
report_trend('  n̄*_S', dlog_nbar, dates);

%% ------------------------------------------------------------
%% 4. π̄*_Q,t = HP(d log p_q_total)  --  trend VA-price inflation (Phillips block)
%%
%% This is the trend (target) of VA-price quarterly inflation.  wp1044
%% defines π*_Q,t as the inflation target (a target series); we use the
%% HP-filtered actual VA-price inflation as the empirical analog, since
%% the AU model uses the actual inflation series rather than a separate
%% target.
%% ------------------------------------------------------------
fprintf('\n4. π̄*_Q,t (trend VA-price inflation)  -->  VA-price Phillips block\n');
log_pQ = S.p_q_total_lvl;
pi_Q = [NaN; diff(log_pQ)];                   % quarterly VA inflation
pi_Q_bar = hp_trend(pi_Q, lambda_hp);
dpi_Q_bar = [NaN; diff(pi_Q_bar)];
report_trend('  π̄*_Q', pi_Q_bar, dates);

%% ------------------------------------------------------------
%% 5. r̄_KB,t = HP(real user cost)  --  trend real user cost (business inv block)
%%
%% Real user cost approximation: r_KB,t = i_10y/400 + delta_q - pi_Q
%%   - i_10y / 400 converts annual % to quarterly decimal
%%   - delta_q is already quarterly depreciation (decimal)
%%   - pi_Q is quarterly log change in VA deflator (decimal)
%%
%% wp1044 uses a more elaborate construction involving p_K/p_Q ratio and
%% wacc, but for a Level-1 replication the simplified form is adequate.
%% Refinement (full wacc) deferred to L2 if needed.
%% ------------------------------------------------------------
fprintf('\n5. r̄_KB,t (trend real user cost of capital)  -->  business investment block\n');
i_10y_pct = ext_aligned.au_i10;               % annualised % per supply dates
delta_q   = S.delta_q;                        % quarterly decimal
real_user_cost = i_10y_pct / 400 + delta_q - pi_Q;
% HP filter the LEVEL (not log) -- avoids issues with brief negative real
% rates (e.g. 2020Q2 inflation spike) where log is undefined.  Then take
% log of the smooth positive trend for the dlog series that enters PAC.
rkb_bar = hp_trend(real_user_cost, lambda_hp);
if any(rkb_bar(~isnan(rkb_bar)) <= 0)
    warning('compute_trend_objects:rkb_neg', ...
        'HP-trend of real user cost goes non-positive somewhere; expect log issues.');
end
log_rkb_bar = log(max(rkb_bar, 1e-6));        % log of trend level
log_rkb_bar(isnan(rkb_bar)) = NaN;
dlog_rkb_bar = [NaN; diff(log_rkb_bar)];
report_trend('  log r̄_KB', log_rkb_bar, dates);
fprintf('  (Real user cost level: mean %.4f, sd %.4f over non-NaN)\n', ...
    mean(real_user_cost, 'omitnan'), std(real_user_cost, 'omitnan'));

%% ------------------------------------------------------------
%% 6. Ī*_H,t = HP(log au_gfcf_dwelling)  --  trend housing inv (housing block)
%%
%% wp1044 §3.5.2 has a more structural target involving permanent income
%% and house prices; HP filter is the Level-1 approximation.
%% ------------------------------------------------------------
fprintf('\n6. Ī*_H,t (trend housing investment target)  -->  housing investment block\n');
IH = ext_aligned.au_gfcf_dwelling;
log_IH = log(IH);            % NaN positions preserved; no extrapolation
log_IHbar = hp_trend(log_IH, lambda_hp);
dlog_IHbar = [NaN; diff(log_IHbar)];
report_trend('  Ī*_H', dlog_IHbar, dates);

%% ------------------------------------------------------------
%% 7. ỹ_t = HP(Δ log Q_total)  --  second HP trend (HtM channel only)
%%
%% wp1044 Eq 35 introduces this distinct HP trend of output GROWTH
%% (not level) for the hand-to-mouth channel.  Used in the level-
%% differential form of the HtM term:
%%     β_2 · [Δ(log(W_H + TG_H) - p_C^VAT) - ỹ_t]
%% ------------------------------------------------------------
fprintf('\n7. ỹ_t (HP trend of GDP GROWTH)  -->  HtM channel in consumption block\n');
dlog_Q_total = [NaN; diff(log_Q_total)];
ytilde = hp_trend(dlog_Q_total, lambda_hp);
report_trend('  ỹ_t', ytilde, dates);

%% ------------------------------------------------------------
%% 8. Structural ȳ_t from Ē_t (informational, not used downstream)
%%
%% wp1044 §3.1.3 derives the long-run output target structurally from
%% Ē_t via the CES production function at SS values of K, N, H.  We
%% compute this for documentation; the HP-filter ȳ_t from Step 1 is
%% what enters the PAC consumption block per wp1044 Eq 35.
%% ------------------------------------------------------------
fprintf('\n8. ȳ_t^struct (structural long-run output from Ē_t, CES; for documentation)\n');
C = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));
sigma_hat = C.sigma;  gamma_hat = C.gamma;  alpha_hat = C.alpha;
xi_ces = (sigma_hat - 1) / sigma_hat;

% Long-run inputs: HP filter K (capital), HP filter N (employment), const H
log_K_lvl = S.k_total_lvl;
log_N_lvl = S.n_total_lvl;
log_H_lvl = S.h_lvl;

log_Kbar = hp_trend(log_K_lvl, lambda_hp);
log_Nbar = log_nbar;            % already computed
log_Hbar = mean(log_H_lvl, 'omitnan') * ones(nQ, 1);   % constant SS hours

Kbar = exp(log_Kbar);
Ebar = exp(E.log_Ebar_det);
Nbar = exp(log_Nbar);
Hbar = exp(log_Hbar);

ENH = Ebar .* Nbar .* Hbar;
ces_inside = alpha_hat * Kbar.^xi_ces + (1 - alpha_hat) * ENH.^xi_ces;
log_ybar_struct = log(gamma_hat) + (1/xi_ces) * log(ces_inside);
dlog_ybar_struct = [NaN; diff(log_ybar_struct)];
report_trend('  ȳ_t^struct', dlog_ybar_struct, dates);

%% ------------------------------------------------------------
%% 9. Save outputs
%% ------------------------------------------------------------
out = struct();
out.method = 'wp1044 §3.5.1 HP-filter (Phase L1.2)';
out.lambda_hp = lambda_hp;
out.dates = dates;
out.nQ = nQ;

% Consumption block: ȳ_t (HP of log GDP), Δȳ_t
out.log_ybar = log_ybar;
out.dlog_ybar = dlog_ybar;

% Business investment block: q̄_t (HP of log mkt VA), Δq̄_t
out.log_qbar = log_qbar;
out.dlog_qbar = dlog_qbar;

% Business investment block: r̄_KB,t (HP of log real user cost), Δlog r̄_KB,t
out.real_user_cost = real_user_cost;
out.log_rkb_bar = log_rkb_bar;
out.dlog_rkb_bar = dlog_rkb_bar;

% Employment block: n̄*_S,t (HP of log emp), Δn̄*_S,t
out.log_nbar = log_nbar;
out.dlog_nbar = dlog_nbar;

% VA-price Phillips block: π̄*_Q,t (HP of quarterly VA inflation)
out.pi_Q = pi_Q;
out.pi_Q_bar = pi_Q_bar;
out.dpi_Q_bar = dpi_Q_bar;

% Housing investment block: Ī*_H,t (HP of log housing inv)
out.log_IHbar = log_IHbar;
out.dlog_IHbar = dlog_IHbar;

% HtM channel: ỹ_t (HP of quarterly GDP growth)
out.ytilde = ytilde;

% Structural ȳ_t from Ē_t (informational only)
out.log_ybar_struct = log_ybar_struct;
out.dlog_ybar_struct = dlog_ybar_struct;
out.log_Kbar = log_Kbar;

save(fullfile(projectdir, 'data', 'trend_series.mat'), '-struct', 'out');
fprintf('\nSaved data/trend_series.mat (9 trend objects + diagnostics)\n');

% Text summary
txtfile = fullfile(projectdir, 'data', 'trend_series.txt');
fid = fopen(txtfile, 'w');
fprintf(fid, 'Block-specific trend objects for wp1044 PAC equations\n');
fprintf(fid, 'Reference: Dubois et al. (2026) BdF WP #1044, §3.3-3.5\n');
fprintf(fid, 'Generated %s  (Phase L1.2)\n', datestr(now));
fprintf(fid, 'Method: HP filter with lambda = %d, on supply-data sample (n=%d)\n\n', ...
    lambda_hp, nQ);

fprintf(fid, '%-22s  %s\n', 'Trend object', 'Block / role');
fprintf(fid, '%-22s  %s\n', '------------', '------------');
fprintf(fid, '%-22s  %s\n', 'log_ybar (Δȳ_t)',  'Consumption growth-neutrality (Eq 35)');
fprintf(fid, '%-22s  %s\n', 'log_qbar (Δq̄_t)',  'Business inv growth-neutrality (Eq 46)');
fprintf(fid, '%-22s  %s\n', 'log_rkb_bar',       'Business inv user-cost trend (Eq 46)');
fprintf(fid, '%-22s  %s\n', 'log_nbar',          'Employment trend (Eq 30)');
fprintf(fid, '%-22s  %s\n', 'pi_Q_bar',          'VA-price Phillips trend (Eq 16)');
fprintf(fid, '%-22s  %s\n', 'log_IHbar',         'Housing inv trend (Eq 37)');
fprintf(fid, '%-22s  %s\n', 'ytilde',            'HtM channel (Eq 35 differential)');
fprintf(fid, '%-22s  %s\n', 'log_ybar_struct',   '(documentation) ȳ_t from Ē via CES');

fprintf(fid, '\nRegime-mean annualised trend growth rates (4 * quarterly diff, percent):\n');
fprintf(fid, '%-20s  %8s  %8s  %8s\n', 'Series', 'pre-2002', '2002-08', 'post-08');
fprintf(fid, '%-20s  %8s  %8s  %8s\n', '------', '--------', '-------', '-------');
regime_summary(fid, '  ybar (GDP)',          dlog_ybar,        dates);
regime_summary(fid, '  qbar (mkt VA)',       dlog_qbar,        dates);
regime_summary(fid, '  nbar (employment)',   dlog_nbar,        dates);
regime_summary(fid, '  IHbar (housing inv)', dlog_IHbar,       dates);
regime_summary(fid, '  ybar^struct',         dlog_ybar_struct, dates);

fprintf(fid, '\nLevel summaries (mean over non-NaN):\n');
fprintf(fid, '  pi_Q_bar      mean = %7.4f q/q (%.2f%% p.a.)\n', ...
    mean(pi_Q_bar, 'omitnan'), 400*mean(pi_Q_bar, 'omitnan'));
fprintf(fid, '  log_rkb_bar   mean = %7.4f  (real user cost level mean %.4f q/q)\n', ...
    mean(log_rkb_bar, 'omitnan'), mean(real_user_cost, 'omitnan'));
fprintf(fid, '  ytilde        mean = %7.4f q/q (%.2f%% p.a.)\n', ...
    mean(ytilde, 'omitnan'), 400*mean(ytilde, 'omitnan'));

fprintf(fid, '\nCross-validation with ces_2026 calibration:\n');
fprintf(fid, '  ces_2026 Ē trend growth (p.a.): pre-2002=%.2f%%, 2002-08=%.2f%%, post-08=%.2f%%\n', ...
    C.trend_growth_E_pre2002, C.trend_growth_E_2002_2008, C.trend_growth_E_post2008);
fprintf(fid, '  Phase L1.1 Ē trend growth (p.a.): pre-2002=%.2f%%, 2002-08=%.2f%%, post-08=%.2f%%\n', ...
    E.g_E_pre_2002, E.g_E_2002_08, E.g_E_post_08);
fprintf(fid, '  (Above are EFFICIENCY growth rates Ē, not output ȳ.  Output trends\n');
fprintf(fid, '   above differ since they incorporate trend K and trend N as well.)\n');
fclose(fid);
fprintf('Saved %s\n', txtfile);

fprintf('\n=== Phase L1.2 complete ===\n');

%% ------------------------------------------------------------
%% Helpers
%% ------------------------------------------------------------
function trend = hp_trend(y, lambda)
%HP_TREND Standard HP filter (Hodrick-Prescott).
%  HP-filters only the contiguous non-NaN range bounded by the first and
%  last valid observations.  Interior NaN gaps are linearly interpolated
%  inside that range.  Positions before the first valid obs and after the
%  last valid obs are left as NaN -- no extrapolation, since extrapolating
%  a log series whose level is changing produces large boundary artifacts
%  in the first-differences of the HP trend.
    y = y(:);
    n = length(y);
    trend = nan(n, 1);
    valid_idx = find(~isnan(y));
    if length(valid_idx) < 4, return; end

    i_lo = valid_idx(1);
    i_hi = valid_idx(end);
    span = i_lo:i_hi;
    y_span = y(span);

    % Interior NaN gaps: linear interpolation (no extrapolation past ends)
    nanmask_span = isnan(y_span);
    if any(nanmask_span)
        idx = find(~nanmask_span);
        y_span = interp1(idx, y_span(idx), 1:length(y_span), 'linear')';
    end

    n_span = length(y_span);
    e = ones(n_span, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n_span-2, n_span);
    A = speye(n_span) + lambda * (D2' * D2);
    trend(span) = A \ y_span;
end

function aligned = align_to_supply_dates(T, T_dates, target_dates)
%ALIGN_TO_SUPPLY_DATES align a table T (with column .date) onto target_dates.
%Result: aligned with size length(target_dates) x same columns as T (minus date).
    varNames = T.Properties.VariableNames;
    nT = length(target_dates);
    aligned = table();
    aligned.date = target_dates;
    for j = 1:length(varNames)
        col = varNames{j};
        if strcmp(col, 'date'), continue; end
        aligned.(col) = nan(nT, 1);
    end
    for i = 1:nT
        d = target_dates(i);
        match = find(year(T_dates) == year(d) & quarter(T_dates) == quarter(d), 1);
        if isempty(match), continue; end
        for j = 1:length(varNames)
            col = varNames{j};
            if strcmp(col, 'date'), continue; end
            v = T.(col);
            if iscell(v)
                aligned.(col)(i) = NaN;   % skip text columns
            else
                aligned.(col)(i) = v(match);
            end
        end
    end
end

function report_trend(name, series, dates)
    n_obs = sum(~isnan(series));
    if n_obs == 0
        fprintf('%s: no valid obs\n', name);
        return
    end
    fprintf('%s: n=%d, mean=%.5f, sd=%.5f, range=[%.4f, %.4f]\n', ...
        name, n_obs, mean(series, 'omitnan'), std(series, 'omitnan'), ...
        min(series), max(series));
end

function regime_summary(fid, name, dseries, dates)
%REGIME_SUMMARY annualised regime means of a quarterly dlog series.
    valid_pre  = dates < datetime(2002, 4, 1) & ~isnan(dseries);
    valid_mid  = dates >= datetime(2002, 4, 1) & dates < datetime(2008, 7, 1) & ~isnan(dseries);
    valid_post = dates >= datetime(2008, 7, 1) & ~isnan(dseries);
    g_pre  = 400 * mean(dseries(valid_pre),  'omitnan');
    g_mid  = 400 * mean(dseries(valid_mid),  'omitnan');
    g_post = 400 * mean(dseries(valid_post), 'omitnan');
    fprintf(fid, '%-20s  %7.2f%%  %7.2f%%  %7.2f%%\n', name, g_pre, g_mid, g_post);
end
