%% estimate_phase_c_lpiv.m
% Phase C: LP-IV for the two stubbed structural drivers in au_pac.mod.
%
%   b_di_c (consumption PAC, FR-BDF eq 61, beta_3 = -0.71):
%       The ad-hoc interest-rate-CHANGE channel into consumption growth.
%       OLS on AU data gave +3.39 (wrong sign) due to reverse causality:
%       when consumption is strong, RBA hikes rates, so corr(di, dln_c) > 0
%       even when the structural effect of di on dln_c is negative.
%
%       Identification: estimate a Taylor rule on observed AU data and use
%       the residuals (Romer-Romer style narrative monetary surprise series)
%       as instrument for di in the consumption equation.
%
%   b_ph_ih (housing investment PAC, FR-BDF eq 67, beta_3 = +0.32):
%       Housing price gap effect on housing investment growth.
%       OLS on ABS 6416 RPPI gave -0.04 (wrong sign vs FR-BDF +0.32) due to
%       supply-side reverse causality: when housing investment is strong,
%       housing prices fall (more supply).
%
%       Identification: use lag-2 ph_gap as instrument for lag-1 ph_gap. Lag-2
%       price isn't a direct determinant of contemporaneous housing investment
%       (PAC equation specifies lag-1), but it predicts lag-1 price.
%
% Both estimates fall back to a Bayesian regularised value if first-stage F<10
% or if the IV-implied coefficient flips sign from the FR-BDF benchmark.
%
% OUTPUT:
%   dynare/phase_c_results.txt — full diagnostic
%   dynare/phase_c_results.mat — point estimates + s.e.
%   Console: ready-to-paste .mod parameter lines.

clear; clc;
this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
projectdir = fullfile(this_dir, '..');

fprintf('=== Phase C: LP-IV for b_di_c and b_ph_ih ===\n\n');

%% 1. Load observable AU data
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
dates  = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
nQ     = height(T_base);

yhat_au  = T_base.au_ygap;
pi_au    = T_base.au_pi;
i_au     = T_base.au_irate / 4;
ibar     = T_base.i_bar / 4;
pibar_au = T_base.pi_bar_au;
i_gap    = i_au  - ibar;
pi_gap   = pi_au - pibar_au;

cons     = T_ext.au_consumption;
dln_c    = [NaN; diff(log(cons))] * 100;
dln_c    = dln_c - mean(dln_c, 'omitnan');

ih       = T_ext.au_gfcf_dwelling;
dln_ih   = [NaN; diff(log(ih))] * 100;
dln_ih   = dln_ih - mean(dln_ih, 'omitnan');

di       = [NaN; diff(i_au)];     % quarterly change in cash rate

%% 2. COVID dummies (consistent with PAC structural step)
D_crash  = (year(dates) == 2020 & quarter(dates) == 2);
D_bounce = (year(dates) == 2020 & quarter(dates) == 3);

%% =================================================================
%% A. b_di_c via Romer-Romer monetary surprise (Taylor-rule residuals)
%% =================================================================
fprintf('--- A. b_di_c: monetary surprise IV ---\n');

%% A.1 Estimate Taylor rule to extract monetary surprise
% i_t = rho * i_{t-1} + (1-rho) * (i_ss + alpha*pi_gap_{t-1} + beta*y_gap_{t-1}) + eps_i
% Use simpler regression: di_t = a + b*pi_gap_{t-1} + c*y_gap_{t-1} + eps_i
% Residuals = monetary surprise.
y = di(2:nQ);
X_taylor = [ones(nQ-1,1), i_au(1:nQ-1), pi_gap(1:nQ-1), yhat_au(1:nQ-1), D_crash(2:nQ), D_bounce(2:nQ)];
valid = all(~isnan([y, X_taylor]), 2);
y_v = y(valid); X_v = X_taylor(valid, :);
beta_taylor = (X_v' * X_v) \ (X_v' * y_v);
ms = nan(nQ, 1);                         % monetary surprise series (full length)
fitted = X_taylor * beta_taylor;
ms(2:nQ) = y - fitted;
fprintf('  Taylor rule residual std: %.4f, R^2 = %.3f\n', ...
        std(ms, 'omitnan'), 1 - var(y_v - X_v*beta_taylor)/var(y_v));

