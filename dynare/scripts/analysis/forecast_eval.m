%% forecast_eval.m — Phase I pseudo-real-time recursive forecast evaluation
%
% For each origin t* in {2018Q1, 2018Q2, ..., 2023Q4}:
%   1. Run Dynare estimation on observations 1..t* (via nobs option)
%   2. Parameters held at Phase G posterior mode (mode_compute=0)
%   3. Kalman smoother gives the state at t*
%   4. Project forward with zero shocks → h-quarter-ahead forecasts
%   5. Record (forecast - actual) for h = 1, 4, 8 quarters
%
% Output: forecast_eval_results.mat, forecast_eval_log.txt,
%         forecast_eval_rmse.png, forecast_eval_paths.png
%
% Usage (in MATLAB; needs Dynare 6.5 on path via setup_dynare_path):
%   >> forecast_eval

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

%% --- Configuration ---
T_FORECAST   = 8;          % forecast horizons evaluated (1Q..8Q)
HORIZONS_TBL = [1 2 4 8];  % reported in RMSE table

%% --- Load full data and meta ---
fprintf('=== Phase I: pseudo-real-time recursive forecast evaluation ===\n');
data = load('estimation_data.mat');
meta = load('estimation_meta.mat');
meta = meta.meta;
varnames = cellstr(meta.varnames);
nObs = double(meta.nObs);
n_vars = length(varnames);
fprintf('  Full sample: %d quarters, %d observables\n', nObs, n_vars);

% Build (year, quarter, index) date list starting 1994Q3
year = 1994; quarter = 3;
dates_all = zeros(nObs, 1);
for i = 1:nObs
    dates_all(i) = year + (quarter - 1) * 0.25;
    quarter = quarter + 1;
    if quarter > 4, quarter = 1; year = year + 1; end
end

% Forecast origins: from 2018Q1 (obs 94) to 2023Q4 (obs 117)
origin_idx = find(dates_all >= 2018 - 1e-6 & dates_all <= 2023.75 + 1e-6);
fprintf('  Forecast origins: %d (from %.2f to %.2f)\n', ...
    length(origin_idx), dates_all(origin_idx(1)), dates_all(origin_idx(end)));

% Collect full-data series for actuals
full_data = struct();
for v = 1:n_vars
    full_data.(varnames{v}) = data.(varnames{v});
end

%% --- Storage ---
n_origins = length(origin_idx);
fcst_mat = nan(n_origins, T_FORECAST, n_vars);
act_mat  = nan(n_origins, T_FORECAST, n_vars);

logfile = fopen('forecast_eval_log.txt', 'w');
fprintf(logfile, 'Phase I forecast evaluation\n');
fprintf(logfile, 'Generated: %s\n', datestr(now));
fprintf(logfile, 'Origins: %d (%.2f to %.2f)\n', n_origins, ...
    dates_all(origin_idx(1)), dates_all(origin_idx(end)));
fprintf(logfile, 'Horizons: 1..%d quarters\n\n', T_FORECAST);

%% --- Loop over origins ---
for o = 1:n_origins
    t_star = origin_idx(o);
    fprintf('\n--- Origin %d/%d: %.2f (obs %d/%d) ---\n', ...
        o, n_origins, dates_all(t_star), t_star, nObs);
    fprintf(logfile, 'Origin %d (obs %d, %.2f): ', o, t_star, dates_all(t_star));

    % Write a custom .mod that uses nobs=t_star + forecast=T_FORECAST
    generate_recursive_mod(t_star, T_FORECAST);

    try
        evalin('base', 'clear M_ oo_ options_');
        dynare au_pac_recursive noclearall nograph;
    catch ME
        fprintf(logfile, 'DYNARE FAIL — %s\n', ME.message);
        continue;
    end

    if ~isfield(oo_, 'forecast') || ~isfield(oo_.forecast, 'Mean')
        fprintf(logfile, 'no oo_.forecast.Mean\n');
        continue;
    end

    % Read T_FORECAST-step forecasts from Dynare's own forecast block
    fmean = oo_.forecast.Mean;
    yf = zeros(T_FORECAST, n_vars);
    for v = 1:n_vars
        if isfield(fmean, varnames{v})
            ser = fmean.(varnames{v});
            for h = 1:min(T_FORECAST, length(ser))
                yf(h, v) = ser(h);
            end
        end
    end

    for h = 1:T_FORECAST
        for v = 1:n_vars
            if t_star + h <= nObs
                fcst_mat(o, h, v) = yf(h, v);
                act_mat(o, h, v)  = full_data.(varnames{v})(t_star + h);
            end
        end
    end
    fprintf(logfile, 'OK\n');
    fprintf('  h=1..%d forecasts recorded\n', T_FORECAST);

    % Checkpoint after each origin so a late crash doesn't lose work
    save('forecast_eval_checkpoint.mat', 'fcst_mat', 'act_mat', ...
         'origin_idx', 'dates_all', 'varnames', 'T_FORECAST');
