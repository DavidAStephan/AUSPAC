function [Phi, state_names, ZL_full, state_data, n_valid] = build_block_var(block_name, L2, base, sample_idx)
%BUILD_BLOCK_VAR Block-specific auxiliary VAR(1) Phi for wp1044 PAC blocks.
%
% Each PAC block has its own state vector in wp1044, matching the
% relevant policy-function table (Tables 3.3.4, 3.4.10, 3.5.3, 3.5.8,
% 3.5.14, 3.5.15).  This helper assembles the right state for each block,
% estimates Phi by OLS lag-by-lag, and returns Phi + lagged state for PV
% computation.
%
% Inputs:
%   block_name   - one of 'pQ', 'n', 'c', 'ih', 'ib'
%   L2           - struct from data/l2_data_layer.mat
%   base         - readtable of dataset.csv
%   sample_idx   - index into L2 sample (e.g. 5:end for first-4-NaN burn-in)
%
% Outputs:
%   Phi          - k x k VAR(1) transition matrix
%   state_names  - cell array of variable names in z
%   ZL_full      - nObs x k matrix of z_{t-1} aligned to sample_idx
%   state_data   - nObs x k matrix of z_t
%   n_valid      - number of obs used in VAR OLS

% Helper: align base table column to L2 sample
align_base = @(col_name) align_to_l2(base, col_name, L2.dates, sample_idx);

% Common state variables
yhat   = align_base('au_ygap');               % output gap, already pp
i_au   = align_base('au_irate');              % cash rate, annualised %
piQ    = L2.piQ(sample_idx);                  % VA inflation q/q %
i_bar  = L2.i_au_trend(sample_idx);
pi_bar = L2.pi_au_trend(sample_idx) * 4;      % annualised
i_gap  = i_au - i_bar;
pi_gap = align_base('au_pi') - L2.pi_au_trend(sample_idx);

% Block-specific state assembly
switch block_name
    case 'pQ'   % wp1044 Table 3.3.4 -- VA-price policy function
        % State: [yhat, i_gap, piQ_gap, yhat_EA, piEA_gap, u_hat, pi_w_eff, pi_Q_bar]
        % AU adaptation: no EA vars cleanly; use US as foreign proxy
        yhat_us = align_base('us_ygap');
        pi_us   = align_base('us_pi');
        u_hat   = L2.u_hat(sample_idx);
        pi_w_eff = (L2.piW(sample_idx) - L2.Delta_e(sample_idx));   % real efficient wage growth
        pi_Q_bar = L2.pi_Q_bar(sample_idx);
        piQ_gap = piQ - pi_Q_bar;
        state_data = [yhat, i_gap, piQ_gap, yhat_us, pi_us, u_hat, pi_w_eff, pi_Q_bar];
        state_names = {'yhat', 'i_gap', 'piQ_gap', 'yhat_us', 'pi_us', 'u_hat', 'pi_w_eff', 'pi_Q_bar'};

    case 'n'    % wp1044 Table 3.4.10 -- employment policy function
        % State: [yhat, i_gap, piQ_gap, yhat_EA, piEA_gap, n_hat_S]
        yhat_us = align_base('us_ygap');
        pi_us   = align_base('us_pi');
        n_hat   = L2.n_hat_star_S(sample_idx);
        piQ_gap = piQ - L2.pi_Q_bar(sample_idx);
        state_data = [yhat, i_gap, piQ_gap, yhat_us, pi_us, n_hat];
        state_names = {'yhat', 'i_gap', 'piQ_gap', 'yhat_us', 'pi_us', 'n_hat_S'};

    case 'c'    % wp1044 Table 3.5.3 -- consumption block (PV(y_H - ybar) policy fn)
        % State: [yhat, i_gap, pi_gap, yhat_EA, piEA_gap, y_H - y_bar, Δw_eff, u_hat]
        yhat_us  = align_base('us_ygap');
        pi_us    = align_base('us_pi');
        yH_gap   = L2.y_H_minus_y_bar(sample_idx);
        Dweff    = L2.Delta_w_eff(sample_idx);
        u_hat    = L2.u_hat(sample_idx);
        state_data = [yhat, i_gap, pi_gap, yhat_us, pi_us, yH_gap, Dweff, u_hat];
        state_names = {'yhat', 'i_gap', 'pi_gap', 'yhat_us', 'pi_us', 'yH_gap', 'Dweff', 'u_hat'};

    case 'ih'   % wp1044 Table 3.5.8 -- housing inv policy function
        % State: [yhat, i_gap, pi_gap, yhat_EA, piEA_gap, log_IH_hat_star]
        yhat_us  = align_base('us_ygap');
        pi_us    = align_base('us_pi');
        % IH gap target -- AU proxy: HP-gap of log au_gfcf_dwelling × 100
        % au_gfcf_dwelling is in extended_dataset (not base); read directly.
        projdir = fileparts(fileparts(mfilename('fullpath')));
        T_ext = readtable(fullfile(projdir, 'extended_dataset.csv'));
        ext_dates = datetime(T_ext.date);
        ih_target = nan(length(L2.dates), 1);
        for ii = 1:length(L2.dates)
            m = find(year(ext_dates) == year(L2.dates(ii)) & ...
                     quarter(ext_dates) == quarter(L2.dates(ii)), 1);
            if ~isempty(m), ih_target(ii) = T_ext.au_gfcf_dwelling(m); end
        end
        ih_target = ih_target(sample_idx);
        log_ih   = log(ih_target);
        log_ih_trend = hp_trend_local(log_ih, 1600);
        IH_gap   = (log_ih - log_ih_trend) * 100;
        state_data = [yhat, i_gap, pi_gap, yhat_us, pi_us, IH_gap];
        state_names = {'yhat', 'i_gap', 'pi_gap', 'yhat_us', 'pi_us', 'IH_gap'};

    case 'ib'   % wp1044 Tables 3.5.14, 3.5.15 -- business inv policy function
        % State: [yhat, i_gap, pi_gap, yhat_EA, piEA_gap, r_KB_gap, q_hat]
        yhat_us  = align_base('us_ygap');
        pi_us    = align_base('us_pi');
        % r_KB gap: AU proxy uses i_10y - pi_Q as real user cost; gap via HP
        i_10y    = align_base('au_i10');
        r_KB     = i_10y - L2.pi_au_trend(sample_idx) * 4;
        r_KB_trend = hp_trend_local(r_KB, 1600);
        r_KB_gap = r_KB - r_KB_trend;
        % q_hat: market VA gap (HP), pp
        q_hat    = L2.Delta_q_hat(sample_idx);   % already pp
        state_data = [yhat, i_gap, pi_gap, yhat_us, pi_us, r_KB_gap, q_hat];
        state_names = {'yhat', 'i_gap', 'pi_gap', 'yhat_us', 'pi_us', 'r_KB_gap', 'q_hat'};

    otherwise
        error('Unknown block: %s', block_name);
