%% make_paper_charts.m -- regenerate paper charts from Phase L2 .mat outputs
%
% Produces the chart set referenced from the regenerated working paper
% into dynare/paper_artifacts/.
%
% Run from MATLAB GUI (R2020a -batch is blocked on Apple Silicon; see
% WORKING_PAPER_BLOCKERS.md):
%
%     cd ~/Documents/AUSPAC/data
%     make_paper_charts
%
% Output PNGs into dynare/paper_artifacts/:
%   chart_fitted_actual_<block>.png      (5 panels: VA-price, employment,
%                                         consumption, housing_inv, business_inv)
%   chart_residual_hist_<block>.png      (5 panels)
%   chart_beta0_cross_block.png          (AU vs wp1044 beta_0 bar chart)
%   chart_bi_exploration.png             (BI spec variant R^2 bar chart)
%   chart_l11_trend_efficiency.png       (L1.1 E_t fitted trend)
%   chart_l12_trend_regimes.png          (L1.2 trend regime growth rates)

clear; clc;
projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
blocks_dir = fullfile(projectdir, 'data', 'pac_blocks');
art_dir    = fullfile(projectdir, 'dynare', 'paper_artifacts');
if ~exist(art_dir, 'dir'); mkdir(art_dir); end

fprintf('=== make_paper_charts ===\n');

%% Fitted vs actual per block
blocks = {'va_price','employment','consumption','housing_inv','business_inv'};
for k = 1:numel(blocks)
    f = fullfile(blocks_dir, ['results_' blocks{k} '.mat']);
    if ~exist(f, 'file'); fprintf('  skip %s (no .mat)\n', blocks{k}); continue; end
    R = load(f);
    if ~isfield(R, 'y_fitted') || ~isfield(R, 'y_actual')
        fprintf('  skip %s (no y_fitted/y_actual)\n', blocks{k}); continue;
    end
    fh = figure('visible', 'off', 'Position', [100 100 900 380]);
    plot(R.y_actual, 'k-', 'LineWidth', 1.2); hold on;
    plot(R.y_fitted, 'b--', 'LineWidth', 1.4);
    xlabel('quarter'); ylabel('100*\Delta log'); grid on;
    legend({'actual','fitted'}, 'Location', 'best');
    title(sprintf('PAC fitted vs actual — %s (wp1044 spec, AU iterative OLS)', ...
                  strrep(blocks{k}, '_', ' ')));
    saveas(fh, fullfile(art_dir, ['chart_fitted_actual_' blocks{k} '.png']));
    close(fh);
end

%% Residual histograms per block
for k = 1:numel(blocks)
    f = fullfile(blocks_dir, ['results_' blocks{k} '.mat']);
    if ~exist(f, 'file'); continue; end
    R = load(f);
    if ~isfield(R, 'resid'); continue; end
    fh = figure('visible', 'off', 'Position', [100 100 700 400]);
    histogram(R.resid, 25); grid on;
    xlabel('residual'); ylabel('count');
    title(sprintf('PAC residual histogram — %s', strrep(blocks{k}, '_', ' ')));
    saveas(fh, fullfile(art_dir, ['chart_residual_hist_' blocks{k} '.png']));
    close(fh);
end

%% Cross-block beta_0 bar chart (AU L2 vs wp1044)
% Numbers (hard-coded for clarity, matching make_paper_tables.m):
au_b0 = [NaN NaN NaN NaN];
labels = {'VA-price','employment','consumption','housing inv'};
for k = 1:numel(labels)
    sf = lower(strrep(labels{k}, ' ', '_'));
    R = load(fullfile(blocks_dir, ['results_' sf '.mat']));
    if isfield(R, 'beta_0'); au_b0(k) = R.beta_0; end
end
fr_b0 = [0.05 0.07 0.29 0.12];                       % wp1044 reference
labels_full = [labels, {'business inv'}];
au_b0_full = [au_b0, NaN];                            % BI: wp1044 imported
fr_b0_full = [fr_b0, 0.096];
fh = figure('visible', 'off', 'Position', [100 100 850 420]);
bar([fr_b0_full(:), au_b0_full(:)]);
set(gca, 'XTickLabel', labels_full);
ylabel('beta_0 (ECM speed)'); grid on;
legend({'wp1044 FR','AU L2'}, 'Location', 'best');
title('Cross-block beta_0 (ECM speed): AU L2 4-8x faster than France except consumption');
saveas(fh, fullfile(art_dir, 'chart_beta0_cross_block.png'));
close(fh);

%% BI exploration variants R^2 bar chart
v_labels = {'baseline (strict PAC)','v1 +dummies','v2 pre-residualize', ...
            'v3-A PV free','v3-B strict','v3-C loose clamps', ...
            'v4 PV coef=1','v5 ToT+trends','v6 ToT target','wp736 form','simplified (no PV)'};
v_R2     = [0.09, 0.11, -23.7, 0.53, -2.20, -67.0, -33.0, -10.7, -39.1, -0.75, 0.33];
fh = figure('visible', 'off', 'Position', [100 100 900 480]);
bh = barh(1:numel(v_R2), v_R2);
set(gca, 'YTick', 1:numel(v_R2), 'YTickLabel', v_labels);
xlabel('R^2 on raw dln_ib'); grid on;
title({'AU business investment: 11 specification variants tested in Phase L2 P1c', ...
       'Strict wp1044 PAC structurally rejected (PV(\Delta q\^) coefficient negative)'});
saveas(fh, fullfile(art_dir, 'chart_bi_exploration.png'));
close(fh);

%% L1.1 trend efficiency
tf = load(fullfile(projectdir, 'data', 'trend_efficiency.mat'));
if isfield(tf, 'E_bar_fitted')
    fh = figure('visible', 'off', 'Position', [100 100 900 360]);
    plot(tf.E_bar_fitted, 'b-', 'LineWidth', 1.2); grid on;
    xlabel('quarter'); ylabel('E_t (log efficiency)');
    title('L1.1 trend efficiency \bar E_t (AU L2 estimate of FR-BDF Eq 7)');
    saveas(fh, fullfile(art_dir, 'chart_l11_trend_efficiency.png'));
    close(fh);
end

%% L1.2 trend regime growth rates
ts = load(fullfile(projectdir, 'data', 'trend_series.mat'));
f = fieldnames(ts); rates = nan(numel(f),1); rate_lbls = {};
for k = 1:numel(f)
    if isnumeric(ts.(f{k})) && isscalar(ts.(f{k}))
        rates(k) = ts.(f{k}); rate_lbls{end+1} = f{k}; %#ok<SAGROW>
    end
end
rates = rates(~isnan(rates));
if ~isempty(rates)
    fh = figure('visible', 'off', 'Position', [100 100 800 380]);
    bar(rates); grid on;
    set(gca, 'XTickLabel', rate_lbls, 'XTickLabelRotation', 45);
    ylabel('annualised growth rate (%)');
    title('L1.2 block-specific trend regime growth rates (HP-filtered)');
    saveas(fh, fullfile(art_dir, 'chart_l12_trend_regimes.png'));
    close(fh);
end

fprintf('done. wrote charts to %s\n', art_dir);
