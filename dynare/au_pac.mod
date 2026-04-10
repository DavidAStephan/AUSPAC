// =========================================================================
// au_pac.mod
// Australian Semi-Structural Model with PAC equations
//
// Phase 7: Full model with closed feedback loops
//          E-SAT + Supply + Labor + Demand + Financial + Trade
//          + Deflators + Government + GDP identity + Feedback wires
//
// Based on FR-BDF (Banque de France WP #736), adapted for Australia.
// Uses Dynare 6.5 PAC framework.
//
// Structure:
//   - E-SAT satellite VAR for backward-looking expectations
//   - Supply block: CES production function, long-run output
//   - VA price: PAC equation with expectations from E-SAT (Section 4.4)
//   - Wage Phillips curve: hybrid backward/forward (Section 4.5.1, eq. 52)
//   - Employment: 4th-order PAC equation (Section 4.5.2, eq. 56)
//   - Household consumption: 1st-order PAC (Section 4.6.1, eq. 61)
//   - Business investment: 2nd-order PAC (Section 4.6.2, eq. 64)
//   - Household investment: 2nd-order PAC (Section 4.6.3, eq. 67)
//   - Term structure: 10Y yield = EH + term premium (Section 4.8, eq. 95)
//   - WACC: weighted average cost of capital (Section 4.8, eq. 98)
//   - Exchange rate: UIP with risk premium (Section 4.8, eq. 105)
//   - Exports: ECM with world demand + competitiveness (Section 4.7, eqs. 70-73)
//   - Imports: ECM with domestic demand + competitiveness (Section 4.7, eqs. 74-77)
//   - Demand deflators: 5 ECM equations tracking VA price (Section 4.7)
//   - Government spending: fiscal rule (Section 4.9)
//   - GDP identity: expenditure-side accounting (Section 4.9)
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

    // === VA price block ===
    piQ             // VA price inflation (quarterly %)
    piQ_star        // growth rate of VA price target
    piQ_star_bar    // HP trend of VA price target growth
    pQ_gap          // gap between VA price target and actual (p*Q - pQ), in log

    // === Labor market: wage Phillips curve ===
    pi_w            // nominal wage inflation (quarterly %)

    // === Labor market: employment PAC ===
    dln_n           // employment growth (quarterly %, log diff)
    dln_n_star      // target employment growth rate
    dln_n_star_bar  // trend (potential) employment growth
    n_gap           // gap between target and actual employment (log level)
    dln_n_1         // auxiliary: dln_n(-1) for higher-order PAC lags
    dln_n_2         // auxiliary: dln_n(-2)
    dln_n_3         // auxiliary: dln_n(-3)

    // === Demand block: household consumption PAC (Section 4.6.1) ===
    dln_c           // consumption growth (quarterly log diff)
    dln_c_star      // target consumption growth (permanent income proxy)
    dln_c_star_bar  // trend consumption growth
    c_gap           // gap between target and actual consumption (log level)

    // === Demand block: business investment PAC (Section 4.6.2) ===
    dln_ib          // business investment growth (quarterly log diff)
    dln_ib_star     // target investment growth (desired capital stock proxy)
    dln_ib_star_bar // trend investment growth
    ib_gap          // gap between target and actual investment (log level)
    dln_ib_1        // auxiliary: dln_ib(-1) for 2nd-order lag

    // === Demand block: household investment PAC (Section 4.6.3) ===
    dln_ih          // household investment growth (quarterly log diff)
    dln_ih_star     // target housing investment growth
    dln_ih_star_bar // trend housing investment growth
    ih_gap          // gap between target and actual housing investment (log level)
    dln_ih_1        // auxiliary: dln_ih(-1) for 2nd-order lag

    // === Financial block (Section 4.8) ===
    i_10y           // 10-year AU government bond yield (quarterly %)
    tp              // term premium (quarterly %)
    wacc            // weighted average cost of capital (quarterly %)
    s_gap           // real exchange rate gap (log, + = AUD depreciation)

    // === Trade block (Section 4.7) ===
    dln_x           // export volume growth (quarterly log diff)
    x_gap           // export gap (equilibrium - actual, log level)
    dln_m           // import volume growth (quarterly log diff)
    m_gap           // import gap (equilibrium - actual, log level)

    // === Demand deflators (Section 4.7) ===
    pi_c            // consumption deflator inflation (quarterly %)
    pi_ib           // business investment deflator inflation (quarterly %)
    pi_ih           // household investment deflator inflation (quarterly %)
    pi_x            // export deflator inflation (quarterly %)
    pi_m            // import deflator inflation (quarterly %)

    // === Government + GDP identity (Section 4.9) ===
    dln_g           // government spending growth (quarterly log diff)
    pi_g            // government deflator inflation (quarterly %)
    yhat_dom        // domestic demand gap (weighted sum of expenditure components)
;



