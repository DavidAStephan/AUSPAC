%% esat_model.m
% Builds the E-SAT structural VAR for Australia, computes the reduced form,
% checks stability, and generates impulse response functions.
%
% Based on Section 3.1.1 of Banque de France WP #736 (Lemoine et al., 2019),
% adapted for Australia (replacing France) with US (replacing euro area).
%
% Structural form:  A * Z_t = B * Z_{t-1} + eps_t
% Reduced form:     Z_t = H * Z_{t-1} + eta_t,   H = A^{-1} * B
%
% State vector (9x1):
%   Z = [1, yhat_AU, i_AU, pi_AU, yhat_US, pi_US, ibar, pibar_AU, pibar_US]
%         1    2       3      4       5       6      7       8         9
%
% Requires: params.mat (from estimate_esat.m)
% Output:   IRF plots

clear; clc;
fprintf('=== E-SAT Australia: Model & Impulse Responses ===\n\n');

outdir = fileparts(mfilename('fullpath'));
if isempty(outdir), outdir = pwd; end

%% Load parameters
paramfile = fullfile(outdir, 'params.mat');
if exist(paramfile, 'file')
    load(paramfile, 'params');
    fprintf('Loaded estimated parameters from params.mat\n');
    use_estimated = true;
else
    fprintf('params.mat not found. Using calibrated defaults.\n');
    use_estimated = false;
    % Calibrate using French model priors as starting point
    params = struct();
    params.delta       = 0.08;
    params.lambda_q    = 0.73;
    params.sigma_q     = 0.28;
    params.lambda_i    = 0.92;
    params.alpha_i     = 1.50;
    params.beta_i      = 0.50;
    params.lambda_pi   = 0.50;
    params.kappa_pi    = 0.08;
    params.lambda_q_us = 0.90;
    params.lambda_pi_us = 0.35;
    params.kappa_pi_us  = 0.04;
    params.lambda_ibar    = 0.985;
    params.lambda_pibar   = 0.93;
    params.lambda_pibar_us = 0.93;
    params.i_ss        = 4.5/4;   % quarterly
    params.pi_ss_au    = 2.5/4;
    params.pi_ss_us    = 2.0/4;
    params.i_bar_annual = 4.5;
    params.pi_bar_au_annual = 2.5;
    params.pi_bar_us_annual = 2.0;
end

%% Extract parameters (short names)
delta       = params.delta;
lam_q       = params.lambda_q;
sig_q       = params.sigma_q;
lam_i       = params.lambda_i;
alpha_i     = params.alpha_i;
beta_i      = params.beta_i;
lam_pi      = params.lambda_pi;
kap_pi      = params.kappa_pi;
lam_q_us    = params.lambda_q_us;
lam_pi_us   = params.lambda_pi_us;
kap_pi_us   = params.kappa_pi_us;
lam_ibar    = params.lambda_ibar;
lam_pibar   = params.lambda_pibar;
lam_pibar_us = params.lambda_pibar_us;
i_ss        = params.i_ss;          % quarterly
pi_ss_au    = params.pi_ss_au;      % quarterly
pi_ss_us    = params.pi_ss_us;      % quarterly

%% -----------------------------------------------------------------------
%  Build structural matrices A and B (9x9)
%  -----------------------------------------------------------------------
% State ordering: [1, yhat_AU, i, pi_AU, yhat_US, pi_US, ibar, pibar_AU, pibar_US]
%                  1    2      3    4       5        6      7      8         9

fprintf('\nBuilding structural matrices A and B...\n');

% --- A matrix ---
% Row 1: 1 = 1                             (intercept identity)
% Row 2: yhat_AU - delta*yhat_US = ...     (AU IS)
% Row 3: i - ibar = ...                    (Taylor rule: i - ibar)
% Row 4: pi_AU - pibar_AU = ...            (AU Phillips)
% Row 5: yhat_US = ...                     (US IS)
% Row 6: pi_US - pibar_US = ...            (US Phillips)
% Row 7: ibar = ...                        (LR rate anchor)
% Row 8: pibar_AU = ...                    (LR AU pi anchor)
% Row 9: pibar_US = ...                    (LR US pi anchor)

