%% compare_irfs_paper.m
% Compare au_pac IRFs to FR-BDF paper Section 5.2 benchmarks
% Run after: dynare au_pac noclearall nograph
%
% Paper benchmarks (Section 5.2.1, +100bp annualized short rate shock):
%   GDP peak:     -0.15% at Q12
%   Consumption:  -0.14% peak
%   Bus. inv:     -0.70% peak
%   HH inv:       -0.70% peak
%   Exports:      +0.35% peak (medium run, after competitiveness gain)
%   Imports:      -0.25% peak
%   Unemp:        +0.10pp peak
%   VA infl:      -0.10pp y-o-y peak at Q12
%   Wage infl:    -0.14pp peak
%   Long rate:    +0.16pp on impact
%   NEER:         +0.40% appreciation on impact

addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

% Run model if not already loaded
if ~exist('oo_','var')
    dynare au_pac noclearall nograph;
end

fprintf('\n========================================\n');
fprintf('IRF COMPARISON: au_pac vs FR-BDF (WP #736 Section 5.2)\n');
fprintf('========================================\n');
fprintf('Shock: eps_i (Taylor rule shock, +1 stderr = %.3f quarterly)\n', M_.Sigma_e(strcmp(M_.exo_names,'eps_i'),strcmp(M_.exo_names,'eps_i'))^0.5);
fprintf('Note: FR-BDF uses +100bp ANNUALIZED (+25bp quarterly) short rate shock.\n');
fprintf('au_pac shock is 1 stderr of eps_i. Scale accordingly.\n\n');

% Extract IRFs to monetary policy shock (eps_i)
shock_name = 'eps_i';
vars_to_check = {'yhat_au','dln_c','dln_ib','dln_ih','dln_x','dln_m',...
                  'piQ','pi_w','pi_c','i_10y','s_gap','i_lh','dln_ph','rw_gap','iad'};

fprintf('%-20s %10s %10s %10s\n', 'Variable', 'Peak', 'At Q', 'Sign');
fprintf('%-20s %10s %10s %10s\n', repmat('-',1,20), repmat('-',1,10), repmat('-',1,10), repmat('-',1,10));

for i = 1:length(vars_to_check)
    vname = vars_to_check{i};
    irf_field = [vname '_' shock_name];
    if isfield(oo_.irfs, irf_field)
        irf_data = oo_.irfs.(irf_field);
        [~, peak_idx] = max(abs(irf_data));
        peak_val = irf_data(peak_idx);
        fprintf('%-20s %10.4f %10d %10s\n', vname, peak_val, peak_idx, ...
            iff(peak_val>0,'+','-'));
    else
        fprintf('%-20s %10s\n', vname, 'NOT FOUND');
    end
end

fprintf('\n--- FR-BDF Paper Benchmarks (Section 5.2.1, +100bp annual) ---\n');
fprintf('%-20s %10s %10s\n', 'Variable', 'FR-BDF', 'Direction');
fprintf('%-20s %10s %10s\n', repmat('-',1,20), repmat('-',1,10), repmat('-',1,10));
fprintf('%-20s %10s %10s\n', 'GDP', '-0.15%', 'negative');
fprintf('%-20s %10s %10s\n', 'Consumption', '-0.14%', 'negative');
fprintf('%-20s %10s %10s\n', 'Bus. investment', '-0.70%', 'negative');
fprintf('%-20s %10s %10s\n', 'HH investment', '-0.70%', 'negative');
fprintf('%-20s %10s %10s\n', 'Exports', '+0.35%', 'pos (medium run)');
fprintf('%-20s %10s %10s\n', 'Imports', '-0.25%', 'negative');
fprintf('%-20s %10s %10s\n', 'VA price infl', '-0.10pp', 'negative');
fprintf('%-20s %10s %10s\n', 'Wage infl', '-0.14pp', 'negative');
fprintf('%-20s %10s %10s\n', 'Long rate', '+0.16pp', 'positive');
fprintf('%-20s %10s %10s\n', 'NEER', '+0.40%%', 'appreciation');

fprintf('\n--- Qualitative Sign Checks ---\n');
% Check signs match paper
checks = {
    'yhat_au',    'negative', 'GDP falls after rate hike';
    'dln_c',      'negative', 'Consumption falls (substitution + income)';
    'dln_ib',     'negative', 'Business investment falls (higher user cost)';
    'dln_ih',     'negative', 'HH investment falls (mortgage channel)';
    'piQ',        'negative', 'VA price inflation falls (Phillips)';
    'pi_w',       'negative', 'Wage inflation falls (unemployment)';
    'i_10y',      'positive', 'Long rate rises (term structure)';
    's_gap',      'negative', 'Exchange rate appreciates (UIP)';
};

n_pass = 0;
for i = 1:size(checks,1)
    vname = checks{i,1};
    expected_sign = checks{i,2};
    description = checks{i,3};
    irf_field = [vname '_' shock_name];
    if isfield(oo_.irfs, irf_field)
        irf_data = oo_.irfs.(irf_field);
        [~, peak_idx] = max(abs(irf_data));
        peak_val = irf_data(peak_idx);
        if strcmp(expected_sign,'negative')
            pass = peak_val < 0;
        else
            pass = peak_val > 0;
        end
        if pass
            fprintf('  PASS: %-15s (%s) peak=%.4f\n', vname, description, peak_val);
            n_pass = n_pass + 1;
        else
            fprintf('  FAIL: %-15s (%s) peak=%.4f, expected %s\n', vname, description, peak_val, expected_sign);
        end
    end
end
fprintf('\nSign checks: %d/%d passed\n', n_pass, size(checks,1));

% Helper function
function r = iff(cond, a, b)
    if cond; r = a; else; r = b; end
end
