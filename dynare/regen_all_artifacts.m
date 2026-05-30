% regen_all_artifacts.m — §6.12 regeneration driver (b1_x=b1_m_ne=0.65)
% Runs dynare once, writes .mat + peaks + all IRF chart PNGs, then verifies
% turning points (oscillation check).
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod;

irfs = oo_.irfs;
save('saved_irfs_hybrid_writeback.mat', 'irfs');

% ---- peaks ----
fid = fopen('paper_irf_peaks.txt', 'w');
pk_shocks = {'eps_i','eps_q_us','eps_pcom','eps_pQ','eps_g','eps_tp'};
pk_lbl = {'100bp monetary','1pp foreign demand','10pct commodity','1pp cost-push','1pp govt','100bp term premium'};
pk_targets = [0.25, 1.0, 10.0, 1.0, 1.0, 0.25];
pk_vars = {'ln_Q','yhat_au','pi_au','dln_c','dln_ib','dln_ih','dln_n','s_gap','i_10y','piQ','pi_w','pi_c'};
for s = 1:length(pk_shocks)
    idx = find(strcmp(M_.exo_names, pk_shocks{s}));
    stderr = sqrt(M_.Sigma_e(idx,idx)); scale = pk_targets(s)/stderr;
    fprintf(fid, '\n=== %s (scale=%.2f) ===\n', pk_lbl{s}, scale);
    for k = 1:length(pk_vars)
        fn = [pk_vars{k} '_' pk_shocks{s}];
        if isfield(irfs, fn)
            x = irfs.(fn)*scale;
            [mn, qi] = min(x(1:min(40,length(x)))); [mx, qm] = max(x(1:min(40,length(x))));
            if abs(mn) > abs(mx), fprintf(fid, '  %-12s  %+.4f%%  Q%d\n', pk_vars{k}, mn, qi);
            else, fprintf(fid, '  %-12s  %+.4f%%  Q%d\n', pk_vars{k}, mx, qm); end
        end
    end
end
fclose(fid); fprintf('Wrote paper_irf_peaks.txt\n');

% ---- charts ----
art_dir = 'paper_artifacts';
shocks = {'eps_i','100bp monetary tightening',0.25;'eps_q_us','1pp foreign demand',1.0; ...
    'eps_pcom','10% commodity price',10.0;'eps_pQ','1pp cost-push',1.0; ...
    'eps_g','1pp govt spending',1.0;'eps_tp','100bp term premium',0.25};
panel_vars = {'ln_Q','yhat_au','pi_au','dln_c','dln_ib','dln_ih','s_gap','i_10y','piQ','pi_w','pi_c','dln_n'};
panel_lbl  = {'ln Q (real GDP)','Output gap','CPI inflation','\Delta ln C','\Delta ln I_B','\Delta ln I_H','s gap (AUD)','10Y yield','\pi_Q (VA price)','\pi_w (wages)','\pi_c (CPI deflator)','\Delta ln N'};
for s = 1:size(shocks,1)
    shock=shocks{s,1}; lbl=shocks{s,2}; target=shocks{s,3};
    idx=find(strcmp(M_.exo_names,shock)); scale=target/sqrt(M_.Sigma_e(idx,idx));
    fh=figure('visible','off','Position',[100 100 1200 700]);
    for v=1:min(12,length(panel_vars))
        subplot(3,4,v); fn=[panel_vars{v} '_' shock];
        if isfield(irfs,fn)
            x=irfs.(fn)(1:min(40,length(irfs.(fn))))*scale;
            plot(0:length(x)-1,x,'b-','LineWidth',1.3); hold on; yline(0,'k:');
            grid on; title(panel_lbl{v},'FontSize',9); xlabel('Q'); ylabel('%');
        end
    end
    sgtitle(sprintf('AU-PAC IRFs — %s (Phase L2 OLS audit)',lbl),'FontSize',11);
    saveas(fh,fullfile(art_dir,sprintf('irf_%s_v3.png',shock))); close(fh);
    fprintf('  wrote irf_%s_v3.png\n',shock);
end
fh=figure('visible','off','Position',[100 100 900 400]); colors=lines(6);
for s=1:size(shocks,1)
    shock=shocks{s,1}; target=shocks{s,3};
    idx=find(strcmp(M_.exo_names,shock)); scale=target/sqrt(M_.Sigma_e(idx,idx));
    fn=['yhat_au_' shock];
    if isfield(irfs,fn), x=irfs.(fn)(1:min(40,length(irfs.(fn))))*scale;
        plot(0:length(x)-1,x,'LineWidth',1.3,'Color',colors(s,:)); hold on; end
end
yline(0,'k:'); grid on; legend(shocks(:,2),'Location','best','FontSize',8);
title('Output gap responses to all shocks (policy-relevant sizes)','FontSize',11);
xlabel('Quarters'); ylabel('% deviation');
saveas(fh,fullfile(art_dir,'irf_overview_output_v3.png')); close(fh);
fprintf('  wrote irf_overview_output_v3.png\n');

% ---- verify: turning points + BK ----
fprintf('\n=== VERIFY (100bp monetary, b1 SA-fix) BK sdim/edim from Dynare above ===\n');
ei=find(strcmp(M_.exo_names,'eps_i')); sc=0.25/sqrt(M_.Sigma_e(ei,ei));
for v={'ln_Q','yhat_au','dln_ib','dln_ih','dln_c','dln_n'}
    fn=[v{1} '_eps_i'];
    if isfield(irfs,fn)
        x=irfs.(fn)(1:40)*sc; d=diff(x); s=sign(d); s=s(s~=0); tp=sum(s(2:end)~=s(1:end-1));
        [tr,qi]=min(x);
        fprintf('  %-9s turns=%d  trough=%+.4f@Q%d  Q40=%+.4f\n', v{1}, tp, tr, qi, x(40));
    end
end
fprintf('done.\n');
