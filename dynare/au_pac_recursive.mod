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
    di_gap          // first difference of i_gap (for consumption PAC, FR-BDF eq 61)
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
    dln_tfp         // total factor productivity growth (quarterly %; transient = ln_tfp - ln_tfp(-1))
    ln_tfp_LR       // long-run log-TFP level (random walk; FR-BDF wp736 §4.3 Ē_t)
    ln_tfp          // smoothed log-TFP level (AR(1) toward ln_tfp_LR)

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
    pv_r_lh_gap     // PV of expected future real lending rate gap (FR-BDF eq 61, audit #26)

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
    pv_i_uip        // forward PV of policy-rate gap for UIP (Hybrid: forward)

    // === Trade block (Section 4.7) ===
    // Proper ECM: long-run equilibrium ln_X_eq / ln_M_eq, plus short-run dynamics.
    // Log-level accumulators are in deviation from SS trend (all SS = 0).
    dln_x           // export volume growth (quarterly log diff)
    ln_x_level      // log exports level (deviation, accumulates dln_x)
    ln_x_eq         // export LR equilibrium (FR-BDF eq 71, deviation form)
    x_gap           // export EC term: ln_x_eq - ln_x_level
    dln_m           // import volume growth (quarterly log diff)
    ln_m_level      // log imports level (deviation, accumulates dln_m)
    ln_m_eq         // import LR equilibrium (FR-BDF eq 76, deviation form)
    m_gap           // import EC term: ln_m_eq - ln_m_level
    ln_d_iad        // log import-weighted demand level (accumulates iad)

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

    // === E-SAT shadow variables for var_model (FR-BDF Section 3.1.1) ===
    // These are simplified copies of E-SAT core dynamics in pure VAR(1) form
    // (no contemporaneous terms), used as the auxiliary model for PAC.
    y_gap_var       // shadow output gap (pure VAR form of yhat_au)
    i_gap_var       // shadow interest rate gap (pure VAR form of i_gap)
    pi_gap_var      // shadow inflation gap (pure VAR form of pi_au_gap)
    // Additional E-SAT state variables (FR-BDF Tables 4.4.4, 4.5.7 use 6-9 states)
    u_gap_var       // shadow unemployment gap (Okun's law in VAR form)
    yhat_us_var     // shadow foreign output gap (AR(1) in VAR form)
    // Auxiliary gap variables (appended to E-SAT, FR-BDF Tables 4.4.4, 4.5.7, etc.)
    piQ_hat         // VA price target gap (FR-BDF eq 45-47 chain)
    n_hat           // employment target gap (FR-BDF eq 57)
    yh_ratio_hat    // household income-output ratio gap (FR-BDF Table 4.6.3: yH-ȳ)
    c_hat           // consumption PV² gap (FR-BDF Table 4.6.4: PV of yh_ratio_hat)
    ib_hat          // business investment output gap (FR-BDF Table 4.6.11)
    rKB_hat         // user cost of capital gap (FR-BDF Table 4.6.12: r̂_KB)
    ih_hat          // housing investment target gap (FR-BDF Table 4.6.16)
    // Backward expectation correction variables (additive wedge at first order)
    // These represent the DIFFERENCE between E-SAT simplified forecast and full model RE.
    // Present in backward models only; absent in MCE.
    pv_piQ_aux  pv_n_aux  pv_c_aux  pv_ib_aux  pv_rKB_aux  pv_ih_aux

    // === Sector financial accounts (Section 4.8.5, eqs 116-126) ===
    // Net financial asset ratios (W_j / nominal LR GDP, quarterly)
    w_F             // firms net financial asset ratio (negative = net debtor)
    w_G             // government net financial asset ratio (negative = govt debt)
    w_H             // households net financial asset ratio (positive = net saver)
    w_N             // NPISH net financial asset ratio
    // Net property income ratios (YF_j / nominal LR GDP)
    yf_F            // firms net property income ratio
    yf_G            // government net property income ratio
    yf_H            // households net property income ratio
    yf_N            // NPISH net property income ratio
    // Net financing capacity ratios (B_j / nominal LR GDP)
    b_F             // firms net financing capacity ratio
    b_G             // government fiscal balance ratio
    b_H             // households net financing capacity ratio
    b_N             // NPISH net financing capacity ratio
    // Transfer rates (to households, as share of LR GDP)
    tau_F           // firms dividend/transfer rate to households
    tau_G           // government social transfer rate (fiscal rule instrument)
    tau_N           // NPISH transfer rate to households
    // Asset return rates
    i_F             // effective return on firms net assets
    i_G             // effective return on government net assets
    i_H             // effective return on household net assets
    i_N             // effective return on NPISH net assets
    // Current account
    b_ROW           // rest of world net financing = -(sum of domestic B_j)

    // === PAC level-accumulation variables (for Dynare PAC diff() form) ===
    pQ_level        // VA price detrended log-level (diff = piQ - pi_ss_au)
    pQ_star_level   // VA price target detrended log-level
    ln_c_level      // consumption detrended log-level (diff = dln_c)
    ln_ib_level     // business investment detrended log-level (diff = dln_ib)
    ln_ih_level     // household investment detrended log-level (diff = dln_ih)
    ln_n_level      // employment detrended log-level (diff = dln_n)

    // === Trend level accumulators (FR-BDF eq 43 — recover levels from gaps) ===
    // These accumulate trend growth rates into log-level indices.
    // Actual level = trend level + gap accumulator.
    // All zero at SS (gap model). Non-zero only after shocks.
    ln_QN           // log potential output index (accumulates dln_y_star)
    ln_Q            // log actual output index = ln_QN + yhat_au
    ln_C_star       // log trend consumption index (accumulates dln_c_star_bar)
    ln_C            // log actual consumption = ln_C_star + ln_c_level
    ln_IB_star      // log trend business investment index (accumulates dln_ib_star_bar)
    ln_IB           // log actual business investment = ln_IB_star + ln_ib_level
    ln_IH_star      // log trend household investment index (accumulates dln_ih_star_bar)
    ln_IH           // log actual household investment = ln_IH_star + ln_ih_level
    ln_N_star       // log trend employment index (accumulates dln_n_star_bar)
    ln_N            // log actual employment = ln_N_star + ln_n_level
    ln_K            // log capital stock index (accumulates dln_k)
    ln_P_star       // log trend price level index (accumulates pibar_au)
    ln_P            // log actual price level = ln_P_star + pQ_level
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
    eps_tfp_LR      // permanent log-TFP level shock (FR-BDF wp736 §5.2.7, 2026-05-15)
    // Commodity price shock (Stage 11b)
    eps_pcom        // commodity price shock
    // Stage 12: equation audit fixes
    eps_lh          // household bank lending rate shock
    eps_ph          // housing price shock
    // var_model shocks (for enriched E-SAT auxiliary model)
    eps_var_y       // shadow output gap shock
    eps_var_i       // shadow interest rate gap shock
    eps_var_pi      // shadow inflation gap shock
    eps_var_pQ      // VA price auxiliary gap shock
    eps_var_n       // employment auxiliary gap shock
    eps_var_c       // consumption auxiliary gap shock
    eps_var_ib      // business investment auxiliary gap shock
    eps_var_ih      // housing investment auxiliary gap shock
    eps_var_u       // shadow unemployment gap shock
    eps_var_yus     // shadow foreign output gap shock
    eps_var_yh      // household income-output ratio gap shock
    eps_var_rKB     // user cost of capital gap shock

    // COVID pulse dummies (exogenous, zero at SS)
    d_covid_crash       // = 1 in 2020Q2 only (lockdown quarter)
    d_covid_bounce      // = 1 in 2020Q3 only (rebound quarter)
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
    b_di_c          // interest rate CHANGE sensitivity (FR-BDF eq 61 β₃)
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
    b_ph_ih         // housing price gap in short-run PAC (FR-BDF eq 67 β₃)
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
    beta_uip        // UIP forward-NPV discount (Hybrid: forward NPV recursion)

    // --- Export parameters (Section 4.7, eqs. 70-73) ---
    b0_x            // error correction speed
    b1_x            // export growth persistence
    b2_x            // SR world demand elasticity (yhat_us -> exports)
    b3_x            // SR exchange rate elasticity (depreciation -> more exports)
    beta_x          // LR foreign income elasticity (FR-BDF eq 71)
    gamma_x         // LR real exchange rate elasticity (depreciation > 0)

    // --- Import parameters (Section 4.7, eqs. 74-77) ---
    b0_m            // error correction speed
    b1_m            // import growth persistence
    b2_m            // SR domestic demand elasticity (iad -> imports)
    b3_m            // SR exchange rate elasticity (depreciation -> fewer imports)
    beta_m          // LR income elasticity of imports (FR-BDF eq 76; >1 ⇒ rising openness)
    gamma_m         // LR real exchange rate elasticity (depreciation < 0)

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

    // === Sector financial account parameters (Section 4.8.5) ===
    // SS asset ratios (W_j / annualized nominal GDP, calibrated from ABS)
    w_F_ss          // firms SS net asset ratio (-0.70 * 4 = -2.80 quarterly)
    w_G_ss          // government SS net asset ratio (-0.40 * 4 = -1.60 quarterly)
    w_N_ss          // NPISH SS net asset ratio (0.02 * 4 = 0.08 quarterly)
    // SS transfer rates
    tau_F_ss        // firms SS dividend rate
    tau_G_ss        // government SS social transfer rate
    tau_N_ss        // NPISH SS transfer rate
    // Stabilization rule parameters (eqs 123-125)
    rho_stab_1      // transfer adjustment speed (0.1)
    rho_stab_2      // debt-stabilizing reaction coefficient (0.1)
    // Asset return convergence
    rho_i_asset     // persistence of asset returns toward i_10y (0.983, ~40Q half-life)
    // SS return premia (over i_10y)
    i_F_prem        // firms return premium
    i_H_prem        // households return premium
    i_N_prem        // NPISH return premium
    // Revaluation parameter for firms (eq 122)
    gamma_reval     // firms revaluation as share of nominal GDP (-0.018)
    // Nominal growth rate (for debt-stabilizing computation)
    g_nom           // quarterly nominal growth rate (real + inflation at SS)

    // PAC discount factor
    beta_pac        // quarterly subjective discount (0.98 ≈ 8% annual)

    // === Dynamic E-SAT auxiliary equation parameters ===
    // Aligned with FR-BDF Tables 4.4.4, 4.5.7, 4.6.3, 4.6.11-12, 4.6.16.
    // Each auxiliary: pv_X_aux = rho·lag + a_y·ŷ(-1) + a_i·(i-ī)(-1) + a_pi·(π-π̄)(-1) + a_u·û(-1)
    // Absent in MCE files (forward leads capture everything).

    // VA price (FR-BDF Table 4.4.4: 3-eq chain — Phillips, Okun, target growth)
    rho_pQ_aux      // own persistence
    a_pQ_y          // output gap (Phillips → ULC → VA price)
    a_pQ_i          // interest rate gap (cost channel)
    a_pQ_pi         // inflation gap (FR-BDF policy fn: 0.00087)
    a_pQ_u          // unemployment gap (wage → ULC channel, FR-BDF: û coeff = -0.011)

    // Employment (FR-BDF Table 4.5.7, eq 57: n̂* = f(ŷ, i, π, û, n̂*))
    rho_n_aux       // own persistence (FR-BDF: 0.67)
    a_n_y           // output gap (Okun, FR-BDF: 0.30)
    a_n_i           // interest rate gap (FR-BDF: 0.07, n.s.)
    a_n_pi          // inflation gap (FR-BDF: 0.16)
    a_n_u           // unemployment gap (FR-BDF Table 4.5.7: implicit via Okun)

    // Household income-output ratio (FR-BDF Table 4.6.3: yH-ȳ auxiliary)
    rho_yh_aux      // own persistence (FR-BDF: 0.92)
    a_yh_y          // output gap → income ratio (FR-BDF: implicit via Okun)
    a_yh_u          // unemployment gap → income ratio (FR-BDF: -0.08 via labor income)

    // Consumption PV² (FR-BDF Table 4.6.4: PV of yH-ȳ changes)
    rho_c_aux       // own persistence
    a_c_y           // output gap (income channel)
    a_c_i           // interest rate gap (substitution)
    a_c_pi          // inflation gap (FR-BDF PV²: 0.002)
    a_c_u           // unemployment gap (income expectation, FR-BDF: -0.03)
    a_c_yh          // income-output ratio gap (FR-BDF PV²: 0.034, key nested PV channel)

    // Business investment output gap (FR-BDF Table 4.6.11: q̂ auxiliary)
    rho_ib_aux      // own persistence (FR-BDF: 0.59 for q̂ aux)
    a_ib_y          // output gap (accelerator, FR-BDF: 0.61 in aux / 0.035 in policy fn)
    a_ib_pi         // inflation gap (FR-BDF: 0.027 in policy fn)
    a_ib_u          // unemployment gap (FR-BDF: implicit via output-unemployment link)

    // Business investment user cost gap (FR-BDF Table 4.6.12: r̂_KB auxiliary)
    rho_rKB_aux     // own persistence (FR-BDF: -0.055 in policy fn)
    a_rKB_i         // interest rate gap (FR-BDF: 4.45 in aux, 0.24 in policy fn)

    // Housing investment (FR-BDF Table 4.6.16: Î*_H = f(ŷ, i, π, Î*_H))
    rho_ih_aux      // own persistence (FR-BDF: 0.71)
    a_ih_y          // output gap (demand, FR-BDF: 0.38)
    a_ih_i          // interest rate gap (mortgage, FR-BDF: -0.89)
    a_ih_pi         // inflation gap (FR-BDF: 0.49)
    a_ih_u          // unemployment gap (FR-BDF: implicit via demand channel)

    // COVID dummy coefficients (one pair per PAC equation)
    b_covid_crash_pQ    b_covid_bounce_pQ       // VA price
    b_covid_crash_c     b_covid_bounce_c        // consumption
    b_covid_crash_ib    b_covid_bounce_ib       // business investment
    b_covid_crash_ih    b_covid_bounce_ih       // household investment
    b_covid_crash_n     b_covid_bounce_n        // employment
