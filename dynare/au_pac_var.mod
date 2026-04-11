// =========================================================================
// au_pac_var.mod
// Australian Semi-Structural Model — PURE VAR-BASED expectations
//
// All expectations backward-looking: pv_u_gap, pv_yh, pv_i use AR(1)
// approximations instead of forward leads. Compare with au_pac.mod (hybrid).
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

    // === CES production function (Section 4.3) ===
    dln_k           // capital services growth (quarterly %, from accumulation eq 32)
    dln_y_star      // potential output growth (quarterly %)
    dln_tfp         // total factor productivity growth (quarterly %)

    // === Wage-price spiral (Stage 9c) ===
    dln_ulc         // unit labor cost growth (quarterly %)
    dln_prod        // labor productivity growth proxy (quarterly %)

    // === Labor market: wage Phillips curve ===
    pi_w            // nominal wage inflation (quarterly %)
    u_gap           // unemployment gap (pp, Okun's law from output gap)
    pv_u_gap        // PV of expected future unemployment gaps (beta_w=0.98)

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
    pv_yh           // PV of expected future output gaps (permanent income proxy, beta_c=0.95)

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

    // === User cost of capital (Stage 10b) ===
    uc_k            // user cost of capital (quarterly %)
    dln_uc_k        // user cost of capital growth (quarterly change)

    // === Financial block (Section 4.8) ===
    i_10y           // 10-year AU government bond yield (quarterly %)
    tp              // term premium (quarterly %)
    pv_i            // PV of expected future short rates (for term structure, kappa_10=0.97)
    wacc            // weighted average cost of capital (quarterly %)
    i_COE           // cost of equity (quarterly %)
    i_LB_firms      // bank lending rate for firms (quarterly %)
    i_BBB           // BBB corporate bond rate (quarterly %)
    s_COE           // equity spread over 10Y govt rate (quarterly %)
    s_LB_firms      // bank lending spread for firms (quarterly %)
    s_BBB           // BBB bond spread (quarterly %)
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

    // === Commodity price channel (Stage 11b, Australia-specific) ===
    dln_pcom        // commodity price growth (quarterly %)

    // === Government + GDP identity (Section 4.9) ===
    dln_g           // government spending growth (quarterly log diff)
    pi_g            // government deflator inflation (quarterly %)
    yhat_dom        // domestic demand gap (weighted sum of expenditure components)

    // === New variables (Stage 12: equation audit fixes) ===
    rw_gap          // real wage growth gap: pi_w - piQ - dln_prod (for employment target)
    iad             // import-adjusted demand (weighted by import content shares)
    i_lh            // household bank lending rate (quarterly %, eq. 68)
    dln_ph          // real housing price growth (quarterly %, eq. 69)
    ph_gap          // housing price gap (log level, cumulated dln_ph)

    // === PAC trend_component_model variables ===
    piQ_aux_l       // I(1) auxiliary VA price level (for TCM EC equation)
    piQ_star_l      // I(1) VA price target level (random walk for TCM)

    // === Detrended log-level for VA price PAC ===
    pQ_level        // VA price detrended log-level (diff = piQ - pi_ss_au)
    pQ_star_level   // VA price target detrended log-level

    // === Consumption PAC TCM variables ===
    c_aux_l         // I(1) auxiliary consumption level (for TCM EC equation)
    c_star_l        // I(1) consumption target level (random walk for TCM)
    ln_c_level      // consumption detrended log-level (diff = dln_c)

    // === Business investment PAC TCM variables ===
    ib_aux_l        // I(1) auxiliary business investment level (for TCM EC equation)
    ib_star_l       // I(1) business investment target level (random walk for TCM)
    ln_ib_level     // business investment detrended log-level (diff = dln_ib)

    // === Household investment PAC TCM variables ===
    ih_aux_l        // I(1) auxiliary household investment level (for TCM EC equation)
    ih_star_l       // I(1) household investment target level (random walk for TCM)
    ln_ih_level     // household investment detrended log-level (diff = dln_ih)

    // === Employment PAC TCM variables ===
    n_aux_l         // I(1) auxiliary employment level (for TCM EC equation)
    n_star_l        // I(1) employment target level (random walk for TCM)
    ln_n_level      // employment detrended log-level (diff = dln_n)
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
    eps_COE         // cost of equity spread shock
    eps_LB_firms    // bank lending spread shock (firms)
    eps_BBB         // BBB bond spread shock
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
    // Supply block shock (Stage 9a)
    eps_tfp         // TFP shock
    // Commodity price shock (Stage 11b)
    eps_pcom        // commodity price shock
    // Stage 12: equation audit fixes
    eps_lh          // household bank lending rate shock
    eps_ph          // housing price shock
    // TCM shocks (for trend_component_model)
    eps_e_q         // TCM non-target (VA price EC) shock
    eps_e_pQ_star   // TCM target (VA price target) shock
    eps_e_c         // TCM non-target (consumption EC) shock
    eps_e_c_star    // TCM target (consumption target) shock
    eps_e_ib        // TCM non-target (business investment EC) shock
    eps_e_ib_star   // TCM target (business investment target) shock
    eps_e_ih        // TCM non-target (household investment EC) shock
    eps_e_ih_star   // TCM target (household investment target) shock
    eps_e_n         // TCM non-target (employment EC) shock
    eps_e_n_star    // TCM target (employment target) shock
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
    gamma_ulc       // ULC pass-through to VA price target (CES dual, labor share)
    gamma_uck       // user cost pass-through to VA price target (CES dual, capital share)

    // --- Cobb-Douglas production function parameters (Stage 9a) ---
    alpha_k         // capital share in Cobb-Douglas
    rho_tfp         // TFP persistence

    // --- Commodity price channel parameters (Stage 11b) ---
    rho_pcom        // commodity price persistence
    b4_x            // commodity price -> export volumes
    alpha_pcom      // commodity price -> export deflator

    // --- Wage Phillips curve parameters (Section 4.5.1) ---
    lambda_w        // wage persistence (coefficient on pi_w(-1))
    kappa_w         // output gap sensitivity (positive: higher gap -> higher wages)
    gamma_w         // weight on current CPI inflation (indexation channel)
    okun_coeff      // Okun's law: output gap -> unemployment gap (negative, ~-0.33)
    rho_u_gap       // unemployment gap persistence (AR1 in Okun's law)
    beta_w          // discount factor for expected unemployment gaps (0.98)
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
    kappa_inc       // permanent income sensitivity: PV(yH) -> consumption target
    beta_c          // discount factor for permanent income PV (0.95, paper Section 4.6.1)
    alpha_c_r       // real lending rate gap -> consumption target (negative, paper eq 59)
    // growth neutrality: coeff on dln_c_star_bar(-1) = (1 - b1_c - omega_c)

    // --- Business investment PAC parameters (Section 4.6.2, 2nd-order) ---
    b0_ib           // error correction speed
    b1_ib           // 1st-order lag persistence
    b2_ib           // 2nd-order lag
    omega_ib        // nonstationary expectations component
    b3_ib           // output gap sensitivity (accelerator channel)
    b4_ib           // real interest rate sensitivity (negative: higher r -> less I)
    rho_ib_star     // target investment growth persistence
    kappa_wacc      // WACC gap -> investment target (legacy, unused)
    delta_k         // quarterly capital depreciation rate (Stage 9a/10b)
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
    rho_L           // long rate persistence (legacy, unused — now uses PV form)
    kappa_10        // term structure decay parameter (paper eq 97, ~0.97)
    tp_ss           // steady-state term premium (quarterly %)
    rho_tp          // term premium persistence

    // --- WACC parameters (Section 4.8, eq. 98) ---
    rho_wacc        // WACC persistence (legacy, unused — now decomposed)
    spread_ss       // steady-state composite spread (quarterly %, for uc_k SS)
    // --- WACC component parameters (Section 4.8.3, eq 98-100) ---
    w_COE           // weight of cost of equity in WACC (0.5)
    w_LB_firms      // weight of bank lending rate in WACC (0.3)
    w_BBB           // weight of BBB bond rate in WACC (0.2)
    rho_COE         // COE spread persistence
    rho_LB_firms    // bank lending spread persistence
    rho_BBB         // BBB spread persistence
    s_COE_ss        // SS equity spread (quarterly %)
    s_LB_firms_ss   // SS bank lending spread (quarterly %)
    s_BBB_ss        // SS BBB bond spread (quarterly %)

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

    // === Stage 12: equation audit fix parameters ===
    // Employment target: real wage sensitivity (Section 4.3, CES elasticity)
    sigma_ces       // CES elasticity of substitution (paper Section 4.3, Table 4.3.2)

    // Deflator import price channels (Section 4.7, IAD weights)
    beta_pc_m       // import price pass-through to consumption deflator
    beta_pib_m      // import price pass-through to business investment deflator
    beta_pih_m      // import price pass-through to housing investment deflator
    gamma_oil       // energy/commodity price pass-through to CPI
    beta_pm_com     // commodity price pass-through to import deflator

    // Import-adjusted demand weights (import content of each component)
    w_iad_c         // import content of consumption
    w_iad_ib        // import content of business investment
    w_iad_ih        // import content of household investment
    w_iad_g         // import content of government spending
    w_iad_x         // import content of exports (re-export channel)

    // Household bank lending rate (Section 4.8.3, eq. 68)
    rho_lh          // bank lending rate persistence
    spread_lh       // bank lending rate spread over 10Y government rate

    // Housing prices (Section 4.6.3, eq. 69)
    rho_ph          // housing price persistence
    alpha_ph_y      // output gap -> housing prices (demand channel)
    alpha_ph_r      // interest rate gap -> housing prices (credit channel, negative)
    kappa_ph        // housing price gap -> household investment target (Tobin's Q)
    kappa_ih_inc    // permanent income -> household investment target (paper eq 66)

    // Investment target output proportionality (Section 4.6.2, eq. 63)
    kappa_ib_y      // output gap -> business investment target

    // PAC discount factor
    beta_pac        // quarterly subjective discount (0.98 ≈ 8% annual)
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
lambda_dom      = 0.399;    // demand feedback weight (posterior mean from Stage 8)

