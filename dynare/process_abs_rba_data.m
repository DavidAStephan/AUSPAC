%% process_abs_rba_data.m — Process ABS/RBA data for Phase 4 estimation
% Extracts quarterly time series from downloaded ABS and RBA files:
%   1. Component IPDs (consumption, investment, exports, imports, housing, govt)
%   2. Chain volume exports & imports
%   3. Housing price index (RPPI)
%   4. Mortgage lending rate (housing loans standard variable)
%
% Output: abs_rba_dataset.mat with aligned quarterly series from 1993Q1

clear; clc;
addpath('C:\dynare\6.5\matlab');

datadir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'abs_rba');
fid = fopen(fullfile(datadir, 'processing_log.txt'), 'w');
log_msg = @(msg) fprintf_both(fid, msg);

log_msg('================================================================\n');
log_msg(sprintf('  ABS/RBA Data Processing — %s\n', datestr(now)));
log_msg('================================================================\n\n');

%% 1. ABS 5206 Table 5: Implicit Price Deflators
log_msg('--- ABS 5206 Implicit Price Deflators ---\n');
ipd_file = fullfile(datadir, 'abs_5206_ipd.xlsx');

% ABS time series spreadsheets: Data sheet has header rows then data
% Sheet names vary; try 'Data1' (seasonally adjusted) first
try
    [~, sheets] = xlsfinfo(ipd_file);
    log_msg(sprintf('  Sheets: %s\n', strjoin(sheets, ', ')));

    % Read seasonally adjusted sheet
    sa_sheet = '';
    for s = 1:length(sheets)
        if contains(sheets{s}, 'Data1') || contains(sheets{s}, 'Seasonally')
            sa_sheet = sheets{s};
            break;
        end
    end
    if isempty(sa_sheet), sa_sheet = sheets{2}; end  % usually Data1 is second sheet
    log_msg(sprintf('  Reading sheet: %s\n', sa_sheet));

    [num_ipd, txt_ipd, raw_ipd] = xlsread(ipd_file, sa_sheet);

    % Find series names in header rows
    % ABS format: Row 1 = series names, Row ~10 = data starts
    header_row = raw_ipd(1, :);
    series_ids = raw_ipd(2, :);  % Series IDs

    % Log available series
    log_msg('  Available IPD series:\n');
    for j = 2:min(20, size(header_row, 2))
        if ischar(header_row{j}) && ~isempty(header_row{j})
            log_msg(sprintf('    Col %d: %s\n', j, header_row{j}));
        end
    end

    % Find specific series by looking for keywords
    ipd_names = {'Household final consumption', 'Private; Gross fixed capital formation; Dwellings', ...
                 'Private; Gross fixed capital formation; Non-dwelling', ...
                 'Exports of goods and services', 'Imports of goods and services', ...
                 'General government', 'Gross domestic product'};
    ipd_cols = zeros(1, length(ipd_names));

    for j = 2:size(raw_ipd, 2)
        for n = 1:length(ipd_names)
            if ischar(raw_ipd{1, j}) && contains(raw_ipd{1, j}, ipd_names{n}, 'IgnoreCase', true)
                if ipd_cols(n) == 0  % take first match
                    ipd_cols(n) = j;
                end
            end
        end
    end

    log_msg('  Matched columns:\n');
    short_names = {'ipd_c', 'ipd_ih', 'ipd_ib', 'ipd_x', 'ipd_m', 'ipd_g', 'ipd_gdp'};
    for n = 1:length(ipd_names)
        if ipd_cols(n) > 0
            log_msg(sprintf('    %s -> col %d (%s)\n', short_names{n}, ipd_cols(n), ipd_names{n}));
        else
            log_msg(sprintf('    %s -> NOT FOUND\n', short_names{n}));
        end
    end

    % Extract date column and data
    % ABS dates are in column 1, format varies (serial number or string)
    data_start = 0;
    for r = 1:size(raw_ipd, 1)
        if isnumeric(raw_ipd{r, 1}) && raw_ipd{r, 1} > 10000
            data_start = r;
            break;
        end
    end
    if data_start == 0
        % Try finding 'Series ID' row
        for r = 1:size(raw_ipd, 1)
            if ischar(raw_ipd{r, 1}) && contains(raw_ipd{r, 1}, 'Series ID')
                data_start = r + 1;
                break;
            end
        end
    end
    log_msg(sprintf('  Data starts at row %d\n', data_start));

    % Extract dates
    nrows = size(raw_ipd, 1) - data_start + 1;
    dates_raw = raw_ipd(data_start:end, 1);
    ipd_data = nan(nrows, length(ipd_names));
    for n = 1:length(ipd_names)
        if ipd_cols(n) > 0
            for r = 1:nrows
                val = raw_ipd{data_start + r - 1, ipd_cols(n)};
                if isnumeric(val) && ~isnan(val)
                    ipd_data(r, n) = val;
                end
            end
        end
    end

    % Convert dates (Excel serial numbers -> MATLAB datenum)
    ipd_dates = NaT(nrows, 1);
    for r = 1:nrows
        d = dates_raw{r};
        if isnumeric(d) && d > 10000
            ipd_dates(r) = datetime(d, 'ConvertFrom', 'excel');
        elseif ischar(d)
            try
                ipd_dates(r) = datetime(d);
            catch
            end
        end
    end

    valid_ipd = ~isnat(ipd_dates);
    ipd_dates = ipd_dates(valid_ipd);
    ipd_data = ipd_data(valid_ipd, :);
    log_msg(sprintf('  IPD: %d quarters, %s to %s\n', sum(valid_ipd), ...
        datestr(ipd_dates(1)), datestr(ipd_dates(end))));

