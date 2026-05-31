% validate_wave1.m — solve au_pac, confirm Blanchard-Kahn, and report the
% 100bp monetary (eps_i) IRF at the Q40 reporting window AND the Q200 level,
% so the potential-output hysteresis fix (long-run neutrality) is auditable.

addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod

% --- BK ---
ev     = oo_.dr.eigval;
n_exp  = sum(abs(ev) > 1 + 1e-9);
solved = isfield(oo_,'dr') && isfield(oo_.dr,'ghx') && ~isempty(oo_.dr.ghx) && all(isfinite(oo_.dr.ghx(:)));

% --- scale eps_i to a 100bp (0.25 quarterly) tightening ---
idx   = find(strcmp(M_.exo_names, 'eps_i'));
scale = 0.25 / sqrt(M_.Sigma_e(idx, idx));

vars = {'ln_Q','yhat_au','ln_N','ln_IH','dln_ih','ln_IB','dln_ib','pi_au','pi_w','i_10y','s_gap'};
H    = numel(oo_.irfs.([vars{1} '_eps_i']));

fid = fopen('validate_wave1_report.txt','w');
prn = @(varargin) fprintf(fid, varargin{:}) + fprintf(varargin{:});

prn('========== Wave 1 validation (100bp eps_i tightening) ==========\n');
prn('Dynare %s | IRF horizon = %d\n', dynare_version, H);
if solved, prn('Blanchard-Kahn: SATISFIED (%d explosive eig, max|eig|=%.5f)\n', n_exp, max(abs(ev)));
else,      prn('Blanchard-Kahn: *** FAILED ***\n'); end
prn('lambda_hyst = %.3f (0 => long-run neutral)\n', lambda_hyst);
prn('%-10s  %12s %6s  %12s   %12s\n','var','Q40-peak','qtr','Q40-level',sprintf('Q%d-level',H));
for k = 1:numel(vars)
    fn = [vars{k} '_eps_i'];
    if ~isfield(oo_.irfs, fn), continue; end
    x   = oo_.irfs.(fn) * scale;
    w   = x(1:min(40,H));
    [mn,qi] = min(w); [mx,qm] = max(w);
    if abs(mn) >= abs(mx), pk = mn; q = qi; else, pk = mx; q = qm; end
    prn('%-10s  %+12.5f %6d  %+12.5f   %+12.5f\n', vars{k}, pk, q, x(40), x(H));
end
prn('Long-run neutrality check: ln_Q and ln_N should return toward 0 at Q%d.\n', H);
prn('================================================================\n');
fclose(fid);
