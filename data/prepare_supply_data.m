%% prepare_supply_data.m
% Phase G Stage 0: read the 9 ABS xlsx files downloaded by
% download_supply_data.m and build a clean quarterly supply-side dataset
% covering 1990Q1-2024Q4 for the FR-BDF Section 4.3 CES production-function
% calibration.
%
% Output: dynare/supply_data.mat (see field list at end).

clear; clc;
fprintf('=== Phase G Stage 0: Supply-side data preparation ===\n\n');

datadir = fullfile(fileparts(mfilename('fullpath')), 'abs_rba');
projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% Master quarterly date grid: 1990Q1 to 2024Q4
qstart = datetime(1990, 1, 1);
qend   = datetime(2024, 10, 1);
dates_q = (qstart:calmonths(3):qend)';
nQ = length(dates_q);
fprintf('Master grid: %d quarters from %s to %s\n\n', nQ, ...
    datestr(dates_q(1)), datestr(dates_q(end)));

%% 1. ABS 5206 Tab 6: industry GVA
% ABS 5206 Tab 6 column structure (Data1 = chain volumes, Data2 = current prices):
%   col 1-50: industry-level volumes (ANZSIC sectors A-S)
%   col 46: Public administration and safety (O)        — exclude (non-market)
%   col 47: Education and training (P)                  — exclude
%   col 48: Health care and social assistance (Q)       — exclude
%   col 51: Ownership of dwellings                      — exclude (imputed rent)
%   col 52: Gross value added at basic prices (TOTAL)   — total GVA
%   col 53: Taxes less subsidies on products
%   col 55: GROSS DOMESTIC PRODUCT (= 52 + 53 + statistical discrepancy)
% Market sector = col 52 − (col 46 + col 47 + col 48 + col 51)
fprintf('Reading abs_5206_industry_gva.xlsx ... ');
[d, vol, h] = read_abs(fullfile(datadir, 'abs_5206_industry_gva.xlsx'));
fprintf('Data1 (volumes): %d obs, %d series\n', length(d), size(vol, 2));

% Series Type layout: cols 1-109 = Trend, cols 110-218 = Seasonally Adjusted,
% cols 219-251 = Original / percentage changes (audit 2026-05-11).
% v1 of this script used the Trend block (cols 46-55), which produces the
% smoothing-artifact pathology described in Phase D §4.8 of the paper —
% Trend series over-smooth their own short-run variation, biasing any
% regression that involves growth rates or gaps. Switching to the SA block
% (cols +109 offset = 155-164) preserves Trend's seasonal-correction
% property without the trend smoothing.
TREND_TO_SA_OFFSET = 109;
% Sanity: confirm col 161 (SA GVA at basic prices) is what we expect.
if ~contains(lower(h{52 + TREND_TO_SA_OFFSET}), 'gross value added')
    error('ABS 5206 Tab 6 col %d header is "%s" — expected SA GVA at basic prices', ...
          52 + TREND_TO_SA_OFFSET, h{52 + TREND_TO_SA_OFFSET});
end

q_total_vol_full   = vol(:, 52 + TREND_TO_SA_OFFSET);
q_pubadmin_vol     = vol(:, 46 + TREND_TO_SA_OFFSET);
q_education_vol    = vol(:, 47 + TREND_TO_SA_OFFSET);
q_health_vol       = vol(:, 48 + TREND_TO_SA_OFFSET);
q_dwellings_vol    = vol(:, 51 + TREND_TO_SA_OFFSET);
q_market_vol_full  = q_total_vol_full - q_pubadmin_vol - q_education_vol - q_health_vol - q_dwellings_vol;

q_total_vol = align_to_q(d, q_total_vol_full, dates_q);
q_market_vol = align_to_q(d, q_market_vol_full, dates_q);
fprintf('  Total GVA (chain vol, col 52):   %d valid obs\n', sum(~isnan(q_total_vol)));
fprintf('  Market sector (52 − 46 − 47 − 48 − 51): %d valid obs\n', sum(~isnan(q_market_vol)));
fprintf('    Market share of GVA (mean): %.1f%%\n', 100*mean(q_market_vol_full ./ q_total_vol_full, 'omitnan'));

