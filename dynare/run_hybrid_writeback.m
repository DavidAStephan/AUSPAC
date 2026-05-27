% run_hybrid_writeback.m — run stoch_simul with hybrid posterior writeback
% and extract key IRF peaks for the 100bp monetary tightening.
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod;

irfs = oo_.irfs;
save('saved_irfs_hybrid_writeback.mat', 'irfs');

% Scale to 100bp annualised = 0.25 qpp
idx_eps_i = find(strcmp(M_.exo_names, 'eps_i'));
stderr_i = sqrt(M_.Sigma_e(idx_eps_i, idx_eps_i));
scale = 0.25 / stderr_i;

vars = {'ln_Q','yhat_au','pi_au','dln_c','dln_ib','dln_ih','dln_n','s_gap','i_10y','piQ','pi_w','pi_c'};
fprintf('\n=== 100bp monetary tightening IRF peaks (hybrid MCMC writeback) ===\n');
fprintf('Scale factor: 0.25 / %.4f = %.2f\n\n', stderr_i, scale);
for k = 1:length(vars)
    fn = [vars{k} '_eps_i'];
    if isfield(irfs, fn)
        x = irfs.(fn) * scale;
        [mn, qi_mn] = min(x(1:min(40,length(x))));
        [mx, qi_mx] = max(x(1:min(40,length(x))));
        if abs(mn) > abs(mx)
            fprintf('  %-15s  trough = %+.4f%%  at Q%d\n', vars{k}, mn, qi_mn);
        else
            fprintf('  %-15s  peak   = %+.4f%%  at Q%d\n', vars{k}, mx, qi_mx);
        end
    else
        fprintf('  %-15s  (not in oo_.irfs)\n', vars{k});
    end
end
fprintf('\ndone.\n');
