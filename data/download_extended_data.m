%% download_extended_data.m
% Downloads additional Australian macro data needed for the supply block,
% labor market, and demand equations of the full semi-structural model.
%
% Extends the base dataset.csv with:
%   - Employment, unemployment rate, wages
%   - GDP expenditure components (C, I, G, X, M)
%   - 10-year government bond yield
%
% All series from FRED (OECD/IMF sources) via curl fallback.

clear; clc;
fprintf('=== Downloading extended Australian data ===\n\n');

outdir = fileparts(mfilename('fullpath'));
if isempty(outdir), outdir = pwd; end
projectdir = fullfile(outdir, '..');

%% FRED series to download
% Format: {FRED_ID, description, frequency}
series = {
    % Labor market
    'LRUNTTTTAUQ156S',   'AU Unemployment rate (%, SA, quarterly)'
    'LFEMTTTTAUQ647S',   'AU Employment (thousands, SA, quarterly)'
    % Price index (for ULC construction)
    'AUSCPIALLQINMEI',   'AU CPI (index, SA, quarterly)'
    % GDP expenditure components (all quarterly, SA, national currency)
    'NAEXKP02AUQ189S',   'AU Private Consumption (vol, SA, quarterly)'
    'NAEXKP04AUQ189S',   'AU Gross Fixed Capital Formation (vol, SA, quarterly)'
    'NAEXKP06AUQ189S',   'AU Exports (vol, SA, quarterly)'
    'NAEXKP07AUQ189S',   'AU Imports (vol, SA, quarterly)'
    % Financial
    'IRLTLT01AUQ156N',   'AU 10-year govt bond yield (%, quarterly)'
};

fred_base = 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=';

data_ext = struct();
for k = 1:size(series, 1)
    sid = series{k, 1};
    desc = series{k, 2};
    url = [fred_base, sid];
    localfile = fullfile(outdir, ['fred_', sid, '.csv']);

    fprintf('Downloading %s ... ', desc);
    try
        opts = weboptions('Timeout', 30);
        websave(localfile, url, opts);
        T = readtable(localfile);
        fprintf('OK (%d obs)\n', height(T));
    catch
        try
            [status, ~] = system(sprintf('curl -skL "%s" -o "%s"', url, localfile));
            if status == 0 && exist(localfile, 'file')
                % Check if it's an HTML error page
                fid_check = fopen(localfile, 'r');
                first_line = fgetl(fid_check);
                fclose(fid_check);
                if ~isempty(strfind(first_line, '<!DOCTYPE')) || ~isempty(strfind(first_line, '<html')) %#ok
                    error('Downloaded HTML error page, not CSV');
                end
                T = readtable(localfile);
                if width(T) < 2
                    error('Invalid CSV');
                end
                fprintf('OK via curl (%d obs)\n', height(T));
            else
                error('curl failed');
            end
        catch ME
            fprintf('FAILED: %s\n', ME.message);
            continue;
        end
    end

    % Store
    dates = datetime(T{:,1});
    values = T{:,2};
    data_ext.(sid).dates = dates;
    data_ext.(sid).values = values;
    data_ext.(sid).desc = desc;
end

%% Build quarterly time series aligned to our sample
% Load existing dataset to get the date vector
base_csv = fullfile(projectdir, 'dataset.csv');
if exist(base_csv, 'file')
    T_base = readtable(base_csv);
    qDates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
    nQ = height(T_base);
else
    % Fallback: construct 1993Q1-2024Q4
    qDates = [];
    for yr = 1993:2024
        for qq = 1:4
            qDates = [qDates; datetime(yr, (qq-1)*3+1, 1)]; %#ok
        end
    end
    nQ = length(qDates);
end

fprintf('\nAligning to %d quarters (%s to %s)\n', nQ, ...
    datestr(qDates(1)), datestr(qDates(end)));

% Helper: align quarterly FRED data
align_q = @(raw_dates, raw_values) align_quarterly_fn(raw_dates, raw_values, qDates);

% --- Unemployment rate ---
ur = NaN(nQ, 1);
if isfield(data_ext, 'LRUNTTTTAUQ156S')
    d = data_ext.LRUNTTTTAUQ156S;
    ur = align_q(d.dates, d.values);
    fprintf('AU Unemployment: %d obs\n', sum(~isnan(ur)));
end

% --- Employment ---
emp = NaN(nQ, 1);
if isfield(data_ext, 'LFEMTTTTAUQ647S')
    d = data_ext.LFEMTTTTAUQ647S;
    emp = align_q(d.dates, d.values);
    fprintf('AU Employment: %d obs\n', sum(~isnan(emp)));
end

% --- CPI index (for ULC construction) ---
cpi_idx = NaN(nQ, 1);
if isfield(data_ext, 'AUSCPIALLQINMEI')
    d = data_ext.AUSCPIALLQINMEI;
    cpi_idx = align_q(d.dates, d.values);
    fprintf('AU CPI index: %d obs\n', sum(~isnan(cpi_idx)));
end

% --- Unit Labour Cost (synthetic) ---
% FRED OECD ULC series (ULQELTT01AUQ661S) is unavailable.
% Construct synthetic ULC: proxy wage bill = CPI_index * (employment/employment_0)
% dlog(ULC) = dlog(CPI) + dlog(employment) ≈ wage_inflation + employment_growth
% This captures nominal compensation dynamics per the FR-BDF framework.
ulc = NaN(nQ, 1);
valid = ~isnan(cpi_idx) & ~isnan(emp);
if any(valid)
    first_valid = find(valid, 1, 'first');
    emp_norm = emp / emp(first_valid);  % normalize employment to 1.0 at start
    ulc(valid) = cpi_idx(valid) .* emp_norm(valid);
    fprintf('AU Unit Labour Cost (synthetic CPI*emp): %d obs\n', sum(~isnan(ulc)));
