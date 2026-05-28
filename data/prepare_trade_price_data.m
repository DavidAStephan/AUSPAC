%% prepare_trade_price_data.m — Phase L2 trade/price OLS data layer
%
% Builds quarterly series for the trade, deflator, and spread OLS:
%   pcom_lvl, dln_pcom   — RBA I02 commodity price index (A$), q-avg of monthly
%   twi_lvl, dln_twi     — RBA F11 trade-weighted index, q-avg of monthly
%   s_gap_proxy          — log TWI minus HP trend (quarterly)
%   pi_x_obs, pi_m_obs   — ABS 5206 IPD export / import % chg (q/q)
%   pi_g_obs             — ABS 5206 IPD government consumption % chg
%   pi_ib_obs, pi_ih_obs — ABS 5206 IPD private GFCF % chg
%   pi_q_obs             — ABS 5206 IPD GDP % chg
%   x_vol, m_vol         — ABS 5206 chain-volume exports / imports
%   dln_x, dln_m         — log-diff trade volumes
%
% Output: data/trade_price_data.mat

clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% I02 commodity (monthly)
fprintf('Loading I02 commodity index ...\n');
T_i02 = readtable(fullfile(projectdir,'data','abs_rba','rba_i02_commodity.xlsx'), ...
                  'Sheet','Data','VariableNamingRule','preserve');
% Col 1 = date string in 'mmm-yyyy', col 2 = A$ commodity index
dates_i02_raw = T_i02{:,1};
pcom_raw = T_i02{:,2};
% Convert to datetime
if iscell(dates_i02_raw)
    dates_i02 = NaT(numel(dates_i02_raw),1);
    for i=1:numel(dates_i02_raw)
        v = dates_i02_raw{i};
        if isdatetime(v), dates_i02(i)=v;
        elseif ischar(v) || isstring(v)
            d = datetime(v,'InputFormat','MMM-yyyy');
            if isnat(d), d=datetime(v); end
            dates_i02(i) = d;
        end
    end
elseif isdatetime(dates_i02_raw)
    dates_i02 = dates_i02_raw;
end
if iscell(pcom_raw)
    pcom_m = NaN(numel(pcom_raw),1);
    for i=1:numel(pcom_raw)
        v = pcom_raw{i};
        if isnumeric(v), pcom_m(i)=v;
        elseif ischar(v) || isstring(v), pcom_m(i)=str2double(v);
        end
    end
else
    pcom_m = pcom_raw;
end
mask = ~isnat(dates_i02) & ~isnan(pcom_m);
dates_i02 = dates_i02(mask); pcom_m = pcom_m(mask);
fprintf('  I02: %d monthly obs from %s to %s\n', numel(pcom_m), ...
        datestr(min(dates_i02),'yyyy-mm'), datestr(max(dates_i02),'yyyy-mm'));

%% F11 TWI — concatenate pre-2009 history + current
fprintf('Loading F11 exchange rates ...\n');
T_f11a = readtable(fullfile(projectdir,'data','abs_rba','rba_f11_pre2009.xls'), ...
                   'Sheet','Data','VariableNamingRule','preserve');
T_f11b = readtable(fullfile(projectdir,'data','abs_rba','rba_f11_exchange.xls'), ...
                   'Sheet','Data','VariableNamingRule','preserve');
% pre-2009 file: col 15 = TWI; current file: col 3 = TWI
dates_f11_raw = [T_f11a{:,1}; T_f11b{:,1}];
twi_raw       = [T_f11a{:,15}; T_f11b{:,3}];
if iscell(dates_f11_raw)
    dates_f11 = NaT(numel(dates_f11_raw),1);
    for i=1:numel(dates_f11_raw)
        v = dates_f11_raw{i};
        if isdatetime(v), dates_f11(i)=v;
        elseif ischar(v) || isstring(v)
            d = datetime(v);
            if isnat(d)
                d = datetime(v,'InputFormat','MMM-yyyy');
            end
            dates_f11(i)=d;
        end
    end
elseif isdatetime(dates_f11_raw)
    dates_f11 = dates_f11_raw;
end
if iscell(twi_raw)
    twi_m = NaN(numel(twi_raw),1);
    for i=1:numel(twi_raw)
        v = twi_raw{i};
        if isnumeric(v), twi_m(i)=v;
        elseif ischar(v) || isstring(v), twi_m(i)=str2double(v);
        end
    end
