% forecast_eval.m — reproducible pseudo-out-of-sample forecast evaluation (Wave 4)
%
% The original full-system pseudo-real-time driver was lost when the MCMC/Kalman
% pipeline was removed (cleanup 7995ce7), and the production model no longer carries a
% varobs/estimation interface to map data -> states. This script provides an honest,
% reproducible REPLACEMENT in the spirit of the equation-by-equation OLS methodology:
% a recursive 1-step-ahead forecast comparison on the model observables.
%
% For every observable it reports recursive 1-step RMSE for three naive benchmarks
% (random walk; recursive AR(1); unconditional mean = 0 in gap form). For the two
% observables whose model equation is a clean PREDETERMINED autoregression — the CPI
% Phillips (pi_au) and the E-SAT IS curve (yhat_au) — it also reports the MODEL's
% fixed-coefficient 1-step forecast (structural shocks are unforecastable, so the
% predetermined component is the model's conditional mean). This shows whether the
% AU-estimated equations beat naive benchmarks out of sample.
%
% Evaluation window: the last 24 one-step transitions (~2018Q1-2023Q4, matching paper
% Table 5.8). Coefficients are held fixed (no per-origin re-estimation), as in the paper.

E = load('/Users/davidstephan/Documents/AUSPAC/dynare/estimation_data.mat');
obs = {'pi_au','pi_w','yhat_au','dln_c','dln_ib','i_au','i_10y','yhat_us','pi_us'};
NW  = 24;                              % evaluation window (origins): last 24 transitions
T   = numel(E.pi_au);
ev  = (T-NW+1):T;                      % forecast targets t; origin is t-1

% Fixed AU model coefficients (from au_pac.mod)
lambda_pi = 0.2588; kappa_pi = -0.0336;                 % CPI Phillips (var_pi_au_gap)
lambda_q  = 0.6959; sigma_q  = 0.0648; delta = 0.1989;  % E-SAT IS curve (var_yhat_au)

rmse = @(e) sqrt(mean(e.^2));

fid = fopen('/Users/davidstephan/Documents/AUSPAC/dynare/results_forecast_eval.txt','w');
w = @(varargin) fprintf(fid,varargin{:}) + fprintf(varargin{:});
w('Pseudo-out-of-sample 1-step forecast RMSE (Wave 4 reproducible reconstruction)\n');
w('Window: last %d transitions of estimation_data.mat (~2018Q1-2023Q4); fixed coefficients.\n\n', NW);
w('%-10s  %8s %8s %8s   %8s\n','obs','RW','AR(1)','mean=0','MODEL');

for k = 1:numel(obs)
    y = E.(obs{k})(:);
    e_rw = []; e_ar = []; e_mn = []; e_md = [];
    for t = ev
        % --- naive benchmarks ---
        e_rw(end+1) = y(t) - y(t-1);                          % random walk
        ar = y(1:t-1); Y=ar(2:end); X=[ones(numel(Y),1) ar(1:end-1)];
        b = X\Y; e_ar(end+1) = y(t) - [1 y(t-1)]*b;           % recursive AR(1)
        e_mn(end+1) = y(t) - 0;                                % unconditional mean (gap form)
        % --- model structural 1-step (predetermined component only) ---
        switch obs{k}
            case 'pi_au'
                e_md(end+1) = y(t) - (lambda_pi*y(t-1) + kappa_pi*E.yhat_au(t-1));
            case 'yhat_au'
                fc = lambda_q*y(t-1) - sigma_q*(E.i_au(t-1)-E.pi_au(t-1)) + delta*E.yhat_us(t-1);
                e_md(end+1) = y(t) - fc;
        end
    end
    if isempty(e_md)
        w('%-10s  %8.4f %8.4f %8.4f   %8s\n', obs{k}, rmse(e_rw), rmse(e_ar), rmse(e_mn), '-');
    else
        w('%-10s  %8.4f %8.4f %8.4f   %8.4f\n', obs{k}, rmse(e_rw), rmse(e_ar), rmse(e_mn), rmse(e_md));
    end
end
w('\nNotes: gap-form observables (demeaned), so "mean=0" is the unconditional-mean forecast.\n');
w('MODEL column = fixed-coef predetermined 1-step forecast (pi_au: CPI Phillips; yhat_au: IS curve).\n');
w('A MODEL RMSE below RW/AR(1) indicates the AU-estimated equation has genuine 1-step OOS skill.\n');
fclose(fid);
fprintf('Wrote results_forecast_eval.txt\n');