varexo
    // E-SAT shocks
    eps_q eps_i eps_pi eps_q_us eps_pi_us
    eps_ibar eps_pibar_au eps_pibar_us
    // VA price shock
    eps_pQ
    // Labor market shocks
    eps_w           // wage shock
    eps_n           // employment shock
    // Demand block shocks
    eps_c           // consumption shock
    eps_ib          // business investment shock
    eps_ih          // household investment shock
    // Financial block shocks
    eps_10y         // long rate shock (term structure residual)
    eps_tp          // term premium shock
    eps_wacc        // WACC shock (credit conditions)
    eps_s           // exchange rate shock (UIP residual / risk premium)
    // Trade block shocks
    eps_x           // export volume shock
    eps_m           // import volume shock
    // Deflator shocks
    eps_pc          // consumption deflator shock
    eps_pib         // investment deflator shock
    eps_pih         // housing investment deflator shock
    eps_px          // export deflator shock
    eps_pm          // import deflator shock
    // Government shocks
    eps_g           // government spending shock
    eps_pg          // government deflator shock
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
    lambda_dom      // demand-side feedback weight (bridge: yhat_dom -> yhat_au)

    // --- VA price PAC parameters ---
    b0_pQ           // error correction speed
    b1_pQ           // persistence (lag of piQ)
    b2_pQ           // output gap sensitivity
    omega_pQ        // share of nonstationary expectations component
    rho_pQ_star     // VA price target persistence

    // --- Wage Phillips curve parameters (Section 4.5.1) ---
    lambda_w        // wage persistence (coefficient on pi_w(-1))
    kappa_w         // output gap sensitivity (positive: higher gap -> higher wages)
    gamma_w         // weight on current CPI inflation (indexation channel)
    // growth neutrality: coeff on pibar_au = (1 - lambda_w - gamma_w)

    // --- Employment PAC parameters (Section 4.5.2, 4th-order) ---
    b0_n            // error correction speed
    b1_n            // 1st-order lag persistence
    b2_n            // 2nd-order lag
    b3_n            // 3rd-order lag
    b4_n            // 4th-order lag
    omega_n         // nonstationary expectations component
    b5_n            // output gap sensitivity (ad hoc HtM / demand channel)
    rho_n_star      // target employment growth persistence
    // growth neutrality: coeff on dln_n_star_bar(-1) = (1 - b1_n - b2_n - b3_n - b4_n - omega_n)

    // --- Household consumption PAC parameters (Section 4.6.1, 1st-order) ---
    b0_c            // error correction speed
    b1_c            // persistence (lag of dln_c)
    omega_c         // nonstationary expectations component
    b2_c            // real interest rate sensitivity (negative: higher r -> less C)
    b3_c            // output gap sensitivity (HtM channel, positive)
    rho_c_star      // target consumption growth persistence
    kappa_inc       // permanent income proxy: output gap -> consumption target
    // growth neutrality: coeff on dln_c_star_bar(-1) = (1 - b1_c - omega_c)

    // --- Business investment PAC parameters (Section 4.6.2, 2nd-order) ---
    b0_ib           // error correction speed
    b1_ib           // 1st-order lag persistence
    b2_ib           // 2nd-order lag
    omega_ib        // nonstationary expectations component
    b3_ib           // output gap sensitivity (accelerator channel)
    b4_ib           // real interest rate sensitivity (negative: higher r -> less I)
    rho_ib_star     // target investment growth persistence
    kappa_wacc      // WACC gap -> investment target (user cost channel)
    // growth neutrality: coeff on dln_ib_star_bar(-1) = (1 - b1_ib - b2_ib - omega_ib)

    // --- Household investment PAC parameters (Section 4.6.3, 2nd-order) ---
    b0_ih           // error correction speed
    b1_ih           // 1st-order lag persistence
    b2_ih           // 2nd-order lag
    omega_ih        // nonstationary expectations component
    b3_ih           // output gap sensitivity
    b4_ih           // real interest rate sensitivity (mortgage channel, negative)
    rho_ih_star     // target housing investment growth persistence
    kappa_mort      // mortgage rate gap -> housing investment target
    // growth neutrality: coeff on dln_ih_star_bar(-1) = (1 - b1_ih - b2_ih - omega_ih)

    // --- Term structure parameters (Section 4.8, eq. 95) ---
    rho_L           // long rate persistence (expectations smoothing)
    tp_ss           // steady-state term premium (quarterly %)
    rho_tp          // term premium persistence

    // --- WACC parameters (Section 4.8, eq. 98) ---
    rho_wacc        // WACC persistence (credit conditions inertia)
    spread_ss       // steady-state credit+equity spread over risk-free (quarterly %)

    // --- Exchange rate parameters (Section 4.8, eq. 105) ---
    rho_s           // real exchange rate persistence (PPP half-life ~3-5 years)
    alpha_s         // interest rate differential -> exchange rate

    // --- Export parameters (Section 4.7, eqs. 70-73) ---
    b0_x            // error correction speed
    b1_x            // export growth persistence
    b2_x            // world demand elasticity (yhat_us -> exports)
    b3_x            // exchange rate elasticity (depreciation -> more exports)

    // --- Import parameters (Section 4.7, eqs. 74-77) ---
    b0_m            // error correction speed
    b1_m            // import growth persistence
    b2_m            // domestic demand elasticity (yhat_au -> imports)
    b3_m            // exchange rate elasticity (depreciation -> fewer imports)

    // --- Demand deflator parameters (Section 4.7, ECM equations) ---
    // All deflators track VA price (piQ) with pass-through + persistence
    rho_pc          // consumption deflator persistence
    alpha_pc        // VA price pass-through to consumption deflator
    rho_pib         // investment deflator persistence
    alpha_pib       // VA price pass-through to investment deflator
    rho_pih         // housing investment deflator persistence
    alpha_pih       // VA price pass-through to housing deflator
    rho_px          // export deflator persistence
    alpha_px        // VA price pass-through to export deflator
    beta_px         // exchange rate pass-through to export deflator
    rho_pm          // import deflator persistence
    alpha_pm        // VA price pass-through to import deflator (weaker)
    beta_pm         // exchange rate pass-through to import deflator (strong)

    // --- Government parameters (Section 4.9) ---
    rho_g           // government spending persistence
    phi_g           // fiscal rule: countercyclical response to output gap (negative)
    rho_pg          // government deflator persistence
    alpha_pg        // VA price pass-through to government deflator

    // --- GDP identity weights (AU expenditure shares, ABS 2023) ---
    w_c             // consumption share of GDP (~55%)
    w_ib            // business investment share (~13%)
    w_ih            // household investment share (~6%)
    w_g             // government spending share (~24%)
    w_x             // export share (~25%)
    w_m             // import share (~23%)
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

