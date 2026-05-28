% gen_paper_irf_charts.m — regenerate IRF chart PNGs from the latest
% hybrid-writeback stoch_simul output, for the working paper.
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod;

irfs = oo_.irfs;
art_dir = 'paper_artifacts';

% Shock definitions: {shock_name, label, target_size, stderr_field}
shocks = {
    'eps_i',     '100bp monetary tightening',  0.25;
    'eps_q_us',  '1pp foreign demand',         1.0;
    'eps_pcom',  '10% commodity price',        10.0;
    'eps_pQ',    '1pp cost-push',              1.0;
    'eps_g',     '1pp govt spending',           1.0;
    'eps_tp',    '100bp term premium',          0.25;
};

panel_vars = {'ln_Q','yhat_au','pi_au','dln_c','dln_ib','dln_ih','s_gap','i_10y','piQ','pi_w','pi_c','dln_n'};
panel_lbl  = {'ln Q (real GDP)','Output gap','CPI inflation','\Delta ln C','\Delta ln I_B','\Delta ln I_H','s gap (AUD)','10Y yield','\pi_Q (VA price)','\pi_w (wages)','\pi_c (CPI deflator)','\Delta ln N'};

for s = 1:size(shocks, 1)
    shock = shocks{s, 1};
    lbl = shocks{s, 2};
    target = shocks{s, 3};
    idx = find(strcmp(M_.exo_names, shock));
    stderr = sqrt(M_.Sigma_e(idx, idx));
    scale = target / stderr;

    fh = figure('visible', 'off', 'Position', [100 100 1200 700]);
    np = min(12, length(panel_vars));
    for v = 1:np
        subplot(3, 4, v);
        fn = [panel_vars{v} '_' shock];
        if isfield(irfs, fn)
            x = irfs.(fn)(1:min(40, length(irfs.(fn)))) * scale;
            plot(0:length(x)-1, x, 'b-', 'LineWidth', 1.3); hold on;
            yline(0, 'k:');
            grid on; title(panel_lbl{v}, 'FontSize', 9);
            xlabel('Q'); ylabel('%');
        end
    end
    sgtitle(sprintf('AU-PAC IRFs — %s (Phase L2 OLS audit)', lbl), 'FontSize', 11);
    saveas(fh, fullfile(art_dir, sprintf('irf_%s_v3.png', shock)));
    close(fh);
    fprintf('  wrote irf_%s_v3.png\n', shock);
end

% Also write the output-gap overview (all shocks on one panel)
fh = figure('visible', 'off', 'Position', [100 100 900 400]);
colors = lines(6);
for s = 1:size(shocks, 1)
    shock = shocks{s, 1};
    target = shocks{s, 3};
    idx = find(strcmp(M_.exo_names, shock));
    stderr = sqrt(M_.Sigma_e(idx, idx));
    scale = target / stderr;
    fn = ['yhat_au_' shock];
    if isfield(irfs, fn)
        x = irfs.(fn)(1:min(40, length(irfs.(fn)))) * scale;
        plot(0:length(x)-1, x, 'LineWidth', 1.3, 'Color', colors(s,:)); hold on;
    end
end
yline(0, 'k:'); grid on;
legend(shocks(:,2), 'Location', 'best', 'FontSize', 8);
title('Output gap responses to all shocks (policy-relevant sizes)', 'FontSize', 11);
xlabel('Quarters'); ylabel('% deviation');
saveas(fh, fullfile(art_dir, 'irf_overview_output_v3.png'));
close(fh);
fprintf('  wrote irf_overview_output_v3.png\n');
fprintf('done.\n');
