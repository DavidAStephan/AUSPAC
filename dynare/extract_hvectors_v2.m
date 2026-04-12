%% extract_hvectors_v2.m
% Extract PAC h-vector values from M_.pac.*.h_param_indices -> M_.params
% Dynare 6.5 stores h-vectors as parameter values, not in oo_.pac.

cd('c:\Users\david\french_model\dynare');
addpath('C:\dynare\6.5\matlab');

if ~exist('M_', 'var')
    dynare au_pac noclearall nograph;
end

fid = fopen('log_hvector_tables_v2.txt', 'w');
fprintf(fid, '=== PAC h-VECTOR TABLES (from M_.pac -> M_.params) ===\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

pac_names  = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
pac_labels = {'VA Price (piQ)', 'Consumption (dln_c)', 'Business Inv. (dln_ib)', ...
              'Household Inv. (dln_ih)', 'Employment (dln_n)'};

% Summary table
fprintf(fid, '### Summary: h-vector parameter values\n\n');
fprintf(fid, '| PAC equation | h-param indices | h-values | Sum | GN param idx | GN value |\n');
fprintf(fid, '|---|---|---|---|---|---|\n');

for p = 1:length(pac_names)
    pname = pac_names{p};
    if isfield(M_.pac, pname)
        info = M_.pac.(pname);
        h_idx = info.h_param_indices;
        h_vals = M_.params(h_idx);
        gn_idx = info.growth_neutrality_param_index;
        gn_val = M_.params(gn_idx);

        h_str = sprintf('%.6f ', h_vals);
        idx_str = sprintf('%d ', h_idx);
        fprintf(fid, '| %s | [%s] | [%s] | %.6f | %d | %.6f |\n', ...
            pac_labels{p}, strtrim(idx_str), strtrim(h_str), sum(h_vals), gn_idx, gn_val);
    end
end

% Detailed per-equation
for p = 1:length(pac_names)
    pname = pac_names{p};
    fprintf(fid, '\n### %s — detailed h-vector\n\n', pac_labels{p});

    if ~isfield(M_.pac, pname)
        fprintf(fid, 'NOT FOUND\n');
        continue;
    end

    info = M_.pac.(pname);
    h_idx = info.h_param_indices;
    h_vals = M_.params(h_idx);

    fprintf(fid, 'Equation: %s\n', info.eq_name);
    fprintf(fid, 'Auxiliary model: %s\n', info.auxiliary_model_name);
    fprintf(fid, 'Growth variable: %s\n', info.growth_str);
    fprintf(fid, 'Max lag (PAC order m): %d\n', info.max_lag);
    fprintf(fid, 'Discount parameter index: %d (value: %.6f)\n', info.discount_index, M_.params(info.discount_index));
    fprintf(fid, '\n');

    fprintf(fid, '| Index | Parameter name | h-value |\n');
    fprintf(fid, '|-------|---------------|--------|\n');
    for j = 1:length(h_idx)
        param_name = deblank(M_.param_names(h_idx(j), :));
        fprintf(fid, '| %d | %s | %.6f |\n', h_idx(j), param_name, h_vals(j));
    end
    fprintf(fid, '| — | **Sum** | **%.6f** |\n', sum(h_vals));

    % Growth neutrality
    gn_idx = info.growth_neutrality_param_index;
    gn_name = deblank(M_.param_names(gn_idx, :));
    fprintf(fid, '\nGrowth neutrality parameter: %s = %.6f (index %d)\n', gn_name, M_.params(gn_idx), gn_idx);

    % EC and AR info
    if isfield(info, 'ec') && isstruct(info.ec)
        ec = info.ec;
        if isfield(ec, 'params')
            fprintf(fid, 'EC speed parameter index: %d (value: %.6f)\n', ec.params, M_.params(ec.params));
        end
    end
    if isfield(info, 'ar') && isstruct(info.ar)
        ar = info.ar;
        if isfield(ar, 'params')
            for j = 1:length(ar.params)
                fprintf(fid, 'AR(%d) parameter index: %d (value: %.6f)\n', j, ar.params(j), M_.params(ar.params(j)));
            end
        end
    end

    fprintf(fid, '\n');
end

fclose(fid);
fprintf('Saved: log_hvector_tables_v2.txt\n');
