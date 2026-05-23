%% prepare_estimation_data.m
% Transforms raw CSV data into Dynare-compatible format for Bayesian estimation.
%
% Loads dataset.csv (E-SAT core) + extended_dataset.csv (demand/labor/financial),
% transforms to model-consistent units (quarterly %, demeaned), aligns sample,
% and saves as dynare/estimation_data.mat.
%
% Observable mapping (10 variables, 10th added 2026-05-22 for Round 1.2):
%   yhat_au        <- au_ygap                  (already quarterly %)
%   pi_au          <- au_pi                    (already quarterly %)
%   i_au           <- au_irate / 4             (annualized -> quarterly)
%   yhat_us        <- us_ygap                  (already quarterly %)
%   pi_us          <- us_pi                    (already quarterly %)
%   pi_w           <- au_pi_w                  (log-diff of synthetic ULC, quarterly %)
%   dln_c          <- 100*dlog(au_consumption)         (log-diff)
%   dln_ib         <- 100*dlog(au_gfcf_nondwelling)    (log-diff, non-dwelling GFCF)
%   i_10y          <- au_i10 / 4               (annualized -> quarterly)
%   wt_H_real_gap  <- 100 * au_wt_H_real_gap   (Round 1.2: HtM income gap, ABS 5206 T20)

clear; clc;
fprintf('=== Preparing estimation data ===\n\n');

outdir = fileparts(mfilename('fullpath'));
if isempty(outdir), outdir = pwd; end
projectdir = fullfile(outdir, '..');

%% Load data sources
fprintf('Loading data sources...\n');

% Base dataset (E-SAT core)
base_csv = fullfile(projectdir, 'dataset.csv');
T_base = readtable(base_csv);
base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
nB = height(T_base);
fprintf('  dataset.csv: %d obs (%s to %s)\n', nB, ...
    datestr(base_dates(1)), datestr(base_dates(end)));

% Extended dataset
ext_csv = fullfile(outdir, 'extended_dataset.csv');
T_ext = readtable(ext_csv);
ext_dates = datetime(T_ext.date, 'InputFormat', 'yyyy-MM-dd');
nE = height(T_ext);
fprintf('  extended_dataset.csv: %d obs (%s to %s)\n', nE, ...
    datestr(ext_dates(1)), datestr(ext_dates(end)));

%% Verify date alignment
% Both datasets should start at 1993Q1 — check they align
assert(isequal(base_dates, ext_dates), ...
    'Date vectors do not match between base and extended datasets');
nQ = nB;
fprintf('  Date vectors aligned: %d quarters\n\n', nQ);

%% Transform variables to model-consistent units
fprintf('Transforming variables...\n');

% --- From base dataset ---
yhat_au_raw = T_base.au_ygap;          % already quarterly %
pi_au_raw   = T_base.au_pi;            % already quarterly %
i_au_raw    = T_base.au_irate / 4;     % annualized -> quarterly
yhat_us_raw = T_base.us_ygap;          % already quarterly %
pi_us_raw   = T_base.us_pi;            % already quarterly %

% --- From extended dataset ---
pi_w_raw    = T_ext.au_pi_w;           % already quarterly % (log-diff of ULC)
i_10y_raw   = T_ext.au_i10 / 4;        % annualized -> quarterly

% Consumption growth: log-difference
cons_raw = T_ext.au_consumption;
dln_c_raw = [NaN; diff(log(cons_raw))] * 100;  % quarterly %

% Business investment growth: log-difference of non-dwelling GFCF
gfcf_nd_raw = T_ext.au_gfcf_nondwelling;
dln_ib_raw = [NaN; diff(log(gfcf_nd_raw))] * 100;  % quarterly %

% Round 1.2 (2026-05-22): household wage+transfer real income gap.
% Source: HP-gap of log[(comp_employees + social_assistance)/p_C], ABS 5206 T20.
% Multiply by 100 to convert log-deviation to percent units (matches yhat_au).
if any(strcmp('au_wt_H_real_gap', T_ext.Properties.VariableNames))
    wt_H_real_gap_raw = T_ext.au_wt_H_real_gap * 100;  % fractional -> percent
    has_wtH = true;
