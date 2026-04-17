function test_full_system()
%% test_full_system.m — Comprehensive end-to-end system test
% Tests every stage of the AUSPAC pipeline.
% Scripts that call 'clear' (estimate_esat, esat_model) are run fresh
% and validated by checking their output files.
% Dynare models and PAC estimation run in-process.

close all;

projectdir = fileparts(mfilename('fullpath'));
if isempty(projectdir), projectdir = pwd; end
dynaredir  = fullfile(projectdir, 'dynare');
addpath(dynaredir);
setup_dynare_path();

logfile    = fullfile(dynaredir, 'full_system_test_results.txt');

fid = fopen(logfile, 'w');
t0 = tic;

fprintf(fid, 'AUSPAC FULL SYSTEM TEST\n');
fprintf(fid, 'Timestamp: %s\n', datestr(now));
fprintf(fid, 'MATLAB: %s\n', version);
fprintf(fid, 'Dynare: 6.5\n');

np = 0; nf = 0; fl = {};

%% =================================================================
%  STAGE 1: DATA LOADING & TRANSFORMATION
%  =================================================================
W(fid, '\n=== STAGE 1: DATA LOADING & TRANSFORMATION ===');
cd(projectdir);

try
    T_base = readtable(fullfile(projectdir, 'dataset.csv'));
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('dataset.csv: %d rows x %d cols', height(T_base), width(T_base)), true, '');

    req = {'date','au_ygap','au_pi','au_irate','us_ygap','us_pi','i_bar','pi_bar_au'};
    miss = setdiff(req, T_base.Properties.VariableNames);
    [np,nf,fl] = R(fid,np,nf,fl,'S1', 'Required columns', isempty(miss), strjoin(miss,','));

    yhat = T_base.au_ygap;
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('au_ygap: %d valid, [%.2f,%.2f]', sum(~isnan(yhat)), min(yhat), max(yhat)), sum(~isnan(yhat))>80, '');
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S1','dataset.csv',false,ME.message);
end

try
    T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('extended_dataset.csv: %d rows', height(T_ext)), true, '');

    req2 = {'au_consumption','au_gfcf_nondwelling','au_gfcf_dwelling','au_employment','au_urate','au_i10','au_pi_w'};
    miss2 = setdiff(req2, T_ext.Properties.VariableNames);
    [np,nf,fl] = R(fid,np,nf,fl,'S1', 'Extended columns', isempty(miss2), strjoin(miss2,','));

    base_d = datetime(T_base.date,'InputFormat','yyyy-MM-dd');
    ext_d  = datetime(T_ext.date,'InputFormat','yyyy-MM-dd');
    [np,nf,fl] = R(fid,np,nf,fl,'S1', 'Date alignment', isequal(base_d, ext_d), '');
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S1','extended_dataset.csv',false,ME.message);
end

try
    i_gap = T_base.au_irate/4 - T_base.i_bar;
    dln_c = [NaN; diff(log(T_ext.au_consumption))]*100;
    dln_ib = [NaN; diff(log(T_ext.au_gfcf_nondwelling))]*100;
    dln_ih = [NaN; diff(log(T_ext.au_gfcf_dwelling))]*100;
    dln_n  = [NaN; diff(log(T_ext.au_employment))]*100;
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('i_gap [%.3f,%.3f]', min(i_gap), max(i_gap)), max(abs(i_gap))<5, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('dln_c std=%.3f', std(dln_c,'omitnan')), std(dln_c,'omitnan')>0.1, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('dln_ib std=%.3f', std(dln_ib,'omitnan')), std(dln_ib,'omitnan')>0.1, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('dln_ih std=%.3f', std(dln_ih,'omitnan')), std(dln_ih,'omitnan')>0.1, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S1', sprintf('dln_n std=%.3f', std(dln_n,'omitnan')), std(dln_n,'omitnan')>0.1, '');
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S1','Transforms',false,ME.message);
end

%% =================================================================
%  STAGE 2: E-SAT OLS ESTIMATION (validate outputs)
%  =================================================================
W(fid, '\n=== STAGE 2: E-SAT OLS ESTIMATION ===');