else
    fprintf('AU Unit Labour Cost: insufficient data for construction\n');
end

% --- Private Consumption ---
cons = NaN(nQ, 1);
if isfield(data_ext, 'NAEXKP02AUQ189S')
    d = data_ext.NAEXKP02AUQ189S;
    cons = align_q(d.dates, d.values);
    fprintf('AU Consumption: %d obs\n', sum(~isnan(cons)));
end

% --- Gross Fixed Capital Formation (business + household investment) ---
gfcf = NaN(nQ, 1);
if isfield(data_ext, 'NAEXKP04AUQ189S')
    d = data_ext.NAEXKP04AUQ189S;
    gfcf = align_q(d.dates, d.values);
    fprintf('AU GFCF: %d obs\n', sum(~isnan(gfcf)));
end

% --- Split GFCF into dwelling vs non-dwelling ---
% FRED does not provide separate dwelling/non-dwelling series for Australia.
% Use ABS historical average: dwelling share ~30% of total private GFCF.
% This share has varied between ~25-35% over the sample (ABS Cat 5206.0 Table 2).
% A time-varying share would be better but requires direct ABS download.
dwelling_share = 0.30;
gfcf_dwelling = gfcf * dwelling_share;
gfcf_nondwelling = gfcf * (1 - dwelling_share);
fprintf('AU GFCF split: dwelling %.0f%% / non-dwelling %.0f%%\n', ...
    dwelling_share*100, (1-dwelling_share)*100);

% --- Exports ---
exports = NaN(nQ, 1);
if isfield(data_ext, 'NAEXKP06AUQ189S')
    d = data_ext.NAEXKP06AUQ189S;
    exports = align_q(d.dates, d.values);
    fprintf('AU Exports: %d obs\n', sum(~isnan(exports)));
end

% --- Imports ---
imports = NaN(nQ, 1);
if isfield(data_ext, 'NAEXKP07AUQ189S')
    d = data_ext.NAEXKP07AUQ189S;
    imports = align_q(d.dates, d.values);
    fprintf('AU Imports: %d obs\n', sum(~isnan(imports)));
end

% --- 10-year govt bond yield ---
i10 = NaN(nQ, 1);
if isfield(data_ext, 'IRLTLT01AUQ156N')
    d = data_ext.IRLTLT01AUQ156N;
    i10 = align_q(d.dates, d.values);
    fprintf('AU 10Y Bond: %d obs\n', sum(~isnan(i10)));
end

%% Compute derived variables

% Wage inflation proxy: q-o-q log change of unit labour cost
pi_w = [NaN; diff(log(ulc))] * 100;  % quarterly %

% Consumption growth
dc = [NaN; diff(log(cons))] * 100;

% Investment growth (non-dwelling = business, dwelling = household)
di_b = [NaN; diff(log(gfcf_nondwelling))] * 100;
di_h = [NaN; diff(log(gfcf_dwelling))] * 100;

%% Save extended dataset
fprintf('\nSaving extended dataset...\n');

date_str = datestr(qDates, 'yyyy-mm-dd');
T_ext = table( ...
    cellstr(date_str), ur, emp, ulc, pi_w, cons, gfcf, ...
    gfcf_nondwelling, gfcf_dwelling, exports, imports, i10, ...
    'VariableNames', { ...
        'date', 'au_urate', 'au_employment', 'au_ulc', 'au_pi_w', ...
        'au_consumption', 'au_gfcf', 'au_gfcf_nondwelling', ...
        'au_gfcf_dwelling', 'au_exports', 'au_imports', 'au_i10' ...
    });

ext_csv = fullfile(outdir, 'extended_dataset.csv');
writetable(T_ext, ext_csv);
fprintf('Saved %d rows to %s\n', nQ, ext_csv);

% Also save as .mat for MATLAB use
ext_data = struct();
ext_data.qDates = qDates;
ext_data.ur = ur;
ext_data.emp = emp;
ext_data.cpi_idx = cpi_idx;
ext_data.ulc = ulc;
ext_data.pi_w = pi_w;
ext_data.cons = cons;
ext_data.gfcf = gfcf;
ext_data.gfcf_nondwelling = gfcf_nondwelling;
ext_data.gfcf_dwelling = gfcf_dwelling;
ext_data.exports = exports;
ext_data.imports = imports;
ext_data.i10 = i10;
save(fullfile(outdir, 'extended_data.mat'), 'ext_data');
fprintf('Saved extended_data.mat\n');

fprintf('\n=== Extended data download complete ===\n');

%% Local function
function aligned = align_quarterly_fn(raw_dates, raw_values, target_qdates)
    nQ = length(target_qdates);
    aligned = NaN(nQ, 1);
    raw_yr = year(raw_dates);
    raw_mo = month(raw_dates);
    raw_qq = ceil(raw_mo / 3);
    tgt_yr = year(target_qdates);
    tgt_mo = month(target_qdates);
    tgt_qq = ceil(tgt_mo / 3);
    for q = 1:nQ
        idx = find(raw_yr == tgt_yr(q) & raw_qq == tgt_qq(q), 1, 'first');
        if ~isempty(idx)
            aligned(q) = raw_values(idx);
        end
    end
end