;

// -----------------------------------------------------------------------
// Parameter values
// -----------------------------------------------------------------------

// E-SAT (Bayesian posterior modes — Australian data 1993Q2-2023Q3)
delta           = 0.1989;       // foreign spillover (calibrated, small open economy)
lambda_q        = 0.6959;       // IS persistence (AU posterior, FR-BDF: 0.877)
sigma_q         = 0.0648;       // real rate sensitivity (AU posterior, FR-BDF: 0.072)
lambda_i        = 0.9576;       // interest rate smoothing (AU posterior, FR-BDF: 0.891)
alpha_i         = 0.3001;       // Taylor inflation response (AU posterior, FR-BDF: 0.390)
beta_i          = 0.0837;       // Taylor output response (AU posterior, FR-BDF: 0.156)
lambda_pi       = 0.2902;       // inflation persistence (AU posterior, FR-BDF: 0.465)
kappa_pi        = 0.0374;       // Phillips slope (AU posterior, FR-BDF: 0.080)
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

// VA price PAC parameters (Phase G MCMC, 2026-05-10; LMD = -931.33 Laplace / -930.999 MHM)
b0_pQ = 0.0306;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0063, 0.0529]
b1_pQ = 0.2907;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1277, 0.4607]
b2_pQ = -0.0001;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.0786, 0.0858]
omega_pQ        = 0.46;     // nonstationary share
rho_pQ_star     = 0.95;     // target persistence
// === CES production-function parameters (FR-BDF 2026 method, Dubois et al. WP #1044 §3.1.2) ===
// FR-BDF Section 3.1 specification with AU-data-determined calibration:
//   σ = 0.5366 (FR-BDF 2026 method: labor FOC eq 3 with two-break trend Φ̂;
//               Bayesian posterior, prior N(0.50, 0.20²), AU FD-spec data
//               weight 64%; FR-BDF 2026 reports σ = 0.4951 for France)
//   α = 0.450  (AU capital-income share, ABS 5204 Tab 48 compensation/GVA)
//   γ = 0.046  (analytical from 2019 Q_market/K_total mean; level scale
//               is units-driven, AU chain-volume convention vs INSEE's;
//               absent from the linearised model code)
//   μ = 1.200  (AU aggregate markup, RBA RDP 2018-09 mid-range)
//
// Implements the three FR-BDF 2026 innovations (see data/estimate_ces_2026.m):
//   1. γ analytical from base-year Q/K (replaces 40k-point grid)
//   2. σ from labor FOC (replaces investment FOC, which failed on AU and FR data)
//   3. Two-break trend efficiency at 2002Q2 and 2008Q3 (replaces single-break)
//
// Linearised pass-through coefficients (γ_ulc, γ_uck) from the CES factor-
// price frontier (FR-BDF 2026 eq 4):
//   ∂log P_Q / ∂log W̃ ≈ (1-α) · σ      (labor cost channel)
//   ∂log P_Q / ∂log r̃_K ≈ α · σ         (capital cost channel)
// AU values: γ_ulc = (1-0.45) · 0.5366 = 0.295, γ_uck = 0.45 · 0.5366 = 0.241
gamma_ulc       = 0.2951;   // ULC pass-through (CES log-linear: (1-α)·σ)
gamma_uck       = 0.2415;   // user cost pass-through (CES log-linear: α·σ)

// --- CES production function (FR-BDF 2026 calibration, AU data) ---
alpha_k         = 0.45;     // CES capital-share parameter α (FR-BDF 2026 AU calibration; was 0.35)
rho_tfp         = 0.95;     // smoothing speed (FR-BDF wp736 eq. 127; was 0.99 amplifying eps 100x)

// --- Commodity price channel (Stage 11b) ---
rho_pcom        = 0.42;     // AU est (s.e.0.08). Was 0.85. IMF commodity index much less persistent
b4_x            = 0.15;     // commodity price -> export volumes
alpha_pcom      = 0.10;     // commodity price -> export deflator pass-through

// Wage Phillips curve parameters (calibrated from Section 4.5.1 / Table 4.5.1)
// Australia: moderate wage persistence, significant gap sensitivity
// Forward expectations proxied by pibar_au (inflation anchor)
lambda_w        = 0.2899;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0342, 0.1573]
kappa_w         = 0.32;     // Phase R refit interim (audit #22): FR-BDF wp736
                            // |β_4| = 0.32 (Table 4.5.3). MCMC re-run required
                            // post-refit to produce AU posterior under the new
                            // (-kappa_w·pv_u_gap) sign convention. Pre-refit
                            // posterior was 0.0966 with HPD [-0.028, 0.128]
                            // under the wrong-signed equation.
gamma_w         = 0.1356;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.9054, 0.9958]
okun_coeff      = -0.13;    // AU OLS estimate (s.e.0.02). FR-BDF: -0.246, old cal: -0.33
rho_u_gap       = 0.946;    // AU OLS estimate (s.e.0.01). FR-BDF: 0.946, EXACT MATCH
beta_w          = 0.98;     // discount for expected unemployment gaps (paper Section 4.5.1)
// growth neutrality coeff = 1 - 0.55 - 0.15 = 0.30 on pibar_au

// Employment PAC parameters (calibrated from Table 4.5.3, 4th-order adjustment costs)
// Australia: labor market is relatively flexible vs France
b0_n = 0.0569;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0156, 0.1065]
b1_n = 0.3211;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1504, 0.4481]
b2_n = -0.1869;   // 2nd lag (OLS, not in Bayesian estimated_params)
b3_n = -0.0763;   // 3rd lag (OLS, not in Bayesian estimated_params)
b4_n = -0.0852;   // 4th lag (OLS, not in Bayesian estimated_params)
omega_n         = 0.30;     // expectations/forward component
b5_n = 0.0072;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.0836, 0.0797]
rho_n_star      = 0.95;     // target persistence
// growth neutrality coeff = 1 - 0.30 - 0.10 - 0.05 - 0.02 - 0.30 = 0.23

