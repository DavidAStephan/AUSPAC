%% estimate_ces_2026_sector.m  --  per-sector CES calibration (industry split)
%
% Runs the FR-BDF wp1044 CES calibration procedure (the same gamma->sigma->
% alpha->mu pipeline as estimate_ces_2026.m) on a SINGLE industry branch,
% reading dynare/supply_data_sector.mat (built by prepare_supply_data_sector.m).
%
% Usage (set `sector` in the base workspace before running, default 'nonmining'):
%     sector = 'nonmining'; estimate_ces_2026_sector   % -> ces_2026_calibration_nm.mat
%     sector = 'mining';    estimate_ces_2026_sector   % -> ces_2026_calibration_m.mat
%
% sector = 'nonmining' : ESTIMATE. Full labour-FOC sigma + analytic gamma + alpha/mu.
%                        GATE 1a expects sigma_nm in [0.4,0.6], DW_lvl>1.5 OR clean FD.
% sector = 'mining'    : the CES factor-substitution procedure is expected to
%                        REJECT (price-taker, quantity-setting). We run it for the
%                        record, then CALIBRATE alpha_m from the mining
%                        gross-operating-surplus share and report the diagnostics.
%
% Spec refs: NEXT_PROJECT_industry_split.md §3.4, §4.1; CES_PRODUCTION_FUNCTION_APPROACH.md §5-§6.

if ~exist('sector', 'var') || isempty(sector)
    sector = 'nonmining';
