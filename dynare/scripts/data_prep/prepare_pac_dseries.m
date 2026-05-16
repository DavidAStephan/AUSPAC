function db = prepare_pac_dseries()
%% prepare_pac_dseries.m
% Constructs a Dynare dseries object containing ALL endogenous variables
% needed by the 5 PAC equations in au_pac.mod.
%
% Observed variables are loaded from CSV data files.
% Unobserved model variables (auxiliary gaps, backward corrections, level
% accumulators) are constructed RECURSIVELY from observed data using the
% calibrated parameter values in M_.params.
%
% This follows the ECB-Base (SemiStructDynareBasics) pattern where the
% dseries is built OUTSIDE Dynare's estimation() block and then passed
% to pac.estimate.iterative_ols or pac.estimate.nls.
%
% REQUIRES: M_ global structure (run dynare au_pac first).
%
% OUTPUT: db [dseries] with all variables needed for PAC estimation,
%         residuals set to NaN.

global M_

fprintf('=== Constructing PAC estimation dseries ===\n');

%% 1. Load observed data
projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');  % up to repo root (post-cleanup fix)
T_base = readtable(fullfile(projectdir, 'dataset.csv'));
T_ext  = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
nQ = height(T_base);

% Parse dates for dseries (need Dynare dates format)
base_dates = datetime(T_base.date, 'InputFormat', 'yyyy-MM-dd');
start_year = year(base_dates(1));
start_quarter = quarter(base_dates(1));

%% 2. Construct observed gap/growth variables
yhat_au   = T_base.au_ygap;                         % output gap (%)
pi_au     = T_base.au_pi;                            % CPI inflation (quarterly %)
i_au      = T_base.au_irate / 4;                     % policy rate (quarterly)
yhat_us   = T_base.us_ygap;                          % US output gap (%)
pi_us     = T_base.us_pi;                            % US inflation (quarterly %)
ibar      = T_base.i_bar;                            % neutral rate
pibar_au  = T_base.pi_bar_au;                        % inflation target

% Derived gaps
i_gap     = i_au - ibar;                             % interest rate gap
pi_au_gap = pi_au - pibar_au;                        % inflation gap

% Unemployment gap
u_rate    = T_ext.au_urate;
u_gap     = u_rate - mean(u_rate, 'omitnan');          % demeaned unemployment gap

% Consumption growth
cons      = T_ext.au_consumption;
dln_c     = [NaN; diff(log(cons))] * 100;
dln_c     = dln_c - mean(dln_c, 'omitnan');

% Business investment growth (non-dwelling)
ib        = T_ext.au_gfcf_nondwelling;
dln_ib    = [NaN; diff(log(ib))] * 100;
dln_ib    = dln_ib - mean(dln_ib, 'omitnan');

% Housing investment growth (dwelling)
ih        = T_ext.au_gfcf_dwelling;
dln_ih    = [NaN; diff(log(ih))] * 100;
dln_ih    = dln_ih - mean(dln_ih, 'omitnan');

% Employment growth
emp       = T_ext.au_employment;
dln_n     = [NaN; diff(log(emp))] * 100;
dln_n     = dln_n - mean(dln_n, 'omitnan');

% VA price inflation (proxy: GDP deflator)
piQ       = pi_au;  % gap model approximation
piQ       = piQ - mean(piQ, 'omitnan');

% 10-year rate
i_10y     = T_ext.au_i10 / 4;

% Wage inflation
pi_w      = T_ext.au_pi_w;

%% 2b. New PAC drivers: di_gap and ph_gap
di_gap = [0; diff(i_gap)];

% ph_gap: recursive from model equations (no observed housing price data)
get_param = @(name) M_.params(strcmp(name, M_.param_names));
rho_ph_val = get_param('rho_ph');
alpha_ph_y_val = get_param('alpha_ph_y');
alpha_ph_r_val = get_param('alpha_ph_r');
dln_ph_rec = zeros(nQ, 1);
ph_gap = zeros(nQ, 1);
for t = 2:nQ
    if ~isnan(yhat_au(t)) && ~isnan(i_gap(t-1))
        dln_ph_rec(t) = rho_ph_val * dln_ph_rec(t-1) + alpha_ph_y_val * yhat_au(t) + alpha_ph_r_val * i_gap(t-1);
    else
        dln_ph_rec(t) = rho_ph_val * dln_ph_rec(t-1);
    end
    ph_gap(t) = 0.98 * ph_gap(t-1) + dln_ph_rec(t);
