// =========================================================================
// au_pac.mod
// Australian Semi-Structural Model with PAC equations
//
// Phase 2: E-SAT core + Supply block + VA Price (first PAC equation)
//
// Based on FR-BDF (Banque de France WP #736), adapted for Australia.
// Uses Dynare 6.5 PAC framework.
//
// Structure:
//   - E-SAT satellite VAR (var_model) for backward-looking expectations
//   - Supply block: CES production function, long-run output
//   - VA price: PAC equation with expectations from E-SAT
// =========================================================================

// -----------------------------------------------------------------------
// Variable declarations
// -----------------------------------------------------------------------

var
    // === E-SAT core variables ===
    yhat_au         // Australian output gap (%)
    i_au            // AU short-term interest rate (quarterly %)
    pi_au           // AU GDP deflator inflation (quarterly %)
    yhat_us         // US output gap (%)
    pi_us           // US inflation (quarterly %)
    ibar            // LR interest rate anchor (quarterly %)
    pibar_au        // LR AU inflation anchor (quarterly %)
    pibar_us        // LR US inflation anchor (quarterly %)
    i_gap           // i_au - ibar
    pi_au_gap       // pi_au - pibar_au
    pi_us_gap       // pi_us - pibar_us

    // === Supply block variables ===
    // (For now, output gap comes from E-SAT; future phases add production function)

    // === VA price block ===
    piQ             // VA price inflation (quarterly %)
    piQ_star        // growth rate of VA price target
    piQ_star_bar    // HP trend of VA price target growth
    pQ_gap          // gap between VA price target and actual (p*Q - pQ), in log
;


varexo
    // E-SAT shocks
    eps_q eps_i eps_pi eps_q_us eps_pi_us
    eps_ibar eps_pibar_au eps_pibar_us
    // VA price shock
    eps_pQ
;

// -----------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------

parameters
    // --- E-SAT parameters (Bayesian posteriors) ---
    delta lambda_q sigma_q
    lambda_i alpha_i beta_i
    lambda_pi kappa_pi
    lambda_q_us
    lambda_pi_us kappa_pi_us
    lambda_ibar lambda_pibar lambda_pibar_us
    i_ss pi_ss_au pi_ss_us

    // --- VA price PAC parameters ---
    // Long run: pQ_star depends on efficient labour cost and marginal return on capital
    // Short run (PAC, eq. 44 in paper):
    //   piQ = PV(piQ_star) + b0*(pQ_star(-1) - pQ(-1)) + b1*piQ(-1) + b2*yhat_au
    //         + (1-b1-omega)*piQ_star_bar(-1) + eps_pQ
    b0_pQ           // error correction speed
    b1_pQ           // persistence (lag of piQ)
    b2_pQ           // output gap sensitivity (ad hoc HtM firms)
    omega_pQ        // share of nonstationary expectations component

    // VA price target: piQ_star = c0*pi_w_eff + (1-c0)*piQ_star_bar
    // For now, simplified: piQ_star tracks pibar_au (inflation target) + output gap effect
    rho_pQ_star     // persistence of target inflation
;

// -----------------------------------------------------------------------
// Parameter values
// -----------------------------------------------------------------------

// E-SAT (Bayesian posterior means)
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
i_ss            = 1.0491;
pi_ss_au        = 0.625;
pi_ss_us        = 0.5;

// VA price PAC parameters
// Calibrated from French model (Table 4.4.3) as starting point,
// to be re-estimated on AU data
b0_pQ           = 0.06;     // error correction
b1_pQ           = 0.50;     // persistence
b2_pQ           = 0.09;     // output gap
omega_pQ        = 0.46;     // nonstationary share
rho_pQ_star     = 0.95;     // target persistence

// -----------------------------------------------------------------------
// Model equations
// -----------------------------------------------------------------------