// VA price PAC parameters (calibrated from Table 4.4.3)
b0_pQ           = 0.06;     // error correction
b1_pQ           = 0.50;     // persistence
b2_pQ           = 0.09;     // output gap
omega_pQ        = 0.46;     // nonstationary share
rho_pQ_star     = 0.95;     // target persistence
gamma_ulc       = 0.12;     // ULC pass-through (CES dual, labor share channel)
gamma_uck       = 0.06;     // user cost pass-through (CES dual, capital share channel)

// --- Cobb-Douglas production function (Stage 9a) ---
alpha_k         = 0.33;     // capital share in Cobb-Douglas
rho_tfp         = 0.99;     // TFP persistence (near unit root)

// --- Commodity price channel (Stage 11b) ---
rho_pcom        = 0.85;     // commodity price persistence
b4_x            = 0.15;     // commodity price -> export volumes
alpha_pcom      = 0.10;     // commodity price -> export deflator pass-through

// Wage Phillips curve parameters (calibrated from Section 4.5.1 / Table 4.5.1)
// Australia: moderate wage persistence, significant gap sensitivity
// Forward expectations proxied by pibar_au (inflation anchor)
lambda_w        = 0.247;    // wage persistence (posterior mean)
kappa_w         = 0.238;    // output gap -> wages (posterior mean)
gamma_w         = 0.15;     // CPI indexation channel
okun_coeff      = -0.33;    // Okun's law: 1pp output gap -> -0.33pp unemployment gap
rho_u_gap       = 0.94;     // unemployment gap persistence (paper Table 4.5.2)
beta_w          = 0.98;     // discount for expected unemployment gaps (paper Section 4.5.1)
// growth neutrality coeff = 1 - 0.55 - 0.15 = 0.30 on pibar_au

// Employment PAC parameters (calibrated from Table 4.5.3, 4th-order adjustment costs)
// Australia: labor market is relatively flexible vs France
b0_n            = 0.040;    // error correction (posterior mean)
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
b0_c            = 0.060;    // error correction (posterior mean)
b1_c            = 0.149;    // persistence (posterior mean)
omega_c         = 0.369;    // expectations/forward component (posterior mean)
b2_c            = -0.02;    // real interest rate -> consumption (negative: substitution)
b3_c            = 0.139;    // output gap -> consumption (posterior mean)
rho_c_star      = 0.95;     // target persistence
kappa_inc       = 0.050;    // permanent income sensitivity (posterior mean)
beta_c          = 0.95;     // permanent income discount (paper Section 4.6.1, ~25% annual)
alpha_c_r       = -0.95;    // real lending rate -> consumption (paper Table 4.6.14, alpha_1=-0.95)
// growth neutrality coeff = 1 - 0.35 - 0.35 = 0.30

// Business investment PAC parameters (calibrated from Section 4.6.2 / Table 4.6.2)
// Australia: investment more volatile than consumption, strong accelerator
// 2nd-order adjustment costs
b0_ib           = 0.030;    // error correction (posterior mean)
b1_ib           = 0.181;    // 1st lag persistence (posterior mean)
b2_ib           = 0.10;     // 2nd lag
omega_ib        = 0.35;     // expectations/forward component
b3_ib           = 0.191;    // output gap -> investment (posterior mean)
b4_ib           = -0.03;    // real interest rate -> investment (user cost channel)
rho_ib_star     = 0.95;     // target persistence
kappa_wacc      = 0.038;    // WACC gap -> investment target (posterior mean, legacy)
delta_k         = 0.025;    // quarterly capital depreciation (~10% annual)
// growth neutrality coeff = 1 - 0.25 - 0.10 - 0.35 = 0.30

// Household investment PAC parameters (calibrated from Section 4.6.3 / Table 4.6.3)
// Australia: housing highly interest-rate sensitive (variable-rate mortgages)
// 2nd-order adjustment costs
b0_ih           = 0.049;    // error correction (posterior mean)
b1_ih           = 0.210;    // 1st lag persistence (posterior mean)
b2_ih           = 0.08;     // 2nd lag
omega_ih        = 0.30;     // expectations/forward component
b3_ih           = 0.12;     // output gap -> housing investment
b4_ih           = -0.05;    // real interest rate -> housing (mortgage channel, strongest)
rho_ih_star     = 0.95;     // target persistence
kappa_mort      = 0.048;    // mortgage rate gap -> housing target (posterior mean)
kappa_ih_inc    = 0.03;     // permanent income -> housing target (paper eq 66, Table 4.6.14)
// growth neutrality coeff = 1 - 0.20 - 0.08 - 0.30 = 0.42

// Term structure parameters (calibrated from Section 4.8 / Table 4.8.1)
// AU 10Y yield tracks RBA cash rate with smoothing + term premium
rho_L           = 0.900;    // legacy (unused — replaced by kappa_10 PV form)
kappa_10        = 0.97;     // term structure decay (paper eq 97, duration ~10Y)
tp_ss           = 0.30;     // SS term premium (~1.2% annual, AU avg yield curve slope)
rho_tp          = 0.98;     // term premium very persistent (global risk appetite)
// SS: i_10y = i_ss + tp_ss = 1.0491 + 0.30 = 1.3491 (~5.4% annual)

// WACC parameters (calibrated from Section 4.8 / eq. 98)
// Cost of capital = long rate + credit/equity spread
rho_wacc        = 0.90;     // legacy (unused — WACC now decomposed)
spread_ss       = 0.50;     // SS composite spread (for uc_k SS calculation)
// SS: wacc = i_10y_ss + spread_ss = 1.3491 + 0.50 = 1.8491 (~7.4% annual)

