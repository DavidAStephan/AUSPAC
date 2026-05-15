%% identification_analysis.m — Phase J identification diagnostics
%
% Runs Dynare's identification command on a stripped-down copy of
% au_pac_bayesian.mod (estimation block replaced with identification
% block). Produces Iskrev (2010) + Komunjer-Ng (2011) tests at the
% Phase G posterior mode, plus prior-vs-posterior overlay plots from
% the existing MCMC chains.
%
% Outputs:
%   - identification_diagnostics.mat         — full Dynare oo_ identification output
%   - identification_diagnostics_log.txt     — readable summary + weak-id flagging
%   - identification_prior_posterior.png     — 28-panel prior/posterior overlay
%
% Run from <repo>/dynare in MATLAB:
%   >> identification_analysis
%
% Prerequisites:
%   - bayesian_mcmc_results.mat (Phase G MCMC posterior)
%   - au_pac_bayesian/Output/au_pac_bayesian_mode.mat
%   - au_pac_bayesian/metropolis/*.mat (MCMC chains)

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

fprintf('=== Phase J: identification analysis ===\n');

%% --- 1. Generate au_pac_identification.mod ---
src = fileread('au_pac_bayesian.mod');

% Replace the estimation(...) varlist; statement. We chain estimation()
% followed by identification(): the first loads the posterior mode from the
% mode_file, the second runs identification at that mode.
% Notes: `parameter_set=posterior_mode` requires oo_.posterior_mode to exist,
% which it only does AFTER an estimation that reads the mode file.
this_obs = 'yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y';
replacement = sprintf([ ...
    'estimation(datafile=''estimation_data.mat'', first_obs=1, ' ...
    'mode_compute=0, mode_file=''%s'', presample=4, ' ...
    'mh_replic=0, mh_nblocks=1, diffuse_filter, nograph) %s;\n\n' ...
    'identification(advanced=1, max_dim_cova_group=4, ' ...
    'parameter_set=posterior_mode, prior_mc=2000, ' ...
    'no_identification_minimal);'], ...
    fullfile(pwd, 'au_pac_bayesian', 'Output', 'au_pac_bayesian_mode'), ...
    this_obs);
src = regexprep(src, 'estimation\([^;]+;', replacement);

% Fix mode_file path to absolute
this_dir = pwd;
mode_path = fullfile(this_dir, 'au_pac_bayesian', 'Output', ...
    'au_pac_bayesian_mode');
src = regexprep(src, ...
    "mode_file='[^']*'", ...
    sprintf("mode_file='%s'", mode_path));

fid = fopen('au_pac_identification.mod', 'w');
fwrite(fid, src);
fclose(fid);

%% --- 2. Run Dynare ---
fprintf('\n--- Running Dynare identification (Iskrev + Komunjer-Ng) ---\n');
try
    dynare au_pac_identification noclearall nograph;
    save('identification_diagnostics.mat', 'M_', 'oo_', 'options_');
    fprintf('  Identification command completed\n');
catch ME
    fprintf('  ERROR: %s\n', ME.message);
    fprintf('  Continuing with manual prior/posterior analysis only.\n');
end

%% --- 3. Diagnostic summary ---
logfid = fopen('identification_diagnostics_log.txt', 'w');
fprintf(logfid, 'Phase J identification diagnostics\n');
fprintf(logfid, 'Generated: %s\n\n', datestr(now));

if exist('oo_', 'var') && isfield(oo_, 'ident')
    ident = oo_.ident;

    % --- Iskrev rank test ---
    fprintf(logfid, '--- Iskrev (2010) rank test ---\n');
    if isfield(ident, 'rank_J')
        fprintf(logfid, '  rank(J)          = %d\n', ident.rank_J);
    end
    if isfield(ident, 'no_obs_state')
        fprintf(logfid, '  no_obs_state     = %d\n', ident.no_obs_state);
    end
    fprintf(logfid, '\n');

    % --- Komunjer-Ng test ---
    fprintf(logfid, '--- Komunjer-Ng (2011) ---\n');
    if isfield(ident, 'KomunjerNg')
        fields_kn = fieldnames(ident.KomunjerNg);
        for k = 1:length(fields_kn)
            f = fields_kn{k};
            v = ident.KomunjerNg.(f);
            if isnumeric(v) && isscalar(v)
                fprintf(logfid, '  %s = %g\n', f, v);
            end
        end
    end
    fprintf(logfid, '\n');

    % --- Identification strength ---
    if isfield(ident, 'ide_strength_dMOMENTS')
        strength = ident.ide_strength_dMOMENTS;
        param_names = ident.name;
        fprintf(logfid, '--- Identification strength (moments) ---\n');
        fprintf(logfid, '  Higher = better identified\n');
        fprintf(logfid, '  %-22s %10s\n', 'Parameter', 'Strength');
        [sorted_str, idx] = sort(strength, 'descend');
        for k = 1:length(sorted_str)
            fprintf(logfid, '  %-22s %10.4f\n', ...
                param_names{idx(k)}, sorted_str(k));
        end
        fprintf(logfid, '\n--- Top 5 weakest-identified ---\n');
        for k = length(sorted_str):-1:max(1, length(sorted_str)-4)
            fprintf(logfid, '  %s (strength %.4f)\n', ...
                param_names{idx(k)}, sorted_str(k));
        end
        fprintf(logfid, '\n');
    end

    % --- Pairwise collinearity warning ---
    if isfield(ident, 'identification_pair_collinearity')
        fprintf(logfid, '--- Pairwise collinearity (>0.95 flagged) ---\n');
        cc = ident.identification_pair_collinearity;
        param_names = ident.name;
        n = length(param_names);
        for i = 1:n
            for j = i+1:n
                if abs(cc(i, j)) > 0.95
                    fprintf(logfid, '  %s -- %s : %.3f\n', ...
                        param_names{i}, param_names{j}, cc(i, j));
                end
            end
        end
        fprintf(logfid, '\n');
    end
end

%% --- 4. Prior/posterior overlay from existing MCMC ---
fprintf('\n--- Plotting prior/posterior overlay from Phase G MCMC ---\n');
mcmc = load('bayesian_mcmc_results.mat', 'oo_', 'M_');
oo_mcmc = mcmc.oo_;
M_mcmc  = mcmc.M_;

% Read all MCMC chains
mh_dir = 'au_pac_bayesian/metropolis';
mh_files = dir(fullfile(mh_dir, 'au_pac_bayesian_mh*_blck*.mat'));
all_chains = [];
for fi = 1:length(mh_files)
    d = load(fullfile(mh_dir, mh_files(fi).name));
    if isfield(d, 'x2')
        all_chains = [all_chains; d.x2];
    end
end

% Param name list — derive from posterior fields (params first, then shocks)
est = {};
if isfield(oo_mcmc, 'posterior_mean')
    if isfield(oo_mcmc.posterior_mean, 'parameters')
        est = [est; fieldnames(oo_mcmc.posterior_mean.parameters)];
    end
    if isfield(oo_mcmc.posterior_mean, 'shocks_std')
        sh = fieldnames(oo_mcmc.posterior_mean.shocks_std);
        for k = 1:length(sh)
            est{end+1, 1} = ['stderr_' sh{k}];
        end
    end
end
n_par = length(est);
fprintf('  Collected %d MCMC draws across %d chains for %d parameters\n', ...
    size(all_chains, 1), length(mh_files), n_par);

% Compose prior moments for each param from bayestopt_ if available
if isfield(oo_mcmc, 'prior')
    prior = oo_mcmc.prior;
else
    prior = [];
end

%% Plot
nrows = ceil(sqrt(n_par));
ncols = ceil(n_par / nrows);
fig = figure('Position', [10 10 1600 1200], 'Color', 'w', 'Visible', 'off');
for p = 1:n_par
    nm = est{p};
    subplot(nrows, ncols, p);
    hold on;
    if size(all_chains, 2) >= p && ~isempty(all_chains)
        post_draws = all_chains(:, p);
        % Histogram-based density (no Stats Toolbox needed)
        [counts, edges] = histcounts(post_draws, 60, 'Normalization', 'pdf');
        x_post = 0.5 * (edges(1:end-1) + edges(2:end));
        plot(x_post, counts, 'b-', 'LineWidth', 1.2);
    end
    % Posterior mean + mode markers (handle params and shocks_std uniformly)
    yl = ylim;
    if startsWith(nm, 'stderr_')
        sub = nm(8:end);
        if isfield(oo_mcmc.posterior_mean, 'shocks_std') && ...
                isfield(oo_mcmc.posterior_mean.shocks_std, sub)
            pm = oo_mcmc.posterior_mean.shocks_std.(sub);
            plot([pm pm], yl, 'r--', 'LineWidth', 1);
        end
        if isfield(oo_mcmc, 'posterior_mode') && ...
                isfield(oo_mcmc.posterior_mode, 'shocks_std') && ...
                isfield(oo_mcmc.posterior_mode.shocks_std, sub)
            pmode = oo_mcmc.posterior_mode.shocks_std.(sub);
            plot([pmode pmode], yl, 'g-', 'LineWidth', 1);
        end
    else
        if isfield(oo_mcmc.posterior_mean, 'parameters') && ...
                isfield(oo_mcmc.posterior_mean.parameters, nm)
            pm = oo_mcmc.posterior_mean.parameters.(nm);
            plot([pm pm], yl, 'r--', 'LineWidth', 1);
        end
        if isfield(oo_mcmc, 'posterior_mode') && ...
                isfield(oo_mcmc.posterior_mode, 'parameters') && ...
                isfield(oo_mcmc.posterior_mode.parameters, nm)
            pmode = oo_mcmc.posterior_mode.parameters.(nm);
            plot([pmode pmode], yl, 'g-', 'LineWidth', 1);
        end
    end
    title(strrep(nm, '_', '\_'), 'FontSize', 8);
    grid on;
    set(gca, 'FontSize', 7);
end
sgtitle('Posterior densities (blue) with posterior mean (red --) and mode (green -)', ...
    'FontSize', 13);
print(fig, 'identification_prior_posterior', '-dpng', '-r200');
close(fig);
fprintf('  Saved: identification_prior_posterior.png\n');

%% --- 5. HPD width ranking (proxy for weak identification) ---
fprintf(logfid, '\n--- HPD width ranking (Phase G posterior, proxy for weak identification) ---\n');
if isfield(oo_mcmc, 'posterior_hpdinf') && isfield(oo_mcmc, 'posterior_hpdsup')
    fprintf(logfid, '  %-22s %10s %10s %10s %12s\n', ...
        'Parameter', 'HPD_lo', 'HPD_hi', 'width', 'norm_width');
    if isfield(oo_mcmc.posterior_hpdinf, 'parameters')
        pf = fieldnames(oo_mcmc.posterior_hpdinf.parameters);
        widths = zeros(length(pf), 1);
        norm_widths = zeros(length(pf), 1);
        for p = 1:length(pf)
            lo = oo_mcmc.posterior_hpdinf.parameters.(pf{p});
            hi = oo_mcmc.posterior_hpdsup.parameters.(pf{p});
            pm = oo_mcmc.posterior_mean.parameters.(pf{p});
            widths(p) = hi - lo;
            if abs(pm) > 1e-9
                norm_widths(p) = widths(p) / abs(pm);
            else
                norm_widths(p) = widths(p);
            end
        end
        [~, ix] = sort(norm_widths, 'descend');
        for p = ix'
            fprintf(logfid, '  %-22s %10.4f %10.4f %10.4f %12.4f\n', ...
                pf{p}, ...
                oo_mcmc.posterior_hpdinf.parameters.(pf{p}), ...
                oo_mcmc.posterior_hpdsup.parameters.(pf{p}), ...
                widths(p), norm_widths(p));
        end
        fprintf(logfid, '\n--- Top 5 widest-normalised HPD intervals (Phase J residual gaps) ---\n');
        for r = 1:min(5, length(ix))
            fprintf(logfid, '  %-22s normalised width = %.4f\n', ...
                pf{ix(r)}, norm_widths(ix(r)));
        end
    end
end

fclose(logfid);
fprintf('\n=== Phase J identification analysis complete ===\n');
fprintf('  Diagnostics: identification_diagnostics_log.txt\n');
fprintf('  Plot:        identification_prior_posterior.png\n');
fprintf('  MAT:         identification_diagnostics.mat\n');