end

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
fprintf('COVID dummies: crash at obs %d, bounce at obs %d\n', ...
    find(d_covid_crash), find(d_covid_bounce));

%% 3. Find valid sample
valid = ~isnan(yhat_au) & ~isnan(pi_au) & ~isnan(i_gap) & ...
        ~isnan(u_gap) & ~isnan(dln_c) & ~isnan(dln_ib) & ...
        ~isnan(dln_ih) & ~isnan(dln_n);
first_v = find(valid, 1, 'first') + 4;  % need 4 lags for employment PAC
last_v  = find(valid, 1, 'last');
T = last_v - first_v + 1;
fprintf('Valid sample: obs %d to %d (%d quarters)\n', first_v, last_v, T);

%% 4. Read calibrated parameters from M_
% Helper to get parameter value by name
get_param = @(name) M_.params(strcmp(name, M_.param_names));

% E-SAT VAR parameters (for constructing auxiliary gaps)
rho_pQ_aux  = get_param('rho_pQ_aux');
a_pQ_y      = get_param('a_pQ_y');
a_pQ_i      = get_param('a_pQ_i');
a_pQ_pi     = get_param('a_pQ_pi');
a_pQ_u      = get_param('a_pQ_u');

rho_n_aux   = get_param('rho_n_aux');
a_n_y       = get_param('a_n_y');
a_n_i       = get_param('a_n_i');
a_n_pi      = get_param('a_n_pi');
a_n_u       = get_param('a_n_u');

rho_yh_aux  = get_param('rho_yh_aux');
a_yh_y      = get_param('a_yh_y');
a_yh_u      = get_param('a_yh_u');

rho_c_aux   = get_param('rho_c_aux');
a_c_y       = get_param('a_c_y');
a_c_i       = get_param('a_c_i');
a_c_pi      = get_param('a_c_pi');
a_c_u       = get_param('a_c_u');
a_c_yh      = get_param('a_c_yh');

rho_ib_aux  = get_param('rho_ib_aux');
a_ib_y      = get_param('a_ib_y');
a_ib_pi     = get_param('a_ib_pi');
a_ib_u      = get_param('a_ib_u');

rho_rKB_aux = get_param('rho_rKB_aux');
a_rKB_i     = get_param('a_rKB_i');

rho_ih_aux  = get_param('rho_ih_aux');
a_ih_y      = get_param('a_ih_y');
a_ih_i      = get_param('a_ih_i');
a_ih_pi     = get_param('a_ih_pi');
a_ih_u      = get_param('a_ih_u');

%% 5. Recursively construct auxiliary gap variables from observed data
% These are the VAR auxiliary equations in au_pac.mod.
% Initialize at zero (steady state).

piQ_hat       = zeros(nQ, 1);
n_hat         = zeros(nQ, 1);
yh_ratio_hat  = zeros(nQ, 1);
c_hat         = zeros(nQ, 1);
ib_hat        = zeros(nQ, 1);
rKB_hat       = zeros(nQ, 1);
ih_hat        = zeros(nQ, 1);

% Also construct pv_X_aux (backward correction terms)
pv_piQ_aux    = zeros(nQ, 1);
pv_n_aux      = zeros(nQ, 1);
pv_c_aux      = zeros(nQ, 1);
pv_ib_aux     = zeros(nQ, 1);
pv_rKB_aux    = zeros(nQ, 1);
pv_ih_aux     = zeros(nQ, 1);

