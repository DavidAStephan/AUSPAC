%% forward_guidance.m — Forward Guidance Puzzle Test (FR-BDF Section 6.3)
%
% Tests whether AU-PAC suffers from the forward guidance puzzle.
%
% Method: Superposition at first order. An N-quarter rate cut =
% N individual 1-period shocks superposed. Peak effects should
% grow linearly (no puzzle) not exponentially (puzzle).
%
% Compares 3 models (all solved by Dynare):
%   1. Standard NK (3 equations — shows the puzzle)
%   2. Discounted NK (McKay et al. 2017 — partial fix)
%   3. AU-PAC (131 equations — should show no puzzle)

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

fprintf('================================================================\n');
fprintf('  Forward Guidance Puzzle Test\n');
fprintf('  FR-BDF Section 6.3 Replication\n');
fprintf('================================================================\n\n');

%% Step 1: Run standard NK model
fprintf('--- Running standard NK model ---\n');
dynare nk_simple noclearall nograph;
irf_x_nk = oo_.irfs.x_eps_i;
irf_pi_nk = oo_.irfs.pi_eps_i;
T_nk = length(irf_x_nk);
fprintf('  NK: %d eigenvalues > 1\n', sum(abs(oo_.dr.eigval) > 1));
clear M_ oo_ options_

%% Step 2: Run discounted NK model
fprintf('--- Running discounted NK model ---\n');
dynare nk_discounted noclearall nograph;
irf_x_disc = oo_.irfs.x_eps_i;
irf_pi_disc = oo_.irfs.pi_eps_i;
fprintf('  Discounted NK: %d eigenvalues > 1\n', sum(abs(oo_.dr.eigval) > 1));
clear M_ oo_ options_

%% Step 3: Run AU-PAC model
fprintf('--- Running AU-PAC model ---\n');
dynare au_pac noclearall nograph;
irf_y_aupac = oo_.irfs.yhat_au_eps_i;
irf_pi_aupac = oo_.irfs.pi_au_eps_i;
T = length(irf_y_aupac);
fprintf('  AU-PAC: %d eigenvalues > 1, T=%d\n\n', sum(abs(oo_.dr.eigval) > 1), T);

%% Step 4: Forward guidance — superposition
% For N-quarter rate cut, superpose N shifted single-period IRFs
max_N = 8;

peak_y_nk = zeros(max_N, 1);
peak_y_disc = zeros(max_N, 1);
peak_y_aupac = zeros(max_N, 1);
peak_pi_nk = zeros(max_N, 1);
peak_pi_disc = zeros(max_N, 1);
peak_pi_aupac = zeros(max_N, 1);

for N = 1:max_N
    % Standard NK
    y_sup = zeros(T_nk + N, 1);
    pi_sup = zeros(T_nk + N, 1);
    for k = 0:N-1
        y_sup(k+1:k+T_nk) = y_sup(k+1:k+T_nk) + irf_x_nk(:);
        pi_sup(k+1:k+T_nk) = pi_sup(k+1:k+T_nk) + irf_pi_nk(:);
    end
    peak_y_nk(N) = max(abs(y_sup));
    peak_pi_nk(N) = max(abs(pi_sup));

    % Discounted NK
    y_sup = zeros(T_nk + N, 1);
    pi_sup = zeros(T_nk + N, 1);
    for k = 0:N-1
        y_sup(k+1:k+T_nk) = y_sup(k+1:k+T_nk) + irf_x_disc(:);
        pi_sup(k+1:k+T_nk) = pi_sup(k+1:k+T_nk) + irf_pi_disc(:);
    end
    peak_y_disc(N) = max(abs(y_sup));
    peak_pi_disc(N) = max(abs(pi_sup));

    % AU-PAC
    y_sup = zeros(T + N, 1);
    pi_sup = zeros(T + N, 1);
    for k = 0:N-1
        y_sup(k+1:k+T) = y_sup(k+1:k+T) + irf_y_aupac(:);
        pi_sup(k+1:k+T) = pi_sup(k+1:k+T) + irf_pi_aupac(:);
    end
    peak_y_aupac(N) = max(abs(y_sup));
    peak_pi_aupac(N) = max(abs(pi_sup));
end

%% Step 5: Normalize for comparability
% Scale all to N=1 = 1.0 for shape comparison
norm_y_nk = peak_y_nk / peak_y_nk(1);
norm_y_disc = peak_y_disc / peak_y_disc(1);
norm_y_aupac = peak_y_aupac / peak_y_aupac(1);

