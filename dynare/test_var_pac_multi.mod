// test_var_pac_multi.mod — Test: 2 PAC equations sharing one var_model
// E-SAT core (3 eqs) + 2 PAC auxiliaries + 2 PAC equations

var y_gap i_gap pi_gap          // E-SAT core
    piQ_hat                      // VA price target gap (in VAR)
    n_hat                        // employment target gap (in VAR)
    piQ pQ_level                 // VA price PAC variables
    dln_n ln_n_level             // employment PAC variables
;

varexo eps_y eps_i eps_pi eps_pQ_aux eps_n_aux eps_pQ eps_n;

parameters
    lambda_q sigma_q lambda_i alpha_i beta_i_par lambda_pi kappa_pi
    rho_pQ_hat a_pQ_y a_pQ_i a_pQ_pi
    rho_n_hat a_n_y a_n_i a_n_pi
    b0_pQ b1_pQ b2_pQ
    b0_n b1_n b5_n
    beta_pac
;

lambda_q = 0.45; sigma_q = 0.17; lambda_i = 0.83; alpha_i = 0.28;
beta_i_par = 0.14; lambda_pi = 0.26; kappa_pi = 0.06;

rho_pQ_hat = 0.70; a_pQ_y = 0.08; a_pQ_i = -0.03; a_pQ_pi = 0.02;
rho_n_hat  = 0.67; a_n_y  = 0.12; a_n_i  = -0.03; a_n_pi  = 0.05;

b0_pQ = 0.06; b1_pQ = 0.50; b2_pQ = 0.09;
b0_n  = 0.04; b1_n  = 0.30; b5_n  = 0.12;
beta_pac = 0.98;

// ONE var_model with E-SAT core + BOTH auxiliaries
var_model(model_name = esat_full, eqtags = ['var_y', 'var_i', 'var_pi', 'var_pQ', 'var_n']);

// TWO pac_models sharing the same var_model
pac_model(auxiliary_model_name = esat_full, discount = beta_pac, model_name = pac_piQ);
pac_model(auxiliary_model_name = esat_full, discount = beta_pac, model_name = pac_n);

model;
    [name = 'var_y']
    y_gap = lambda_q * y_gap(-1) - sigma_q * (i_gap(-1) - pi_gap(-1)) + eps_y;

    [name = 'var_i']
    i_gap = lambda_i * i_gap(-1) + (1 - lambda_i) * (alpha_i * pi_gap(-1) + beta_i_par * y_gap(-1)) + eps_i;

    [name = 'var_pi']
    pi_gap = lambda_pi * pi_gap(-1) + kappa_pi * y_gap(-1) + eps_pi;

    [name = 'var_pQ']
    piQ_hat = rho_pQ_hat * piQ_hat(-1) + a_pQ_y * y_gap(-1) + a_pQ_i * i_gap(-1) + a_pQ_pi * pi_gap(-1) + eps_pQ_aux;

    [name = 'var_n']
    n_hat = rho_n_hat * n_hat(-1) + a_n_y * y_gap(-1) + a_n_i * i_gap(-1) + a_n_pi * pi_gap(-1) + eps_n_aux;

    // Accumulation levels
    [name = 'eq_pQ_level']
    pQ_level = pQ_level(-1) + piQ;

    [name = 'eq_ln_n_level']
    ln_n_level = ln_n_level(-1) + dln_n;

    // VA price PAC
    [name = 'eq_piQ_pac']
    diff(pQ_level) = b0_pQ * (piQ_hat(-1) - pQ_level(-1))
                   + b1_pQ * diff(pQ_level(-1))
                   + pac_expectation(pac_piQ)
                   + b2_pQ * y_gap
                   + eps_pQ;

    // Employment PAC (1st-order simplified for test)
    [name = 'eq_dln_n_pac']
    diff(ln_n_level) = b0_n * (n_hat(-1) - ln_n_level(-1))
                     + b1_n * diff(ln_n_level(-1))
                     + pac_expectation(pac_n)
                     + b5_n * y_gap
                     + eps_n;
end;

shocks;
    var eps_y;      stderr 0.34;
    var eps_i;      stderr 0.10;
    var eps_pi;     stderr 0.26;
    var eps_pQ_aux; stderr 0.50;
    var eps_n_aux;  stderr 0.50;
    var eps_pQ;     stderr 0.50;
    var eps_n;      stderr 0.50;
end;

pac.initialize('pac_piQ');
pac.update.expectation('pac_piQ');
pac.initialize('pac_n');
pac.update.expectation('pac_n');

stoch_simul(order=1, irf=40, nograph) y_gap i_gap pi_gap piQ dln_n piQ_hat n_hat;