// WACC decomposition (Section 4.8.3, eq 98, Table 4.8.4, adapted for AU)
w_COE           = 0.50;     // equity share of funding (paper: 0.5)
w_LB_firms      = 0.30;     // bank lending share (paper: 0.3)
w_BBB           = 0.20;     // bond share (paper: 0.2)
rho_COE         = 0.92;     // equity risk premium persistence (paper: 0.92)
rho_LB_firms    = 0.77;     // bank lending spread persistence (paper: 0.77)
rho_BBB         = 0.94;     // BBB spread persistence (paper: 0.94)
s_COE_ss        = 0.80;     // SS equity spread (~3.2% annual)
s_LB_firms_ss   = 0.25;     // SS bank lending spread (~1.0% annual)
s_BBB_ss        = 0.05;     // SS BBB bond spread (~0.2% annual)
// Weighted SS: 0.5*0.80 + 0.3*0.25 + 0.2*0.05 = 0.485 ≈ spread_ss

// Exchange rate parameters (calibrated from Section 4.8 / eq. 105)
// AUD/USD real exchange rate, UIP-based with persistent deviations from PPP
// s_gap > 0 = AUD depreciation (less purchasing power)
rho_s           = 0.950;    // persistent misalignment (posterior mean)
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

// === Stage 12: equation audit fix parameter values ===

// CES substitution elasticity (paper Table 4.3.2: sigma = 0.53)
// CES substitution elasticity: governs employment target (eq 55), investment target
// (eq 63), and VA price target (unit cost dual, eqs 42-43).
sigma_ces       = 0.53;     // paper Table 4.3.2 estimate for France; adopted for AU

// Import price pass-through to domestic deflators (Section 4.7, IAD weights)
// beta_j_m = import content share * partial pass-through coefficient
beta_pc_m       = 0.10;     // consumption: ~20% import content, ~50% pass-through
beta_pib_m      = 0.12;     // business investment: ~25% import content
beta_pih_m      = 0.08;     // housing: ~15% import content (domestic materials)
gamma_oil       = 0.03;     // energy/commodity -> CPI (smaller for AU than FR)
beta_pm_com     = 0.05;     // commodity price -> import deflator

// Import-adjusted demand weights (import content of each expenditure component)
// From ABS input-output tables, approximate for AU economy
w_iad_c         = 0.12;     // consumption has moderate import content
w_iad_ib        = 0.25;     // business investment: capital goods highly imported
w_iad_ih        = 0.15;     // housing: some imported materials
w_iad_g         = 0.08;     // government: mostly domestic services
w_iad_x         = 0.30;     // exports: high re-export content (commodity processing)

// Household bank lending rate (Section 4.8.3, eq. 68, Table 4.6.17)
// Paper: iLH adjusts toward i_10y with spread, persistence rho = 0.88
rho_lh          = 0.88;     // bank lending rate persistence (paper beta0 = 0.88)
spread_lh       = 0.40;     // ~1.6% annual AU mortgage spread over 10Y bonds
// SS: i_lh = i_ss + tp_ss + spread_lh = 1.0491 + 0.30 + 0.40 = 1.7491 (~7.0% annual)

// Housing prices (Section 4.6.3, eq. 69, Table 4.6.18)
// Paper: AR(2) with rho0=0.48, rho1=0.43; simplified to AR(1) with ~0.90
rho_ph          = 0.90;     // high persistence (AU housing cycle ~7 year half-life)
alpha_ph_y      = 0.15;     // output gap -> housing prices (demand/income channel)
alpha_ph_r      = -0.10;    // rate hike -> lower house prices (credit channel)
kappa_ph        = 0.03;     // housing price gap -> household investment (Tobin's Q)

// Investment target output proportionality (Section 4.6.2, eq. 63)
// Paper: log I* = a0 + q - sigma*log(rKB) + log(I*/K*)
// The 'q' term means desired investment is proportional to output level.
kappa_ib_y      = 0.06;     // output gap -> business investment target

// PAC discount factor (paper Section 4.1: beta = 0.98 for most blocks)
beta_pac        = 0.98;

// -----------------------------------------------------------------------
// PAC infrastructure: auxiliary VAR + PAC model declarations
// Must appear BEFORE the model block.
// -----------------------------------------------------------------------

// Minimal TCM: just the VA price error-correction + target trend.
// Only 2 equations to keep it simple and match known-working patterns.
trend_component_model(model_name = esat_tcm,
    eqtags = ['eq_tcm_piQ_ec', 'eq_tcm_piQ_target'],
    targets = ['eq_tcm_piQ_target']);

pac_model(auxiliary_model_name = esat_tcm, discount = beta_pac, model_name = pac_pQ, growth = piQ_star_l(-1));

// Consumption TCM: 2 equations for consumption PAC.
trend_component_model(model_name = c_tcm,
    eqtags = ['eq_tcm_c_ec', 'eq_tcm_c_target'],
    targets = ['eq_tcm_c_target']);

pac_model(auxiliary_model_name = c_tcm, discount = beta_pac, model_name = pac_c, growth = c_star_l(-1));

// Business investment TCM: 2 equations for business investment PAC.
trend_component_model(model_name = ib_tcm,
    eqtags = ['eq_tcm_ib_ec', 'eq_tcm_ib_target'],
    targets = ['eq_tcm_ib_target']);

pac_model(auxiliary_model_name = ib_tcm, discount = beta_pac, model_name = pac_ib, growth = ib_star_l(-1));

// Household investment TCM: 2 equations for household investment PAC.
trend_component_model(model_name = ih_tcm,
    eqtags = ['eq_tcm_ih_ec', 'eq_tcm_ih_target'],
    targets = ['eq_tcm_ih_target']);

pac_model(auxiliary_model_name = ih_tcm, discount = beta_pac, model_name = pac_ih, growth = ih_star_l(-1));

// Employment TCM: 2 equations for employment PAC.
trend_component_model(model_name = n_tcm,
    eqtags = ['eq_tcm_n_ec', 'eq_tcm_n_target'],
    targets = ['eq_tcm_n_target']);

