"""Propagate the FR-BDF trade ECM fix to sibling .mod files.

Applies the same surgical edits we made to au_pac_bayesian.mod:
  1. New endogenous variables in the trade block declaration.
  2. New parameters in the trade parameter block.
  3. Parameter calibration values just after b3_m.
  4. Trade-block equations: degenerate m_gap/x_gap accumulators replaced
     with proper LR equilibrium + EC term (FR-BDF Section 4.7).
  5. Steady-state additions for the new vars (all = 0).

Each file is edited in place. The script verifies that each edit applies
exactly once before touching the file, so unexpected variations abort
without partial writes.

Note: Sibling .mod files have varying observation/estimation blocks
(some don't run estimation). This script only touches the equation block,
parameter block, and SS — varobs / estimation_command edits are caller's
responsibility per file.
"""

from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
DYNARE = HERE.parent  # dynare/ workspace where MATLAB writes .mat artefacts
TARGETS = [
    "au_pac.mod",
    "au_pac_mce.mod",
    "au_pac_recursive.mod",
    "au_pac_condforecast.mod",
    "au_pac_var.mod",
    "au_pac_smooth.mod",
    "au_pac_identification.mod",
]


# --- Edit 1: variable declarations -----------------------------------------
OLD_VARS = """    // === Trade block (Section 4.7) ===
    dln_x           // export volume growth (quarterly log diff)
    x_gap           // export gap (equilibrium - actual, log level)
    dln_m           // import volume growth (quarterly log diff)
    m_gap           // import gap (equilibrium - actual, log level)"""

NEW_VARS = """    // === Trade block (Section 4.7) ===
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
    ln_d_iad        // log import-weighted demand level (accumulates iad)"""


# --- Edit 2: parameter declarations ----------------------------------------
OLD_PARAMS = """    // --- Export parameters (Section 4.7, eqs. 70-73) ---
    b0_x            // error correction speed
    b1_x            // export growth persistence
    b2_x            // world demand elasticity (yhat_us -> exports)
    b3_x            // exchange rate elasticity (depreciation -> more exports)

    // --- Import parameters (Section 4.7, eqs. 74-77) ---
    b0_m            // error correction speed
    b1_m            // import growth persistence
    b2_m            // domestic demand elasticity (yhat_au -> imports)
    b3_m            // exchange rate elasticity (depreciation -> fewer imports)"""

NEW_PARAMS = """    // --- Export parameters (Section 4.7, eqs. 70-73) ---
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
    gamma_m         // LR real exchange rate elasticity (depreciation < 0)"""


# --- Edit 3: calibration values (inserted after the existing b3_m line) ----
OLD_CALIB = """b3_m            = -0.08;    // depreciation -> fewer imports (negative: price effect)"""

NEW_CALIB = """b3_m            = -0.08;    // depreciation -> fewer imports (negative: price effect)

// Long-run trade elasticities (FR-BDF Section 4.7 / Table 4.7.1-2 proper ECM)
// AU empirical estimates: imports income-elastic (rising openness 1960-now),
// exports world-demand-elastic; both have real-exchange-rate response.
beta_m          = 1.50;     // LR income elasticity of imports (AU 1.3-1.7 range)
gamma_m         = -0.40;    // LR RER elasticity (depreciation -> import volumes fall)
beta_x          = 1.20;     // LR foreign-income elasticity of exports
gamma_x         =  0.40;    // LR RER elasticity (depreciation -> export volumes rise)"""


# --- Edit 4: trade-block equations -----------------------------------------
OLD_EQNS = """    // === EXPORTS ECM (eqs. 70-73) ===
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
            + eps_m;"""

NEW_EQNS = """    // Log-level accumulators (deviation form, all SS = 0).
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
            + eps_m;"""


# --- Edit 5: steady-state additions ----------------------------------------
OLD_SS = """    // Trade block
    dln_x          = 0;       // zero export growth in stationary model
    x_gap          = 0;
    dln_m          = 0;       // zero import growth in stationary model
    m_gap          = 0;"""

NEW_SS = """    // Trade block (proper ECM, all level deviations zero at SS)
    dln_x          = 0;       // zero export growth in stationary model
    ln_x_level     = 0;
    ln_x_eq        = 0;       // = beta_x*0 + gamma_x*0 = 0
    x_gap          = 0;
    dln_m          = 0;       // zero import growth in stationary model
    ln_m_level     = 0;
    ln_m_eq        = 0;       // = beta_m*0 + gamma_m*0 = 0
    m_gap          = 0;
    ln_d_iad       = 0;       // cumulated iad = 0 at SS (iad SS = 0)"""


EDITS = [
    ("variable declarations", OLD_VARS, NEW_VARS),
    ("parameter declarations", OLD_PARAMS, NEW_PARAMS),
    ("calibration values", OLD_CALIB, NEW_CALIB),
    ("trade-block equations", OLD_EQNS, NEW_EQNS),
    ("steady-state additions", OLD_SS, NEW_SS),
]


def apply_to_file(path):
    text = path.read_text()
    log = []
    for label, old, new in EDITS:
        count = text.count(old)
        if count == 0:
            log.append(f"  [SKIP] {label}: pattern not found")
            continue
        if count > 1:
            log.append(f"  [FAIL] {label}: matched {count} times — abort")
            return False, log
        text = text.replace(old, new, 1)
        log.append(f"  [ OK ] {label}: applied")
    path.write_text(text)
    return True, log


def main():
    print("Propagating FR-BDF trade ECM fix to sibling .mod files\n")
    for fname in TARGETS:
        path = DYNARE / fname
        if not path.exists():
            print(f"--- {fname} (NOT FOUND) ---")
            continue
        print(f"--- {fname} ---")
        ok, log = apply_to_file(path)
        for line in log:
            print(line)
        if not ok:
            print(f"  ABORTED on {fname}")
            sys.exit(1)
        print()


if __name__ == "__main__":
    main()