% VA deflator: use ABS 5206 Tab 5 (Implicit Price Deflators) directly rather
% than computing nominal/real from Data2 (Data2 has trailing zeros that
% break log(0)). The IPD file already has GDP IPD as a published series.
try
    [d_ipd, v_ipd, h_ipd] = read_abs(fullfile(datadir, 'abs_5206_ipd.xlsx'));
    fprintf('  ABS 5206 IPD: %d obs, %d series\n', length(d_ipd), size(v_ipd, 2));
    % Find GDP IPD
    idx_gdp_ipd = find(contains(lower(h_ipd), 'gross domestic product'), 1);
    if isempty(idx_gdp_ipd)
        fprintf('    GDP IPD not found, headers (first 20):\n');
        for i = 1:min(20, length(h_ipd)), fprintf('    %d: %s\n', i, h_ipd{i}); end
        p_q_total = nan(nQ, 1);
    else
        p_q_total_idx = align_to_q(d_ipd, v_ipd(:, idx_gdp_ipd), dates_q);
        p_q_total = p_q_total_idx;  % index, not a ratio
        fprintf('  GDP IPD aligned: %d valid obs (col %d: %s)\n', sum(~isnan(p_q_total)), idx_gdp_ipd, h_ipd{idx_gdp_ipd});
    end
catch ME
    fprintf('  IPD file not readable: %s\n', ME.message);
    p_q_total = nan(nQ, 1);
end
% Market sector deflator: use total as a proxy until we have a separate market IPD
p_q_market = p_q_total;

%% 2. ABS 6202 Tab 1: Labour Force aggregates (monthly)
% Each ABS series typically appears 3 times in succession: Original, Trend,
% Seasonally Adjusted. We want SA, which is the 3rd occurrence.
% Confirmed cols (from diagnose_stage0): col 3 = Employed total Persons SA,
% col 66 = Unemployment rate Persons SA, col 93 = Labour force total Persons SA.
fprintf('\nReading abs_6202_labour_force.xlsx ... ');
[d, v, h] = read_abs(fullfile(datadir, 'abs_6202_labour_force.xlsx'));
fprintf('%d obs, %d series\n', length(d), size(v, 2));

% FIX 2026-05-30 (§6.14): the occurrence order in abs_6202_labour_force.xlsx is
% Trend(1)/Seasonally-Adjusted(2)/Original(3) — so the old emp_cols(3) "3rd = SA"
% actually picked the ORIGINAL (NSA) series, injecting seasonality into emp/urate/lf
% and their consumers (wage Phillips u-term, u_gap). Use the robust pick_sa_col
% helper (reads the Series Type metadata row) as hours/WPI already do.
lab_file = fullfile(datadir, 'abs_6202_labour_force.xlsx');
emp_cols = find(contains(h, 'Employed total ;  Persons ;') & ~contains(h, '>'));
idx_emp  = pick_sa_col(lab_file, emp_cols);
n_total_raw = align_to_q(d, v(:, idx_emp), dates_q);
fprintf('  Employed persons SA:     %d valid obs (col %d: %s)\n', sum(~isnan(n_total_raw)), idx_emp, h{idx_emp});

% Unemployment rate SA
ur_cols = find(contains(h, 'Unemployment rate ;  Persons ;') & ~contains(h, '>'));
idx_ur  = pick_sa_col(lab_file, ur_cols);
urate = align_to_q(d, v(:, idx_ur), dates_q);
fprintf('  Unemployment rate SA:    %d valid obs (col %d: %s)\n', sum(~isnan(urate)), idx_ur, h{idx_ur});

% Labour force SA
lf_cols = find(contains(h, 'Labour force total ;  Persons ;') & ~contains(h, '>'));
idx_lf  = pick_sa_col(lab_file, lf_cols);
lf_raw = align_to_q(d, v(:, idx_lf), dates_q);
fprintf('  Labour force SA:         %d valid obs (col %d: %s)\n', sum(~isnan(lf_raw)), idx_lf, h{idx_lf});

