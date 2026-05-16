"""Build aggregate-compatible parameters.inc + parameter-values.inc in
simulation/identities/ from au_pac.mod's declarations and calibration.

aggregate.m expects:
- parameters.inc: a single line of the form `parameters name1 name2 ... ;`
- parameter-values.inc: one `name = value;` per line
"""
import re
import pathlib

SRC = pathlib.Path('/Users/davidstephan/Documents/AUSPAC/dynare/au_pac.mod')
ROOT = pathlib.Path('/Users/davidstephan/Documents/AUSPAC/dynare/simulation/identities')

# Parameters set by aux files (cherrypicked) — exclude from identities/
# to avoid duplicate-value errors in aggregate()
AUX_OWNED_PARAMS = {
    # PAC short-run coefficients (estimated in aux files via pac.estimate)
    'b0_pQ', 'b1_pQ', 'b2_pQ',
    'b0_c', 'b1_c', 'b2_c', 'b3_c',
    'b0_ib', 'b1_ib', 'b2_ib', 'b3_ib',
    'b0_ih', 'b1_ih', 'b2_ih', 'b3_ih',
    'b0_n', 'b1_n', 'b2_n', 'b3_n', 'b4_n', 'b5_n',
    # Auxiliary regression coefficients (set in aux files)
    'rho_pQ_aux', 'a_pQ_y', 'a_pQ_i', 'a_pQ_pi', 'a_pQ_u',
    'rho_n_aux', 'a_n_y', 'a_n_i', 'a_n_pi', 'a_n_u',
    'rho_yh_aux', 'a_yh_y', 'a_yh_u',
    'rho_c_aux', 'a_c_y', 'a_c_i', 'a_c_pi', 'a_c_u', 'a_c_yh',
    'rho_ib_aux', 'a_ib_y', 'a_ib_pi', 'a_ib_u',
    'rho_rKB_aux', 'a_rKB_i',
    'rho_ih_aux', 'a_ih_y', 'a_ih_i', 'a_ih_pi', 'a_ih_u',
}


def strip_comments(line):
    idx = line.find('//')
    return line[:idx] if idx >= 0 else line


def extract_params_block(src_text):
    """Find the `parameters ... ;` block."""
    m = re.search(r'^\s*parameters\b(.*?);', src_text, re.M | re.S)
    if not m:
        raise ValueError("parameters block not found")
    return m.group(1)


def extract_calibrations(src_text, param_names):
    """Find <name> = <value>; assignments for params in param_names.
    aggregate.m uses textscan('%s = %f') which requires a single float on RHS,
    so any arithmetic expressions (e.g., '-0.70 * 4') must be pre-evaluated."""
    out = []
    for line in src_text.split('\n'):
        line = strip_comments(line)
        m = re.match(r'^\s*(\w+)\s*=\s*([^;]+);', line)
        if not m:
            continue
        name, val = m.group(1).strip(), m.group(2).strip()
        if name not in param_names:
            continue
        # Try to pre-evaluate arithmetic
        try:
            # Only allow basic arithmetic with numbers
            if re.match(r'^[\d\s\.\-\+\*\/\(\)eE]+$', val):
                evaluated = eval(val, {'__builtins__': None}, {})
                val = repr(evaluated)
        except Exception:
            pass
        out.append((name, val))
    return out


def main():
    src = SRC.read_text()
    # Strip comments line by line first
    src_clean = '\n'.join(strip_comments(l) for l in src.split('\n'))

    # Extract param names
    body = extract_params_block(src_clean)
    names = re.findall(r'[A-Za-z_][A-Za-z_0-9]*', body)
    # Dedup, preserve order
    seen = set()
    uniq = []
    for n in names:
        if n in seen: continue
        seen.add(n); uniq.append(n)
    print(f"Found {len(uniq)} parameter names")

    # Write parameters.inc as a single line — no // comments (aggregate doesn't strip)
    out = "parameters " + " ".join(uniq) + " ;"
    (ROOT / 'parameters.inc').write_text(out + "\n")
    print(f"  wrote parameters.inc")

    # Extract calibrations
    name_set = set(uniq)
    calibs = extract_calibrations(src_clean, name_set)
    # Dedup: keep LAST occurrence per name (calibration block has the actual values)
    seen = {}
    for name, val in calibs:
        seen[name] = val
    print(f"Found {len(seen)} calibrations")

    # Write parameter-values.inc — exclude aux-owned params (cherrypicked)
    lines = []
    excluded = 0
    for name in uniq:  # preserve declaration order
        if name in AUX_OWNED_PARAMS:
            excluded += 1
            continue
        if name in seen:
            lines.append(f"{name} = {seen[name]};")
    print(f"  excluded {excluded} aux-owned params (cherrypicked instead)")
    (ROOT / 'parameter-values.inc').write_text("\n".join(lines) + "\n")
    print(f"  wrote parameter-values.inc ({len(lines)} assignments)")


if __name__ == '__main__':
    main()
