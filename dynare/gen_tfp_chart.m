addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod;
irfs = oo_.irfs;
panel_vars = {'ln_Q','yhat_au','pi_au','dln_c','dln_ib','dln_ih','s_gap','i_10y','piQ','pi_w','pi_c','dln_n'};
panel_lbl = {'ln Q','Output gap','CPI inflation','dln C','dln I_B','dln I_H','s gap','10Y yield','piQ','pi_w','pi_c','dln N'};
shock = 'eps_tfp_LR';
idx = find(strcmp(M_.exo_names, shock));
stderr = sqrt(M_.Sigma_e(idx,idx));
scale = 1.0 / stderr;
fh = figure('visible','off','Position',[100 100 1200 700]);
for v = 1:12
    subplot(3,4,v);
    fn = [panel_vars{v} '_' shock];
    if isfield(irfs, fn)
        x = irfs.(fn)(1:min(40,length(irfs.(fn)))) * scale;
        plot(0:length(x)-1, x, 'b-', 'LineWidth', 1.3); hold on;
        yline(0,'k:'); grid on; title(panel_lbl{v},'FontSize',9);
    end
end
sgtitle('AU-PAC IRFs -- 1 sd TFP shock (v3: hybrid + ULC/UCK + energy split)');
saveas(fh, 'paper_artifacts/irf_eps_tfp_v3.png');
close(fh);
fprintf('wrote irf_eps_tfp_v3.png\n');
