%% generate_data_plots.m
% Generates a 9-panel figure showing all observable time series
% used in AU-PAC estimation (Figure 5.1 for working paper).

clear; clc;
projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
dates_base = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');

% Transform to model-consistent units
yhat_au = T_base.au_ygap;
pi_au   = T_base.au_pi;
i_au    = T_base.au_irate;           % already quarterly %
yhat_us = T_base.us_ygap;
pi_us   = T_base.us_pi;
pi_w    = T_ext.au_pi_w;
i_10y   = T_ext.au_i10 / 4;         % annual -> quarterly
cons    = T_ext.au_consumption;
dln_c   = [NaN; diff(log(cons))]*100;
gfcf_nd = T_ext.au_gfcf_nondwelling;
dln_ib  = [NaN; diff(log(gfcf_nd))]*100;

vars   = {yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y};
titles = {'AU Output Gap (\hat{y})', 'AU Inflation (\pi)', ...
          'RBA Cash Rate (i)', 'US Output Gap (\hat{y}^{US})', ...
          'US Inflation (\pi^{US})', 'Wage Inflation (\pi_w)', ...
          'Consumption Growth (\Delta\ln c)', 'Bus. Inv. Growth (\Delta\ln i_b)', ...
          '10Y Bond Yield (i_{10})'};
ylabs  = {'% gap', 'quarterly %', 'quarterly %', '% gap', ...
           'quarterly %', 'quarterly %', 'quarterly %', 'quarterly %', 'quarterly %'};

fig = figure('Position', [50 50 1400 900], 'Visible', 'off');
for k = 1:9
    subplot(3, 3, k);
    v = vars{k};
    valid = ~isnan(v);
    plot(dates_base(valid), v(valid), 'b-', 'LineWidth', 1.2);
    hold on;
    yline(0, 'k--', 'LineWidth', 0.5);
    title(titles{k}, 'FontSize', 10);
    ylabel(ylabs{k}, 'FontSize', 8);
    xlim([dates_base(1), dates_base(end)]);
    grid on;
    set(gca, 'FontSize', 8);
end
sgtitle('AU-PAC Observable Variables (1993Q1-2024Q4)', 'FontSize', 13);
saveas(fig, fullfile(fileparts(mfilename('fullpath')), 'data_observables.png'));
close(fig);
fprintf('Saved data_observables.png\n');