% estimate_esat.m calls clear — validate from existing params.mat
pfile = fullfile(projectdir, 'params.mat');
[np,nf,fl] = R(fid,np,nf,fl,'S2', 'params.mat exists', exist(pfile,'file')==2, 'Run estimate_esat.m first');
if exist(pfile,'file')
    S = load(pfile, 'params'); p = S.params;
    [np,nf,fl] = R(fid,np,nf,fl,'S2', sprintf('lambda_q=%.4f', p.lambda_q), p.lambda_q>0.3 && p.lambda_q<0.99, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S2', sprintf('lambda_i=%.4f', p.lambda_i), p.lambda_i>0.7 && p.lambda_i<1.0, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S2', sprintf('kappa_pi=%.4f (>0)', p.kappa_pi), p.kappa_pi>0, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S2', sprintf('sigma_q=%.4f (>0)', p.sigma_q), p.sigma_q>0, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S2', sprintf('delta=%.4f (spillover)', p.delta), p.delta>0, '');
end

%% =================================================================
%  STAGE 3: E-SAT MODEL BUILD & IRFs (validate outputs)
%  =================================================================
W(fid, '\n=== STAGE 3: E-SAT MODEL & IRFs ===');

[np,nf,fl] = R(fid,np,nf,fl,'S3', 'esat_model.m exists', exist(fullfile(projectdir,'esat_model.m'),'file')==2, '');
[np,nf,fl] = R(fid,np,nf,fl,'S3', 'irf_interest_rate.png', exist(fullfile(projectdir,'irf_interest_rate.png'),'file')==2, '');
[np,nf,fl] = R(fid,np,nf,fl,'S3', 'irf_us_output_gap.png', exist(fullfile(projectdir,'irf_us_output_gap.png'),'file')==2, '');
[np,nf,fl] = R(fid,np,nf,fl,'S3', 'data.mat exists', exist(fullfile(projectdir,'data.mat'),'file')==2, '');

%% =================================================================
%  STAGE 4: EXTENDED DATA PREP
%  =================================================================
W(fid, '\n=== STAGE 4: EXTENDED DATA PREPARATION ===');
% prepare_estimation_data.m calls 'clear' — validate output file instead
ef = fullfile(dynaredir, 'estimation_data.mat');
[np,nf,fl] = R(fid,np,nf,fl,'S4', 'estimation_data.mat exists', exist(ef,'file')==2, 'Run prepare_estimation_data.m');
if exist(ef,'file')
    S = load(ef);
    nv = length(fieldnames(S));
    no = length(S.yhat_au);
    [np,nf,fl] = R(fid,np,nf,fl,'S4', sprintf('%d vars x %d obs', nv, no), nv>=9 && no>100, '');
    % Check key variables are demeaned
    [np,nf,fl] = R(fid,np,nf,fl,'S4', sprintf('yhat_au mean=%.4f (demeaned)', mean(S.yhat_au)), abs(mean(S.yhat_au))<0.5, '');
    [np,nf,fl] = R(fid,np,nf,fl,'S4', sprintf('dln_c mean=%.4f (demeaned)', mean(S.dln_c)), abs(mean(S.dln_c))<0.5, '');
end
emf = fullfile(dynaredir, 'estimation_meta.mat');
[np,nf,fl] = R(fid,np,nf,fl,'S4', 'estimation_meta.mat exists', exist(emf,'file')==2, '');

%% =================================================================
%  STAGE 5: DYNARE AU_PAC_VAR (backward)
%  =================================================================
W(fid, '\n=== STAGE 5: DYNARE AU_PAC_VAR (backward) ===');
cd(dynaredir);
clear_dynare_globals();

try
    dynare au_pac_var noclearall nograph
    global M_ oo_
    [np,nf,fl] = R(fid,np,nf,fl,'S5', sprintf('Compiles: %d endo %d exo', M_.endo_nbr, M_.exo_nbr), M_.endo_nbr>=60, '');
    me = max(abs(oo_.dr.eigval));
    [np,nf,fl] = R(fid,np,nf,fl,'S5', sprintf('Max|eig|=%.4f', me), me<1.01, '');
    bk = check_bk(M_, oo_);
    [np,nf,fl] = R(fid,np,nf,fl,'S5', 'BK conditions', bk, '');

    if isfield(oo_,'irfs') && isfield(oo_.irfs,'yhat_au_eps_i')
        y = oo_.irfs.yhat_au_eps_i;
        [np,nf,fl] = R(fid,np,nf,fl,'S5', sprintf('MP->output trough=%.4f%%', min(y)), min(y)<0, '');
        irfs_var = oo_.irfs; %#ok
        save(fullfile(dynaredir,'saved_irfs_var.mat'), 'irfs_var');
    else
        [np,nf,fl] = R(fid,np,nf,fl,'S5','IRFs exist',false,'Missing');
    end
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S5','au_pac_var',false,ME.message);
end

