%% run_post_mcmc.m — refresh IRFs and saved_irfs files after MCMC completes
%
% Runs each model variant (var, hybrid, mce) and saves the IRFs in the
% format the Python regen scripts expect (saved_irfs_var.mat with
% irfs_var struct, etc.).
%
% Should be run AFTER run_bayesian_mcmc.m has completed and the .mod
% parameter values reflect the new posterior modes (which the bayesian
% mcmc step writes back implicitly via M_.params updates — but the .mod
% file text isn't auto-edited, so we re-run with current .mod text which
% still has the calibrated initial values).
%
% NOTE: After run_bayesian_mcmc, the saved bayesian_mcmc_results.mat
% holds the new posterior modes in oo_.posterior_mode. To refresh the .mod
% files with these, run extract_mcmc_results which writes mcmc_writeback.txt
% and the user can paste into the .mod (or we can do that programmatically
% with a small helper).

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

regimes = {'au_pac_var', 'au_pac', 'au_pac_mce'};
tags    = {'var', 'hybrid', 'mce'};

for r = 1:3
    fprintf('\n--- [%d/3] Running %s ---\n', r, regimes{r});
    try
        evalin('base', 'clear M_ oo_ options_');
        eval(['dynare ' regimes{r} ' noclearall nograph']);
        irfs_struct = oo_.irfs;
        switch tags{r}
            case 'var'
                irfs_var = irfs_struct;
                save('saved_irfs_var.mat', 'irfs_var');
            case 'hybrid'
                irfs_hybrid = irfs_struct;
                save('saved_irfs_hybrid.mat', 'irfs_hybrid');
            case 'mce'
                irfs_mce = irfs_struct;
                save('saved_irfs_mce.mat', 'irfs_mce');
        end
        fprintf('  saved_irfs_%s.mat written\n', tags{r});
    catch ME
        fprintf('  ERROR running %s: %s\n', regimes{r}, ME.message);
    end
end

fprintf('\n=== Post-MCMC IRF refresh complete ===\n');