pac_model(auxiliary_model_name = n_tcm, discount = beta_pac, model_name = pac_n, growth = n_star_l(-1));

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

    // =================================================================
    // SHADOW E-SAT — TREND COMPONENT MODEL FORM (for Dynare PAC)
    // =================================================================
    // Written in diff() form for I(1) pseudo-level variables.
    // TCM requires: diff(x) = f(lagged vars) + shock
    // The I(0) gap variables are the differences of pseudo-levels.

    // Minimal TCM: 2 equations for VA price PAC.
    // Non-target: error-correction of detrended VA price level toward target.
    // Target: random walk (stochastic trend for VA price level).
    // TCM requires unit coefficient on x(-1) in EC term.
    // Form: diff(x) = a*target(-1) - x(-1) + b*diff(x(-1)) + eps
    // This means the EC speed is implicitly 1 (absorbed into target coeff).
    [name = 'eq_tcm_piQ_ec']
    diff(piQ_aux_l) = b0_pQ * piQ_star_l(-1) - piQ_aux_l(-1) + b1_pQ * diff(piQ_aux_l(-1)) + eps_e_q;

    [name = 'eq_tcm_piQ_target']
    piQ_star_l = piQ_star_l(-1) + eps_e_pQ_star;

    // --- Consumption TCM ---
    // Non-target: error-correction of detrended consumption level toward target.
    // Same structure as VA price TCM: unit EC coefficient on x(-1).
    [name = 'eq_tcm_c_ec']
    diff(c_aux_l) = b0_c * c_star_l(-1) - c_aux_l(-1) + b1_c * diff(c_aux_l(-1)) + eps_e_c;

    [name = 'eq_tcm_c_target']
    c_star_l = c_star_l(-1) + eps_e_c_star;

    // --- Business investment TCM ---
    [name = 'eq_tcm_ib_ec']
    diff(ib_aux_l) = b0_ib * ib_star_l(-1) - ib_aux_l(-1) + b1_ib * diff(ib_aux_l(-1)) + eps_e_ib;

    [name = 'eq_tcm_ib_target']
    ib_star_l = ib_star_l(-1) + eps_e_ib_star;

    // --- Household investment TCM ---
    [name = 'eq_tcm_ih_ec']
    diff(ih_aux_l) = b0_ih * ih_star_l(-1) - ih_aux_l(-1) + b1_ih * diff(ih_aux_l(-1)) + eps_e_ih;

    [name = 'eq_tcm_ih_target']
    ih_star_l = ih_star_l(-1) + eps_e_ih_star;

    // --- Employment TCM ---
    [name = 'eq_tcm_n_ec']
    diff(n_aux_l) = b0_n * n_star_l(-1) - n_aux_l(-1) + b1_n * diff(n_aux_l(-1)) + eps_e_n;

    [name = 'eq_tcm_n_target']
    n_star_l = n_star_l(-1) + eps_e_n_star;

    // =================================================================
    // LOG-LEVEL VARIABLES FOR DYNARE PAC (VA price)
    // =================================================================
    // Dynare PAC expects diff(z) on LHS. We accumulate piQ into a level.
    // At SS: pQ_level = pQ_star_level = 0 (gap model, everything demeaned).

    // Detrended price levels: pQ_level measures cumulated (piQ - pi_ss_au).
    // At SS: piQ = pi_ss_au => diff(pQ_level) = 0 => pQ_level = 0. Stationary.
    // This allows Dynare PAC to work on stationary level variables.
    [name = 'eq_piQ_from_level']
    piQ = (pQ_level - pQ_level(-1)) + pi_ss_au;

    // pQ_star_level accumulates the detrended VA price target growth.
    // Uses piQ_star_gap_e from the shadow E-SAT for PAC target tracking.
    // The main model piQ_star is still computed separately (eq_piQ_star).
    // pQ_star_level accumulates the detrended VA price target growth from the main model.
    // This is separate from the shadow VAR — it just tracks the main model's target.
    [name = 'eq_pQ_star_level']
    pQ_star_level = pQ_star_level(-1) + (piQ_star - pi_ss_au);

    // =================================================================
    // LOG-LEVEL VARIABLES FOR DYNARE PAC (Consumption)
    // =================================================================
    // dln_c has SS = 0 (gap model), so diff(ln_c_level) = dln_c directly.
    // At SS: dln_c = 0 => diff(ln_c_level) = 0 => ln_c_level = 0.
    [name = 'eq_dln_c_from_level']
    dln_c = ln_c_level - ln_c_level(-1);

    // =================================================================
    // LOG-LEVEL VARIABLES FOR DYNARE PAC (Business investment)
    // =================================================================
    [name = 'eq_dln_ib_from_level']
    dln_ib = ln_ib_level - ln_ib_level(-1);

    // =================================================================
    // LOG-LEVEL VARIABLES FOR DYNARE PAC (Household investment)
    // =================================================================
    [name = 'eq_dln_ih_from_level']
    dln_ih = ln_ih_level - ln_ih_level(-1);

    // =================================================================
    // LOG-LEVEL VARIABLES FOR DYNARE PAC (Employment)
    // =================================================================
    [name = 'eq_dln_n_from_level']
    dln_n = ln_n_level - ln_n_level(-1);

    // === CAPITAL ACCUMULATION (Section 4.3, eq 32) ===
    // K_t = (1-delta)*K_{t-1} + I_t. In growth rates (linearized):
    // dln_k = (1-delta_k)*dln_k(-1) + delta_k*dln_ib
    // At SS: dln_k = 0 (stationary gap model). I/K = delta_k at SS.
    // The (1-delta_k) persistence captures how capital builds up slowly.
    [name = 'eq_dln_k']
    dln_k = (1 - delta_k) * dln_k(-1) + delta_k * dln_ib;

    // === CES PRODUCTION FUNCTION (Section 4.3, sigma_ces = 0.53) ===
    // Growth-rate accounting form using capital growth from accumulation equation.
    // CES effects captured through factor demand target equations:
    //   - Employment target (eq_dln_n_star_bar): sigma_ces on rw_gap (eq 55)
    //   - Investment target (eq_dln_ib_star_bar): sigma_ces on dln_uc_k (eq 63)
    //   - VA price target (eq_piQ_star): gamma_uck on dln_uc_k (unit cost dual, eqs 42-43)
    // Does NOT redefine yhat_au — IS curve still drives output gap.
    [name = 'eq_dln_y_star']
    dln_y_star = alpha_k * dln_k
               + (1 - alpha_k) * dln_n_star_bar
               + dln_tfp;

    // TFP follows a persistent AR(1) process
    [name = 'eq_dln_tfp']
    dln_tfp = rho_tfp * dln_tfp(-1) + eps_tfp;

    // === WAGE-PRICE SPIRAL (Stage 9c, upgraded with TFP from Stage 9b) ===
    // Productivity growth: TFP-based (replaces cyclical proxy yhat_au - yhat_au(-1)).
    // From Cobb-Douglas: labor productivity = TFP / (1-alpha_k).
    // At SS: dln_prod = 0 (since dln_tfp = 0).
    [name = 'eq_dln_prod']
    dln_prod = dln_tfp / (1 - alpha_k);

    // Unit labor cost growth = wage inflation - productivity growth
    // At SS: dln_ulc = pi_ss_au - 0 = pi_ss_au (correct: ULC grows at inflation rate)
    [name = 'eq_dln_ulc']
    dln_ulc = pi_w - dln_prod;

    // === VA PRICE BLOCK ===
    // VA price target from CES unit cost dual (paper eqs. 42-43).
    // CES cost function: p_Q* = [alpha_K * r_KB^(1-sigma) + (1-alpha_K)*(w/e)^(1-sigma)]^(1/(1-sigma))
    // Log-linearized: piQ_star = s_K * d(uc_k) + s_L * dln_ulc.
    // gamma_ulc: labor share channel (ULC pass-through).
    // gamma_uck: capital share channel (user cost pass-through, zero at SS).
    // Growth neutrality: dln_uc_k = 0 at SS, so gamma_uck term vanishes.
    //   piQ_star_ss = rho_pQ_star*pi_ss + gamma_ulc*pi_ss + gamma_uck*0
    //                 + (1-rho_pQ_star-gamma_ulc)*pi_ss = pi_ss (verified)
    [name = 'eq_piQ_star']
    piQ_star = rho_pQ_star * piQ_star(-1)
             + gamma_ulc * dln_ulc
             + gamma_uck * dln_uc_k
             + (1 - rho_pQ_star - gamma_ulc) * pibar_au;

    [name = 'eq_piQ_star_bar']
    piQ_star_bar = pibar_au;

    // pQ_gap from detrended levels (equivalent to cumulated piQ_star - piQ)
    [name = 'eq_pQ_gap']
    pQ_gap = pQ_star_level - pQ_level;

    // VA price PAC equation — now using Dynare native pac_expectation().
    // pac_expectation(pac_pQ) replaces the manual omega_pQ * piQ_star term.
    // It computes h0'*Z_{t-1} + h1'*Z_{t-1} from the shadow E-SAT companion matrix,
    // giving the full discounted sum of expected future target changes (paper eqs 14-17).
    // The growth neutrality correction is handled by the 'growth' option in pac_model.
    // VA price PAC with Dynare native pac_expectation.
    // diff(pQ_level) = piQ - pi_ss_au (detrended).
    // Error correction: pQ_star_level(-1) - pQ_level(-1) = cumulated gap.
    // EC target must reference the TCM target variable (piQ_star_l),
    // not the main model's pQ_star_level, so PAC machinery can link them.
    [name = 'eq_piQ_pac']
    diff(pQ_level) = b0_pQ * (piQ_star_l(-1) - pQ_level(-1))
                     + b1_pQ * diff(pQ_level(-1))
                     + pac_expectation(pac_pQ)
                     + b2_pQ * yhat_au
                     + eps_pQ;

    // === UNEMPLOYMENT GAP (Okun's law, paper eq 53/Table 4.5.2) ===
    // u_gap = AR(1) with output gap driving force. Negative: higher output -> lower unemployment.
    // At SS: yhat_au = 0 => u_gap = 0.
    [name = 'eq_u_gap']
    u_gap = rho_u_gap * u_gap(-1) + okun_coeff * yhat_au;

    // PV of expected future unemployment gaps — VAR-BASED (backward-looking).
    // Backward approximation: weighted average of current and lagged PV.
    // At SS: u_gap = 0 => pv_u_gap = 0.
    [name = 'eq_pv_u_gap']
    pv_u_gap = beta_w * pv_u_gap(-1) + (1 - beta_w) * u_gap;

    // === WAGE PHILLIPS CURVE (Section 4.5.1, eq. 52) ===
    // Hybrid backward/forward Phillips curve for nominal wages.
    // Now uses forward PV of unemployment gap (pv_u_gap) instead of current yhat_au.
    // kappa_w measures sensitivity to expected labor market tightness.
    //
    // Stage 12 fix: Added efficiency trend (1-lambda_w)*dln_prod.
    // Growth neutrality: at SS with dln_prod = 0, pv_u_gap = 0:
    //   pi_w_ss = lambda_w*pi_w_ss + gamma_w*pi_ss + 0 + (1-lw-gw)*pi_ss + 0
    //   => pi_w_ss = pi_ss (verified)

    [name = 'eq_pi_w']
    pi_w = lambda_w * pi_w(-1)
           + gamma_w * pi_au
           + kappa_w * pv_u_gap
           + (1 - lambda_w - gamma_w) * pibar_au
           + (1 - lambda_w) * dln_prod
           + eps_w;

    // === EMPLOYMENT PAC (Section 4.5.2, eq. 56, 4th-order) ===
    // Target employment: n_star tracks potential output (zero growth in gap model).
    // Simplified: dln_n_star follows an AR(1) toward trend growth.
    // Full model: inverted CES production function determines n_star.

    [name = 'eq_dln_n_star']
    dln_n_star = rho_n_star * dln_n_star(-1)
                 + (1 - rho_n_star) * dln_n_star_bar;

    // Trend employment growth: derived from inverted production function (Stage 9b).
    // Stage 12 fix: Added real wage sensitivity from paper eq. 55:
    //   n* = b0 + q - ē - σ*(w̃ - pQ - ē - h)
    // In growth rates: dln_n_star depends on productivity AND real wage gap.
    // rw_gap = pi_w - piQ - dln_prod: real wage growth above productivity.
    // When real wages rise above productivity, firms reduce labor demand.
    // At SS: rw_gap = 0 => no effect. dln_tfp = 0 => dln_n_star_bar = 0.
    [name = 'eq_dln_n_star_bar']
    dln_n_star_bar = dln_tfp / (1 - alpha_k) - sigma_ces * rw_gap;

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

    // Employment PAC equation — now using Dynare native pac_expectation().
    // pac_expectation(pac_n) replaces omega_n * dln_n_star + neutrality term.
    // 4th-order adjustment costs: 4 AR lags of diff(ln_n_level).

    [name = 'eq_dln_n_pac']
    diff(ln_n_level) = b0_n * (n_star_l(-1) - ln_n_level(-1))
            + b1_n * diff(ln_n_level(-1))
            + b2_n * diff(ln_n_level(-2))
            + b3_n * diff(ln_n_level(-3))
            + b4_n * diff(ln_n_level(-4))
            + pac_expectation(pac_n)
            + b5_n * yhat_au
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

    // Permanent income — VAR-BASED (backward-looking).
    // Backward approximation of discounted PV.
    // At SS: yhat_au = 0 => pv_yh = 0.
    [name = 'eq_pv_yh']
    pv_yh = beta_c * pv_yh(-1) + (1 - beta_c) * yhat_au;

    // Consumption target (paper eq 59): c* = a0 + PV(yH) + alpha1*(rLH - r_bar).
    // In growth rates: dln_c_star_bar = kappa_inc*d(pv_yh) + alpha_c_r*d(r_lh_gap).
    // Real lending rate gap: (i_lh - pi_c) - (i_ss + tp_ss + spread_lh - pi_ss_au).
    // At SS: pv_yh=0, i_lh=SS, pi_c=pi_ss => dln_c_star_bar = 0.
    [name = 'eq_dln_c_star_bar']
    dln_c_star_bar = kappa_inc * (pv_yh - pv_yh(-1))
                   + alpha_c_r * ((i_lh - pi_c - (i_ss + tp_ss + spread_lh - pi_ss_au))
                                - (i_lh(-1) - pi_c(-1) - (i_ss + tp_ss + spread_lh - pi_ss_au)));

    // Consumption gap accumulation
    [name = 'eq_c_gap']
    c_gap = c_gap(-1) + dln_c_star - dln_c;

    // Consumption PAC equation — now using Dynare native pac_expectation().
    // pac_expectation(pac_c) replaces omega_c * dln_c_star + (1-b1_c-omega_c) * dln_c_star_bar(-1).
    // It computes h0'*Z_{t-1} + h1'*Z_{t-1} from the consumption TCM companion matrix.
    // Growth neutrality correction handled by 'growth' option in pac_model.
    // EC term references TCM target variable (c_star_l), not main model's c_gap.
    //
    // Stage 12 fix preserved: real bank lending rate gap (i_lh - pi_c).

    [name = 'eq_dln_c_pac']
    diff(ln_c_level) = b0_c * (c_star_l(-1) - ln_c_level(-1))
            + b1_c * diff(ln_c_level(-1))
            + pac_expectation(pac_c)
            + b2_c * i_gap(-1)
            + b3_c * yhat_au
            + eps_c;

    // === BUSINESS INVESTMENT PAC (Section 4.6.2, eq. 64, 2nd-order) ===
    // Target: desired capital stock from inverted production function
    // Simplified: dln_ib_star tracks output growth (accelerator)
    // Full: user cost of capital (WACC + depreciation + relative prices) from Phase 5

    [name = 'eq_dln_ib_star']
    dln_ib_star = rho_ib_star * dln_ib_star(-1)
                  + (1 - rho_ib_star) * dln_ib_star_bar;

    // User cost of capital (Stage 10b): financial cost + depreciation - capital gains
    // At SS: uc_k = wacc_ss + delta_k - 0 = i_ss + tp_ss + spread_ss + delta_k
    [name = 'eq_uc_k']
    uc_k = wacc + delta_k - (pi_ib - piQ);

    // User cost growth: needed for CES capital demand and unit cost dual.
    // At SS: uc_k constant => dln_uc_k = 0.
    [name = 'eq_dln_uc_k']
    dln_uc_k = uc_k - uc_k(-1);

    // Investment target: CES capital demand (paper eq. 63).
    // log I* = a0 + q - sigma*log(rKB) + log(I*/K*).
    // In growth rates: dln_ib_star = dln_q - sigma*d(log rKB).
    // sigma_ces: CES substitution elasticity governs sensitivity to user cost changes.
    // kappa_ib_y: output proportionality ('q' term in eq. 63).
    // At SS: dln_uc_k = 0, yhat_au = 0 => target = 0.
    [name = 'eq_dln_ib_star_bar']
    dln_ib_star_bar = kappa_ib_y * yhat_au - sigma_ces * dln_uc_k;

    // Investment gap accumulation
    [name = 'eq_ib_gap']
    ib_gap = ib_gap(-1) + dln_ib_star - dln_ib;

    // Auxiliary lag variable for 2nd-order PAC
    [name = 'eq_dln_ib_1']
    dln_ib_1 = dln_ib(-1);

    // Business investment PAC equation — now using Dynare native pac_expectation().
    // pac_expectation(pac_ib) replaces omega_ib * dln_ib_star + neutrality term.
    // 2nd-order adjustment costs: 2 AR lags of diff(ln_ib_level).
    // Accelerator (b3_ib): output gap drives investment via demand.
    // User cost (b4_ib): interest rate gap depresses investment.

    [name = 'eq_dln_ib_pac']
    diff(ln_ib_level) = b0_ib * (ib_star_l(-1) - ln_ib_level(-1))
             + b1_ib * diff(ln_ib_level(-1))
             + b2_ib * diff(ln_ib_level(-2))
             + pac_expectation(pac_ib)
             + b3_ib * yhat_au
             + b4_ib * i_gap(-1)
             + eps_ib;

    // === HOUSEHOLD INVESTMENT PAC (Section 4.6.3, eq. 67, 2nd-order) ===
    // Target: desired housing stock from housing demand function
    // Simplified: dln_ih_star tracks income growth
    // Full: user cost of housing capital (mortgage rate + depreciation + house prices)
    // Australia-specific: variable-rate mortgages => strong RBA transmission

    [name = 'eq_dln_ih_star']
    dln_ih_star = rho_ih_star * dln_ih_star(-1)
                  + (1 - rho_ih_star) * dln_ih_star_bar;

    // Housing investment target (paper eq 66): log I*_H = a0 + PV(yH)
    //   + gamma_1*(pIH - pC) + gamma_2*(pSH - pC) + gamma_3*log(rLH + delta_H).
    // In growth rates: permanent income + mortgage rate gap + housing Tobin's Q.
    // Relative price of new vs existing housing approximated by ph_gap
    // (existing price gap captures the Tobin's Q incentive to build).
    // At SS: pv_yh=0, i_lh=SS, ph_gap=0 => target = 0.
    [name = 'eq_dln_ih_star_bar']
    dln_ih_star_bar = kappa_ih_inc * (pv_yh - pv_yh(-1))
                      - kappa_mort * (i_lh - (i_ss + tp_ss + spread_lh))
                      + kappa_ph * ph_gap(-1);

    // Housing investment gap accumulation
    [name = 'eq_ih_gap']
    ih_gap = ih_gap(-1) + dln_ih_star - dln_ih;

    // Auxiliary lag variable for 2nd-order PAC
    [name = 'eq_dln_ih_1']
    dln_ih_1 = dln_ih(-1);

    // Household investment PAC equation — now using Dynare native pac_expectation().
    // pac_expectation(pac_ih) replaces omega_ih * dln_ih_star + neutrality term.
    // 2nd-order adjustment costs: 2 AR lags of diff(ln_ih_level).
    // Mortgage channel (b4_ih): strongest interest rate sensitivity.

    [name = 'eq_dln_ih_pac']
    diff(ln_ih_level) = b0_ih * (ih_star_l(-1) - ln_ih_level(-1))
             + b1_ih * diff(ln_ih_level(-1))
             + b2_ih * diff(ln_ih_level(-2))
             + pac_expectation(pac_ih)
             + b3_ih * yhat_au
             + b4_ih * i_gap(-1)
             + eps_ih;

    // =================================================================
    // FINANCIAL BLOCK (Section 4.8)
    // =================================================================

    // === TERM STRUCTURE (paper eqs 95-97, 132) ===
    // i_10 = PV(i) + s_10 where PV(i) is the discounted sum of expected
    // future short rates (eq 97: kappa_10 = 0.97 decay parameter).
    // Recursive form (eq 132): PV(i)_t = (1-kappa_10)*i_t + kappa_10*PV(i)_{t+1}
    // This works for both VAR-based and MCE expectations.
    // At SS: pv_i = i_ss, i_10y = i_ss + tp_ss.

    [name = 'eq_term_premium']
    tp = rho_tp * tp(-1) + (1 - rho_tp) * tp_ss + eps_tp;

    // Expected discounted sum of future short rates — VAR-BASED (backward).
    [name = 'eq_pv_i']
    pv_i = kappa_10 * pv_i(-1) + (1 - kappa_10) * i_au;

    // 10Y rate = expectation component + term premium + residual
    [name = 'eq_i_10y']
    i_10y = pv_i + tp + eps_10y;

    // === WACC (Section 4.8.3, eq 98-100, Table 4.8.4) ===
    // Decomposed into 3 components: cost of equity, bank lending, BBB bonds.
    // Each rate = 10Y govt rate + spread_j. Spreads follow AR(1).
    // wacc = w_COE*i_COE + w_LB*i_LB + w_BBB*i_BBB
    // At SS: wacc = i_10y_ss + weighted_spread_ss

    // Spread processes (eq 100)
    [name = 'eq_s_COE']
    s_COE = (1 - rho_COE) * s_COE_ss + rho_COE * s_COE(-1) + eps_COE;

    [name = 'eq_s_LB_firms']
    s_LB_firms = (1 - rho_LB_firms) * s_LB_firms_ss + rho_LB_firms * s_LB_firms(-1) + eps_LB_firms;

    [name = 'eq_s_BBB']
    s_BBB = (1 - rho_BBB) * s_BBB_ss + rho_BBB * s_BBB(-1) + eps_BBB;

    // Component rates (eq 99)
    [name = 'eq_i_COE']
    i_COE = i_10y + s_COE;

    [name = 'eq_i_LB_firms']
    i_LB_firms = i_10y + s_LB_firms;

    [name = 'eq_i_BBB']
    i_BBB = i_10y + s_BBB;

    // WACC identity (eq 98)
    [name = 'eq_wacc']
    wacc = w_COE * i_COE + w_LB_firms * i_LB_firms + w_BBB * i_BBB;

    // === EXCHANGE RATE (eq. 105) ===
    // Real exchange rate gap follows modified UIP.
    // s_gap > 0 = AUD depreciation (weaker purchasing power).
    // Higher AU interest rates attract capital, appreciating AUD (negative alpha_s).
    // Persistent deviations from PPP (rho_s ~0.92, half-life ~8 quarters).
    //
    // At SS: s_gap = 0 (PPP holds in long run)

    // Stage 12 fix: Added inflation differential per paper eq. 104.
    // Paper: ξ + p_EA - p_F = Σ(i-i_F) - Σ(π_EA - π_F).
    // Real interest rate differential = (i - π) - (i_F - π_F).
    // Higher AU inflation reduces real rate attractiveness → AUD depreciates.
    // Uses same alpha_s coefficient (real rate parity).
    [name = 'eq_s_gap']
    s_gap = rho_s * s_gap(-1)
            - alpha_s * i_gap
            + alpha_s * (pi_au_gap - pi_us_gap)
            + eps_s;

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
            + b4_x * dln_pcom
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

    // Stage 12 fix: Replaced yhat_au with import-adjusted demand (iad).
    // Paper eqs. 72-75: imports driven by IAD = Σ(w_j * component_j),
    // with weights = import content shares from input-output tables.
    // IAD correctly distinguishes high-import-content demand (investment,
    // exports) from low-import-content demand (government spending).
    [name = 'eq_dln_m']
    dln_m = b0_m * m_gap(-1)
            + b1_m * dln_m(-1)
            + b2_m * iad
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

    // === Consumption deflator (CPI-like, Section 4.7.1, eqs. 79-80) ===
    // Stage 12 fix: Added import price channel (beta_pc_m * pi_m) and
    // energy/commodity price pass-through (gamma_oil * dln_pcom).
    // Paper target: p*_C = (1-β0)*pQ + β0*pM (β0 = IAD import content ~0.23).
    // Growth neutrality: (rho_pc + alpha_pc + beta_pc_m) < 1, rest on pibar_au.
    // At SS: all pi = pi_ss, dln_pcom = 0 => pi_c = pi_ss (verified).
    [name = 'eq_pi_c']
    pi_c = rho_pc * pi_c(-1)
           + alpha_pc * piQ
           + beta_pc_m * pi_m
           + gamma_oil * dln_pcom
           + (1 - rho_pc - alpha_pc - beta_pc_m) * pibar_au
           + eps_pc;

    // === Business investment deflator (Section 4.7.2, eqs. 81-82) ===
    // Stage 12 fix: Added import price channel (beta_pib_m * pi_m).
    // Capital goods have high import content (~25%).
    [name = 'eq_pi_ib']
    pi_ib = rho_pib * pi_ib(-1)
            + alpha_pib * piQ
            + beta_pib_m * pi_m
            + (1 - rho_pib - alpha_pib - beta_pib_m) * pibar_au
            + eps_pib;

    // === Household investment deflator (construction costs, Section 4.7.3, eqs. 83-84) ===
    // Stage 12 fix: Added import price channel (beta_pih_m * pi_m).
    // Housing construction uses some imported materials (~15%).
    [name = 'eq_pi_ih']
    pi_ih = rho_pih * pi_ih(-1)
            + alpha_pih * piQ
            + beta_pih_m * pi_m
            + (1 - rho_pih - alpha_pih - beta_pih_m) * pibar_au
            + eps_pih;

    // === Export deflator (world price + commodity influence via exchange rate) ===
    // Depreciation (s_gap > 0) raises domestic-currency export prices.
    // Commodity price pass-through (Stage 11b): higher pcom → higher export deflator.
    [name = 'eq_pi_x']
    pi_x = rho_px * pi_x(-1)
           + alpha_px * piQ
           + (1 - rho_px - alpha_px) * pibar_au
           + beta_px * s_gap
           + alpha_pcom * dln_pcom
           + eps_px;

    // === Import deflator (exchange rate pass-through dominant, Section 4.7.5) ===
    // Depreciation (s_gap > 0) raises import prices in AUD.
    // Stage 12 fix: Added commodity price pass-through (beta_pm_com * dln_pcom).
    // Captures energy import price channel without separate energy import block.
    // Paper has separate energy (eq. 91) and non-energy (eq. 89) import deflators.
    [name = 'eq_pi_m']
    pi_m = rho_pm * pi_m(-1)
           + alpha_pm * piQ
           + (1 - rho_pm - alpha_pm) * pibar_au
           + beta_pm * s_gap
           + beta_pm_com * dln_pcom
           + eps_pm;

    // =================================================================
    // COMMODITY PRICE CHANNEL (Stage 11b, Australia-specific)
    // =================================================================
    // Commodity prices: exogenous AR(1) + world demand link (via yhat_us).
    // Australia is a major commodity exporter — this channel is key.
    // At SS: dln_pcom = 0 (no trend commodity price growth in gap model).
    [name = 'eq_dln_pcom']
    dln_pcom = rho_pcom * dln_pcom(-1) + 0.10 * yhat_us + eps_pcom;

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

    // === Government deflator (Section 4.7.6, eq. 92) ===
    // Stage 12 fix: Paper uses πG = 0.54*(πW - Δē) + 0.46*π̄.
    // Government prices driven by public sector wages (not VA price).
    // alpha_pg weight on efficient wage (pi_w - dln_prod), rest on pibar_au.
    // At SS: alpha_pg*(pi_ss - 0) + ... = pi_ss (verified).
    // At BGP with g: alpha_pg*(pi_ss+g-g) + (1-rho_pg-alpha_pg)*pi_ss = pi_ss.
    [name = 'eq_pi_g']
    pi_g = rho_pg * pi_g(-1)
           + alpha_pg * (pi_w - dln_prod)
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

    // =================================================================
    // STAGE 12: NEW EQUATIONS (equation audit fixes)
    // =================================================================

    // === Real wage growth gap (for employment target, Section 4.3, eq. 27) ===
    // rw_gap = nominal wage growth - VA price inflation - productivity growth.
    // Measures how fast real wages grow above labor productivity.
    // When rw_gap > 0: real wages outpacing productivity → firms cut labor demand.
    // At SS: pi_w = pi_ss, piQ = pi_ss, dln_prod = 0 => rw_gap = 0.
    [name = 'eq_rw_gap']
    rw_gap = pi_w - piQ - dln_prod;

    // === Import-adjusted demand (Section 4.6.4, eqs. 72-73) ===
    // Weighted sum of expenditure components by their import content shares.
    // Replaces yhat_au in import equation for correct composition effects.
    // High-import-content components (investment, exports) get higher weight.
    // At SS: all dln_j = 0 => iad = 0.
    [name = 'eq_iad']
    iad = w_iad_c * dln_c + w_iad_ib * dln_ib + w_iad_ih * dln_ih
          + w_iad_g * dln_g + w_iad_x * dln_x;

    // === Household bank lending rate (Section 4.8.3, eq. 68) ===
    // Paper: ΔiLH = α1*(iLH(-1) - i10(-1) - α0) + lags of Δi10 + Δi10(-1) + ΔiLH(-1)
    // Simplified to partial adjustment toward 10Y rate + spread.
    // rho_lh captures the sluggish pass-through of market rates to retail rates.
    // At SS: i_lh = i_10y_ss + spread_lh = i_ss + tp_ss + spread_lh.
    [name = 'eq_i_lh']
    i_lh = rho_lh * i_lh(-1)
           + (1 - rho_lh) * (i_10y + spread_lh)
           + eps_lh;

    // === Housing price dynamics (Section 4.6.3, eq. 69) ===
    // Paper: ΔpSH = ρ0*ΔpSH(-1) + ρ1*ΔpSH(-2) + (1-ρ0-ρ1)*π̄.
    // Simplified to AR(1) of real housing price growth + demand/credit channels.
    // Real housing prices (deflated) so SS growth = 0.
    // Output gap: demand channel (higher income → higher house prices).
    // Interest rate: credit channel (rate hikes reduce borrowing → lower prices).
    // At SS: dln_ph = 0.
    [name = 'eq_dln_ph']
    dln_ph = rho_ph * dln_ph(-1)
             + alpha_ph_y * yhat_au
             + alpha_ph_r * i_gap(-1)
             + eps_ph;

    // Housing price gap accumulation (for Tobin's Q in household investment target)
    // ph_gap > 0: house prices above trend → incentive to build new housing.
    // Small mean-reversion (0.02 per quarter ≈ half-life 35 quarters) ensures
    // stationarity — housing price gaps are persistent but not permanent.
    // At SS: dln_ph = 0 => ph_gap = 0.
    [name = 'eq_ph_gap']
    ph_gap = 0.98 * ph_gap(-1) + dln_ph;

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

    // Production function (Section 4.3)
    dln_k        = 0;         // zero capital growth at SS (gap model)
    dln_y_star   = 0;         // zero potential output growth at SS (gap model)
    dln_tfp      = 0;         // zero TFP growth at SS

    // Wage-price spiral (Stage 9c)
    dln_prod     = 0;         // zero productivity growth at SS
    dln_ulc      = pi_ss_au;  // ULC grows at inflation rate at SS

    // VA price block
    piQ_star     = pi_ss_au;
    piQ_star_bar = pi_ss_au;
    piQ          = pi_ss_au;
    pQ_gap       = 0;

    // Wage Phillips curve
    u_gap        = 0;         // unemployment at equilibrium at SS
    pv_u_gap     = 0;         // PV of future unemployment gaps = 0 at SS
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
    pv_yh          = 0;       // permanent income PV = 0 at SS (gap model)
    dln_c          = 0;       // zero consumption growth in stationary model
    dln_c_star     = 0;
    dln_c_star_bar = 0;
    c_gap          = 0;

    // User cost of capital: uc_k = wacc + delta_k at SS (pi_ib = piQ at SS)
    uc_k           = w_COE*(i_ss+tp_ss+s_COE_ss) + w_LB_firms*(i_ss+tp_ss+s_LB_firms_ss) + w_BBB*(i_ss+tp_ss+s_BBB_ss) + delta_k;
    dln_uc_k       = 0;            // user cost constant at SS

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
    pv_i           = i_ss;                          // PV of future short rates = current rate at SS
    i_10y          = i_ss + tp_ss;                  // 10Y yield = short rate + term premium
    s_COE          = s_COE_ss;                      // equity spread at SS
    s_LB_firms     = s_LB_firms_ss;                 // bank lending spread at SS
    s_BBB          = s_BBB_ss;                      // BBB bond spread at SS
    i_COE          = i_ss + tp_ss + s_COE_ss;       // cost of equity at SS
    i_LB_firms     = i_ss + tp_ss + s_LB_firms_ss;  // bank lending rate firms at SS
    i_BBB          = i_ss + tp_ss + s_BBB_ss;        // BBB bond rate at SS
    wacc           = w_COE*(i_ss+tp_ss+s_COE_ss) + w_LB_firms*(i_ss+tp_ss+s_LB_firms_ss) + w_BBB*(i_ss+tp_ss+s_BBB_ss);
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

    // Commodity prices (Stage 11b)
    dln_pcom       = 0;       // zero commodity price growth at SS

    // Government
    dln_g          = 0;       // zero government spending growth in stationary model
    pi_g           = pi_ss_au;

    // GDP identity
    yhat_dom       = 0;       // zero at SS (all components zero)

    // Stage 12: new variables
    rw_gap         = 0;                            // pi_w - piQ - dln_prod = pi_ss - pi_ss - 0 = 0
    iad            = 0;                            // all dln_j = 0 => iad = 0
    i_lh           = i_ss + tp_ss + spread_lh;     // bank lending rate at SS
    dln_ph         = 0;                            // zero real housing price growth at SS
    ph_gap         = 0;                            // housing prices at trend at SS

    // PAC TCM variables (zero at SS)
    piQ_aux_l      = 0;
    piQ_star_l     = 0;

    // Log-level variables for PAC (zero at SS — gap model, everything demeaned)
    pQ_level       = 0;
    pQ_star_level  = 0;

    // Consumption PAC TCM + level variables
    c_aux_l        = 0;
    c_star_l       = 0;
    ln_c_level     = 0;

    // Business investment PAC TCM + level variables
    ib_aux_l       = 0;
    ib_star_l      = 0;
    ln_ib_level    = 0;

    // Household investment PAC TCM + level variables
    ih_aux_l       = 0;
    ih_star_l      = 0;
    ln_ih_level    = 0;

    // Employment PAC TCM + level variables
    n_aux_l        = 0;
    n_star_l       = 0;
    ln_n_level     = 0;