%% =================================================================
%  STAGE 6: DYNARE AU_PAC (hybrid)
%  =================================================================
W(fid, '\n=== STAGE 6: DYNARE AU_PAC (hybrid) ===');
cd(dynaredir);
clear_dynare_globals();

try
    dynare au_pac noclearall nograph
    global M_ oo_
    [np,nf,fl] = R(fid,np,nf,fl,'S6', sprintf('Compiles: %d endo %d exo', M_.endo_nbr, M_.exo_nbr), M_.endo_nbr>=60, '');
    me = max(abs(oo_.dr.eigval));
    [np,nf,fl] = R(fid,np,nf,fl,'S6', sprintf('Max|eig|=%.4f', me), me<1.01, '');
    bk = check_bk(M_, oo_);
    [np,nf,fl] = R(fid,np,nf,fl,'S6', 'BK conditions', bk, '');

    if isfield(M_,'pac')
        [np,nf,fl] = R(fid,np,nf,fl,'S6', sprintf('%d PAC models', length(fieldnames(M_.pac))), length(fieldnames(M_.pac))==5, '');
    end

    if isfield(oo_,'irfs') && isfield(oo_.irfs,'yhat_au_eps_i')
        sh = 'eps_i';
        vars_check = {'yhat_au','pi_au','dln_c','dln_ib','dln_ih','dln_n','pi_w','s_gap','i_10y','piQ'};
        for v = 1:length(vars_check)
            fld = [vars_check{v} '_' sh];
            if isfield(oo_.irfs, fld)
                pk = max(abs(oo_.irfs.(fld)));
                [np,nf,fl] = R(fid,np,nf,fl,'S6', sprintf('IRF %s peak=%.4f', vars_check{v}, pk), pk>0, '');
            else
                [np,nf,fl] = R(fid,np,nf,fl,'S6', sprintf('IRF %s', vars_check{v}), false, 'Missing');
            end
        end
        irfs_hybrid = oo_.irfs; %#ok
        save(fullfile(dynaredir,'saved_irfs_hybrid.mat'), 'irfs_hybrid');
    else
        [np,nf,fl] = R(fid,np,nf,fl,'S6','IRFs exist',false,'Missing');
    end
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S6','au_pac',false,ME.message);
end

%% =================================================================
%  STAGE 7: DYNARE AU_PAC_MCE (forward)
%  =================================================================
W(fid, '\n=== STAGE 7: DYNARE AU_PAC_MCE (forward) ===');
cd(dynaredir);
clear_dynare_globals();

try
    dynare au_pac_mce noclearall nograph
    global M_ oo_
    [np,nf,fl] = R(fid,np,nf,fl,'S7', sprintf('Compiles: %d endo', M_.endo_nbr), M_.endo_nbr>=60, '');
    bk = check_bk(M_, oo_);
    [np,nf,fl] = R(fid,np,nf,fl,'S7', 'BK conditions', bk, '');
    nfwd = M_.nfwrd + M_.nboth;
    [np,nf,fl] = R(fid,np,nf,fl,'S7', sprintf('%d forward vars (expect >0)', nfwd), nfwd>0, '');

    if isfield(oo_,'irfs') && isfield(oo_.irfs,'yhat_au_eps_i')
        y = oo_.irfs.yhat_au_eps_i;
        [np,nf,fl] = R(fid,np,nf,fl,'S7', sprintf('MP->output trough=%.4f%%', min(y)), min(y)<0, '');
        irfs_mce = oo_.irfs; %#ok
        save(fullfile(dynaredir,'saved_irfs_mce.mat'), 'irfs_mce');
    else
        [np,nf,fl] = R(fid,np,nf,fl,'S7','IRFs exist',false,'Missing');
    end
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S7','au_pac_mce',false,ME.message);
end

%% =================================================================
%  STAGE 8: PAC STRUCTURAL ESTIMATION (iterative OLS)
%  =================================================================
W(fid, '\n=== STAGE 8: PAC ESTIMATION (iterative OLS) ===');
cd(dynaredir);
clear_dynare_globals();

