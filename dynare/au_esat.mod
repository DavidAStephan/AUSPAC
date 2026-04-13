// =========================================================================
// au_esat.mod
// E-SAT Expectation Satellite Model for Australia — Dynare implementation
//
// Adapted from Section 3.1.1 of Banque de France WP #736 (Lemoine et al.)
// Australia replaces France; US replaces euro area.
// RBA Taylor rule reacts to domestic variables (not foreign).
//
// This file encodes the E-SAT VAR so it can be used as an auxiliary model
// for PAC equations in the full semi-structural model.
//
// State vector: [yhat_au, i_gap, pi_au_gap, yhat_us, pi_us_gap]
// Plus anchors: [ibar, pibar_au, pibar_us]
//
// Dynare 6.5 required for full PAC support.
// =========================================================================

// -----------------------------------------------------------------------
// Variable declarations
// -----------------------------------------------------------------------

var
    // Core E-SAT variables (deviations from anchors where noted)
    yhat_au         // Australian output gap (%)
    i_au            // Australian short-term interest rate (quarterly %)
    pi_au           // Australian inflation (quarterly %)
    yhat_us         // US output gap (%)
    pi_us           // US inflation (quarterly %)
    // Long-run anchors
    ibar            // LR interest rate anchor (quarterly %)
    pibar_au        // LR Australian inflation anchor (quarterly %)
    pibar_us        // LR US inflation anchor (quarterly %)
    // Gap variables (for convenience)
    i_gap           // i_au - ibar
    pi_au_gap       // pi_au - pibar_au
    pi_us_gap       // pi_us - pibar_us
;

varexo
    eps_q           // AU IS shock
    eps_i           // Taylor rule shock
    eps_pi          // AU Phillips shock
    eps_q_us        // US IS shock
    eps_pi_us       // US Phillips shock
    eps_ibar        // LR interest rate anchor shock
    eps_pibar_au    // LR AU inflation anchor shock
    eps_pibar_us    // LR US inflation anchor shock
;

// -----------------------------------------------------------------------
// Parameters — Bayesian posterior means from our estimation
// (loaded from params.mat via setup script, but declared with defaults here)
// -----------------------------------------------------------------------

parameters
    // AU IS curve
    delta           // AU-US output co-movement
    lambda_q        // AU IS persistence
    sigma_q         // AU real rate sensitivity
    // Taylor rule (RBA)
    lambda_i        // Taylor rule inertia
    alpha_i         // Taylor inflation response
    beta_i          // Taylor output gap response
    // AU Phillips curve
    lambda_pi       // AU Phillips persistence
    kappa_pi        // AU Phillips slope
    // US IS curve (AR1)
    lambda_q_us     // US IS persistence
    // US Phillips curve
    lambda_pi_us    // US Phillips persistence
    kappa_pi_us     // US Phillips slope
    // LR anchor persistence
    lambda_ibar
    lambda_pibar
    lambda_pibar_us
    // Steady states (quarterly)
    i_ss
    pi_ss_au
    pi_ss_us
;

// -----------------------------------------------------------------------
// Parameter values (Bayesian posterior means)
// These will be overridden by the setup script loading params.mat
// -----------------------------------------------------------------------

// Defaults from our Bayesian estimation (posterior means):
delta           = 0.1989;
lambda_q        = 0.4479;
sigma_q         = 0.1663;
lambda_i        = 0.8281;
alpha_i         = 0.2787;
beta_i          = 0.1350;
lambda_pi       = 0.2629;
kappa_pi        = 0.0582;
lambda_q_us     = 0.8057;
lambda_pi_us    = 0.6529;
kappa_pi_us     = 0.0131;
lambda_ibar     = 0.985;
lambda_pibar    = 0.93;
lambda_pibar_us = 0.93;
i_ss            = 1.0491;    // ~4.20% annualized / 4
pi_ss_au        = 0.625;     // 2.50% annualized / 4
pi_ss_us        = 0.5;       // 2.00% annualized / 4

