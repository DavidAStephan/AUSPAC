%% prepare_estimation_data.m
% Transforms raw CSV data into Dynare-compatible format for Bayesian estimation.
%
% Loads dataset.csv (E-SAT core) + extended_dataset.csv (demand/labor/financial)
% + trend_series.mat (Phase L1.2 HP-filtered trend objects), transforms to
% model-consistent units (quarterly %, demeaned), aligns sample, and saves
% as dynare/estimation_data.mat.
%
% Observable mapping (10 variables):
%   yhat_au     <- au_ygap                          (already quarterly %)
%   pi_au       <- au_pi                            (already quarterly %)
%   i_au        <- au_irate / 4                     (annualized -> quarterly)
%   yhat_us     <- us_ygap                          (already quarterly %)
%   pi_us       <- us_pi                            (already quarterly %)
%   pi_w        <- au_pi_w                          (log-diff of synthetic ULC, quarterly %)
%   dln_c       <- 100*dlog(au_consumption)         (log-diff)
%   dln_ib      <- 100*dlog(au_gfcf_nondwelling)    (log-diff, non-dwelling GFCF)
%   i_10y       <- au_i10 / 4                       (annualized -> quarterly)
%   dy_bar_gap  <- 100*dlog_ybar - mean             (Phase L1.3 wp1044 Eq 35 growth-
%                                                    neutrality trend, demeaned)

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

% --- Phase L1.3: trend GDP growth from Phase L1.2 HP filter ---
% Loaded from data/trend_series.mat (built by compute_trend_objects.m).
% dlog_ybar is decimal q/q growth on the supply-data sample (1990Q1+);
% align to base_dates via year/quarter match and convert to quarterly %.
trend_path = fullfile(outdir, 'trend_series.mat');
if ~isfile(trend_path)
    error('prepare_estimation_data:no_trend', ...
        'Missing %s.  Run compute_trend_objects.m first.', trend_path);
end
TS = load(trend_path);
dy_bar_raw = nan(nB, 1);
for i = 1:nB
    bd = base_dates(i);
    match = find(year(TS.dates) == year(bd) & quarter(TS.dates) == quarter(bd), 1);
    if ~isempty(match)
        dy_bar_raw(i) = TS.dlog_ybar(match);
    end
end
dy_bar_raw = dy_bar_raw * 100;   % convert decimal -> quarterly %

fprintf('  yhat_au:    %d valid obs\n', sum(~isnan(yhat_au_raw)));
fprintf('  pi_au:      %d valid obs\n', sum(~isnan(pi_au_raw)));
fprintf('  i_au:       %d valid obs\n', sum(~isnan(i_au_raw)));
fprintf('  yhat_us:    %d valid obs\n', sum(~isnan(yhat_us_raw)));
fprintf('  pi_us:      %d valid obs\n', sum(~isnan(pi_us_raw)));
fprintf('  pi_w:       %d valid obs\n', sum(~isnan(pi_w_raw)));
fprintf('  dln_c:      %d valid obs\n', sum(~isnan(dln_c_raw)));
fprintf('  dln_ib:     %d valid obs\n', sum(~isnan(dln_ib_raw)));
fprintf('  i_10y:      %d valid obs\n', sum(~isnan(i_10y_raw)));
fprintf('  dy_bar_gap: %d valid obs (from trend_series.mat)\n', sum(~isnan(dy_bar_raw)));

%% Find common sample (no NaN in any observable)
all_data = [yhat_au_raw, pi_au_raw, i_au_raw, yhat_us_raw, pi_us_raw, ...
            pi_w_raw, dln_c_raw, dln_ib_raw, i_10y_raw, dy_bar_raw];
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
yhat_au    = all_data(sample_range, 1);
pi_au      = all_data(sample_range, 2);
i_au       = all_data(sample_range, 3);
yhat_us    = all_data(sample_range, 4);
pi_us      = all_data(sample_range, 5);
pi_w       = all_data(sample_range, 6);
dln_c      = all_data(sample_range, 7);
dln_ib     = all_data(sample_range, 8);
i_10y      = all_data(sample_range, 9);
dy_bar_gap = all_data(sample_range, 10);
nObs = length(sample_range);

%% Demean
% Dynare estimation with gap/growth variables expects demeaned data.
% For interest rates: subtract steady-state values from au_pac.mod.
% For gap variables: already zero-mean by construction.
% For growth rates: subtract sample mean (≈ steady-state growth).

fprintf('\nDemeaning (subtracting sample means for all variables)...\n');
% Dynare estimation requires demeaned data when the model is written in
% deviations from steady state. Using sample means (rather than model SS)
% avoids systematic bias from the low-rate era not matching historical SS.

varnames_raw = {'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
                'pi_w', 'dln_c', 'dln_ib', 'i_10y', 'dy_bar_gap'};
raw_means = mean([yhat_au, pi_au, i_au, yhat_us, pi_us, ...
                   pi_w, dln_c, dln_ib, i_10y, dy_bar_gap]);

for j = 1:length(varnames_raw)
    fprintf('  %s mean: %.4f (subtracting)\n', varnames_raw{j}, raw_means(j));
end

yhat_au_mean    = raw_means(1);  yhat_au    = yhat_au    - yhat_au_mean;
pi_au_mean      = raw_means(2);  pi_au      = pi_au      - pi_au_mean;
i_au_mean       = raw_means(3);  i_au       = i_au       - i_au_mean;
yhat_us_mean    = raw_means(4);  yhat_us    = yhat_us    - yhat_us_mean;
pi_us_mean      = raw_means(5);  pi_us      = pi_us      - pi_us_mean;
pi_w_mean       = raw_means(6);  pi_w       = pi_w       - pi_w_mean;
dln_c_mean      = raw_means(7);  dln_c      = dln_c      - dln_c_mean;
dln_ib_mean     = raw_means(8);  dln_ib     = dln_ib     - dln_ib_mean;
i_10y_mean      = raw_means(9);  i_10y      = i_10y      - i_10y_mean;
dy_bar_gap_mean = raw_means(10); dy_bar_gap = dy_bar_gap - dy_bar_gap_mean;

%% Summary statistics
fprintf('\n--- Demeaned data summary (T=%d) ---\n', nObs);
varnames = {'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
            'pi_w', 'dln_c', 'dln_ib', 'i_10y', 'dy_bar_gap'};
data_mat = [yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y, dy_bar_gap];
fprintf('%-10s %8s %8s %8s %8s\n', 'Variable', 'Mean', 'Std', 'Min', 'Max');
for j = 1:length(varnames)
    v = data_mat(:, j);
    fprintf('%-10s %8.4f %8.4f %8.4f %8.4f\n', varnames{j}, ...
        mean(v), std(v), min(v), max(v));
end

%% Save for Dynare estimation
% Dynare expects a .mat file with variables named as in varobs statement,
% each as a column vector of length nObs.
outfile = fullfile(projectdir, 'dynare', 'estimation_data.mat');
save(outfile, 'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
     'pi_w', 'dln_c', 'dln_ib', 'i_10y', 'dy_bar_gap');
fprintf('\nSaved %d obs x 10 variables to %s\n', nObs, outfile);

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
    'dy_bar_gap_mean', dy_bar_gap_mean);
save(fullfile(projectdir, 'dynare', 'estimation_meta.mat'), 'meta');

fprintf('\n=== Estimation data preparation complete ===\n');
