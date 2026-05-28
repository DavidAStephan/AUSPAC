%% estimate_wage_phillips_constrained.m — wage Phillips OLS with structural
% constraint imposed for BK-stability.
%
% Model equation (au_pac.mod line 1180):
%   pi_w = lambda_w*pi_w(-1) + gamma_w*pi_c - kappa_w*pv_u_gap
%        + (1 - lambda_w - gamma_w)*pibar_au + (1 - lambda_w)*dln_prod + eps_w
%
% Long-run neutrality (pi_c=pibar, dln_prod_ss=0 → pi_w=pibar) is automatic
% for any (lambda_w, gamma_w). The BK problem is over-indexation: when
% gamma_w > 1, the wage-price spiral closes (pi_c responds to pi_w through
% the ULC channel, pi_w responds 1.59x to pi_c → eigenvalue outside unit
% circle).
%
% This script imposes the BK-stability constraint gamma_w + lambda_w <= 0.95
% as a hard upper bound (slightly < 1 to leave margin) AND lambda_w >= 0
% (positive persistence). It also forces the pibar coefficient to equal
% (1 - lambda_w - gamma_w) and the dln_prod coefficient to equal (1 - lambda_w),
% restricting the regression to the structural functional form.
%
% Reduced regression after imposing the structural form:
%   pi_w_centered = lambda_w*(pi_w(-1) - pibar) + gamma_w*(pi_c - pibar)
%                 + (1-lambda_w)*dln_prod - kappa_w*pv_u_gap + eps
% where pi_w_centered = pi_w - pibar.
%
% Algorithm: constrained QP (quadprog) with linear inequality
%   [1 1 0 0] [lambda_w; gamma_w; kappa_w; const] <= 0.95
%   [-1 0 0 0] ...                                <= 0
%   [0 -1 0 0] ...                                <= 0     (gamma_w >= 0)
%   [0 0 -1 0] ...                                <= 0     (kappa_w >= 0; Phillips sign)
% Bonus diagnostic: also report the value of the constraint at the optimum.

clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
L = load(fullfile(projectdir, 'data',   'l2_data_layer_v2.mat'));

T = numel(E.pi_w);
qkey = @(d) year(d)*10 + ceil(month(d)/3);
est_start = M.meta.sample_start;
est_dates = est_start + calquarters(0:T-1);
ek = qkey(est_dates);

pi_w = E.pi_w(:);
lk = qkey(L.dates);
pibar = NaN(T,1);
u_hat = NaN(T,1);
for t=1:T
    ix = find(lk==ek(t),1);
    if ~isempty(ix)
        pibar(t) = L.pi_au_trend(ix);
        u_hat(t) = L.u_hat(ix);
    end
end
pi_au_raw = E.pi_au(:) + pibar;        % undo gap-form for CPI
pi_c = pi_au_raw;

prod_lvl = S.q_total_lvl ./ S.n_total_lvl;
sdates = datetime(1990,1,1) + calquarters(0:numel(prod_lvl)-1);
sk = qkey(sdates);
dln_prod_arr = [NaN; diff(log(prod_lvl))*100];
dln_prod = NaN(T,1);
for t=1:T
    ix = find(sk==ek(t),1);
    if ~isempty(ix), dln_prod(t) = dln_prod_arr(ix); end
end

lag1 = @(x) [NaN; x(1:end-1)];

