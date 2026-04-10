function g1 = dynamic_g1(T, y, x, params, steady_state, it_, T_flag)
% function g1 = dynamic_g1(T, y, x, params, steady_state, it_, T_flag)
%
% File created by Dynare Preprocessor from .mod file
%
% Inputs:
%   T             [#temp variables by 1]     double   vector of temporary terms to be filled by function
%   y             [#dynamic variables by 1]  double   vector of endogenous variables in the order stored
%                                                     in M_.lead_lag_incidence; see the Manual
%   x             [nperiods by M_.exo_nbr]   double   matrix of exogenous variables (in declaration order)
%                                                     for all simulation periods
%   steady_state  [M_.endo_nbr by 1]         double   vector of steady state values
%   params        [M_.param_nbr by 1]        double   vector of parameter values in declaration order
%   it_           scalar                     double   time period for exogenous variables for which
%                                                     to evaluate the model
%   T_flag        boolean                    boolean  flag saying whether or not to calculate temporary terms
%
% Output:
%   g1
%

if T_flag
    T = au_esat.dynamic_g1_tt(T, y, x, params, steady_state, it_);
end
g1 = zeros(11, 27);
g1(1,10)=(-1);
g1(1,14)=1;
g1(1,17)=1;
g1(2,11)=(-1);
g1(2,15)=1;
g1(2,18)=1;
g1(3,13)=(-1);
g1(3,16)=1;
g1(3,19)=1;
g1(4,1)=(-params(2));
g1(4,9)=1;
g1(4,12)=(-params(1));
g1(4,6)=params(3);
g1(4,7)=(-params(3));
g1(4,20)=(-1);
g1(5,1)=(-((1-params(4))*params(6)));
g1(5,6)=(-params(4));
g1(5,17)=1;
g1(5,7)=(-((1-params(4))*params(5)));
g1(5,21)=(-1);
g1(6,1)=(-params(8));
g1(6,7)=(-params(7));
g1(6,18)=1;
g1(6,22)=(-1);
g1(7,2)=(-params(9));
g1(7,12)=1;
g1(7,23)=(-1);
g1(8,2)=(-params(11));
g1(8,8)=(-params(10));
g1(8,19)=1;
g1(8,24)=(-1);
g1(9,3)=(-params(12));
g1(9,14)=1;
g1(9,25)=(-1);
g1(10,4)=(-params(13));
g1(10,15)=1;
g1(10,26)=(-1);
g1(11,5)=(-params(14));
g1(11,16)=1;
g1(11,27)=(-1);

end
