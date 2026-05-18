"""Normalize endogenous.inc and exogenous.inc for aggregate() compatibility.

aggregate.m expects each declaration file to be:
  var
      var1
      var2
      ...
      ;

(or `varexo` for exogenous). One name per line, terminated by `;`. Tabs are
stripped. We also remove shadow variables/shocks that are now declared in
the cherrypicked aux files.
"""

import re
import pathlib

ROOT = pathlib.Path('/Users/davidstephan/Documents/AUSPAC/dynare/simulation/identities')

# Shadow variables to REMOVE from endogenous.inc
SHADOW_VARS = {
    # 5 shadow E-SAT core variables
    'y_gap_var', 'i_gap_var', 'pi_gap_var', 'u_gap_var', 'yhat_us_var',
    # 7 auxiliary regression target variables (now declared in aux/*.mod cherrypicks)
    'piQ_hat', 'n_hat', 'yh_ratio_hat', 'c_hat', 'ib_hat', 'rKB_hat', 'ih_hat',
}

# Shadow shocks to REMOVE from exogenous.inc
SHADOW_SHOCKS = {
    'eps_var_y', 'eps_var_i', 'eps_var_pi', 'eps_var_pQ', 'eps_var_n', 'eps_var_c',
    'eps_var_yh', 'eps_var_ib', 'eps_var_rKB', 'eps_var_ih', 'eps_var_u', 'eps_var_yus',
    # COVID dummies: terms removed from cherrypicked PAC eqs (v2 is steady-state simulation,
    # not historical fit), so the dummies are no longer referenced anywhere
    'd_covid_crash', 'd_covid_bounce',
}


def normalize_decls(input_path, keyword, removed_set):
    """Read input_path (a .inc with `var` or `varexo` block), strip comments,
    filter out removed_set names, emit aggregate-compatible form."""
    txt = input_path.read_text()
    # Strip comments line-by-line
    lines = []
    for line in txt.split('\n'):
        idx = line.find('//')
        if idx >= 0:
            line = line[:idx]
        lines.append(line.rstrip())
    txt = '\n'.join(lines)
    # Find the keyword block: `var ... ;` (greedy)
    m = re.search(r'^\s*' + keyword + r'\b(.*?);\s*$', txt, re.M | re.S)
    if not m:
        raise ValueError(f"{keyword} block not found in {input_path}")
    body = m.group(1)
    # Tokenize: split on whitespace, filter empties
    names = re.findall(r'[A-Za-z_][A-Za-z_0-9]*', body)
    # Filter out removed
    kept = [n for n in names if n not in removed_set]
    # Dedup while preserving order
    seen = set()
    out_names = []
    for n in kept:
        if n in seen: continue
        seen.add(n); out_names.append(n)
    # Emit
    lines = [keyword]
    for n in out_names:
        lines.append('\t' + n)
    out = '\n'.join(lines) + ';\n'
    return out, len(out_names), len(names) - len(kept)


def main():
    # endogenous.inc — aggregate.m does NOT strip // comments
    out, kept, dropped = normalize_decls(ROOT / 'endogenous.inc', 'var', SHADOW_VARS)
    (ROOT / 'endogenous.inc').write_text(out)
    print(f"endogenous.inc: kept {kept}, dropped {dropped}")

    # exogenous.inc
    out, kept, dropped = normalize_decls(ROOT / 'exogenous.inc', 'varexo', SHADOW_SHOCKS)
    (ROOT / 'exogenous.inc').write_text(out)
    print(f"exogenous.inc: kept {kept}, dropped {dropped}")


if __name__ == '__main__':
    main()
