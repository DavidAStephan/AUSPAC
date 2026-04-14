%% download_ces_data.m — Download ABS data for CES production function estimation
%
% Downloads from ABS website via actxserver (R2019a xlsx workaround):
%   1. ABS 5206.0 Table 7: GDP Income (COE, GOS, GMI) — for alpha_k
%   2. ABS 5206.0 Table 5: GDP deflator index — for VA price level
%   3. ABS 6345.0: Wage Price Index — for wage level
%   4. ABS 5204.0 Table 51: Capital stock (annual) — for delta_k
%
% Alternative: download pre-formatted CSVs from ABS data explorer
%
% USAGE:
%   cd('c:\Users\david\french_model\data\abs_rba')
%   download_ces_data

clear; clc;
outdir = fileparts(mfilename('fullpath'));
if isempty(outdir), outdir = pwd; end

fid = fopen(fullfile(outdir, 'ces_download_log.txt'), 'w');
logm = @(msg) fprintf_both(fid, msg);

logm('================================================================\n');
logm('  ABS DATA DOWNLOAD FOR CES ESTIMATION\n');
logm(sprintf('  %s\n', datestr(now)));
logm('================================================================\n\n');

%% =====================================================================
%  APPROACH: Use ABS Data Explorer API (CSV format, no xlsx issues)
%  =====================================================================
%  ABS provides a SDMX-compatible REST API at stat.data.abs.gov.au
%  Format: https://api.data.abs.gov.au/data/{dataflowId}/{dataKey}?format=csv
%
%  Alternative: direct xlsx table downloads from abs.gov.au/statistics

urls = {
    % GDP Income components (5206.0 Table 7, quarterly, current prices, SA)
    % Compensation of employees: ABS dataflow ANA_AGGREGATE, measure COMPE
    % Gross operating surplus: measure GOS
    'https://api.data.abs.gov.au/data/ABS,ANA_AGGREGATE,1.0.0/Q.1+2+3+4.AUS.GP.SA?format=csv&startPeriod=1990-Q1', ...
        'abs_5206_income.csv', 'ABS 5206 GDP Income (Table 7)'
    % Wage Price Index (6345.0, quarterly, SA, all sectors, total hourly)
    'https://api.data.abs.gov.au/data/ABS,WPI,1.0.0/Q.3.7.0.20.30.10.AUS?format=csv&startPeriod=1990-Q1', ...
        'abs_6345_wpi.csv', 'ABS 6345 Wage Price Index'
    % GDP deflator: can be computed from 5206.0 current/chain volume GDP
    % But easier to get the implicit price deflator directly
    'https://api.data.abs.gov.au/data/ABS,ANA_AGGREGATE_IPD,1.0.0/Q.1.AUS.GP.SA?format=csv&startPeriod=1990-Q1', ...
        'abs_5206_gdp_ipd.csv', 'ABS 5206 GDP IPD'
};

for k = 1:size(urls, 1)
    url = urls{k, 1};
    fname = urls{k, 2};
    desc = urls{k, 3};
    outfile = fullfile(outdir, fname);

    logm(sprintf('Downloading %s...\n', desc));
    logm(sprintf('  URL: %s\n', url));

    try
        opts = weboptions('Timeout', 30, 'ContentType', 'text');
        websave(outfile, url, opts);
        % Check file size
        d = dir(outfile);
        logm(sprintf('  OK: %d bytes\n', d.bytes));
    catch ME
        logm(sprintf('  FAILED: %s\n', ME.message));
        logm('  Trying alternative approach...\n');

        % Fallback: try with Java URL connection (SSL workaround for R2019a)
        try
            jurl = java.net.URL(url);
            conn = jurl.openConnection();
            conn.setRequestProperty('Accept', 'text/csv');
            conn.setConnectTimeout(30000);
            conn.setReadTimeout(30000);
            is = conn.getInputStream();
            reader = java.io.BufferedReader(java.io.InputStreamReader(is));

            fout = fopen(outfile, 'w');
            line = reader.readLine();
            while ~isempty(line)
                fprintf(fout, '%s\n', char(line));
                line = reader.readLine();
            end
            fclose(fout);
            reader.close();

            d = dir(outfile);
            logm(sprintf('  Java fallback OK: %d bytes\n', d.bytes));
        catch ME2
            logm(sprintf('  Java fallback also failed: %s\n', ME2.message));
        end
    end
end

%% =====================================================================
%  MANUAL FALLBACK: Construct from FRED data we already have
%  =====================================================================
%  If ABS API fails, we can construct approximate factor shares from
%  the FRED OECD data already downloaded

logm('\n--- Checking for FRED fallback data ---\n');
freddir = fullfile(outdir, '..');

% FRED has AU labor share from Penn World Table (annual)
% LABSHPAUA156NRUG — but download may have timed out earlier
ls_file = fullfile(freddir, 'fred_LABSHPAUA156NRUG.csv');
if exist(ls_file, 'file')
    logm(sprintf('  Found FRED labor share: %s\n', ls_file));
else
    logm('  FRED labor share not found. Trying download...\n');
    try
        url_ls = 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=LABSHPAUA156NRUG';
        opts = weboptions('Timeout', 15);
        websave(ls_file, url_ls, opts);
        logm('  FRED download OK\n');
    catch
        logm('  FRED download failed (timeout)\n');
    end
end

% FRED also has OECD unit labor costs for AU
ulc_file = fullfile(freddir, 'fred_ULQELP01AUQ661S.csv');
if ~exist(ulc_file, 'file')
    logm('  Trying OECD ULC index from FRED...\n');
    try
        url_ulc = 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=ULQELP01AUQ661S';
        opts = weboptions('Timeout', 15);
        websave(ulc_file, url_ulc, opts);
        logm('  OECD ULC download OK\n');
    catch
        logm('  OECD ULC download failed\n');
    end
end

% CPI index (we already have this)
cpi_file = fullfile(freddir, 'fred_AUSCPIALLQINMEI.csv');
if exist(cpi_file, 'file')
    logm(sprintf('  Found CPI index: %s\n', cpi_file));
end

%% Summary
logm('\n--- Download summary ---\n');
files_to_check = {
    fullfile(outdir, 'abs_5206_income.csv'), 'GDP income (COE, GOS)'
    fullfile(outdir, 'abs_6345_wpi.csv'), 'Wage Price Index'
    fullfile(outdir, 'abs_5206_gdp_ipd.csv'), 'GDP deflator'
    ls_file, 'Labor share (FRED)'
    ulc_file, 'ULC index (FRED)'
};

for k = 1:size(files_to_check, 1)
    f = files_to_check{k, 1};
    desc = files_to_check{k, 2};
    if exist(f, 'file')
        d = dir(f);
        logm(sprintf('  [OK]   %-30s %d bytes\n', desc, d.bytes));
    else
        logm(sprintf('  [MISS] %-30s\n', desc));
    end
end

logm('\n================================================================\n');
logm('  DOWNLOAD COMPLETE\n');
logm('================================================================\n');
fclose(fid);

end

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0, fprintf(fid, msg); end
end
