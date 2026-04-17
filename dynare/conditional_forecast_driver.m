%% conditional_forecast_driver.m
% Conditional forecasting via Dynare's conditional_forecast command.
%
% Implements the ECB-Base "residual inversion" approach:
%   Given a desired path for conditioned variables, solve for the shock
%   sequence that replicates it, then simulate all other variables.
%
% Pre-defined scenarios:
%   1. RBA tightening: gradual 100bp hike, then hold, then normalize
%   2. RBA easing: 150bp cut over 6 quarters
%   3. Demand shock: output gap follows recession-recovery path
%   4. Stagflation: simultaneous rate + inflation conditioning
%
% USAGE:
%   >> cd(<repo>/dynare); conditional_forecast_driver              % default scenario
%   >> conditional_forecast_driver('easing')                       % easing scenario
%   >> conditional_forecast_driver('custom', scenario_struct)

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = 'conditional_forecast_log.txt';
fid_log = fopen(logfile, 'w');
log_msg = @(msg) fprintf_both(fid_log, msg);

log_msg('================================================================\n');
log_msg('  AU_PAC CONDITIONAL FORECASTING\n');
log_msg(sprintf('  %s\n', datestr(now)));
log_msg('================================================================\n\n');

%% 1. Define scenarios
% Values are deviations from steady state (quarterly %)
% i_au SS = i_ss = 1.0491 (quarterly) ≈ 4.2% annual

scenarios = struct();

% Scenario 1: RBA tightening cycle
% +25bp/quarter for 4Q, hold 4Q, then normalize over 4Q
% In quarterly terms: +0.0625 per quarter step = +25bp annual / 4
scenarios.tightening.name = 'RBA Tightening Cycle (100bp over 4Q)';
scenarios.tightening.horizon = 16;
scenarios.tightening.vars = {'i_au'};
scenarios.tightening.values = {[0.0625, 0.125, 0.1875, 0.25, ...   % ramp up
                                 0.25, 0.25, 0.25, 0.25, ...        % hold
                                 0.20, 0.15, 0.10, 0.05, ...        % normalize
                                 0, 0, 0, 0]};                      % back to SS
scenarios.tightening.shocks = {'eps_i'};

% Scenario 2: RBA easing cycle
% -25bp/quarter for 6Q, then hold
scenarios.easing.name = 'RBA Easing Cycle (150bp cut over 6Q)';
scenarios.easing.horizon = 16;
scenarios.easing.vars = {'i_au'};
scenarios.easing.values = {[-0.0625, -0.125, -0.1875, -0.25, -0.3125, -0.375, ...
                             -0.375, -0.375, -0.375, -0.375, ...
                             -0.30, -0.20, -0.10, 0, 0, 0]};
scenarios.easing.shocks = {'eps_i'};

% Scenario 3: Recession scenario
% Output gap follows recession path, controlled by demand shock
scenarios.recession.name = 'Recession (output gap to -2%, gradual recovery)';
scenarios.recession.horizon = 16;
scenarios.recession.vars = {'yhat_au'};
scenarios.recession.values = {[-0.5, -1.0, -1.5, -2.0, ...
                                -1.8, -1.5, -1.2, -0.9, ...
                                -0.6, -0.4, -0.2, -0.1, ...
                                 0, 0, 0, 0]};
scenarios.recession.shocks = {'eps_q'};

% Scenario 4: Stagflation — condition on BOTH rate and inflation
% RBA raises rates while inflation stays elevated
scenarios.stagflation.name = 'Stagflation (elevated inflation + RBA tightening)';
scenarios.stagflation.horizon = 12;
scenarios.stagflation.vars = {'i_au', 'pi_au'};
scenarios.stagflation.values = {[0.0625, 0.125, 0.1875, 0.25, 0.25, 0.25, ...
                                  0.20, 0.15, 0.10, 0.05, 0, 0], ...
                                 [0.3, 0.35, 0.35, 0.30, 0.25, 0.20, ...
                                  0.15, 0.10, 0.05, 0, 0, 0]};
scenarios.stagflation.shocks = {'eps_i', 'eps_pi'};

%% 2. Select scenario
scenario_name = 'tightening';  % default
sc = scenarios.(scenario_name);

log_msg(sprintf('Scenario: %s\n', sc.name));
log_msg(sprintf('Horizon: %d quarters\n', sc.horizon));
log_msg(sprintf('Conditioned variables: %s\n', strjoin(sc.vars, ', ')));
log_msg(sprintf('Controlled shocks: %s\n', strjoin(sc.shocks, ', ')));