// Bridge equation: demand-side feedback into IS curve (Phase 7a)
// Closes the Keynesian multiplier: demand components -> yhat_dom -> yhat_au
// Start conservative to avoid instability; loop gain must be < 1
lambda_dom      = 0.10;     // demand feedback weight (conservative start)

// VA price PAC parameters (calibrated from Table 4.4.3)
b0_pQ           = 0.06;     // error correction
b1_pQ           = 0.50;     // persistence
b2_pQ           = 0.09;     // output gap
omega_pQ        = 0.46;     // nonstationary share
rho_pQ_star     = 0.95;     // target persistence

// Wage Phillips curve parameters (calibrated from Section 4.5.1 / Table 4.5.1)
// Australia: moderate wage persistence, significant gap sensitivity
// Forward expectations proxied by pibar_au (inflation anchor)
lambda_w        = 0.55;     // wage persistence
kappa_w         = 0.10;     // output gap -> wages (positive sign: Okun implicit)
gamma_w         = 0.15;     // CPI indexation channel
// growth neutrality coeff = 1 - 0.55 - 0.15 = 0.30 on pibar_au

// Employment PAC parameters (calibrated from Table 4.5.3, 4th-order adjustment costs)
// Australia: labor market is relatively flexible vs France
b0_n            = 0.04;     // error correction (slow adjustment to target)
b1_n            = 0.30;     // 1st lag
b2_n            = 0.10;     // 2nd lag
b3_n            = 0.05;     // 3rd lag
b4_n            = 0.02;     // 4th lag
omega_n         = 0.30;     // expectations/forward component
b5_n            = 0.12;     // output gap sensitivity
rho_n_star      = 0.95;     // target persistence
// growth neutrality coeff = 1 - 0.30 - 0.10 - 0.05 - 0.02 - 0.30 = 0.23

// Household consumption PAC parameters (calibrated from Section 4.6.1 / Table 4.6.1)
// Australia: moderate consumption smoothing, significant HtM share (~30%)
// 1st-order adjustment costs (simplest PAC form)
b0_c            = 0.06;     // error correction (moderate speed)
b1_c            = 0.35;     // persistence (1st lag)
omega_c         = 0.35;     // expectations/forward component
b2_c            = -0.02;    // real interest rate -> consumption (negative: substitution)
b3_c            = 0.15;     // output gap -> consumption (HtM channel)
rho_c_star      = 0.95;     // target persistence
kappa_inc       = 0.08;     // output gap -> consumption target (permanent income proxy)
// growth neutrality coeff = 1 - 0.35 - 0.35 = 0.30

// Business investment PAC parameters (calibrated from Section 4.6.2 / Table 4.6.2)
// Australia: investment more volatile than consumption, strong accelerator
// 2nd-order adjustment costs
b0_ib           = 0.04;     // error correction (slow — capital stock adjusts slowly)
b1_ib           = 0.25;     // 1st lag persistence
b2_ib           = 0.10;     // 2nd lag
omega_ib        = 0.35;     // expectations/forward component
b3_ib           = 0.20;     // output gap -> investment (accelerator, strong)
b4_ib           = -0.03;    // real interest rate -> investment (user cost channel)
rho_ib_star     = 0.95;     // target persistence
kappa_wacc      = 0.04;     // WACC gap -> investment target (user cost of capital)
// growth neutrality coeff = 1 - 0.25 - 0.10 - 0.35 = 0.30

// Household investment PAC parameters (calibrated from Section 4.6.3 / Table 4.6.3)
// Australia: housing highly interest-rate sensitive (variable-rate mortgages)
// 2nd-order adjustment costs
b0_ih           = 0.05;     // error correction
b1_ih           = 0.20;     // 1st lag persistence
b2_ih           = 0.08;     // 2nd lag
omega_ih        = 0.30;     // expectations/forward component
b3_ih           = 0.12;     // output gap -> housing investment
b4_ih           = -0.05;    // real interest rate -> housing (mortgage channel, strongest)
rho_ih_star     = 0.95;     // target persistence
kappa_mort      = 0.05;     // mortgage rate gap -> housing target (AU variable-rate)
// growth neutrality coeff = 1 - 0.20 - 0.08 - 0.30 = 0.42

// Term structure parameters (calibrated from Section 4.8 / Table 4.8.1)
// AU 10Y yield tracks RBA cash rate with smoothing + term premium
rho_L           = 0.85;     // long rate persistence (smooths short rate movements)
tp_ss           = 0.30;     // SS term premium (~1.2% annual, AU avg yield curve slope)
rho_tp          = 0.98;     // term premium very persistent (global risk appetite)
// SS: i_10y = i_ss + tp_ss = 1.0491 + 0.30 = 1.3491 (~5.4% annual)

// WACC parameters (calibrated from Section 4.8 / eq. 98)
// Cost of capital = long rate + credit/equity spread
rho_wacc        = 0.90;     // persistent credit conditions
spread_ss       = 0.50;     // SS spread (~2% annual, AU corporate + equity premium)
// SS: wacc = i_10y_ss + spread_ss = 1.3491 + 0.50 = 1.8491 (~7.4% annual)

// Exchange rate parameters (calibrated from Section 4.8 / eq. 105)
// AUD/USD real exchange rate, UIP-based with persistent deviations from PPP
// s_gap > 0 = AUD depreciation (less purchasing power)
rho_s           = 0.92;     // persistent misalignment (PPP half-life ~8 quarters)
alpha_s         = 0.15;     // interest rate differential -> appreciation (negative sign in eq)

// Export parameters (calibrated from Section 4.7 / Table 4.7.1)
// Australia: commodity exports sensitive to world demand, moderate price elasticity
b0_x            = 0.05;     // error correction (moderate speed)
b1_x            = 0.30;     // export growth persistence
b2_x            = 0.25;     // world demand (yhat_us) -> AU exports (strong)
b3_x            = 0.10;     // depreciation -> more exports (Marshall-Lerner)

