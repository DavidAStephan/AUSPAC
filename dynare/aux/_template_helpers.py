"""Generate aux_X.mod files for the 4 remaining PAC blocks (consumption,
business_inv, housing_inv, employment) using a shared template.

The template follows the aux_pQ.mod pattern: E-SAT core in pure-VAR form,
auxiliary regression(s) for the PAC target, the PAC equation with
pac_expectation, and var_model + pac_model declarations.

Variables external to the aux file (pv_X_aux, di_gap, ph_gap, COVID dummies)
are declared as varexo so Dynare's compile doesn't complain.
"""

import pathlib

ESAT_VARS = """    yhat_au         pi_au_gap       i_gap           u_gap
    yhat_us         pi_us_gap
    ibar            pibar_au        pibar_us
    piQ             pi_m            dln_pcom"""

ESAT_SHOCKS = """    eps_q           eps_i           eps_pi          eps_q_us
    eps_pi_us       eps_ibar        eps_pibar_au    eps_pibar_us
    eps_u_gap       eps_piQ         eps_pi_m        eps_pcom"""

ESAT_PARAMS = """    delta           lambda_q        sigma_q
    lambda_i        alpha_i         beta_i
    lambda_pi       kappa_pi
    lambda_q_us     lambda_pi_us    kappa_pi_us
    lambda_ibar     lambda_pibar    lambda_pibar_us
    rho_u_gap       okun_coeff
    alpha_pc        beta_pc_m       gamma_oil
    i_ss            pi_ss_au        pi_ss_us
    rho_piQ         rho_pi_m        rho_pcom"""

ESAT_CALIB = """delta           = 0.1989;       lambda_q        = 0.6959;       sigma_q         = 0.0648;
lambda_i        = 0.9576;       alpha_i         = 0.3001;       beta_i          = 0.0837;
lambda_pi       = 0.2902;       kappa_pi        = 0.0374;
lambda_q_us     = 0.8057;       lambda_pi_us    = 0.6529;       kappa_pi_us     = 0.0131;
lambda_ibar     = 0.985;        lambda_pibar    = 0.93;         lambda_pibar_us = 0.93;
rho_u_gap       = 0.94;         okun_coeff      = -0.33;
alpha_pc        = 0.17;         beta_pc_m       = 0.10;         gamma_oil       = 0.03;
i_ss            = 1.0491;       pi_ss_au        = 0.625;        pi_ss_us        = 0.5;
rho_piQ         = 0.85;         rho_pi_m        = 0.7;          rho_pcom        = 0.42;"""

ESAT_MODEL = """    [name = 'var_yhat_au']
    yhat_au = lambda_q*yhat_au(-1) - sigma_q*(i_gap(-1) - pi_au_gap(-1)) + delta*yhat_us(-1) + eps_q;

    [name = 'var_i_gap']
    i_gap = lambda_i*i_gap(-1) + (1-lambda_i)*(alpha_i*pi_au_gap(-1) + beta_i*yhat_au(-1)) + eps_i;

    [name = 'var_pi_au_gap']
    pi_au_gap = lambda_pi*pi_au_gap(-1) + kappa_pi*yhat_au(-1)
              + alpha_pc*(piQ(-1) - pibar_au(-1)) + beta_pc_m*(pi_m(-1) - pibar_au(-1))
              + gamma_oil*dln_pcom(-1) + eps_pi;

    [name = 'var_u_gap']
    u_gap = rho_u_gap*u_gap(-1) + okun_coeff*yhat_au(-1) + eps_u_gap;

    [name = 'var_yhat_us']
    yhat_us = lambda_q_us*yhat_us(-1) + eps_q_us;

    [name = 'var_pi_us_gap']
    pi_us_gap = lambda_pi_us*pi_us_gap(-1) + kappa_pi_us*yhat_us(-1) + eps_pi_us;

    [name = 'var_ibar']
    ibar = lambda_ibar*ibar(-1) + (1-lambda_ibar)*i_ss + eps_ibar;

    [name = 'var_pibar_au']
    pibar_au = lambda_pibar*pibar_au(-1) + (1-lambda_pibar)*pi_ss_au + eps_pibar_au;

    [name = 'var_pibar_us']
    pibar_us = lambda_pibar_us*pibar_us(-1) + (1-lambda_pibar_us)*pi_ss_us + eps_pibar_us;

    [name = 'var_piQ']
    piQ = rho_piQ*piQ(-1) + (1-rho_piQ)*pi_ss_au + eps_piQ;

    [name = 'var_pi_m']
    pi_m = rho_pi_m*pi_m(-1) + (1-rho_pi_m)*pi_ss_au + eps_pi_m;

    [name = 'var_dln_pcom']
    dln_pcom = rho_pcom*dln_pcom(-1) + eps_pcom;"""