%% 3. ABS 6202 Tab 19: hours
% Audit 2026-05-11: this file has only 2 column variants for the all-Persons
% aggregate — col 1 = Trend, col 2 = Seasonally Adjusted. The prior comment
% ("Col 1=Original, col 2=Trend, col 3=SA") was wrong, and the "3rd
% occurrence" fallback was silently picking col 1 (Trend). Now using the
% explicit SA column via Series Type lookup.
fprintf('\nReading abs_6202_hours.xlsx ... ');
[d, v, h] = read_abs(fullfile(datadir, 'abs_6202_hours.xlsx'));
fprintf('%d obs, %d series\n', length(d), size(v, 2));
hrs_cols = find(contains(h, 'Monthly hours worked in all jobs ;  Persons ;') & ~contains(h, '>'));
% Pick the SA variant. In the current file SA is col 2 (after col 1 Trend).
% Verify by reading the Series Type metadata row.
idx_hrs = pick_sa_col(fullfile(datadir, 'abs_6202_hours.xlsx'), hrs_cols);
hours_total = align_to_q(d, v(:, idx_hrs), dates_q);
fprintf('  Aggregate hours SA:      %d valid obs (col %d: %s)\n', sum(~isnan(hours_total)), idx_hrs, h{idx_hrs});
% Hours total is in '000 hours per month; employed is in '000 persons.
% Hours per worker per month = total_hours / employed_persons (both /1000 cancel)
h_per_worker = hours_total ./ n_total_raw;

%% 4. ABS 6345: WPI
% Audit 2026-05-11: this file has 9 columns each in Original / SA / Trend
% (27 cols total, plus aggregates). The previous "ordinary" search keyword
% didn't match any header (no header contains "ordinary") so the script
% fell back to idx_wpi = 1, which is Original (col 1 = Private All
% industries Original) — i.e., a SEASONAL series flowed into the supply
% data. Now pick the SA Private+Public All industries (col 6).
fprintf('\nReading abs_6345_wpi.xlsx ... ');
[d, v, h] = read_abs(fullfile(datadir, 'abs_6345_wpi.xlsx'));
fprintf('%d obs, %d series\n', length(d), size(v, 2));
% Find Private+Public + All industries headers, then pick the SA variant.
wpi_cands = find(contains(lower(h), 'private and public') & ...
                  contains(lower(h), 'all industries'));
if isempty(wpi_cands)
    error('abs_6345_wpi: no Private+Public All industries column found');
end
idx_wpi = pick_sa_col(fullfile(datadir, 'abs_6345_wpi.xlsx'), wpi_cands);
wpi = align_to_q(d, v(:, idx_wpi), dates_q);
fprintf('  WPI (SA):                %d valid obs (col %d: %s)\n', sum(~isnan(wpi)), idx_wpi, h{idx_wpi});

%% 5. ABS 6302: AWE
% Col 9 = "Earnings; Persons; Total earnings".
% Audit 2026-05-11: the downloaded abs_6302_awe.xlsx contains ONLY Trend
% variants (all 9 series cols flagged Trend in the Series Type metadata).
% This is a download-time selection issue (download_supply_data.m fetched
% the Trend-only sheet, not the full Original/Trend/SA workbook). The AWE
% series is used only at half-yearly + semi-annual frequencies in the
% supply-side calibration, so the Trend smoothing has less impact than for
% the GVA / hours / WPI series, but it is still flagged here as a known
% gap. To resolve, re-download abs_6302_awe.xlsx from the ABS 6302 Data1
% sheet (not Trend-only) and update read_abs to pick the SA col explicitly.
fprintf('\nReading abs_6302_awe.xlsx ... ');
[d, v, h] = read_abs(fullfile(datadir, 'abs_6302_awe.xlsx'));
fprintf('%d obs, %d series\n', length(d), size(v, 2));
idx_awe = find(contains(h, 'Earnings; Persons; Total earnings'), 1);
if isempty(idx_awe), idx_awe = 9; end
awe = align_to_q(d, v(:, idx_awe), dates_q);
fprintf('  AWE Persons Total (TREND — see comment): %d valid obs (col %d: %s)\n', ...
        sum(~isnan(awe)), idx_awe, h{idx_awe});

%% 6. ABS 5204 Tab 63: Net capital stock annual
% Col layout: chain-volumes block first (~112 cols), then current-prices block.
fprintf('\nReading abs_5204_net_capital_stock.xlsx ... ');
[d, v, h] = read_abs(fullfile(datadir, 'abs_5204_net_capital_stock.xlsx'));
fprintf('%d obs, %d series\n', length(d), size(v, 2));