// Import parameters (calibrated from Section 4.7 / Table 4.7.2)
// Australia: imports track domestic demand closely
b0_m            = 0.06;     // error correction
b1_m            = 0.25;     // import growth persistence
b2_m            = 0.30;     // domestic demand (yhat_au) -> imports (strong, high import share)
b3_m            = -0.08;    // depreciation -> fewer imports (negative: price effect)

// Demand deflator parameters (calibrated from Section 4.7)
// ECM structure: pi_j = rho * pi_j(-1) + alpha * piQ + (1-rho-alpha) * pibar_au
// All satisfy growth neutrality: at SS, pi_j = piQ = pibar_au = pi_ss_au

// Consumption deflator: close to CPI, tracks VA price with full pass-through
rho_pc          = 0.40;     // moderate persistence
alpha_pc        = 0.30;     // VA price pass-through (rest from pibar_au)
// neutrality: (1-0.40-0.30) = 0.30 on pibar_au

// Business investment deflator: tracks VA price, less persistent
rho_pib         = 0.35;     // moderate persistence
alpha_pib       = 0.25;     // VA price pass-through
// neutrality: (1-0.35-0.25) = 0.40 on pibar_au

// Household investment deflator: construction costs, high persistence
rho_pih         = 0.45;     // higher persistence (construction costs sticky)
alpha_pih       = 0.25;     // VA price pass-through
// neutrality: (1-0.45-0.25) = 0.30 on pibar_au

// Export deflator: influenced by world prices via exchange rate
rho_px          = 0.30;     // lower persistence (commodity price pass-through)
alpha_px        = 0.20;     // VA price pass-through (weaker: world price taker)
beta_px         = -0.05;    // depreciation -> higher export prices in domestic currency
// neutrality: (1-0.30-0.20) = 0.50 on pibar_au (+ beta_px*0 at SS)

// Import deflator: heavily influenced by exchange rate
rho_pm          = 0.30;     // moderate persistence
alpha_pm        = 0.15;     // VA price pass-through (weak: foreign prices dominate)
beta_pm         = 0.08;     // depreciation -> higher import prices (strong pass-through)
// neutrality: (1-0.30-0.15) = 0.55 on pibar_au (+ beta_pm*0 at SS)

// Government parameters
// Spending follows simple fiscal rule: countercyclical stabilizer
rho_g           = 0.85;     // government spending persistent (budget inertia)
phi_g           = -0.10;    // countercyclical: positive gap -> less spending growth
rho_pg          = 0.50;     // government deflator moderately persistent
alpha_pg        = 0.30;     // VA price pass-through to government prices
// neutrality: (1-0.50-0.30) = 0.20 on pibar_au