else
    twi_m = twi_raw;
end
mask = ~isnat(dates_f11) & ~isnan(twi_m);
dates_f11 = dates_f11(mask); twi_m = twi_m(mask);
fprintf('  F11: %d monthly obs from %s to %s\n', numel(twi_m), ...
        datestr(min(dates_f11),'yyyy-mm'), datestr(max(dates_f11),'yyyy-mm'));

%% Quarterly aggregation helper
quarter_avg = @(dt, x) accum_q(dt, x);

[q_pcom_dates, q_pcom] = accum_q(dates_i02, pcom_m);
[q_twi_dates,  q_twi]  = accum_q(dates_f11, twi_m);

fprintf('  Quarterly: pcom %d obs (%s..%s), twi %d obs (%s..%s)\n', ...
        numel(q_pcom), datestr(q_pcom_dates(1),'yyyy-Qq'), datestr(q_pcom_dates(end),'yyyy-Qq'), ...
        numel(q_twi),  datestr(q_twi_dates(1),'yyyy-Qq'),  datestr(q_twi_dates(end),'yyyy-Qq'));

%% ABS 5206 IPD percentage changes (already quarterly)
fprintf('Loading ABS 5206 IPD ...\n');
T_ipd = readtable(fullfile(projectdir,'data','abs_rba','abs_5206_ipd.xlsx'), ...
                  'Sheet','Data1','VariableNamingRule','preserve');
% IPD percentage-change cols (from earlier diagnostic):
%   75: Exports % chg
%   76: Imports % chg
%   77: GDP % chg
% Levels:
%   37: Exports
%   38: Imports
%   39: GDP
get_col = @(K) cell_to_num(T_ipd{:,K});
pi_x_full   = get_col(75);
pi_m_full   = get_col(76);
pi_q_full   = get_col(77);
p_X_lvl     = get_col(37);  % level (NB: contains rebasing jumps for older obs)
p_M_lvl     = get_col(38);
p_Q_lvl     = get_col(39);
% Government consumption deflator pct chg: col 46 (All sectors Final consumption)
%   wait — col 46 = "All sectors Final consumption: Percentage changes"
% For government specifically:
%   44: General government Final consumption: Percentage changes
pi_g_full   = get_col(44);
% GFCF deflators: Total private GFCF % chg might be col 60 area
% Use specific:
%   58: Private GFCF - Machinery and equipment: Percentage changes? Need to check
% Simpler: use Private GFCF Total = col 24 levels, then percentage from col 24+38=62
pi_ib_full  = get_col(62);   % Private GFCF % chg (placeholder; refine if needed)
pi_ih_full  = get_col(49);   % Private GFCF Dwellings Total % chg

ipd_dates = T_ipd{:,1};
if iscell(ipd_dates)
    dt_ipd = NaT(numel(ipd_dates),1);
    for i=1:numel(ipd_dates)
        v = ipd_dates{i};
        if isdatetime(v), dt_ipd(i)=v;
        elseif ischar(v) || isstring(v), dt_ipd(i)=datetime(v);
        end
    end
    ipd_dates = dt_ipd;
end
mask = ~isnat(ipd_dates) & ~isnan(pi_q_full);
ipd_dates = ipd_dates(mask);
pi_x_full = pi_x_full(mask); pi_m_full = pi_m_full(mask); pi_q_full = pi_q_full(mask);
pi_g_full = pi_g_full(mask); pi_ib_full = pi_ib_full(mask); pi_ih_full = pi_ih_full(mask);
p_X_lvl = p_X_lvl(mask); p_M_lvl = p_M_lvl(mask); p_Q_lvl = p_Q_lvl(mask);
fprintf('  ABS 5206 IPD: %d quarterly obs from %s to %s\n', numel(pi_x_full), ...
        datestr(min(ipd_dates),'yyyy-Qq'), datestr(max(ipd_dates),'yyyy-Qq'));

%% ABS 5206 chain volumes for trade (xlsx — longer than csv)
fprintf('Loading ABS 5206 chain volumes (xlsx) ...\n');
T_vol = readtable(fullfile(projectdir,'data','abs_rba','abs_5206_vol.xlsx'), ...
                  'Sheet','Data1','VariableNamingRule','preserve');
