function generate_smoother_mod()
%% generate_smoother_mod.m
% Generates au_pac_smooth.mod from au_pac.mod by:
%   1. Inserting a 'varobs' declaration before the model block
%   2. Appending 'calib_smoother' after stoch_simul
%
% This avoids duplicating the entire .mod file. The generated file
% is used for Kalman smoothing to extract model-consistent values
% of all endogenous variables (especially unobserved auxiliary gaps).

fprintf('=== Generating au_pac_smooth.mod ===\n');

moddir = fileparts(mfilename('fullpath'));
infile  = fullfile(moddir, 'au_pac.mod');
outfile = fullfile(moddir, 'au_pac_smooth.mod');

% Read source line by line
fid = fopen(infile, 'r');
lines = {};
while ~feof(fid)
    lines{end+1} = fgetl(fid); %#ok<AGROW>
end
fclose(fid);

% Process lines
outlines = {};
varobs_inserted = false;
smoother_inserted = false;
varfix_inserted = false;

in_stochsimul = false;
for k = 1:length(lines)
    ln = lines{k};

    % Insert varobs just before 'model;'
    if ~varobs_inserted && strcmp(strtrim(ln), 'model;')
        outlines{end+1} = '';
        outlines{end+1} = '// Observable variables for Kalman smoother (auto-generated)';
        outlines{end+1} = 'varobs yhat_au pi_au i_au yhat_us pi_us dln_c dln_ib dln_ih dln_n;';
        outlines{end+1} = '';
        varobs_inserted = true;
    end

    % Fix oo_.var before the first pac.initialize call
    % (noclearall preserves oo_.var as double from prior stoch_simul)
    if ~varfix_inserted && ~isempty(strfind(ln, 'pac.initialize('))
        outlines{end+1} = '// Fix oo_.var from prior stoch_simul (auto-generated)';
        outlines{end+1} = 'if exist(''oo_'', ''var'') && isfield(oo_, ''var'') && ~isstruct(oo_.var), oo_.var = struct(); end';
        varfix_inserted = true;
    end

    % Output the original line
    outlines{end+1} = ln;

    % Track multi-line stoch_simul: wait for its closing semicolon
    if ~smoother_inserted && ~isempty(strfind(ln, 'stoch_simul('))
        in_stochsimul = true;
    end
    if in_stochsimul && ~isempty(strfind(ln, ';'))
        % Found the end of stoch_simul statement — insert calib_smoother after it
        outlines{end+1} = '';
        outlines{end+1} = '// Fix oo_.var for calib_smoother (stoch_simul sets it to double)';
        outlines{end+1} = 'if ~isstruct(oo_.var), oo_.var = struct(); end';
        outlines{end+1} = 'get_companion_matrix(''esat_enriched'', ''var'');';
        outlines{end+1} = '';
        outlines{end+1} = '// Kalman smoother: extract model-consistent states (auto-generated)';
        outlines{end+1} = 'calib_smoother(datafile=''smoother_data.mat'', diffuse_filter) yhat_au pi_au i_au yhat_us pi_us';
        outlines{end+1} = '    dln_c dln_ib dln_ih dln_n';
        outlines{end+1} = '    piQ_hat c_hat ib_hat ih_hat n_hat yh_ratio_hat rKB_hat';
        outlines{end+1} = '    pv_piQ_aux pv_n_aux pv_c_aux pv_ib_aux pv_rKB_aux pv_ih_aux';
        outlines{end+1} = '    ph_gap di_gap dln_ph';
        outlines{end+1} = '    pQ_level ln_c_level ln_ib_level ln_ih_level ln_n_level';
        outlines{end+1} = '    y_gap_var i_gap_var pi_gap_var u_gap_var yhat_us_var;';
        in_stochsimul = false;
        smoother_inserted = true;
    end
end

% Write output
fid = fopen(outfile, 'w');
for k = 1:length(outlines)
    fprintf(fid, '%s\n', outlines{k});
end
fclose(fid);

fprintf('  varobs inserted: %d\n', varobs_inserted);
fprintf('  calib_smoother inserted: %d\n', smoother_inserted);
fprintf('  Total lines: %d -> %d\n', length(lines), length(outlines));
fprintf('  Output: %s\n', outfile);
fprintf('=== au_pac_smooth.mod generated ===\n');

end