A = zeros(9,9);
A(1,1) = 1;
A(2,2) = 1;  A(2,5) = -delta;           % yhat_AU - delta*yhat_US
A(3,3) = 1;  A(3,7) = -1;               % i - ibar
A(4,4) = 1;  A(4,8) = -1;               % pi_AU - pibar_AU
A(5,5) = 1;                              % yhat_US
A(6,6) = 1;  A(6,9) = -1;               % pi_US - pibar_US
A(7,7) = 1;                              % ibar
A(8,8) = 1;                              % pibar_AU
A(9,9) = 1;                              % pibar_US

% --- B matrix ---
%       1              2(yhat_AU) 3(i)     4(pi_AU) 5(yhat_US) 6(pi_US) 7(ibar) 8(pibar_AU) 9(pibar_US)
B = zeros(9,9);

% Row 1: intercept
B(1,1) = 1;

% Row 2: AU IS curve
% RHS: lambda_q*yhat_AU(-1) - sigma_q*(i(-1) - pi_AU(-1) - ibar(-1) + pibar_AU(-1))
%     = lambda_q*yhat_AU(-1) - sigma_q*i(-1) + sigma_q*pi_AU(-1) + sigma_q*ibar(-1) - sigma_q*pibar_AU(-1)
B(2,2) = lam_q;          % yhat_AU(-1)
B(2,3) = -sig_q;         % i(-1)
B(2,4) = sig_q;          % pi_AU(-1)
B(2,7) = sig_q;          % ibar(-1)
B(2,8) = -sig_q;         % pibar_AU(-1)

% Row 3: Taylor rule (RBA) - KEY DIFFERENCE from French model
% RHS: lambda_i*(i(-1) - ibar(-1)) + (1-lam_i)*(alpha*pi_AU_gap(-1) + beta*yhat_AU(-1))
%     = lambda_i*i(-1) - lambda_i*ibar(-1)
%       + (1-lam_i)*alpha*pi_AU(-1) - (1-lam_i)*alpha*pibar_AU(-1)
%       + (1-lam_i)*beta*yhat_AU(-1)
B(3,2) = (1-lam_i)*beta_i;              % yhat_AU(-1)  <-- domestic, unlike French model
B(3,3) = lam_i;                          % i(-1)
B(3,4) = (1-lam_i)*alpha_i;             % pi_AU(-1)    <-- domestic, unlike French model
B(3,7) = -lam_i;                         % ibar(-1)
B(3,8) = -(1-lam_i)*alpha_i;            % pibar_AU(-1) <-- domestic, unlike French model

% Row 4: AU Phillips curve
% RHS: lambda_pi*(pi_AU(-1) - pibar_AU(-1)) + kappa_pi*yhat_AU(-1)
B(4,2) = kap_pi;         % yhat_AU(-1)
B(4,4) = lam_pi;         % pi_AU(-1)
B(4,8) = -lam_pi;        % pibar_AU(-1)

% Row 5: US IS curve (simplified AR1)
B(5,5) = lam_q_us;       % yhat_US(-1)

% Row 6: US Phillips curve
% RHS: lambda_pi_us*(pi_US(-1) - pibar_US(-1)) + kappa_pi_us*yhat_US(-1)
B(6,5) = kap_pi_us;      % yhat_US(-1)
B(6,6) = lam_pi_us;      % pi_US(-1)
B(6,9) = -lam_pi_us;     % pibar_US(-1)

% Row 7: LR interest rate anchor
B(7,1) = (1-lam_ibar)*i_ss;   % intercept: (1-lambda_ibar)*i_ss
B(7,7) = lam_ibar;             % ibar(-1)

% Row 8: LR AU inflation anchor
B(8,1) = (1-lam_pibar)*pi_ss_au;
B(8,8) = lam_pibar;