// Household consumption PAC parameters (calibrated from Section 4.6.1 / Table 4.6.1)
// Australia: moderate consumption smoothing, significant HtM share (~30%)
// 1st-order adjustment costs (simplest PAC form)
b0_c = 0.0601;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0294, 0.0961]
b1_c = 0.0354;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0065, 0.0754]
omega_c         = 0.369;    // expectations/forward component (posterior mean, legacy)
b2_c = -0.3307;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.5889, -0.0571]
b3_c = 0.0199;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.0639, 0.0953]
b_di_c          = -0.701;   // Phase C Bayesian regularised (IV with monetary-surprise instrument failed identification due to RBA endogeneity); posterior dominated by prior N(-0.71, 0.30^2)
rho_c_star      = 0.95;     // target persistence
kappa_inc       = 0.050;    // permanent income sensitivity (posterior mean)
beta_c          = 0.95;     // permanent income discount (paper Section 4.6.1, ~25% annual)
alpha_c_r       = -0.95;    // real lending rate -> consumption (paper Table 4.6.14, alpha_1=-0.95)
// growth neutrality coeff = 1 - 0.35 - 0.35 = 0.30

// Business investment PAC parameters (calibrated from Section 4.6.2 / Table 4.6.2)
// Australia: investment more volatile than consumption, strong accelerator
// 2nd-order adjustment costs
b0_ib = 0.0188;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0047, 0.0323]
b1_ib = 0.0801;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0196, 0.1503]
b2_ib = -0.0445;  // 2nd lag (OLS, not in Bayesian estimated_params)
omega_ib        = 0.35;     // expectations/forward component
b3_ib = 0.3094;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1825, 0.4828]
b4_ib           = -0.03;    // real interest rate -> investment (user cost channel)
rho_ib_star     = 0.95;     // target persistence
kappa_wacc      = 0.038;    // WACC gap -> investment target (posterior mean, legacy)
delta_k         = 0.0134;   // quarterly capital depreciation (Phase G ABS 5204: 5.4% annual; was 0.025 from FR-BDF)
// growth neutrality coeff = 1 - 0.25 - 0.10 - 0.35 = 0.30

// Household investment PAC parameters (calibrated from Section 4.6.3 / Table 4.6.3)
// Australia: housing highly interest-rate sensitive (variable-rate mortgages)
// 2nd-order adjustment costs
b0_ih = 0.0289;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0092, 0.0525]
b1_ih = 0.1152;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0243, 0.1744]
b2_ih = -0.0368;  // 2nd lag (OLS, not in Bayesian estimated_params)
omega_ih        = 0.30;     // expectations/forward component
b3_ih = 0.2262;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0655, 0.3848]
b4_ih           = 0;        // DROPPED: rate channel already in pv_ih_aux (a_ih_i=-0.15) + pac_expectation (F=0.001, not significant)
b_ph_ih         =  0.0099;  // Phase C, spliced housing-price series (1959Q3+ via house_price_history_long backcast onto ABS 6416 RPPI at 2003Q3): IV (lag-2 ph_gap; F=432.1) on T=115 obs. Sign now matches FR-BDF +0.32 (was wrong-signed on the 2003+ ABS RPPI alone), but magnitude is much smaller — the AU housing-price-gap channel is close to zero in the longer sample. Direct rate channel still enters via pv_ih_aux a_ih_i and pac_expectation kappa_mort.
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
rho_s           = 0.775;    // AU est (s.e.0.06). Was 0.95. AUD less persistent PPP deviations
alpha_s         = 0.15;     // interest rate differential -> appreciation (negative sign in eq)
beta_uip        = 0.92;     // UIP forward-NPV discount (Hybrid: jump on impact)

// Export parameters (calibrated from Section 4.7 / Table 4.7.1)
// Australia: commodity exports sensitive to world demand, moderate price elasticity
b0_x            = 0.05;     // error correction (moderate speed)
b1_x            = 0.30;     // Phase D v2 (2026-05-11, ABS 5206 SA volumes T=126 + COVID dummies): OLS gave -0.194 (wrong-signed, t=-2.18) — the 0.807 from Phase D v1 was a Trend-smoothing artifact. Kept FR-BDF 0.30. Asian-PMI / China-GDP proxies would help.
b2_x            = 0.25;     // Phase D v2 (ABS 5206 SA T=126 + COVID dummies): OLS = -0.008 (t=-0.07, indistinguishable from zero). Confirms US output gap is the wrong demand proxy — AU exports respond to China/Asia commodity demand. Kept FR-BDF 0.25 pending Asian-PMI series (Phase K).
b3_x            = 0.10;     // depreciation -> more exports (Marshall-Lerner)

// Import parameters (calibrated from Section 4.7 / Table 4.7.2)
// Australia: imports track domestic demand closely
b0_m            = 0.06;     // error correction
b1_m            = 0.2316;   // Phase D v3 (2026-05-11, ABS 5206 SA + IAD demand index + COVID dummies): OLS = +0.232 (s.e. 0.086, t=2.71) — slightly lower than v2 (0.255) when controlling for proper IAD-weighted demand. Still correctly signed and statistically significant.
b2_m            = 0.3591;   // Phase D v3 (2026-05-11, ABS 5206 SA + IAD demand index): OLS = +0.359 (s.e. 0.101, t=3.56) — Phase K residual RESOLVED. The IAD = w_iad_c·dln_c + w_iad_ib·dln_ib + w_iad_ih·dln_ih + w_iad_g·dln_g + w_iad_x·dln_x correctly captures the demand mix weighted by import content (calibrated weights from paper Table 4.8.3). Was wrong-signed (-0.317, t=-1.01) under yhat_au alone in v2.
b3_m            = -0.08;    // depreciation -> fewer imports (negative: price effect)

// Long-run trade elasticities (FR-BDF Section 4.7 / Table 4.7.1-2 proper ECM)
// AU empirical estimates: imports income-elastic (rising openness 1960-now),
// exports world-demand-elastic; both have real-exchange-rate response.
beta_m          = 1.50;     // LR income elasticity of imports (AU 1.3-1.7 range)
gamma_m         = -0.40;    // LR RER elasticity (depreciation -> import volumes fall)
beta_x          = 1.20;     // LR foreign-income elasticity of exports
gamma_x         =  0.40;    // LR RER elasticity (depreciation -> export volumes rise)

// Demand deflator parameters (calibrated from Section 4.7)
// ECM structure: pi_j = rho * pi_j(-1) + alpha * piQ + (1-rho-alpha) * pibar_au
// All satisfy growth neutrality: at SS, pi_j = piQ = pibar_au = pi_ss_au

// Consumption deflator: close to CPI, tracks VA price with full pass-through
rho_pc          = 0.67;     // AU est 0.674 (s.e.0.056), ABS 5206 IPD, T=127
alpha_pc        = 0.17;     // AU est 0.168 (s.e.0.035), weaker than FR-BDF 0.71
// neutrality: (1-0.67-0.17) = 0.16 on pibar_au

// Business investment deflator: tracks VA price, less persistent
rho_pib         = 0.70;     // AU est 0.699 (s.e.0.060), ABS 5206 IPD, T=127
alpha_pib       = 0.19;     // AU est 0.193 (s.e.0.053)
// neutrality: (1-0.70-0.19) = 0.11 on pibar_au

// Household investment deflator: construction costs, high persistence
rho_pih         = 0.49;     // AU est 0.491 (s.e.0.072), ABS 5206 IPD, T=127
alpha_pih       = 0.40;     // AU est 0.395 (s.e.0.082), stronger than FR-BDF 0.25
// neutrality: (1-0.49-0.40) = 0.11 on pibar_au

// Export deflator: influenced by world prices via exchange rate
rho_px          = 0.21;     // AU est 0.214 (s.e.0.069), ABS 5206 IPD, T=127
alpha_px        = 0.20;     // kept: AU est 2.23 implausible (multicollinearity)
beta_px         = -0.05;    // depreciation -> higher export prices in domestic currency
// neutrality: (1-0.21-0.20) = 0.59 on pibar_au (+ beta_px*0 at SS)

// Import deflator: heavily influenced by exchange rate
rho_pm          = 0.28;     // AU est 0.276 (s.e.0.085), ABS 5206 IPD, T=127
alpha_pm        = 0.38;     // AU est 0.384 (s.e.0.199), stronger than FR-BDF 0.15
beta_pm         = 0.09;     // AU est (s.e.0.03). Was 0.08. REER pass-through confirmed
// neutrality: (1-0.28-0.38) = 0.34 on pibar_au (+ beta_pm*0 at SS)

// Government parameters
// Spending follows simple fiscal rule: countercyclical stabilizer
rho_g           = 0.85;     // government spending persistent (budget inertia)
phi_g           = -0.10;    // countercyclical: positive gap -> less spending growth
rho_pg          = 0.13;     // AU est (s.e.0.05). Was 0.50. Less persistent than assumed
alpha_pg        = 0.37;     // AU est (s.e.0.02). Was 0.30. Slightly stronger wage pass-through
// neutrality: (1-0.13-0.37) = 0.50 on pibar_au

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
sigma_ces       = 0.5366;   // CES elasticity (FR-BDF 2026 method, 2026-05-14 refresh: labor FOC eq 3 with two-break trend Φ̂_t; Bayesian posterior prior N(0.50, 0.20²); FR-BDF 2026 reports σ=0.4951 for France; was 0.3374 under 2019-method investment FOC)