catch ME
    log_msg(sprintf('  IPD FAILED: %s\n', ME.message));
    ipd_data = []; ipd_dates = [];
end

%% 2. ABS 5206 Table 2: Chain Volume Measures
log_msg('\n--- ABS 5206 Chain Volume Measures ---\n');
vol_file = fullfile(datadir, 'abs_5206_vol.xlsx');

try
    [~, sheets] = xlsfinfo(vol_file);
    log_msg(sprintf('  Sheets: %s\n', strjoin(sheets, ', ')));

    sa_sheet = '';
    for s = 1:length(sheets)
        if contains(sheets{s}, 'Data1') || contains(sheets{s}, 'Seasonally')
            sa_sheet = sheets{s};
            break;
        end
    end
    if isempty(sa_sheet), sa_sheet = sheets{2}; end
    log_msg(sprintf('  Reading sheet: %s\n', sa_sheet));

    [~, ~, raw_vol] = xlsread(vol_file, sa_sheet);

    % Find exports and imports
    vol_names = {'Exports of goods and services', 'Imports of goods and services', ...
                 'Household final consumption', 'Private; Gross fixed capital formation; Dwellings', ...
                 'Private; Gross fixed capital formation; Non-dwelling'};
    vol_short = {'vol_x', 'vol_m', 'vol_c', 'vol_ih', 'vol_ib'};
    vol_cols = zeros(1, length(vol_names));

    for j = 2:size(raw_vol, 2)
        for n = 1:length(vol_names)
            if ischar(raw_vol{1, j}) && contains(raw_vol{1, j}, vol_names{n}, 'IgnoreCase', true)
                if vol_cols(n) == 0
                    vol_cols(n) = j;
                end
            end
        end
    end

    log_msg('  Matched columns:\n');
    for n = 1:length(vol_names)
        if vol_cols(n) > 0
            log_msg(sprintf('    %s -> col %d\n', vol_short{n}, vol_cols(n)));
        else
            log_msg(sprintf('    %s -> NOT FOUND\n', vol_short{n}));
        end
    end

    % Find data start
    data_start_v = 0;
    for r = 1:size(raw_vol, 1)
        if ischar(raw_vol{r, 1}) && contains(raw_vol{r, 1}, 'Series ID')
            data_start_v = r + 1;
            break;
        elseif isnumeric(raw_vol{r, 1}) && raw_vol{r, 1} > 10000
            data_start_v = r;
            break;
        end
    end

    nrows_v = size(raw_vol, 1) - data_start_v + 1;
    vol_data = nan(nrows_v, length(vol_names));
    vol_dates_raw = raw_vol(data_start_v:end, 1);

    for n = 1:length(vol_names)
        if vol_cols(n) > 0
            for r = 1:nrows_v
                val = raw_vol{data_start_v + r - 1, vol_cols(n)};
                if isnumeric(val) && ~isnan(val)
                    vol_data(r, n) = val;
                end
            end
        end
    end

    vol_dates = NaT(nrows_v, 1);
    for r = 1:nrows_v
        d = vol_dates_raw{r};
        if isnumeric(d) && d > 10000
            vol_dates(r) = datetime(d, 'ConvertFrom', 'excel');
        elseif ischar(d)
            try, vol_dates(r) = datetime(d); catch, end
        end
    end
    valid_vol = ~isnat(vol_dates);
    vol_dates = vol_dates(valid_vol);
    vol_data = vol_data(valid_vol, :);
    log_msg(sprintf('  Volume: %d quarters, %s to %s\n', sum(valid_vol), ...
        datestr(vol_dates(1)), datestr(vol_dates(end))));