%% A.2 LP-IV: regress dln_c_t on di_t (instrumented by ms_t), with controls
% First stage: di_t = pi0 + pi1 * ms_t + controls + u_t
% Second stage: dln_c_t = a + b_di_c * \hat{di}_t + controls + v_t
% Use lagged dln_c, output gap, real rate gap as controls.
y_c   = dln_c(3:nQ);
X_2nd = [ones(nQ-2,1), di(3:nQ), dln_c(2:nQ-1), yhat_au(2:nQ-1), i_gap(2:nQ-1) - pi_gap(2:nQ-1), D_crash(3:nQ), D_bounce(3:nQ)];
Z_inst = [ones(nQ-2,1), ms(3:nQ),  dln_c(2:nQ-1), yhat_au(2:nQ-1), i_gap(2:nQ-1) - pi_gap(2:nQ-1), D_crash(3:nQ), D_bounce(3:nQ)];

valid_c = all(~isnan([y_c, X_2nd, Z_inst]), 2);
y_c_v = y_c(valid_c); X_2nd_v = X_2nd(valid_c, :); Z_v = Z_inst(valid_c, :);
T_c = sum(valid_c);

%% A.3 First stage F-test on the excluded instrument
% Regress endogenous regressor (di) on the controls + the instrument (ms).
y_first = X_2nd_v(:, 2);   % di
X_first_full = [Z_v];
X_first_red  = [Z_v(:, 1), Z_v(:, 3:end)];   % drop ms
beta_full = (X_first_full' * X_first_full) \ (X_first_full' * y_first);
beta_red  = (X_first_red'  * X_first_red ) \ (X_first_red'  * y_first);
sse_full  = sum((y_first - X_first_full*beta_full).^2);
sse_red   = sum((y_first - X_first_red *beta_red ).^2);
F_stage1_a = ((sse_red - sse_full) / 1) / (sse_full / (T_c - size(X_first_full,2)));
fprintf('  First-stage F (di ~ ms): %.2f (T=%d)\n', F_stage1_a, T_c);
fprintf('  Stock-Yogo critical value (10%% relative bias): 16.38; weak IV if F < 10.\n');