// Import price pass-through to domestic deflators (Section 4.7, IAD weights)
// beta_j_m = import content share * partial pass-through coefficient
beta_pc_m       = 0.10;     // consumption: ~20% import content, ~50% pass-through
beta_pib_m      = 0.12;     // business investment: ~25% import content
beta_pih_m      = 0.08;     // housing: ~15% import content (domestic materials)
gamma_oil       = 0.03;     // energy/commodity -> CPI (smaller for AU than FR)
beta_pm_com     = 0.42;     // AU est (s.e.0.02). Was 0.05. Strong commodity pass-through to imports (AU-specific)

// Import-adjusted demand weights (import content of each expenditure component)
// From ABS input-output tables, approximate for AU economy
w_iad_c         = 0.12;     // consumption has moderate import content
w_iad_ib        = 0.25;     // business investment: capital goods highly imported
w_iad_ih        = 0.15;     // housing: some imported materials
w_iad_g         = 0.08;     // government: mostly domestic services
w_iad_x         = 0.30;     // exports: high re-export content (commodity processing)

// Household bank lending rate (Section 4.8.3, eq. 68, Table 4.6.17)
// Paper: iLH adjusts toward i_10y with spread, persistence rho = 0.88
rho_lh          = 0.97;     // AU est 0.972 (s.e.0.020), RBA F5, T=127. Very persistent
spread_lh       = 0.40;     // ~1.6% annual AU mortgage spread over 10Y bonds
// SS: i_lh = i_ss + tp_ss + spread_lh = 1.0491 + 0.30 + 0.40 = 1.7491 (~7.0% annual)

// Housing prices (Section 4.6.3, eq. 69, Table 4.6.18)
// AU estimate from ABS 6416 RPPI (2003-2021, T=72, R2=0.40)
rho_ph          = 0.60;     // AU est 0.605 (s.e.0.096). Less persistent than FR-BDF 0.90
alpha_ph_y      = 0.15;     // kept: AU est 0.088 insignificant (t=0.53)
alpha_ph_r      = -0.70;    // AU est -0.700 (s.e.0.279). Stronger rate channel (t=2.51)
kappa_ph        = 0.03;     // housing price gap -> household investment (Tobin's Q)

// Investment target output proportionality (Section 4.6.2, eq. 63)
// Paper: log I* = a0 + q - sigma*log(rKB) + log(I*/K*)
// The 'q' term means desired investment is proportional to output level.
kappa_ib_y      = 0.06;     // output gap -> business investment target

// PAC discount factor (paper Section 4.1: beta = 0.98 for most blocks)
beta_pac        = 0.98;

// Dynamic E-SAT auxiliary parameters — aligned with FR-BDF auxiliary equations.
// Coefficients from FR-BDF Tables 4.4.4, 4.5.7, 4.6.3, 4.6.11-12, 4.6.16.
// Where FR-BDF coefficients are insignificant (large s.e.), we use the point estimate
// but flag for future re-estimation with Australian data.

// === E-SAT auxiliary equations: AU Bayesian posteriors (Phase B, 2026-05-09) ===
// Re-estimated equation-by-equation on observable AU target proxies (HP-detrended log levels)
// with Normal priors (sd = max(|prior|/2, 0.03)) centred on FR-BDF or prior AU smoother values.
// COVID dummies (2020Q2/Q3) absorb pandemic outliers. See estimate_auxiliary_bayesian.m.

// VA price auxiliary (FR-BDF Table 4.4.4)
rho_pQ_aux      =  0.334;   // Bayesian posterior, 90% CI [0.191, 0.476]; OLS=0.135, FR-BDF=0.70
a_pQ_y          =  0.043;   // Bayesian posterior, 90% CI [-0.000, 0.087]
a_pQ_i          = -0.021;   // Bayesian posterior, 90% CI [-0.070, 0.029] (CI crosses 0)
a_pQ_pi         =  0.007;   // Bayesian posterior, 90% CI [-0.042, 0.057] (CI crosses 0)
a_pQ_u          = -0.021;   // Bayesian posterior, 90% CI [-0.069, 0.027] (CI crosses 0)

// Employment auxiliary (FR-BDF Table 4.5.7, eq 57)
rho_n_aux       =  0.743;   // Bayesian posterior, 90% CI [0.669, 0.817]; OLS=0.716, prior AU=0.56
a_n_y           =  0.094;   // Bayesian posterior, 90% CI [0.036, 0.152]; significant
a_n_i           = -0.031;   // Bayesian posterior, 90% CI [-0.080, 0.018] (CI crosses 0)
a_n_pi          =  0.057;   // Bayesian posterior, 90% CI [0.013, 0.100]; significant
a_n_u           = -0.029;   // Bayesian posterior, 90% CI [-0.076, 0.019]

// Household income-output ratio auxiliary (FR-BDF Table 4.6.3) — kept at AU smoother
// estimate; YH/Y series unavailable in extended_dataset.csv (Phase B did not re-estimate)
rho_yh_aux      =  0.93;    // AU smoother (s.e.0.002). FR-BDF: 0.92
a_yh_y          =  0.12;    // AU smoother (s.e.0.006). FR-BDF: 0.08
a_yh_u          = -0.07;    // AU smoother (s.e.0.003). FR-BDF: -0.10

// Consumption PV² auxiliary (FR-BDF Table 4.6.4)
rho_c_aux       =  0.581;   // Bayesian posterior, 90% CI [0.484, 0.679]; OLS=0.515
a_c_y           =  0.058;   // Bayesian posterior, 90% CI [0.010, 0.107]; significant
a_c_i           = -0.043;   // Bayesian posterior, 90% CI [-0.092, 0.006] (OLS=-1.865; shrunk)
a_c_pi          =  0.010;   // Bayesian posterior, 90% CI [-0.038, 0.059] (CI crosses 0)
a_c_u           = -0.036;   // Bayesian posterior, 90% CI [-0.085, 0.013] (CI crosses 0)
a_c_yh          =  0.10;    // AU smoother (kept; YH/Y data needed to re-estimate)

// Business investment auxiliary (FR-BDF Table 4.6.11)
rho_ib_aux      =  0.694;   // Bayesian posterior, 90% CI [0.598, 0.791]; OLS=0.721
a_ib_y          =  0.050;   // Bayesian posterior, 90% CI [0.001, 0.099]; marginally significant
a_ib_pi         =  0.023;   // Bayesian posterior, 90% CI [-0.027, 0.072] (OLS=-1.037; shrunk)
a_ib_u          =  0.004;   // Bayesian posterior, 90% CI [-0.046, 0.053] (CI crosses 0)

// Business investment USER COST gap auxiliary (FR-BDF Table 4.6.12: r̂_KB)
rho_rKB_aux     =  0.162;   // Bayesian posterior, 90% CI [0.036, 0.287]; OLS=0.113
a_rKB_i         =  0.242;   // Bayesian posterior, 90% CI [0.057, 0.428]; significant

// Housing investment auxiliary (FR-BDF Table 4.6.16)
rho_ih_aux      =  0.699;   // Bayesian posterior, 90% CI [0.600, 0.797]; OLS=0.723
a_ih_y          =  0.097;   // Bayesian posterior, 90% CI [0.016, 0.178]; significant
a_ih_i          = -0.152;   // Bayesian posterior, 90% CI [-0.276, -0.029]; significant negative
a_ih_pi         =  0.042;   // Bayesian posterior, 90% CI [-0.007, 0.092] (CI brushes 0)
a_ih_u          =  0.004;   // Bayesian posterior, 90% CI [-0.045, 0.053] (CI crosses 0)

// COVID dummy coefficients — initial = 0 (estimated by pac.estimate; inert for stoch_simul)
b_covid_crash_pQ   = 0;    b_covid_bounce_pQ  = 0;
b_covid_crash_c    = 0;    b_covid_bounce_c   = 0;
b_covid_crash_ib   = 0;    b_covid_bounce_ib  = 0;
b_covid_crash_ih   = 0;    b_covid_bounce_ih  = 0;
b_covid_crash_n    = 0;    b_covid_bounce_n   = 0;

// === Sector financial account parameters (Section 4.8.5) ===
// SS net asset ratios (as share of *quarterly* nominal GDP)
// Paper uses annualized GDP; multiply by 4 for quarterly convention
w_F_ss          = -0.70 * 4;    // firms: net debtor (~280% quarterly GDP)
w_G_ss          = -0.40 * 4;    // government: net debt (~160% quarterly GDP, ~40% annual)
w_N_ss          = 0.02 * 4;     // NPISH: small net creditor
// w_H_ss is endogenous: w_H = -(w_F + w_G + w_N) at SS (closed economy approx)

// SS transfer rates (as share of quarterly nominal GDP)
tau_F_ss        = 0.026;        // firms dividend payout rate
tau_G_ss        = 0.16;         // government social transfers (calibrated per paper eq 125)
tau_N_ss        = 0.00026;      // NPISH transfers (tiny)

// Stabilization rule parameters (paper eqs 123-125)
rho_stab_1      = 0.10;         // transfer adjustment speed
rho_stab_2      = 0.25;         // debt-stabilizing reaction coefficient (stronger for BK)

// Asset return parameters (paper eq 126, Table 4.8.8)
rho_i_asset     = 0.983;        // half-life ~40 quarters for return convergence
i_F_prem        = -0.0037;      // firms return premium over i_10y (negative: debtor)
i_H_prem        = -0.0007;      // households return premium
i_N_prem        = -0.001;       // NPISH return premium
// Government: i_G converges to i_10y (zero premium, paper Table 4.8.8)

// Firms revaluation (paper eq 122)
gamma_reval     = -0.018;       // quarterly revaluation as share of nominal GDP

// Nominal growth rate at SS (for debt-stabilizing computation)
g_nom           = 0.002625;     // quarterly (~1.05% annual real + 2.5% inflation / 4)

// -----------------------------------------------------------------------
// PAC infrastructure: auxiliary VAR + PAC model declarations
// Must appear BEFORE the model block.
// -----------------------------------------------------------------------