%% 3. Generate conditional forecast .mod file
log_msg('\n--- Generating au_pac_condforecast.mod ---\n');
generate_condforecast_mod(sc);

%% 4. Run Dynare
log_msg('\n--- Running dynare au_pac_condforecast ---\n\n');

try
    dynare au_pac_condforecast noclearall

    log_msg('\n--- Conditional forecast complete ---\n');

    % Extract results
    if isfield(oo_, 'conditional_forecast')
        cf = oo_.conditional_forecast;
        log_msg('\nConditional forecast results:\n');

        % Key variables to display
        display_vars = {'yhat_au', 'pi_au', 'i_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'i_10y'};

        log_msg(sprintf('\n  %-12s %8s %8s %8s %8s %8s\n', ...
            'Variable', 'Q1', 'Q4', 'Q8', 'Q12', 'Q16'));

        for v = 1:length(display_vars)
            vname = display_vars{v};
            if isfield(cf.cond, vname)
                vals = cf.cond.(vname).Mean;
                H = length(vals);
                q1  = vals(min(1, H));
                q4  = vals(min(4, H));
                q8  = vals(min(8, H));
                q12 = vals(min(12, H));
                q16 = vals(min(16, H));
                log_msg(sprintf('  %-12s %+8.4f %+8.4f %+8.4f %+8.4f %+8.4f\n', ...
                    vname, q1, q4, q8, q12, q16));
            end
        end

        % Save results
        save('conditional_forecast_results.mat', 'oo_', 'sc', 'cf');
        log_msg('\nResults saved to conditional_forecast_results.mat\n');

        % Plot
        log_msg('\nGenerating plots...\n');
        plot_conditional_forecast(cf, sc, display_vars);

    else
        log_msg('WARNING: oo_.conditional_forecast not found\n');
        log_msg('Attempting manual residual inversion...\n');
        manual_conditional_forecast(oo_, M_, sc, log_msg);
    end

catch ME
    log_msg(sprintf('\nDynare conditional_forecast failed: %s\n', ME.message));
    log_msg('Falling back to manual residual inversion...\n\n');

    % Manual approach using decision rule matrices
    % First, run stoch_simul to get the decision rule
    log_msg('Running dynare au_pac json=compute for decision rule...\n');
    dynare au_pac json=compute noclearall

    % Build companion and initialize PAC
    if ~isstruct(oo_.var), oo_.var = struct(); end
    get_companion_matrix('esat_enriched', 'var');
    pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
    for k = 1:length(pac_models)
        pac.initialize(pac_models{k});
        pac.update.expectation(pac_models{k});
    end

    manual_conditional_forecast(oo_, M_, sc, log_msg);
end

log_msg('\n================================================================\n');
log_msg('  CONDITIONAL FORECASTING COMPLETE\n');
log_msg('================================================================\n');
fclose(fid_log);

%% =====================================================================
%  Helper functions
%  =====================================================================

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0
        fprintf(fid, msg);
    end
end

function generate_condforecast_mod(sc)
% Generate au_pac_condforecast.mod from au_pac.mod
% Appends conditional_forecast_paths + conditional_forecast after stoch_simul

    moddir = fileparts(mfilename('fullpath'));
    infile  = fullfile(moddir, 'au_pac.mod');
    outfile = fullfile(moddir, 'au_pac_condforecast.mod');

    fid_in = fopen(infile, 'r');
    lines = {};
    while ~feof(fid_in)
        lines{end+1} = fgetl(fid_in); %#ok<AGROW>
    end
    fclose(fid_in);

    outlines = {};
    cf_inserted = false;

    for k = 1:length(lines)
        ln = lines{k};
        outlines{end+1} = ln;

        % Insert conditional forecast after stoch_simul
        if ~cf_inserted && contains(ln, 'stoch_simul(')
            outlines{end+1} = '';
            outlines{end+1} = '// Conditional forecast paths (auto-generated)';
            outlines{end+1} = 'conditional_forecast_paths;';

            for v = 1:length(sc.vars)
                vname = sc.vars{v};
                vals = sc.values{v};
                % Dynare requires comma-separated values
                val_parts = arrayfun(@(x) sprintf('%.4f', x), vals, 'UniformOutput', false);
                val_str = strjoin(val_parts, ', ');
                outlines{end+1} = sprintf('var %s;', vname);
                outlines{end+1} = sprintf('periods 1:%d;', length(vals));
                outlines{end+1} = sprintf('values %s;', val_str);
            end

            outlines{end+1} = 'end;';
            outlines{end+1} = '';

            % Build controlled_varexo string
            shock_str = strjoin(sc.shocks, ', ');
            outlines{end+1} = sprintf('conditional_forecast(parameter_set = calibration, controlled_varexo = (%s), replic = 5000);', shock_str);
            outlines{end+1} = '';
            outlines{end+1} = sprintf('plot_conditional_forecast(periods = %d) yhat_au pi_au i_au dln_c dln_ib dln_ih dln_n i_10y;', sc.horizon);

            cf_inserted = true;
        end

        % Stop before estimation infrastructure comments
        if contains(ln, 'ESTIMATION INFRASTRUCTURE')
            break;
        end
    end

    fid_out = fopen(outfile, 'w');
    for k = 1:length(outlines)
        fprintf(fid_out, '%s\n', outlines{k});
    end
    fclose(fid_out);

    fprintf('  au_pac_condforecast.mod generated (cf_inserted=%d)\n', cf_inserted);
end

function manual_conditional_forecast(oo_, M_, sc, log_fn)
% Manual residual inversion using Dynare decision rule matrices.
%
% Decision rule (order=1): y_t = ys + ghx*(x_{t-1} - xs) + ghu*eps_t
%   where x = state variables, eps = shocks
%
% Algorithm:
%   For each t=1,...,H:
%     1. Baseline: y_t^0 = ys + ghx*(x_{t-1} - xs)  (no shocks)
%     2. Gap: delta = y_cond_t - y_t^0  (for conditioned vars)
%     3. Solve: eps_cond = R_sub \ delta
%     4. Update: y_t = y_t^0 + ghu * eps_t

    log_fn('--- Manual residual inversion ---\n\n');

    dr = oo_.dr;
    ys = dr.ys;          % steady state (declaration order)
    ghx = dr.ghx;        % state transition (DR order), nendo x nstate
    ghu = dr.ghu;        % shock impact (DR order), nendo x nexo
    order_var = dr.order_var;  % DR order -> declaration order mapping
    nstatic = M_.nstatic;
    npred = M_.npred;
    nboth = M_.nboth;
    nfwrd = M_.nfwrd;

    % State variables = predetermined + mixed (both), in DR order positions
    nstate = npred + nboth;
    state_idx = (nstatic+1):(nstatic+nstate);
    nendo = M_.endo_nbr;
    nexo = M_.exo_nbr;

    % Map variable names to DR order indices
    get_dr_idx = @(vname) find(order_var == find(strcmp(vname, M_.endo_names)));
    get_exo_idx = @(ename) find(strcmp(ename, M_.exo_names));

    % Conditioned variable indices (in DR order)
    cond_dr_idx = zeros(length(sc.vars), 1);
    for v = 1:length(sc.vars)
        cond_dr_idx(v) = get_dr_idx(sc.vars{v});
    end

    % Controlled shock indices
    ctrl_exo_idx = zeros(length(sc.shocks), 1);
    for s = 1:length(sc.shocks)
        ctrl_exo_idx(s) = get_exo_idx(sc.shocks{s});
    end

    log_fn(sprintf('  Conditioned vars (DR order): %s\n', mat2str(cond_dr_idx')));
    log_fn(sprintf('  Controlled shocks: %s\n', mat2str(ctrl_exo_idx')));
    log_fn(sprintf('  State vars: %d, Total endo: %d, Total exo: %d\n', nstate, nendo, nexo));

    H = sc.horizon;

    % Build conditioned paths (deviations from SS, in DR order)
    cond_paths = zeros(length(sc.vars), H);
    for v = 1:length(sc.vars)
        vals = sc.values{v};
        cond_paths(v, 1:length(vals)) = vals;
    end

    % Initialize state at steady state
    x_state = zeros(nstate, 1);  % state deviations from SS

    % Storage: y_dev stores deviations from SS in declaration order
    y_dev = zeros(nendo, H);
    eps_solved = zeros(nexo, H);

    for t = 1:H
        % 1. Baseline (no shocks): deviations from SS in DR order
        y_base_dr = ghx * x_state;

        % 2. Gap for conditioned variables (deviations from SS)
        delta = cond_paths(:, t) - y_base_dr(cond_dr_idx);

        % 3. Impact sub-matrix for controlled shocks on conditioned variables
        R_sub = ghu(cond_dr_idx, ctrl_exo_idx);

        % 4. Solve for controlled shocks
        eps_cond = R_sub \ delta;

        % 5. Full shock vector
        eps_t = zeros(nexo, 1);
        eps_t(ctrl_exo_idx) = eps_cond;
        eps_solved(:, t) = eps_t;

        % 6. Full forecast (deviations from SS, DR order)
        y_dr = y_base_dr + ghu * eps_t;

        % 7. Convert DR order -> declaration order (deviations from SS)
        y_dev(order_var, t) = y_dr;

        % 8. Update state for next period (states in DR order)
        x_state = y_dr(state_idx);
    end

    % Display results (deviations from SS, declaration order)
    display_vars = {'yhat_au', 'pi_au', 'i_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'i_10y'};
    log_fn(sprintf('\n  %-12s', 'Variable'));
    for t = [1, 4, 8, 12, min(16, H)]
        log_fn(sprintf(' %8s', sprintf('Q%d', t)));
    end
    log_fn('\n');

    results = struct();
    for v = 1:length(display_vars)
        vname = display_vars{v};
        vidx = find(strcmp(vname, M_.endo_names));
        if ~isempty(vidx)
            vals = y_dev(vidx, :);  % already deviations from SS
            results.(vname) = vals;

            log_fn(sprintf('  %-12s', vname));
            for t = [1, 4, 8, 12, min(16, H)]
                if t <= H
                    log_fn(sprintf(' %+8.4f', vals(t)));
                end
            end
            log_fn('\n');
        end
    end

    % Log solved shocks
    log_fn('\n  Solved shock magnitudes:\n');
    for s = 1:length(sc.shocks)
        sname = sc.shocks{s};
        sidx = ctrl_exo_idx(s);
        log_fn(sprintf('  %-12s: max=%.4f, sum=%.4f\n', ...
            sname, max(abs(eps_solved(sidx,:))), sum(eps_solved(sidx,:))));
    end

    % Save
    save('conditional_forecast_manual.mat', 'y_dev', 'eps_solved', 'sc', 'results', 'ys');
    log_fn('\nManual results saved to conditional_forecast_manual.mat\n');

    % Plot
    plot_manual_forecast(results, sc, ys, M_);
end

function plot_conditional_forecast(cf, sc, display_vars)
    figure('Position', [100 100 1200 800], 'Visible', 'off');
    nv = length(display_vars);
    nc = 3;
    nr = ceil(nv / nc);

    for v = 1:nv
        vname = display_vars{v};
        if isfield(cf.cond, vname)
            subplot(nr, nc, v);
            vals = cf.cond.(vname).Mean;
            ci_lo = cf.cond.(vname).ci;
            H = length(vals);
            fill([1:H, H:-1:1], [ci_lo(1,:), fliplr(ci_lo(2,:))], ...
                [0.8 0.85 1], 'EdgeColor', 'none'); hold on;
            plot(1:H, vals, 'b-', 'LineWidth', 2);
            plot(1:H, zeros(1,H), 'k--');
            title(strrep(vname, '_', '\_'));
            xlabel('Quarters');
            ylabel('Dev. from SS');
            xlim([1 H]);
        end
    end
    sgtitle(strrep(sc.name, '_', '\_'));
    saveas(gcf, sprintf('conditional_forecast_%s.png', ...
        lower(strrep(strrep(sc.name, ' ', '_'), '(', ''))));
    close;
end

function plot_manual_forecast(results, sc, ys, M_)
    display_vars = {'yhat_au', 'pi_au', 'i_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'i_10y'};
    figure('Position', [100 100 1200 800], 'Visible', 'off');
    nv = length(display_vars);
    nc = 3;
    nr = ceil(nv / nc);

    H = sc.horizon;
    for v = 1:nv
        vname = display_vars{v};
        if isfield(results, vname)
            subplot(nr, nc, v);
            vals = results.(vname);
            plot(1:H, vals, 'b-', 'LineWidth', 2); hold on;
            plot(1:H, zeros(1,H), 'k--');

            % Mark conditioned variables
            if ismember(vname, sc.vars)
                plot(1:H, vals, 'ro', 'MarkerSize', 4);
            end

            title(strrep(vname, '_', '\_'));
            xlabel('Quarters');
            ylabel('Dev. from SS');
            xlim([1 H]);
            grid on;
        end
    end
    sgtitle(sprintf('Conditional Forecast: %s', strrep(sc.name, '_', '\_')));
    saveas(gcf, 'conditional_forecast_manual.png');
    close;
    fprintf('  Plot saved to conditional_forecast_manual.png\n');
end
