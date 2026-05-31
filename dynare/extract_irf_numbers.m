% extract_irf_numbers.m — dump every IRF quantity the working paper §7 cites,
% at the paper's policy-relevant target scalings, from the CURRENT model.
% Used to refresh the paper's IRF numbers after the employment-χ / housing /
% consumption-SA writebacks amplified the real-activity responses.

addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod
irfs = oo_.irfs;

scaleof = @(shock,target) target / sqrt(M_.Sigma_e(strcmp(M_.exo_names,shock), strcmp(M_.exo_names,shock)));

function report(irfs, scale, shock, vars)
    for k = 1:numel(vars)
        fn = [vars{k} '_' shock];
        if ~isfield(irfs, fn), fprintf('  %-12s  (not in irfs)\n', vars{k}); continue; end
        x = irfs.(fn) * scale;
        w = x(1:min(40,numel(x)));
        [mn,qi] = min(w); [mx,qm] = max(w);
        if abs(mn) >= abs(mx), pk=mn; q=qi; else, pk=mx; q=qm; end
        fprintf('  %-12s  peak %+8.4f%% @Q%-2d | impact(Q1) %+8.4f | Q40 %+8.4f\n', vars{k}, pk, q, x(1), x(40));
    end
end

fid = fopen('irf_numbers_for_paper.txt','w');
diary('irf_numbers_for_paper.txt');

fprintf('==== Monetary eps_i (100bp = scale %.3f) ====\n', scaleof('eps_i',0.25));
report(irfs, scaleof('eps_i',0.25), 'eps_i', {'ln_Q','yhat_au','dln_c','dln_ib','dln_ih','dln_n','s_gap','i_10y','pi_au','pi_w','pi_c'});
% YoY CPI at Q3 = 4-quarter trailing sum of quarterly pi_au (impact quarter = index 1)
s = scaleof('eps_i',0.25); pia = irfs.pi_au_eps_i * s;
fprintf('  pi_au YoY@Q3 (sum Q0..Q3) = %+.4f ; quarterly pi_au@Q3 = %+.4f\n', sum(pia(1:4)), pia(4));
piw = irfs.pi_w_eps_i * s; fprintf('  pi_w @Q3 (quarterly) = %+.4f\n', piw(4));

fprintf('\n==== Foreign demand eps_q_us (1pp = scale %.3f) ====\n', scaleof('eps_q_us',1.0));
report(irfs, scaleof('eps_q_us',1.0), 'eps_q_us', {'yhat_au','ln_Q','dln_ih','dln_x','dln_ib'});

fprintf('\n==== Govt eps_g (1%% GDP = scale %.3f) ====\n', scaleof('eps_g',1.0));
report(irfs, scaleof('eps_g',1.0), 'eps_g', {'yhat_au','ln_Q','dln_m','dln_c','dln_ib'});

fprintf('\n==== Commodity eps_pcom (10%% = scale %.3f) ====\n', scaleof('eps_pcom',10.0));
report(irfs, scaleof('eps_pcom',10.0), 'eps_pcom', {'yhat_au','dln_ih','dln_x','dln_m','pi_au'});

fprintf('\n==== Cost-push eps_pQ (1pp = scale %.3f) ====\n', scaleof('eps_pQ',1.0));
report(irfs, scaleof('eps_pQ',1.0), 'eps_pQ', {'piQ','pi_au','pi_c','ln_Q','yhat_au','i_au'});
s = scaleof('eps_pQ',1.0);
fprintf('  piQ impact(Q1) = %+.4f ; pi_au impact(Q1) = %+.4f ; ln_Q@Q2 = %+.4f ; ln_Q@Q20 = %+.4f\n', ...
        irfs.piQ_eps_pQ(1)*s, irfs.pi_au_eps_pQ(1)*s, irfs.ln_Q_eps_pQ(2)*s, irfs.ln_Q_eps_pQ(20)*s);

fprintf('\n==== TFP eps_tfp_LR (1 s.d. = scale 1.0) ====\n');
report(irfs, 1.0, 'eps_tfp_LR', {'ln_Q','ln_QN','ln_N','yhat_au','pi_w'});

fprintf('\n==== Term premium eps_tp (100bp = scale %.3f) ====\n', scaleof('eps_tp',0.25));
report(irfs, scaleof('eps_tp',0.25), 'eps_tp', {'ln_C','ln_IB','ln_IH','yhat_au','i_10y'});

diary off;
fclose(fid);
fprintf('\nWrote irf_numbers_for_paper.txt\n');
