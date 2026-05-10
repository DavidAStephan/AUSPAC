%% download_supply_data.m
% Phase G Stage 0: Fetch ABS series needed for the CES production-function
% supply block (FR-BDF Section 4.3).
%
% Series targeted:
%   1. ABS 5206 Table 6/7   — Industry GVA chain volumes + current prices
%                              (for market-branches Q and VA deflator P_Q)
%   2. ABS 5204             — Capital services and depreciation (annual)
%                              [optional; perpetual-inventory K can be built
%                               instead from quarterly investment]
%   3. ABS 6202             — Labour Force (employed persons, hours worked,
%                              labour force, unemployment)
%   4. ABS 6291             — Labour Force Detailed by industry
%   5. ABS 6345             — Wage Price Index (private + public)
%   6. ABS 6302             — Average Weekly Earnings (alternative wage series)
%
% URLs use the dec-2025 release where available; if a URL 404s the script
% logs the failure and continues. Manual download instructions are written to
% download_supply_log.txt for any series that don't fetch automatically.

clear; clc;
fprintf('=== Phase G Stage 0: ABS supply-side data download ===\n\n');

outdir = fullfile(fileparts(mfilename('fullpath')), 'abs_rba');
if ~exist(outdir, 'dir'), mkdir(outdir); end

logfile = fullfile(outdir, 'download_supply_log.txt');
fid = fopen(logfile, 'w');
fprintf(fid, 'Phase G Stage 0 download: %s\n\n', datestr(now));

% (URL, local-filename, label) — the ABS URL pattern is
% https://www.abs.gov.au/statistics/<topic>/<release>/<file>.xlsx
% File numbers follow the publication-table convention (e.g. 5206006 = ABS
% Cat 5206, Table 6).
urls = {
    % --- ABS 5206 (Quarterly National Accounts) ---
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/dec-2025/5206006_Industry_GVA.xlsx', ...
        'abs_5206_industry_gva.xlsx', 'ABS 5206 Tab 6: Industry GVA (quarterly, vol+CP)';
    % --- ABS 6202 (Labour Force monthly) ---
    'https://www.abs.gov.au/statistics/labour/employment-and-unemployment/labour-force-australia/feb-2026/6202001.xlsx', ...
        'abs_6202_labour_force.xlsx', 'ABS 6202 Tab 1: Labour Force aggregates';
    'https://www.abs.gov.au/statistics/labour/employment-and-unemployment/labour-force-australia/feb-2026/6202019.xlsx', ...
        'abs_6202_hours.xlsx', 'ABS 6202 Tab 19: Aggregate monthly hours worked';
    % --- ABS 6345 (Wage Price Index quarterly) ---
    'https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/wage-price-index-australia/dec-2025/634501.xlsx', ...
        'abs_6345_wpi.xlsx', 'ABS 6345 Tab 1: Wage Price Index';
    % --- ABS 6302 (Average Weekly Earnings) ---
    'https://www.abs.gov.au/statistics/labour/earnings-and-working-conditions/average-weekly-earnings-australia/nov-2025/6302001.xlsx', ...
        'abs_6302_awe.xlsx', 'ABS 6302 Tab 1: Average Weekly Earnings';
    % --- ABS 5204 (Annual Australian System of National Accounts) ---
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-system-national-accounts/2024-25/5204063_Net_Capital_Stock_By_Industry.xlsx', ...
        'abs_5204_net_capital_stock.xlsx', 'ABS 5204 Tab 63: Net capital stock by industry (annual)';
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-system-national-accounts/2024-25/5204047_Cons_Fixed_Capital_By_Industry.xlsx', ...
        'abs_5204_depreciation.xlsx', 'ABS 5204 Tab 47: Consumption of fixed capital by industry (annual)';
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-system-national-accounts/2024-25/5204048_Comp_Employees_By_Industry.xlsx', ...
        'abs_5204_compensation.xlsx', 'ABS 5204 Tab 48: Compensation of employees by industry (annual)';
    'https://www.abs.gov.au/statistics/economy/national-accounts/australian-system-national-accounts/2024-25/5204013_Productivity.xlsx', ...
        'abs_5204_productivity.xlsx', 'ABS 5204 Tab 13: Productivity (capital services growth, hours)';
};

success = false(size(urls, 1), 1);

for k = 1:size(urls, 1)
    url = urls{k, 1};
    fname = fullfile(outdir, urls{k, 2});
    label = urls{k, 3};
    fprintf('  %-50s ... ', label);
    fprintf(fid, '%s\n  URL: %s\n', label, url);
    try
        opts = weboptions('Timeout', 60, 'CertificateFilename', '');
        websave(fname, url, opts);
        d = dir(fname);
        if d.bytes > 1024  % >1KB suggests a real file, not an error page
            fprintf('OK (%d KB)\n', round(d.bytes/1024));
            fprintf(fid, '  Saved: %s (%d bytes)\n\n', fname, d.bytes);
            success(k) = true;
        else
            fprintf('FAILED (file too small, likely 404)\n');
            fprintf(fid, '  FAILED: response too small (%d bytes)\n\n', d.bytes);
            delete(fname);
        end
    catch ME
        fprintf('FAILED: %s\n', ME.message);
        fprintf(fid, '  FAILED: %s\n\n', ME.message);
    end
end

%% Report
fprintf('\n=== Download summary ===\n');
fprintf('  %d of %d series fetched successfully.\n', sum(success), length(success));
if any(~success)
    fprintf('\nManual download required for failed series:\n');
    fprintf(fid, '\n=== Manual download required ===\n');
    for k = find(~success(:))'
        fprintf('  - %s\n      URL pattern: %s\n', urls{k, 3}, urls{k, 1});
        fprintf(fid, '  - %s\n      Save as: %s\n      Try: %s\n\n', ...
            urls{k, 3}, fullfile(outdir, urls{k, 2}), urls{k, 1});
    end
    fprintf('\nNote: ABS publication URLs change with each release. If the\n');
    fprintf('dec-2025 / feb-2026 URLs above fail, navigate to abs.gov.au, find\n');
    fprintf('the relevant publication, and copy the latest file URL.\n');
end

fclose(fid);
fprintf('\nLog: %s\n', logfile);
fprintf('=== Done ===\n');
