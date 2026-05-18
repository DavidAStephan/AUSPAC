"""Normalize au_pac.mod's model body into aggregate-compatible model.inc form.

aggregate.m (Dynare 6.5) parses line-by-line, expecting:
  - Lines starting with [name='foo']
  - Single-line equations terminated with ;
  - No comments, no leading whitespace, no embedded macros

Also REMOVES equations that come from cherrypicked aux files:
  - 12 shadow var_* equations (var_y/i/pi/u/yus + 7 auxiliary regressions)
  - 5 PAC equations (eq_piQ_pac, eq_dln_c_pac, eq_dln_ib_pac, eq_dln_ih_pac, eq_dln_n_pac)
"""

import re
import pathlib

SRC = pathlib.Path('/Users/davidstephan/Documents/AUSPAC/dynare/au_pac.mod')
DST = pathlib.Path('/Users/davidstephan/Documents/AUSPAC/dynare/simulation/identities/model.inc')

# Equations to EXCLUDE — they live in aux/ + cherrypick
EXCLUDED_EQTAGS = {
    # 12 shadow VAR equations (5 E-SAT core shadows + 7 aux regressions)
    'var_y', 'var_i', 'var_pi', 'var_u', 'var_yus',
    'var_pQ', 'var_n', 'var_yh', 'var_c', 'var_ib', 'var_rKB', 'var_ih',
    # 5 PAC equations
    'eq_piQ_pac', 'eq_dln_n_pac', 'eq_dln_c_pac', 'eq_dln_ib_pac', 'eq_dln_ih_pac',
}

# Equation REWRITES to avoid LHS-variable conflicts in aggregate's dedup.
# aggregate.m dedups by LHS variable name; def_X_gap shares LHS with eq_taylor
# (i_gap) / eq_au_phillips (pi_au_gap) / eq_us_phillips (pi_us_gap), so we
# flip the definitional identities to use the LEVEL variable as LHS instead.
EQUATION_REWRITES = {
    'def_i_gap': ('i_au', 'i_au = i_gap + ibar;'),
    'def_pi_au_gap': ('pi_au', 'pi_au = pi_au_gap + pibar_au;'),
    'def_pi_us_gap': ('pi_us', 'pi_us = pi_us_gap + pibar_us;'),
}


def extract_model_block(src_text):
    """Find the body of the model; ... end; block."""
    # Find "model;" start
    m = re.search(r'^\s*model;\s*$', src_text, re.M)
    if not m:
        raise ValueError("model; opener not found")
    body_start = m.end()
    # Find first "end;" after that
    e = re.search(r'^\s*end;\s*$', src_text[body_start:], re.M)
    if not e:
        raise ValueError("end; not found after model;")
    return src_text[body_start:body_start + e.start()]


def strip_comments(line):
    """Remove // comments from a line."""
    # Find // not inside a string (model file has no strings, so just split)
    idx = line.find('//')
    if idx >= 0:
        return line[:idx]
    return line


def normalize(body):
    """Tokenize body into equations, drop excluded, emit normalized form."""
    # Strip all // comments first
    lines = []
    for line in body.split('\n'):
        line = strip_comments(line).rstrip()
        lines.append(line)

    # Walk lines, accumulate equations
    out = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        # Equation tag?
        m = re.match(r"\[name\s*=\s*'(\w+)'\s*\]", line)
        if m:
            tag = m.group(1)
            # Collect the equation body — all subsequent lines until the line that ends with ;
            eq_lines = []
            i += 1
            while i < n:
                ln = lines[i].strip()
                if ln:
                    eq_lines.append(ln)
                    if ln.endswith(';'):
                        i += 1
                        break
                i += 1
            eq = ' '.join(eq_lines)
            # Normalize internal whitespace
            eq = re.sub(r'\s+', ' ', eq).strip()
            if tag in EXCLUDED_EQTAGS:
                # Skip this equation
                continue
            if tag in EQUATION_REWRITES:
                # Flip LHS to avoid aggregate's dedup-by-LHS collision
                new_tag, new_eq = EQUATION_REWRITES[tag]
                out.append(f"[name='{new_tag}']")
                out.append(new_eq)
                out.append('')
                continue
            # Emit normalized
            out.append(f"[name='{tag}']")
            out.append(eq)
            out.append('')
        else:
            # Equation without a tag (rare) — just emit normalized
            # Actually for safety, skip lines we can't parse
            i += 1
    return '\n'.join(out)


def main():
    src_text = SRC.read_text()
    body = extract_model_block(src_text)
    normalized = normalize(body)
    # aggregate.m does NOT strip // comments — must omit them
    DST.write_text(normalized + "\n")
    print(f"Wrote {DST} ({len(normalized.splitlines())} lines)")


if __name__ == '__main__':
    main()