end;

// Initialize PAC models BEFORE steady (h vectors must be computed first)
pac.initialize('pac_pQ');
pac.update.expectation('pac_pQ');
pac.initialize('pac_c');
pac.update.expectation('pac_c');
pac.initialize('pac_ib');
pac.update.expectation('pac_ib');
pac.initialize('pac_ih');
pac.update.expectation('pac_ih');
pac.initialize('pac_n');
pac.update.expectation('pac_n');

steady;
check;

// -----------------------------------------------------------------------
// Shocks
// -----------------------------------------------------------------------

shocks;
    var eps_q;        stderr 0.506;     // posterior mean
    var eps_i;        stderr 0.081;     // posterior mean
    var eps_pi;       stderr 0.729;     // posterior mean
    var eps_q_us;     stderr 1.0879;
    var eps_pi_us;    stderr 0.2645;
    var eps_ibar;     stderr 0.01;
    var eps_pibar_au; stderr 0.01;
    var eps_pibar_us; stderr 0.01;
    var eps_pQ;       stderr 0.5;    // VA price shock (~0.5% quarterly)
    var eps_w;        stderr 0.6;    // wage shock (comparable to price Phillips)
    var eps_n;        stderr 0.4;    // employment shock
    var eps_c;        stderr 1.794;  // consumption shock (posterior mean)
    var eps_ib;       stderr 2.807;  // business investment shock (posterior mean)
    var eps_ih;       stderr 1.729;  // household investment shock (posterior mean)
    var eps_10y;      stderr 0.10;   // long rate shock (small — most variation from short rate)
    var eps_tp;       stderr 0.05;   // term premium shock (small, persistent)
    var eps_COE;      stderr 0.15;   // cost of equity spread shock
    var eps_LB_firms; stderr 0.10;   // bank lending spread shock (firms)
    var eps_BBB;      stderr 0.08;   // BBB bond spread shock
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
    var eps_tfp;      stderr 0.2;    // TFP shock (Stage 9a)
    var eps_pcom;     stderr 3.0;    // commodity price shock (Stage 11b, volatile)
    // Stage 12: new shocks
    var eps_lh;       stderr 0.15;   // bank lending rate shock (credit conditions)
    var eps_ph;       stderr 1.0;    // housing price shock (AU housing very volatile)
    // Shadow E-SAT shocks (same scale as main E-SAT)
    var eps_e_q;      stderr 0.506;   // TCM non-target shock (VA price)
    var eps_e_pQ_star; stderr 0.5;   // TCM target shock (VA price)
    var eps_e_c;      stderr 0.506;   // TCM non-target shock (consumption)
    var eps_e_c_star; stderr 0.5;    // TCM target shock (consumption)
    var eps_e_ib;     stderr 0.506;  // TCM non-target shock (business investment)
    var eps_e_ib_star; stderr 0.5;   // TCM target shock (business investment)
    var eps_e_ih;     stderr 0.506;  // TCM non-target shock (household investment)
    var eps_e_ih_star; stderr 0.5;   // TCM target shock (household investment)
    var eps_e_n;      stderr 0.506;  // TCM non-target shock (employment)
    var eps_e_n_star; stderr 0.5;    // TCM target shock (employment)
