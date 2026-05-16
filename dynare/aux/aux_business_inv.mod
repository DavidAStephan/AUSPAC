// --+ options: stochastic,json=compute +--
// =========================================================================
// aux_business_inv.mod — Phase T aux file for business_inv PAC equation
// AUTO-GENERATED from aux/_template_helpers.py
// =========================================================================

var
    yhat_au         pi_au_gap       i_gap           u_gap
    yhat_us         pi_us_gap
    ibar            pibar_au        pibar_us
    piQ             pi_m            dln_pcom
    ib_hat          rKB_hat
    ln_ib_level
;

varexo
    eps_q           eps_i           eps_pi          eps_q_us
    eps_pi_us       eps_ibar        eps_pibar_au    eps_pibar_us
    eps_u_gap       eps_piQ         eps_pi_m        eps_pcom
    eps_var_ib      eps_var_rKB     eps_ib
;

parameters
    delta           lambda_q        sigma_q
    lambda_i        alpha_i         beta_i
    lambda_pi       kappa_pi
    lambda_q_us     lambda_pi_us    kappa_pi_us
    lambda_ibar     lambda_pibar    lambda_pibar_us
    rho_u_gap       okun_coeff
    alpha_pc        beta_pc_m       gamma_oil
    i_ss            pi_ss_au        pi_ss_us
    rho_piQ         rho_pi_m        rho_pcom
    rho_ib_aux      a_ib_y          a_ib_pi         a_ib_u
    rho_rKB_aux     a_rKB_i
    b0_ib           b1_ib           b2_ib           b3_ib
    beta_pac
;

delta           = 0.1989;       lambda_q        = 0.6959;       sigma_q         = 0.0648;
lambda_i        = 0.9576;       alpha_i         = 0.3001;       beta_i          = 0.0837;
lambda_pi       = 0.2902;       kappa_pi        = 0.0374;
lambda_q_us     = 0.8057;       lambda_pi_us    = 0.6529;       kappa_pi_us     = 0.0131;
lambda_ibar     = 0.985;        lambda_pibar    = 0.93;         lambda_pibar_us = 0.93;
rho_u_gap       = 0.94;         okun_coeff      = -0.33;
alpha_pc        = 0.17;         beta_pc_m       = 0.10;         gamma_oil       = 0.03;
i_ss            = 1.0491;       pi_ss_au        = 0.625;        pi_ss_us        = 0.5;
rho_piQ         = 0.85;         rho_pi_m        = 0.7;          rho_pcom        = 0.42;
rho_ib_aux      = 0.6;           a_ib_y          = 0.15;          a_ib_pi         = 0.04;
a_ib_u          = -0.02;
rho_rKB_aux     = 0.55;          a_rKB_i         = 0.24;
b0_ib           = 0.0180;        b1_ib           = 0.0818;        b2_ib           = 0.0;           b3_ib           = 0.3144;
beta_pac        = 0.98;

var_model(model_name = esat_business_inv,
    eqtags = [
        'var_yhat_au', 'var_i_gap', 'var_pi_au_gap', 'var_u_gap',
        'var_yhat_us', 'var_pi_us_gap',
        'var_ibar', 'var_pibar_au', 'var_pibar_us',
        'var_piQ', 'var_pi_m', 'var_dln_pcom',
        'var_ib', 'var_rKB'
    ]);

pac_model(auxiliary_model_name = esat_business_inv, discount = beta_pac, model_name = pac_ib);

model;

    [name = 'var_yhat_au']
    yhat_au = lambda_q*yhat_au(-1) - sigma_q*(i_gap(-1) - pi_au_gap(-1)) + delta*yhat_us(-1) + eps_q;

    [name = 'var_i_gap']
    i_gap = lambda_i*i_gap(-1) + (1-lambda_i)*(alpha_i*pi_au_gap(-1) + beta_i*yhat_au(-1)) + eps_i;

    [name = 'var_pi_au_gap']
    pi_au_gap = lambda_pi*pi_au_gap(-1) + kappa_pi*yhat_au(-1)
              + alpha_pc*(piQ(-1) - pibar_au(-1)) + beta_pc_m*(pi_m(-1) - pibar_au(-1))
              + gamma_oil*dln_pcom(-1) + eps_pi;

    [name = 'var_u_gap']
    u_gap = rho_u_gap*u_gap(-1) + okun_coeff*yhat_au(-1) + eps_u_gap;

    [name = 'var_yhat_us']
    yhat_us = lambda_q_us*yhat_us(-1) + eps_q_us;

    [name = 'var_pi_us_gap']
    pi_us_gap = lambda_pi_us*pi_us_gap(-1) + kappa_pi_us*yhat_us(-1) + eps_pi_us;

    [name = 'var_ibar']
    ibar = lambda_ibar*ibar(-1) + (1-lambda_ibar)*i_ss + eps_ibar;

    [name = 'var_pibar_au']
    pibar_au = lambda_pibar*pibar_au(-1) + (1-lambda_pibar)*pi_ss_au + eps_pibar_au;

    [name = 'var_pibar_us']
    pibar_us = lambda_pibar_us*pibar_us(-1) + (1-lambda_pibar_us)*pi_ss_us + eps_pibar_us;

    [name = 'var_piQ']
    piQ = rho_piQ*piQ(-1) + (1-rho_piQ)*pi_ss_au + eps_piQ;

    [name = 'var_pi_m']
    pi_m = rho_pi_m*pi_m(-1) + (1-rho_pi_m)*pi_ss_au + eps_pi_m;

    [name = 'var_dln_pcom']
    dln_pcom = rho_pcom*dln_pcom(-1) + eps_pcom;

    [name = 'var_ib']
    ib_hat = rho_ib_aux*ib_hat(-1) + a_ib_y*yhat_au(-1) + a_ib_pi*pi_au_gap(-1) + a_ib_u*u_gap(-1) + eps_var_ib;

    [name = 'var_rKB']
    rKB_hat = rho_rKB_aux*rKB_hat(-1) + a_rKB_i*i_gap(-1) + eps_var_rKB;



    [name = 'eq_dln_ib_pac']
    diff(ln_ib_level) = b0_ib*(ib_hat(-1) - ln_ib_level(-1))
                      + b1_ib*diff(ln_ib_level(-1))
                      + b2_ib*diff(ln_ib_level(-2))
                      + pac_expectation(pac_ib)
                      + b3_ib*yhat_au
                      + eps_ib;

end;

shocks;
    var eps_q;          stderr 0.527;
    var eps_i;          stderr 0.110;
    var eps_pi;         stderr 0.590;
    var eps_q_us;       stderr 1.138;
    var eps_pi_us;      stderr 0.319;
    var eps_ibar;       stderr 0.01;
    var eps_pibar_au;   stderr 0.01;
    var eps_pibar_us;   stderr 0.01;
    var eps_u_gap;      stderr 0.05;
    var eps_piQ;        stderr 0.571;
    var eps_pi_m;       stderr 0.5;
    var eps_pcom;       stderr 3.0;
    var eps_var_ib;       stderr 0.01;
    var eps_var_rKB;       stderr 0.01;
    var eps_ib;       stderr 2.78;
end;

pac.initialize('pac_ib');
pac.update.expectation('pac_ib');
pac.print('pac_ib', 'eq_dln_ib_pac');
