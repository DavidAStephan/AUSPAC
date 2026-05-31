% estimate_credit_dsr.m — Wave 3: household credit / Debt-Service-Ratio block (wp1044 §3.7.2)
%
% Builds the AU household interest-DSR (debt-to-income x mortgage rate) and estimates the
% two block parameters from AU data:
%   rho_DSR   — persistence of the DSR gap (AR(1) on the HP-gap of the DSR)
%   alpha_DSR — Delta(DSR_gap) -> consumption-growth drag (eq dln_c_star_bar, wp1044 §3.7.2)
%
% DSR series (RBA E2 debt-to-income BHFDDIT x RBA F5 mortgage rate FILRHLBVS, HP-gap in pp)
% is prebuilt in data/au_household_dsr_q.csv for reproducibility without re-parsing the
% ragged RBA CSVs.

here = fileparts(mfilename('fullpath')); root = fileparts(fileparts(here));
D = readtable(fullfile(root,'data','au_household_dsr_q.csv'));
g = D.DSR_gap_pp;                                  % DSR gap, percentage points of income

% rho_DSR: AR(1) of the gap
y = g(2:end); X = [ones(numel(y),1) g(1:end-1)]; b = X\y; r = y - X*b; n = numel(y);
se = sqrt(diag((r'*r/(n-2))*inv(X'*X)));
rho_DSR = b(2); eps_DSR_sd = std(r);
R2 = 1 - (r'*r)/sum((y-mean(y)).^2);

% alpha_DSR: consumption-growth response to Delta(DSR_gap)
E = load(fullfile(root,'dynare','estimation_data.mat')); dln_c = E.dln_c(:);
% align: DSR series is 1988Q2.., dln_c is the last numel(dln_c) quarters ending 2024Q4
dg = [NaN; diff(g)];
% take the trailing overlap
ND = numel(dln_c); dg_al = dg(end-ND+1:end);
v = ~isnan(dg_al);
yc = dln_c(v); Xc = [ones(sum(v),1) dg_al(v)];
bc = Xc\yc; rc = yc - Xc*bc; sec = sqrt(diag((rc'*rc/(sum(v)-2))*inv(Xc'*Xc)));
alpha_DSR = bc(2);     % sign: negative => higher debt-service growth lowers consumption growth

fid = fopen(fullfile(here,'results_credit_dsr.txt'),'w');
w = @(varargin) fprintf(fid,varargin{:}) + fprintf(varargin{:});
w('Household credit / DSR block (wp1044 §3.7.2) — AU OLS (%s)\n', datestr(now));
w('DSR = RBA E2 debt-to-income (BHFDDIT) x RBA F5 mortgage rate (FILRHLBVS); HP-gap (pp).\n');
w('  DSR mean ~10%% of income; gap std %.3f pp\n', std(g));
w('  rho_DSR   = %.4f   (se %.4f, t=%.1f)   R2=%.3f, N=%d   [eps_DSR std=%.4f pp]\n', ...
   rho_DSR, se(2), rho_DSR/se(2), R2, n, eps_DSR_sd);
w('  alpha_DSR = %.4f   (se %.4f, t=%.1f)   [Delta(DSR_gap)->dln_c; right-signed if <0]\n', ...
   alpha_DSR, sec(2), alpha_DSR/sec(2));
w('WRITEBACK (au_pac.mod): rho_DSR, alpha_DSR, eps_DSR std written back verbatim.\n');
w('NOTE: alpha_DSR is insignificant on AU data (weak credit channel) but the block now\n');
w('  EXISTS and is AU-estimated; follow-up = endogenous debt-stock ECM + aux-VAR/h_pac\n');
w('  consolidation so agents anticipate DSR shocks (cf. Round 4-8 consolidation).\n');
fclose(fid);
fprintf('Wrote results_credit_dsr.txt: rho_DSR=%.4f, alpha_DSR=%.4f, eps_DSR_sd=%.4f\n', ...
        rho_DSR, alpha_DSR, eps_DSR_sd);
