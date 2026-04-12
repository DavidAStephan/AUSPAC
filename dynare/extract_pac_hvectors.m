%% extract_pac_hvectors.m
% Extract h-vector weights from Dynare PAC internals for AU-PAC documentation.
% Produces markdown-formatted tables showing how each TCM state variable
% maps to its expectation weight in each PAC equation.
%
% Must be run AFTER `dynare au_pac noclearall nograph`
% (or the oo_ struct must be in the workspace).
%
% Output: printed to console as markdown tables for pasting into docs.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

%% Run model if not already loaded
if ~exist('oo_', 'var') || ~exist('M_', 'var')
    fprintf('Running au_pac.mod to populate oo_ and M_...\n');
    dynare au_pac noclearall nograph;
end

%% PAC configuration
pac_names  = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
pac_labels = {'VA Price (piQ)', 'Consumption (dln_c)', ...
              'Business Investment (dln_ib)', 'Household Investment (dln_ih)', ...
              'Employment (dln_n)'};
tcm_names  = {'esat_tcm', 'c_tcm', 'ib_tcm', 'ih_tcm', 'n_tcm'};
pac_orders = [1, 1, 2, 2, 4];  % PAC polynomial order m

fprintf('\n\n=== PAC h-VECTOR EXTRACTION FOR DOCUMENTATION ===\n');
fprintf('(Appendix D: h-Vector Decomposition Tables)\n\n');

%% Summary table
fprintf('### Summary: h-vector sums vs manual omega\n\n');
fprintf('| PAC equation | Order m | h_0 sum (stationary) | h_1 sum (nonstationary) | Total omega |\n');
fprintf('|---|---|---|---|---|\n');

for p = 1:length(pac_names)
    pname = pac_names{p};

    if isfield(oo_.pac, pname)
        pac_info = oo_.pac.(pname);

        h0_sum = 0; h1_sum = 0;
        if isfield(pac_info, 'h_v_0')
            h0_sum = sum(pac_info.h_v_0);
        end
        if isfield(pac_info, 'h_v_1')
            h1_sum = sum(pac_info.h_v_1);
        end

        fprintf('| %s | %d | %.4f | %.4f | %.4f |\n', ...
            pac_labels{p}, pac_orders(p), h0_sum, h1_sum, h0_sum + h1_sum);
    else
        fprintf('| %s | %d | NOT FOUND | — | — |\n', pac_labels{p}, pac_orders(p));
    end
end

%% Detailed h-vector tables per PAC equation
for p = 1:length(pac_names)
    pname = pac_names{p};
    fprintf('\n\n### %s — h-vector decomposition\n\n', pac_labels{p});

    if ~isfield(oo_.pac, pname)
        fprintf('*PAC model `%s` not found in oo_.pac*\n', pname);
        continue;
    end

    pac_info = oo_.pac.(pname);

    % --- h_v_0 (stationary component weights) ---
    if isfield(pac_info, 'h_v_0')
        h0 = pac_info.h_v_0;
        fprintf('**h_v_0 (stationary target change PV):** %d elements\n\n', length(h0));
        fprintf('| Index | Weight | Cumulative |\n');
        fprintf('|-------|--------|------------|\n');
        cum = 0;
        for i = 1:length(h0)
            cum = cum + h0(i);
            if abs(h0(i)) > 1e-6
                fprintf('| %d | %.6f | %.6f |\n', i, h0(i), cum);
            end
        end
        fprintf('| **Sum** | **%.6f** | |\n\n', sum(h0));
    end

    % --- h_v_1 (nonstationary component weights) ---
    if isfield(pac_info, 'h_v_1')
        h1 = pac_info.h_v_1;
        fprintf('**h_v_1 (nonstationary target change PV):** %d elements\n\n', length(h1));
        fprintf('| Index | Weight | Cumulative |\n');
        fprintf('|-------|--------|------------|\n');
        cum = 0;
        for i = 1:length(h1)
            cum = cum + h1(i);
            if abs(h1(i)) > 1e-6
                fprintf('| %d | %.6f | %.6f |\n', i, h1(i), cum);
            end
        end
        fprintf('| **Sum** | **%.6f** | |\n\n', sum(h1));
    end

    % --- Companion matrix info ---
    if isfield(pac_info, 'companion_matrix')
        G = pac_info.companion_matrix;
        eigs_G = eig(G);
        fprintf('**Companion matrix G** (%dx%d), eigenvalue moduli: ', size(G,1), size(G,2));
        fprintf('[%s]\n\n', num2str(sort(abs(eigs_G))', '%.4f '));
        fprintf('Spectral radius: %.4f (must be < 1 for convergence)\n\n', max(abs(eigs_G)));
    end

    % --- Discount factor ---
    if isfield(pac_info, 'discount')
        fprintf('**Discount factor beta:** %.4f\n\n', pac_info.discount);
    end
end

fprintf('\n=== h-vector extraction complete ===\n');
