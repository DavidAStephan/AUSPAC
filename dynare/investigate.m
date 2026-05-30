% investigate.m — decompose (1) weaker monetary transmission and (2) positive ln_Q drift
% under §6.11 (trade fix b1_x=0.30,b1_m_ne=0.23 + reverted §6.10 PAC hack). Flat script.
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab');
dynare au_pac.mod;                       % compiles §6.9 PAC + trade fix (current worktree)
run('/tmp/load_p610.m');                 % loads struct P610 (the §6.10 PAC param set)

options_.nograph = 1; options_.noprint = 1;
ei  = find(strcmp(M_.exo_names,'eps_i'));
scale = 0.25 / sqrt(M_.Sigma_e(ei,ei));
fprintf('\n>>> eps_i scale = %.4f (stderr=%.5f)\n', scale, sqrt(M_.Sigma_e(ei,ei)));

vl = {'ln_Q','yhat_au','ln_QN','yhat_dom','dln_c','dln_ib','dln_ih','dln_n', ...
      'dln_g','dln_x','dln_m','dln_m_ne','ln_c_level','ln_ib_level','ln_ih_level', ...
      'ln_n_level','ln_x_level','ln_m_ne_level','s_gap','uc_k','ln_x_eq','i_gap','pi_au_gap'};
vl = vl(ismember(vl, M_.endo_names));
miss = setdiff({'ln_QN','yhat_dom','dln_g','dln_x','dln_m','ln_x_level','ln_m_ne_level','s_gap','uc_k','ln_x_eq'}, vl);
if ~isempty(miss), fprintf('NOTE missing vars: %s\n', strjoin(miss,', ')); end

%% ===================== PART A: convergence + drift decomposition =====================
fprintf('\n================ PART A: long-horizon convergence (§6.11 config) ================\n');
options_.irf = 1000;
[~, oo_, options_, M_] = stoch_simul(M_, options_, oo_, vl);
A = struct();
for k=1:numel(vl), A.(vl{k}) = oo_.irfs.([vl{k} '_eps_i'])(:)*scale; end
getA = @(nm) ( isfield(A,nm) * 1 );   % helper marker
g = @(nm,H) (isfield(A,nm) && ~isempty(A.(nm))) * 0;  % unused

qs = [9 17 40 100 200 500 1000];
fprintf('Q      ln_Q      yhat_au   ln_QN\n');
for q=qs
    lq = A.ln_Q(q); yh = A.yhat_au(q);
    qn = 0; if isfield(A,'ln_QN'), qn = A.ln_QN(q); end
    fprintf('%-6d %+8.4f  %+8.4f  %+8.4f\n', q, lq, yh, qn);
end

fprintf('\n-- cumulative demand decomposition of yhat_au (= integral of yhat_dom) --\n');
wnm={'w_c','w_ib','w_ih','w_g','w_x','w_m'}; w=zeros(1,6);
for i=1:6, w(i)=M_.params(strcmp(M_.param_names,wnm{i})); end
fprintf('weights: w_c=%.3f w_ib=%.3f w_ih=%.3f w_g=%.3f w_x=%.3f w_m=%.3f\n', w);
H=1000; z=zeros(H,1);
cc = z; if isfield(A,'dln_c'), cc=A.dln_c; end
cib= z; if isfield(A,'dln_ib'), cib=A.dln_ib; end
cih= z; if isfield(A,'dln_ih'), cih=A.dln_ih; end
cg = z; if isfield(A,'dln_g'), cg=A.dln_g; end
cx = z; if isfield(A,'dln_x'), cx=A.dln_x; end
cm = z; if isfield(A,'dln_m'), cm=A.dln_m; end
contrib = [w(1)*cumsum(cc), w(2)*cumsum(cib), w(3)*cumsum(cih), w(4)*cumsum(cg), w(5)*cumsum(cx), -w(6)*cumsum(cm)];
lab={'C','IB','IH','G','X','-M'};
fprintf('contribution to yhat_au [cumulated*weight] at Q40 / Q1000:\n');
for j=1:6, fprintf('   %-3s  Q40=%+8.4f   Q1000=%+8.4f\n', lab{j}, contrib(40,j), contrib(end,j)); end
fprintf('   SUM(components) Q1000=%+8.4f   vs yhat_au(1000)=%+8.4f\n', sum(contrib(end,:)), A.yhat_au(1000));

