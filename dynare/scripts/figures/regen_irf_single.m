%% regen_irf_single.m  -  Regenerate IRFs for a single regime
% Call with environment variable IRF_REGIME set to one of:
%   au_pac_var, au_pac, au_pac_mce
% Or pass via base workspace variable `IRF_REGIME`.

if ~exist('IRF_REGIME', 'var')
    IRF_REGIME = getenv('IRF_REGIME');
end
if isempty(IRF_REGIME)
    error('Set IRF_REGIME to one of au_pac_var, au_pac, au_pac_mce');
end

cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

fprintf('=== Regenerating IRFs for %s ===\n', IRF_REGIME);

eval(['dynare ' IRF_REGIME ' noclearall nograph']);

irfs_struct = oo_.irfs;
switch IRF_REGIME
    case 'au_pac_var',
        irfs_var = irfs_struct;
        save('saved_irfs_var.mat', 'irfs_var');
        fprintf('  saved_irfs_var.mat written\n');
    case 'au_pac',
        irfs_hybrid = irfs_struct;
        save('saved_irfs_hybrid.mat', 'irfs_hybrid');
        fprintf('  saved_irfs_hybrid.mat written\n');
    case 'au_pac_mce',
        irfs_mce = irfs_struct;
        save('saved_irfs_mce.mat', 'irfs_mce');
        fprintf('  saved_irfs_mce.mat written\n');
end

fprintf('=== Done ===\n');
