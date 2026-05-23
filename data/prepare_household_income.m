%% prepare_household_income.m — Construct Round 1.2 household labour+transfer
%% income series from ABS 5206 Table 20 + Table 23, splice CPI deflator,
%% and append wt_H_real_gap column to extended_dataset.csv.
%%
%% Source ABS series (Seasonally Adjusted, $ Millions, quarterly):
%%   A2302915V  Compensation of employees received by households (W_H)
%%   A2302919C  Social assistance benefits in cash received (TG_H detail)
%%   A2302939L  Gross disposable income (cross-check)
%%   A2304037L  Final consumption expenditure (deflator base)
%%
%% Round 1.2 channel (FR-BDF wp1044 §3.5.1 eq 35):
%%   + b_HtM · Delta[log(W_H + TG_H) - p_C - y_per_capita]
%%
%% wt_H_real_gap_t = log((W_H + TG_H)/p_C) - HP-trend
%%   (gap form, demeaned, ready to enter as a model state alongside yhat_au)
%%
%% Author: AUSPAC project, 2026-05-21.

clear; clc;

dataroot = fileparts(mfilename('fullpath'));
hi_xlsx  = fullfile(dataroot, 'abs_rba', 'abs_5206_household_income.xlsx');
ext_csv  = fullfile(dataroot, 'extended_dataset.csv');

assert(exist(hi_xlsx, 'file') == 2, 'Missing %s', hi_xlsx);
assert(exist(ext_csv, 'file') == 2, 'Missing %s', ext_csv);

% --- Load Table 20 ----------------------------------------------------------
fprintf('Reading %s...\n', hi_xlsx);
[~, ~, raw] = xlsread(hi_xlsx, 'Data1');
% Row 10 is Series IDs, row 11+ is data with column 1 = date
series_ids = string(raw(10, 2:end));
dates_raw  = raw(11:end, 1);
data_raw   = cell2mat(raw(11:end, 2:end));

% Convert ABS date strings to MATLAB datenum
dates_num = nan(numel(dates_raw), 1);
for i = 1:numel(dates_raw)
    if ischar(dates_raw{i}) || isstring(dates_raw{i})
        dates_num(i) = datenum(dates_raw{i});
    elseif isnumeric(dates_raw{i})
        dates_num(i) = dates_raw{i} + datenum('1900-01-01') - 2;  % Excel epoch
    end
end

pick = @(sid) data_raw(:, find(series_ids == sid, 1));
W_H   = pick('A2302915V');   % Compensation of employees, SA, $M
TG_H  = pick('A2302919C');   % Social assistance benefits, SA, $M
Y_H   = pick('A2302939L');   % Gross disposable income, SA, $M (cross-check)
C_H   = pick('A2304037L');   % Final consumption expenditure (nominal), SA, $M

assert(~isempty(W_H), 'Series A2302915V not found in Table 20');
assert(~isempty(TG_H), 'Series A2302919C not found in Table 20');

% --- Construct nominal household labour+transfer income ---------------------
labtrans = W_H + TG_H;                    % $M, SA, quarterly (Round 1.2 base)
% Round 1.2 Option 2 (2026-05-23): decompose into wages-only and transfers-only
% so the HtM channel can have separate elasticities. Wages are smoothly cyclical
% (no GFC stimulus / JobKeeper spikes); transfers are spike-dominated.
labtrans_W  = W_H;                        % wages-only
labtrans_TG = TG_H;                       % transfers-only

% --- CPI deflator: implicit deflator p_C = nominal consumption / real consumption
%     We already have nominal C in column C_H, and existing extended_dataset.csv
%     has au_consumption in nominal $. Use that consistency: p_C ≡ 1 here, so
%     wt_H_real = log(labtrans) - log(C_real) is the LABOR-INCOME-TO-CONSUMPTION ratio.
%     Alternative: use ABS 5206 IPDs for an explicit p_C. For first pass we use
%     the cleaner ratio form which is what the FR-BDF eq 35 effectively becomes
%     under wp1044's assumption that p_C is the consumption deflator.

% Real consumption per capita is a cleaner reference than yhat_au directly;
% but since the model uses yhat_au as the per-capita output proxy, we form:
%   wt_real_logged = log(labtrans / p_C)
% and the model will reference Delta(wt_real_logged - yhat_au).
% For p_C we use the ABS 5206 IPD for final consumption.

ipd_xlsx = fullfile(dataroot, 'abs_rba', 'abs_5206_ipd.xlsx');
fprintf('Reading %s for consumption IPD...\n', ipd_xlsx);
[~, ~, raw_ipd] = xlsread(ipd_xlsx, 'Data1');
ipd_ids   = string(raw_ipd(10, 2:end));
ipd_dates = raw_ipd(11:end, 1);
ipd_data  = cell2mat(raw_ipd(11:end, 2:end));

% Households final consumption expenditure IPD, Seasonally Adjusted: A2303940R
pC_col = find(ipd_ids == 'A2303940R', 1);
assert(~isempty(pC_col), 'Series A2303940R (Households HFCE IPD, SA) not found in Table 5.');
p_C_raw = ipd_data(:, pC_col);