// -----------------------------------------------------------------------
// ENRICHED E-SAT var_model (FR-BDF Section 3.1.1)
// -----------------------------------------------------------------------
// Single VAR with E-SAT core dynamics + 5 auxiliary gap equations.
// The companion matrix H is 8x8, capturing joint E-SAT + auxiliary dynamics.
// h-vectors (k_0, k_1) from PAC eqs 14-17 depend on ALL state variables.
// This is the correct FR-BDF architecture: auxiliary equations are INSIDE
// the expectation satellite model, not separate additive terms.

var_model(model_name = esat_enriched,
    eqtags = ['var_y', 'var_i', 'var_pi',
              'var_u', 'var_yus',
              'var_pQ', 'var_n', 'var_yh', 'var_c', 'var_ib', 'var_rKB', 'var_ih']);

// All 5 PAC models share this enriched var_model.
// Each finds its own target variable (piQ_hat, n_hat, etc.) in the VAR.
pac_model(auxiliary_model_name = esat_enriched, discount = beta_pac, model_name = pac_pQ);
pac_model(auxiliary_model_name = esat_enriched, discount = beta_pac, model_name = pac_c);
pac_model(auxiliary_model_name = esat_enriched, discount = beta_pac, model_name = pac_ib);
pac_model(auxiliary_model_name = esat_enriched, discount = beta_pac, model_name = pac_ih);
pac_model(auxiliary_model_name = esat_enriched, discount = beta_pac, model_name = pac_n);

// -----------------------------------------------------------------------
// Model equations
// -----------------------------------------------------------------------


// Observable variables for Bayesian estimation (auto-generated)
// 9 observables matching estimation_data.mat columns
varobs yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;

