%% download_data.m
% Downloads and processes Australian and US macroeconomic data for the
% E-SAT structural VAR model (adapted from Banque de France WP #736).
%
% Data sources (all free, no registration):
%   - FRED: US Real GDP (GDPC1), US GDP Deflator (GDPDEF), US Potential GDP (GDPPOT)
%           Australian Real GDP from IMF via FRED (NGDPRSAXDCAUQ)
%           Australian CPI from OECD via FRED (AUSCPIALLQINMEI)
%           Australian 3-month interbank rate via FRED (IR3TIB01AUM156N)
%   - RBA:  Cash rate (Table F1.1), Inflation expectations (Table G3)
%
% Output: saves data.mat and dataset.csv
%
% Set USE_LOCAL_CSV = true to load from dataset.csv instead of downloading.
% This is useful for offline work or reproducibility.

% Preserve USE_LOCAL_CSV flag across clear
if ~exist('USE_LOCAL_CSV', 'var')
    USE_LOCAL_CSV = false;
end
clearvars -except USE_LOCAL_CSV;
clc;

fprintf('=== E-SAT Australia: Data Download ===\n\n');
fprintf('USE_LOCAL_CSV = %d\n\n', USE_LOCAL_CSV);

outdir = fileparts(mfilename('fullpath'));
if isempty(outdir), outdir = pwd; end

csvfile = fullfile(outdir, 'dataset.csv');

if USE_LOCAL_CSV
    %% ===================================================================
    %  LOAD FROM LOCAL CSV
    %  ===================================================================
    fprintf('Loading data from %s ...\n', csvfile);
    if ~exist(csvfile, 'file')
        error('dataset.csv not found in %s. Set USE_LOCAL_CSV = false to download.', outdir);
    end

    T_csv = readtable(csvfile);
    nQ = height(T_csv);

    % Parse dates
    qDates = datetime(T_csv.date, 'InputFormat', 'yyyy-MM-dd');

    % Reconstruct data struct
    data = struct();
    data.qDates = qDates;
    data.nQ     = nQ;
    data.au_ygap      = T_csv.au_ygap;
    data.au_pi        = T_csv.au_pi;
    data.au_irate     = T_csv.au_irate;
    data.us_ygap      = T_csv.us_ygap;
    data.us_pi        = T_csv.us_pi;
    data.au_irate_bar = T_csv.au_irate_bar;
    data.au_pi_bar    = T_csv.au_pi_bar;
    data.us_pi_bar    = T_csv.us_pi_bar;

    % Steady-state values from CSV metadata columns
    data.i_bar     = T_csv.i_bar(1);
    data.pi_bar_au = T_csv.pi_bar_au(1);
    data.pi_bar_us = T_csv.pi_bar_us(1);
    data.i_bar_annual     = T_csv.i_bar(1) * 4;
    data.pi_bar_au_annual = T_csv.pi_bar_au(1) * 4;
    data.pi_bar_us_annual = T_csv.pi_bar_us(1) * 4;

    save(fullfile(outdir, 'data.mat'), 'data');
    fprintf('Loaded %d quarters from CSV. Saved to data.mat.\n', nQ);
    fprintf('=== Data load from CSV complete ===\n');
    return;
end

%% =======================================================================
%  DOWNLOAD FROM WEB
%  =======================================================================

%% -----------------------------------------------------------------------
%  1. Download from FRED (direct CSV)
%  -----------------------------------------------------------------------
fred_base = 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=';

series_fred = {
    'GDPC1',              'US Real GDP (Bil. 2017$)'
    'GDPDEF',             'US GDP Deflator (Index 2017=100)'
    'GDPPOT',             'US Potential GDP (Bil. 2017$)'
    'NGDPRSAXDCAUQ',      'AU Real GDP (IMF, level)'
    'AUSCPIALLQINMEI',    'AU CPI (OECD, quarterly index)'
    'IR3TIB01AUM156N',    'AU 3-month interbank rate (monthly)'
};

fred_data = struct();
for k = 1:size(series_fred,1)
    sid = series_fred{k,1};
    desc = series_fred{k,2};
    url = [fred_base, sid];
    localfile = fullfile(outdir, ['fred_', sid, '.csv']);

    fprintf('Downloading %s ... ', desc);
    try
        % Try websave first (works if MATLAB has valid SSL certs)
        opts = weboptions('Timeout', 30);
        websave(localfile, url, opts);
        T = readtable(localfile);
        fprintf('OK (%d obs)\n', height(T));
    catch
        % Fallback: use system curl (bypasses MATLAB SSL issues)
        try
            [status, ~] = system(sprintf('curl -skL "%s" -o "%s"', url, localfile));
            if status == 0 && exist(localfile, 'file')
                T = readtable(localfile);
                fprintf('OK via curl (%d obs)\n', height(T));
            else
                error('curl download failed');
            end
        catch ME
            fprintf('FAILED: %s\n', ME.message);
            fprintf('  Download manually from:\n  %s\n  Save to: %s\n', url, localfile);
            continue;
        end
    end

    % FRED CSVs have columns DATE and the series id
    dates = datetime(T{:,1});
    values = T{:,2};

    % Store
    fred_data.(sid).dates = dates;
    fred_data.(sid).values = values;
    fred_data.(sid).desc = desc;
end

%% -----------------------------------------------------------------------
%  2. Download from RBA (CSV tables)
%  -----------------------------------------------------------------------
fprintf('\nDownloading RBA data...\n');

% --- Cash rate (Table F1.1 - monthly) ---
rba_f1_url = 'https://www.rba.gov.au/statistics/tables/csv/f1.1-data.csv';
rba_f1_file = fullfile(outdir, 'rba_f1.1.csv');
fprintf('  Cash rate (F1.1) ... ');
try
    opts = weboptions('Timeout', 30);
    websave(rba_f1_file, rba_f1_url, opts);
    fprintf('OK\n');
    rba_f1_downloaded = true;
catch
    try
        [status, ~] = system(sprintf('curl -skL "%s" -o "%s"', rba_f1_url, rba_f1_file));
        if status == 0 && exist(rba_f1_file, 'file')
            fprintf('OK via curl\n');
            rba_f1_downloaded = true;
        else
            error('curl failed');
        end
    catch ME
        fprintf('FAILED: %s\n', ME.message);
        rba_f1_downloaded = false;
    end
end

% --- Inflation expectations (Table G3) ---
rba_g3_url = 'https://www.rba.gov.au/statistics/tables/csv/g3-data.csv';
rba_g3_file = fullfile(outdir, 'rba_g3.csv');
fprintf('  Inflation expectations (G3) ... ');
try
    opts = weboptions('Timeout', 30);
    websave(rba_g3_file, rba_g3_url, opts);
    fprintf('OK\n');
    rba_g3_downloaded = true;
catch
    try
        [status, ~] = system(sprintf('curl -skL "%s" -o "%s"', rba_g3_url, rba_g3_file));
        if status == 0 && exist(rba_g3_file, 'file')
            fprintf('OK via curl\n');
            rba_g3_downloaded = true;
        else
            error('curl failed');
        end
    catch ME
        fprintf('FAILED: %s\n', ME.message);
        rba_g3_downloaded = false;
    end
end

%% -----------------------------------------------------------------------
%  3. Parse RBA CSVs (they have a non-standard header format)
%  -----------------------------------------------------------------------
% RBA CSVs typically have metadata rows before the actual data.
% We need to detect where the numeric data starts.

if rba_f1_downloaded
    fprintf('\nParsing RBA F1.1 (cash rate)...\n');
    try
        rba_f1_raw = fileread(rba_f1_file);
        lines = strsplit(rba_f1_raw, '\n');

        % Find the header row (contains 'Series ID' or 'Title')
        datastart = 0;
        for r = 1:length(lines)
            if ~isempty(strfind(lines{r}, 'Cash Rate Target'))  %#ok
                % The series descriptions are above; data rows follow
            end
            % Data rows start with a date like "Jan-1990" or "01-Jan-1990"
            tokens = regexp(lines{r}, '^\d{2}-[A-Za-z]{3}-\d{4}', 'match');
            if ~isempty(tokens)
                datastart = r;
                break;
            end
        end

        if datastart == 0
            % Try alternate date format
            for r = 1:length(lines)
                tokens = regexp(lines{r}, '^\d{4}-\d{2}', 'match');
                if ~isempty(tokens)
                    datastart = r;
                    break;
                end
            end
        end

        if datastart > 0
            % Read from datastart onwards
            % Use readtable with header detection
            opts = detectImportOptions(rba_f1_file);
            T_f1 = readtable(rba_f1_file, opts);
            % First column should be dates, look for cash rate column
            fprintf('  Parsed %d rows, %d columns\n', height(T_f1), width(T_f1));
        end
    catch ME
        fprintf('  Parse error: %s\n', ME.message);
    end
end

%% -----------------------------------------------------------------------
%  4. Construct quarterly time series
%  -----------------------------------------------------------------------
fprintf('\n=== Constructing quarterly series ===\n');

% Target sample
startYear = 1993; startQ = 1;
endYear   = 2024; endQ   = 4;

% Build quarterly date vector
qDates = [];
for yr = startYear:endYear
    for qq = 1:4
        if yr == startYear && qq < startQ, continue; end
        if yr == endYear && qq > endQ, continue; end
        % Quarterly date = first day of quarter
        qDates = [qDates; datetime(yr, (qq-1)*3+1, 1)]; %#ok
    end
end
nQ = length(qDates);
fprintf('Sample: %s to %s (%d quarters)\n', ...
    datestr(qDates(1)), datestr(qDates(end)), nQ);

% --- Australian Real GDP ---
if isfield(fred_data, 'NGDPRSAXDCAUQ')
    au_gdp_raw = fred_data.NGDPRSAXDCAUQ;
    [au_rgdp, au_gdp_dates] = align_quarterly(au_gdp_raw.dates, au_gdp_raw.values, qDates);
    fprintf('AU Real GDP: %d obs aligned\n', sum(~isnan(au_rgdp)));
else
    au_rgdp = NaN(nQ,1);
    fprintf('AU Real GDP: NOT AVAILABLE\n');
end

% --- Australian CPI (proxy for GDP deflator) ---
if isfield(fred_data, 'AUSCPIALLQINMEI')
    au_def_raw = fred_data.AUSCPIALLQINMEI;
    [au_deflator, ~] = align_quarterly(au_def_raw.dates, au_def_raw.values, qDates);
    fprintf('AU CPI (deflator proxy): %d obs aligned\n', sum(~isnan(au_deflator)));
else
    au_deflator = NaN(nQ,1);
    fprintf('AU CPI: NOT AVAILABLE\n');
end

% --- Australian 3-month interbank rate (proxy for cash rate) ---
if isfield(fred_data, 'IR3TIB01AUM156N')
    au_ir_raw = fred_data.IR3TIB01AUM156N;
    % This is monthly -- average to quarterly
    [au_ir_monthly, ~] = align_monthly_to_quarterly(au_ir_raw.dates, au_ir_raw.values, qDates);
    au_irate = au_ir_monthly;           % annualized percent
    au_irate_annual = au_irate;
    au_irate_quarterly = au_irate / 4;  % quarterly rate
    fprintf('AU Interest rate (3m interbank): %d obs aligned\n', sum(~isnan(au_irate)));
else
    fprintf('AU Interest rate: NOT AVAILABLE from FRED\n');
end

% --- US Real GDP ---
if isfield(fred_data, 'GDPC1')
    us_gdp_raw = fred_data.GDPC1;
    [us_rgdp, ~] = align_quarterly(us_gdp_raw.dates, us_gdp_raw.values, qDates);
    fprintf('US Real GDP: %d obs aligned\n', sum(~isnan(us_rgdp)));
else
    us_rgdp = NaN(nQ,1);
end

% --- US Potential GDP ---
if isfield(fred_data, 'GDPPOT')
    us_pot_raw = fred_data.GDPPOT;
    [us_potgdp, ~] = align_quarterly(us_pot_raw.dates, us_pot_raw.values, qDates);
    fprintf('US Potential GDP: %d obs aligned\n', sum(~isnan(us_potgdp)));
else
    us_potgdp = NaN(nQ,1);
end

% --- US GDP Deflator ---
if isfield(fred_data, 'GDPDEF')
    us_def_raw = fred_data.GDPDEF;
    [us_deflator, ~] = align_quarterly(us_def_raw.dates, us_def_raw.values, qDates);
    fprintf('US GDP Deflator: %d obs aligned\n', sum(~isnan(us_deflator)));
else
    us_deflator = NaN(nQ,1);
end

%% -----------------------------------------------------------------------
%  5. Compute derived series
%  -----------------------------------------------------------------------
fprintf('\n=== Computing derived series ===\n');

% Australian output gap: HP filter on log real GDP
au_log_rgdp = log(au_rgdp);
valid_au = ~isnan(au_log_rgdp);
au_trend = NaN(nQ,1);
if sum(valid_au) > 20
    au_trend(valid_au) = hpfilter_1side(au_log_rgdp(valid_au), 1600);
    au_ygap = (au_log_rgdp - au_trend) * 100;  % in percent
    fprintf('AU output gap computed (HP filter, lambda=1600)\n');
else
    au_ygap = NaN(nQ,1);
    fprintf('AU output gap: insufficient data\n');
end

% US output gap: use CBO potential if available, else HP filter
if sum(~isnan(us_potgdp)) > 20
    us_ygap = (log(us_rgdp) - log(us_potgdp)) * 100;
    fprintf('US output gap computed (CBO potential)\n');
else
    us_log_rgdp = log(us_rgdp);
    valid_us = ~isnan(us_log_rgdp);
    us_trend = NaN(nQ,1);
    if sum(valid_us) > 20
        us_trend(valid_us) = hpfilter_1side(us_log_rgdp(valid_us), 1600);
    end
    us_ygap = (us_log_rgdp - us_trend) * 100;
    fprintf('US output gap computed (HP filter)\n');
end

% Australian inflation: quarterly log-change of GDP deflator (quarterly rate)
au_pi = [NaN; diff(log(au_deflator))] * 100;  % quarterly percent
fprintf('AU inflation (GDP deflator, qoq): computed\n');

% US inflation: quarterly log-change of GDP deflator
us_pi = [NaN; diff(log(us_deflator))] * 100;
fprintf('US inflation (GDP deflator, qoq): computed\n');

% Australian interest rate: check if already filled from FRED above
if ~exist('au_irate','var') || all(isnan(au_irate))
    au_irate = NaN(nQ,1);
    au_irate_quarterly = NaN(nQ,1);
    au_irate_annual = NaN(nQ,1);
    fprintf('AU interest rate: to be parsed from RBA data\n');
else
    fprintf('AU interest rate: already loaded from FRED (%d obs)\n', sum(~isnan(au_irate)));
end

% Long-run inflation expectations: placeholder
au_pi_lr = NaN(nQ,1);
fprintf('AU LR inflation expectations: to be parsed from RBA G3\n');

%% -----------------------------------------------------------------------
%  6. Try to parse RBA cash rate from downloaded file (if FRED failed)
%  -----------------------------------------------------------------------
if all(isnan(au_irate)) && rba_f1_downloaded
    fprintf('\nAttempting to parse RBA cash rate from F1.1...\n');
    try
        fid = fopen(rba_f1_file, 'r');
        raw_lines = {};
        while ~feof(fid)
            raw_lines{end+1} = fgetl(fid); %#ok
        end
        fclose(fid);

        cash_dates = [];
        cash_values = [];
        for r = 1:length(raw_lines)
            ln = raw_lines{r};
            tok = regexp(ln, '^(\d{2}-[A-Za-z]{3}-\d{4})', 'tokens');
            if ~isempty(tok)
                parts = strsplit(ln, ',');
                d = datetime(tok{1}{1}, 'InputFormat', 'dd-MMM-yyyy');
                for c = 2:length(parts)
                    val = str2double(strtrim(parts{c}));
                    if ~isnan(val)
                        cash_dates = [cash_dates; d]; %#ok
                        cash_values = [cash_values; val]; %#ok
                        break;
                    end
                end
            end
        end

        if ~isempty(cash_dates)
            fprintf('  Found %d RBA cash rate observations\n', length(cash_dates));
            for q = 1:nQ
                qstart = qDates(q);
                qend = qDates(q) + calmonths(3) - caldays(1);
                mask = cash_dates >= qstart & cash_dates <= qend;
                if any(mask)
                    au_irate(q) = mean(cash_values(mask));
                end
            end
            au_irate_annual = au_irate;
            au_irate_quarterly = au_irate / 4;
            fprintf('  Quarterly cash rate: %d non-NaN obs\n', sum(~isnan(au_irate)));
        end
    catch ME
        fprintf('  RBA parse failed: %s\n', ME.message);
    end
end

%% -----------------------------------------------------------------------
%  7. Construct long-run anchors
%  -----------------------------------------------------------------------
fprintf('\n=== Long-run anchors ===\n');

% Steady-state values (annualized)
pi_bar_au_annual = 2.5;   % midpoint of RBA 2-3% target (annualized)
pi_bar_us_annual = 2.0;   % Fed target (annualized)

% Convert to quarterly
pi_bar_au = pi_bar_au_annual / 4;
pi_bar_us = pi_bar_us_annual / 4;

% Long-run interest rate anchor: historical mean of cash rate
valid_irate_ann = au_irate_annual(~isnan(au_irate_annual));
if ~isempty(valid_irate_ann)
    i_bar_annual = mean(valid_irate_ann);
    i_bar = i_bar_annual / 4;  % quarterly
    fprintf('  i_bar = %.2f%% (annualized, sample mean of cash rate)\n', i_bar_annual);
else
    i_bar_annual = 4.5;  % fallback calibration
    i_bar = i_bar_annual / 4;
    fprintf('  i_bar = %.2f%% (annualized, calibrated fallback)\n', i_bar_annual);
end

fprintf('  pi_bar_AU = %.2f%% (annualized)\n', pi_bar_au_annual);
fprintf('  pi_bar_US = %.2f%% (annualized)\n', pi_bar_us_annual);

% Long-run inflation anchor series: use HP trend of inflation as proxy
% or simply set to constant target
au_pi_bar = pi_bar_au * ones(nQ, 1);  % constant at target (quarterly)
us_pi_bar = pi_bar_us * ones(nQ, 1);

% Long-run interest rate anchor series: HP trend of cash rate
if exist('au_irate_quarterly','var') && sum(~isnan(au_irate_quarterly)) > 20
    valid_ir = ~isnan(au_irate_quarterly);
    ibar_trend = NaN(nQ,1);
    ibar_trend(valid_ir) = hpfilter_1side(au_irate_quarterly(valid_ir), 1600);
    au_irate_bar = ibar_trend;
    fprintf('  LR interest rate anchor: HP trend of quarterly rate\n');
else
    au_irate_bar = i_bar * ones(nQ, 1);
    fprintf('  LR interest rate anchor: constant at %.2f%% (quarterly)\n', i_bar*100);
end

%% -----------------------------------------------------------------------
%  8. Save processed data
%  -----------------------------------------------------------------------
data = struct();
data.qDates = qDates;
data.nQ = nQ;

% Raw quarterly series (quarterly rates for i and pi)
data.au_ygap = au_ygap;            % AU output gap (%)
data.au_pi   = au_pi;              % AU inflation (quarterly %)
data.au_irate = au_irate_quarterly; % AU cash rate (quarterly %)
data.us_ygap = us_ygap;            % US output gap (%)
data.us_pi   = us_pi;              % US inflation (quarterly %)

% Long-run anchors (quarterly rates)
data.au_irate_bar = au_irate_bar;  % LR interest rate anchor (quarterly)
data.au_pi_bar = au_pi_bar;        % LR AU inflation anchor (quarterly)
data.us_pi_bar = us_pi_bar;        % LR US inflation anchor (quarterly)

% Steady-state values (quarterly)
data.i_bar = i_bar;
data.pi_bar_au = pi_bar_au;
data.pi_bar_us = pi_bar_us;

% Annualized versions for reference
data.i_bar_annual = i_bar_annual;
data.pi_bar_au_annual = pi_bar_au_annual;
data.pi_bar_us_annual = pi_bar_us_annual;

savefile = fullfile(outdir, 'data.mat');
save(savefile, 'data');
fprintf('\nData saved to %s\n', savefile);

%% -----------------------------------------------------------------------
%  9. Export to dataset.csv
%  -----------------------------------------------------------------------
fprintf('\nExporting to dataset.csv ...\n');

date_str = datestr(qDates, 'yyyy-mm-dd');
T_export = table( ...
    cellstr(date_str), ...
    data.au_ygap, ...
    data.au_pi, ...
    data.au_irate, ...
    data.us_ygap, ...
    data.us_pi, ...
    data.au_irate_bar, ...
    data.au_pi_bar, ...
    data.us_pi_bar, ...
    repmat(data.i_bar, nQ, 1), ...
    repmat(data.pi_bar_au, nQ, 1), ...
    repmat(data.pi_bar_us, nQ, 1), ...
    'VariableNames', { ...
        'date', ...
        'au_ygap', ...        % AU output gap (%)
        'au_pi', ...          % AU inflation (quarterly %)
        'au_irate', ...       % AU interest rate (quarterly %)
        'us_ygap', ...        % US output gap (%)
        'us_pi', ...          % US inflation (quarterly %)
        'au_irate_bar', ...   % LR AU interest rate anchor (quarterly %)
        'au_pi_bar', ...      % LR AU inflation anchor (quarterly %)
        'us_pi_bar', ...      % LR US inflation anchor (quarterly %)
        'i_bar', ...          % steady-state interest rate (quarterly %)
        'pi_bar_au', ...      % steady-state AU inflation (quarterly %)
        'pi_bar_us' ...       % steady-state US inflation (quarterly %)
    });

writetable(T_export, csvfile);
fprintf('Exported %d rows to %s\n', nQ, csvfile);
fprintf('=== Data download complete ===\n');


%% =======================================================================
%  LOCAL FUNCTIONS
%  =======================================================================

function [aligned, qdates] = align_quarterly(raw_dates, raw_values, target_qdates)
% Align a time series to a target quarterly date vector.
% Matches by year and quarter.
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
    qdates = target_qdates;
end

function [aligned, qdates] = align_monthly_to_quarterly(raw_dates, raw_values, target_qdates)
% Average monthly data to quarterly, aligning to target quarterly dates.
    nQ = length(target_qdates);
    aligned = NaN(nQ, 1);

    tgt_yr = year(target_qdates);
    tgt_mo = month(target_qdates);
    tgt_qq = ceil(tgt_mo / 3);

    raw_yr = year(raw_dates);
    raw_mo = month(raw_dates);
    raw_qq = ceil(raw_mo / 3);

    for q = 1:nQ
        mask = raw_yr == tgt_yr(q) & raw_qq == tgt_qq(q);
        vals = raw_values(mask);
        vals = vals(~isnan(vals));
        if ~isempty(vals)
            aligned(q) = mean(vals);
        end
    end
    qdates = target_qdates;
end

function trend = hpfilter_1side(y, lambda)
% One-sided HP filter (simple two-sided HP for now).
% For proper one-sided, would need Kalman filter implementation.
    n = length(y);
    % Build the second-difference matrix
    e = ones(n,1);
    D = spdiags([e -2*e e], 0:2, n-2, n);
    % HP filter: minimize (y - trend)^2 + lambda * (D*trend)^2
    trend = (speye(n) + lambda * (D' * D)) \ y;
end