%% A.4 2SLS (IV) estimator
% beta_iv = (Z'X)^{-1} Z'y
ZtX = Z_v' * X_2nd_v;
Zty = Z_v' * y_c_v;
if rcond(ZtX) > 1e-10
    beta_iv = ZtX \ Zty;
    resid_iv = y_c_v - X_2nd_v * beta_iv;
    sigma2_iv = (resid_iv' * resid_iv) / (T_c - size(X_2nd_v, 2));
    V_iv = sigma2_iv * inv(ZtX) * (Z_v' * Z_v) * inv(ZtX');
    se_iv = sqrt(diag(V_iv));
    b_di_c_iv = beta_iv(2);
    se_b_di_c = se_iv(2);
else
    b_di_c_iv = NaN;
    se_b_di_c = NaN;
end
fprintf('  IV estimate: b_di_c = %.4f (s.e. %.4f)\n', b_di_c_iv, se_b_di_c);

% OLS for comparison
beta_ols_c = (X_2nd_v' * X_2nd_v) \ (X_2nd_v' * y_c_v);
fprintf('  OLS estimate: b_di_c = %.4f (note: known to be wrong-signed due to reverse causality)\n', beta_ols_c(2));

% Decision: use IV if (a) first-stage F >= 10 AND (b) sign matches FR-BDF (-0.71)
fr_bdf_b_di_c = -0.71;
use_iv_a = (F_stage1_a >= 10) && (sign(b_di_c_iv) == sign(fr_bdf_b_di_c));
if use_iv_a
    final_b_di_c = b_di_c_iv;
    method_a = sprintf('IV (Taylor-rule residual instrument; F=%.1f)', F_stage1_a);
else
    % Fall back: Bayesian regularised at FR-BDF prior with weak data update.
    % Posterior with Normal prior N(-0.71, 0.30^2) and OLS as data signal.
    prior_mean = fr_bdf_b_di_c;
    prior_sd   = 0.30;
    data_signal = beta_ols_c(2);
    data_sd     = max(0.5, abs(beta_ols_c(2)));   % skeptical when data implausible
    % Posterior precision-weighted average
    final_b_di_c = (prior_mean / prior_sd^2 + data_signal / data_sd^2) / ...
                   (1/prior_sd^2 + 1/data_sd^2);
    method_a = sprintf('Bayesian regularised (weak IV F=%.1f); fallback prior N(-0.71, 0.30^2)', F_stage1_a);
end
fprintf('  FINAL b_di_c = %.4f via %s\n\n', final_b_di_c, method_a);

%% =================================================================
%% B. b_ph_ih via lag-2 IV on housing prices
%% =================================================================
fprintf('--- B. b_ph_ih: housing price IV ---\n');

%% B.1 Load ABS 6416 RPPI weighted average
rppi_csv = fullfile(projectdir, 'data', 'abs_rba', 'abs_6416_rppi.csv');
opts = detectImportOptions(rppi_csv, 'NumHeaderLines', 9);
opts = setvartype(opts, opts.VariableNames{1}, 'char');
T_rppi = readtable(rppi_csv, opts);
fprintf('  RPPI columns: %d, rows: %d\n', width(T_rppi), height(T_rppi));

% First column is date string in d/MM/yyyy format
rppi_dates_raw = T_rppi.(1);
rppi_dates = datetime(rppi_dates_raw, 'InputFormat', 'd/MM/yyyy');

% 10th column = weighted average index (after 1 date col + 9 city cols, the 10th from
% the file = "Weighted average of eight capital cities" index — but readtable may not
% include the date column in T_rppi.Properties.VariableNames depending on options. Use
% column index relative to the table.
rppi_weighted = T_rppi.(10);
if iscell(rppi_weighted)
    rppi_weighted = str2double(rppi_weighted);
end

% Filter to quarterly end-of-quarter alignment with main dataset
rppi_weighted_aligned = nan(nQ, 1);
for k = 1:length(rppi_dates)
    target_q = quarter(rppi_dates(k));
    target_y = year(rppi_dates(k));
    idx = find(year(dates) == target_y & quarter(dates) == target_q, 1);
    if ~isempty(idx)
        rppi_weighted_aligned(idx) = rppi_weighted(k);
    end
end

% Check coverage
n_rppi = sum(~isnan(rppi_weighted_aligned));
fprintf('  RPPI aligned: %d valid obs (%s onward)\n', n_rppi, ...
    datestr(dates(find(~isnan(rppi_weighted_aligned), 1, 'first'))));

if n_rppi < 30
    fprintf('  Insufficient RPPI data; skipping IV estimation.\n');
    final_b_ph_ih = 0;
    method_b = 'kept at 0 — insufficient RPPI data';
else
    %% B.2 Construct ph_gap = log(RPPI) - HP-trend
    log_rppi = log(rppi_weighted_aligned);
    log_rppi_filled = fill_nan_linear(log_rppi);
    rppi_trend = hp_trend_local(log_rppi_filled, 1600);
    ph_gap = 100 * (log_rppi - rppi_trend);

    %% B.3 LP-IV: regress dln_ih_t on ph_gap_{t-1} (instrumented by ph_gap_{t-2})
    y_ih  = dln_ih(3:nQ);
    X_2nd_b = [ones(nQ-2,1), ph_gap(2:nQ-1), dln_ih(2:nQ-1), yhat_au(2:nQ-1), i_gap(2:nQ-1), D_crash(3:nQ), D_bounce(3:nQ)];
    Z_inst_b = [ones(nQ-2,1), ph_gap(1:nQ-2), dln_ih(2:nQ-1), yhat_au(2:nQ-1), i_gap(2:nQ-1), D_crash(3:nQ), D_bounce(3:nQ)];

    valid_b = all(~isnan([y_ih, X_2nd_b, Z_inst_b]), 2);
    y_ih_v = y_ih(valid_b); X_2nd_bv = X_2nd_b(valid_b, :); Z_bv = Z_inst_b(valid_b, :);
    T_b = sum(valid_b);

    %% B.4 First-stage F
    y_first_b = X_2nd_bv(:, 2);   % ph_gap_{t-1}
    X_first_full_b = [Z_bv];
    X_first_red_b  = [Z_bv(:, 1), Z_bv(:, 3:end)];
    beta_full_b = (X_first_full_b' * X_first_full_b) \ (X_first_full_b' * y_first_b);
    beta_red_b  = (X_first_red_b'  * X_first_red_b ) \ (X_first_red_b'  * y_first_b);
    sse_full_b = sum((y_first_b - X_first_full_b*beta_full_b).^2);
    sse_red_b  = sum((y_first_b - X_first_red_b *beta_red_b ).^2);
    F_stage1_b = ((sse_red_b - sse_full_b) / 1) / (sse_full_b / (T_b - size(X_first_full_b,2)));
    fprintf('  First-stage F (ph_gap_{t-1} ~ ph_gap_{t-2}): %.2f (T=%d)\n', F_stage1_b, T_b);

    %% B.5 2SLS estimator
    ZtX_b = Z_bv' * X_2nd_bv;
    Zty_b = Z_bv' * y_ih_v;
    if rcond(ZtX_b) > 1e-10
        beta_iv_b = ZtX_b \ Zty_b;
        resid_iv_b = y_ih_v - X_2nd_bv * beta_iv_b;
        sigma2_iv_b = (resid_iv_b' * resid_iv_b) / (T_b - size(X_2nd_bv, 2));
        V_iv_b = sigma2_iv_b * inv(ZtX_b) * (Z_bv' * Z_bv) * inv(ZtX_b');
        se_iv_b = sqrt(diag(V_iv_b));
        b_ph_ih_iv = beta_iv_b(2);
        se_b_ph_ih = se_iv_b(2);
    else
        b_ph_ih_iv = NaN;
        se_b_ph_ih = NaN;
    end
    fprintf('  IV estimate: b_ph_ih = %.4f (s.e. %.4f)\n', b_ph_ih_iv, se_b_ph_ih);

    beta_ols_b = (X_2nd_bv' * X_2nd_bv) \ (X_2nd_bv' * y_ih_v);
    fprintf('  OLS estimate: b_ph_ih = %.4f\n', beta_ols_b(2));

    fr_bdf_b_ph_ih = 0.32;
    use_iv_b = (F_stage1_b >= 10) && (sign(b_ph_ih_iv) == sign(fr_bdf_b_ph_ih));
    if use_iv_b
        final_b_ph_ih = b_ph_ih_iv;
        method_b = sprintf('IV (lag-2 ph_gap; F=%.1f)', F_stage1_b);
    else
        prior_mean = fr_bdf_b_ph_ih;
        prior_sd   = 0.20;
        data_signal = beta_ols_b(2);
        data_sd     = max(0.3, abs(beta_ols_b(2)));
        final_b_ph_ih = (prior_mean / prior_sd^2 + data_signal / data_sd^2) / ...
                        (1/prior_sd^2 + 1/data_sd^2);
        method_b = sprintf('Bayesian regularised (weak/wrong-sign IV F=%.1f); fallback prior N(0.32, 0.20^2)', F_stage1_b);
    end
    fprintf('  FINAL b_ph_ih = %.4f via %s\n\n', final_b_ph_ih, method_b);
end

%% 7. Save results
out_txt = fullfile(this_dir, 'phase_c_results.txt');
fid = fopen(out_txt, 'w');
fprintf(fid, 'Phase C: LP-IV for b_di_c and b_ph_ih\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, '=== A. b_di_c (consumption interest-rate-change channel) ===\n');
fprintf(fid, '  Identification: Taylor-rule residual as monetary surprise IV\n');
fprintf(fid, '  First-stage F: %.2f (Stock-Yogo 10%%-relative-bias threshold = 16.38)\n', F_stage1_a);
fprintf(fid, '  IV estimate: %.4f (s.e. %.4f)\n', b_di_c_iv, se_b_di_c);
fprintf(fid, '  OLS comparator: %.4f (known wrong sign — reverse causality)\n', beta_ols_c(2));
fprintf(fid, '  Method used: %s\n', method_a);
fprintf(fid, '  FINAL: b_di_c = %.4f\n\n', final_b_di_c);
fprintf(fid, '=== B. b_ph_ih (housing investment housing-price-gap channel) ===\n');
fprintf(fid, '  Identification: lag-2 ph_gap IV for lag-1 ph_gap\n');
if exist('F_stage1_b', 'var')
    fprintf(fid, '  First-stage F: %.2f\n', F_stage1_b);
    fprintf(fid, '  IV estimate: %.4f (s.e. %.4f)\n', b_ph_ih_iv, se_b_ph_ih);
    fprintf(fid, '  OLS comparator: %.4f\n', beta_ols_b(2));
    fprintf(fid, '  Method used: %s\n', method_b);
    fprintf(fid, '  FINAL: b_ph_ih = %.4f\n\n', final_b_ph_ih);
else
    fprintf(fid, '  Skipped — insufficient RPPI data\n');
    fprintf(fid, '  FINAL: b_ph_ih = 0 (kept at zero)\n\n');
end

fprintf(fid, '--- .mod parameter lines ---\n');
fprintf(fid, 'b_di_c          = %7.4f;    // Phase C %s\n', final_b_di_c, method_a);
fprintf(fid, 'b_ph_ih         = %7.4f;    // Phase C %s\n', final_b_ph_ih, method_b);
fclose(fid);

results = struct();
results.b_di_c.final = final_b_di_c;
results.b_di_c.iv = b_di_c_iv;
results.b_di_c.ols = beta_ols_c(2);
results.b_di_c.f_stage1 = F_stage1_a;
results.b_di_c.method = method_a;
results.b_ph_ih.final = final_b_ph_ih;
if exist('b_ph_ih_iv', 'var')
    results.b_ph_ih.iv = b_ph_ih_iv;
    results.b_ph_ih.ols = beta_ols_b(2);
    results.b_ph_ih.f_stage1 = F_stage1_b;
end
results.b_ph_ih.method = method_b;
save(fullfile(this_dir, 'phase_c_results.mat'), 'results');

fprintf('=== Saved ===\n  %s\n  %s\n\n', out_txt, fullfile(this_dir, 'phase_c_results.mat'));
fprintf('Final values:\n  b_di_c = %.4f\n  b_ph_ih = %.4f\n', final_b_di_c, final_b_ph_ih);

%% ---------- helper: HP filter trend ----------
function trend = hp_trend_local(y, lambda)
    y = y(:);
    n = length(y);
    e = ones(n, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n-2, n);
    A  = speye(n) + lambda * (D2' * D2);
    trend = A \ y;
end

function v = fill_nan_linear(y)
    y = y(:);
    n = length(y);
    nanmask = isnan(y);
    if any(nanmask) && sum(~nanmask) >= 2
        valid_idx = find(~nanmask);
        v = y;
        v(nanmask) = interp1(valid_idx, y(valid_idx), find(nanmask), 'linear', 'extrap');
    else
        v = y;
    end
end
