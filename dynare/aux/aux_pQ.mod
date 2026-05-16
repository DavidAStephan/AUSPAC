// --+ options: stochastic,json=compute +--
// =========================================================================
// aux_pQ.mod — Phase T aux file for VA-price PAC equation
//
// PURPOSE (estimation only, never simulated directly): use Dynare's
// var_model + pac_model infrastructure to compute the closed-form
// expectation formula for pac_expectation(pac_pQ). The formula is then
// cherrypicked and pasted into the simulation au_pac_v2.mod by the
// aggregator.
//
// KEY DIFFERENCE FROM PHASE S au_pac.mod:
// - The var_model variables are now the STRUCTURAL E-SAT core variables
//   (yhat_au, i_gap, pi_au_gap, ...), not shadow copies (y_gap_var, ...).
// - Each var_model eqtag's equation is in pure-VAR form (lagged-only RHS).
// - When eps_pQ moves piQ structurally in the simulation model, the
//   expectation formula propagates it via piQ(-1) in next period —
//   closing the cost-push transmission channel into PAC expectations.
// =========================================================================

// -----------------------------------------------------------------------
// Endogenous variables (minimal subset needed for the E-SAT companion +
// piQ_hat auxiliary regression + VA-price PAC)
// -----------------------------------------------------------------------
var
    // E-SAT core (8 + intercept)
    yhat_au         pi_au_gap       i_gap           u_gap
    yhat_us         pi_us_gap
    ibar            pibar_au        pibar_us
    // E-SAT auxiliary structural states (Phase T addition: structural piQ, pi_m, dln_pcom)
    piQ             pi_m            dln_pcom
    // VA-price aux regression target (the trend_component target for the PAC)
    piQ_hat
    // Cumulative levels for the PAC equation (LHS of eq_piQ_pac is diff(pQ_level))
    pQ_level
;

varexo
    eps_q           eps_i           eps_pi          eps_q_us
    eps_pi_us       eps_ibar        eps_pibar_au    eps_pibar_us
    eps_u_gap       eps_piQ         eps_pi_m        eps_pcom
    eps_var_pQ      eps_pQ
;

parameters
    // E-SAT calibrations (will be loaded from Phase S au_pac.mod values)
    delta           lambda_q        sigma_q
    lambda_i        alpha_i         beta_i
    lambda_pi       kappa_pi
    lambda_q_us     lambda_pi_us    kappa_pi_us
    lambda_ibar     lambda_pibar    lambda_pibar_us
    rho_u_gap       okun_coeff
    // Phase S structural deflator channels in eq_au_phillips
    alpha_pc        beta_pc_m       gamma_oil
    // SS anchors
    i_ss            pi_ss_au        pi_ss_us
    // piQ_hat auxiliary regression coefficients
    rho_pQ_aux      a_pQ_y          a_pQ_i          a_pQ_pi         a_pQ_u
    // piQ AR coefficient (simple AR1 for var_model purposes)
    rho_piQ
    // pi_m, dln_pcom AR coefficients (simple AR1 for var_model purposes)
    rho_pi_m        rho_pcom
    // VA-price PAC short-run coefficients
    b0_pQ           b1_pQ           b2_pQ
    // PAC discount factor
    beta_pac
;

// -----------------------------------------------------------------------
// Calibration (E-SAT params from Phase S; var_pQ aux regression coefs from
// Phase S calibration block; PAC coefs from Phase S MCMC posterior modes)
// -----------------------------------------------------------------------
delta           = 0.1989;       lambda_q        = 0.6959;       sigma_q         = 0.0648;
lambda_i        = 0.9576;       alpha_i         = 0.3001;       beta_i          = 0.0837;
lambda_pi       = 0.2902;       kappa_pi        = 0.0374;
lambda_q_us     = 0.8057;       lambda_pi_us    = 0.6529;       kappa_pi_us     = 0.0131;
lambda_ibar     = 0.985;        lambda_pibar    = 0.93;         lambda_pibar_us = 0.93;
rho_u_gap       = 0.94;         okun_coeff      = -0.33;

alpha_pc        = 0.17;         beta_pc_m       = 0.10;         gamma_oil       = 0.03;

i_ss            = 1.0491;       pi_ss_au        = 0.625;        pi_ss_us        = 0.5;

rho_pQ_aux      = 0.85;
a_pQ_y          = 0.05;         a_pQ_i          = 0.0;          a_pQ_pi         = 0.0;          a_pQ_u          = 0.0;

