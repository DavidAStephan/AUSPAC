%% forward_guidance.m — Forward Guidance Puzzle Test (FR-BDF Section 6.3)
%
% Tests whether AU-PAC suffers from the forward guidance puzzle.
% Method: superposition at first order. An N-quarter rate cut =
% N individual 1-period shocks superposed. Peak effects should grow
% linearly (no puzzle) not exponentially (puzzle).
%
% Compares 3 models (all solved by Dynare):
%   1. Standard NK     (nk_simple.mod)     — shows the puzzle
%   2. Discounted NK   (nk_discounted.mod) — partial fix
%   3. AU-PAC          (au_pac.mod)        — should show no puzzle
%
% Each Dynare run executes in its own clear workspace to avoid PAC state
% pollution between models.

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

max_N = 12;
fprintf('=== Forward Guidance Puzzle Test (N up to %d) ===\n\n', max_N);

%% Step 1: Run AU-PAC model (first, before any other dynare contaminates state)
fprintf('--- Running AU-PAC model ---\n');
dynare au_pac noclearall nograph;
irf_y_aupac = oo_.irfs.yhat_au_eps_i;
irf_pi_aupac = oo_.irfs.pi_au_eps_i;
T_aupac = length(irf_y_aupac);
n_fwd_aupac = sum(abs(oo_.dr.eigval) > 1);
fprintf('  AU-PAC: %d eigenvalues > 1, T=%d\n\n', n_fwd_aupac, T_aupac);

save('temp_aupac_irf.mat', 'irf_y_aupac', 'irf_pi_aupac', 'T_aupac', 'n_fwd_aupac');

%% Step 2: Run standard NK model
clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;

fprintf('--- Running standard NK model ---\n');
dynare nk_simple noclearall nograph;
irf_x_nk = oo_.irfs.x_eps_i;
irf_pi_nk = oo_.irfs.pi_eps_i;
T_nk = length(irf_x_nk);
fprintf('  NK: %d eigenvalues > 1\n\n', sum(abs(oo_.dr.eigval) > 1));

save('temp_nk_irf.mat', 'irf_x_nk', 'irf_pi_nk', 'T_nk');

%% Step 3: Run discounted NK model
clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;

fprintf('--- Running discounted NK model ---\n');
dynare nk_discounted noclearall nograph;
irf_x_disc = oo_.irfs.x_eps_i;
irf_pi_disc = oo_.irfs.pi_eps_i;
fprintf('  Discounted NK: %d eigenvalues > 1\n\n', sum(abs(oo_.dr.eigval) > 1));

%% Reload AU-PAC + NK IRFs
S1 = load('temp_aupac_irf.mat');
S2 = load('temp_nk_irf.mat');
irf_y_aupac = S1.irf_y_aupac; irf_pi_aupac = S1.irf_pi_aupac;
T_aupac = S1.T_aupac;
irf_x_nk = S2.irf_x_nk; irf_pi_nk = S2.irf_pi_nk;
T_nk = S2.T_nk;

%% Step 4: Forward guidance — superposition
peak_y_nk = zeros(max_N, 1);
peak_y_disc = zeros(max_N, 1);
peak_y_aupac = zeros(max_N, 1);
peak_pi_nk = zeros(max_N, 1);
peak_pi_disc = zeros(max_N, 1);
peak_pi_aupac = zeros(max_N, 1);

T = T_aupac;
for N = 1:max_N
    y_sup = zeros(T_nk + N, 1); pi_sup = zeros(T_nk + N, 1);
    for k = 0:N-1
        y_sup(k+1:k+T_nk) = y_sup(k+1:k+T_nk) + irf_x_nk(:);
        pi_sup(k+1:k+T_nk) = pi_sup(k+1:k+T_nk) + irf_pi_nk(:);
    end
    peak_y_nk(N) = max(abs(y_sup));
    peak_pi_nk(N) = max(abs(pi_sup));

    y_sup = zeros(T_nk + N, 1); pi_sup = zeros(T_nk + N, 1);
    for k = 0:N-1
        y_sup(k+1:k+T_nk) = y_sup(k+1:k+T_nk) + irf_x_disc(:);
        pi_sup(k+1:k+T_nk) = pi_sup(k+1:k+T_nk) + irf_pi_disc(:);
    end
    peak_y_disc(N) = max(abs(y_sup));
    peak_pi_disc(N) = max(abs(pi_sup));

    y_sup = zeros(T + N, 1); pi_sup = zeros(T + N, 1);
    for k = 0:N-1
        y_sup(k+1:k+T) = y_sup(k+1:k+T) + irf_y_aupac(:);
        pi_sup(k+1:k+T) = pi_sup(k+1:k+T) + irf_pi_aupac(:);
    end
    peak_y_aupac(N) = max(abs(y_sup));
    peak_pi_aupac(N) = max(abs(pi_sup));
end

%% Step 5: Normalize
norm_y_nk = peak_y_nk / peak_y_nk(1);
norm_y_disc = peak_y_disc / peak_y_disc(1);
norm_y_aupac = peak_y_aupac / peak_y_aupac(1);

%% Step 6: Print
fprintf('================================================================\n');
fprintf('  Peak GDP Response (absolute, max_N=%d)\n', max_N);
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

fprintf('\n  Amplification ratio (N=%d / N=1):\n', max_N);
fprintf('    Standard NK:   %5.2f  (linear would be %d.0)\n', norm_y_nk(max_N), max_N);
fprintf('    Discounted NK: %5.2f\n', norm_y_disc(max_N));
fprintf('    AU-PAC:        %5.2f\n', norm_y_aupac(max_N));

%% Step 7: Plot
fig = figure('Position', [50 50 1200 500], 'Visible', 'off');
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
ylim([0 max(norm_y_nk(max_N), max_N)*1.1]);

sgtitle(sprintf('Forward Guidance Puzzle Test (N up to %d, FR-BDF §6.3)', max_N), 'FontSize', 13);
saveas(fig, 'forward_guidance_puzzle.png');
fprintf('\n  Saved: forward_guidance_puzzle.png\n');
close(fig);

% Cleanup
delete temp_aupac_irf.mat temp_nk_irf.mat;
fprintf('\n=== Forward guidance test complete ===\n');
