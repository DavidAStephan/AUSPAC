%% generate_dynamic_contributions.m
% Decompose PAC equation IRFs into additive component contributions.
% Styled like FR-BDF Figures 4.4.1, 4.5.2, 4.5.3, 4.6.1-4.6.3.
%
% For each PAC equation, decomposes the IRF to a monetary policy shock into:
%   - Error correction term
%   - AR lag(s)
%   - PAC expectation term (computed as residual: total - EC - AR - ad hoc)
%   - Ad hoc terms (output gap, interest rate)
%
% Must be run AFTER `dynare au_pac noclearall nograph`.
%
% Output: 5 PNG files (contrib_piQ.png, contrib_n.png, contrib_c.png,
%         contrib_ib.png, contrib_ih.png)

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

%% Run model if not already loaded
if ~exist('oo_', 'var') || ~exist('M_', 'var')
    fprintf('Running au_pac.mod...\n');
    dynare au_pac noclearall nograph;
end

shock_name = 'eps_i';
T = 40;  % quarters to plot

fprintf('\n=== DYNAMIC CONTRIBUTIONS (Monetary Policy Shock) ===\n\n');

%% Helper: get parameter value by name
get_param = @(name) M_.params(strcmp(cellstr(M_.param_names), name));

%% Helper: get IRF, pad if needed
get_irf = @(varname) get_irf_safe(oo_, varname, shock_name, T);

%% Color palette (FR-BDF style)
colors = struct(...
    'ec',      [0.2 0.4 0.8], ...   % blue
    'ar1',     [0.8 0.2 0.2], ...   % red
    'ar2',     [0.9 0.5 0.1], ...   % orange
    'ar3',     [0.6 0.3 0.6], ...   % purple
    'ar4',     [0.4 0.6 0.3], ...   % olive
    'pac_exp', [0.2 0.7 0.2], ...   % green
    'adhoc1',  [0.9 0.6 0.1], ...   % gold
    'adhoc2',  [0.5 0.8 0.9], ...   % light blue
    'total',   [0 0 0.5]);           % dark blue line

%% ========================================================================
%  1. VA Price (piQ) — 1st order PAC
%  ========================================================================
fprintf('--- 1. VA Price (piQ) ---\n');

b0_pQ = get_param('b0_pQ');
b1_pQ = get_param('b1_pQ');
b2_pQ = get_param('b2_pQ');

% diff(pQ_level) = b0_pQ*(gap(-1)) + b1_pQ*diff(pQ_level(-1)) + pac_exp + b2_pQ*yhat + eps
% piQ ≈ diff(pQ_level) in detrended model

irf_total = get_irf('piQ');       % if available; else try pQ_level
irf_yhat  = get_irf('yhat_au');

% Build lagged versions (IRF at t=0 is period 1)
irf_total_lag = [0, irf_total(1:T-1)];

% Component 1: EC term — need gap IRF
% gap = piQ_star_l(-1) - pQ_level(-1); approximate from cumulation
% Since we can't directly get pQ_gap IRF easily, compute from piQ
% pQ_gap(t) = pQ_gap(t-1) + piQ_star(t) - piQ(t)
% piQ_star shock response ≈ 0 (target is exogenous AR(1))
% So pQ_gap(t) ≈ pQ_gap(t-1) - piQ(t) = -cumsum(piQ)
pQ_gap_approx = -cumsum(irf_total);
pQ_gap_lag = [0, pQ_gap_approx(1:T-1)];

ec_comp    = b0_pQ * pQ_gap_lag;
ar1_comp   = b1_pQ * irf_total_lag;
adhoc_comp = b2_pQ * irf_yhat;
pac_comp   = irf_total - ec_comp - ar1_comp - adhoc_comp;

plot_contributions('VA Price Inflation (piQ): Dynamic Contributions', ...
    {ec_comp, ar1_comp, pac_comp, adhoc_comp}, ...
    {'EC term', 'AR(1) lag', 'PAC expectation', 'Output gap'}, ...
    {colors.ec, colors.ar1, colors.pac_exp, colors.adhoc1}, ...
    irf_total, T, 'contrib_piQ');

%% ========================================================================
%  2. Employment (dln_n) — 4th order PAC
%  ========================================================================
fprintf('--- 2. Employment (dln_n) ---\n');