% Align dates
ipd_dates_num = nan(numel(ipd_dates), 1);
for i = 1:numel(ipd_dates)
    if ischar(ipd_dates{i}) || isstring(ipd_dates{i})
        ipd_dates_num(i) = datenum(ipd_dates{i});
    elseif isnumeric(ipd_dates{i})
        ipd_dates_num(i) = ipd_dates{i} + datenum('1900-01-01') - 2;
    end
end

[common_dates, ia, ib] = intersect(dates_num, ipd_dates_num);
labtrans_aligned    = labtrans(ia);
labtrans_W_aligned  = labtrans_W(ia);     % Option 2: wages-only
labtrans_TG_aligned = labtrans_TG(ia);    % Option 2: transfers-only
p_C_aligned         = p_C_raw(ib);

% Real series (deflated by HFCE IPD rebased to fraction)
deflator      = p_C_aligned / 100;
labtrans_real    = labtrans_aligned    ./ deflator;
labtrans_W_real  = labtrans_W_aligned  ./ deflator;
labtrans_TG_real = labtrans_TG_aligned ./ deflator;
log_lt_real    = log(labtrans_real);
log_W_real     = log(labtrans_W_real);
log_TG_real    = log(labtrans_TG_real);

% --- Construct gap variables -----------------------------------------------
% HP filter each log series to get a smooth trend; gap = level - trend.
T = numel(log_lt_real);
lambda = 1600;
I = speye(T);
D = spdiags([ones(T-2,1) -2*ones(T-2,1) ones(T-2,1)], 0:2, T-2, T);
HPmat = (I + lambda * (D' * D));
trend       = HPmat \ log_lt_real;
trend_W     = HPmat \ log_W_real;
trend_TG    = HPmat \ log_TG_real;
log_lt_gap = log_lt_real - trend;
log_W_gap  = log_W_real  - trend_W;
log_TG_gap = log_TG_real - trend_TG;

% --- Merge into extended_dataset.csv ---------------------------------------
% ABS uses end-of-quarter dating (Mar/Jun/Sep/Dec); extended_dataset.csv uses
% start-of-quarter (Jan/Apr/Jul/Oct). Align by year+quarter rather than exact date.
fprintf('Reading %s...\n', ext_csv);
ext = readtable(ext_csv);

ext_dates_num = datenum(ext.date);
[ext_y, ext_m] = datevec(ext_dates_num);
ext_q = floor((ext_m - 1) / 3) + 1;           % 1..4

[abs_y, abs_m] = datevec(common_dates);
abs_q = floor((abs_m - 1) / 3) + 1;

wt_H_real_gap   = nan(height(ext), 1);
wt_H_W_gap      = nan(height(ext), 1);
wt_H_TG_gap     = nan(height(ext), 1);
for i = 1:height(ext)
    idx = find(abs_y == ext_y(i) & abs_q == ext_q(i), 1);
    if ~isempty(idx)
        wt_H_real_gap(i) = log_lt_gap(idx);
        wt_H_W_gap(i)    = log_W_gap(idx);
        wt_H_TG_gap(i)   = log_TG_gap(idx);
    end
end

ext.au_wt_H_real_gap = wt_H_real_gap;
ext.au_wt_H_W_gap    = wt_H_W_gap;       % Option 2: wages-only
ext.au_wt_H_TG_gap   = wt_H_TG_gap;      % Option 2: transfers-only
writetable(ext, ext_csv);

fprintf('Appended au_wt_H_real_gap / au_wt_H_W_gap / au_wt_H_TG_gap to %s (n=%d non-NaN of %d rows).\n', ...
        ext_csv, sum(~isnan(wt_H_real_gap)), height(ext));
fprintf('  Wages-only      sd = %.4f, range [%+.3f, %+.3f]\n', ...
        std(log_W_gap,'omitnan'), min(log_W_gap), max(log_W_gap));
fprintf('  Transfers-only  sd = %.4f, range [%+.3f, %+.3f]\n', ...
        std(log_TG_gap,'omitnan'), min(log_TG_gap), max(log_TG_gap));
fprintf('  Combined (W+TG) sd = %.4f, range [%+.3f, %+.3f]\n', ...
        std(log_lt_gap,'omitnan'), min(log_lt_gap), max(log_lt_gap));

% --- Quick diagnostic plot --------------------------------------------------
try
    fig = figure('Visible', 'off');
    plot(common_dates, log_lt_gap, 'b-', 'LineWidth', 1.2);
    datetick('x', 'yyyy');
    grid on; xlabel('Date'); ylabel('log(W_H+TG_H)/p_C, HP-gap (\lambda=1600)');
    title('AU Household Labor+Transfer Real Income Gap (Round 1.2 source)');
    out_png = fullfile(dataroot, 'wt_H_real_gap_diag.png');
    print(fig, out_png, '-dpng', '-r120');
    close(fig);
    fprintf('Diagnostic plot: %s\n', out_png);
catch ME
    fprintf('Plot skipped: %s\n', ME.message);
end

fprintf('Done.\n');