ESAT_SHOCKS_BLOCK = """    var eps_q;          stderr 0.527;
    var eps_i;          stderr 0.110;
    var eps_pi;         stderr 0.590;
    var eps_q_us;       stderr 1.138;
    var eps_pi_us;      stderr 0.319;
    var eps_ibar;       stderr 0.01;
    var eps_pibar_au;   stderr 0.01;
    var eps_pibar_us;   stderr 0.01;
    var eps_u_gap;      stderr 0.05;
    var eps_piQ;        stderr 0.571;
    var eps_pi_m;       stderr 0.5;
    var eps_pcom;       stderr 3.0;"""

ESAT_EQTAGS = """'var_yhat_au', 'var_i_gap', 'var_pi_au_gap', 'var_u_gap',
        'var_yhat_us', 'var_pi_us_gap',
        'var_ibar', 'var_pibar_au', 'var_pibar_us',
        'var_piQ', 'var_pi_m', 'var_dln_pcom'"""


def aux_template(block_name, pac_name, extra_vars, extra_shocks, extra_params, extra_calib,
                 aux_regression_eqtags, aux_regression_eqs,
                 pac_eq_name, pac_eq_body, pac_lhs_var,
                 extra_aux_block=""):
    """Generate an aux_<block>.mod file."""
    return f"""// --+ options: stochastic,json=compute +--
// =========================================================================
// aux_{block_name}.mod — Phase T aux file for {block_name} PAC equation
// AUTO-GENERATED from aux/_template_helpers.py
// =========================================================================

var
{ESAT_VARS}
{extra_vars}
;

varexo
{ESAT_SHOCKS}
{extra_shocks}
;

parameters
{ESAT_PARAMS}
{extra_params}
;

{ESAT_CALIB}
{extra_calib}

var_model(model_name = esat_{block_name},
    eqtags = [
        {ESAT_EQTAGS},
        {aux_regression_eqtags}
    ]);

pac_model(auxiliary_model_name = esat_{block_name}, discount = beta_pac, model_name = {pac_name});

model;

{ESAT_MODEL}

{aux_regression_eqs}

{extra_aux_block}

    [name = '{pac_eq_name}']
{pac_eq_body}

end;

shocks;
{ESAT_SHOCKS_BLOCK}
{extra_shocks_block(extra_shocks)}
end;

pac.initialize('{pac_name}');
pac.update.expectation('{pac_name}');
pac.print('{pac_name}', '{pac_eq_name}');
"""


def extra_shocks_block(extra_shocks):
    """Generate shocks; var eps_X; stderr ...; for each extra shock."""
    out = []
    defaults = {
        'eps_var_pQ': 0.01, 'eps_var_n': 0.01, 'eps_var_c': 0.01, 'eps_var_yh': 0.01,
        'eps_var_ib': 0.01, 'eps_var_rKB': 0.01, 'eps_var_ih': 0.01,
        'eps_pQ': 0.571, 'eps_n': 0.39, 'eps_c': 1.81, 'eps_ib': 2.78, 'eps_ih': 1.78,
    }
    for tok in extra_shocks.replace('\n', ' ').split():
        tok = tok.strip()
        if not tok or tok == ';':
            continue
        std = defaults.get(tok, 0.5)
        out.append(f"    var {tok};       stderr {std};")
    return '\n'.join(out)