// GDP expenditure shares (ABS National Accounts, 2023 averages)
// These sum to 1.0 for the domestic demand + net exports identity.
// yhat_dom = w_c*dln_c + w_ib*dln_ib + w_ih*dln_ih + w_g*dln_g + w_x*dln_x - w_m*dln_m
w_c             = 0.55;     // household consumption
w_ib            = 0.13;     // business investment (non-dwelling GFCF)
w_ih            = 0.06;     // household investment (dwelling GFCF)
w_g             = 0.24;     // government consumption + investment
w_x             = 0.25;     // exports
w_m             = 0.23;     // imports (subtracted)
// Note: w_c + w_ib + w_ih + w_g + w_x - w_m = 1.00

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

    // IS curve with demand-side feedback (Phase 7a bridge equation).
    // lambda_dom * yhat_dom closes the Keynesian multiplier loop:
    // monetary policy -> demand components -> yhat_dom -> yhat_au -> inflation -> policy
    [name = 'eq_au_is']
    yhat_au = delta * yhat_us
              + lambda_q * yhat_au(-1)
              - sigma_q * (i_gap(-1) - pi_au_gap(-1))
              + lambda_dom * yhat_dom
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

    [name = 'eq_piQ_star']
    piQ_star = rho_pQ_star * piQ_star(-1) + (1 - rho_pQ_star) * pibar_au;

    [name = 'eq_piQ_star_bar']
    piQ_star_bar = pibar_au;

    [name = 'eq_pQ_gap']
    pQ_gap = pQ_gap(-1) + piQ_star - piQ;

    [name = 'eq_piQ_pac']
    piQ = b0_pQ * pQ_gap(-1)
          + b1_pQ * piQ(-1)
          + omega_pQ * piQ_star
          + b2_pQ * yhat_au
          + (1 - b1_pQ - omega_pQ) * piQ_star_bar(-1)
          + eps_pQ;

    // === WAGE PHILLIPS CURVE (Section 4.5.1, eq. 52) ===
    // Hybrid backward/forward Phillips curve for nominal wages.
    // Forward expectations proxied by inflation anchor pibar_au.
    // pi_w = lambda_w * pi_w(-1) + gamma_w * pi_au + kappa_w * yhat_au
    //         + (1 - lambda_w - gamma_w) * pibar_au + eps_w
    //
    // Growth neutrality: at SS with pi_au = pibar_au = pi_ss,
    //   pi_w_ss = lambda_w * pi_w_ss + gamma_w * pi_ss + kappa_w * 0
    //             + (1 - lambda_w - gamma_w) * pi_ss
    //           = lambda_w * pi_w_ss + pi_ss - lambda_w * pi_ss
    //   => pi_w_ss = pi_ss  (verified)

    [name = 'eq_pi_w']
    pi_w = lambda_w * pi_w(-1)
           + gamma_w * pi_au
           + kappa_w * yhat_au
           + (1 - lambda_w - gamma_w) * pibar_au
           + eps_w;

    // === EMPLOYMENT PAC (Section 4.5.2, eq. 56, 4th-order) ===
    // Target employment: n_star tracks potential output (zero growth in gap model).
    // Simplified: dln_n_star follows an AR(1) toward trend growth.
    // Full model: inverted CES production function determines n_star.

    [name = 'eq_dln_n_star']
    dln_n_star = rho_n_star * dln_n_star(-1)
                 + (1 - rho_n_star) * dln_n_star_bar;

    // Trend employment growth: zero in stationary gap model.
    // Future: linked to working-age population growth / labor force trend.
    [name = 'eq_dln_n_star_bar']
    dln_n_star_bar = 0;

    // Employment gap accumulation (parallel to pQ_gap)
    [name = 'eq_n_gap']
    n_gap = n_gap(-1) + dln_n_star - dln_n;

    // Auxiliary lag variables for 4th-order PAC
    [name = 'eq_dln_n_1']
    dln_n_1 = dln_n(-1);

    [name = 'eq_dln_n_2']
    dln_n_2 = dln_n_1(-1);

    [name = 'eq_dln_n_3']
    dln_n_3 = dln_n_2(-1);

    // Employment PAC equation (4th-order adjustment costs)
    // dln_n = error_correction + 4 AR lags + expectations + output_gap + growth_neutrality
    //
    // Growth neutrality: at SS with all gaps = 0 and dln_n = dln_n_star = dln_n_star_bar = 0:
    //   0 = b0_n*0 + (b1_n+b2_n+b3_n+b4_n)*0 + omega_n*0 + b5_n*0
    //       + (1-b1_n-b2_n-b3_n-b4_n-omega_n)*0 = 0  (verified)

    [name = 'eq_dln_n_pac']
    dln_n = b0_n * n_gap(-1)
            + b1_n * dln_n(-1)
            + b2_n * dln_n_1(-1)
            + b3_n * dln_n_2(-1)
            + b4_n * dln_n_3(-1)
            + omega_n * dln_n_star
            + b5_n * yhat_au
            + (1 - b1_n - b2_n - b3_n - b4_n - omega_n) * dln_n_star_bar(-1)
            + eps_n;

    // =================================================================
    // DEMAND BLOCK
    // =================================================================

    // === HOUSEHOLD CONSUMPTION PAC (Section 4.6.1, eq. 61, 1st-order) ===
    // Target: permanent income (simplified — tracks trend output growth)
    // Full model: forward-solved from E-SAT income forecasts + wealth
    // Simplified target: dln_c_star = rho * dln_c_star(-1) + (1-rho) * dln_c_star_bar

    [name = 'eq_dln_c_star']
    dln_c_star = rho_c_star * dln_c_star(-1)
                 + (1 - rho_c_star) * dln_c_star_bar;

    // Consumption target: permanent income proxy (Phase 7d).
    // When output is above potential, permanent income estimate rises,
    // pulling the consumption target up. Preserves SS: yhat_au=0 => target=0.
    [name = 'eq_dln_c_star_bar']
    dln_c_star_bar = kappa_inc * yhat_au;

    // Consumption gap accumulation
    [name = 'eq_c_gap']
    c_gap = c_gap(-1) + dln_c_star - dln_c;

    // Consumption PAC equation (1st-order adjustment costs)
    // dln_c = error_correction + 1 AR lag + expectations + real_rate + output_gap + neutrality
    //
    // Growth neutrality: at SS with all gaps = 0 and dln_c = dln_c_star = dln_c_star_bar = 0:
    //   0 = b0_c*0 + b1_c*0 + omega_c*0 + b2_c*0 + b3_c*0 + (1-b1_c-omega_c)*0 = 0  (verified)
    //
    // Real interest rate: (i_gap - pi_au_gap) = real rate gap.
    // Negative b2_c: higher real rates depress consumption (substitution effect).

    [name = 'eq_dln_c_pac']
    dln_c = b0_c * c_gap(-1)
            + b1_c * dln_c(-1)
            + omega_c * dln_c_star
            + b2_c * (i_gap(-1) - pi_au_gap(-1))
            + b3_c * yhat_au
            + (1 - b1_c - omega_c) * dln_c_star_bar(-1)
            + eps_c;

    // === BUSINESS INVESTMENT PAC (Section 4.6.2, eq. 64, 2nd-order) ===
    // Target: desired capital stock from inverted production function
    // Simplified: dln_ib_star tracks output growth (accelerator)
    // Full: user cost of capital (WACC + depreciation + relative prices) from Phase 5

    [name = 'eq_dln_ib_star']
    dln_ib_star = rho_ib_star * dln_ib_star(-1)
                  + (1 - rho_ib_star) * dln_ib_star_bar;

    // Investment target: WACC-driven user cost channel (Phase 7b).
    // When WACC rises above SS (tight credit), desired capital growth falls.
    // Preserves SS: wacc = i_ss + tp_ss + spread_ss => gap = 0 => target = 0.
    [name = 'eq_dln_ib_star_bar']
    dln_ib_star_bar = -kappa_wacc * (wacc - (i_ss + tp_ss + spread_ss));

    // Investment gap accumulation
    [name = 'eq_ib_gap']
    ib_gap = ib_gap(-1) + dln_ib_star - dln_ib;

    // Auxiliary lag variable for 2nd-order PAC
    [name = 'eq_dln_ib_1']
    dln_ib_1 = dln_ib(-1);

    // Business investment PAC equation (2nd-order adjustment costs)
    // dln_ib = EC + 2 AR lags + expectations + output_gap + real_rate + neutrality
    //
    // Growth neutrality at SS: verified (all terms zero).
    // Accelerator (b3_ib): output gap drives investment via demand.
    // User cost (b4_ib): real interest rate gap depresses investment.

    [name = 'eq_dln_ib_pac']
    dln_ib = b0_ib * ib_gap(-1)
             + b1_ib * dln_ib(-1)
             + b2_ib * dln_ib_1(-1)
             + omega_ib * dln_ib_star
             + b3_ib * yhat_au
             + b4_ib * (i_gap(-1) - pi_au_gap(-1))
             + (1 - b1_ib - b2_ib - omega_ib) * dln_ib_star_bar(-1)
             + eps_ib;

    // === HOUSEHOLD INVESTMENT PAC (Section 4.6.3, eq. 67, 2nd-order) ===
    // Target: desired housing stock from housing demand function
    // Simplified: dln_ih_star tracks income growth
    // Full: user cost of housing capital (mortgage rate + depreciation + house prices)
    // Australia-specific: variable-rate mortgages => strong RBA transmission

    [name = 'eq_dln_ih_star']
    dln_ih_star = rho_ih_star * dln_ih_star(-1)
                  + (1 - rho_ih_star) * dln_ih_star_bar;

    // Housing investment target: mortgage rate channel (Phase 7c).
    // Uses short rate gap as mortgage rate proxy (AU variable-rate dominance).
    // When RBA raises rates above neutral, housing investment target falls.
    // Preserves SS: i_gap = 0 => target = 0.
    [name = 'eq_dln_ih_star_bar']
    dln_ih_star_bar = -kappa_mort * i_gap;

    // Housing investment gap accumulation
    [name = 'eq_ih_gap']
    ih_gap = ih_gap(-1) + dln_ih_star - dln_ih;

    // Auxiliary lag variable for 2nd-order PAC
    [name = 'eq_dln_ih_1']
    dln_ih_1 = dln_ih(-1);

    // Household investment PAC equation (2nd-order adjustment costs)
    // dln_ih = EC + 2 AR lags + expectations + output_gap + real_rate + neutrality
    //
    // Growth neutrality at SS: verified (all terms zero).
    // Mortgage channel (b4_ih): strongest interest rate sensitivity of all demand
    // components — reflects Australia's variable-rate mortgage dominance.

    [name = 'eq_dln_ih_pac']
    dln_ih = b0_ih * ih_gap(-1)
             + b1_ih * dln_ih(-1)
             + b2_ih * dln_ih_1(-1)
             + omega_ih * dln_ih_star
             + b3_ih * yhat_au
             + b4_ih * (i_gap(-1) - pi_au_gap(-1))
             + (1 - b1_ih - b2_ih - omega_ih) * dln_ih_star_bar(-1)
             + eps_ih;

    // =================================================================
    // FINANCIAL BLOCK (Section 4.8)
    // =================================================================

    // === TERM STRUCTURE (eq. 95) ===
    // 10Y yield follows expectations hypothesis: weighted average of expected
    // future short rates + term premium. Simplified to partial adjustment:
    // i_10y adjusts toward (current short rate + term premium) with smoothing.
    //
    // At SS: i_10y = i_au + tp = i_ss + tp_ss

    [name = 'eq_term_premium']
    tp = rho_tp * tp(-1) + (1 - rho_tp) * tp_ss + eps_tp;

    [name = 'eq_i_10y']
    i_10y = rho_L * i_10y(-1) + (1 - rho_L) * (i_au + tp) + eps_10y;

    // === WACC (eq. 98) ===
    // Weighted average cost of capital for firms.
    // Simplified: WACC = long rate + credit/equity spread.
    // Full model: w_d*(i_L + credit_spread) + w_e*(i_L + equity_premium)
    // Future: feed back into business investment target (dln_ib_star_bar).
    //
    // At SS: wacc = i_10y_ss + spread_ss

    [name = 'eq_wacc']
    wacc = rho_wacc * wacc(-1) + (1 - rho_wacc) * (i_10y + spread_ss) + eps_wacc;

    // === EXCHANGE RATE (eq. 105) ===
    // Real exchange rate gap follows modified UIP.
    // s_gap > 0 = AUD depreciation (weaker purchasing power).
    // Higher AU interest rates attract capital, appreciating AUD (negative alpha_s).
    // Persistent deviations from PPP (rho_s ~0.92, half-life ~8 quarters).
    //
    // At SS: s_gap = 0 (PPP holds in long run)

    [name = 'eq_s_gap']
    s_gap = rho_s * s_gap(-1) - alpha_s * i_gap + eps_s;

    // =================================================================
    // TRADE BLOCK (Section 4.7)
    // =================================================================

    // === EXPORTS ECM (eqs. 70-73) ===
    // Export volumes adjust toward equilibrium determined by world demand
    // and competitiveness (real exchange rate).
    // Error correction: x_gap > 0 means exports below equilibrium, pulls up.
    // World demand channel: yhat_us (proxy for AU's trading partners).
    // Competitiveness: s_gap > 0 (depreciation) -> more competitive -> more exports.
    //
    // At SS: dln_x = 0, x_gap = 0

    [name = 'eq_x_gap']
    x_gap = x_gap(-1) - dln_x;

    [name = 'eq_dln_x']
    dln_x = b0_x * x_gap(-1)
            + b1_x * dln_x(-1)
            + b2_x * yhat_us
            + b3_x * s_gap
            + eps_x;

    // === IMPORTS ECM (eqs. 74-77) ===
    // Import volumes adjust toward equilibrium determined by domestic demand
    // and competitiveness (real exchange rate).
    // Error correction: m_gap > 0 means imports below equilibrium, pulls up.
    // Domestic demand channel: yhat_au (income elasticity of imports).
    // Competitiveness: s_gap > 0 (depreciation) -> imports more expensive -> fewer imports.
    //
    // At SS: dln_m = 0, m_gap = 0

    [name = 'eq_m_gap']
    m_gap = m_gap(-1) - dln_m;

    [name = 'eq_dln_m']
    dln_m = b0_m * m_gap(-1)
            + b1_m * dln_m(-1)
            + b2_m * yhat_au
            + b3_m * s_gap
            + eps_m;

    // =================================================================
    // DEMAND DEFLATORS (Section 4.7)
    // =================================================================
    // Each deflator follows an ECM tracking the VA price (piQ) with
    // partial pass-through. Growth neutrality: at SS all deflators
    // converge to pi_ss_au = piQ_ss = pibar_au_ss.
    //
    // General form: pi_j = rho_j * pi_j(-1) + alpha_j * piQ
    //                     + (1 - rho_j - alpha_j) * pibar_au + eps_j
    // Trade deflators add exchange rate pass-through (beta * s_gap).

    // === Consumption deflator (CPI-like) ===
    [name = 'eq_pi_c']
    pi_c = rho_pc * pi_c(-1)
           + alpha_pc * piQ
           + (1 - rho_pc - alpha_pc) * pibar_au
           + eps_pc;

    // === Business investment deflator ===
    [name = 'eq_pi_ib']
    pi_ib = rho_pib * pi_ib(-1)
            + alpha_pib * piQ
            + (1 - rho_pib - alpha_pib) * pibar_au
            + eps_pib;

    // === Household investment deflator (construction costs) ===
    [name = 'eq_pi_ih']
    pi_ih = rho_pih * pi_ih(-1)
            + alpha_pih * piQ
            + (1 - rho_pih - alpha_pih) * pibar_au
            + eps_pih;

    // === Export deflator (world price influence via exchange rate) ===
    // Depreciation (s_gap > 0) raises domestic-currency export prices.
    [name = 'eq_pi_x']
    pi_x = rho_px * pi_x(-1)
           + alpha_px * piQ
           + (1 - rho_px - alpha_px) * pibar_au
           + beta_px * s_gap
           + eps_px;

    // === Import deflator (exchange rate pass-through dominant) ===
    // Depreciation (s_gap > 0) raises import prices in AUD.
    [name = 'eq_pi_m']
    pi_m = rho_pm * pi_m(-1)
           + alpha_pm * piQ
           + (1 - rho_pm - alpha_pm) * pibar_au
           + beta_pm * s_gap
           + eps_pm;

    // =================================================================
    // GOVERNMENT + GDP IDENTITY (Section 4.9)
    // =================================================================

    // === Government spending: fiscal rule ===
    // Government consumption + investment growth follows a simple
    // countercyclical rule: spending rises when output falls (automatic
    // stabilizers + discretionary policy). Budget inertia via rho_g.
    //
    // At SS: dln_g = 0

    [name = 'eq_dln_g']
    dln_g = rho_g * dln_g(-1)
            + phi_g * yhat_au
            + eps_g;

    // === Government deflator ===
    // Tracks VA price with moderate pass-through (public sector wages).
    [name = 'eq_pi_g']
    pi_g = rho_pg * pi_g(-1)
           + alpha_pg * piQ
           + (1 - rho_pg - alpha_pg) * pibar_au
           + eps_pg;

    // === GDP EXPENDITURE IDENTITY ===
    // Domestic demand gap as weighted sum of expenditure component growth
    // rates. This is the model's accounting closure: yhat_dom summarizes
    // the demand side.
    //
    // yhat_dom = w_c*dln_c + w_ib*dln_ib + w_ih*dln_ih + w_g*dln_g
    //          + w_x*dln_x - w_m*dln_m
    //
    // At SS: yhat_dom = 0 (all component growth rates zero)
    //
    // Note: yhat_dom is a flow measure (growth contribution). It feeds
    // back into yhat_au via the bridge equation (lambda_dom * yhat_dom
    // in the IS curve), closing the Keynesian multiplier loop.

    [name = 'eq_gdp_identity']
    yhat_dom = w_c * dln_c + w_ib * dln_ib + w_ih * dln_ih
             + w_g * dln_g + w_x * dln_x - w_m * dln_m;

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
    piQ          = pi_ss_au;
    pQ_gap       = 0;

    // Wage Phillips curve
    pi_w         = pi_ss_au;  // wages grow at LR inflation rate at SS

    // Employment PAC
    dln_n          = 0;       // zero employment growth in stationary model
    dln_n_star     = 0;
    dln_n_star_bar = 0;
    n_gap          = 0;
    dln_n_1        = 0;
    dln_n_2        = 0;
    dln_n_3        = 0;

    // Household consumption PAC
    dln_c          = 0;       // zero consumption growth in stationary model
    dln_c_star     = 0;
    dln_c_star_bar = 0;
    c_gap          = 0;

    // Business investment PAC
    dln_ib         = 0;       // zero investment growth in stationary model
    dln_ib_star    = 0;
    dln_ib_star_bar = 0;
    ib_gap         = 0;
    dln_ib_1       = 0;

    // Household investment PAC
    dln_ih         = 0;       // zero housing investment growth in stationary model
    dln_ih_star    = 0;
    dln_ih_star_bar = 0;
    ih_gap         = 0;
    dln_ih_1       = 0;

    // Financial block
    tp             = tp_ss;                         // term premium at SS
    i_10y          = i_ss + tp_ss;                  // 10Y yield = short rate + term premium
    wacc           = i_ss + tp_ss + spread_ss;      // WACC = long rate + spread
    s_gap          = 0;                             // PPP holds at SS

    // Trade block
    dln_x          = 0;       // zero export growth in stationary model
    x_gap          = 0;
    dln_m          = 0;       // zero import growth in stationary model
    m_gap          = 0;

    // Demand deflators: all converge to pi_ss_au at SS
    pi_c           = pi_ss_au;
    pi_ib          = pi_ss_au;
    pi_ih          = pi_ss_au;
    pi_x           = pi_ss_au;
    pi_m           = pi_ss_au;

    // Government
    dln_g          = 0;       // zero government spending growth in stationary model
    pi_g           = pi_ss_au;

    // GDP identity
    yhat_dom       = 0;       // zero at SS (all components zero)
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
    var eps_pQ;       stderr 0.5;    // VA price shock (~0.5% quarterly)
    var eps_w;        stderr 0.6;    // wage shock (comparable to price Phillips)
    var eps_n;        stderr 0.4;    // employment shock
    var eps_c;        stderr 0.5;    // consumption shock (~0.5% quarterly)
    var eps_ib;       stderr 1.5;    // business investment shock (most volatile component)
    var eps_ih;       stderr 2.0;    // household investment shock (housing very volatile)
    var eps_10y;      stderr 0.10;   // long rate shock (small — most variation from short rate)
    var eps_tp;       stderr 0.05;   // term premium shock (small, persistent)
    var eps_wacc;     stderr 0.15;   // WACC shock (credit conditions)
    var eps_s;        stderr 2.5;    // exchange rate shock (AUD/USD volatile)
    var eps_x;        stderr 1.2;    // export volume shock
    var eps_m;        stderr 1.0;    // import volume shock
    var eps_pc;       stderr 0.3;    // consumption deflator shock
    var eps_pib;      stderr 0.4;    // investment deflator shock
    var eps_pih;      stderr 0.5;    // housing investment deflator shock
    var eps_px;       stderr 0.8;    // export deflator shock (commodity price volatility)
    var eps_pm;       stderr 0.7;    // import deflator shock (exchange rate volatility)
    var eps_g;        stderr 0.3;    // government spending shock (small, policy-driven)
    var eps_pg;       stderr 0.3;    // government deflator shock
