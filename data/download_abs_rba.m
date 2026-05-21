%% download_abs_rba.m — Download ABS and RBA data for Phase 4 estimation
% Downloads:
%   1. ABS 5206 Table 5 — Expenditure Implicit Price Deflators (quarterly)
%   2. ABS 5206 Table 2 — Expenditure Chain Volume Measures (quarterly)
%   3. RBA Table F5 — Indicator Lending Rates (monthly)
%   4. RBA Table F6 — Housing Lending Rates (monthly)

outdir = fullfile(fileparts(mfilename('fullpath')), 'abs_rba');
if ~exist(outdir, 'dir'), mkdir(outdir); end

fid = fopen(fullfile(outdir, 'download_log.txt'), 'w');
fprintf(fid, 'ABS/RBA data download: %s\n\n', datestr(now));

urls = {
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/dec-2025/5206005_Expenditure_Implicit_Price_Deflators.xlsx', ...
        'abs_5206_ipd.xlsx', 'ABS 5206 Table 5: Expenditure IPDs';
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/dec-2025/5206002_Expenditure_Volume_Measures.xlsx', ...
        'abs_5206_vol.xlsx', 'ABS 5206 Table 2: Expenditure Volume Measures';
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/dec-2025/5206020_Household_Income.xlsx', ...
        'abs_5206_household_income.xlsx', 'ABS 5206 Table 20: Household Income Account (Round 1.2 source)';
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/dec-2025/5206022_Taxes.xlsx', ...
        'abs_5206_taxes.xlsx', 'ABS 5206 Table 22: Taxes (PAYG / CIT / GST decomposition for Round 6)';
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/dec-2025/5206023_Social_Assistance_Benefits.xlsx', ...
        'abs_5206_social_assistance.xlsx', 'ABS 5206 Table 23: Social Assistance Benefits (TG_H detail)';
    'https://www.rba.gov.au/statistics/tables/csv/f5-data.csv', ...
        'rba_f5.csv', 'RBA F5: Indicator Lending Rates';
    'https://www.rba.gov.au/statistics/tables/csv/f6-data.csv', ...
        'rba_f6.csv', 'RBA F6: Housing Lending Rates';
};

for k = 1:size(urls, 1)
    url = urls{k, 1};
    fname = fullfile(outdir, urls{k, 2});
    label = urls{k, 3};
    fprintf('Downloading %s...\n', label);
    fprintf(fid, '%s\n  URL: %s\n', label, url);
    try
        websave(fname, url);
        d = dir(fname);
        fprintf(fid, '  Saved: %s (%d bytes)\n\n', fname, d.bytes);
        fprintf('  OK (%d bytes)\n', d.bytes);
    catch ME
        fprintf(fid, '  FAILED: %s\n\n', ME.message);
        fprintf('  FAILED: %s\n', ME.message);
    end
end

% Also try the housing price data from Total Value of Dwellings
fprintf('\nDownloading ABS Total Value of Dwellings...\n');
try
    url_tvd = 'https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/latest-release';
    % The actual data file URL pattern — try the xlsx download
    url_tvd_data = 'https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/dec-quarter-2025/6432001.xlsx';
    fname_tvd = fullfile(outdir, 'abs_6432_tvd.xlsx');
    websave(fname_tvd, url_tvd_data);
    d = dir(fname_tvd);
    fprintf(fid, 'ABS Total Value of Dwellings\n  URL: %s\n  Saved: %s (%d bytes)\n\n', url_tvd_data, fname_tvd, d.bytes);
    fprintf('  OK (%d bytes)\n', d.bytes);
catch ME
    fprintf(fid, 'ABS Total Value of Dwellings: FAILED: %s\n\n', ME.message);
    fprintf('  FAILED: %s\n  Trying alternate URL...\n', ME.message);
    % Try alternate filename patterns
    alt_urls = {
        'https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/dec-quarter-2025/6432002.xlsx'
        'https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/total-value-dwellings/dec-quarter-2025/64320DO001.xlsx'
    };
    for j = 1:length(alt_urls)
        try
            websave(fname_tvd, alt_urls{j});
            d = dir(fname_tvd);
            fprintf(fid, '  Alt URL OK: %s (%d bytes)\n', alt_urls{j}, d.bytes);
            fprintf('  Alt OK (%d bytes)\n', d.bytes);
            break;
        catch
            fprintf('  Alt %d also failed\n', j);
        end
    end
end

% Try the old 6416.0 RPPI (last release Dec 2021)
fprintf('\nDownloading ABS 6416.0 RPPI (last release Dec 2021)...\n');
try
    url_rppi = 'https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/residential-property-price-indexes-eight-capital-cities/dec-2021/641601.xlsx';
    fname_rppi = fullfile(outdir, 'abs_6416_rppi.xlsx');
    websave(fname_rppi, url_rppi);
    d = dir(fname_rppi);
    fprintf(fid, 'ABS 6416.0 RPPI (Dec 2021)\n  Saved: %s (%d bytes)\n\n', fname_rppi, d.bytes);
    fprintf('  OK (%d bytes)\n', d.bytes);
catch ME
    fprintf(fid, 'ABS 6416.0 RPPI: FAILED: %s\n\n', ME.message);
    fprintf('  FAILED: %s\n', ME.message);
    % Try alternate
    try
        url_rppi2 = 'https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/residential-property-price-indexes-eight-capital-cities/dec-2021/6416001.xlsx';
        websave(fname_rppi, url_rppi2);
        d = dir(fname_rppi);
        fprintf('  Alt OK (%d bytes)\n', d.bytes);
    catch, fprintf('  Alt also failed\n'); end
end

fprintf(fid, '\nDownload complete: %s\n', datestr(now));
fclose(fid);
fprintf('\nAll downloads complete. See %s\n', fullfile(outdir, 'download_log.txt'));