model;

    // === E-SAT CORE (identical to au_esat.mod) ===

    [name = 'def_i_gap']
    i_gap = i_au - ibar;

    [name = 'def_pi_au_gap']
    pi_au_gap = pi_au - pibar_au;

    [name = 'def_pi_us_gap']
    pi_us_gap = pi_us - pibar_us;

    [name = 'eq_au_is']
    yhat_au = delta * yhat_us
              + lambda_q * yhat_au(-1)
              - sigma_q * (i_gap(-1) - pi_au_gap(-1))
              + eps_q;

    [name = 'eq_taylor']
    i_gap = lambda_i * i_gap(-1)
            + (1 - lambda_i) * (alpha_i * pi_au_gap(-1) + beta_i * yhat_au(-1))
            + eps_i;

    [name = 'eq_au_phillips']
    pi_au_gap = lambda_pi * pi_au_gap(-1)
                + kappa_pi * yhat_au(-1)
                + eps_pi;

    [name = 'eq_us_is']
    yhat_us = lambda_q_us * yhat_us(-1) + eps_q_us;

    [name = 'eq_us_phillips']
    pi_us_gap = lambda_pi_us * pi_us_gap(-1)
                + kappa_pi_us * yhat_us(-1)
                + eps_pi_us;

    [name = 'eq_ibar']
    ibar = lambda_ibar * ibar(-1) + (1 - lambda_ibar) * i_ss + eps_ibar;

    [name = 'eq_pibar_au']
    pibar_au = lambda_pibar * pibar_au(-1) + (1 - lambda_pibar) * pi_ss_au + eps_pibar_au;

    [name = 'eq_pibar_us']
    pibar_us = lambda_pibar_us * pibar_us(-1) + (1 - lambda_pibar_us) * pi_ss_us + eps_pibar_us;

    // === VA PRICE BLOCK ===

    // VA price target growth rate
    // Simplified: tracks LR inflation anchor with persistence.
    // Full model: comes from factor price frontier (eq. 38).
    [name = 'eq_piQ_star']
    piQ_star = rho_pQ_star * piQ_star(-1) + (1 - rho_pQ_star) * pibar_au;

    // HP trend of target growth (anchored to pibar_au)
    [name = 'eq_piQ_star_bar']
    piQ_star_bar = pibar_au;

    // Price gap dynamics: gap = (piQ_star - piQ) accumulated
    // At SS: piQ = piQ_star => gap is stationary
    // pQ_gap evolves as: pQ_gap = pQ_gap(-1) + (piQ_star - piQ)
    [name = 'eq_pQ_gap']
    pQ_gap = pQ_gap(-1) + piQ_star - piQ;

    // VA price PAC equation (eq. 44 in paper, Section 4.4)
    // piQ = error_correction + persistence + expectations_proxy + output_gap + growth_neutrality
    [name = 'eq_piQ_pac']
    piQ = b0_pQ * pQ_gap(-1)
          + b1_pQ * piQ(-1)
          + omega_pQ * piQ_star
          + b2_pQ * yhat_au
          + (1 - b1_pQ - omega_pQ) * piQ_star_bar(-1)
          + eps_pQ;

end;

// -----------------------------------------------------------------------
// Steady state
// -----------------------------------------------------------------------

steady_state_model;
    // E-SAT
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

    // VA price block
    piQ_star     = pi_ss_au;
    piQ_star_bar = pi_ss_au;
    piQ          = pi_ss_au;  // at SS, inflation = target inflation
    pQ_gap       = 0;         // no gap at SS
end;

steady;
check;

// -----------------------------------------------------------------------
// Shocks
// -----------------------------------------------------------------------

shocks;
    var eps_q;        stderr 0.7773;
    var eps_i;        stderr 0.0978;
    var eps_pi;       stderr 0.5806;
    var eps_q_us;     stderr 1.0879;
    var eps_pi_us;    stderr 0.2645;
    var eps_ibar;     stderr 0.01;
    var eps_pibar_au; stderr 0.01;
    var eps_pibar_us; stderr 0.01;
    var eps_pQ;       stderr 0.5;   // VA price shock (~0.5% quarterly)
end;

// -----------------------------------------------------------------------
// Compute IRFs
// -----------------------------------------------------------------------

stoch_simul(order=1, irf=80, nograph);