% Column indices (chain-volume block):
%   6   = Agriculture, forestry and fishing
%   12  = Mining (B)
%   79  = Public administration and safety
%   84  = Education and training
%   89  = Health care and social assistance
%   103 = ALL INDUSTRIES ; Dwellings (asset type)
%   113 = ALL INDUSTRIES total (all assets, all industries)
% Current-prices block:
%   226 = ALL INDUSTRIES total current prices
idx_k_chain   = 113;
idx_k_cp      = 226;
idx_k_dwell   = 103;   % dwellings asset — not part of market-sector production
idx_k_pubadm  = 79;    % non-market industry
idx_k_edu     = 84;    % non-market industry
idx_k_health  = 89;    % non-market industry
idx_k_mining  = 12;    % mining (B) — for Phase L3 mining/non-mining split

% Verify key columns
assert(contains(h{idx_k_chain}, 'ALL INDUSTRIES') && contains(h{idx_k_chain}, 'Chain volume'), ...
    'Col 113 header is "%s" — expected ALL INDUSTRIES chain volume', h{idx_k_chain});
assert(contains(h{idx_k_cp}, 'ALL INDUSTRIES') && contains(h{idx_k_cp}, 'Current prices'), ...
    'Col 226 header is "%s" — expected ALL INDUSTRIES current prices', h{idx_k_cp});
assert(contains(h{idx_k_dwell}, 'Dwellings'), ...
    'Col 103 header is "%s" — expected Dwellings', h{idx_k_dwell});
assert(contains(h{idx_k_mining}, 'Mining'), ...
    'Col 12 header is "%s" — expected Mining', h{idx_k_mining});

k_total_annual    = v(:, idx_k_chain);
k_total_cp_annual = v(:, idx_k_cp);
k_dwell_annual    = v(:, idx_k_dwell);
k_pubadm_annual   = v(:, idx_k_pubadm);
k_edu_annual      = v(:, idx_k_edu);
k_health_annual   = v(:, idx_k_health);
k_mining_annual   = v(:, idx_k_mining);
k_total_dates     = d;

% Market-sector capital = total − dwellings − non-market industries
% Matches the Q_market definition: total GVA − pub admin − education − health − dwellings
k_market_annual = k_total_annual - k_dwell_annual - k_pubadm_annual - k_edu_annual - k_health_annual;
k_nonmining_market_annual = k_market_annual - k_mining_annual;

fprintf('  K_total chain vol:       %d valid obs (col %d)\n', sum(~isnan(k_total_annual)), idx_k_chain);
fprintf('  K_dwellings:             %d valid obs (col %d)\n', sum(~isnan(k_dwell_annual)), idx_k_dwell);
fprintf('  K_pubadm:                %d valid obs\n', sum(~isnan(k_pubadm_annual)));
fprintf('  K_edu:                   %d valid obs\n', sum(~isnan(k_edu_annual)));
fprintf('  K_health:                %d valid obs\n', sum(~isnan(k_health_annual)));
fprintf('  K_mining:                %d valid obs (col %d)\n', sum(~isnan(k_mining_annual)), idx_k_mining);
fprintf('  K_market (derived):      %d valid obs\n', sum(~isnan(k_market_annual)));
fprintf('  K current prices annual: %d valid obs (col %d)\n', sum(~isnan(k_total_cp_annual)), idx_k_cp);
% Diagnostic: compare 2019 values
idx_2019 = find(year(d) == 2019, 1);
if ~isempty(idx_2019)
    fprintf('  2019 K_total=$%.0fM, K_market=$%.0fM (%.1f%% of total), K_mining=$%.0fM (%.1f%% of market)\n', ...
        k_total_annual(idx_2019), k_market_annual(idx_2019), ...
        100*k_market_annual(idx_2019)/k_total_annual(idx_2019), ...
        k_mining_annual(idx_2019), ...
        100*k_mining_annual(idx_2019)/k_market_annual(idx_2019));
end