end;

// -----------------------------------------------------------------------
// Compute IRFs
// -----------------------------------------------------------------------

// stoch_simul(order=1, irf=80, nograph);  // commented out for estimation

// =======================================================================
// ESTIMATION INFRASTRUCTURE (Phase 7e)
// =======================================================================
// Uncomment the blocks below to run Bayesian estimation.
// Data: dataset.csv (E-SAT core) + extended_dataset.csv (demand/labor/financial)
// Requires: observed data transformed to model-consistent units (quarterly %,
//           log-differenced, demeaned) and saved as a Dynare-compatible .m file.
//
// To run estimation:
//   1. Prepare data: run data/prepare_estimation_data.m (to be created)
//   2. Uncomment varobs + estimated_params blocks below
//   3. Comment out stoch_simul above
//   4. Uncomment estimation command at bottom
//   5. Run: dynare au_pac noclearall

// -----------------------------------------------------------------------
// Observable variables
// -----------------------------------------------------------------------
// Map model variables to data columns:
//   yhat_au     <- au_ygap (dataset.csv)
//   pi_au       <- au_pi (dataset.csv)
//   i_au        <- au_irate/4 (dataset.csv, annualized -> quarterly)
//   yhat_us     <- us_ygap (dataset.csv)
//   pi_us       <- us_pi (dataset.csv)
//   pi_w        <- au_pi_w (extended_dataset.csv, log-diff of ULC)
//   dln_c       <- dlog(au_consumption) (extended_dataset.csv)
//   dln_ib      <- dlog(au_gfcf) (extended_dataset.csv, approx — needs split)
//   i_10y       <- au_i10/4 (extended_dataset.csv, annualized -> quarterly)
//
varobs yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;

