%% prepare_l2_data_extras.m
%
% Phase L2-extension: close 4 of the 5 wp1044 gaps documented in
% BLOCK_LIMITATIONS.md, by sourcing AU data we already have locally and
% adding the resulting series to l2_data_layer.mat.
%
% Series added:
%   exports         A2304114F SA volume from abs_5206_vol.xlsx
%   imports         A2304115J SA volume from abs_5206_vol.xlsx
%   df_full         consumption + housing + exports (now with exports!)
%   Delta_df_full   df_full growth
%   Delta_df_bar_full  HP trend of df_full growth
%   p_IH            new-dwellings IPD A2303713R from abs_5206_ipd.xlsx
%   p_SH            ABS 6416 RPPI weighted-8-cities (Index Numbers)
%                   -- only available from ~2003Q3 onwards
%   r_KB_wacc       proper user cost = wacc + delta_q - pi_Q
%                   wacc = 0.55·i_10y + 0.45·i_au  (AU proxy weights)
%   Delta_log_r_KB_wacc, Delta_log_r_KB_wacc_bar  -- wacc-based user-cost
%                                                    decomposition
%
% Inputs:
%   data/l2_data_layer.mat  (Phase A output)
%   dynare/supply_data.mat
%   data/abs_rba/abs_5206_vol.xlsx  (exports, imports volume)
%   data/abs_rba/abs_5206_ipd.xlsx  (housing IPD)
%   data/abs_rba/abs_6416_rppi.csv  (RPPI weighted average)
%
% Output:
%   data/l2_data_layer_v2.mat  (= l2_data_layer.mat + 10 new fields)

clear; clc;
fprintf('=== Phase L2-extras: close 4 of 5 wp1044 data gaps ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
L2 = load(fullfile(projectdir, 'data', 'l2_data_layer.mat'));
S  = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));

supply_dates = L2.dates;
nQ = L2.nQ;

%% 1. Exports + Imports (volumes, SA)
xlsx_vol = fullfile(projectdir, 'data', 'abs_rba', 'abs_5206_vol.xlsx');
fprintf('Reading exports/imports from %s...\n', xlsx_vol);
ex = read_abs_series(xlsx_vol, 'A2304114F');
im = read_abs_series(xlsx_vol, 'A2304115J');

% Align to supply_dates
exports = align_q(ex.vals, ex.dates, supply_dates);
imports = align_q(im.vals, im.dates, supply_dates);
fprintf('exports: %d valid obs, mean=%.0f $M\n', sum(~isnan(exports)), mean(exports, 'omitnan'));
fprintf('imports: %d valid obs, mean=%.0f $M\n', sum(~isnan(imports)), mean(imports, 'omitnan'));

%% 2. Build df_full = c + ih + exports
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
ext_dates = datetime(ext.date);
c_full   = align_q(ext.au_consumption,   ext_dates, supply_dates);
ih_full  = align_q(ext.au_gfcf_dwelling, ext_dates, supply_dates);

df_full = c_full + ih_full + exports;
log_df_full = log(df_full);
Delta_df_full = [NaN; diff(log_df_full)] * 100;
Delta_df_bar_full = hp_trend(Delta_df_full, 1600);
fprintf('df_full (c + ih + exports): %d valid obs\n', sum(~isnan(df_full)));

%% 3. p_IH: new dwellings IPD (A2303713R)
xlsx_ipd = fullfile(projectdir, 'data', 'abs_rba', 'abs_5206_ipd.xlsx');
fprintf('Reading dwellings IPD from %s...\n', xlsx_ipd);
ipd_dwell = read_abs_series(xlsx_ipd, 'A2303713R');
p_IH = align_q(ipd_dwell.vals, ipd_dwell.dates, supply_dates);
fprintf('p_IH (dwellings IPD): %d valid obs\n', sum(~isnan(p_IH)));

%% 4. p_SH: ABS 6416 RPPI weighted-8-cities (Index Numbers, col 10 in CSV)
csv_rppi = fullfile(projectdir, 'data', 'abs_rba', 'abs_6416_rppi.csv');
fprintf('Reading RPPI from %s...\n', csv_rppi);
% Force dd/MM/uuuu parsing -- ABS RPPI uses Australian date format
opts = detectImportOptions(csv_rppi, 'NumHeaderLines', 9);
opts.VariableTypes{1} = 'char';      % read date as string first
T_rppi = readtable(csv_rppi, opts);
rppi_dates_str = T_rppi.(opts.VariableNames{1});
rppi_dates = datetime(rppi_dates_str, 'InputFormat', 'dd/MM/uuuu');
rppi_index = T_rppi.(opts.VariableNames{10});
p_SH = align_q(rppi_index, rppi_dates, supply_dates);
fprintf('p_SH (RPPI 8-cities): %d valid obs (RPPI starts ~2003)\n', sum(~isnan(p_SH)));