try
    dynare au_pac json=compute noclearall nograph
    global M_ oo_
    [np,nf,fl] = R(fid,np,nf,fl,'S8', 'json=compute OK', true, '');

    if ~isstruct(oo_.var), oo_.var = struct(); end
    get_companion_matrix('esat_enriched', 'var');
    CM = oo_.var.esat_enriched.CompanionMatrix;
    [np,nf,fl] = R(fid,np,nf,fl,'S8', sprintf('Companion %dx%d', size(CM,1), size(CM,2)), size(CM,1)==12 && ~any(isnan(CM(:))), '');

    for k = 1:5
        pn = {'pac_pQ','pac_c','pac_ib','pac_ih','pac_n'};
        pac.initialize(pn{k}); pac.update.expectation(pn{k});
    end
    [np,nf,fl] = R(fid,np,nf,fl,'S8', '5 PAC models initialized', true, '');

    db = prepare_pac_dseries();
    [np,nf,fl] = R(fid,np,nf,fl,'S8', sprintf('dseries %d vars x %d obs', db.vobs, db.nobs), db.vobs>=50, '');

    er = dates('1994Q2'):dates('2023Q3');
    pac_eqs    = {'eq_piQ_pac','eq_dln_c_pac','eq_dln_ib_pac','eq_dln_ih_pac','eq_dln_n_pac'};
    pac_labels = {'VA Price','Consumption','Bus.Inv.','Hhold.Inv.','Employment'};
    pac_oo     = {'pac_pQ','pac_c','pac_ib','pac_ih','pac_n'};
    pac_params = {
        struct('b0_pQ',0.06,'b1_pQ',0.50,'b2_pQ',0.09,'b_covid_crash_pQ',0,'b_covid_bounce_pQ',0)
        struct('b0_c',0.06,'b1_c',0.149,'b2_c',-0.02,'b3_c',0.139,'b_di_c',0,'b_covid_crash_c',0,'b_covid_bounce_c',0)
        struct('b0_ib',0.030,'b1_ib',0.181,'b2_ib',0.10,'b3_ib',0.191,'b_covid_crash_ib',0,'b_covid_bounce_ib',0)
        struct('b0_ih',0.049,'b1_ih',0.210,'b2_ih',0.08,'b3_ih',0.12,'b_ph_ih',0,'b_covid_crash_ih',0,'b_covid_bounce_ih',0)
        struct('b0_n',0.040,'b1_n',0.30,'b2_n',0.10,'b3_n',0.05,'b4_n',0.02,'b5_n',0.12,'b_covid_crash_n',0,'b_covid_bounce_n',0)
    };

    for eq = 1:5
        try
            pac.estimate.iterative_ols(pac_eqs{eq}, pac_params{eq}, db, er);
            est = oo_.pac.(pac_oo{eq}).estimator;
            ssr = oo_.pac.(pac_oo{eq}).ssr;
            T = length(oo_.pac.(pac_oo{eq}).residual);
            pnames = fieldnames(pac_params{eq});
            detail = '';
            for j=1:length(pnames)
                detail = [detail sprintf('%s:%.3f->%.3f ', pnames{j}, pac_params{eq}.(pnames{j}), est(j))]; %#ok
            end
            [np,nf,fl] = R(fid,np,nf,fl,'S8', sprintf('%s: SSR=%.1f T=%d', pac_labels{eq}, ssr, T), true, detail);
        catch ME
            [np,nf,fl] = R(fid,np,nf,fl,'S8', pac_labels{eq}, false, ME.message);
        end
    end
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S8','PAC setup',false,ME.message);
    for k=1:min(3,length(ME.stack))
        W(fid, sprintf('  at %s line %d', ME.stack(k).name, ME.stack(k).line));
    end
end

%% =================================================================
%  STAGE 9: PAC NLS ESTIMATION
%  =================================================================
W(fid, '\n=== STAGE 9: PAC NLS ESTIMATION ===');

try
    global oo_ %#ok
    if isstruct(oo_.var) && isfield(oo_.var,'esat_enriched')
        p = struct('b0_c',0.06,'b1_c',0.149,'b2_c',-0.02,'b3_c',0.139);
        pac.estimate.nls('eq_dln_c_pac', p, db, er, 'csminwel', 'MaxIter', 50);
        est = oo_.pac.pac_c.estimator;
        [np,nf,fl] = R(fid,np,nf,fl,'S9', sprintf('NLS Consumption: b0=%.4f b1=%.4f', est(1), est(2)), true, '');
    else
        [np,nf,fl] = R(fid,np,nf,fl,'S9','NLS',false,'No companion matrix');
    end
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S9','NLS',false,ME.message);
end

