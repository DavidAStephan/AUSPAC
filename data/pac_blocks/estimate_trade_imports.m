%% estimate_trade_imports.m — single-equation OLS for AU aggregate imports
%
% Model equation (au_pac.mod line 1344):
%   dln_m_ne_t = b0_m_ne · m_ne_gap_{t-1} + b1_m_ne · dln_m_ne_{t-1} + iad_t + eps
% where m_ne_gap = beta_m_ne · ln_d_iad - ln_m_level + gamma_m_ne · s_gap.
%
% Since 95% of imports are non-energy (w_m_ne=0.95), we estimate the aggregate
% imports OLS and use the result for the non-energy block. Energy block keeps
% wp1044 calibration (b0_m_e=0.11, b1_m_e=0.38, beta_m_e=1.0, gamma_m_e=-0.19).
%
% iad enters with unit elasticity per model equation; we compute iad_data from
% weighted final-demand growth and use it as a known offset.

clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

D = load(fullfile(projectdir, 'data', 'trade_price_data.mat'));
E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));

% wp1044 iad weights (from au_pac.mod lines 819-823)
w_iad_ne_c  = 0.193;
w_iad_ne_ib = 0.276;
w_iad_ne_ih = 0.161;
w_iad_ne_g  = 0.106;
w_iad_ne_x  = 0.337;

%% Align series — use vol_dates as master
qkey = @(d) year(d)*10 + ceil(month(d)/3);
master_dates = D.vol_dates;
T = numel(master_dates);
mk = qkey(master_dates);

dln_m = D.dln_m;
dln_x = D.dln_x;
dln_g = D.dln_g;
ln_m  = log(D.m_vol);

% est_data dln_c, dln_ib
est_start = M.meta.sample_start;
n_est     = numel(E.dln_c);
est_dates = est_start + calquarters(0:n_est-1);
ek = qkey(est_dates);

dln_c_full  = NaN(T,1);
dln_ib_full = NaN(T,1);
for t=1:T
    ix = find(ek==mk(t), 1);
    if ~isempty(ix)
        dln_c_full(t)  = E.dln_c(ix);
        dln_ib_full(t) = E.dln_ib(ix);
    end
end

% dln_ih: not in estimation_data; derive from ABS 5206 vol col 12 (Dwellings - Total)
% Use Private GFCF Dwellings Total directly from xlsx. Quickest: re-read.
T_vol = readtable(fullfile(projectdir,'data','abs_rba','abs_5206_vol.xlsx'), ...
                  'Sheet','Data1','VariableNamingRule','preserve');
% wp1044 cols: 13 = "Private ; GFCF - Dwellings - Total" (1-indexed in MATLAB)
% Earlier we saw col 39=Exports, col 40=Imports. Need to find dwellings.
% In the prior dump: col 11 = Dwellings - Total. Let's confirm.
ih_lvl_raw = T_vol{:, 12};  % "Private ; GFCF - Dwellings - Total ;"  (col 11 + 1 for date)
if iscell(ih_lvl_raw)
    ih_lvl = NaN(numel(ih_lvl_raw),1);
    for i=1:numel(ih_lvl_raw)
        v=ih_lvl_raw{i}; if isnumeric(v),ih_lvl(i)=v; elseif ischar(v)||isstring(v), ih_lvl(i)=str2double(v); end
    end
else
    ih_lvl = ih_lvl_raw;
end
mask = ~isnan(ih_lvl);
dln_ih_aligned = NaN(T,1);
% Use the same accumulated approach: index by vol_dates (same order)
ix_in_vol = find(~isnan(D.x_vol));
dln_ih_arr = [NaN; diff(log(ih_lvl(mask)))*100];
% Recover positions in full master
ih_dates_full = T_vol{:,1};
if iscell(ih_dates_full)
    dt = NaT(numel(ih_dates_full),1);
    for i=1:numel(ih_dates_full), v=ih_dates_full{i}; if ischar(v)||isstring(v), dt(i)=datetime(v); elseif isdatetime(v), dt(i)=v; end; end
    ih_dates_full = dt;
end
ih_dates_valid = ih_dates_full(mask);
ihk = qkey(ih_dates_valid);
for t=1:T
    ix = find(ihk==mk(t), 1);
    if ~isempty(ix), dln_ih_aligned(t) = dln_ih_arr(ix); end
end

%% Compute iad_data
iad_data = w_iad_ne_c * dln_c_full + w_iad_ne_ib * dln_ib_full + ...
           w_iad_ne_ih * dln_ih_aligned + w_iad_ne_g * dln_g + ...
           w_iad_ne_x * dln_x;