else
    wt_H_real_gap_raw = nan(nE, 1);
    has_wtH = false;
    warning('au_wt_H_real_gap missing from extended_dataset.csv; run data/prepare_household_income.m first.');
end

% (Round 1.2 Option 4 stimulus-quarter NaN-out happens AFTER demeaning;
% see the post-demeaning block below — applied to the aligned sample so it
% doesn't interfere with common-sample finding or interpolation of the
% other observables.)

fprintf('  yhat_au:       %d valid obs\n', sum(~isnan(yhat_au_raw)));
fprintf('  pi_au:         %d valid obs\n', sum(~isnan(pi_au_raw)));
fprintf('  i_au:          %d valid obs\n', sum(~isnan(i_au_raw)));
fprintf('  yhat_us:       %d valid obs\n', sum(~isnan(yhat_us_raw)));
fprintf('  pi_us:         %d valid obs\n', sum(~isnan(pi_us_raw)));
fprintf('  pi_w:          %d valid obs\n', sum(~isnan(pi_w_raw)));
fprintf('  dln_c:         %d valid obs\n', sum(~isnan(dln_c_raw)));
fprintf('  dln_ib:        %d valid obs\n', sum(~isnan(dln_ib_raw)));
fprintf('  i_10y:         %d valid obs\n', sum(~isnan(i_10y_raw)));
fprintf('  wt_H_real_gap: %d valid obs (Round 1.2)\n', sum(~isnan(wt_H_real_gap_raw)));

%% Find common sample (no NaN in any observable)
all_data = [yhat_au_raw, pi_au_raw, i_au_raw, yhat_us_raw, pi_us_raw, ...
            pi_w_raw, dln_c_raw, dln_ib_raw, i_10y_raw, wt_H_real_gap_raw];
valid = all(~isnan(all_data), 2);
first_valid = find(valid, 1, 'first');
last_valid  = find(valid, 1, 'last');

fprintf('\nCommon sample: obs %d to %d (%s to %s) = %d quarters\n', ...
    first_valid, last_valid, ...
    datestr(base_dates(first_valid)), datestr(base_dates(last_valid)), ...
    last_valid - first_valid + 1);

% Check for internal NaN gaps
sample_range = first_valid:last_valid;
internal_nan = sum(~valid(sample_range));
if internal_nan > 0
    fprintf('  WARNING: %d internal NaN observations — filling with linear interpolation\n', internal_nan);
    for col = 1:size(all_data, 2)
        v = all_data(sample_range, col);
        nanidx = isnan(v);
        if any(nanidx) && sum(~nanidx) >= 2
            v(nanidx) = interp1(find(~nanidx), v(~nanidx), find(nanidx), 'linear', 'extrap');
            all_data(sample_range, col) = v;
        end
    end
end

% Extract aligned sample
yhat_au       = all_data(sample_range, 1);
pi_au         = all_data(sample_range, 2);
i_au          = all_data(sample_range, 3);
yhat_us       = all_data(sample_range, 4);
pi_us         = all_data(sample_range, 5);
pi_w          = all_data(sample_range, 6);
dln_c         = all_data(sample_range, 7);
dln_ib        = all_data(sample_range, 8);
i_10y         = all_data(sample_range, 9);
wt_H_real_gap = all_data(sample_range, 10);
nObs = length(sample_range);