%% =================================================================
%  STAGE 10: THREE-REGIME IRF COMPARISON
%  =================================================================
W(fid, '\n=== STAGE 10: THREE-REGIME IRF COMPARISON ===');

try
    fv = fullfile(dynaredir,'saved_irfs_var.mat');
    fh = fullfile(dynaredir,'saved_irfs_hybrid.mat');
    fm = fullfile(dynaredir,'saved_irfs_mce.mat');
    has_all = exist(fv,'file')==2 && exist(fh,'file')==2 && exist(fm,'file')==2;
    [np,nf,fl] = R(fid,np,nf,fl,'S10', 'All 3 IRF files', has_all, '');

    if has_all
        load(fv,'irfs_var'); load(fh,'irfs_hybrid'); load(fm,'irfs_mce');
        sh = 'eps_i';

        yv = irfs_var.(['yhat_au_' sh]);
        yh = irfs_hybrid.(['yhat_au_' sh]);
        ym = irfs_mce.(['yhat_au_' sh]);

        W(fid, sprintf('  Output trough: VAR=%.4f%% Hybrid=%.4f%% MCE=%.4f%%', min(yv), min(yh), min(ym)));
        [np,nf,fl] = R(fid,np,nf,fl,'S10', 'All negative output response', min(yv)<0&&min(yh)<0&&min(ym)<0, '');

        dvm = max(abs(yv - ym));
        [np,nf,fl] = R(fid,np,nf,fl,'S10', sprintf('VAR-MCE diff=%.6f', dvm), dvm>1e-6, 'Regimes should differ');

        % Sign checks
        for vn = {'yhat_au','pi_au','dln_c','dln_ib'}
            fld = [vn{1} '_' sh];
            if isfield(irfs_hybrid, fld)
                [np,nf,fl] = R(fid,np,nf,fl,'S10', sprintf('Hybrid %s<0 (%.4f)', vn{1}, min(irfs_hybrid.(fld))), ...
                    min(irfs_hybrid.(fld))<0, '');
            end
        end

        % Comparison table
        W(fid, '');
        W(fid, sprintf('  %-12s %10s %10s %10s', 'Variable', 'VAR(Q4)', 'Hybrid(Q4)', 'MCE(Q4)'));
        cvars = {'yhat_au','pi_au','piQ','dln_c','dln_ib','dln_ih','dln_n','pi_w','i_10y'};
        a3 = {irfs_var, irfs_hybrid, irfs_mce};
        for v = 1:length(cvars)
            fld = [cvars{v} '_' sh];
            val = [0 0 0];
            for r=1:3
                if isfield(a3{r},fld) && length(a3{r}.(fld))>=4, val(r)=a3{r}.(fld)(4); end
            end
            W(fid, sprintf('  %-12s %10.4f %10.4f %10.4f', cvars{v}, val(1), val(2), val(3)));
        end
    end
catch ME
    [np,nf,fl] = R(fid,np,nf,fl,'S10','Comparison',false,ME.message);
end

%% =================================================================
%  SUMMARY
%  =================================================================
elapsed = toc(t0);
W(fid, '');
W(fid, sprintf('====== SUMMARY: %d PASS, %d FAIL (%.1f sec) ======', np, nf, elapsed));
if nf > 0
    W(fid, ''); W(fid, 'FAILURES:');
    for k=1:length(fl), W(fid, sprintf('  %s', fl{k})); end
end
W(fid, '--- END OF TEST ---');
fclose(fid);

fprintf('\n=== FULL SYSTEM TEST COMPLETE ===\n');
fprintf('Results: %d PASS, %d FAIL (%.1f sec)\n', np, nf, elapsed);
fprintf('Log: %s\n', logfile);
end

%% helpers
function W(fid, s), fprintf(fid, '%s\n', s); end

function [np,nf,fl] = R(fid, np, nf, fl, stg, name, ok, detail)
if ok
    np=np+1; fprintf(fid, '  [PASS] [%s] %s\n', stg, name);
else
    nf=nf+1; fprintf(fid, '  [FAIL] [%s] %s: %s\n', stg, name, detail);
    fl{end+1} = sprintf('[%s] %s: %s', stg, name, detail);
end
end

function ok = check_bk(M_, oo_)
try
    nu = sum(abs(oo_.dr.eigval)>1);
    nf = M_.nfwrd + M_.nboth;
    ok = (nu==nf);
catch, ok=false; end
end

function clear_dynare_globals()
    evalin('caller', 'clear global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info');
end