// -----------------------------------------------------------------------
// Estimated parameters with priors
// -----------------------------------------------------------------------
// Priors centered on current calibrated values with informative spreads.
// Beta distribution for [0,1] parameters, Gamma for positive, Normal for others.
//
estimated_params;
    // --- Demand block: key PAC parameters ---
    b0_c,       beta_pdf, 0.06, 0.02;     // consumption error correction
    b1_c,       beta_pdf, 0.35, 0.10;     // consumption persistence
    omega_c,    beta_pdf, 0.35, 0.10;     // consumption expectations
    b3_c,       normal_pdf, 0.15, 0.05;   // consumption HtM channel
    b0_ib,      beta_pdf, 0.04, 0.02;     // investment error correction
    b1_ib,      beta_pdf, 0.25, 0.08;     // investment persistence
    b3_ib,      normal_pdf, 0.20, 0.08;   // investment accelerator
    b0_ih,      beta_pdf, 0.05, 0.02;     // housing error correction
    b1_ih,      beta_pdf, 0.20, 0.08;     // housing persistence

    // --- Labor block ---
    lambda_w,   beta_pdf, 0.55, 0.10;     // wage persistence
    kappa_w,    normal_pdf, 0.10, 0.05;   // wage Phillips slope
    b0_n,       beta_pdf, 0.04, 0.02;     // employment error correction

    // --- Financial block ---
    rho_L,      beta_pdf, 0.85, 0.05;     // term structure smoothing
    rho_s,      beta_pdf, 0.92, 0.03;     // exchange rate persistence

    // --- Feedback parameters (Phase 7) ---
    lambda_dom, beta_pdf, 0.10, 0.05;     // demand bridge weight
    kappa_wacc, normal_pdf, 0.04, 0.02;   // WACC -> investment target
    kappa_mort, normal_pdf, 0.05, 0.02;   // mortgage -> housing target
    kappa_inc,  normal_pdf, 0.08, 0.04;   // income -> consumption target

    // --- Shock standard deviations ---
    stderr eps_q,        inv_gamma_pdf, 0.80, inf;
    stderr eps_i,        inv_gamma_pdf, 0.10, inf;
    stderr eps_pi,       inv_gamma_pdf, 0.60, inf;
    stderr eps_c,        inv_gamma_pdf, 0.50, inf;
    stderr eps_ib,       inv_gamma_pdf, 1.50, inf;
    stderr eps_ih,       inv_gamma_pdf, 2.00, inf;
end;

// -----------------------------------------------------------------------
// Estimation command
// -----------------------------------------------------------------------
estimation(datafile='estimation_data.mat',
           first_obs=1, nobs=122,
           mh_replic=10000, mh_nblocks=2, mh_jscale=0.3,
           mode_compute=4, presample=4,
           bayesian_irf,
           graph_format=(eps), nograph)
           yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;
