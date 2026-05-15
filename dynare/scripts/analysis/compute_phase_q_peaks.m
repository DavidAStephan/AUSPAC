%% compute_phase_q_peaks.m — extract IRF peaks for three-regime comparison
% Reads saved_irfs_{var,hybrid,mce}.mat and prints peak values scaled to
% 100bp annualized monetary tightening (0.25 qpp / 0.111 stderr ≈ 2.252 scale).

cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/

% Posterior mean of stderr_eps_i (from MCMC log)
stderr_i = 0.1110;
scale = 0.25 / stderr_i;
fprintf('Scale: 0.25 / %.4f = %.4f\n\n', stderr_i, scale);

regimes = struct( ...
    'var',    'saved_irfs_var.mat',    ...
    'hybrid', 'saved_irfs_hybrid.mat', ...
    'mce',    'saved_irfs_mce.mat');

vars_of_interest = {
    'ln_Q',     'Real GDP (% from SS)';
    'yhat_au',  'Output gap (%)';
    'piQ',      'VA price inflation (qpp)';
    'pi_au',    'CPI inflation (qpp)';
    'dln_c',    'Consumption growth (qpp)';
    'dln_ib',   'Business inv growth (qpp)';
    'dln_ih',   'Housing inv growth (qpp)';
    'dln_n',    'Employment growth (qpp)';
    'pi_w',     'Wage inflation (qpp)';
    's_gap',    'Exchange rate (- = AUD appreciation)';
    'i_10y',    '10Y yield (qpp)';
    'pv_i_uip', 'UIP NPV (forward-looking PV of i_gap)';
    };

regnames = fieldnames(regimes);
results = cell(size(vars_of_interest, 1), 1 + 2*numel(regnames));
results{1, 1} = 'Variable';
for r = 1:numel(regnames)
    fname = regimes.(regnames{r});
    fprintf('=== Regime: %s (%s) ===\n', regnames{r}, fname);
    d = load(fname);
    fnms = fieldnames(d);
    irfs = d.(fnms{1});

    for k = 1:size(vars_of_interest, 1)
        vname = vars_of_interest{k, 1};
        field = [vname '_eps_i'];
        if isfield(irfs, field)
            y = double(getfield(irfs, field)) * scale; %#ok<GFLD>
            [pk, qpk] = max(abs(y));
            signed_pk = sign(y(qpk)) * pk;
            fprintf('  %-12s peak %+10.4f at Q%-2d\n', vname, signed_pk, qpk);
            results{k, 2*r} = signed_pk;
            results{k, 2*r+1} = qpk;
        else
            fprintf('  %-12s MISSING (%s)\n', vname, field);
        end
    end
    fprintf('\n');
end

% Print compact summary table
fprintf('\n=== SUMMARY (peak | Q-of-peak, 100bp annualized) ===\n');
fprintf('%-26s %18s %18s %18s\n', '', '   VAR ', '  Hybrid ', '   MCE  ');
fprintf('%s\n', repmat('-', 1, 80));
for k = 1:size(vars_of_interest, 1)
    vname = vars_of_interest{k, 1};
    label = vars_of_interest{k, 2};
    fprintf('%-26s %+8.4f Q%-3d  %+8.4f Q%-3d  %+8.4f Q%-3d\n', ...
        label, ...
        results{k, 2}, results{k, 3}, ...
        results{k, 4}, results{k, 5}, ...
        results{k, 6}, results{k, 7});
end
