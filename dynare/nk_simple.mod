// Simple 3-equation NK model for forward guidance puzzle comparison
// Standard Taylor rule ensures determinacy

var x pi i_gap;
varexo eps_i;
parameters sigma_nk kappa_nk beta_nk rho_i_nk phi_pi phi_x;

sigma_nk = 1.0;
kappa_nk = 0.3;
beta_nk = 0.99;
rho_i_nk = 0.80;
phi_pi = 1.5;   // Taylor principle: react >1 to inflation
phi_x = 0.5;    // output gap reaction

model;
    x = x(+1) - sigma_nk * (i_gap - pi(+1));
    pi = beta_nk * pi(+1) + kappa_nk * x;
    i_gap = rho_i_nk * i_gap(-1) + (1 - rho_i_nk) * (phi_pi * pi + phi_x * x) + eps_i;
end;

steady_state_model;
    x = 0; pi = 0; i_gap = 0;
end;

steady; check;

shocks;
    var eps_i; stderr 0.0625;
end;

stoch_simul(order=1, irf=40, nograph, noprint) x pi;
