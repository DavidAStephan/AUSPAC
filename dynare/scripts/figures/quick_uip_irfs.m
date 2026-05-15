%% quick_uip_irfs.m — run one regime, save IRFs.
%% Usage: matlab -batch "cd('...'); regime='au_pac'; tag='hybrid'; run('quick_uip_irfs.m')"

cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

assert(exist('regime','var')==1, 'must set regime variable');
assert(exist('tag','var')==1, 'must set tag variable');

fprintf('=== quick_uip_irfs: regime=%s tag=%s ===\n', regime, tag);
t0 = tic;
eval(['dynare ' regime ' noclearall nograph']);
irfs = oo_.irfs;
fname = sprintf('saved_irfs_uip_%s.mat', tag);
save(fname, 'irfs');
fprintf('  saved %s  (%.1fs)\n', fname, toc(t0));

% Print quick summary: peak of ln_Q and s_gap under eps_i, scaled to 100bp
stderr_i = 0.1105;
scale = 0.25 / stderr_i;
if isfield(irfs, 'ln_Q_eps_i')
    y = irfs.ln_Q_eps_i * scale;
    [pk, qpk] = max(abs(y));
    fprintf('  ln_Q peak = %+.4f%% at Q%d (sign=%+d)\n', ...
        sign(y(qpk))*pk, qpk, sign(y(qpk)));
end
if isfield(irfs, 's_gap_eps_i')
    y = irfs.s_gap_eps_i * scale;
    [pk, qpk] = max(abs(y));
    fprintf('  s_gap peak = %+.4f at Q%d (- = AUD appreciation)\n', ...
        sign(y(qpk))*pk, qpk);
end
if isfield(irfs, 'dln_x_eps_i')
    y = irfs.dln_x_eps_i * scale;
    [pk, qpk] = max(abs(y));
    fprintf('  dln_x peak = %+.4f%% at Q%d\n', sign(y(qpk))*pk, qpk);
end
if isfield(irfs, 'dln_m_eps_i')
    y = irfs.dln_m_eps_i * scale;
    [pk, qpk] = max(abs(y));
    fprintf('  dln_m peak = %+.4f%% at Q%d\n', sign(y(qpk))*pk, qpk);
end
if isfield(irfs, 'pv_i_uip_eps_i')
    y = irfs.pv_i_uip_eps_i * scale;
    [pk, qpk] = max(abs(y));
    fprintf('  pv_i_uip peak = %+.4f at Q%d (impact=%+.4f)\n', sign(y(qpk))*pk, qpk, y(1)*scale/scale);
end
