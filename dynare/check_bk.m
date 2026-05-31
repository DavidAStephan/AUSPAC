% check_bk.m — fast, committed Blanchard-Kahn / steady-state diagnostic for au_pac.mod
%
% Re-confirms model stability after any parameter or equation edit, and writes a
% terse report to check_bk_report.txt. Dynare prints its own BK verdict during the
% solve; this adds an explicit eigenvalue / jump-variable tally and steady-state check.
%
% Run:  cd dynare; run('check_bk.m')
%   or  /Applications/MATLAB_R2026a.app/bin/matlab -batch "cd dynare; run('check_bk.m')"

addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod                 % Dynare prints "Blanchard-Kahn conditions are satisfied" on success

ev     = oo_.dr.eigval;
n_exp  = sum(abs(ev) > 1 + 1e-9);  % explosive (modulus > 1) eigenvalues
maxss  = max(abs(oo_.steady_state));
% Authoritative BK signal: Dynare aborts the solve on a BK violation, so a populated,
% finite decision rule (oo_.dr.ghx) means the Blanchard-Kahn conditions were satisfied.
solved = isfield(oo_, 'dr') && isfield(oo_.dr, 'ghx') && ~isempty(oo_.dr.ghx) && all(isfinite(oo_.dr.ghx(:)));

lines = {};
lines{end+1} = sprintf('========== au_pac BK / steady-state diagnostic ==========');
lines{end+1} = sprintf('Dynare %s', dynare_version);
if solved
    lines{end+1} = sprintf('Decision rule solved: YES  ->  Blanchard-Kahn SATISFIED');
else
    lines{end+1} = sprintf('Decision rule solved: NO   ->  *** BK / SOLVE FAILED ***');
end
lines{end+1} = sprintf('explosive eigenvalues (|.|>1): %d', n_exp);
if isfield(oo_.dr, 'edim'), lines{end+1} = sprintf('oo_.dr.edim (explosive-subspace dim): %d', oo_.dr.edim); end
lines{end+1} = sprintf('largest |eig| = %.5f', max(abs(ev)));
lines{end+1} = sprintf('max|steady_state| = %.3e (gap/deviation model -> expect ~0)', maxss);
lines{end+1} = sprintf('=========================================================');

txt = strjoin(lines, '\n');
fprintf('\n%s\n', txt);
fid = fopen('check_bk_report.txt', 'w');
fprintf(fid, '%s\n', txt);
fclose(fid);
fprintf('Wrote check_bk_report.txt\n');