%% 5. r_KB wacc proxy
% wp1044's wacc uses cost of equity + BBB bond + bank lending rate weights.
% AU proxy: weight the long bond and short rate as a first-order
% approximation: wacc ≈ 0.55·i_10y + 0.45·i_au
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
base_dates = datetime(T_base.date);
i_10y_aligned = align_q(ext.au_i10, ext_dates, supply_dates);   % annualised %
i_au_aligned  = align_q(T_base.au_irate, base_dates, supply_dates); % annualised %

wacc = 0.55 * i_10y_aligned + 0.45 * i_au_aligned;     % annualised %, weighted
delta_q = S.delta_q;       % quarterly decimal
piQ = L2.piQ;              % q/q %

% Real user cost: r_KB = wacc/4 (quarterly nominal rate) + delta_q - piQ/100
r_KB_wacc = wacc / 400 + delta_q - piQ / 100;
log_r_KB_wacc = log(max(r_KB_wacc, 1e-6));
log_r_KB_wacc_trend = hp_trend(log_r_KB_wacc, 1600);
Delta_log_r_KB_wacc = [NaN; diff(log_r_KB_wacc)] * 100;
Delta_log_r_KB_wacc_bar = hp_trend(Delta_log_r_KB_wacc, 1600);
fprintf('wacc (0.55*i_10y + 0.45*i_au): mean=%.2f%% p.a.\n', mean(wacc, 'omitnan'));
fprintf('r_KB_wacc: mean=%.4f, sd=%.4f (quarterly decimal)\n', ...
    mean(r_KB_wacc, 'omitnan'), std(r_KB_wacc, 'omitnan'));

%% 6. Pack as v2 -- copy L2 + add new fields
out = L2;
out.exports = exports;
out.imports = imports;
out.df_full = df_full;
out.Delta_df_full = Delta_df_full;
out.Delta_df_bar_full = Delta_df_bar_full;
out.p_IH = p_IH;
out.p_SH = p_SH;
out.wacc = wacc;
out.r_KB_wacc = r_KB_wacc;
out.Delta_log_r_KB_wacc = Delta_log_r_KB_wacc;
out.Delta_log_r_KB_wacc_bar = Delta_log_r_KB_wacc_bar;
out.note_v2 = 'L2 data layer v2: exports/imports, p_IH/p_SH, df_full, r_KB_wacc';

save(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'), '-struct', 'out');
fprintf('\nSaved data/l2_data_layer_v2.mat (with %d fields)\n', length(fieldnames(out)));

fprintf('\n=== Phase L2-extras complete ===\n');

%% Helpers
function v = read_abs_series(filename, series_id)
    [~, ~, raw] = xlsread(filename, 'Data1');
    ids = string(raw(10, 2:end));
    col_idx = find(ids == series_id, 1);
    if isempty(col_idx)
        error('Series %s not found in %s', series_id, filename);
    end
    col_data = raw(11:end, col_idx + 1);
    raw_dates = raw(11:end, 1);
    n = length(col_data);
    dates_out = nan(n, 1);
    vals = nan(n, 1);
    for i = 1:n
        d = raw_dates{i};
        if ischar(d) || isstring(d)
            try, dates_out(i) = datenum(d); catch, dates_out(i) = NaN; end
        elseif isnumeric(d) && ~isempty(d)
            dates_out(i) = d + datenum('1900-01-01') - 2;
        end
        vc = col_data{i};
        if isnumeric(vc) && ~isempty(vc), vals(i) = double(vc); end
    end
    v = struct('dates', datetime(dates_out, 'ConvertFrom', 'datenum'), ...
               'vals', vals);
end

function vq = align_q(src_col, src_dates, target_dates)
    nq = length(target_dates);
    vq = nan(nq, 1);
    for i = 1:nq
        m = find(year(src_dates) == year(target_dates(i)) & quarter(src_dates) == quarter(target_dates(i)), 1);
        if ~isempty(m), vq(i) = src_col(m); end
    end
end
function trend = hp_trend(y, lambda)
    y = y(:); n = length(y); trend = nan(n, 1);
    valid = find(~isnan(y)); if length(valid) < 4, return; end
    lo = valid(1); hi = valid(end); span = lo:hi; y_span = y(span);
    nm = isnan(y_span);
    if any(nm), idx = find(~nm); y_span = interp1(idx, y_span(idx), 1:length(y_span), 'linear')'; end
    n_span = length(y_span); e = ones(n_span, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n_span-2, n_span);
    A = speye(n_span) + lambda * (D2' * D2);
    trend(span) = A \ y_span;
end