%% Demean
% Dynare estimation with gap/growth variables expects demeaned data.
% For interest rates: subtract steady-state values from au_pac.mod.
% For gap variables: already zero-mean by construction.
% For growth rates: subtract sample mean (≈ steady-state growth).
%
% DEMEAN_MODE = 'sample'   : subtract constant sample means (default; legacy)
%             = 'hp_trend' : subtract HP-filter trend growth from growth rates
%                            (pragmatic time-varying demeaning, 2026-05-23).
%                            Captures AU productivity slowdown 1990s → 2010s.
%             = 'frbdf'    : subtract model-implied trend from CES Ē with
%                            two breaks (2002Q2, 2008Q3) + pop growth + hours.
%                            FR-BDF wp1044 §3.2 style — structural trend.
%             = 'none'     : Option α — NO demeaning of dln_c, dln_ib (the
%                            model's dln_c_star_bar carries the trend now).
%                            pi_w still demeaned by sample mean as a known
%                            limitation pending Option β. Saved fields named
%                            dln_C_obs / dln_IB_obs to match the new varobs.
DEMEAN_MODE = 'none';      % flip to 'sample' / 'hp_trend' / 'frbdf' to compare
fprintf('\nDEMEAN_MODE = %s\n', DEMEAN_MODE);
fprintf('Demeaning (subtracting trends)...\n');

varnames_raw = {'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
                'pi_w', 'dln_c', 'dln_ib', 'i_10y', 'wt_H_real_gap'};
raw_means = mean([yhat_au, pi_au, i_au, yhat_us, pi_us, ...
                   pi_w, dln_c, dln_ib, i_10y, wt_H_real_gap]);

% ------------------------------------------------------------------------
% Build TIME-VARYING TREND series for growth-rate observables.
% Only dln_c, dln_ib, pi_w need this — gap variables and inflation/rate
% targets remain demeaned by constant sample mean (their target SSs ARE
% constant in the model).
% ------------------------------------------------------------------------
hp_lambda = 1600;
dln_c_trend  = zeros(nObs, 1);
dln_ib_trend = zeros(nObs, 1);
pi_w_trend   = zeros(nObs, 1);

switch DEMEAN_MODE
  case 'sample'
    % Legacy: constant trend = sample mean
    dln_c_trend(:)  = raw_means(7);
    dln_ib_trend(:) = raw_means(8);
    pi_w_trend(:)   = raw_means(6);

  case 'none'
    % Option α: NO demeaning of dln_c / dln_ib. The model's dln_c_star_bar /
    % dln_ib_star_bar carry the BGP trend (g_bar_C, g_bar_IB calibrated post-
    % 2008Q3 in identity layer). varobs are renamed dln_C_obs / dln_IB_obs.
    % pi_w still demeaned by sample mean — known Option α limitation pending β.
    dln_c_trend(:)  = 0;            % no subtraction
    dln_ib_trend(:) = 0;            % no subtraction
    pi_w_trend(:)   = raw_means(6); % still demeaned

  case 'hp_trend'
    % Pragmatic TVD: HP filter the log-level of each underlying series,
    % then take diff(trend) to get a time-varying trend growth rate.
    cons_lvl_raw    = T_ext.au_consumption(sample_range);
    gfcf_nd_lvl_raw = T_ext.au_gfcf_nondwelling(sample_range);
    ulc_lvl_raw     = T_ext.au_ulc(sample_range);

    log_cons_trend = local_hp_trend(log(fill_nan_lin(cons_lvl_raw)),    hp_lambda);
    log_gfcf_trend = local_hp_trend(log(fill_nan_lin(gfcf_nd_lvl_raw)), hp_lambda);
    log_ulc_trend  = local_hp_trend(log(fill_nan_lin(ulc_lvl_raw)),     hp_lambda);

    dln_c_trend(2:end)  = diff(log_cons_trend) * 100;  dln_c_trend(1)  = dln_c_trend(2);
    dln_ib_trend(2:end) = diff(log_gfcf_trend) * 100;  dln_ib_trend(1) = dln_ib_trend(2);
    pi_w_trend(2:end)   = diff(log_ulc_trend)  * 100;  pi_w_trend(1)   = pi_w_trend(2);

  case 'frbdf'
    % FR-BDF-style structural trend. On the BGP the model implies:
    %   trend dln_c  = dln_Ē + dln_N_bar       (consumption = output growth, BGP)
    %   trend dln_ib = dln_Ē + dln_N_bar       (investment = output growth, BGP)
    %   trend pi_w   = pi_ss + dln_Ē           (nominal wage = target + productivity)
    % with dln_Ē piecewise-constant from the CES 2026 calibration (two breaks
    % at 2002Q2 and 2008Q3) and dln_N_bar from HP-filter of log(employment).
    % Values (quarterly %) from dynare/ces_2026_calibration.txt:
    %   pre-2002Q2  : dln_Ē = 3.07/4 = 0.7675
    %   2002Q2–08Q3 : dln_Ē = 0.43/4 = 0.1075
    %   post-2008Q3 : dln_Ē = 0.49/4 = 0.1225
    alpha_ces = 0.45;   % AUSPAC capital share (ABS 5204 Tab 48)
    pi_ss_qoq = 0.625;  % RBA target, % qoq

    sample_dates_full = base_dates(sample_range);
    dln_E_bar = zeros(nObs, 1);
    pre_b1 = sample_dates_full <  datetime(2002, 4, 1);
    mid_b  = sample_dates_full >= datetime(2002, 4, 1) & sample_dates_full < datetime(2008, 7, 1);
    post_b = sample_dates_full >= datetime(2008, 7, 1);
    dln_E_bar(pre_b1) = 3.07 / 4;
    dln_E_bar(mid_b)  = 0.43 / 4;
    dln_E_bar(post_b) = 0.49 / 4;

    % Trend employment growth via HP-filter
    emp_lvl   = T_ext.au_employment(sample_range);
    log_emp_tr = local_hp_trend(log(fill_nan_lin(emp_lvl)), hp_lambda);
    dln_N_bar = zeros(nObs, 1);
    dln_N_bar(2:end) = diff(log_emp_tr) * 100;
    dln_N_bar(1) = dln_N_bar(2);

    dln_c_trend  = dln_E_bar + dln_N_bar;            % BGP growth = Ē + N_bar
    dln_ib_trend = dln_E_bar + dln_N_bar;            % BGP: I = Y
    pi_w_trend   = pi_ss_qoq + dln_E_bar;            % nominal wage = pi_ss + dln_Ē
  otherwise
    error('Unknown DEMEAN_MODE: %s', DEMEAN_MODE);
end

fprintf('\n  Trend statistics (%% qoq):\n');
fprintf('  %-14s mean=%+.3f sd=%.3f range=[%+.3f, %+.3f]\n', 'dln_c trend',  mean(dln_c_trend),  std(dln_c_trend),  min(dln_c_trend),  max(dln_c_trend));
fprintf('  %-14s mean=%+.3f sd=%.3f range=[%+.3f, %+.3f]\n', 'dln_ib trend', mean(dln_ib_trend), std(dln_ib_trend), min(dln_ib_trend), max(dln_ib_trend));
fprintf('  %-14s mean=%+.3f sd=%.3f range=[%+.3f, %+.3f]\n', 'pi_w trend',   mean(pi_w_trend),   std(pi_w_trend),   min(pi_w_trend),   max(pi_w_trend));

for j = 1:length(varnames_raw)
    fprintf('  %s mean: %.4f (subtracting)\n', varnames_raw{j}, raw_means(j));
end

% Apply: gap variables, inflation, rates use constant sample-mean demeaning;
% growth rates use the time-varying trend (when DEMEAN_MODE != 'sample').
yhat_au_mean        = raw_means(1);  yhat_au       = yhat_au       - yhat_au_mean;
pi_au_mean          = raw_means(2);  pi_au         = pi_au         - pi_au_mean;
i_au_mean           = raw_means(3);  i_au          = i_au          - i_au_mean;
yhat_us_mean        = raw_means(4);  yhat_us       = yhat_us       - yhat_us_mean;
pi_us_mean          = raw_means(5);  pi_us         = pi_us         - pi_us_mean;
pi_w_mean           = raw_means(6);  pi_w          = pi_w          - pi_w_trend;     % TVD
dln_c_mean          = raw_means(7);  dln_c         = dln_c         - dln_c_trend;    % TVD
dln_ib_mean         = raw_means(8);  dln_ib        = dln_ib        - dln_ib_trend;   % TVD
i_10y_mean          = raw_means(9);  i_10y         = i_10y         - i_10y_mean;
wt_H_real_gap_mean  = raw_means(10); wt_H_real_gap = wt_H_real_gap - wt_H_real_gap_mean;

%% Round 1.2 Option 4 (2026-05-23): NaN-out wt_H_real_gap during identified
% fiscal-stimulus quarters where the social-assistance series spikes without
% a corresponding consumption rise (households save the windfall). Removing
% these quarters from the wt_H_real_gap likelihood identifies b_HtM from
% normal-times cyclical wage variation only. Dynare's diffuse_filter handles
% NaN observations cleanly: the Kalman filter skips them for this observable
% while keeping all other observables intact in the same quarter.
%   GFC stimulus (Rudd cash bonus): 2008Q4, 2009Q1
%   COVID + JobKeeper:              2020Q1, 2020Q2, 2020Q3, 2020Q4
NAN_STIMULUS_QUARTERS = true;
if NAN_STIMULUS_QUARTERS
    sample_dates = base_dates(sample_range);
    stim_dates = [datetime(2008,10,1); datetime(2009,1,1); ...
                  datetime(2020,1,1); datetime(2020,4,1); datetime(2020,7,1); datetime(2020,10,1)];
    stim_mask = ismember(sample_dates, stim_dates);
    wt_H_real_gap(stim_mask) = NaN;
    fprintf('\nOption 4: NaN-d %d stimulus quarters in wt_H_real_gap (b_HtM identified from normal-times only)\n', sum(stim_mask));
    fprintf('  Stimulus quarters: '); fprintf('%s ', datestr(stim_dates(ismember(stim_dates, sample_dates)),'yyyyQQ')); fprintf('\n');
end

%% Summary statistics
fprintf('\n--- Demeaned data summary (T=%d) ---\n', nObs);
varnames = {'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
            'pi_w', 'dln_c', 'dln_ib', 'i_10y', 'wt_H_real_gap'};
data_mat = [yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y, wt_H_real_gap];
fprintf('%-14s %8s %8s %8s %8s\n', 'Variable', 'Mean', 'Std', 'Min', 'Max');
for j = 1:length(varnames)
    v = data_mat(:, j);
    fprintf('%-14s %8.4f %8.4f %8.4f %8.4f\n', varnames{j}, ...
        mean(v), std(v), min(v), max(v));
end

%% Save for Dynare estimation
% Dynare expects a .mat file with variables named as in varobs statement,
% each as a column vector of length nObs.
%
% Option α (2026-05-23): when DEMEAN_MODE='none', the model's varobs uses
% dln_C_obs / dln_IB_obs (= cycle + trend) instead of dln_c / dln_ib (cycle).
% Save the same numeric series under both names so a varobs swap doesn't
% require regenerating the .mat. Other DEMEAN_MODE values use dln_c / dln_ib.
dln_C_obs  = dln_c;   % same numeric series; field-name matches new varobs
dln_IB_obs = dln_ib;  % same numeric series; field-name matches new varobs

outfile = fullfile(projectdir, 'dynare', 'estimation_data.mat');
save(outfile, 'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
     'pi_w', 'dln_c', 'dln_ib', 'dln_C_obs', 'dln_IB_obs', 'i_10y', 'wt_H_real_gap');
fprintf('\nSaved %d obs x %d variables to %s\n', nObs, length(varnames), outfile);

% Also save metadata
meta = struct();
meta.sample_start = base_dates(first_valid);
meta.sample_end   = base_dates(last_valid);
meta.nObs         = nObs;
meta.varnames     = varnames;
meta.demean_values = struct( ...
    'yhat_au_mean', yhat_au_mean, ...
    'pi_au_mean', pi_au_mean, ...
    'i_au_mean', i_au_mean, ...
    'yhat_us_mean', yhat_us_mean, ...
    'pi_us_mean', pi_us_mean, ...
    'pi_w_mean', pi_w_mean, ...
    'dln_c_mean', dln_c_mean, ...
    'dln_ib_mean', dln_ib_mean, ...
    'i_10y_mean', i_10y_mean, ...
    'wt_H_real_gap_mean', wt_H_real_gap_mean);
save(fullfile(projectdir, 'dynare', 'estimation_meta.mat'), 'meta');

fprintf('\n=== Estimation data preparation complete ===\n');


%% ==================== Local helpers (R2016b+ scripts) =====================
function y = fill_nan_lin(x)
% Linear interpolation of internal NaNs (and constant-extrapolation at ends).
    x = x(:);
    valid_idx = find(~isnan(x));
    if length(valid_idx) < 2
        y = x;
        return;
    end
    y = interp1(valid_idx, x(valid_idx), (1:length(x))', 'linear', 'extrap');
end

function trend = local_hp_trend(x, lambda)
% Two-sided HP-filter trend with smoothing parameter lambda.
    x = x(:);
    n = length(x);
    if n < 3
        trend = x;
        return;
    end
    I = speye(n);
    D = spdiags([ones(n-2,1) -2*ones(n-2,1) ones(n-2,1)], 0:2, n-2, n);
    trend = (I + lambda * (D' * D)) \ x;
end