b0_n = get_param('b0_n');
b1_n = get_param('b1_n');
b2_n = get_param('b2_n');
b3_n = get_param('b3_n');
b4_n = get_param('b4_n');
b5_n = get_param('b5_n');

irf_n = get_irf('dln_n');
irf_n_lag1 = [0, irf_n(1:T-1)];
irf_n_lag2 = [0, 0, irf_n(1:T-2)];
irf_n_lag3 = [0, 0, 0, irf_n(1:T-3)];
irf_n_lag4 = [0, 0, 0, 0, irf_n(1:T-4)];

n_gap_approx = -cumsum(irf_n);  % similar logic: n_gap ≈ -cumsum(dln_n)
n_gap_lag = [0, n_gap_approx(1:T-1)];

ec_n     = b0_n * n_gap_lag;
ar1_n    = b1_n * irf_n_lag1;
ar2_n    = b2_n * irf_n_lag2;
ar3_n    = b3_n * irf_n_lag3;
ar4_n    = b4_n * irf_n_lag4;
adhoc_n  = b5_n * irf_yhat;
pac_n    = irf_n - ec_n - ar1_n - ar2_n - ar3_n - ar4_n - adhoc_n;

plot_contributions('Employment (dln_n): Dynamic Contributions', ...
    {ec_n, ar1_n, ar2_n+ar3_n+ar4_n, pac_n, adhoc_n}, ...
    {'EC term', 'AR(1) lag', 'AR(2-4) lags', 'PAC expectation', 'Output gap'}, ...
    {colors.ec, colors.ar1, colors.ar2, colors.pac_exp, colors.adhoc1}, ...
    irf_n, T, 'contrib_n');

%% ========================================================================
%  3. Consumption (dln_c) — 1st order PAC
%  ========================================================================
fprintf('--- 3. Consumption (dln_c) ---\n');

b0_c = get_param('b0_c');
b1_c = get_param('b1_c');
b2_c = get_param('b2_c');
b3_c = get_param('b3_c');

irf_c = get_irf('dln_c');
irf_c_lag = [0, irf_c(1:T-1)];
irf_igap = get_irf('i_au');  % i_gap ≈ i_au - i_ss, but IRF of i_gap = IRF of i_au
irf_igap_lag = [0, irf_igap(1:T-1)];

c_gap_approx = -cumsum(irf_c);
c_gap_lag = [0, c_gap_approx(1:T-1)];

ec_c     = b0_c * c_gap_lag;
ar1_c    = b1_c * irf_c_lag;
rate_c   = b2_c * irf_igap_lag;
adhoc_c  = b3_c * irf_yhat;
pac_c    = irf_c - ec_c - ar1_c - rate_c - adhoc_c;

plot_contributions('Household Consumption (dln_c): Dynamic Contributions', ...
    {ec_c, ar1_c, pac_c, rate_c, adhoc_c}, ...
    {'EC term', 'AR(1) lag', 'PAC expectation', 'Interest rate', 'Output gap'}, ...
    {colors.ec, colors.ar1, colors.pac_exp, colors.adhoc2, colors.adhoc1}, ...
    irf_c, T, 'contrib_c');

%% ========================================================================
%  4. Business Investment (dln_ib) — 2nd order PAC
%  ========================================================================
fprintf('--- 4. Business Investment (dln_ib) ---\n');

b0_ib = get_param('b0_ib');
b1_ib = get_param('b1_ib');
b2_ib = get_param('b2_ib');
b3_ib = get_param('b3_ib');
b4_ib = get_param('b4_ib');

irf_ib = get_irf('dln_ib');
irf_ib_lag1 = [0, irf_ib(1:T-1)];
irf_ib_lag2 = [0, 0, irf_ib(1:T-2)];

ib_gap_approx = -cumsum(irf_ib);
ib_gap_lag = [0, ib_gap_approx(1:T-1)];

ec_ib    = b0_ib * ib_gap_lag;
ar1_ib   = b1_ib * irf_ib_lag1;
ar2_ib   = b2_ib * irf_ib_lag2;
adhoc_ib = b3_ib * irf_yhat;
rate_ib  = b4_ib * irf_igap_lag;
pac_ib   = irf_ib - ec_ib - ar1_ib - ar2_ib - adhoc_ib - rate_ib;

