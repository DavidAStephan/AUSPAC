%% smoke_uip_three_regimes.m — verify all 3 regimes compile + solve under
%% the forward-looking UIP (pv_i_uip) added 2026-05-15.
%%
%% Runs dynare on each .mod, captures errors, and reports BK / steady-state.
%% Does NOT run estimation. Each regime gets a fresh MATLAB invocation so
%% dynare's local-clearing doesn't break the loop.

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

logfile = 'smoke_uip_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Smoke test: forward-looking UIP, %s\n', datestr(now));
fclose(fid);

regimes = {'au_pac_var', 'au_pac', 'au_pac_mce'};
labels  = {'VAR (backward UIP)', 'Hybrid (forward UIP)', 'MCE (forward UIP)'};

for r = 1:numel(regimes)
    fprintf('\n=== [%d/%d] %s — %s ===\n', r, numel(regimes), regimes{r}, labels{r});
    ok = true;
    try
        evalin('base', 'clear M_ oo_ options_');
        eval(['dynare ' regimes{r} ' noclearall nograph']);
        if isfield(oo_, 'steady_state') && all(isfinite(oo_.steady_state))
            fprintf('  STEADY STATE: OK (n=%d vars)\n', numel(oo_.steady_state));
        else
            fprintf('  STEADY STATE: BAD\n');
            ok = false;
        end
        % Check pv_i_uip is in the variable list and SS = 0
        idx = find(strcmp(cellstr(M_.endo_names), 'pv_i_uip'));
        if isempty(idx)
            fprintf('  pv_i_uip: MISSING from endo_names!\n');
            ok = false;
        else
            pv_ss = oo_.steady_state(idx);
            fprintf('  pv_i_uip SS = %.6e (expect 0)\n', pv_ss);
            if abs(pv_ss) > 1e-8
                fprintf('  ** pv_i_uip SS not zero **\n');
                ok = false;
            end
        end
        % Check eigenvalues / BK
        if isfield(oo_, 'dr') && ~isempty(oo_.dr)
            fprintf('  POLICY FUNCTION: solved (n_static=%d, n_pred=%d, n_fwd=%d, n_both=%d)\n', ...
                M_.nstatic, M_.npred, M_.nfwrd, M_.nboth);
        end
    catch ME
        fprintf('  *** ERROR ***: %s\n', ME.message);
        ok = false;
    end
    fid = fopen(logfile, 'a');
    if ok
        fprintf(fid, 'PASS  %s  %s\n', regimes{r}, labels{r});
    else
        fprintf(fid, 'FAIL  %s  %s\n', regimes{r}, labels{r});
    end
    fclose(fid);
end

fprintf('\n=== Smoke test complete — see %s ===\n', logfile);
