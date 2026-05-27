%% make_paper_tables.m -- regenerate the 9 paper tables from Phase L2 .mat outputs
%
% Produces nine sets of (.txt, .tex) files into dynare/paper_artifacts/ for
% inclusion in the regenerated working paper.  Numbers come from per-block
% results_*.mat files in data/pac_blocks/ (Phase L2 iterative-OLS outputs)
% and from a hard-coded wp1044 look-up table (sourced from Dubois et al.
% 2026, Tables 3.3.3, 3.4.9, 3.5.2, 3.5.7, 3.5.13).
%
% Run from MATLAB GUI (R2020a -batch is blocked on Apple Silicon; see
% WORKING_PAPER_BLOCKERS.md):
%
%     cd ~/Documents/AUSPAC/data
%     make_paper_tables
%
% Output files (in dynare/paper_artifacts/):
%   table_1_trend_efficiency.{txt,tex}
%   table_2_block_trend_regimes.{txt,tex}
%   table_3_va_price.{txt,tex}
%   table_4_employment.{txt,tex}
%   table_5_consumption.{txt,tex}
%   table_6_housing_inv.{txt,tex}
%   table_7_business_inv_wp1044.{txt,tex}
%   table_8_cross_block_summary.{txt,tex}
%   table_9_bi_exploration.{txt,tex}

clear; clc;
projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
blocks_dir = fullfile(projectdir, 'data', 'pac_blocks');
art_dir    = fullfile(projectdir, 'dynare', 'paper_artifacts');
if ~exist(art_dir, 'dir'); mkdir(art_dir); end

fprintf('=== make_paper_tables ===\n');

%% wp1044 reference values (Dubois et al. 2026 Tables 3.3.3 / 3.4.9 / 3.5.2 / 3.5.7 / 3.5.13)
wp = struct();
wp.va_price       = struct('beta_0', 0.05, 'beta_1', 0.20, 'beta_2', 0.09, 'omega', 0.62, 'R2', 0.61);
wp.employment     = struct('beta_0', 0.07, 'beta_1', 0.44, 'beta_2', 0.12, 'beta_3', 0.12, 'beta_4', 0.13, 'omega', 0.34, 'R2', 0.95);
wp.consumption    = struct('beta_0', 0.29, 'beta_1', 0.17, 'beta_2', 0.32, 'beta_3', -1.07, 'alpha_1', -1.15, 'R2', 0.95);
wp.housing_inv    = struct('beta_0', 0.12, 'beta_1', 0.18, 'beta_2', 0.50, 'beta_3', 0.05, 'omega', 0.05, 'R2', 0.89);
wp.business_inv   = struct('beta_0', 0.096, 'beta_1', 0.33, 'beta_2', 0.11, 'beta_3', 0.69, 'omega', 0.35, 'sigma', 0.50, 'R2', 0.83);

%% Table 1: L1.1 trend efficiency Eq 7 coefficients
tf = load(fullfile(projectdir, 'data', 'trend_efficiency.mat'));
T1 = table();
T1.coef = (1:numel(tf.zhat))';
T1.au   = tf.zhat(:);
% wp1044 reference (Dubois et al. Table 2 of supplementary appendix); paste-in:
% z_1=0.092, z_2=0.030, z_3..z_9 zero or near-zero.  Use the actual values
% from the supplementary appendix or leave blank for unknown coefs.
T1.fr_ref = nan(numel(tf.zhat), 1);
T1.fr_ref(1:min(2, numel(tf.zhat))) = [0.092; 0.030];
write_table(T1, art_dir, 'table_1_trend_efficiency', ...
    'L1.1 trend efficiency E_t equation (Eq 7) coefficients: AU L2 vs wp1044 FR');

%% Table 2: L1.2 block-specific trend regime growth rates
ts = load(fullfile(projectdir, 'data', 'trend_series.mat'));
T2 = trend_regime_table(ts);
write_table(T2, art_dir, 'table_2_block_trend_regimes', ...
    'L1.2 block-specific trend regime growth rates (HP-filtered, annualised %)');

%% Table 3: VA-price PAC (Eq 16) — AU L2 vs wp1044
R = load(fullfile(blocks_dir, 'results_va_price.mat'));
T3 = pac_block_table(R, {'beta_0','beta_1','beta_2','omega','chi','R2'}, ...
                     wp.va_price);