plot_contributions('Business Investment (dln_ib): Dynamic Contributions', ...
    {ec_ib, ar1_ib+ar2_ib, pac_ib, adhoc_ib, rate_ib}, ...
    {'EC term', 'AR(1-2) lags', 'PAC expectation', 'Accelerator', 'Interest rate'}, ...
    {colors.ec, colors.ar1, colors.pac_exp, colors.adhoc1, colors.adhoc2}, ...
    irf_ib, T, 'contrib_ib');

%% ========================================================================
%  5. Household Investment (dln_ih) — 2nd order PAC
%  ========================================================================
fprintf('--- 5. Household Investment (dln_ih) ---\n');

b0_ih = get_param('b0_ih');
b1_ih = get_param('b1_ih');
b2_ih = get_param('b2_ih');
b3_ih = get_param('b3_ih');
b4_ih = get_param('b4_ih');

irf_ih = get_irf('dln_ih');
irf_ih_lag1 = [0, irf_ih(1:T-1)];
irf_ih_lag2 = [0, 0, irf_ih(1:T-2)];

ih_gap_approx = -cumsum(irf_ih);
ih_gap_lag = [0, ih_gap_approx(1:T-1)];

ec_ih    = b0_ih * ih_gap_lag;
ar1_ih   = b1_ih * irf_ih_lag1;
ar2_ih   = b2_ih * irf_ih_lag2;
adhoc_ih = b3_ih * irf_yhat;
rate_ih  = b4_ih * irf_igap_lag;
pac_ih   = irf_ih - ec_ih - ar1_ih - ar2_ih - adhoc_ih - rate_ih;

plot_contributions('Housing Investment (dln_ih): Dynamic Contributions', ...
    {ec_ih, ar1_ih+ar2_ih, pac_ih, adhoc_ih, rate_ih}, ...
    {'EC term', 'AR(1-2) lags', 'PAC expectation', 'Output gap', 'Mortgage rate'}, ...
    {colors.ec, colors.ar1, colors.pac_exp, colors.adhoc1, colors.adhoc2}, ...
    irf_ih, T, 'contrib_ih');

fprintf('\n=== Dynamic contributions complete ===\n');

%% ========================================================================
%  LOCAL FUNCTIONS
%  ========================================================================

function irf = get_irf_safe(oo_, varname, shock_name, T)
    field = [varname '_' shock_name];
    if isfield(oo_.irfs, field)
        raw = oo_.irfs.(field);
        if length(raw) >= T
            irf = raw(1:T);
        else
            irf = [raw, zeros(1, T - length(raw))];
        end
    else
        fprintf('  WARNING: IRF %s not found, using zeros\n', field);
        irf = zeros(1, T);
    end
end

function plot_contributions(title_str, components, labels, plot_colors, total, T, filename)
    % Stacked bar chart of IRF contributions
    % components: cell array of 1xT vectors
    % labels: cell array of strings
    % plot_colors: cell array of RGB triplets
    % total: 1xT total IRF
    % filename: save name (without extension)

    nComp = length(components);
    data = zeros(T, nComp);
    for k = 1:nComp
        data(:, k) = components{k}(:);
    end

    fig = figure('Position', [100 100 900 400], 'Color', 'w', 'Visible', 'off');

    % Stacked bar
    b = bar(1:T, data, 'stacked', 'EdgeColor', 'none');
    for k = 1:nComp
        b(k).FaceColor = plot_colors{k};
    end

    hold on;
    plot(1:T, total, 'k-', 'LineWidth', 2);
    plot([1 T], [0 0], 'k:', 'LineWidth', 0.5);
    hold off;

    legend([labels, {'Total'}], 'Location', 'best', 'FontSize', 9);
    title(title_str, 'FontSize', 12);
    xlabel('Quarters after shock', 'FontSize', 10);
    ylabel('pp / % deviation', 'FontSize', 10);
    xlim([0.5 T+0.5]);
    grid on;
    set(gca, 'FontSize', 10);

    print(fig, filename, '-dpng', '-r300');
    fprintf('  Saved: %s.png\n', filename);
    close(fig);
end