end

%% --- Compute RMSEs ---
err  = fcst_mat - act_mat;
rmse = squeeze(sqrt(mean(err.^2, 1, 'omitnan')));    % (horizon × variable)
mae  = squeeze(mean(abs(err), 1, 'omitnan'));
bias = squeeze(mean(err, 1, 'omitnan'));

fprintf(logfile, '\n=== RMSE table ===\n');
fprintf(logfile, '%-12s', 'Variable');
for h = HORIZONS_TBL, fprintf(logfile, '  RMSE_h%-2d', h); end
fprintf(logfile, '\n');
for v = 1:n_vars
    fprintf(logfile, '%-12s', varnames{v});
    for h = HORIZONS_TBL
        fprintf(logfile, '  %8.4f', rmse(h, v));
    end
    fprintf(logfile, '\n');
end

%% --- Markdown table for paper §5.5 ---
md = fopen('forecast_eval_table.md', 'w');
fprintf(md, '### Table 5.8: Pseudo-real-time recursive RMSE (Phase I)\n\n');
fprintf(md, '%d forecast origins: 2018Q1–2023Q4. Parameters held at Phase G ', ...
    n_origins);
fprintf(md, 'posterior mode (mode_compute=0). Smoother re-run each origin on ');
fprintf(md, 'expanding window; forecast = zero-shock projection of state via ');
fprintf(md, 'gx*state_{t-1}.\n\n');
fprintf(md, '| Variable | h=1 | h=2 | h=4 | h=8 |\n');
fprintf(md, '|---|---|---|---|---|\n');
for v = 1:n_vars
    fprintf(md, '| %s ', varnames{v});
    for h = HORIZONS_TBL
        fprintf(md, '| %.4f ', rmse(h, v));
    end
    fprintf(md, '|\n');
end
fclose(md);

