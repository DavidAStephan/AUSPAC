// test_var_pac.mod — Test: var_model PAC with enriched E-SAT auxiliary
// Minimal test: E-SAT core (3 eqs) + 1 PAC auxiliary + 1 PAC equation
// If this works, we extend to the full model.

var y_gap i_gap pi_gap   // E-SAT core (simplified)
    piQ_star_hat          // VA price target gap (auxiliary in VAR)
    piQ                   // VA price (main model, PAC equation)
    pQ_level              // accumulated VA price level (for PAC diff form)
;

varexo eps_y eps_i eps_pi eps_pQ_aux eps_pQ;

parameters
    // E-SAT core
    lambda_q sigma_q lambda_i alpha_i beta_i_par lambda_pi kappa_pi
    // Auxiliary
    rho_pQ_hat a_pQ_y a_pQ_i a_pQ_pi
    // PAC
    b0_pQ b1_pQ b2_pQ beta_pac
    // SS
    pi_ss
;

// E-SAT core (simplified IS-Phillips-Taylor)
lambda_q  = 0.45;
sigma_q   = 0.17;
lambda_i  = 0.83;
alpha_i   = 0.28;
beta_i_par = 0.14;
lambda_pi = 0.26;
kappa_pi  = 0.06;

// Auxiliary (from FR-BDF Table 4.4.4 / eq 57 pattern)
rho_pQ_hat = 0.70;
a_pQ_y     = 0.08;     // output gap -> VA price target gap
a_pQ_i     = -0.03;    // interest rate -> VA price target gap
a_pQ_pi    = 0.02;     // inflation -> VA price target gap

// PAC
b0_pQ     = 0.06;
b1_pQ     = 0.50;
b2_pQ     = 0.09;
beta_pac  = 0.98;
pi_ss     = 0.00;  // detrended

// -----------------------------------------------------------------------
// VAR model: E-SAT core + VA price auxiliary
// All equations in pure VAR(1) form: x = f(x(-1)) + eps
// -----------------------------------------------------------------------

var_model(model_name = esat_enriched, eqtags = ['var_y', 'var_i', 'var_pi', 'var_pQ_hat']);

// PAC model references the enriched VAR
// The target is piQ_star_hat (the auxiliary gap variable in the VAR)
pac_model(auxiliary_model_name = esat_enriched, discount = beta_pac, model_name = pac_piQ);

model;

    // === E-SAT CORE in pure VAR(1) form ===
    // IS curve (no contemporaneous terms — lagged only)
    [name = 'var_y']
    y_gap = lambda_q * y_gap(-1) - sigma_q * (i_gap(-1) - pi_gap(-1)) + eps_y;

    // Taylor rule (lagged feedback)
    [name = 'var_i']
    i_gap = lambda_i * i_gap(-1) + (1 - lambda_i) * (alpha_i * pi_gap(-1) + beta_i_par * y_gap(-1)) + eps_i;

    // Phillips curve
    [name = 'var_pi']
    pi_gap = lambda_pi * pi_gap(-1) + kappa_pi * y_gap(-1) + eps_pi;

    // === AUXILIARY: VA price target gap (FR-BDF Table 4.4.4 style) ===
    // This is the key: it's INSIDE the var_model, so the companion matrix
    // includes E-SAT dynamics + auxiliary dynamics jointly.
    [name = 'var_pQ_hat']
    piQ_star_hat = rho_pQ_hat * piQ_star_hat(-1)
                 + a_pQ_y * y_gap(-1)
                 + a_pQ_i * i_gap(-1)
                 + a_pQ_pi * pi_gap(-1)
                 + eps_pQ_aux;

    // === MAIN MODEL: VA price PAC equation ===
    // piQ adjusts toward piQ_star_hat with PAC adjustment costs
    // pQ_level accumulates piQ for Dynare PAC diff() form
    [name = 'eq_pQ_level']
    pQ_level = pQ_level(-1) + piQ;

    [name = 'eq_piQ_pac']
    diff(pQ_level) = b0_pQ * (piQ_star_hat(-1) - pQ_level(-1))
                   + b1_pQ * diff(pQ_level(-1))
                   + pac_expectation(pac_piQ)
                   + b2_pQ * y_gap
                   + eps_pQ;

end;

shocks;
    var eps_y;      stderr 0.34;
    var eps_i;      stderr 0.10;
    var eps_pi;     stderr 0.26;
    var eps_pQ_aux; stderr 0.50;
    var eps_pQ;     stderr 0.50;
end;

// Initialize and compute PAC parameters
pac.initialize('pac_piQ');
pac.update.expectation('pac_piQ');

stoch_simul(order=1, irf=40, nograph) y_gap i_gap pi_gap piQ piQ_star_hat;
