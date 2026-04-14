%% extract_bayesian_results.m — Extract and log Bayesian Stage 1 results
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('bayesian_stage1_results.txt', 'w');

% Load the results
if exist('bayesian_estimation_results.mat', 'file')
    r = load('bayesian_estimation_results.mat');
    fprintf(fid, 'Bayesian Stage 1 Results (from bayesian_estimation_results.mat)\n');
    fprintf(fid, '================================================================\n\n');

    % Posterior mode
    if isfield(r.oo_, 'posterior_mode')
        pm = r.oo_.posterior_mode;
        if isfield(pm, 'parameters')
            pfields = fieldnames(pm.parameters);
            fprintf(fid, '%-22s %10s\n', 'Parameter', 'Mode');
            fprintf(fid, '%s\n', repmat('-', 1, 34));
            for k = 1:length(pfields)
                fprintf(fid, '%-22s %10.4f\n', pfields{k}, pm.parameters.(pfields{k}));
            end
        end
        if isfield(pm, 'shocks_std')
            sfields = fieldnames(pm.shocks_std);
            fprintf(fid, '\n%-22s %10s\n', 'Shock std dev', 'Mode');
            fprintf(fid, '%s\n', repmat('-', 1, 34));
            for k = 1:length(sfields)
                fprintf(fid, '%-22s %10.4f\n', sfields{k}, pm.shocks_std.(sfields{k}));
            end
        end
    else
        fprintf(fid, 'No posterior_mode field in oo_\n');
    end

    % Log marginal density
    if isfield(r.oo_, 'MarginalDensity')
        fprintf(fid, '\n--- Log marginal density ---\n');
        if isfield(r.oo_.MarginalDensity, 'LaplaceApproximation')
            fprintf(fid, 'Laplace: %.4f\n', r.oo_.MarginalDensity.LaplaceApproximation);
        end
    else
        fprintf(fid, '\nNo MarginalDensity field\n');
    end

    % Check if mode file has info
    fprintf(fid, '\n--- Mode file info ---\n');
    mode_file = 'au_pac_bayesian/Output/au_pac_bayesian_mode.mat';
    if exist(mode_file, 'file')
        md = load(mode_file);
        if isfield(md, 'xparam1')
            fprintf(fid, 'Mode vector: %d parameters\n', length(md.xparam1));
            fprintf(fid, 'Log posterior at mode: %.4f\n', -md.fval);
        end
        if isfield(md, 'parameter_names')
            for k = 1:length(md.parameter_names)
                fprintf(fid, '  %-22s = %.6f\n', md.parameter_names{k}, md.xparam1(k));
            end
        end
    end

else
    fprintf(fid, 'bayesian_estimation_results.mat not found\n');
end

fclose(fid);
type('bayesian_stage1_results.txt');