catch ME
    log_msg(sprintf('  Volume FAILED: %s\n', ME.message));
    vol_data = []; vol_dates = [];
end

%% 3. ABS 6416 Residential Property Price Index
log_msg('\n--- ABS 6416 RPPI ---\n');
rppi_file = fullfile(datadir, 'abs_6416_rppi.xlsx');

try
    [~, sheets] = xlsfinfo(rppi_file);
    log_msg(sprintf('  Sheets: %s\n', strjoin(sheets, ', ')));

    % Read first data sheet
    sa_sheet = '';
    for s = 1:length(sheets)
        if contains(sheets{s}, 'Data1')
            sa_sheet = sheets{s};
            break;
        end
    end
    if isempty(sa_sheet), sa_sheet = sheets{min(2, length(sheets))}; end

    [~, ~, raw_rppi] = xlsread(rppi_file, sa_sheet);

    % Find weighted average 8 capitals
    rppi_col = 0;
    for j = 2:size(raw_rppi, 2)
        if ischar(raw_rppi{1, j}) && (contains(raw_rppi{1, j}, 'Weighted average', 'IgnoreCase', true) || ...
                                       contains(raw_rppi{1, j}, 'Eight capital', 'IgnoreCase', true) || ...
                                       contains(raw_rppi{1, j}, 'All groups', 'IgnoreCase', true))
            rppi_col = j;
            log_msg(sprintf('  RPPI col %d: %s\n', j, raw_rppi{1, j}));
            break;
        end
    end
    if rppi_col == 0
        % List all columns to find the right one
        log_msg('  No weighted average found. Available columns:\n');
        for j = 2:min(15, size(raw_rppi, 2))
            if ischar(raw_rppi{1, j})
                log_msg(sprintf('    Col %d: %s\n', j, raw_rppi{1, j}));
            end
        end
        rppi_col = 2;  % take first data column
    end

    % Extract data
    data_start_r = 0;
    for r = 1:size(raw_rppi, 1)
        if ischar(raw_rppi{r, 1}) && contains(raw_rppi{r, 1}, 'Series ID')
            data_start_r = r + 1;
            break;
        elseif isnumeric(raw_rppi{r, 1}) && raw_rppi{r, 1} > 10000
            data_start_r = r;
            break;
        end
    end

    nrows_r = size(raw_rppi, 1) - data_start_r + 1;
    rppi_data = nan(nrows_r, 1);
    rppi_dates = NaT(nrows_r, 1);
    for r = 1:nrows_r
        d = raw_rppi{data_start_r + r - 1, 1};
        if isnumeric(d) && d > 10000
            rppi_dates(r) = datetime(d, 'ConvertFrom', 'excel');
        elseif ischar(d)
            try, rppi_dates(r) = datetime(d); catch, end
        end
        val = raw_rppi{data_start_r + r - 1, rppi_col};
        if isnumeric(val), rppi_data(r) = val; end
    end
    valid_r = ~isnat(rppi_dates) & ~isnan(rppi_data);
    rppi_dates = rppi_dates(valid_r);
    rppi_data = rppi_data(valid_r);
    log_msg(sprintf('  RPPI: %d quarters, %s to %s\n', length(rppi_data), ...
        datestr(rppi_dates(1)), datestr(rppi_dates(end))));

catch ME
    log_msg(sprintf('  RPPI FAILED: %s\n', ME.message));
    rppi_data = []; rppi_dates = [];
end

%% 4. RBA F5: Housing Lending Rate
log_msg('\n--- RBA F5: Housing Lending Rates ---\n');
f5_file = fullfile(datadir, 'rba_f5.csv');

