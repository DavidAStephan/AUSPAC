// =========================================================================
// au_esat_est.mod — E-SAT Core Bayesian Estimation
// All variables in gap/deviation form → SS = 0 → compatible with demeaned data
// =========================================================================

var yhat_au i_gap pi_au_gap yhat_us pi_us_gap;

varexo eps_q eps_i eps_pi eps_q_us eps_pi_us;

varobs yhat_au pi_au_gap i_gap yhat_us pi_us_gap;

parameters
    lambda_q sigma_q delta
    lambda_i alpha_i beta_i
    lambda_pi kappa_pi
    lambda_q_us lambda_pi_us kappa_pi_us
;

// Initial values for estimated parameters (prior means)
lambda_q        = 0.88;
sigma_q         = 0.08;
lambda_i        = 0.88;
alpha_i         = 0.40;
beta_i          = 0.15;
lambda_pi       = 0.50;
kappa_pi        = 0.08;

// Fixed (calibrated) parameters
delta           = 0.10;
lambda_q_us     = 0.95;
lambda_pi_us    = 0.50;
kappa_pi_us     = 0.10;

model;
    // IS curve
    yhat_au = delta * yhat_us + lambda_q * yhat_au(-1)
              - sigma_q * (i_gap(-1) - pi_au_gap(-1)) + eps_q;

    // Taylor rule (in gap form)
    i_gap = lambda_i * i_gap(-1)
            + (1 - lambda_i) * (alpha_i * pi_au_gap(-1) + beta_i * yhat_au(-1))
            + eps_i;

    // Phillips curve (in gap form)
    pi_au_gap = lambda_pi * pi_au_gap(-1) + kappa_pi * yhat_au(-1) + eps_pi;

    // US IS (simplified AR(1))
    yhat_us = lambda_q_us * yhat_us(-1) + eps_q_us;

    // US Phillips (simplified)
    pi_us_gap = lambda_pi_us * pi_us_gap(-1) + kappa_pi_us * yhat_us(-1) + eps_pi_us;
end;

steady;
check;

// -----------------------------------------------------------------------
// Priors
// -----------------------------------------------------------------------
estimated_params;
    lambda_q,   beta_pdf, 0.88, 0.05;
    sigma_q,    gamma_pdf, 0.08, 0.03;
    lambda_i,   beta_pdf, 0.88, 0.05;
    alpha_i,    gamma_pdf, 0.40, 0.15;
    beta_i,     gamma_pdf, 0.15, 0.08;
    lambda_pi,  beta_pdf, 0.50, 0.15;
    kappa_pi,   gamma_pdf, 0.08, 0.04;
    stderr eps_q,       inv_gamma_pdf, 0.50, inf;
    stderr eps_i,       inv_gamma_pdf, 0.08, inf;
    stderr eps_pi,      inv_gamma_pdf, 0.70, inf;
    stderr eps_q_us,    inv_gamma_pdf, 1.00, inf;
    stderr eps_pi_us,   inv_gamma_pdf, 0.30, inf;
end;

// -----------------------------------------------------------------------
// Estimation
// -----------------------------------------------------------------------
estimation(datafile = 'estimation_data.mat',
           first_obs = 1,
           nobs = 122,
           mh_replic = 25000,
           mh_nblocks = 2,
           mh_jscale = 0.4,
           mode_compute = 4,
           presample = 4,
           nograph);
