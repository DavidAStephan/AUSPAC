function db = prepare_pac_dseries_hybrid(oo_smooth)
%% prepare_pac_dseries_hybrid.m
% Constructs a dseries using a HYBRID of Kalman-smoothed and recursive data:
%
%   - OBSERVED VARIABLES (LHS + regressors): from data (dln_c, yhat_au, i_gap, etc.)
%   - AUXILIARY GAP TARGETS (EC term): from Kalman smoother (c_hat, piQ_hat, etc.)
%   - BACKWARD CORRECTION TERMS (pv_X_aux): recursive construction (NOT smoothed)
%   - LEVEL ACCUMULATORS: from cumulated observed growth rates
%   - VAR STATE VARIABLES: from observed data (= y_gap_var, etc.)
%
% This avoids the over-identification problem where pure Kalman-smoothed
% pv_X_aux terms absorb all the signal, leaving PAC structural parameters
% unidentified.
%
% The key insight: the Kalman smoother gives model-consistent values for
% the UNOBSERVED auxiliary gaps (which can't be constructed from data alone),
% while the observed variables and recursive terms remain data-driven.
%
% INPUT:
%   oo_smooth  struct  oo_ from calib_smoother pass
%
% OUTPUT:
%   db  [dseries]  for pac.estimate.iterative_ols / pac.estimate.nls
%
% REQUIRES: M_ global structure (from dynare au_pac).

global M_

fprintf('=== Constructing HYBRID PAC dseries (smoothed targets + recursive corrections) ===\n');

get_param = @(name) M_.params(strcmp(name, M_.param_names));

sv = oo_smooth.SmoothedVariables;

%% 1. Load observed data (same as prepare_pac_dseries.m)
projectdir = fullfile(fileparts(mfilename('fullpath')), '..');
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
nQ = height(T_base);

base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
start_year = year(base_dates(1));
start_quarter = quarter(base_dates(1));

%% 2. Observed gap/growth variables (from data, NOT smoother)
yhat_au   = T_base.au_ygap;
pi_au     = T_base.au_pi;
i_au      = T_base.au_irate / 4;
yhat_us   = T_base.us_ygap;
pi_us     = T_base.us_pi;
ibar      = T_base.i_bar;
pibar_au  = T_base.pi_bar_au;
i_gap     = i_au - ibar;
pi_au_gap = pi_au - pibar_au;

u_rate    = T_ext.au_urate;
u_gap     = u_rate - mean(u_rate, 'omitnan');

cons      = T_ext.au_consumption;
dln_c     = [NaN; diff(log(cons))] * 100;
dln_c     = dln_c - mean(dln_c, 'omitnan');

ib        = T_ext.au_gfcf_nondwelling;
dln_ib    = [NaN; diff(log(ib))] * 100;
dln_ib    = dln_ib - mean(dln_ib, 'omitnan');

ih        = T_ext.au_gfcf_dwelling;
dln_ih    = [NaN; diff(log(ih))] * 100;
dln_ih    = dln_ih - mean(dln_ih, 'omitnan');

emp       = T_ext.au_employment;
dln_n     = [NaN; diff(log(emp))] * 100;
dln_n     = dln_n - mean(dln_n, 'omitnan');

piQ       = pi_au;
piQ       = piQ - mean(piQ, 'omitnan');

i_10y     = T_ext.au_i10 / 4;
pi_w      = T_ext.au_pi_w;

%% 2b. New PAC drivers: di_gap and ph_gap
% di_gap = first difference of i_gap (FR-BDF eq 61, consumption)
di_gap = [0; diff(i_gap)];

% ph_gap = housing price gap (model variable, from smoother or recursive)
% Constructed recursively from eq_dln_ph: dln_ph = rho_ph*dln_ph(-1) + alpha_ph_y*yhat + alpha_ph_r*i_gap(-1)
% then eq_ph_gap: ph_gap = 0.98*ph_gap(-1) + dln_ph
% Will be overwritten by smoother if available (section 5 below)
rho_ph_val = get_param('rho_ph');
alpha_ph_y_val = get_param('alpha_ph_y');
alpha_ph_r_val = get_param('alpha_ph_r');
dln_ph_rec = zeros(nQ, 1);
ph_gap_rec = zeros(nQ, 1);
for t = 2:nQ
    if ~isnan(yhat_au(t)) && ~isnan(i_gap(t-1))
        dln_ph_rec(t) = rho_ph_val * dln_ph_rec(t-1) + alpha_ph_y_val * yhat_au(t) + alpha_ph_r_val * i_gap(t-1);
    else
        dln_ph_rec(t) = rho_ph_val * dln_ph_rec(t-1);
    end
    ph_gap_rec(t) = 0.98 * ph_gap_rec(t-1) + dln_ph_rec(t);
end
ph_gap = ph_gap_rec;  % default; overwritten by smoother below if available

%% 2c. COVID pulse dummies
d_covid_crash  = zeros(nQ, 1);
d_covid_bounce = zeros(nQ, 1);
for t = 1:nQ
    dt = base_dates(t);
    if year(dt) == 2020 && quarter(dt) == 2
        d_covid_crash(t) = 1;
    elseif year(dt) == 2020 && quarter(dt) == 3
        d_covid_bounce(t) = 1;
    end
end
fprintf('  COVID dummies: crash at obs %d, bounce at obs %d\n', ...
    find(d_covid_crash), find(d_covid_bounce));

%% 3. Level accumulators (from cumulated observed growth rates)
ln_c_level  = cumsum_nan(dln_c);
ln_ib_level = cumsum_nan(dln_ib);
ln_ih_level = cumsum_nan(dln_ih);
ln_n_level  = cumsum_nan(dln_n);
pQ_level    = cumsum_nan(piQ);

% Auxiliary lag variables
dln_n_1  = [0; dln_n(1:end-1)];
dln_n_2  = [0; dln_n_1(1:end-1)];
dln_n_3  = [0; dln_n_2(1:end-1)];
dln_ib_1 = [0; dln_ib(1:end-1)];
dln_ih_1 = [0; dln_ih(1:end-1)];

%% 4. VAR state variables (from observed data)
y_gap_var   = yhat_au;
i_gap_var   = i_gap;
pi_gap_var  = pi_au_gap;
u_gap_var   = u_gap;
yhat_us_var = yhat_us;

%% 5. AUXILIARY GAP TARGETS — from Kalman smoother
% These are the key variables that benefit from model-consistent smoothing.
% The EC terms (e.g., b0_c*(c_hat(-1) - ln_c_level(-1))) depend on the
% unobserved gap targets. The smoother gives better estimates than
% recursive construction.
%
% Map smoother T to data T: smoother has fewer obs (starts later)
sv_T = length(sv.yhat_au);
% Identify where smoother data maps to in the full sample
% smoother data corresponds to the valid sample from prepare_smoother_data
valid = ~isnan(yhat_au) & ~isnan(pi_au) & ~isnan(i_au) & ...
        ~isnan(yhat_us) & ~isnan(pi_us) & ...
        ~isnan(dln_c) & ~isnan(dln_ib) & ~isnan(dln_ih) & ~isnan(dln_n);
first_valid = find(valid, 1, 'first');
last_valid  = find(valid, 1, 'last');

% Initialize with zeros, then fill smoother range
piQ_hat       = zeros(nQ, 1);
n_hat         = zeros(nQ, 1);
yh_ratio_hat  = zeros(nQ, 1);
c_hat         = zeros(nQ, 1);
ib_hat        = zeros(nQ, 1);
rKB_hat       = zeros(nQ, 1);
ih_hat        = zeros(nQ, 1);

sv_idx = first_valid:last_valid;
if length(sv_idx) == sv_T
    piQ_hat(sv_idx)      = sv.piQ_hat;
    n_hat(sv_idx)        = sv.n_hat;
    yh_ratio_hat(sv_idx) = sv.yh_ratio_hat;
    c_hat(sv_idx)        = sv.c_hat;
    ib_hat(sv_idx)       = sv.ib_hat;
    rKB_hat(sv_idx)      = sv.rKB_hat;
    ih_hat(sv_idx)       = sv.ih_hat;
    % Override ph_gap with smoother if available
    if isfield(sv, 'ph_gap')
        ph_gap(sv_idx) = sv.ph_gap;
        fprintf('  ph_gap: using Kalman-smoothed values\n');
    else
        fprintf('  ph_gap: smoother field not found, using recursive construction\n');
    end
    fprintf('  Smoothed auxiliary targets mapped: obs %d-%d (%d quarters)\n', ...
        first_valid, last_valid, sv_T);
else
    fprintf('  WARNING: smoother length mismatch (%d vs %d), using recursive construction\n', ...
        length(sv_idx), sv_T);
    % Fall back to recursive construction
    [piQ_hat, n_hat, yh_ratio_hat, c_hat, ib_hat, rKB_hat, ih_hat] = ...
        build_recursive_aux(nQ, yhat_au, i_gap, pi_au_gap, u_gap, M_);
end

%% 6. BACKWARD CORRECTION TERMS (pv_X_aux) — recursive construction
% These are constructed recursively from observed data, NOT from the smoother.
% The smoother's pv_X_aux values absorb too much of the PAC equation's
% signal, making structural parameters unidentifiable.

rho_pQ_aux  = get_param('rho_pQ_aux');
a_pQ_y = get_param('a_pQ_y'); a_pQ_i = get_param('a_pQ_i');
a_pQ_pi = get_param('a_pQ_pi'); a_pQ_u = get_param('a_pQ_u');

rho_n_aux  = get_param('rho_n_aux');
a_n_y = get_param('a_n_y'); a_n_i = get_param('a_n_i');
a_n_pi = get_param('a_n_pi'); a_n_u = get_param('a_n_u');

rho_c_aux  = get_param('rho_c_aux');
a_c_y = get_param('a_c_y'); a_c_i = get_param('a_c_i');
a_c_pi = get_param('a_c_pi'); a_c_u = get_param('a_c_u');

rho_ib_aux = get_param('rho_ib_aux');
a_ib_y = get_param('a_ib_y'); a_ib_pi = get_param('a_ib_pi'); a_ib_u = get_param('a_ib_u');

rho_rKB_aux = get_param('rho_rKB_aux');
a_rKB_i = get_param('a_rKB_i');

rho_ih_aux = get_param('rho_ih_aux');
a_ih_y = get_param('a_ih_y'); a_ih_i = get_param('a_ih_i');
a_ih_pi = get_param('a_ih_pi'); a_ih_u = get_param('a_ih_u');

pv_piQ_aux = zeros(nQ, 1);
pv_n_aux   = zeros(nQ, 1);
pv_c_aux   = zeros(nQ, 1);
pv_ib_aux  = zeros(nQ, 1);
pv_rKB_aux = zeros(nQ, 1);
pv_ih_aux  = zeros(nQ, 1);

for t = 2:nQ
    if isnan(yhat_au(t-1)) || isnan(i_gap(t-1)) || isnan(pi_au_gap(t-1)) || isnan(u_gap(t-1))
        continue;
    end
    y_1 = yhat_au(t-1); i_1 = i_gap(t-1);
    p_1 = pi_au_gap(t-1); u_1 = u_gap(t-1);

    pv_piQ_aux(t) = rho_pQ_aux * pv_piQ_aux(t-1) + a_pQ_y*y_1 + a_pQ_i*i_1 + a_pQ_pi*p_1 + a_pQ_u*u_1;
    pv_n_aux(t)   = rho_n_aux  * pv_n_aux(t-1)   + a_n_y*y_1  + a_n_i*i_1  + a_n_pi*p_1  + a_n_u*u_1;
    pv_c_aux(t)   = rho_c_aux  * pv_c_aux(t-1)   + a_c_y*y_1  + a_c_i*i_1  + a_c_pi*p_1  + a_c_u*u_1;
    pv_ib_aux(t)  = rho_ib_aux * pv_ib_aux(t-1)  + a_ib_y*y_1 + a_ib_pi*p_1 + a_ib_u*u_1;
    pv_rKB_aux(t) = rho_rKB_aux* pv_rKB_aux(t-1) + a_rKB_i*i_1;
    pv_ih_aux(t)  = rho_ih_aux * pv_ih_aux(t-1)  + a_ih_y*y_1 + a_ih_i*i_1  + a_ih_pi*p_1 + a_ih_u*u_1;
end

%% 7. Print comparison: smoothed vs recursive auxiliary targets
fprintf('\n  --- Smoothed vs recursive auxiliary target comparison ---\n');
% Build recursive auxiliaries for comparison
[piQ_hat_rec, n_hat_rec, ~, c_hat_rec, ib_hat_rec, rKB_hat_rec, ih_hat_rec] = ...
    build_recursive_aux(nQ, yhat_au, i_gap, pi_au_gap, u_gap, M_);

comp_vars = {'piQ_hat', 'c_hat', 'ib_hat', 'ih_hat', 'n_hat', 'rKB_hat'};
comp_smooth = {piQ_hat, c_hat, ib_hat, ih_hat, n_hat, rKB_hat};
comp_recur  = {piQ_hat_rec, c_hat_rec, ib_hat_rec, ih_hat_rec, n_hat_rec, rKB_hat_rec};
for k = 1:length(comp_vars)
    s = comp_smooth{k}(sv_idx);
    r = comp_recur{k}(sv_idx);
    corr_sr = corrcoef(s, r);
    fprintf('  %-18s  corr=%.3f  smooth_std=%.4f  recur_std=%.4f  RMSD=%.4f\n', ...
        comp_vars{k}, corr_sr(1,2), std(s), std(r), sqrt(mean((s-r).^2)));
end

%% 8. Pack into dseries
start_date = dates(sprintf('%dQ%d', start_year, start_quarter));

varnames = { ...
    'yhat_au', 'pi_au', 'i_au', 'yhat_us', 'pi_us', ...
    'i_gap', 'pi_au_gap', 'u_gap', 'ibar', 'pibar_au', ...
    'y_gap_var', 'i_gap_var', 'pi_gap_var', 'u_gap_var', 'yhat_us_var', ...
    'piQ_hat', 'n_hat', 'yh_ratio_hat', 'c_hat', 'ib_hat', 'rKB_hat', 'ih_hat', ...
    'pv_piQ_aux', 'pv_n_aux', 'pv_c_aux', 'pv_ib_aux', 'pv_rKB_aux', 'pv_ih_aux', ...
    'di_gap', 'ph_gap', ...
    'pQ_level', 'ln_c_level', 'ln_ib_level', 'ln_ih_level', 'ln_n_level', ...
    'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'piQ', ...
    'dln_n_1', 'dln_n_2', 'dln_n_3', 'dln_ib_1', 'dln_ih_1', ...
    'pi_w', 'i_10y', ...
    'd_covid_crash', 'd_covid_bounce', ...
    'eps_pQ', 'eps_c', 'eps_ib', 'eps_ih', 'eps_n', ...
    'eps_var_y', 'eps_var_i', 'eps_var_pi', 'eps_var_u', 'eps_var_yus', ...
    'eps_var_pQ', 'eps_var_n', 'eps_var_yh', 'eps_var_c', ...
    'eps_var_ib', 'eps_var_rKB', 'eps_var_ih'};

data_mat = zeros(nQ, length(varnames));
for j = 1:length(varnames)
    vname = varnames{j};
    if startsWith(vname, 'eps_')
        data_mat(:, j) = NaN;
    else
        data_mat(:, j) = eval(vname);
    end
end

db = dseries(data_mat, start_date, varnames);

fprintf('\n  dseries: %d variables x %d observations\n', length(varnames), nQ);
fprintf('  Date range: %s to %s\n', char(db.dates(1)), char(db.dates(end)));
fprintf('=== Hybrid dseries construction complete ===\n');

end

%% Helper: cumulative sum with NaN handling
function y = cumsum_nan(x)
    y = zeros(size(x));
    for t = 1:length(x)
        if isnan(x(t))
            if t > 1, y(t) = y(t-1); end
        else
            if t > 1, y(t) = y(t-1) + x(t); else, y(t) = x(t); end
        end
    end
end

%% Helper: build recursive auxiliary gap variables
function [piQ_hat, n_hat, yh_hat, c_hat, ib_hat, rKB_hat, ih_hat] = ...
    build_recursive_aux(nQ, yhat_au, i_gap, pi_au_gap, u_gap, M_)

    get_p = @(name) M_.params(strcmp(name, M_.param_names));

    piQ_hat  = zeros(nQ, 1); n_hat    = zeros(nQ, 1);
    yh_hat   = zeros(nQ, 1); c_hat    = zeros(nQ, 1);
    ib_hat   = zeros(nQ, 1); rKB_hat  = zeros(nQ, 1);
    ih_hat   = zeros(nQ, 1);

    for t = 2:nQ
        if isnan(yhat_au(t-1)) || isnan(i_gap(t-1)) || isnan(pi_au_gap(t-1)) || isnan(u_gap(t-1))
            continue;
        end
        y1 = yhat_au(t-1); i1 = i_gap(t-1); p1 = pi_au_gap(t-1); u1 = u_gap(t-1);

        piQ_hat(t) = get_p('rho_pQ_aux')*piQ_hat(t-1) + get_p('a_pQ_y')*y1 + get_p('a_pQ_i')*i1 + get_p('a_pQ_pi')*p1 + get_p('a_pQ_u')*u1;
        n_hat(t)   = get_p('rho_n_aux')*n_hat(t-1) + get_p('a_n_y')*y1 + get_p('a_n_i')*i1 + get_p('a_n_pi')*p1 + get_p('a_n_u')*u1;
        yh_hat(t)  = get_p('rho_yh_aux')*yh_hat(t-1) + get_p('a_yh_y')*y1 + get_p('a_yh_u')*u1;
        c_hat(t)   = get_p('rho_c_aux')*c_hat(t-1) + get_p('a_c_y')*y1 + get_p('a_c_i')*i1 + get_p('a_c_pi')*p1 + get_p('a_c_u')*u1 + get_p('a_c_yh')*yh_hat(t-1);
        ib_hat(t)  = get_p('rho_ib_aux')*ib_hat(t-1) + get_p('a_ib_y')*y1 + get_p('a_ib_pi')*p1 + get_p('a_ib_u')*u1;
        rKB_hat(t) = get_p('rho_rKB_aux')*rKB_hat(t-1) + get_p('a_rKB_i')*i1;
        ih_hat(t)  = get_p('rho_ih_aux')*ih_hat(t-1) + get_p('a_ih_y')*y1 + get_p('a_ih_i')*i1 + get_p('a_ih_pi')*p1 + get_p('a_ih_u')*u1;
    end
end