%% Step 6: Print results
fprintf('================================================================\n');
fprintf('  Peak GDP Response (absolute values)\n');
fprintf('================================================================\n');
fprintf('  %3s  %12s  %12s  %12s\n', 'N', 'Std NK', 'Disc NK', 'AU-PAC');
for N = 1:max_N
    fprintf('  %3d  %12.6f  %12.6f  %12.6f\n', N, peak_y_nk(N), peak_y_disc(N), peak_y_aupac(N));
end

fprintf('\n  Normalized peak GDP (N=1 baseline = 1.0):\n');
fprintf('  %3s  %8s  %8s  %8s  %8s\n', 'N', 'Std NK', 'Disc NK', 'AU-PAC', 'Linear');
for N = 1:max_N
    fprintf('  %3d  %8.2f  %8.2f  %8.2f  %8.2f\n', N, norm_y_nk(N), norm_y_disc(N), norm_y_aupac(N), N*1.0);
end

fprintf('\n  Amplification ratio (N=8 / N=1):\n');
fprintf('    Standard NK:   %5.2f  (linear would be 8.0)\n', norm_y_nk(8));
fprintf('    Discounted NK: %5.2f\n', norm_y_disc(8));
fprintf('    AU-PAC:        %5.2f\n', norm_y_aupac(8));

% Diagnosis
fprintf('\n  Diagnosis:\n');
if norm_y_nk(8) > 10
    fprintf('    Standard NK:   PUZZLE (ratio %.1f >> 8, explosive amplification)\n', norm_y_nk(8));
elseif norm_y_nk(8) > 8.5
    fprintf('    Standard NK:   Mild puzzle (ratio %.1f > 8)\n', norm_y_nk(8));
else
    fprintf('    Standard NK:   No puzzle (ratio %.1f ~ 8)\n', norm_y_nk(8));
end

if norm_y_aupac(8) > 10
    fprintf('    AU-PAC:        PUZZLE (ratio %.1f >> 8)\n', norm_y_aupac(8));
elseif abs(norm_y_aupac(8) - 8) < 2
    fprintf('    AU-PAC:        NO PUZZLE (ratio %.1f ~ linear)\n', norm_y_aupac(8));
else
    fprintf('    AU-PAC:        Sublinear (ratio %.1f < 8, concave scaling)\n', norm_y_aupac(8));
end

%% Step 7: Plot (replicating FR-BDF Figure 6.3.2)
fig = figure('Position', [50 50 1200 500], 'Visible', 'off');

% Left panel: absolute peak GDP
subplot(1,2,1);
yyaxis left
plot(1:max_N, peak_y_nk*100, 'g-d', 'LineWidth', 1.5, 'MarkerSize', 8); hold on;
plot(1:max_N, peak_y_disc*100, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 8);
ylabel('NK models (% x 100)');
yyaxis right
plot(1:max_N, peak_y_aupac*100, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
ylabel('AU-PAC (% x 100)');
xlabel('Duration of rate cut (quarters)');
title('Peak |GDP| effects');
legend('Nondiscounted NK', 'Discounted NK', 'AU-PAC (rhs)', 'Location', 'northwest');
grid on;

% Right panel: normalized (shape comparison)
subplot(1,2,2);
plot(1:max_N, norm_y_nk, 'g-d', 'LineWidth', 1.5, 'MarkerSize', 8); hold on;
plot(1:max_N, norm_y_disc, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 8);
plot(1:max_N, norm_y_aupac, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
plot(1:max_N, 1:max_N, 'k--', 'LineWidth', 1);
xlabel('Duration of rate cut (quarters)');
ylabel('Peak |GDP| / Peak at N=1');
title('Normalized scaling (linear = no puzzle)');
legend('Nondiscounted NK', 'Discounted NK', 'AU-PAC', 'Linear reference', 'Location', 'northwest');
grid on;
ylim([0 max(norm_y_nk(8), 10)*1.1]);

sgtitle('Forward Guidance Puzzle Test (FR-BDF Fig. 6.3.2)', 'FontSize', 13);
saveas(fig, 'forward_guidance_puzzle.png');
fprintf('\n  Saved: forward_guidance_puzzle.png\n');
close(fig);

fprintf('\n=== Forward guidance experiment complete ===\n');