%% 7. ABS 5204 Tab 47: Depreciation annual
% Col 23 = "ALL INDUSTRIES" (total consumption of fixed capital, current prices)
fprintf('\nReading abs_5204_depreciation.xlsx ... ');
[d, v, h] = read_abs(fullfile(datadir, 'abs_5204_depreciation.xlsx'));
fprintf('%d obs, %d series\n', length(d), size(v, 2));
% Search for ALL INDUSTRIES total
idx_dep = [];
for i = 1:length(h)
    s = strtrim(h{i});
    if startsWith(s, 'ALL INDUSTRIES') || strcmpi(s, 'ALL INDUSTRIES ;')
        idx_dep = i; break;
    end
end
if isempty(idx_dep)
    idx_dep = find(contains(lower(h), 'total') & ~contains(lower(h), 'transfer'), 1);
end
if isempty(idx_dep), idx_dep = 1; end
dep_annual = v(:, idx_dep);
dep_dates = d;
fprintf('  Depreciation annual:     %d valid obs (col %d: %s)\n', sum(~isnan(dep_annual)), idx_dep, h{idx_dep});

%% Read 5204 compensation/productivity for diagnostic only
for fn = {'abs_5204_compensation', 'abs_5204_productivity'}
    [d, v, h] = read_abs(fullfile(datadir, [fn{1} '.xlsx']));
    fprintf('Read %-30s: %d obs, %d series\n', fn{1}, length(d), size(v, 2));
end

%% Interpolate annual K and depreciation to quarterly
fprintf('\nInterpolating K and depreciation to quarterly...\n');

% Helper: interpolate an annual series aligned at Q2 to quarterly
interp_annual_to_q = @(k_ann) interp_annual_q2(k_ann, k_total_dates, dates_q, nQ);

k_total_q    = interp_annual_to_q(k_total_annual);
k_market_q   = interp_annual_to_q(k_market_annual);
k_mining_q   = interp_annual_to_q(k_mining_annual);
k_nonmin_q   = interp_annual_to_q(k_nonmining_market_annual);

fprintf('  K_total quarterly:       %d valid obs\n', sum(~isnan(k_total_q)));
fprintf('  K_market quarterly:      %d valid obs\n', sum(~isnan(k_market_q)));
fprintf('  K_mining quarterly:      %d valid obs\n', sum(~isnan(k_mining_q)));
fprintf('  K_nonmining quarterly:   %d valid obs\n', sum(~isnan(k_nonmin_q)));

% Diagnostic: gamma at 2019
idx_2019q = find(year(dates_q) == 2019 & quarter(dates_q) == 1, 1);
if ~isempty(idx_2019q) && ~isnan(k_market_q(idx_2019q))
    gamma_old = exp(log(q_market_vol(idx_2019q)) - log(k_total_q(idx_2019q)));
    gamma_new = exp(log(q_market_vol(idx_2019q)) - log(k_market_q(idx_2019q)));
    fprintf('  gamma_old (Q_mkt/K_total) at 2019Q1: %.4f\n', gamma_old);
    fprintf('  gamma_new (Q_mkt/K_market) at 2019Q1: %.4f\n', gamma_new);
    fprintf('  FR-BDF 2026 gamma = 0.2561\n');
end

dep_q = nan(nQ, 1);
for i = 1:length(dep_dates)
    if isnat(dep_dates(i)), continue; end
    yr = year(dep_dates(i));
    idx = find(year(dates_q) == yr & quarter(dates_q) == 2, 1);
    if ~isempty(idx) && ~isnan(dep_annual(i)), dep_q(idx) = dep_annual(i); end
end
nan_idx = isnan(dep_q);
v_idx = find(~nan_idx);
if length(v_idx) >= 2
    dep_q(nan_idx) = interp1(v_idx, dep_q(v_idx), find(nan_idx), 'linear', 'extrap');
end

% Use K current-prices ÷ depreciation current-prices — both in $millions
% so units cancel and δ comes out as a fraction.
k_total_cp_q = nan(nQ, 1);
for i = 1:length(k_total_dates)
    if isnat(k_total_dates(i)), continue; end
    yr = year(k_total_dates(i));
    idx = find(year(dates_q) == yr & quarter(dates_q) == 2, 1);
    if ~isempty(idx) && ~isnan(k_total_cp_annual(i)), k_total_cp_q(idx) = k_total_cp_annual(i); end