try
    % RBA CSV format: header rows then data
    % Read raw text to parse the irregular header
    ftext = fileread(f5_file);
    lines = strsplit(ftext, '\n');

    % Find the data start (after 'Series ID' row)
    data_start_f = 0;
    for r = 1:length(lines)
        if startsWith(lines{r}, 'Series ID')
            data_start_f = r + 1;
            break;
        end
    end

    % Parse title row to find housing loan rate column
    title_line = lines{2};  % Row 2 = Title
    titles = strsplit(title_line, ',');

    % Find "Housing loans; Banks; Variable; Standard; Owner-occupier"
    housing_col = 0;
    for j = 2:length(titles)
        if contains(titles{j}, 'Housing loans') && contains(titles{j}, 'Variable') && ...
           contains(titles{j}, 'Standard') && contains(titles{j}, 'Owner-occupier') && ...
           ~contains(titles{j}, 'interest-only')
            housing_col = j;
            log_msg(sprintf('  Housing rate col %d: %s\n', j, strtrim(titles{j})));
            break;
        end
    end

    if housing_col == 0
        log_msg('  Housing loan rate column not found!\n');
    end

    % Parse monthly data
    ndata = length(lines) - data_start_f;
    f5_dates = NaT(ndata, 1);
    f5_housing = nan(ndata, 1);

    for r = 1:ndata
        ln = lines{data_start_f + r - 1};
        if isempty(strtrim(ln)), continue; end
        parts = strsplit(ln, ',');
        if length(parts) < housing_col, continue; end

        % Parse date (DD/MM/YYYY)
        try
            f5_dates(r) = datetime(parts{1}, 'InputFormat', 'dd/MM/yyyy');
        catch
        end

        % Parse housing rate
        val = str2double(parts{housing_col});
        if ~isnan(val), f5_housing(r) = val; end
    end

    valid_f = ~isnat(f5_dates) & ~isnan(f5_housing);
    f5_dates = f5_dates(valid_f);
    f5_housing = f5_housing(valid_f);

    % Convert monthly -> quarterly (end-of-quarter)
    f5_years = year(f5_dates);
    f5_months = month(f5_dates);
    f5_quarters = ceil(f5_months / 3);

    % Take last month of each quarter
    [unique_yq, ~, idx] = unique([f5_years, f5_quarters], 'rows');
    nq = size(unique_yq, 1);
    housing_rate_q = nan(nq, 1);
    housing_dates_q = NaT(nq, 1);
    for q = 1:nq
        mask = idx == q;
        vals = f5_housing(mask);
        housing_rate_q(q) = vals(end);  % last month of quarter
        housing_dates_q(q) = f5_dates(find(mask, 1, 'last'));
    end

    valid_h = ~isnan(housing_rate_q);
    housing_dates_q = housing_dates_q(valid_h);
    housing_rate_q = housing_rate_q(valid_h);
    log_msg(sprintf('  Housing rate: %d quarters, %s to %s\n', ...
        length(housing_rate_q), datestr(housing_dates_q(1)), datestr(housing_dates_q(end))));
    log_msg(sprintf('  Latest rate: %.2f%% p.a.\n', housing_rate_q(end)));

catch ME
    log_msg(sprintf('  F5 FAILED: %s\n', ME.message));
    housing_rate_q = []; housing_dates_q = [];
end

%% 5. Save aligned dataset
log_msg('\n--- Saving aligned dataset ---\n');

result = struct();
result.ipd_dates = ipd_dates;
result.ipd_data = ipd_data;
result.ipd_names = {'ipd_c', 'ipd_ih', 'ipd_ib', 'ipd_x', 'ipd_m', 'ipd_g', 'ipd_gdp'};
result.vol_dates = vol_dates;
result.vol_data = vol_data;
result.vol_names = {'vol_x', 'vol_m', 'vol_c', 'vol_ih', 'vol_ib'};
result.rppi_dates = rppi_dates;
result.rppi_data = rppi_data;
result.housing_rate_dates = housing_dates_q;
result.housing_rate = housing_rate_q;

save(fullfile(datadir, 'abs_rba_dataset.mat'), '-struct', 'result');
log_msg(sprintf('  Saved to abs_rba_dataset.mat\n'));

%% 6. Quick summary statistics
log_msg('\n--- Summary statistics (1993Q1-2025Q4 where available) ---\n');

if ~isempty(ipd_data)
    % Compute quarterly inflation rates from IPD levels
    log_msg('  Component deflator inflation (q/q %, demeaned):\n');
    for n = 1:min(7, size(ipd_data, 2))
        if ipd_cols(n) > 0
            d = ipd_data(:, n);
            pi_q = [NaN; diff(log(d))] * 100;
            pi_q = pi_q - nanmean(pi_q);
            log_msg(sprintf('    %s: mean=%.3f, std=%.3f, T=%d\n', ...
                short_names{n}, nanmean(pi_q), nanstd(pi_q), sum(~isnan(pi_q))));
        end
    end
end

if ~isempty(rppi_data)
    dln_ph = [NaN; diff(log(rppi_data))] * 100;
    log_msg(sprintf('  Housing prices (dln_ph): mean=%.3f, std=%.3f, T=%d\n', ...
        nanmean(dln_ph), nanstd(dln_ph), sum(~isnan(dln_ph))));
end

if ~isempty(housing_rate_q)
    log_msg(sprintf('  Mortgage rate: mean=%.2f, std=%.2f, T=%d\n', ...
        nanmean(housing_rate_q), nanstd(housing_rate_q), length(housing_rate_q)));
end

log_msg('\n================================================================\n');
log_msg('  PROCESSING COMPLETE\n');
log_msg('================================================================\n');
fclose(fid);

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0, fprintf(fid, msg); end
end