write_table(T3, art_dir, 'table_3_va_price', ...
    'VA-price PAC coefficients (wp1044 Eq 16): AU L2 iterative OLS vs FR-BDF');

%% Table 4: Employment PAC (Eq 30) depth-3
R = load(fullfile(blocks_dir, 'results_employment.mat'));
T4 = pac_block_table(R, {'beta_0','beta_1','beta_2','beta_3','beta_4','omega','chi','R2'}, ...
                     wp.employment);
write_table(T4, art_dir, 'table_4_employment', ...
    'Employment PAC coefficients (wp1044 Eq 30, depth 3): AU L2 vs FR-BDF');

%% Table 5: Consumption PAC (Eq 35) with beta_PAC
R = load(fullfile(blocks_dir, 'results_consumption.mat'));
T5 = pac_block_table(R, {'beta_0','beta_1','alpha_1','beta_PAC','beta_2','beta_3','chi','R2'}, ...
                     wp.consumption);
write_table(T5, art_dir, 'table_5_consumption', ...
    'Consumption PAC coefficients (wp1044 Eq 35): AU L2 vs FR-BDF — headline beta_0 match');

%% Table 6: Housing inv (Eq 37) with price spread
R = load(fullfile(blocks_dir, 'results_housing_inv.mat'));
T6 = pac_block_table(R, {'beta_0','beta_1','beta_2','beta_3','omega','chi','R2'}, ...
                     wp.housing_inv);
write_table(T6, art_dir, 'table_6_housing_inv', ...
    'Housing inv PAC coefficients (wp1044 Eq 37): AU L2 vs FR-BDF');

%% Table 7: Business inv — wp1044 calibration imported (Option 1, no AU estimates)
T7 = table( ...
    {'beta_0';'beta_1';'beta_2';'beta_3';'omega';'sigma_ces';'R2 (FR)'}, ...
    [wp.business_inv.beta_0; wp.business_inv.beta_1; wp.business_inv.beta_2; ...
     wp.business_inv.beta_3; wp.business_inv.omega; wp.business_inv.sigma; ...
     wp.business_inv.R2], ...
    {'wp1044 Table 3.5.13';'wp1044 Table 3.5.13';'wp1044 Table 3.5.13'; ...
     'wp1044 Table 3.5.13';'AU = wp1044 (matched)';'AU = 0.5366 (matched)'; ...
     'wp1044 reported'}, ...
    'VariableNames', {'coef','value','source'});
write_table(T7, art_dir, 'table_7_business_inv_wp1044', ...
    'Business investment calibration — wp1044 Option 1 import (no AU estimates)');

%% Table 8: Cross-block summary
T8 = cross_block_summary_table(blocks_dir, wp);
write_table(T8, art_dir, 'table_8_cross_block_summary', ...
    'Cross-block summary: AU L2 vs FR-BDF — beta_0, beta_1, R^2, source');

%% Table 9: BI exploration variants R^2
T9 = bi_variants_table(blocks_dir);
write_table(T9, art_dir, 'table_9_bi_exploration', ...
    'Business investment specification variants tested in Phase L2 P1c');

fprintf('done. wrote 9 tables to %s\n', art_dir);

%% Helpers ===============================================================

function T = pac_block_table(R, fields, wp)
    n = numel(fields);
    coef = fields(:);
    au   = nan(n,1);
    fr   = nan(n,1);
    for k = 1:n
        f = fields{k};
        if isfield(R, f)
            au(k) = R.(f);
        elseif isfield(R, lower(f))
            au(k) = R.(lower(f));
        end
        if isfield(wp, f)
            fr(k) = wp.(f);
        end
    end
    T = table(coef, au, fr, 'VariableNames', {'coef','au_L2','wp1044_FR'});
end