# ---- aux_consumption.mod ----
aux_consumption = aux_template(
    block_name='consumption',
    pac_name='pac_c',
    extra_vars="    yh_ratio_hat    c_hat\n    ln_c_level",
    extra_shocks="    eps_var_yh      eps_var_c       eps_c",
    extra_params="""    rho_yh_aux      a_yh_y          a_yh_u
    rho_c_aux       a_c_y           a_c_i           a_c_pi          a_c_u           a_c_yh
    b0_c            b1_c            b2_c            b3_c
    beta_pac""",
    extra_calib="""rho_yh_aux      = 0.6;           a_yh_y          = 0.4;           a_yh_u          = -0.2;
rho_c_aux       = 0.6;           a_c_y           = 0.06;          a_c_i           = -0.04;
a_c_pi          = 0.005;         a_c_u           = -0.03;         a_c_yh          = 0.39;
b0_c            = 0.0736;        b1_c            = 0.0375;        b2_c            = -0.3330;       b3_c            = 0.0220;
beta_pac        = 0.95;""",
    aux_regression_eqtags="'var_yh', 'var_c'",
    aux_regression_eqs="""    [name = 'var_yh']
    yh_ratio_hat = rho_yh_aux*yh_ratio_hat(-1) + a_yh_y*yhat_au(-1) + a_yh_u*u_gap(-1) + eps_var_yh;

    [name = 'var_c']
    c_hat = rho_c_aux*c_hat(-1) + a_c_y*yhat_au(-1) + a_c_i*i_gap(-1) + a_c_pi*pi_au_gap(-1) + a_c_u*u_gap(-1) + a_c_yh*yh_ratio_hat(-1) + eps_var_c;""",
    pac_eq_name='eq_dln_c_pac',
    pac_eq_body="""    diff(ln_c_level) = b0_c*(c_hat(-1) - ln_c_level(-1))
                     + b1_c*diff(ln_c_level(-1))
                     + pac_expectation(pac_c)
                     + b2_c*i_gap(-1)
                     + b3_c*yhat_au
                     + eps_c;""",
    pac_lhs_var='ln_c_level',
)

# ---- aux_business_inv.mod ----
aux_business_inv = aux_template(
    block_name='business_inv',
    pac_name='pac_ib',
    extra_vars="    ib_hat          rKB_hat\n    ln_ib_level",
    extra_shocks="    eps_var_ib      eps_var_rKB     eps_ib",
    extra_params="""    rho_ib_aux      a_ib_y          a_ib_pi         a_ib_u
    rho_rKB_aux     a_rKB_i
    b0_ib           b1_ib           b2_ib           b3_ib
    beta_pac""",
    extra_calib="""rho_ib_aux      = 0.6;           a_ib_y          = 0.15;          a_ib_pi         = 0.04;
a_ib_u          = -0.02;
rho_rKB_aux     = 0.55;          a_rKB_i         = 0.24;
b0_ib           = 0.0180;        b1_ib           = 0.0818;        b2_ib           = 0.0;           b3_ib           = 0.3144;
beta_pac        = 0.98;""",
    aux_regression_eqtags="'var_ib', 'var_rKB'",
    aux_regression_eqs="""    [name = 'var_ib']
    ib_hat = rho_ib_aux*ib_hat(-1) + a_ib_y*yhat_au(-1) + a_ib_pi*pi_au_gap(-1) + a_ib_u*u_gap(-1) + eps_var_ib;

    [name = 'var_rKB']
    rKB_hat = rho_rKB_aux*rKB_hat(-1) + a_rKB_i*i_gap(-1) + eps_var_rKB;""",
    pac_eq_name='eq_dln_ib_pac',
    pac_eq_body="""    diff(ln_ib_level) = b0_ib*(ib_hat(-1) - ln_ib_level(-1))
                      + b1_ib*diff(ln_ib_level(-1))
                      + b2_ib*diff(ln_ib_level(-2))
                      + pac_expectation(pac_ib)
                      + b3_ib*yhat_au
                      + eps_ib;""",
    pac_lhs_var='ln_ib_level',
)

