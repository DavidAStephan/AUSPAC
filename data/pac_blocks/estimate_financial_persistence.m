% estimate_financial_persistence.m — Wave 2: AU-data estimation of financial-block
% persistences that the production model currently calibrates.
%
% Cleanly identified here (single-series AR(1), units reconciled):
%   rho_tp  — term-premium persistence, eq 'tp': tp = rho_tp*tp(-1) + (1-rho_tp)*tp_ss + eps_tp
%
% UNIT NOTE (critical): dataset.csv au_irate is QUARTERLY %% (mean 1.049 = model i_ss),
% extended_dataset.csv au_i10 is ANNUAL %% (mean ~4.86). The consistent-unit term
% spread is therefore (au_i10/4 - au_irate). The AR(1) persistence is scale-invariant,
% but the spread LEVEL (hence tp_ss) requires the /4 conversion.
%
% Deferred (need more than a clean single-series AR(1)):
%   rho_s     — s_gap has forward UIP (pv_i_uip) + inflation-diff terms; a bare AR(1) is misspecified.
%   rho_lh    — needs an AU mortgage-rate series (RBA F6/F16) parsed to quarterly.
%   rho_COE/BBB/LB_firms — need AU equity-cost / corporate-spread series.

here   = fileparts(mfilename('fullpath'));
root   = fileparts(fileparts(here));
ds     = readtable(fullfile(root,'dataset.csv'));
ext    = readtable(fullfile(root,'data','extended_dataset.csv'));

% align on date, drop missing
ds.date  = datetime(ds.date);
ext.date = datetime(ext.date);
T = innerjoin(ds(:,{'date','au_irate'}), ext(:,{'date','au_i10'}), 'Keys','date');
T = T(~isnan(T.au_irate) & ~isnan(T.au_i10), :);

tp_proxy = T.au_i10/4 - T.au_irate;          % consistent quarterly %% term spread

% AR(1) OLS: y_t = c + rho*y_{t-1}
y = tp_proxy(2:end); x = [ones(numel(y),1) tp_proxy(1:end-1)];
b = x\y; resid = y - x*b;
n = numel(y); s2 = (resid'*resid)/(n-2); V = s2*inv(x'*x);
rho_tp = b(2); se = sqrt(V(2,2)); tstat = rho_tp/se;
tp_ss_implied = b(1)/(1-rho_tp);             % sample-mean term spread (quarterly %%)
resid_sd = std(resid); R2 = 1 - (resid'*resid)/sum((y-mean(y)).^2);

fid = fopen(fullfile(here,'results_financial.txt'),'w');
w = @(varargin) fprintf(fid,varargin{:}) + fprintf(varargin{:});
w('Financial-block persistence — AU single-equation OLS (Wave 2, %s)\n', datestr(now));
w('Sample: %s..%s, N=%d (after 1 lag)\n', datestr(T.date(1),'yyyyQQ'), datestr(T.date(end),'yyyyQQ'), n);
w('\n[tp] term-premium persistence  tp = rho_tp*tp(-1) + (1-rho_tp)*tp_ss + eps_tp\n');
w('  tp proxy = au_i10/4 - au_irate (quarterly %%)\n');
w('  rho_tp      = %.4f   (se %.4f, t=%.1f)   [model calibrated: 0.98]\n', rho_tp, se, tstat);
w('  tp_ss(impl) = %.4f q  (= sample-mean spread; model calibrated: 0.30)\n', tp_ss_implied);
w('  resid_sd    = %.4f    R2 = %.3f\n', resid_sd, R2);
w('\nWRITEBACK: rho_tp = %.4f (dynamic coef, AU-identified). tp_ss LEFT calibrated\n', rho_tp);
w('  (the term premium is latent vs the observable spread; the sample-mean spread\n');
w('   %.3f is recorded for a future steady-state recalibration of tp_ss).\n', tp_ss_implied);
fclose(fid);
fprintf('Wrote results_financial.txt: rho_tp = %.4f (t=%.1f, R2=%.3f, N=%d)\n', rho_tp, tstat, R2, n);