fprintf('\n-- cyclical/eq LEVELS (Q40 / Q200 / Q1000) — should ~0 if fully reverted --\n');
for v={'ln_c_level','ln_ib_level','ln_ih_level','ln_n_level','ln_x_level','ln_m_ne_level','s_gap','uc_k','ln_x_eq'}
    vv=v{1};
    if isfield(A,vv)&&~isempty(A.(vv))
        fprintf('   %-14s %+8.4f  %+8.4f  %+8.4f\n', vv, A.(vv)(40), A.(vv)(200), A.(vv)(1000));
    end
end
eigA = sort(abs(oo_.dr.eigval),'descend');

%% snapshot §6.9 values then run 2x2
flipnames = fieldnames(P610); P69 = struct();
for i=1:numel(flipnames), P69.(flipnames{i}) = M_.params(strcmp(M_.param_names,flipnames{i})); end

fprintf('\n================ PART B: 2x2 (PAC block) x (trade persistence) ================\n');
options_.irf = 200; vlb = {'ln_Q','yhat_au'};
res = zeros(4,4);  % [trough, q, Q40, Q200]
labels = {'C4 §6.9 PAC + tradefix(0.30/0.23)','C3 §6.9 PAC + trade ORIG(0.87/0.74)', ...
          'C2 §6.10PAC + tradefix(0.30/0.23)','C1 §6.10PAC + trade ORIG(0.87/0.74) [=HEAD]'};
for cfg=1:4
    if cfg==1||cfg==2, for i=1:numel(flipnames), set_param_value(flipnames{i},P69.(flipnames{i})); end
    else,             for i=1:numel(flipnames), set_param_value(flipnames{i},P610.(flipnames{i})); end, end
    if cfg==1||cfg==3, set_param_value('b1_x',0.30); set_param_value('b1_m_ne',0.23);
    else,              set_param_value('b1_x',0.8673); set_param_value('b1_m_ne',0.7427); end
    [~, oo_, options_, M_] = stoch_simul(M_, options_, oo_, vlb);
    lnQ = oo_.irfs.ln_Q_eps_i(:)*scale; yh = oo_.irfs.yhat_au_eps_i(:)*scale;
    [tmn,qi]=min(lnQ(1:200));
    res(cfg,:) = [tmn, qi, lnQ(40), lnQ(200)];
    fprintf('%s\n   ln_Q trough %+7.4f @Q%-3d | Q40 %+7.4f | Q200 %+7.4f | yhat_au trough %+7.4f\n', ...
        labels{cfg}, tmn, qi, lnQ(40), lnQ(200), min(yh(1:200)));
end
fprintf('\n-- ln_Q trough decomposition --\n');
fprintf('   C1 old HEAD              : %+7.4f\n', res(4,1));
fprintf('   trade-fix effect (C1->C2): %+7.4f\n', res(3,1)-res(4,1));
fprintf('   PAC-revert effect(C2->C4): %+7.4f\n', res(1,1)-res(3,1));
fprintf('   alt path PAC (C1->C3)    : %+7.4f ;  trade (C3->C4): %+7.4f\n', res(2,1)-res(4,1), res(1,1)-res(2,1));
fprintf('   C4 new §6.11             : %+7.4f\n', res(1,1));

%% restore §6.9 + trade fix and report eigen spectrum
for i=1:numel(flipnames), set_param_value(flipnames{i},P69.(flipnames{i})); end
set_param_value('b1_x',0.30); set_param_value('b1_m_ne',0.23);

fprintf('\n================ PART C: slowest modes |lambda| ================\n');
fprintf('§6.11 top-12 |eig|: '); fprintf('%.4f ', eigA(1:12)); fprintf('\n');
fprintf('\nDONE.\n');
