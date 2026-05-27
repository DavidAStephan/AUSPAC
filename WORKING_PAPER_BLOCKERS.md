# WORKING_PAPER_BLOCKERS.md — Phase B blockers and workarounds (RESOLVED 2026-05-26)

**Generated**: 2026-05-26 during the Phase L2 → working-paper-v2 regeneration session.
**Updated**: 2026-05-26 — all three blockers below have been resolved in-session via the workarounds tabulated. Kept for reference and for the next time someone hits the same launcher errors.

| Tool | Status | Detail | Workaround |
|---|---|---|---|
| MATLAB R2020a (`/Applications/MATLAB_R2020a.app/bin/matlab -batch`) | **RESOLVED** via `arch -x86_64` prefix | R2020a's `bin/util/arch.sh` checks `uname -p`: on Intel Macs it returns `i386` and ARCH is set to `maci64`; on Apple Silicon it returns `arm` and ARCH stays unset → the launcher prints `"Sorry! We could not determine the machine architecture for your host"` and exits 1. The `arch -x86_64` wrapper forces the child process to run in Rosetta's x86_64 personality, which makes `uname -p` return `i386`, so the detection passes and MATLAB starts normally. | `arch -x86_64 /Applications/MATLAB_R2020a.app/bin/matlab -batch "..."` |
| Dynare 6.5 (`/Applications/Dynare/6.5-x86_64/`) | **RESOLVED** transitively | Once MATLAB batch works, Dynare runs as its MATLAB Mex layer. | `arch -x86_64 .../matlab -batch "addpath('/Applications/Dynare/6.5-x86_64/matlab'); dynare au_pac_bayesian.mod"` |
| LaTeX (`pdflatex`, `xelatex`) | **RESOLVED** via `tectonic` | No standard TeX Live distribution installed, but `tectonic` (a self-contained Rust-implemented LaTeX engine) is in `/opt/homebrew/bin/tectonic`. | `cd dynare && tectonic AUSPAC_WORKING_PAPER.tex` — produces `AUSPAC_WORKING_PAPER.pdf`. Greek-letter warnings in lmroman are non-fatal. |

For future sessions hitting the MATLAB launcher error: the one-liner is `arch -x86_64 /Applications/MATLAB_R2020a.app/bin/matlab -batch "...your matlab code..."`. The Octave + brew-dynare path is also available but Octave's MH MCMC is ~5× slower than MATLAB's on this workload, so prefer MATLAB.

Per [NEXT_SESSION.md](NEXT_SESSION.md) §working-principles point 5: "Stop-on-blocker — if Dynare fails at Phase B3, document the error in WORKING_PAPER_BLOCKERS.md and proceed with the other phases; pick up Dynare separately."

This document records that decision and the workarounds adopted for the other phases.

## What is delivered in spite of the blocker

1. **Build scripts written but not executed.** `data/make_paper_tables.m` and `data/make_paper_charts.m` are committed and can be run from a MATLAB GUI session via `cd data; make_paper_tables; make_paper_charts;`. They produce the nine tables and the chart set described in NEXT_SESSION.md Phase WP-B1–B2 against the existing `data/pac_blocks/results_*.mat` artifacts (already produced in Phase L2).
2. **IRF regeneration script written but not executed.** A short driver `dynare/regen/regen_irfs_hybrid.m` invokes `dynare au_pac` (with `irf=40, order=1`) and saves the post-hybrid-calibration IRFs to `dynare/paper_artifacts/irf_<shock>_hybrid.png`. It must be run from MATLAB GUI.
3. **Existing IRF PNGs are reused in the paper.** The IRF PNGs in `dynare/` (`irf_eps_i.png`, `irf_eps_q_us.png`, etc.) were generated under the prior calibration. The hybrid-calibration impact on IRFs is structurally bounded: the BI block now has the wp1044 coefficients (β₀=0.096 vs prior 0.018 — 5× faster ECM; β₁=0.33 vs prior 0.082 — 4× more inertial), so post-hybrid IRFs for the **monetary, term-premium, and commodity-price shocks** will differ in magnitude through the BI channel. The §7.2 Channel-by-channel walkthrough in the paper is updated to flag this; the figures themselves are kept and clearly labelled as "pre-hybrid baseline (Phase Y, 2026-05-17)" with a forward reference to the post-hybrid update once MATLAB GUI is available.
4. **Tables in the paper are populated from per-block `.txt` artifacts.** Every numeric value in the new tables 4.3.2 / 4.4.4 / 4.5.2 / 4.6.x / 4.6.business and §5 cross-block / Appendix G comes directly from a `results_*.txt` (Phase L2 outputs) or from wp1044 Tables 3.3.3 / 3.4.9 / 3.5.2 / 3.5.7 / 3.5.13. No regeneration needed.
5. **Pandoc compilation.** `pandoc` 3.9.0.2 is available; the paper compiles to `.tex` and `.html` cleanly. PDF compilation is deferred to a session with LaTeX.

## What to do next time MATLAB GUI is available

1. Launch MATLAB R2020a GUI.
2. Run from MATLAB:
   ```matlab
   cd ~/Documents/AUSPAC/data
   make_paper_tables    % produces dynare/paper_artifacts/table_*.{txt,tex}
   make_paper_charts    % produces dynare/paper_artifacts/chart_*.png
   cd ../dynare
   regen/regen_irfs_hybrid    % produces dynare/paper_artifacts/irf_*_hybrid.png
   ```
3. Commit the produced `.png/.tex/.txt` files into `dynare/paper_artifacts/`.
4. Re-render the paper via `pandoc` (no edits to `AUSPAC_WORKING_PAPER.md` should be needed; the figure paths are already correct).
5. Once a LaTeX distribution is installed, regenerate the PDF.

## Confirmation log

```
$ /Applications/MATLAB_R2020a.app/bin/matlab -batch 'fprintf(\"hi\\n\"); exit'
    Sorry! We could not determine the machine architecture for your
           host. Please contact:
               MathWorks Technical Support
           for further assistance.
trap: usage: trap [-lp] [arg signal_spec ...]

$ which pdflatex xelatex tlmgr
pdflatex not found
xelatex not found
tlmgr not found

$ which pandoc
/opt/homebrew/bin/pandoc

$ pandoc --version | head -1
pandoc 3.9.0.2
```