end
nan_idx = isnan(k_total_cp_q);
v_idx = find(~nan_idx);
if length(v_idx) >= 2
    k_total_cp_q(nan_idx) = interp1(v_idx, k_total_cp_q(v_idx), find(nan_idx), 'linear', 'extrap');
end
delta_annual = dep_q ./ k_total_cp_q;
delta_q = delta_annual / 4;
fprintf('  Implied annual delta:    mean=%.4f, median=%.4f\n', mean(delta_annual, 'omitnan'), median(delta_annual, 'omitnan'));

% (p_q_total / p_q_market computed earlier from 5206 IPD — see above)

%% Trends
psi_bar = ones(nQ, 1);   % market employment share — placeholder
pop_bar = exp(hp_trend(log(lf_raw), 1600));

%% Total labour cost per worker (gross + ~10.5% super uplift)
super_uplift = 1.105;
w_total = awe * super_uplift;

%% Save
out = struct();
out.dates = dates_q;
out.nQ = nQ;
out.q_total_lvl = log(q_total_vol);
out.q_market_lvl = log(q_market_vol);
out.p_q_total_lvl = log(p_q_total);
out.p_q_market_lvl = log(p_q_market);
out.k_total_lvl = log(k_total_q);       % ALL-INDUSTRIES total (includes dwellings + govt) — kept for depreciation calc
out.k_market_lvl = log(k_market_q);     % market-sector K (matched to Q_market) — USE THIS for CES γ
out.k_mining_lvl = log(k_mining_q);     % mining (B) — for Phase L3 mining/non-mining split
out.k_nonmining_market_lvl = log(k_nonmin_q);  % non-mining market-sector K
out.delta_q = delta_q;
out.n_total_lvl = log(n_total_raw);
out.h_lvl = log(h_per_worker);
out.labour_force_lvl = log(lf_raw);
out.urate = urate;
out.wpi_lvl = log(wpi);
out.awe_lvl = log(awe);
out.w_total_lvl = log(w_total);
out.psi_bar = psi_bar;
out.pop_bar = pop_bar;

fprintf('\n--- Final supply-data summary ---\n');
fprintf('%-22s %8s %12s %12s %12s\n', 'field', 'valid', 'first', 'mean', 'std');
fields = fieldnames(out);
for k = 1:length(fields)
    f = fields{k};
    val = out.(f);
    if isnumeric(val) && length(val) == nQ
        valid = sum(~isnan(val));
        if valid == 0, continue; end
        fv = find(~isnan(val), 1, 'first');
        fprintf('%-22s %8d %12s %12.3f %12.3f\n', f, valid, ...
            datestr(dates_q(fv), 'yyyy-mmm'), ...
            mean(val(~isnan(val))), std(val(~isnan(val))));
    end
end

savefile = fullfile(projectdir, 'dynare', 'supply_data.mat');
save(savefile, '-struct', 'out');
fprintf('\nSaved to %s\n', savefile);
fprintf('=== Done ===\n');

%% ---------- helper functions ----------
function [dates, vals, headers] = read_abs(fname, sheet)
    if nargin < 2, sheet = 'Data1'; end
    [num, txt, raw] = xlsread(fname, sheet);
    headers = txt(1, 2:end);   % col B onward (col A is dates header)

    % ABS stores dates as Excel serial numbers in col A. xlsread returns
    % `num` with col 1 = date serial, col 2+ = data values aligned with
    % `headers`. Strip col 1 from num so vals(:, idx) matches headers{idx}.
    if size(num, 2) >= length(headers) + 1
        date_serials = num(:, 1);
        vals = num(:, 2:end);
    else
        % Fallback: if num doesn't have a date col (text dates),
        % vals == num and dates parsed from raw text.
        date_serials = nan(size(num, 1), 1);
        vals = num;
    end

    % Take only data rows (10 metadata rows above)
    data_start = 10;  % first data row is row 11 in spreadsheet, index 10 in 0-based
    if size(vals, 1) > data_start
        vals = vals(data_start+1:end, :);
        date_serials = date_serials(data_start+1:end);
    end

    % Build datetime vector
    nR = size(vals, 1);
    dates = NaT(nR, 1);
    raw_col1 = raw(data_start+1:min(data_start+nR, size(raw, 1)), 1);
    for i = 1:length(raw_col1)
        d = raw_col1{i};
        if isnumeric(d) && ~isnan(d)
            dates(i) = datetime(d, 'ConvertFrom', 'excel');
        elseif ischar(d) || isstring(d)
            try, dates(i) = datetime(d); catch, end
        end
    end
    % If dates from raw failed but serials available, use those
    nat_mask = isnat(dates);
    use_serials = nat_mask & ~isnan(date_serials(1:length(dates)));
    if any(use_serials)
        dates(use_serials) = datetime(date_serials(use_serials), 'ConvertFrom', 'excel');
    end

    % Trim trailing rows where date didn't parse
    last_valid = find(~isnat(dates), 1, 'last');
    if ~isempty(last_valid) && last_valid < length(dates)
        dates = dates(1:last_valid);
        vals = vals(1:last_valid, :);
    elseif isempty(last_valid)
        dates = NaT(0, 1);
        vals = zeros(0, size(vals, 2));
    end