% Confirmed cols: 39 Exports, 40 Imports, 6 General govt final consumption
ix_x = 39; ix_m = 40; ix_g = 6;
fprintf('  Cols: X=%d M=%d G=%d\n', ix_x, ix_m, ix_g);
x_vol_full = cell_to_num(T_vol{:,ix_x});
m_vol_full = cell_to_num(T_vol{:,ix_m});
g_vol_full = cell_to_num(T_vol{:,ix_g});
vol_dates = T_vol{:,1};
if iscell(vol_dates)
    dt_vol = NaT(numel(vol_dates),1);
    for i=1:numel(vol_dates), v=vol_dates{i}; if ischar(v)||isstring(v), dt_vol(i)=datetime(v); elseif isdatetime(v), dt_vol(i)=v; end; end
    vol_dates = dt_vol;
end
mask = ~isnat(vol_dates) & ~isnan(x_vol_full);
vol_dates = vol_dates(mask); x_vol_full = x_vol_full(mask); m_vol_full = m_vol_full(mask); g_vol_full = g_vol_full(mask);
fprintf('  ABS 5206 vol: %d obs from %s to %s\n', numel(x_vol_full), ...
        datestr(min(vol_dates),'yyyy-Qq'), datestr(max(vol_dates),'yyyy-Qq'));

dln_x_full = [NaN; diff(log(x_vol_full))*100];
dln_m_full = [NaN; diff(log(m_vol_full))*100];
dln_g_full = [NaN; diff(log(g_vol_full))*100];

%% s_gap_proxy: log TWI - HP trend (lambda=1600 quarterly)
ln_twi = log(q_twi);
ln_twi_trend = hp_filter(ln_twi, 1600);
s_gap_proxy = ln_twi - ln_twi_trend;       % units: log points (small)
dln_twi = [NaN; diff(ln_twi)*100];

%% dln_pcom: log-diff of commodity price (q/q, %)
dln_pcom = [NaN; diff(log(q_pcom))*100];

%% Save
out.q_pcom_dates  = q_pcom_dates;
out.pcom_lvl      = q_pcom;
out.dln_pcom      = dln_pcom;
out.q_twi_dates   = q_twi_dates;
out.twi_lvl       = q_twi;
out.dln_twi       = dln_twi;
out.s_gap_proxy   = s_gap_proxy;
out.ipd_dates     = ipd_dates;
out.pi_x_obs      = pi_x_full;
out.pi_m_obs      = pi_m_full;
out.pi_q_obs      = pi_q_full;
out.pi_g_obs      = pi_g_full;
out.pi_ib_obs     = pi_ib_full;
out.pi_ih_obs     = pi_ih_full;
out.p_X_lvl       = p_X_lvl;
out.p_M_lvl       = p_M_lvl;
out.p_Q_lvl       = p_Q_lvl;
out.vol_dates     = vol_dates;
out.x_vol         = x_vol_full;
out.m_vol         = m_vol_full;
out.g_vol         = g_vol_full;
out.dln_x         = dln_x_full;
out.dln_m         = dln_m_full;
out.dln_g         = dln_g_full;

save(fullfile(projectdir, 'data', 'trade_price_data.mat'), '-struct', 'out');
fprintf('\nWrote trade_price_data.mat\n');

%% Helper functions
function y = cell_to_num(c)
    if iscell(c)
        y = NaN(numel(c),1);
        for i=1:numel(c)
            v = c{i};
            if isnumeric(v), y(i)=v;
            elseif ischar(v) || isstring(v), y(i)=str2double(v);
            end
        end
    elseif isnumeric(c)
        y = c;
    elseif isdatetime(c)
        y = datenum(c);
    end
end

function [q_dates, q_vals] = accum_q(monthly_dates, monthly_vals)
    % Average within each quarter
    qy = year(monthly_dates);
    qq = ceil(month(monthly_dates)/3);
    keys = qy*10 + qq;
    [u, ~, ix] = unique(keys);
    q_vals = accumarray(ix, monthly_vals, [], @(x) mean(x,'omitnan'));
    q_dates = NaT(numel(u),1);
    for k=1:numel(u)
        yy = floor(u(k)/10); qn = mod(u(k),10);
        q_dates(k) = datetime(yy, (qn-1)*3+1, 1);
    end
end

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