%% Restricted regression in structural form
% LHS: pi_w - pibar - dln_prod (= the gap that depends on lambda_w * (pi_w_lag-pibar-dln_prod)
% Actually let's not pre-shift dln_prod; restrict to:
%   pi_w - pibar = lambda_w * (pi_w(-1) - pibar) + gamma_w * (pi_c - pibar)
%                + (1 - lambda_w) * dln_prod - kappa_w * u_hat + eps
% Rearrange:
%   pi_w - pibar - dln_prod = lambda_w * (pi_w(-1) - pibar - dln_prod)
%                           + gamma_w * (pi_c - pibar)
%                           - kappa_w * u_hat + eps
% so LHS uses (pi_w - pibar - dln_prod), and pi_w_lag regressor is (pi_w(-1) - pibar - dln_prod).
y = pi_w - pibar - dln_prod;
X = [ lag1(pi_w - pibar - dln_prod), ...
      pi_c - pibar, ...
      -u_hat ];          % minus sign so coefficient = kappa_w (positive Phillips)

valid = ~any(isnan([X, y]),2);
Xv = X(valid,:); yv = y(valid);
N = sum(valid);
fprintf('Wage Phillips constrained OLS: %d obs valid (sample 1993Q3..2023Q3)\n', N);

%% Unconstrained baseline for comparison
b_ols = (Xv' * Xv) \ (Xv' * yv);
e_ols = yv - Xv*b_ols;
sigma2_ols = (e_ols'*e_ols)/(N - 3);
se_ols = sqrt(diag(sigma2_ols * inv(Xv'*Xv)));
fprintf('\nUnconstrained OLS (for reference):\n');
fprintf('  lambda_w = %+8.4f (se %.4f, t=%.2f)\n', b_ols(1), se_ols(1), b_ols(1)/se_ols(1));
fprintf('  gamma_w  = %+8.4f (se %.4f, t=%.2f)\n', b_ols(2), se_ols(2), b_ols(2)/se_ols(2));
fprintf('  kappa_w  = %+8.4f (se %.4f, t=%.2f)\n', b_ols(3), se_ols(3), b_ols(3)/se_ols(3));
fprintf('  gamma + lambda = %.4f (BK requires < 1)\n', b_ols(1)+b_ols(2));

%% Constrained QP
% min || X*b - y ||^2 = min (1/2) b' (X'X) b - (X'y)' b
% s.t. A*b <= b_ineq
H = Xv' * Xv;
f = -Xv' * yv;
% Constraints:
%   gamma_w + lambda_w <= 0.95  →  [1 1 0] b <= 0.95
%   -lambda_w <= 0              →  [-1 0 0] b <= 0   (lambda_w >= 0)
%   -gamma_w <= 0               →  [0 -1 0] b <= 0   (gamma_w >= 0)
%   -kappa_w <= 0               →  [0 0 -1] b <= 0   (kappa_w >= 0)
A_ineq = [1 1 0; -1 0 0; 0 -1 0; 0 0 -1];
b_ineq = [0.95; 0; 0; 0];

opts = optimoptions('quadprog','Display','off');
b_con = quadprog(H, f, A_ineq, b_ineq, [], [], [], [], b_ols, opts);

e_con = yv - Xv*b_con;
sigma2_con = (e_con'*e_con)/(N - 3);

% Note: classical SE doesn't apply when constraints bind. Report inactive
% directions' SE; active constraints have effective sd=0 (point identified).
active = abs(A_ineq*b_con - b_ineq) < 1e-6;
fprintf('\nConstrained QP (lambda_w+gamma_w <= 0.95, all coefs >= 0):\n');
fprintf('  lambda_w = %+8.4f\n', b_con(1));
fprintf('  gamma_w  = %+8.4f\n', b_con(2));
fprintf('  kappa_w  = %+8.4f\n', b_con(3));
fprintf('  gamma + lambda = %.4f\n', b_con(1)+b_con(2));
fprintf('  Active constraints: ');
cn = {'gamma+lambda<=0.95', 'lambda>=0', 'gamma>=0', 'kappa>=0'};
for k=1:numel(cn), if active(k), fprintf('[%s] ', cn{k}); end; end; fprintf('\n');

% R^2
tss = sum((yv - mean(yv)).^2);
R2_ols = 1 - sum(e_ols.^2)/tss;
R2_con = 1 - sum(e_con.^2)/tss;
fprintf('\nR² unconstrained: %.4f\n', R2_ols);
fprintf('R² constrained:   %.4f\n', R2_con);
fprintf('Loss from constraint: %.4f nats\n', N/2 * log(sum(e_con.^2)/sum(e_ols.^2)));

%% Save
out.b_unconstrained = b_ols;
out.b_constrained   = b_con;
out.N = N;
out.R2_unconstrained = R2_ols;
out.R2_constrained   = R2_con;
out.active_constraints = active;
out.lambda_w = b_con(1);
out.gamma_w  = b_con(2);
out.kappa_w  = b_con(3);
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_wage_phillips_constrained.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_wage_phillips_constrained.txt'), 'w');
fprintf(fid, 'Wage Phillips constrained OLS\nGenerated %s\nN=%d\n\n', datetime('now'), N);
fprintf(fid, 'Unconstrained:\n  lambda=%.4f gamma=%.4f kappa=%.4f sum=%.4f R²=%.4f\n', ...
        b_ols(1), b_ols(2), b_ols(3), b_ols(1)+b_ols(2), R2_ols);
fprintf(fid, 'Constrained (gamma+lambda<=0.95, all >= 0):\n  lambda=%.4f gamma=%.4f kappa=%.4f sum=%.4f R²=%.4f\n', ...
        b_con(1), b_con(2), b_con(3), b_con(1)+b_con(2), R2_con);
fprintf(fid, 'Active constraints: ');
for k=1:numel(cn), if active(k), fprintf(fid, '[%s] ', cn{k}); end; end; fprintf(fid, '\n');
fclose(fid);
fprintf('\nWrote results_wage_phillips_constrained.{mat,txt}\n');