% Row 9: LR US inflation anchor
B(9,1) = (1-lam_pibar_us)*pi_ss_us;
B(9,9) = lam_pibar_us;

%% -----------------------------------------------------------------------
%  Compute reduced form
%  -----------------------------------------------------------------------
fprintf('Computing reduced-form matrix H = A\\B ...\n');
H = A \ B;

%% -----------------------------------------------------------------------
%  Stability check
%  -----------------------------------------------------------------------
eigenvalues = eig(H);
eigmods = abs(eigenvalues);

fprintf('\nEigenvalues of H:\n');
for k = 1:length(eigenvalues)
    ev = eigenvalues(k);
    if imag(ev) ~= 0
        fprintf('  %2d: %8.4f + %8.4fi  (|.| = %.4f)\n', k, real(ev), imag(ev), abs(ev));
    else
        fprintf('  %2d: %8.4f              (|.| = %.4f)\n', k, real(ev), abs(ev));
    end
end

% The intercept row produces a unit eigenvalue (1.0) by construction.
% Exclude it from the stability check.
dynamic_eigmods = eigmods(abs(eigmods - 1.0) > 1e-8);
max_eigmod = max(dynamic_eigmods);

fprintf('\nMax eigenvalue modulus (excl. intercept): %.6f\n', max_eigmod);
if max_eigmod < 1
    fprintf('  => STABLE (all dynamic eigenvalues inside unit circle)\n');
else
    fprintf('  => WARNING: UNSTABLE (eigenvalue(s) outside unit circle)\n');
end

%% -----------------------------------------------------------------------
%  Impulse Response Functions
%  -----------------------------------------------------------------------
nIRF = 100;  % quarters (25 years)

% Structural shock identification: eps_t enters via A^{-1}
% Shock to the k-th structural equation = column k of A^{-1}
Ainv = inv(A);

% Variable names for plotting
varnames = {'Intercept', 'AU Output Gap', 'Interest Rate', 'AU Inflation', ...
            'US Output Gap', 'US Inflation', 'LR Rate Anchor', ...
            'LR AU Infl. Anchor', 'LR US Infl. Anchor'};

%% --- IRF 1: Interest rate shock (+0.25pp quarterly = +1pp annualized) ---
fprintf('\n--- Computing IRF: Interest rate shock (+1pp annualized) ---\n');

shock_size_i = 0.25;  % quarterly (= 1pp annualized)
% Shock enters the Taylor rule (equation 3)
shock_vec_i = zeros(9,1);
shock_vec_i(3) = shock_size_i;

% The structural shock propagates as: eta_0 = A^{-1} * eps
% Then Z_1 = H*Z_0 + A^{-1}*eps (where Z_0 = steady state with intercept=1)
% For IRF, we track deviations from steady state: dZ_t
% dZ_0 = A^{-1} * shock_vec_i
% dZ_t = H * dZ_{t-1}  for t >= 1

irf_i = zeros(9, nIRF+1);
irf_i(:,1) = Ainv * shock_vec_i;  % impact (t=0)
for t = 2:(nIRF+1)
    irf_i(:,t) = H * irf_i(:,t-1);
end

% But the shock also persists through ibar (the LR anchor in E-SAT receives
% the shock via the Taylor rule equation and ibar process).
% Actually, in the E-SAT model, the interest rate shock enters through
% the Taylor rule residual. The persistence comes from lambda_i in the
% Taylor rule and lambda_ibar in the anchor equation.
% The reduced form H already captures all these dynamics.

%% --- IRF 2: US output gap shock (+1pp) ---
fprintf('--- Computing IRF: US output gap shock (+1pp) ---\n');

shock_size_us = 1.0;  % 1pp
shock_vec_us = zeros(9,1);
shock_vec_us(5) = shock_size_us;  % US IS equation

irf_us = zeros(9, nIRF+1);
irf_us(:,1) = Ainv * shock_vec_us;
for t = 2:(nIRF+1)
    irf_us(:,t) = H * irf_us(:,t-1);
end

%% -----------------------------------------------------------------------
%  Plot IRFs
%  -----------------------------------------------------------------------
quarters = 0:nIRF;