# ---- aux_housing_inv.mod ----
aux_housing_inv = aux_template(
    block_name='housing_inv',
    pac_name='pac_ih',
    extra_vars="    ih_hat\n    ln_ih_level",
    extra_shocks="    eps_var_ih      eps_ih",
    extra_params="""    rho_ih_aux      a_ih_y          a_ih_i          a_ih_pi         a_ih_u
    b0_ih           b1_ih           b2_ih           b3_ih
    beta_pac""",
    extra_calib="""rho_ih_aux      = 0.71;          a_ih_y          = 0.08;          a_ih_i          = -0.08;
a_ih_pi         = 0.05;          a_ih_u          = -0.03;
b0_ih           = 0.0309;        b1_ih           = 0.1080;        b2_ih           = 0.0;           b3_ih           = 0.2322;
beta_pac        = 0.98;""",
    aux_regression_eqtags="'var_ih'",
    aux_regression_eqs="""    [name = 'var_ih']
    ih_hat = rho_ih_aux*ih_hat(-1) + a_ih_y*yhat_au(-1) + a_ih_i*i_gap(-1) + a_ih_pi*pi_au_gap(-1) + a_ih_u*u_gap(-1) + eps_var_ih;""",
    pac_eq_name='eq_dln_ih_pac',
    pac_eq_body="""    diff(ln_ih_level) = b0_ih*(ih_hat(-1) - ln_ih_level(-1))
                      + b1_ih*diff(ln_ih_level(-1))
                      + b2_ih*diff(ln_ih_level(-2))
                      + pac_expectation(pac_ih)
                      + b3_ih*yhat_au
                      + eps_ih;""",
    pac_lhs_var='ln_ih_level',
)

# ---- aux_employment.mod ----
aux_employment = aux_template(
    block_name='employment',
    pac_name='pac_n',
    extra_vars="    n_hat\n    ln_n_level",
    extra_shocks="    eps_var_n       eps_n",
    extra_params="""    rho_n_aux       a_n_y           a_n_i           a_n_pi          a_n_u
    b0_n            b1_n            b2_n            b3_n            b4_n            b5_n
    beta_pac""",
    extra_calib="""rho_n_aux       = 0.67;          a_n_y           = 0.12;          a_n_i           = -0.03;
a_n_pi          = 0.05;          a_n_u           = -0.04;
b0_n            = 0.0578;        b1_n            = 0.3118;        b2_n            = 0.0;           b3_n            = 0.0;           b4_n            = 0.0;           b5_n            = -0.0007;
beta_pac        = 0.98;""",
    aux_regression_eqtags="'var_n'",
    aux_regression_eqs="""    [name = 'var_n']
    n_hat = rho_n_aux*n_hat(-1) + a_n_y*yhat_au(-1) + a_n_i*i_gap(-1) + a_n_pi*pi_au_gap(-1) + a_n_u*u_gap(-1) + eps_var_n;""",
    pac_eq_name='eq_dln_n_pac',
    pac_eq_body="""    diff(ln_n_level) = b0_n*(n_hat(-1) - ln_n_level(-1))
                     + b1_n*diff(ln_n_level(-1))
                     + b2_n*diff(ln_n_level(-2))
                     + b3_n*diff(ln_n_level(-3))
                     + b4_n*diff(ln_n_level(-4))
                     + pac_expectation(pac_n)
                     + b5_n*yhat_au
                     + eps_n;""",
    pac_lhs_var='ln_n_level',
)


def write_all():
    here = pathlib.Path(__file__).parent
    for name, content in [
        ('aux_consumption.mod', aux_consumption),
        ('aux_business_inv.mod', aux_business_inv),
        ('aux_housing_inv.mod', aux_housing_inv),
        ('aux_employment.mod', aux_employment),
    ]:
        (here / name).write_text(content)
        print(f"  wrote {name} ({len(content.splitlines())} lines)")


if __name__ == '__main__':
    write_all()