rho_piQ         = 0.85;         rho_pi_m        = 0.7;          rho_pcom        = 0.42;

b0_pQ           = 0.0294;       b1_pQ           = 0.2784;       b2_pQ           = 0.0022;
beta_pac        = 0.98;

// -----------------------------------------------------------------------
// var_model declaration
// -----------------------------------------------------------------------
// Eqtags refer to equations BELOW that determine each state variable in
// pure-VAR form (lagged-only RHS). The var_model companion matrix H is
// built from these equations.
var_model(model_name = esat_pQ,
    eqtags = [
        'var_yhat_au', 'var_i_gap', 'var_pi_au_gap', 'var_u_gap',
        'var_yhat_us', 'var_pi_us_gap',
        'var_ibar', 'var_pibar_au', 'var_pibar_us',
        'var_piQ', 'var_pi_m', 'var_dln_pcom',
        'var_piQ_hat'
    ]);

pac_model(auxiliary_model_name = esat_pQ, discount = beta_pac, model_name = pac_pQ);

model;

    // ---------------------------------------------------------------
    // E-SAT core equations in PURE-VAR FORM (lagged-only RHS)
    // ---------------------------------------------------------------
    // Note: contemporaneous yhat_us in eq_au_is becomes yhat_us(-1) here.
    // The contemporaneous-term version lives in the simulation model.inc.
    [name = 'var_yhat_au']
    yhat_au = lambda_q*yhat_au(-1) - sigma_q*(i_gap(-1) - (pi_au_gap(-1))) + delta*yhat_us(-1) + eps_q;

    [name = 'var_i_gap']
    i_gap = lambda_i*i_gap(-1) + (1-lambda_i)*(alpha_i*pi_au_gap(-1) + beta_i*yhat_au(-1)) + eps_i;

    // Phase S structural channels — now using LAGGED structural piQ, pi_m, dln_pcom
    [name = 'var_pi_au_gap']
    pi_au_gap = lambda_pi*pi_au_gap(-1) + kappa_pi*yhat_au(-1) + alpha_pc*(piQ(-1) - pibar_au(-1)) + beta_pc_m*(pi_m(-1) - pibar_au(-1)) + gamma_oil*dln_pcom(-1) + eps_pi;

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

    // ---------------------------------------------------------------
    // Phase T addition: STRUCTURAL piQ, pi_m, dln_pcom in pure-VAR form
    // (simple AR1; the FULL structural dynamics live in simulation/model.inc
    // where they can have contemporaneous terms and PAC equations)
    // ---------------------------------------------------------------
    [name = 'var_piQ']
    piQ = rho_piQ*piQ(-1) + (1-rho_piQ)*pi_ss_au + eps_piQ;

    [name = 'var_pi_m']
    pi_m = rho_pi_m*pi_m(-1) + (1-rho_pi_m)*pi_ss_au + eps_pi_m;

    [name = 'var_dln_pcom']
    dln_pcom = rho_pcom*dln_pcom(-1) + eps_pcom;

    // ---------------------------------------------------------------
    // piQ_hat auxiliary regression (the TARGET projection for VA-price PAC)
    // ---------------------------------------------------------------
    [name = 'var_piQ_hat']
    piQ_hat = rho_pQ_aux*piQ_hat(-1) + a_pQ_y*yhat_au(-1) + a_pQ_i*i_gap(-1) + a_pQ_pi*pi_au_gap(-1) + a_pQ_u*u_gap(-1) + eps_var_pQ;

    // ---------------------------------------------------------------
    // VA-price PAC equation — this is what pac.print expands
    // ---------------------------------------------------------------
    [name = 'eq_piQ_pac']
    diff(pQ_level) = b0_pQ*(piQ_hat(-1) - pQ_level(-1))
                   + b1_pQ*diff(pQ_level(-1))
                   + pac_expectation(pac_pQ)
                   + b2_pQ*yhat_au
                   + eps_pQ;

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
    var eps_var_pQ;     stderr 0.01;
    var eps_pQ;         stderr 0.571;
end;

// Initialize the PAC model — builds companion matrix from var_model
pac.initialize('pac_pQ');
pac.update.expectation('pac_pQ');

// Write the expectation formula files to aux_pQ/model/pac-expectations/
pac.print('pac_pQ', 'eq_piQ_pac');
