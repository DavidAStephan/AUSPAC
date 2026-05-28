% gen_paper_irfs.m — generate all IRF peaks for the paper, save to file
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod;
irfs = oo_.irfs;
save('saved_irfs_hybrid_writeback.mat', 'irfs');

fid = fopen('paper_irf_peaks.txt', 'w');
shocks = {'eps_i','eps_q_us','eps_pcom','eps_pQ','eps_g','eps_tp'};
shock_lbl = {'100bp monetary','1pp foreign demand','10pct commodity','1pp cost-push','1pp govt','100bp term premium'};
targets = [0.25, 1.0, 10.0, 1.0, 1.0, 0.25];
vars = {'ln_Q','yhat_au','pi_au','dln_c','dln_ib','dln_ih','dln_n','s_gap','i_10y','piQ','pi_w','pi_c'};

for s = 1:length(shocks)
    idx = find(strcmp(M_.exo_names, shocks{s}));
    stderr = sqrt(M_.Sigma_e(idx,idx));
    scale = targets(s) / stderr;
    fprintf(fid, '\n=== %s (scale=%.2f) ===\n', shock_lbl{s}, scale);
    for k = 1:length(vars)
        fn = [vars{k} '_' shocks{s}];
        if isfield(irfs, fn)
            x = irfs.(fn) * scale;
            [mn, qi] = min(x(1:min(40,length(x))));
            [mx, qm] = max(x(1:min(40,length(x))));
            if abs(mn) > abs(mx)
                fprintf(fid, '  %-12s  %+.4f%%  Q%d\n', vars{k}, mn, qi);
            else
                fprintf(fid, '  %-12s  %+.4f%%  Q%d\n', vars{k}, mx, qm);
            end
        end
    end
end
fclose(fid);
fprintf('Wrote paper_irf_peaks.txt\n');