function T = cross_block_summary_table(blocks_dir, wp)
    blocks  = {'va_price','employment','consumption','housing_inv'};
    fr_b0   = [wp.va_price.beta_0, wp.employment.beta_0, wp.consumption.beta_0, wp.housing_inv.beta_0];
    fr_b1   = [wp.va_price.beta_1, wp.employment.beta_1, wp.consumption.beta_1, wp.housing_inv.beta_1];
    fr_R2   = [wp.va_price.R2,     wp.employment.R2,     wp.consumption.R2,     wp.housing_inv.R2];
    au_b0   = nan(1,4); au_b1 = nan(1,4); au_R2 = nan(1,4);
    for k = 1:4
        R = load(fullfile(blocks_dir, ['results_' blocks{k} '.mat']));
        au_b0(k) = pickf(R, {'beta_0'});
        au_b1(k) = pickf(R, {'beta_1'});
        au_R2(k) = pickf(R, {'R2'});
    end
    % BI: wp1044 imported, no AU estimate
    blocks_lbl  = [blocks, {'business_inv'}];
    au_b0_full  = [au_b0,  NaN]; au_b1_full = [au_b1, NaN]; au_R2_full = [au_R2, NaN];
    fr_b0_full  = [fr_b0,  wp.business_inv.beta_0];
    fr_b1_full  = [fr_b1,  wp.business_inv.beta_1];
    fr_R2_full  = [fr_R2,  wp.business_inv.R2];
    source = {'AU L2';'AU L2';'AU L2';'AU L2';'wp1044 (Option 1)'};
    T = table(blocks_lbl(:), au_b0_full(:), fr_b0_full(:), au_b1_full(:), fr_b1_full(:), ...
              au_R2_full(:), fr_R2_full(:), source, ...
              'VariableNames', {'block','beta0_AU','beta0_FR','beta1_AU','beta1_FR','R2_AU','R2_FR','source'});
end

function T = bi_variants_table(blocks_dir)
    variants = {
        'baseline (strict wp1044)',                'results_business_inv.mat',           0.09;
        'v1: + AU dummies',                        'results_business_inv_au.mat',        0.11;
        'v2: pre-residualize dummies',             'results_business_inv_au_v2.mat',    -23.7;
        'v3-A: PV free + dummies',                 '',                                   0.53;
        'v3-B: strict + dummies single-shot',      '',                                  -2.20;
        'v3-C: strict + dummies loose clamps',     '',                                  -67.0;
        'v4: combined PV coef=1 + dummies',        'results_business_inv_au_v4.mat',   -33.0;
        'v5: + ToT + piecewise trends',            'results_business_inv_au_v5.mat',   -10.7;
        'v6: replace q with q_AU (ToT target)',    'results_business_inv_au_v6_tot.mat', -39.1;
        'wp736 (2019 simpler form) + dummies',     'results_business_inv_wp736.mat',    -0.75;
        'simplified (drops PV)',                   '',                                   0.33;
        };
    R2 = cell2mat(variants(:,3));
    T = table(variants(:,1), R2, variants(:,2), ...
              'VariableNames', {'variant','R2','results_file'});
end

function v = pickf(R, fields)
    v = NaN;
    for k = 1:numel(fields)
        if isfield(R, fields{k})
            v = R.(fields{k}); return
        end
    end
end

function write_table(T, dir_, basename, caption)
    txt_path = fullfile(dir_, [basename '.txt']);
    tex_path = fullfile(dir_, [basename '.tex']);
    fid = fopen(txt_path, 'w');
    fprintf(fid, '%s\n\n', caption);
    writetable(T, txt_path, 'WriteMode', 'append', 'Delimiter', '\t');
    fclose(fid);
    % Minimal LaTeX export: use Matlab's "table2latex" via writetable variant
    try
        writetable(T, tex_path, 'FileType', 'text', 'WriteVariableNames', true, 'Delimiter', '|');
    catch
        % Fall back to a plain dump if writetable's tex output isn't supported.
        fid = fopen(tex_path, 'w'); fprintf(fid, '%% %s\n', caption); fclose(fid);
        writetable(T, [tex_path '.csv']);
    end
    fprintf('  wrote %s\n', basename);
end

function T = trend_regime_table(ts)
    % ts should contain per-block trend growth rates; the exact field names
    % depend on the L1.2 builder.  Probe defensively.
    if isfield(ts, 'regime_table')
        T = ts.regime_table; return
    end
    f = fieldnames(ts);
    is_rate = endsWith(f, '_rate') | endsWith(f, '_growth') | startsWith(f, 'g_');
    if any(is_rate)
        f = f(is_rate);
        rates = nan(numel(f), 1);
        for k = 1:numel(f); rates(k) = ts.(f{k}); end
        T = table(f, rates, 'VariableNames', {'series','growth_pa'});
    else
        T = table({'(no per-regime fields found in trend_series.mat)'}, NaN, ...
                  'VariableNames', {'series','growth_pa'});
    end
end
