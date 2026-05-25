// ==========================================================================
// shocks.inc — Phase T DAY-2 EXTRACTION (2026-05-16)
// Extracted from au_pac.mod lines 2245-2293 (body of shocks;)
// ==========================================================================

    var eps_q;        stderr 0.5269;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.4619, 0.5878]
    var eps_i;        stderr 0.1095;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0982, 0.1216]
    var eps_pi;       stderr 0.5901;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.5263, 0.6430]
    var eps_q_us;     stderr 1.138;     // AU posterior mode
    var eps_pi_us;    stderr 0.319;     // AU posterior mode
    var eps_ibar;     stderr 0.01;
    var eps_pibar_au; stderr 0.01;
    var eps_pibar_us; stderr 0.01;
    var eps_pQ;       stderr 0.571;  // VA price shock (AU OLS residual)
    var eps_w;        stderr 0.1528;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.6359, 0.8296]
    var eps_n;        stderr 0.3917;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.1229, 0.7341]
    var eps_c;        stderr 1.8134;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [1.6525, 2.0461]
    var eps_ib;       stderr 2.7719;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [2.4853, 3.0525]
    var eps_ih;       stderr 1.3698;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.4871, 2.9457]
    var eps_10y;      stderr 0.0649;    // MCMC refresh 2026-05-11: posterior mean, 90% HPD [0.0504, 0.0778]
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
    var eps_tfp_LR;   stderr 0.01;   // FR-BDF wp736 §5.2.7: permanent +1% LR-level
                                     // shock to log trend efficiency. Replaces the
                                     // old growth-rate eps_tfp ~N(0, 0.2²) (2026-05-15).
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
    // Round 4-8 (2026-05-20): new exogenous shock processes
    var eps_pop_bar;  stderr 0.05;   // Round 5: demographic-trend gap shock
    var eps_ibar_us;  stderr 0.01;   // Round 4: US LR anchor shock
    var eps_i_us;     stderr 0.15;   // Round 4: US policy rate shock
    var eps_tau_GST;  stderr 0.10;   // Round 6: GST effective-rate shock
    var eps_tau_PAYG; stderr 0.20;   // Round 6: PAYG effective-rate shock
    var eps_tau_CIT;  stderr 0.30;   // Round 6: CIT effective-rate shock
    var eps_BLR;      stderr 0.05;   // Round 8: BLR nowcast shock
    var eps_MAPI;     stderr 0.50;   // Round 8: MAPI nowcast shock
    var eps_MAPU;     stderr 0.30;   // Round 8: MAPU nowcast shock
    var eps_wtH;      stderr 0.012;  // Round 1.2: household wage+transfer-income shock
                                     //   (sd from HP-gap of ABS 5206 Table 20, 1993-2024)
    var eps_dy_bar;   stderr 0.05;   // Phase L1.3a: HP-filtered trend GDP growth RW innovation