%% Compute ln_d_iad (cumulative) — required for the LR target
% Construction: ln_d_iad starts at 0 at first valid obs, accumulates iad_data
ln_d_iad = NaN(T,1);
first_valid = find(~isnan(iad_data),1);
if ~isempty(first_valid)
    ln_d_iad(first_valid) = 0;
    for t=first_valid+1:T
        if ~isnan(iad_data(t))
            ln_d_iad(t) = ln_d_iad(t-1) + iad_data(t)/100;  % iad in %, convert to log
        else
            ln_d_iad(t) = ln_d_iad(t-1);
        end
    end
end

% Center ln_m by HP trend (lambda=1600), scale to %
ln_m_trend = hp_filter(ln_m, 1600);
ln_m_centered = (ln_m - ln_m_trend) * 100;

% s_gap aligned
twi_k = qkey(D.q_twi_dates);
s_gap_full = NaN(T,1);
for t=1:T
    ix = find(twi_k==mk(t),1);
    if ~isempty(ix), s_gap_full(t) = D.s_gap_proxy(ix); end
end

%% OLS: (dln_m - iad_data) = const + a1*ln_m_centered(-1) + a2*ln_d_iad(-1)*100
%                          + a3*s_gap(-1) + a4*dln_m(-1) + eps
lag1 = @(x) [NaN; x(1:end-1)];

ln_d_iad_scaled = ln_d_iad * 100;     % put in same % scale as ln_m_centered
y = dln_m - iad_data;
X = [ones(T,1), ...
     lag1(ln_m_centered), ...
     lag1(ln_d_iad_scaled), ...
     lag1(s_gap_full), ...
     lag1(dln_m)];

valid = ~any(isnan([X, y]), 2);
fprintf('Imports OLS: %d obs valid out of %d\n', sum(valid), T);

[b, se, tstat, R2, ~, N] = ols_with_se(X(valid,:), y(valid));

names = {'(intercept)', 'ln_m_centered(-1)', 'ln_d_iad(-1) [%]', 's_gap(-1)', 'dln_m(-1)'};

fprintf('\nImports OLS (wp1044 import equation, aggregate)\n');
fprintf('Generated %s\n\n', datetime('now'));
fprintf('%-22s  %10s  %10s  %8s\n', 'regressor', 'estimate', 'se', 't');
for k=1:numel(names)
    fprintf('%-22s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf('R^2 = %.4f, N = %d\n', R2, N);

b0_m_hat    = -b(2);
beta_m_hat  = b(3) / b0_m_hat;   % units: ln_d_iad is in %, so beta_m is dimensionless
gamma_m_hat = b(4) / b0_m_hat;
b1_m_hat    = b(5);

fprintf('\nRecovered structural parameters (write to b0_m_ne, b1_m_ne, beta_m_ne, gamma_m_ne):\n');
fprintf('  b0_m    = %+8.4f  (ECM speed, wp1044 0.06)\n', b0_m_hat);
fprintf('  beta_m  = %+8.4f  (LR income elasticity, wp1044 1.5)\n', beta_m_hat);
fprintf('  gamma_m = %+8.4f  (LR RER elasticity, wp1044 -0.4)\n', gamma_m_hat);
fprintf('  b1_m    = %+8.4f  (AR(1), wp1044 0.23)\n', b1_m_hat);

%% Save
out.b = b; out.se = se; out.tstat = tstat; out.R2 = R2; out.N = N;
out.names = names;
out.b0_m = b0_m_hat; out.beta_m = beta_m_hat; out.gamma_m = gamma_m_hat; out.b1_m = b1_m_hat;
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_imports.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_imports.txt'), 'w');
fprintf(fid, 'Imports OLS (wp1044, aggregate; assigned to non-energy block)\n');
fprintf(fid, 'Generated %s\n\n', datetime('now'));
fprintf(fid, '%-22s  %10s  %10s  %8s\n', 'regressor', 'estimate', 'se', 't');
for k=1:numel(names)
    fprintf(fid, '%-22s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf(fid, 'R^2 = %.4f, N = %d\n\n', R2, N);
fprintf(fid, 'Recovered:\n  b0_m = %+8.4f\n  beta_m = %+8.4f\n  gamma_m = %+8.4f\n  b1_m = %+8.4f\n', b0_m_hat, beta_m_hat, gamma_m_hat, b1_m_hat);
fclose(fid);
fprintf('\nWrote results_imports.mat + .txt\n');

function trend = hp_filter(y, lambda)
    n = numel(y); valid = ~isnan(y);
    if sum(valid) < 4, trend = NaN(n,1); return; end
    yv = y(valid); m = numel(yv);
    I = speye(m);
    D = spdiags([ones(m,1), -2*ones(m,1), ones(m,1)], 0:2, m-2, m);
    A = I + lambda * (D' * D);
    tv = A \ yv;
    trend = NaN(n,1); trend(valid) = tv;
end