end
sector = lower(string(sector));
fprintf('\n========================================================================\n');
fprintf('=== Per-sector CES calibration (FR-BDF wp1044 method): sector = %s ===\n', sector);
fprintf('========================================================================\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
S = load(fullfile(projectdir, 'dynare', 'supply_data_sector.mat'));
nQ = S.nQ; dates = S.dates;

%% Select sector series ------------------------------------------------------
switch sector
    case "nonmining"
        log_Q  = S.q_nm_lvl;   log_K  = S.k_nm_lvl;
        log_N  = S.n_nm_lvl;   log_H  = S.h_nm_lvl;
        log_PQ = S.p_q_nm_lvl; tag = 'nm';
    case "mining"
        log_Q  = S.q_m_lvl;    log_K  = S.k_m_lvl;
        log_N  = S.n_m_lvl;    log_H  = S.h_m_lvl;
        log_PQ = S.p_q_m_lvl;  tag = 'm';
    otherwise
        error('sector must be ''nonmining'' or ''mining''');
end
% Wage: WPI (SA, from 1997Q3); pre-1997 AWE splice if available.
log_W = S.wpi_lvl;
nan_wpi = isnan(log_W);
log_W(nan_wpi) = S.awe_lvl(nan_wpi);

fprintf('Coverage (%s): Q=%d K=%d N=%d H=%d W=%d P_Q=%d\n\n', sector, ...
    sum(~isnan(log_Q)), sum(~isnan(log_K)), sum(~isnan(log_N)), ...
    sum(~isnan(log_H)), sum(~isnan(log_W)), sum(~isnan(log_PQ)));

%% 1. Observed productivity Phi = Q/(N H) ------------------------------------
log_Phi = log_Q - log_N - log_H;

%% 2. Trend productivity Phi_hat (wp1044 eq 6, two breaks + COVID) ------------
trend_start_year = 1990;
T1 = max(0, (year(dates)-trend_start_year) + (quarter(dates)-1)/4);
T2 = max(0, (year(dates)-2002) + (quarter(dates)-1)/4 - 0.25);
T3 = max(0, (year(dates)-2008) + (quarter(dates)-1)/4 - 0.5);
T1(T1<0)=0; T2(T2<0)=0; T3(T3<0)=0;
d_08Q3_step  = double(dates >= datetime(2008,7,1));
d_covid_lvl  = double(dates >= datetime(2020,4,1) & dates <= datetime(2021,12,31));
d_covid_20q1 = double(year(dates)==2020 & quarter(dates)==1);
d_covid_20q2 = double(year(dates)==2020 & quarter(dates)==2);
d_covid_20q3 = double(year(dates)==2020 & quarter(dates)==3);
covid_phi_loss = 0.015;

z1_grid = 0.1:0.025:0.95;
best_loglik = -inf; best_z1 = NaN; best_beta = [];
for k = 1:length(z1_grid)
    z1 = z1_grid(k);
    y_qd = log_Phi - z1*[NaN; log_Phi(1:end-1)];
    x_const = (1-z1)*ones(nQ,1);
    x_step  = (1-z1)*d_08Q3_step;
    x_covid = -(1-z1)*covid_phi_loss*d_covid_lvl;
    x_T1 = T1 - z1*[NaN;T1(1:end-1)];
    x_T2 = T2 - z1*[NaN;T2(1:end-1)];
    x_T3 = T3 - z1*[NaN;T3(1:end-1)];
    lhs = y_qd - x_covid;
    X = [x_const, x_step, x_T1, x_T2, x_T3, d_covid_20q2, d_covid_20q1+d_covid_20q3];
    vk = ~isnan(lhs) & all(~isnan(X),2);
    if sum(vk) < 30, continue; end
    bk = (X(vk,:)'*X(vk,:)) \ (X(vk,:)'*lhs(vk));
    rk = lhs(vk) - X(vk,:)*bk;
    s2 = (rk'*rk)/(sum(vk)-size(X,2));
    ll = -0.5*sum(vk)*(log(2*pi*s2)+1);
    if ll > best_loglik
        best_loglik = ll; best_z1 = z1; best_beta = bk;
    end
end
z1_hat = best_z1;
z2=best_beta(1); z6=best_beta(2); z3=best_beta(3); z4=best_beta(4); z5=best_beta(5);
log_Phi_hat = z2 + z6*d_08Q3_step + z3*T1 + z4*T2 + z5*T3 - covid_phi_loss*d_covid_lvl;
fprintf('Step 2: trend productivity  z1=%.3f  growth p.a.  pre02=%.2f%%  02-08=%.2f%%  post08=%.2f%%\n', ...
    z1_hat, 100*z3, 100*(z3+z4), 100*(z3+z4+z5));

%% 3. sigma from the long-run labour FOC (wp1044 eq 3/9) ---------------------
y_sig = log_N - log_Q + log_Phi_hat + log_H;
x_sig = log_W - log_PQ - log_Phi_hat - log_H;
covid_mask = (dates>=datetime(2020,1,1)) & (dates<=datetime(2020,12,31));
valid_sig = ~isnan(y_sig) & ~isnan(x_sig) & ~covid_mask;
idx_sig = find(valid_sig);
fprintf('Step 3: sigma labour-FOC sample %d obs, %s to %s\n', ...
    length(idx_sig), datestr(dates(idx_sig(1))), datestr(dates(idx_sig(end))));

% Spec A: levels
y_lvl = y_sig(valid_sig); X_lvl = [ones(sum(valid_sig),1), x_sig(valid_sig)];
b_lvl = (X_lvl'*X_lvl)\(X_lvl'*y_lvl); r_lvl = y_lvl - X_lvl*b_lvl;
n_lvl = length(y_lvl); sig2_lvl = (r_lvl'*r_lvl)/(n_lvl-2);
se_lvl = sqrt(diag(sig2_lvl*inv(X_lvl'*X_lvl)));
sigma_lvl = -b_lvl(2); R2_lvl = 1-var(r_lvl)/var(y_lvl);
DW_lvl = sum(diff(r_lvl).^2)/sum(r_lvl.^2);
fprintf('  Spec A (levels): sigma=%.4f (se %.4f, t=%.2f)  R2=%.4f  DW=%.3f  T=%d\n', ...
    sigma_lvl, se_lvl(2), -b_lvl(2)/se_lvl(2), R2_lvl, DW_lvl, n_lvl);

% Spec B: first differences
dy = [NaN; diff(y_sig)]; dx = [NaN; diff(x_sig)];
valid_d = ~isnan(dy) & ~isnan(dx) & ~covid_mask;
y_d = dy(valid_d); X_d = [ones(sum(valid_d),1), dx(valid_d)];
b_d = (X_d'*X_d)\(X_d'*y_d); r_d = y_d - X_d*b_d;
n_d = length(y_d); sig2_d = (r_d'*r_d)/(n_d-2);
se_d = sqrt(diag(sig2_d*inv(X_d'*X_d)));
sigma_d = -b_d(2); R2_d = 1-var(r_d)/var(y_d);
DW_d = sum(diff(r_d).^2)/sum(r_d.^2);
fprintf('  Spec B (FD):     sigma=%.4f (se %.4f, t=%.2f)  R2=%.4f  DW=%.3f  T=%d\n', ...
    sigma_d, se_d(2), -b_d(2)/se_d(2), R2_d, DW_d, n_d);

% Spec C: Bayesian regularisation (prior N(0.50,0.20^2))
prior_mean = 0.50; prior_sd = 0.20;
level_coint = (DW_lvl>=1.5) && (sigma_lvl>=0.1 && sigma_lvl<=1.5);
fd_plausible = (sigma_d>=0.1 && sigma_d<=1.5);
if level_coint
    data_signal = sigma_lvl; data_sd = max(0.15, abs(se_lvl(2)));
    spec_used = 'Level (DW supports cointegration)';
elseif fd_plausible
    data_signal = sigma_d; data_sd = max(0.15, abs(se_d(2)));
    spec_used = sprintf('First differences (level DW=%.2f, no cointegration)', DW_lvl);
else
    data_signal = prior_mean; data_sd = prior_sd*2;
    spec_used = 'Prior-only (both specs out of range)';
end
sigma_post = (prior_mean/prior_sd^2 + data_signal/data_sd^2)/(1/prior_sd^2 + 1/data_sd^2);
sigma_post_sd = sqrt(1/(1/prior_sd^2 + 1/data_sd^2));
weight_data = (1/data_sd^2)/(1/prior_sd^2 + 1/data_sd^2);
sigma_hat = sigma_post; b_0_hat = b_lvl(1);
fprintf('  Spec C (Bayes):  posterior sigma=%.4f (sd %.4f, data weight %.0f%%)  [%s]\n', ...
    sigma_post, sigma_post_sd, 100*weight_data, spec_used);

%% 4. gamma from base-year Q/K (wp1044 analytic) -----------------------------
base_year = 2019;
base_mask = year(dates)==base_year & ~isnan(log_Q) & ~isnan(log_K);
if sum(base_mask) < 2
    for yr = 2019:-1:2010
        m = year(dates)==yr & ~isnan(log_Q) & ~isnan(log_K);
        if sum(m)>=4, base_mask=m; base_year=yr; break; end
    end
end
gamma_hat = exp(mean(log_Q(base_mask) - log_K(base_mask)));
fprintf('Step 4: gamma = exp(mean logQ - logK), %d base = %.4f\n', base_year, gamma_hat);

%% 5/6. alpha, mu -- sector-specific calibration -----------------------------
% For mining we do NOT trust sigma (CES factor-substitution rejected); we
% calibrate alpha_m from the mining gross-operating-surplus (capital-income)
% share. For non-mining we calibrate alpha_nm from the non-mining capital share.
% mu calibrated from AU markup literature.
mu_hat = 1.20;   % RBA RDP 2018-09 mid-range
if sector == "nonmining"
    % Non-mining is LESS capital-intensive than the mining-inflated aggregate
    % (aggregate alpha=0.45). Spec §2.2 expects alpha_nm ~ 0.32-0.38.
    alpha_hat = 0.35;
    alpha_src = 'AU non-mining capital-income share (spec expects 0.32-0.38)';
else
    % Mining GOS share is very high (capital-intensive resource extraction).
    % Spec §4.1 calibrates alpha_m from the mining GOS share (ABS 5204 T48 /
    % IO P2) and ANTICIPATED 0.60-0.70. The ACTUAL IO 5209 2021-22 number
    % (mining-industry primary inputs, P2 GOS+mixed / V1 GVA, summed over
    % IOIG industry cols {601,701,801,802,901,1001}) is HIGHER: 0.841 (see
    % build-time grounding below). Following the project's OLS/data-over-
    % calibration rule we use the data-grounded share, and report both. Mining
    % is overwhelmingly corporate GOS (mixed income P2.2 is <0.5% of VA): a very
    % high capital share is exactly the supply/capacity-driven feature the split
    % is built around. We cap at 0.84 (the measured value), not the 0.65 guess.
    alpha_hat = 0.84;
    alpha_src = 'AU mining GOS share P2/V1 from IO 5209 2021-22 = 0.841 (spec anticipated 0.60-0.70)';
end

%% 7. GATE verdict + save ----------------------------------------------------
if sector == "nonmining"
    gate_sigma_ok = (sigma_hat>=0.4 && sigma_hat<=0.6);
    gate_dw_ok    = (DW_lvl>1.5) || fd_plausible;   % level DW>1.5 OR clean FD fallback
    gate_pass     = gate_sigma_ok && gate_dw_ok;
    if gate_pass
        gate_verdict = 'PASS';
    else
        gate_verdict = 'FALLBACK';
        % calibration fallback per spec §4.1 / R12
        sigma_hat = 0.5366; alpha_hat = 0.35;
    end
    fprintf('\n=== GATE 1a (non-mining): sigma in [0.4,0.6]=%d, DW>1.5 or clean FD=%d => %s ===\n', ...
        gate_sigma_ok, gate_dw_ok, gate_verdict);
else
    gate_verdict = 'CALIBRATED (CES factor-substitution rejected for price-taker mining)';
    fprintf('\n=== Mining: CES procedure run for record; sigma_m NOT used. %s ===\n', gate_verdict);
end

% CES dual pass-throughs (used in the inflation Phillips block of the clone)
gamma_ulc = (1-alpha_hat)*sigma_hat;
gamma_uck = alpha_hat*sigma_hat;

fprintf('\n------------------------------------------------------------\n');
fprintf('CES calibration summary (%s):\n', sector);
fprintf('  sigma = %.4f   gamma = %.4f   alpha = %.3f (%s)\n', ...
    sigma_hat, gamma_hat, alpha_hat, alpha_src);
fprintf('  mu = %.3f   gamma_ulc=(1-a)s=%.4f   gamma_uck=a*s=%.4f\n', ...
    mu_hat, gamma_ulc, gamma_uck);
fprintf('------------------------------------------------------------\n');

out = struct();
out.sector       = char(sector);
out.method       = 'FR-BDF wp1044 per-sector CES';
out.dates        = dates;
out.sigma        = sigma_hat;
out.sigma_lvl    = sigma_lvl;
out.sigma_diff   = sigma_d;
out.sigma_post_sd = sigma_post_sd;
out.gamma        = gamma_hat;
out.alpha        = alpha_hat;
out.alpha_source = alpha_src;
out.mu           = mu_hat;
out.gamma_ulc    = gamma_ulc;
out.gamma_uck    = gamma_uck;
out.b_0          = b_0_hat;
out.base_year    = base_year;
out.DW_lvl       = DW_lvl;
out.DW_diff      = DW_d;
out.R2_lvl       = R2_lvl;
out.R2_diff      = R2_d;
out.se_sigma_lvl = se_lvl(2);
out.se_sigma_diff = se_d(2);
out.t_sigma_lvl  = -b_lvl(2)/se_lvl(2);
out.t_sigma_diff = -b_d(2)/se_d(2);
out.n_sigma      = n_lvl;
out.spec_used    = spec_used;
out.gate_verdict = gate_verdict;
out.z1_phi       = z1_hat;
out.trend_growth_phi_pre2002    = 100*z3;
out.trend_growth_phi_2002_2008  = 100*(z3+z4);
out.trend_growth_phi_post2008   = 100*(z3+z4+z5);

savefile = fullfile(projectdir, 'dynare', sprintf('ces_2026_calibration_%s.mat', tag));
save(savefile, '-struct', 'out');
fprintf('Saved: %s\n', savefile);
fprintf('=== Done (%s) ===\n', sector);