for t = 2:nQ
    if isnan(yhat_au(t-1)) || isnan(i_gap(t-1)) || isnan(pi_au_gap(t-1)) || isnan(u_gap(t-1))
        continue;
    end
    y_1 = yhat_au(t-1);
    i_1 = i_gap(t-1);
    p_1 = pi_au_gap(t-1);
    u_1 = u_gap(t-1);

    % Auxiliary gaps (var_model equations)
    piQ_hat(t)      = rho_pQ_aux * piQ_hat(t-1) + a_pQ_y*y_1 + a_pQ_i*i_1 + a_pQ_pi*p_1 + a_pQ_u*u_1;
    n_hat(t)        = rho_n_aux  * n_hat(t-1)   + a_n_y*y_1  + a_n_i*i_1  + a_n_pi*p_1  + a_n_u*u_1;
    yh_ratio_hat(t) = rho_yh_aux * yh_ratio_hat(t-1) + a_yh_y*y_1 + a_yh_u*u_1;
    c_hat(t)        = rho_c_aux  * c_hat(t-1)   + a_c_y*y_1  + a_c_i*i_1  + a_c_pi*p_1  + a_c_u*u_1 + a_c_yh*yh_ratio_hat(t-1);
    ib_hat(t)       = rho_ib_aux * ib_hat(t-1)  + a_ib_y*y_1 + a_ib_pi*p_1 + a_ib_u*u_1;
    rKB_hat(t)      = rho_rKB_aux* rKB_hat(t-1) + a_rKB_i*i_1;
    ih_hat(t)       = rho_ih_aux * ih_hat(t-1)  + a_ih_y*y_1 + a_ih_i*i_1  + a_ih_pi*p_1 + a_ih_u*u_1;

    % Backward correction terms (pv_X_aux equations)
    pv_piQ_aux(t)   = rho_pQ_aux * pv_piQ_aux(t-1) + a_pQ_y*y_1 + a_pQ_i*i_1 + a_pQ_pi*p_1 + a_pQ_u*u_1;
    pv_n_aux(t)     = rho_n_aux  * pv_n_aux(t-1)   + a_n_y*y_1  + a_n_i*i_1  + a_n_pi*p_1  + a_n_u*u_1;
    pv_c_aux(t)     = rho_c_aux  * pv_c_aux(t-1)   + a_c_y*y_1  + a_c_i*i_1  + a_c_pi*p_1  + a_c_u*u_1;
    pv_ib_aux(t)    = rho_ib_aux * pv_ib_aux(t-1)  + a_ib_y*y_1 + a_ib_pi*p_1 + a_ib_u*u_1;
    pv_rKB_aux(t)   = rho_rKB_aux* pv_rKB_aux(t-1) + a_rKB_i*i_1;
    pv_ih_aux(t)    = rho_ih_aux * pv_ih_aux(t-1)  + a_ih_y*y_1 + a_ih_i*i_1  + a_ih_pi*p_1 + a_ih_u*u_1;
end

%% 6. Construct level accumulation variables
% Dynare PAC uses diff(level) form. We need the level variables.
% Accumulate from growth rates starting at 0 (gap model, everything demeaned).

ln_c_level  = cumsum_nan(dln_c);
ln_ib_level = cumsum_nan(dln_ib);
ln_ih_level = cumsum_nan(dln_ih);
ln_n_level  = cumsum_nan(dln_n);
pQ_level    = cumsum_nan(piQ);

% Auxiliary lag variables for higher-order PAC
dln_n_1  = [0; dln_n(1:end-1)];
dln_n_2  = [0; dln_n_1(1:end-1)];
dln_n_3  = [0; dln_n_2(1:end-1)];
dln_ib_1 = [0; dln_ib(1:end-1)];
dln_ih_1 = [0; dln_ih(1:end-1)];

%% 7. Also need the VAR state variables with their model names
% The var_model uses: y_gap_var, i_gap_var, pi_gap_var, u_gap_var, yhat_us_var
% These are identified with the observed counterparts.
y_gap_var   = yhat_au;
i_gap_var   = i_gap;
pi_gap_var  = pi_au_gap;
u_gap_var   = u_gap;
yhat_us_var = yhat_us;

%% 8. Pack into dseries
% Dynare dseries needs: dates + variable names matching model

% Construct the date string for dseries init
start_date = dates(sprintf('%dQ%d', start_year, start_quarter));

% Build the data matrix — all variables that might appear in PAC equations
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
        % Residuals must be NaN for pac.estimate
        data_mat(:, j) = NaN;
    else
        data_mat(:, j) = eval(vname);
    end
end

% Create dseries
db = dseries(data_mat, start_date, varnames);

fprintf('dseries created: %d variables x %d observations\n', length(varnames), nQ);
fprintf('Date range: %s to %s\n', char(db.dates(1)), char(db.dates(end)));
fprintf('=== dseries construction complete ===\n');

end

%% Helper function: cumulative sum handling NaN
function y = cumsum_nan(x)
    y = zeros(size(x));
    for t = 1:length(x)
        if isnan(x(t))
            if t > 1
                y(t) = y(t-1);  % carry forward
            end
        else
            if t > 1
                y(t) = y(t-1) + x(t);
            else
                y(t) = x(t);
            end
        end
    end
end