// -----------------------------------------------------------------------
// Model equations
// -----------------------------------------------------------------------

model;

    // --- Definitions of gap variables ---
    [name = 'def_i_gap']
    i_gap = i_au - ibar;

    [name = 'def_pi_au_gap']
    pi_au_gap = pi_au - pibar_au;

    [name = 'def_pi_us_gap']
    pi_us_gap = pi_us - pibar_us;

    // --- Eq 1: Australian IS curve ---
    // yhat_au - delta*yhat_us = lambda_q*yhat_au(-1) - sigma_q*(i_gap(-1) - pi_au_gap(-1))
    [name = 'eq_au_is']
    yhat_au = delta * yhat_us
              + lambda_q * yhat_au(-1)
              - sigma_q * (i_gap(-1) - pi_au_gap(-1))
              + eps_q;

    // --- Eq 2: Taylor rule (RBA) ---
    // i_gap = lambda_i*i_gap(-1) + (1-lambda_i)*(alpha_i*pi_au_gap(-1) + beta_i*yhat_au(-1))
    [name = 'eq_taylor']
    i_gap = lambda_i * i_gap(-1)
            + (1 - lambda_i) * (alpha_i * pi_au_gap(-1) + beta_i * yhat_au(-1))
            + eps_i;

    // --- Eq 3: Australian Phillips curve ---
    // pi_au_gap = lambda_pi*pi_au_gap(-1) + kappa_pi*yhat_au(-1)
    [name = 'eq_au_phillips']
    pi_au_gap = lambda_pi * pi_au_gap(-1)
                + kappa_pi * yhat_au(-1)
                + eps_pi;

    // --- Eq 4: US IS curve (AR1) ---
    [name = 'eq_us_is']
    yhat_us = lambda_q_us * yhat_us(-1) + eps_q_us;

    // --- Eq 5: US Phillips curve ---
    [name = 'eq_us_phillips']
    pi_us_gap = lambda_pi_us * pi_us_gap(-1)
                + kappa_pi_us * yhat_us(-1)
                + eps_pi_us;

    // --- Eq 6: LR interest rate anchor ---
    [name = 'eq_ibar']
    ibar = lambda_ibar * ibar(-1) + (1 - lambda_ibar) * i_ss + eps_ibar;

    // --- Eq 7: LR Australian inflation anchor ---
    [name = 'eq_pibar_au']
    pibar_au = lambda_pibar * pibar_au(-1) + (1 - lambda_pibar) * pi_ss_au + eps_pibar_au;

    // --- Eq 8: LR US inflation anchor ---
    [name = 'eq_pibar_us']
    pibar_us = lambda_pibar_us * pibar_us(-1) + (1 - lambda_pibar_us) * pi_ss_us + eps_pibar_us;

end;

// -----------------------------------------------------------------------
// Steady state (all gaps = 0, anchors at steady state)
// -----------------------------------------------------------------------

steady_state_model;
    ibar     = i_ss;
    pibar_au = pi_ss_au;
    pibar_us = pi_ss_us;
    yhat_au  = 0;
    yhat_us  = 0;
    i_au     = i_ss;
    pi_au    = pi_ss_au;
    pi_us    = pi_ss_us;
    i_gap    = 0;
    pi_au_gap = 0;
    pi_us_gap = 0;
end;

steady;
check;

// -----------------------------------------------------------------------
// Shocks for IRFs
// -----------------------------------------------------------------------

shocks;
    var eps_q;       stderr 0.7773;
    var eps_i;       stderr 0.0978;
    var eps_pi;      stderr 0.5806;
    var eps_q_us;    stderr 1.0879;
    var eps_pi_us;   stderr 0.2645;
    var eps_ibar;    stderr 0.01;
    var eps_pibar_au; stderr 0.01;
    var eps_pibar_us; stderr 0.01;
end;

// -----------------------------------------------------------------------
// Compute IRFs
// -----------------------------------------------------------------------

stoch_simul(order=1, irf=100, nograph);