model;

    // === E-SAT CORE (identical to au_esat.mod) ===

    [name = 'def_i_gap']
    i_gap = i_au - ibar;

    [name = 'def_di_gap']
    di_gap = i_gap - i_gap(-1);

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

    // Phase S (2026-05-16): FR-BDF wp736 §3.1.1 / §5.2.6 cost-push replication.
    // The reduced-form quasi-VAR was missing the structural deflator channels
    // (piQ, pi_m, dln_pcom) that pi_c already had via eq_pi_c. As a result
    // a positive eps_pQ raised piQ but not pi_au, so the Taylor rule didn't
    // tighten and the cost-push IRF on ln_Q came out wrong-signed (+0.15% vs
    // FR-BDF's -0.45%). Adding the structural channels to eq_au_phillips makes
    // pi_au structurally a function of VA price + import price + commodity,
    // mirroring the role of pi_C in FR-BDF's deflator block (eqs 79-80) while
    // preserving the existing Phillips slope (kappa_pi) and own persistence
    // (lambda_pi) as residual reduced-form components.
    [name = 'eq_au_phillips']
    pi_au_gap = lambda_pi * pi_au_gap(-1)
                + kappa_pi * yhat_au(-1)
                + alpha_pc * (piQ - pibar_au)
                + beta_pc_m * (pi_m - pibar_au)
                + gamma_oil * dln_pcom
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
    // ENRICHED E-SAT var_model EQUATIONS (FR-BDF Section 3.1.1)
    // =================================================================
    // Pure VAR(1) form: x = f(x(-1)) + eps. No contemporaneous terms.
    // These equations form the auxiliary model for PAC expectations.
    // The companion matrix H is 10x10, jointly capturing E-SAT + auxiliary dynamics.
    // h-vectors from pac_expectation() depend on ALL state variables.

    // --- E-SAT core: simplified IS curve (lagged terms only) ---
    [name = 'var_y']
    y_gap_var = lambda_q * y_gap_var(-1) - sigma_q * (i_gap_var(-1) - pi_gap_var(-1)) + eps_var_y;

    // --- E-SAT core: Taylor rule (lagged feedback) ---
    [name = 'var_i']
    i_gap_var = lambda_i * i_gap_var(-1) + (1 - lambda_i) * (alpha_i * pi_gap_var(-1) + beta_i * y_gap_var(-1)) + eps_var_i;

    // --- E-SAT core: Phillips curve ---
    [name = 'var_pi']
    pi_gap_var = lambda_pi * pi_gap_var(-1) + kappa_pi * y_gap_var(-1) + eps_var_pi;

    // --- E-SAT additional: unemployment gap (Okun's law, FR-BDF Table 4.5.2) ---
    [name = 'var_u']
    u_gap_var = rho_u_gap * u_gap_var(-1) + okun_coeff * y_gap_var(-1) + eps_var_u;

    // --- E-SAT additional: foreign output gap (US, simplified AR(1)) ---
    [name = 'var_yus']
    yhat_us_var = lambda_q_us * yhat_us_var(-1) + eps_var_yus;

    // --- Auxiliary: VA price target gap (FR-BDF Table 4.4.4, eqs 45-47) ---
    [name = 'var_pQ']
    piQ_hat = rho_pQ_aux * piQ_hat(-1) + a_pQ_y * y_gap_var(-1) + a_pQ_i * i_gap_var(-1) + a_pQ_pi * pi_gap_var(-1) + a_pQ_u * u_gap_var(-1) + eps_var_pQ;

    // --- Auxiliary: employment target gap (FR-BDF Table 4.5.7, eq 57) ---
    [name = 'var_n']
    n_hat = rho_n_aux * n_hat(-1) + a_n_y * y_gap_var(-1) + a_n_i * i_gap_var(-1) + a_n_pi * pi_gap_var(-1) + a_n_u * u_gap_var(-1) + eps_var_n;

    // --- Auxiliary: household income-output ratio gap (FR-BDF Table 4.6.3: yH-ȳ) ---
    // This is the FIRST layer of the nested PV: income ratio tracks output and unemployment
    [name = 'var_yh']
    yh_ratio_hat = rho_yh_aux * yh_ratio_hat(-1) + a_yh_y * y_gap_var(-1) + a_yh_u * u_gap_var(-1) + eps_var_yh;

    // --- Auxiliary: consumption PV² gap (FR-BDF Table 4.6.4: PV of yH-ȳ) ---
    // This is the SECOND layer: PV of changes in the income-output ratio.
    // c_hat depends on yh_ratio_hat(-1), creating the nested PV structure.
    [name = 'var_c']
    c_hat = rho_c_aux * c_hat(-1) + a_c_y * y_gap_var(-1) + a_c_i * i_gap_var(-1) + a_c_pi * pi_gap_var(-1) + a_c_u * u_gap_var(-1) + a_c_yh * yh_ratio_hat(-1) + eps_var_c;

    // --- Auxiliary: business inv output gap (FR-BDF Table 4.6.11: q̂) ---
    // Output channel only; interest rate channel moves to rKB_hat (Table 4.6.12)
    [name = 'var_ib']
    ib_hat = rho_ib_aux * ib_hat(-1) + a_ib_y * y_gap_var(-1) + a_ib_pi * pi_gap_var(-1) + a_ib_u * u_gap_var(-1) + eps_var_ib;

    // --- Auxiliary: business inv user cost gap (FR-BDF Table 4.6.12: r̂_KB) ---
    // Separate user cost expectations: interest rate → cost of capital → investment
    [name = 'var_rKB']
    rKB_hat = rho_rKB_aux * rKB_hat(-1) + a_rKB_i * i_gap_var(-1) + eps_var_rKB;

    // --- Auxiliary: housing inv target gap (FR-BDF Table 4.6.16) ---
    [name = 'var_ih']
    ih_hat = rho_ih_aux * ih_hat(-1) + a_ih_y * y_gap_var(-1) + a_ih_i * i_gap_var(-1) + a_ih_pi * pi_gap_var(-1) + a_ih_u * u_gap_var(-1) + eps_var_ih;

    // =================================================================
    // LOG-LEVEL ACCUMULATION FOR DYNARE PAC (diff() form)
    // =================================================================
    // Dynare PAC expects diff(z) on LHS. We accumulate growth rates into levels.
    // At SS: all levels = 0 (gap model, everything demeaned).

    [name = 'eq_piQ_from_level']
    piQ = (pQ_level - pQ_level(-1)) + pi_ss_au;

    [name = 'eq_pQ_star_level']
    pQ_star_level = pQ_star_level(-1) + (piQ_star - pi_ss_au);

    [name = 'eq_dln_c_from_level']
    dln_c = ln_c_level - ln_c_level(-1);

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

    // === TREND LEVEL ACCUMULATORS (FR-BDF eq 43 — recover levels from gaps) ===
    // These are pure accounting identities that accumulate trend growth rates.
    // They do NOT affect model dynamics — just enable level recovery.
    // At SS: all = 0. After shocks, they track cumulative deviations from SS path.
    // Usage: ln_Q gives actual output index, ln_QN gives potential output index.
    //        The difference ln_Q - ln_QN = yhat_au (output gap) by construction.

    // Output: potential and actual
    [name = 'eq_ln_QN']
    ln_QN = ln_QN(-1) + dln_y_star;

    [name = 'eq_ln_Q']
    ln_Q = ln_QN + yhat_au;

    // Consumption: trend and actual
    [name = 'eq_ln_C_star']
    ln_C_star = ln_C_star(-1) + dln_c_star_bar;

    [name = 'eq_ln_C']
    ln_C = ln_C_star + ln_c_level;

    // Business investment: trend and actual
    [name = 'eq_ln_IB_star']
    ln_IB_star = ln_IB_star(-1) + dln_ib_star_bar;

    [name = 'eq_ln_IB']
    ln_IB = ln_IB_star + ln_ib_level;

    // Household investment: trend and actual
    [name = 'eq_ln_IH_star']
    ln_IH_star = ln_IH_star(-1) + dln_ih_star_bar;

    [name = 'eq_ln_IH']
    ln_IH = ln_IH_star + ln_ih_level;

    // Employment: trend and actual
    [name = 'eq_ln_N_star']
    ln_N_star = ln_N_star(-1) + dln_n_star_bar;

    [name = 'eq_ln_N']
    ln_N = ln_N_star + ln_n_level;

    // Capital stock
    [name = 'eq_ln_K']
    ln_K = ln_K(-1) + dln_k;

    // Price level: trend and actual
    [name = 'eq_ln_P_star']
    ln_P_star = ln_P_star(-1) + (pibar_au - pi_ss_au);

    [name = 'eq_ln_P']
    ln_P = ln_P_star + pQ_level;

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

    // === FR-BDF wp736 §4.3 / §5.2.7 TFP block (2026-05-15 refit) ===
    // eps_tfp_LR is a permanent +1% level shock to log trend efficiency.
    // See au_pac.mod for the full derivation.
    [name = 'eq_ln_tfp_LR']
    ln_tfp_LR = ln_tfp_LR(-1) + eps_tfp_LR;

    [name = 'eq_ln_tfp']
    ln_tfp    = rho_tfp * ln_tfp(-1) + (1 - rho_tfp) * ln_tfp_LR;

    [name = 'eq_dln_tfp']
    dln_tfp   = ln_tfp - ln_tfp(-1);

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

    // =================================================================
    // DYNAMIC E-SAT AUXILIARY EXPECTATIONS
    // Aligned with FR-BDF Tables 4.4.4, 4.5.7, 4.6.3, 4.6.11-12, 4.6.16
    // =================================================================
    // Each auxiliary is an AR(1) with multiple E-SAT state variable drivers,
    // matching the structure of FR-BDF's auxiliary regression equations.
    // Channels: output gap (ŷ), interest rate gap (i-ī), inflation gap (π-π̄),
    // unemployment gap (û). Absent in MCE (forward leads capture everything).

    // =================================================================
    // BACKWARD EXPECTATION CORRECTIONS (additive first-order wedge)
    // =================================================================
    // These AR(1) terms represent the DIFFERENCE between E-SAT simplified
    // forecasts and the full model RE solution. They create the backward/
    // forward wedge at first-order perturbation. The var_model h-vectors
    // provide the structural framework; these terms provide the quantitative
    // differentiation. Absent in MCE (forward leads already capture everything).

    [name = 'eq_pv_piQ_aux']
    pv_piQ_aux = rho_pQ_aux * pv_piQ_aux(-1) + a_pQ_y * yhat_au(-1) + a_pQ_i * i_gap(-1) + a_pQ_pi * pi_au_gap(-1) + a_pQ_u * u_gap(-1);
    [name = 'eq_pv_n_aux']
    pv_n_aux = rho_n_aux * pv_n_aux(-1) + a_n_y * yhat_au(-1) + a_n_i * i_gap(-1) + a_n_pi * pi_au_gap(-1) + a_n_u * u_gap(-1);
    [name = 'eq_pv_c_aux']
    pv_c_aux = rho_c_aux * pv_c_aux(-1) + a_c_y * yhat_au(-1) + a_c_i * i_gap(-1) + a_c_pi * pi_au_gap(-1) + a_c_u * u_gap(-1);
    [name = 'eq_pv_ib_aux']
    pv_ib_aux = rho_ib_aux * pv_ib_aux(-1) + a_ib_y * yhat_au(-1) + a_ib_pi * pi_au_gap(-1) + a_ib_u * u_gap(-1);
    [name = 'eq_pv_rKB_aux']
    pv_rKB_aux = rho_rKB_aux * pv_rKB_aux(-1) + a_rKB_i * i_gap(-1);
    [name = 'eq_pv_ih_aux']
    pv_ih_aux = rho_ih_aux * pv_ih_aux(-1) + a_ih_y * yhat_au(-1) + a_ih_i * i_gap(-1) + a_ih_pi * pi_au_gap(-1) + a_ih_u * u_gap(-1);

    // VA price PAC equation — h-vectors from enriched E-SAT var_model
    // PLUS backward expectation correction for first-order wedge.
    [name = 'eq_piQ_pac']
    diff(pQ_level) = b0_pQ * (piQ_hat(-1) - pQ_level(-1))
                     + b1_pQ * diff(pQ_level(-1))
                     + pac_expectation(pac_pQ)
                     + b2_pQ * yhat_au
                     + b_covid_crash_pQ * d_covid_crash + b_covid_bounce_pQ * d_covid_bounce
                     + pv_piQ_aux
                     + eps_pQ;

    // === UNEMPLOYMENT GAP (Okun's law, paper eq 53/Table 4.5.2) ===
    // u_gap = AR(1) with output gap driving force. Negative: higher output -> lower unemployment.
    // At SS: yhat_au = 0 => u_gap = 0.
    [name = 'eq_u_gap']
    u_gap = rho_u_gap * u_gap(-1) + okun_coeff * yhat_au;

    // Discounted PV of expected future unemployment gaps (paper eq 52, Section 4.5.1).
    // PV(û)_t = (1-beta_w)*û_t + beta_w*PV(û)_{t+1} (recursive, eq 137 in paper).
    // Under VAR-based expectations this collapses to a backward-looking policy function.
    // Here we use the recursive form which works for both VAR and MCE cases.
    // At SS: u_gap = 0 => pv_u_gap = 0.
    [name = 'eq_pv_u_gap']
    pv_u_gap = (1 - beta_w) * u_gap + beta_w * pv_u_gap(+1);

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
    // Phase R refit (audit #22 + #23, 2026-05-15):
    //   #22 — sign flip on unemployment-gap channel (was + kappa_w·pv_u_gap,
    //         which gave WRONG sign: high unemployment → wage inflation).
    //         Now: − kappa_w·pv_u_gap with kappa_w > 0 → high unemployment
    //         → wage deflation, matching FR-BDF eq 49 (-λ·(u-u_N)) and
    //         eq 52 (β_4 < 0 sign convention).
    //   #23 — indexation switched from pi_au (VA price) to pi_c (consumer
    //         price). Workers index to what they buy, not what firms charge
    //         per unit output. FR-BDF eq 52 uses π_C,t-1 explicitly.
    pi_w = lambda_w * pi_w(-1)
           + gamma_w * pi_c
           - kappa_w * pv_u_gap
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

    // Trend employment growth: derived from inverted production function.
    // Phase R refit (audit #17 + #21, 2026-05-15): aligned with FR-BDF wp736
    // eq 55 / eq 36 in growth form:
    //   n* = b0 + q - ē - h - σ·(w̃ - pQ - ē - h)
    //   Δn* = Δq - (1-σ)·Δē - σ·Δw̃ + σ·Δp_Q
    //
    // With Δē = dln_prod = dln_tfp/(1-α_k) and rw_gap = pi_w - piQ - dln_prod:
    //   dln_n_star_bar = (yhat_au - yhat_au(-1))    ← Δq channel (was MISSING, #17)
    //                  - dln_tfp / (1 - alpha_k)     ← sign FIXED + → − (#21)
    //                  - sigma_ces * rw_gap;          ← real wage gap (Stage 12, retained)
    //
    // This expands to: Δyhat_au - (1-σ)/(1-α_k)·dln_tfp - σ·pi_w + σ·piQ
    // matching FR-BDF eq 36.
    //
    // Pre-Phase-R bug: leading sign was +, Δq channel was absent. Net dln_tfp
    // coefficient was +(1+σ)/(1-α_k) ≈ +2.79 (vs FR-BDF -(1-σ)/(1-α_k) ≈ -0.84,
    // OPPOSITE sign and 3.3× too large). Audit §4.3 / §4.5 ✗ findings.
    //
    // At SS: yhat_au stationary => Δyhat_au = 0; dln_tfp = 0; rw_gap = 0
    //        => dln_n_star_bar = 0 (verified).
    [name = 'eq_dln_n_star_bar']
    dln_n_star_bar = (yhat_au - yhat_au(-1))
                   - dln_tfp / (1 - alpha_k)
                   - sigma_ces * rw_gap;

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
    diff(ln_n_level) = b0_n * (n_hat(-1) - ln_n_level(-1))
            + b1_n * diff(ln_n_level(-1))
            + b2_n * diff(ln_n_level(-2))
            + b3_n * diff(ln_n_level(-3))
            + b4_n * diff(ln_n_level(-4))
            + pac_expectation(pac_n)
            + b5_n * yhat_au
            + b_covid_crash_n * d_covid_crash + b_covid_bounce_n * d_covid_bounce
            + pv_n_aux
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

    // Permanent income: discounted PV of expected future output gaps (paper eq 60/136).
    // PV(yH)_t = (1-beta_c)*yhat_au_t + beta_c*PV(yH)_{t+1}
    // beta_c = 0.95 (high discount due to risk aversion + income uncertainty).
    // This heavy discounting is key to avoiding the forward guidance puzzle (paper Section 6.3).
    // At SS: yhat_au = 0 => pv_yh = 0.
    [name = 'eq_pv_yh']
    pv_yh = (1 - beta_c) * yhat_au + beta_c * pv_yh(+1);

    // Phase R refit (audit #26, 2026-05-15): forward NPV of real lending rate gap.
    // FR-BDF eq 61 includes α_1·(PV(r_LH) - PV(ī - π̄)) channel that captures
    // the forward-looking real-rate transmission to consumption (essential for
    // no-forward-guidance-puzzle property under MCE).
    //
    // Pre-Phase-R: eq_dln_c_pac had only b2_c·i_gap(-1) (lagged level) and
    //   b_di_c·di_gap (current change) — no forward-looking PV channel.
    // Post-Phase-R: + alpha_c_r · pv_r_lh_gap term added below.
    //
    // At SS: i_lh = i_ss + tp_ss + spread_lh, pi_c = pi_ss_au
    //        => bracket = 0 => pv_r_lh_gap = 0 (verified).
    [name = 'eq_pv_r_lh_gap']
    pv_r_lh_gap = (1 - beta_c) * (i_lh - pi_c - (i_ss + tp_ss + spread_lh - pi_ss_au))
                + beta_c * pv_r_lh_gap(+1);

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
    diff(ln_c_level) = b0_c * (c_hat(-1) - ln_c_level(-1))
            + b1_c * diff(ln_c_level(-1))
            + pac_expectation(pac_c)
            + alpha_c_r * pv_r_lh_gap                      // Phase R refit (audit #26): FR-BDF eq 61 PV(r_LH) channel
            + b2_c * i_gap(-1)
            + b_di_c * di_gap
            + b3_c * yhat_au
            + b_covid_crash_c * d_covid_crash + b_covid_bounce_c * d_covid_bounce
            + pv_c_aux
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
    // User cost: sigma_ces * pv_rKB_aux (FR-BDF eq 64: σ·PV(Δlog r̂_KB), structural)

    [name = 'eq_dln_ib_pac']
    diff(ln_ib_level) = b0_ib * (ib_hat(-1) - ln_ib_level(-1))
             + b1_ib * diff(ln_ib_level(-1))
             + b2_ib * diff(ln_ib_level(-2))
             + pac_expectation(pac_ib)
             + b3_ib * yhat_au
             + b_covid_crash_ib * d_covid_crash + b_covid_bounce_ib * d_covid_bounce
             - sigma_ces * pv_rKB_aux
             + pv_ib_aux
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
    // Rate channel enters via pac_expectation (kappa_mort*(i_lh-SS) in target)
    // and pv_ih_aux (a_ih_i=-0.15). Direct b4_ih*i_gap term was redundant
    // (F=0.001, delta SSR=0.005 on 118 obs — statistically insignificant).

    [name = 'eq_dln_ih_pac']
    diff(ln_ih_level) = b0_ih * (ih_hat(-1) - ln_ih_level(-1))
             + b1_ih * diff(ln_ih_level(-1))
             + b2_ih * diff(ln_ih_level(-2))
             + pac_expectation(pac_ih)
             + b3_ih * yhat_au
             + b_ph_ih * ph_gap(-1)
             + b_covid_crash_ih * d_covid_crash + b_covid_bounce_ih * d_covid_bounce
             + pv_ih_aux
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

    // Expected discounted sum of future short rates (forward-looking)
    [name = 'eq_pv_i']
    pv_i = (1 - kappa_10) * i_au + kappa_10 * pv_i(+1);

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
    // Forward-looking modified UIP (Phase Q, 2026-05-15).
    // At SS: pv_i_uip = 0, s_gap = 0 (PPP holds in long run).
    [name = 'eq_pv_i_uip']
    pv_i_uip = (i_au - ibar) + beta_uip * pv_i_uip(+1);

    [name = 'eq_s_gap']
    s_gap = rho_s * s_gap(-1)
            - alpha_s * pv_i_uip
            + alpha_s * (pi_au_gap - pi_us_gap)
            + eps_s;

    // =================================================================
    // TRADE BLOCK (Section 4.7)
    // =================================================================

    // Log-level accumulators (deviation form, all SS = 0).
    // ln_x_level, ln_m_level track actual log levels relative to SS trend.
    // ln_d_iad accumulates the import-weighted demand growth into a level.
    [name = 'eq_ln_x_level']
    ln_x_level = ln_x_level(-1) + dln_x;

    [name = 'eq_ln_m_level']
    ln_m_level = ln_m_level(-1) + dln_m;

    [name = 'eq_ln_d_iad']
    ln_d_iad = ln_d_iad(-1) + iad;

    // === EXPORTS ECM (FR-BDF eqs. 70-73, proper long-run + short-run) ===
    // Long run (eq 71): ln(X)_eq = β_x * ln(D_us) + γ_x * ln(RER)
    //   where ln(D_us) ≈ yhat_us (foreign output level deviation) and
    //   ln(RER) ≈ s_gap (real exchange rate deviation, + = depreciation).
    // Error-correction term x_gap = ln_x_eq - ln_x_level: positive when
    // exports below equilibrium, pulling growth up via b0_x.
    // Short-run dynamics retain b2_x, b3_x, b4_x as impact-response terms;
    // beta_x and gamma_x govern long-run equilibrium.
    //
    // At SS: yhat_us = 0, s_gap = 0, ln_x_level = 0  ⇒  ln_x_eq = 0, x_gap = 0.

    [name = 'eq_ln_x_eq']
    ln_x_eq = beta_x * yhat_us + gamma_x * s_gap;

    [name = 'eq_x_gap']
    x_gap = ln_x_eq - ln_x_level;

    [name = 'eq_dln_x']
    dln_x = b0_x * x_gap(-1)
            + b1_x * dln_x(-1)
            + b2_x * yhat_us
            + b3_x * s_gap
            + b4_x * dln_pcom
            + eps_x;

    // === IMPORTS ECM (FR-BDF eqs. 74-77, proper long-run + short-run) ===
    // Long run (eq 76): ln(M)_eq = β_m * ln(D) + γ_m * ln(RER)
    //   where ln(D) ≈ ln_d_iad (cumulated import-weighted demand) and
    //   ln(RER) ≈ s_gap. With β_m > 1 (AU openness rising), import target
    //   responds more than one-for-one to demand level, generating the
    //   secular rise in M/GDP that the previous degenerate m_gap couldn't.
    // Error-correction term m_gap = ln_m_eq - ln_m_level.
    // Short run keeps b2_m * iad (impact response) and b3_m * s_gap.
    //
    // At SS: ln_d_iad = 0, s_gap = 0, ln_m_level = 0  ⇒  ln_m_eq = 0, m_gap = 0.

    [name = 'eq_ln_m_eq']
    ln_m_eq = beta_m * ln_d_iad + gamma_m * s_gap;

    [name = 'eq_m_gap']
    m_gap = ln_m_eq - ln_m_level;

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

    // =================================================================
    // SECTOR FINANCIAL ACCOUNTS (Section 4.8.5, eqs 116-126)
    // =================================================================
    // All variables are ratios to nominal long-run GDP.
    // In the gap model, nominal GDP growth at SS = g_nom.

    // === Asset return processes (paper eq 126) ===
    // Each sector's effective return converges to i_10y + premium.
    // rho_i_asset = 0.983 (half-life ~40 quarters).
    [name = 'eq_i_F']
    i_F = i_F_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_F(-1);

    [name = 'eq_i_G']
    i_G = (1 - rho_i_asset) * i_10y + rho_i_asset * i_G(-1);

    [name = 'eq_i_H']
    i_H = i_H_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_H(-1);

    [name = 'eq_i_N']
    i_N = i_N_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_N(-1);

    // === Net property income (paper eq 116) ===
    // YF_j = i_Fj * W_j_ss (using SS wealth to prevent explosive feedback).
    // Deviations driven by interest rate changes, not wealth stock changes.
    // At SS: yf_j = i_j_ss * w_j_ss - tau_j_ss.
    [name = 'eq_yf_F']
    yf_F = i_F * w_F_ss - tau_F;

    [name = 'eq_yf_G']
    yf_G = i_G * w_G_ss;

    [name = 'eq_yf_H']
    yf_H = i_H * (-(w_F_ss + w_G_ss + w_N_ss)) + tau_F + tau_N;

    [name = 'eq_yf_N']
    yf_N = i_N * w_N_ss - tau_N;

    // === Transfer / stabilization rules (paper eqs 123-125) ===
    // Firms transfer to households (dividends): stabilizes w_F toward w_F_ss.
    // tau_F adjusts to keep firms' net asset ratio stable.
    // Transfer rules: simple AR(1) toward SS values (non-aggressive).
    // Transfers track SS with slow adjustment. Wealth stabilization happens
    // endogenously through the consumption/income channel, not transfers.
    // At SS: tau_j = tau_j_ss.
    [name = 'eq_tau_F']
    tau_F = (1 - rho_stab_1) * tau_F(-1) + rho_stab_1 * tau_F_ss;

    [name = 'eq_tau_N']
    tau_N = (1 - rho_stab_1) * tau_N(-1) + rho_stab_1 * tau_N_ss;

    // Government social transfers: AR(1) toward SS + countercyclical.
    // Government spending equation (eq_dln_g) provides the main fiscal rule;
    // tau_G provides additional smoothing of social transfers.
    [name = 'eq_tau_G']
    tau_G = (1 - rho_stab_1) * tau_G(-1) + rho_stab_1 * tau_G_ss
          + 0.05 * yhat_au;

    // === Net financing capacity (B_j) ===
    // B_j measures deviations from SS financing flows.
    // Property income enters only through the interest rate gap (i_j - i_j_ss),
    // NOT through wealth changes, to prevent positive feedback instability.
    // At SS: all terms zero => b_j = 0.

    // Firms: investment gap + interest rate effect on debt servicing
    [name = 'eq_b_F']
    b_F = -w_ib * dln_ib - (tau_F - tau_F_ss) + (i_F - (i_ss + tp_ss + i_F_prem)) * w_F_ss;

    // Government: spending gap - tax revenue + interest rate on debt
    [name = 'eq_b_G']
    b_G = -w_g * dln_g + 0.30 * yhat_au - (tau_G - tau_G_ss) + (i_G - (i_ss + tp_ss)) * w_G_ss;

    // Households: saving gap + interest income
    [name = 'eq_b_H']
    b_H = w_c * (yhat_au - dln_c) - w_ih * dln_ih + (i_H - (i_ss + tp_ss + i_H_prem)) * (-(w_F_ss+w_G_ss+w_N_ss));

    // NPISH: small, interest rate effect only
    [name = 'eq_b_N']
    b_N = (i_N - (i_ss + tp_ss + i_N_prem)) * w_N_ss;

    // === Wealth accumulation (paper eqs 120-121) ===
    // Wealth accumulation with mean-reversion toward SS.
    // w_j = (1-phi)*w_j(-1) + phi*w_j_ss + b_j
    // phi = small (0.02 ~ half-life 35Q) ensures stationarity.
    // Combined with transfer stabilization rules, this keeps sector
    // balance sheets bounded. At SS: b_j=0 => w_j = w_j_ss.
    [name = 'eq_w_F']
    w_F = 0.98 * w_F(-1) + 0.02 * w_F_ss + b_F;

    [name = 'eq_w_G']
    w_G = 0.98 * w_G(-1) + 0.02 * w_G_ss + b_G;

    [name = 'eq_w_H']
    w_H = 0.98 * w_H(-1) + 0.02 * (-(w_F_ss+w_G_ss+w_N_ss)) + b_H;

    [name = 'eq_w_N']
    w_N = 0.98 * w_N(-1) + 0.02 * w_N_ss + b_N;

    // === Current account (ROW closure) ===
    // Flow-of-funds identity: sum of all domestic B_j + B_ROW = 0.
    [name = 'eq_b_ROW']
    b_ROW = -(b_F + b_G + b_H + b_N);

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
    di_gap   = 0;
    pi_au_gap = 0;
    pi_us_gap = 0;

    // Production function (Section 4.3)
    dln_k        = 0;         // zero capital growth at SS (gap model)
    dln_y_star   = 0;         // zero potential output growth at SS (gap model)
    dln_tfp      = 0;         // zero TFP growth at SS
    ln_tfp_LR    = 0;         // FR-BDF Ē_t residual at baseline (gap model)
    ln_tfp       = 0;         // smoothed TFP level converges to ln_tfp_LR = 0

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
    pv_r_lh_gap    = 0;       // real lending rate PV = 0 at SS (audit #26, FR-BDF eq 61)
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
    pv_i_uip       = 0;                             // forward UIP PV = 0 at SS

    // Trade block (proper ECM, all level deviations zero at SS)
    dln_x          = 0;       // zero export growth in stationary model
    ln_x_level     = 0;
    ln_x_eq        = 0;       // = beta_x*0 + gamma_x*0 = 0
    x_gap          = 0;
    dln_m          = 0;       // zero import growth in stationary model
    ln_m_level     = 0;
    ln_m_eq        = 0;       // = beta_m*0 + gamma_m*0 = 0
    m_gap          = 0;
    ln_d_iad       = 0;       // cumulated iad = 0 at SS (iad SS = 0)

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

    // Sector financial accounts
    w_F            = w_F_ss;                       // firms at SS net asset ratio
    w_G            = w_G_ss;                       // government at SS debt ratio
    w_N            = w_N_ss;                       // NPISH at SS
    w_H            = -(w_F_ss + w_G_ss + w_N_ss); // households = residual (closed economy)
    i_F            = i_ss + tp_ss + i_F_prem;      // firms effective return at SS
    i_G            = i_ss + tp_ss;                  // government return = i_10y at SS
    i_H            = i_ss + tp_ss + i_H_prem;      // households effective return at SS
    i_N            = i_ss + tp_ss + i_N_prem;      // NPISH effective return at SS
    tau_F          = tau_F_ss;
    tau_G          = tau_G_ss;
    tau_N          = tau_N_ss;
    yf_F           = i_F * w_F_ss - tau_F_ss;      // firms property income at SS
    yf_G           = i_G * w_G_ss;                  // government property income at SS
    yf_H           = i_H * (-(w_F_ss+w_G_ss+w_N_ss)) + tau_F_ss + tau_N_ss;
    yf_N           = i_N * w_N_ss - tau_N_ss;
    b_F            = 0;                             // firms balanced at SS (deviations = 0)
    b_G            = 0;                             // government balanced at SS
    b_H            = 0;                             // households balanced at SS
    b_N            = 0;                             // NPISH balanced at SS
    b_ROW          = 0;                             // ROW balanced at SS

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

    // Trend level accumulators (all zero at SS)
    ln_QN          = 0;
    ln_Q           = 0;
    ln_C_star      = 0;
    ln_C           = 0;
    ln_IB_star     = 0;
    ln_IB          = 0;
    ln_IH_star     = 0;
    ln_IH          = 0;
    ln_N_star      = 0;
    ln_N           = 0;
    ln_K           = 0;
    ln_P_star      = 0;
    ln_P           = 0;
