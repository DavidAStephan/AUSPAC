// ==========================================================================
// calibration.inc — extracted from au_pac.mod for Phase T refactor (2026-05-16)
// Original line range: 567-951
// ==========================================================================


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
b0_pQ = 0.0282;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0063, 0.0529]
b1_pQ = 0.2842;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1277, 0.4607]
b2_pQ = -0.0065;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.0786, 0.0858]
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
rho_tfp         = 0.95;     // smoothing speed for ln_tfp -> ln_tfp_LR transition.
                            // FR-BDF wp736 eq. 127 uses ρ_HT = 0.95 for trend smoothing
                            // (~14q half-life). Earlier 0.99 amplified eps_tfp 100x.

// --- Commodity price channel (Stage 11b) ---
rho_pcom        = 0.42;     // AU est (s.e.0.08). Was 0.85. IMF commodity index much less persistent
b4_x            = 0.15;     // commodity price -> export volumes
alpha_pcom      = 0.10;     // commodity price -> export deflator pass-through

// Wage Phillips curve parameters (calibrated from Section 4.5.1 / Table 4.5.1)
// Australia: moderate wage persistence, significant gap sensitivity
// Forward expectations proxied by pibar_au (inflation anchor)
lambda_w        = 0.2017;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0342, 0.1573]
kappa_w         = 0.0544;     // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.0288, 0.1420]
                            // |β_4| = 0.32 (Table 4.5.3). MCMC re-run required
                            // post-refit to produce AU posterior under the new
                            // (-kappa_w·pv_u_gap) sign convention. Pre-refit
                            // posterior was 0.0966 with HPD [-0.028, 0.128]
                            // under the wrong-signed equation.
gamma_w         = 0.4579;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.9054, 0.9958]
okun_coeff      = -0.13;    // AU OLS estimate (s.e.0.02). FR-BDF: -0.246, old cal: -0.33
rho_u_gap       = 0.946;    // AU OLS estimate (s.e.0.01). FR-BDF: 0.946, EXACT MATCH
beta_w          = 0.98;     // discount for expected unemployment gaps (paper Section 4.5.1)
// growth neutrality coeff = 1 - 0.55 - 0.15 = 0.30 on pibar_au

// Employment PAC parameters (calibrated from Table 4.5.3, 4th-order adjustment costs)
// Australia: labor market is relatively flexible vs France
b0_n = 0.0616;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0156, 0.1065]
b1_n = 0.3109;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1504, 0.4481]
b2_n = -0.1869;   // 2nd lag (OLS, not in Bayesian estimated_params)
b3_n = -0.0763;   // 3rd lag (OLS, not in Bayesian estimated_params)
b4_n = -0.0852;   // 4th lag (OLS, not in Bayesian estimated_params)
omega_n         = 0.30;     // expectations/forward component
b5_n = 0.0037;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.0836, 0.0797]
rho_n_star      = 0.95;     // target persistence
// growth neutrality coeff = 1 - 0.30 - 0.10 - 0.05 - 0.02 - 0.30 = 0.23

// Household consumption PAC parameters (calibrated from Section 4.6.1 / Table 4.6.1)
// Australia: moderate consumption smoothing, significant HtM share (~30%)
// 1st-order adjustment costs (simplest PAC form)
b0_c = 0.0720;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0294, 0.0961]
b1_c = 0.0345;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0065, 0.0754]
omega_c         = 0.369;    // expectations/forward component (posterior mean, legacy)
b2_c = -0.3570;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.5889, -0.0571]
b3_c = 0.0202;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [-0.0639, 0.0953]
b_di_c          = -0.701;   // Phase C Bayesian regularised (IV with monetary-surprise instrument failed identification due to RBA endogeneity); posterior dominated by prior N(-0.71, 0.30^2)
rho_c_star      = 0.95;     // target persistence
kappa_inc       = 0.050;    // permanent income sensitivity (posterior mean)
beta_c          = 0.95;     // permanent income discount (paper Section 4.6.1, ~25% annual)
alpha_c_r       = -0.95;    // real lending rate -> consumption (paper Table 4.6.14, alpha_1=-0.95)
// growth neutrality coeff = 1 - 0.35 - 0.35 = 0.30

// Business investment PAC parameters (calibrated from Section 4.6.2 / Table 4.6.2)
// Australia: investment more volatile than consumption, strong accelerator
// 2nd-order adjustment costs
b0_ib = 0.0177;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0047, 0.0323]
b1_ib = 0.0849;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0196, 0.1503]
b2_ib = -0.0445;  // 2nd lag (OLS, not in Bayesian estimated_params)
omega_ib        = 0.35;     // expectations/forward component
b3_ib = 0.3074;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1825, 0.4828]
b4_ib           = -0.03;    // real interest rate -> investment (user cost channel)
rho_ib_star     = 0.95;     // target persistence
kappa_wacc      = 0.038;    // WACC gap -> investment target (posterior mean, legacy)
delta_k         = 0.0134;   // quarterly capital depreciation (Phase G ABS 5204: 5.4% annual; was 0.025 from FR-BDF)
// growth neutrality coeff = 1 - 0.25 - 0.10 - 0.35 = 0.30

// Household investment PAC parameters (calibrated from Section 4.6.3 / Table 4.6.3)
// Australia: housing highly interest-rate sensitive (variable-rate mortgages)
// 2nd-order adjustment costs
b0_ih = 0.0284;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0092, 0.0525]
b1_ih = 0.1194;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0243, 0.1744]
b2_ih = -0.0368;  // 2nd lag (OLS, not in Bayesian estimated_params)
omega_ih        = 0.30;     // expectations/forward component
b3_ih = 0.2328;   // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0655, 0.3848]
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
beta_uip        = 0.92;     // UIP forward-NPV discount. Standard NPV form (coeff 1 on i_gap).
                            // Under Hybrid/MCE, pv_i_uip jumps to ~4.5x i_gap on impact
                            // -> AUD appreciation jumps -> export/import channel
                            // -> FR-BDF-style Hybrid amplification.

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
