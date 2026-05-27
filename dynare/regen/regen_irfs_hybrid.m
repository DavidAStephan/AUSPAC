%% regen_irfs_hybrid.m -- regenerate IRFs from the hybrid-calibrated au_pac.mod
%
% Run from MATLAB GUI (R2020a -batch is blocked on Apple Silicon; see
% WORKING_PAPER_BLOCKERS.md).  Requires Dynare 6.5 already added to path.
%
%     cd ~/Documents/AUSPAC/dynare
%     addpath('/Applications/Dynare/6.5-x86_64/matlab');   % adjust if needed
%     regen/regen_irfs_hybrid
%
% Inputs : au_pac.mod (already locked at Phase L2 P1c hybrid calibration —
%          BI block at wp1044 Table 3.5.13, other 4 blocks at AU L2 estimates)
% Outputs: dynare/paper_artifacts/irf_<shock>_hybrid.png for the 6 shocks
%          listed in NEXT_SESSION.md Phase WP-B3.

clear; clc;
projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
art_dir    = fullfile(projectdir, 'dynare', 'paper_artifacts');
if ~exist(art_dir, 'dir'); mkdir(art_dir); end

cd(fullfile(projectdir, 'dynare'));
fprintf('=== regen_irfs_hybrid ===\n');
fprintf('Running dynare au_pac (hybrid calibration: BI from wp1044, other 4 blocks AU L2)\n');

dynare au_pac;

% After dynare returns, oo_.irfs contains all stoch_simul IRFs.
% Helper to plot a panel of 5 variables for a given shock.
shocks   = {'eps_i', 'eps_q_us', 'eps_pcom', 'eps_pQ', 'eps_tfp', 'eps_g'};
shock_lbl = {'100bp monetary tightening', '1pp foreign demand', ...
             '10% commodity price', '1pp cost-push', '1 sd TFP', '1pp govt'};
panel_vars = {'ln_Q', 'pi_au', 'dln_ib', 'dln_c', 'dln_ih', 's_gap'};
panel_lbl  = {'ln Q (real GDP)','CPI inflation', '\Delta ln I_B', ...
              '\Delta ln C', '\Delta ln I_H', 's gap (AUD)'};

for k = 1:numel(shocks)
    fh = figure('visible','off','Position',[100 100 1100 540]);
    for v = 1:numel(panel_vars)
        subplot(2, 3, v);
        var_name = panel_vars{v};
        fn = [var_name '_' shocks{k}];
        if isfield(oo_.irfs, fn)
            plot(oo_.irfs.(fn), 'b-', 'LineWidth', 1.2); hold on;
            yline(0, 'k:'); grid on;
            title(panel_lbl{v});
            xlabel('quarters'); ylabel('% / pp');
        else
            text(0.5,0.5,sprintf('no IRF: %s', fn), 'HorizontalAlignment','center');
        end
    end
    sgtitle(sprintf('AU-PAC hybrid-calibration IRFs — %s', shock_lbl{k}));
    saveas(fh, fullfile(art_dir, sprintf('irf_%s_hybrid.png', shocks{k})));
    close(fh);
end

fprintf('done. wrote %d IRF panels to %s\n', numel(shocks), art_dir);