end;

// Initialize PAC models BEFORE steady (h vectors must be computed first)
if exist('oo_', 'var') && isfield(oo_, 'var') && ~isstruct(oo_.var), oo_.var = struct(); end
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
    var eps_q;        stderr 0.5233;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.4619, 0.5878]
    var eps_i;        stderr 0.1103;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0982, 0.1216]
    var eps_pi;       stderr 0.5872;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.5263, 0.6430]
    var eps_q_us;     stderr 1.138;     // AU posterior mode
    var eps_pi_us;    stderr 0.319;     // AU posterior mode
    var eps_ibar;     stderr 0.01;
    var eps_pibar_au; stderr 0.01;
    var eps_pibar_us; stderr 0.01;
    var eps_pQ;       stderr 0.571;  // VA price shock (AU OLS residual)
    var eps_w;        stderr 0.1486;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.6359, 0.8296]
    var eps_n;        stderr 0.4430;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1229, 0.7341]
    var eps_c;        stderr 1.8587;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [1.6525, 2.0461]
    var eps_ib;       stderr 2.7529;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [2.4853, 3.0525]
    var eps_ih;       stderr 1.3529;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.4871, 2.9457]
    var eps_10y;      stderr 0.0641;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0504, 0.0778]
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
    var eps_tfp_LR;   stderr 0.01;   // FR-BDF §5.2.7: permanent +1% LR level shock (2026-05-15)
    var eps_pcom;     stderr 3.0;    // commodity price shock (Stage 11b, volatile)
    // Stage 12: new shocks
    var eps_lh;       stderr 0.15;   // bank lending rate shock (credit conditions)
    var eps_ph;       stderr 1.0;    // housing price shock (AU housing very volatile)
    // var_model E-SAT shadow + auxiliary shocks
    var eps_var_y;    stderr 0.34;   // shadow output gap (E-SAT scale)
    var eps_var_i;    stderr 0.10;   // shadow interest rate gap
    var eps_var_pi;   stderr 0.26;   // shadow inflation gap
    var eps_var_u;    stderr 0.20;   // shadow unemployment gap
    var eps_var_yus;  stderr 0.50;   // shadow foreign output gap
    var eps_var_yh;   stderr 0.30;   // household income-output ratio gap
    var eps_var_rKB;  stderr 0.30;   // user cost of capital gap
    var eps_var_pQ;   stderr 0.50;   // VA price auxiliary gap
    var eps_var_n;    stderr 0.50;   // employment auxiliary gap
    var eps_var_c;    stderr 0.50;   // consumption auxiliary gap
    var eps_var_ib;   stderr 0.50;   // business investment auxiliary gap
    var eps_var_ih;   stderr 0.50;   // housing investment auxiliary gap