%% --- Plot 1: RMSE bar chart ---
fig1 = figure('Position', [50 50 1200 600], 'Color', 'w', 'Visible', 'off');
bar(rmse(HORIZONS_TBL, :)');
set(gca, 'XTickLabel', varnames, 'XTickLabelRotation', 45);
ylabel('RMSE');
legend(arrayfun(@(h) sprintf('h=%d', h), HORIZONS_TBL, 'UniformOutput', false), ...
    'Location', 'best');
title(sprintf('AU-PAC pseudo-real-time RMSE by horizon (Phase I, %d origins)', n_origins));
grid on;
print(fig1, 'forecast_eval_rmse', '-dpng', '-r200');
close(fig1);

%% --- Plot 2: forecast paths for 4 key vars ---
key_vars = {'yhat_au', 'pi_au', 'dln_c', 'i_au'};
fig2 = figure('Position', [50 50 1400 900], 'Color', 'w', 'Visible', 'off');
for k = 1:length(key_vars)
    subplot(2, 2, k);
    hold on;
    nm = key_vars{k};
    v_idx = find(strcmp(varnames, nm));
    if isempty(v_idx), continue; end

    plot(dates_all, full_data.(nm), 'k-', 'LineWidth', 1.6);
    for o = 1:n_origins
        t_star = origin_idx(o);
        h_max = min(T_FORECAST, nObs - t_star);
        if h_max < 1, continue; end
        fc_dates = dates_all(t_star + (1:h_max));
        fc_vals = squeeze(fcst_mat(o, 1:h_max, v_idx));
        plot(fc_dates, fc_vals, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.7);
    end
    title(strrep(nm, '_', '\_'), 'FontSize', 11);
    xlabel('Year'); grid on;
    set(gca, 'FontSize', 10);
end
sgtitle('Recursive forecast paths vs actual (Phase I)', 'FontSize', 13);
print(fig2, 'forecast_eval_paths', '-dpng', '-r200');
close(fig2);

%% --- Save full results ---
save('forecast_eval_results.mat', 'fcst_mat', 'act_mat', 'err', 'rmse', ...
    'mae', 'bias', 'origin_idx', 'dates_all', 'varnames', ...
    'HORIZONS_TBL', 'T_FORECAST');
fclose(logfile);

fprintf('\n=== Phase I forecast evaluation complete ===\n');
fprintf('  Log:        forecast_eval_log.txt\n');
fprintf('  Results:    forecast_eval_results.mat\n');
fprintf('  MD table:   forecast_eval_table.md\n');
fprintf('  RMSE plot:  forecast_eval_rmse.png\n');
fprintf('  Paths plot: forecast_eval_paths.png\n');


%% ==================================================================
%% Helper functions
%% ==================================================================

function generate_recursive_mod(t_star, T_FORECAST)
%% Generate a one-shot au_pac_recursive.mod with nobs=t_star, no MCMC,
%  Dynare's built-in forecast option for the saddle-path-correct horizon.
src = fileread('au_pac_bayesian.mod');

src = regexprep(src, 'first_obs=\d+', 'first_obs=1');
src = regexprep(src, 'mode_compute=\d+', 'mode_compute=0');
src = regexprep(src, 'mh_replic=\d+', 'mh_replic=0');
src = regexprep(src, 'mh_nblocks=\d+', 'mh_nblocks=1');
src = regexprep(src, 'mh_jscale=[\d\.]+', ...
    sprintf('nobs=%d, forecast=%d', t_star, T_FORECAST));

% Absolute mode_file path
this_dir = pwd;
mode_path = fullfile(this_dir, 'au_pac_bayesian', 'Output', ...
    'au_pac_bayesian_mode');
src = regexprep(src, ...
    "mode_file='[^']*'", ...
    sprintf("mode_file='%s'", mode_path));

fid = fopen('au_pac_recursive.mod', 'w');
fwrite(fid, src);
fclose(fid);
end


function yf = forecast_from_state(oo_, M_, T_FORECAST, obs_names)
%% Iterate the linear decision rule forward T_FORECAST quarters from the
%  smoothed state at the last in-sample period, with zero shocks.

ys = oo_.dr.ys;
gx = oo_.dr.ghx;
order_var = oo_.dr.order_var;
state_var = oo_.dr.state_var;

endo_names = cellstr(M_.endo_names);
n_endo = length(ys);
n_obs = length(obs_names);

% Last smoothed value of each endogenous, in declaration order
last_smoothed = zeros(n_endo, 1);
for k = 1:n_endo
    nm = endo_names{k};
    if isfield(oo_.SmoothedVariables, nm)
        ser = oo_.SmoothedVariables.(nm);
        last_smoothed(k) = ser(end);
    else
        last_smoothed(k) = ys(k);
    end
end
y_dev_decl = last_smoothed - ys;           % declaration-order deviation
y_dev_dr = y_dev_decl(order_var);          % DR-order deviation

% Iterate forward
yf = zeros(T_FORECAST, n_obs);
y_prev = y_dev_dr;
for t = 1:T_FORECAST
    y_state = y_prev(state_var);
    y_curr_dr = gx * y_state;     % gu*0 = 0
    % Map back to declaration order, add SS to get level forecast
    y_curr_decl = zeros(n_endo, 1);
    for j = 1:n_endo
        y_curr_decl(order_var(j)) = y_curr_dr(j);
    end
    y_level = ys + y_curr_decl;
    for v = 1:n_obs
        ix = find(strcmp(endo_names, obs_names{v}), 1);
        if ~isempty(ix)
            yf(t, v) = y_level(ix);
        end
    end
    y_prev = y_curr_dr;
end
end