end;

// -----------------------------------------------------------------------
// Compute IRFs
// -----------------------------------------------------------------------

stoch_simul(order=1, irf=40, nograph, noprint) yhat_au pi_au i_au piQ dln_c dln_ib dln_ih dln_n pi_w s_gap i_10y;

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
// varobs yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;

// -----------------------------------------------------------------------
// Estimated parameters with priors
// -----------------------------------------------------------------------
// Priors centered on current calibrated values with informative spreads.
// Beta distribution for [0,1] parameters, Gamma for positive, Normal for others.
//
// estimated_params;
//     // --- Demand block: key PAC parameters ---
//     b0_c,       beta_pdf, 0.06, 0.02;
//     b1_c,       beta_pdf, 0.35, 0.10;
//     omega_c,    beta_pdf, 0.35, 0.10;
//     b3_c,       normal_pdf, 0.15, 0.05;
//     b0_ib,      beta_pdf, 0.04, 0.02;
//     b1_ib,      beta_pdf, 0.25, 0.08;
//     b3_ib,      normal_pdf, 0.20, 0.08;
//     b0_ih,      beta_pdf, 0.05, 0.02;
//     b1_ih,      beta_pdf, 0.20, 0.08;
//     // --- Labor block ---
//     lambda_w,   beta_pdf, 0.55, 0.10;
//     kappa_w,    normal_pdf, 0.10, 0.05;
//     b0_n,       beta_pdf, 0.04, 0.02;
//     // --- Financial block ---
//     rho_L,      beta_pdf, 0.85, 0.05;
//     rho_s,      beta_pdf, 0.92, 0.03;
//     // --- Feedback parameters (Phase 7) ---
//     lambda_dom, beta_pdf, 0.10, 0.05;
//     kappa_wacc, normal_pdf, 0.04, 0.02;
//     kappa_mort, normal_pdf, 0.05, 0.02;
//     kappa_inc,  normal_pdf, 0.08, 0.04;
//     // --- Shock standard deviations ---
//     stderr eps_q,        inv_gamma_pdf, 0.80, inf;
//     stderr eps_i,        inv_gamma_pdf, 0.10, inf;
//     stderr eps_pi,       inv_gamma_pdf, 0.60, inf;
//     stderr eps_c,        inv_gamma_pdf, 0.50, inf;
//     stderr eps_ib,       inv_gamma_pdf, 1.50, inf;
//     stderr eps_ih,       inv_gamma_pdf, 2.00, inf;
// end;

// -----------------------------------------------------------------------
// Estimation command
// -----------------------------------------------------------------------
// estimation(datafile='estimation_data.mat',
//            first_obs=1, nobs=122,
//            mh_replic=10000, mh_nblocks=2, mh_jscale=0.3,
//            mode_compute=4, presample=4,
//            bayesian_irf,
//            graph_format=(eps), nograph)
//            yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;