end;

// ===================================================================
// ESTIMATED PARAMETERS WITH PRIORS (auto-generated)
// Priors centered on iterative OLS + Bayesian posteriors (2026-04-14)
// ===================================================================
estimated_params;
    // --- VA Price PAC ---
    b0_pQ,      beta_pdf,       0.03,   0.015;
    b1_pQ,      beta_pdf,       0.29,   0.10;
    b2_pQ,      normal_pdf,     0.00,   0.05;
    // --- Consumption PAC ---
    b0_c,       beta_pdf,       0.07,   0.03;
    b1_c,       beta_pdf,       0.05,   0.03;
    b2_c,       normal_pdf,    -0.55,   0.20;   // OLS=-0.555, prior centered on OLS
    b3_c,       normal_pdf,     0.02,   0.05;
    // --- Business Investment PAC ---
    b0_ib,      beta_pdf,       0.02,   0.01;
    b1_ib,      beta_pdf,       0.09,   0.05;   // OLS=0.093
    b3_ib,      normal_pdf,     0.34,   0.10;   // OLS=0.344, strong accelerator
    // --- Household Investment PAC ---
    b0_ih,      beta_pdf,       0.03,   0.015;
    b1_ih,      beta_pdf,       0.11,   0.05;
    b3_ih,      normal_pdf,     0.23,   0.10;   // OLS=0.231
    // --- Employment PAC ---
    b0_n,       beta_pdf,       0.06,   0.03;   // OLS=0.062
    b1_n,       beta_pdf,       0.31,   0.10;   // OLS=0.315
    b5_n,       normal_pdf,     0.00,   0.05;
    // --- E-SAT / supply block ---
    lambda_w,   beta_pdf,       0.25,   0.10;   // posterior=0.225, away from 0.55 prior
    gamma_w,    beta_pdf,       0.70,   0.15;   // posterior=0.770, very strong AU CPI indexation
    kappa_w,    normal_pdf,     0.08,   0.05;   // posterior=0.080
    // --- Shock standard deviations ---
    stderr eps_q,       inv_gamma_pdf,  0.80,  inf;
    stderr eps_i,       inv_gamma_pdf,  0.10,  inf;
    stderr eps_pi,      inv_gamma_pdf,  0.60,  inf;
    stderr eps_c,       inv_gamma_pdf,  0.50,  inf;
    stderr eps_ib,      inv_gamma_pdf,  1.50,  inf;
    stderr eps_ih,      inv_gamma_pdf,  2.00,  inf;
    stderr eps_n,       inv_gamma_pdf,  0.50,  inf;
    stderr eps_w,       inv_gamma_pdf,  0.30,  inf;
    stderr eps_10y,     inv_gamma_pdf,  0.10,  inf;
end;

// Stage 2: estimated_params_init(use_calibration) NOT compatible with mode_file
// Starting values come from mode file instead

// -----------------------------------------------------------------------
// Compute IRFs
// -----------------------------------------------------------------------

// Initialize PAC models from the enriched var_model companion matrix
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

// stoch_simul replaced by estimation (auto-generated)
// diffuse_filter needed for unit root processes (level accumulators)
// Stage 2: MCMC from saved posterior mode
estimation(datafile='estimation_data.mat',
           first_obs=1,
           mode_compute=0,
           mode_file='/Users/davidstephan/Documents/AUSPAC/dynare/au_pac_bayesian/Output/au_pac_bayesian_mode',
           presample=4,
           mh_replic=0,
           mh_nblocks=1,
           nobs=118, forecast=8,
           diffuse_filter,
           nograph)
           yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;

// =======================================================================
// (Estimation infrastructure activated above — original comments removed)