% --- Figure 1: Interest rate shock (analogous to paper's Figure 3.1.2) ---
figure('Name', 'IRF: Interest Rate Shock (+1pp annualized)', ...
       'Position', [50 50 1100 700]);

subplot(2,3,1);
plot(quarters, irf_i(3,:)*4, 'b-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('Interest rate (annualized)');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,2);
plot(quarters, irf_i(2,:), 'b-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('AU Output Gap');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,3);
plot(quarters, irf_i(4,:)*4, 'b-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('AU Inflation (annualized)');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,4);
plot(quarters, irf_i(5,:), 'b-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('US Output Gap');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,5);
plot(quarters, irf_i(6,:)*4, 'b-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('US Inflation (annualized)');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,6);
% Show the long-run interest rate anchor response
plot(quarters, irf_i(7,:)*4, 'b-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('LR Interest Rate Anchor (ann.)');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

sgtitle('E-SAT Australia: IRF to +1pp Interest Rate Shock', 'FontSize', 14);

% Save figure
saveas(gcf, fullfile(outdir, 'irf_interest_rate.png'));
fprintf('Saved: irf_interest_rate.png\n');

% --- Figure 2: US output gap shock (analogous to paper's Figure 3.1.3) ---
figure('Name', 'IRF: US Output Gap Shock (+1pp)', ...
       'Position', [100 100 1100 700]);

subplot(2,3,1);
plot(quarters, irf_us(5,:), 'r-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('US Output Gap');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,2);
plot(quarters, irf_us(2,:), 'r-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('AU Output Gap');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,3);
plot(quarters, irf_us(4,:)*4, 'r-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('AU Inflation (annualized)');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,4);
plot(quarters, irf_us(3,:)*4, 'r-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('Interest Rate (annualized)');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,5);
plot(quarters, irf_us(6,:)*4, 'r-', 'LineWidth', 1.5); hold on;
plot(quarters, zeros(size(quarters)), 'k--', 'LineWidth', 0.5);
title('US Inflation (annualized)');
ylabel('pp deviation'); xlabel('Quarters');
grid on;

subplot(2,3,6);
% Blank or additional diagnostic
text(0.5, 0.5, sprintf('Max |eig(H)| = %.4f\n\\delta = %.3f\n\\lambda_q = %.3f', ...
    max_eigmod, delta, lam_q), ...
    'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 11);
title('Model Diagnostics');
axis off;

sgtitle('E-SAT Australia: IRF to +1pp US Output Gap Shock', 'FontSize', 14);

saveas(gcf, fullfile(outdir, 'irf_us_output_gap.png'));
fprintf('Saved: irf_us_output_gap.png\n');

%% -----------------------------------------------------------------------
%  Print key model diagnostics
%  -----------------------------------------------------------------------
fprintf('\n=== Key Diagnostics ===\n');
fprintf('  Max eigenvalue modulus:        %.4f\n', max_eigmod);
fprintf('  AU Phillips slope (annual):    %.3f  [kappa/(1-lambda_pi)*4]\n', ...
    kap_pi / (1 - lam_pi) * 4);
fprintf('  Interest rate persistence:     %.3f\n', lam_i);
fprintf('  AU-US output co-movement:      %.3f\n', delta);

% Peak effects of interest rate shock
[min_ygap, idx_ygap] = min(irf_i(2,:));
[min_pi, idx_pi] = min(irf_i(4,:)*4);
fprintf('  IR shock -> AU output gap trough: %.3f pp at Q%d\n', min_ygap, idx_ygap-1);
fprintf('  IR shock -> AU inflation trough:  %.3f pp (ann.) at Q%d\n', min_pi, idx_pi-1);

% Peak effects of US output gap shock
[max_au_ygap, idx_au] = max(irf_us(2,:));
fprintf('  US shock -> AU output gap peak:   %.3f pp at Q%d\n', max_au_ygap, idx_au-1);

fprintf('\n=== E-SAT Model complete ===\n');