end

function idx_sa = pick_sa_col(fname, candidate_cols)
%% Pick the Seasonally Adjusted variant from a set of candidate columns.
%  Reads the Series Type metadata row (row 3 in ABS layout) directly and
%  filters candidate_cols to the one(s) marked "Seasonally Adjusted".
%  If none, falls back to "Trend"; if none, returns the first candidate.
    [~, ~, raw] = xlsread(fname, 'Data1');
    sa_hits = [];
    trend_hits = [];
    for k = 1:length(candidate_cols)
        c = candidate_cols(k);
        st = '';
        if c + 1 <= size(raw, 2)
            st = char(string(raw{3, c + 1}));
        end
        if contains(lower(st), 'seasonally adjusted')
            sa_hits(end+1) = c; %#ok<AGROW>
        elseif contains(lower(st), 'trend')
            trend_hits(end+1) = c; %#ok<AGROW>
        end
    end
    if ~isempty(sa_hits)
        idx_sa = sa_hits(1);
    elseif ~isempty(trend_hits)
        warning('pick_sa_col(%s): no SA candidate found; falling back to Trend col %d', ...
                fname, trend_hits(1));
        idx_sa = trend_hits(1);
    else
        idx_sa = candidate_cols(1);
    end
end

function v_q = align_to_q(d_in, v_in, dates_q)
    v_q = nan(length(dates_q), 1);
    for i = 1:length(dates_q)
        yr = year(dates_q(i));
        qq = quarter(dates_q(i));
        idx = year(d_in) == yr & quarter(d_in) == qq;
        if any(idx), v_q(i) = mean(v_in(idx), 'omitnan'); continue; end
        if qq == 4 && any(year(d_in) == yr)
            v_q(i) = mean(v_in(year(d_in) == yr), 'omitnan');
        end
    end
end

function k_q = interp_annual_q2(k_annual, k_dates, dates_q, nQ)
    % Interpolate an annual series (aligned at fiscal-year Q2) to quarterly.
    k_q = nan(nQ, 1);
    for i = 1:length(k_dates)
        if isnat(k_dates(i)), continue; end
        yr = year(k_dates(i));
        idx = find(year(dates_q) == yr & quarter(dates_q) == 2, 1);
        if ~isempty(idx) && ~isnan(k_annual(i)), k_q(idx) = k_annual(i); end
    end
    nan_idx = isnan(k_q);
    v_idx = find(~nan_idx);
    if length(v_idx) >= 2
        k_q(nan_idx) = interp1(v_idx, k_q(v_idx), find(nan_idx), 'linear', 'extrap');
    end
end

function trend = hp_trend(y, lambda)
    y = y(:);
    n = length(y);
    nanmask = isnan(y);
    if any(nanmask)
        idx = find(~nanmask);
        if length(idx) < 4, trend = y; return; end
        y_filled = interp1(idx, y(idx), 1:n, 'linear', 'extrap')';
    else
        y_filled = y;
    end
    e = ones(n, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n-2, n);
    A = speye(n) + lambda * (D2' * D2);
    trend = A \ y_filled;
    trend(nanmask) = NaN;
end