end

% Estimate VAR(1) Phi via OLS lag-by-lag on rows with no NaN
k = size(state_data, 2);
valid = ~any(isnan(state_data), 2);
Z = state_data(valid, :);
Z_lag = Z(1:end-1, :);
Z_t   = Z(2:end, :);
n_valid = size(Z, 1);

% OLS each equation: z_t = Phi z_{t-1} + e
Phi = ((Z_lag' * Z_lag) \ (Z_lag' * Z_t))';   % rows = output dim

% Build ZL_full: z_{t-1} aligned to the sample (NaN where source NaN)
nObs = size(state_data, 1);
ZL_full = nan(nObs, k);
v_idx = find(valid);
for ii = 2:length(v_idx)
    ZL_full(v_idx(ii), :) = state_data(v_idx(ii-1), :);
end
end

function vq = align_to_l2(T, colname, L2_dates, sample_idx)
    src_dates = datetime(T.date);
    target_dates = L2_dates(sample_idx);
    nq = length(target_dates);
    vq = nan(nq, 1);
    col = T.(colname);
    for i = 1:nq
        m = find(year(src_dates) == year(target_dates(i)) & ...
                 quarter(src_dates) == quarter(target_dates(i)), 1);
        if ~isempty(m), vq(i) = col(m); end
    end
end

function trend = hp_trend_local(y, lambda)
    y = y(:);
    n = length(y);
    trend = nan(n, 1);
    valid = find(~isnan(y));
    if length(valid) < 4, return; end
    lo = valid(1); hi = valid(end);
    span = lo:hi;
    y_span = y(span);
    nm = isnan(y_span);
    if any(nm)
        idx = find(~nm);
        y_span = interp1(idx, y_span(idx), 1:length(y_span), 'linear')';
    end
    n_span = length(y_span);
    e = ones(n_span, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n_span-2, n_span);
    A = speye(n_span) + lambda * (D2' * D2);
    trend(span) = A \ y_span;
end
