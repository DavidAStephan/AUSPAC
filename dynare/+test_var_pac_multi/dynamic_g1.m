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
    T = test_var_pac_multi.dynamic_g1_tt(T, y, x, params, steady_state, it_);
end
g1 = zeros(15, 31);
g1(1,1)=(-params(1));
g1(1,10)=1;
g1(1,2)=params(2);
g1(1,3)=(-params(2));
g1(1,25)=(-1);
g1(2,1)=(-((1-params(3))*params(5)));
g1(2,2)=(-params(3));
g1(2,11)=1;
g1(2,3)=(-((1-params(3))*params(4)));
g1(2,26)=(-1);
g1(3,1)=(-params(7));
g1(3,3)=(-params(6));
g1(3,12)=1;
g1(3,27)=(-1);
g1(4,1)=(-params(9));
g1(4,2)=(-params(10));
g1(4,3)=(-params(11));
g1(4,4)=(-params(8));
g1(4,13)=1;
g1(4,28)=(-1);
g1(5,1)=(-params(13));
g1(5,2)=(-params(14));
g1(5,3)=(-params(15));
g1(5,5)=(-params(12));
g1(5,14)=1;
g1(5,29)=(-1);
g1(6,15)=(-1);
g1(6,6)=(-1);
g1(6,16)=1;
g1(7,17)=(-1);
g1(7,7)=(-1);
g1(7,18)=1;
g1(8,10)=(-params(18));
g1(8,4)=(-params(16));
g1(8,6)=params(16);
g1(8,30)=(-1);
g1(8,19)=1;
g1(8,20)=(-params(17));
g1(8,24)=(-1);
g1(9,10)=(-params(21));
g1(9,5)=(-params(19));
g1(9,7)=params(19);
g1(9,31)=(-1);
g1(9,21)=1;
g1(9,22)=(-params(20));
g1(9,23)=(-1);
g1(10,6)=1;
g1(10,16)=(-1);
g1(10,19)=1;
g1(11,8)=(-1);
g1(11,20)=1;
g1(12,7)=1;
g1(12,18)=(-1);
g1(12,21)=1;
g1(13,9)=(-1);
g1(13,22)=1;
g1(14,1)=(-params(24));
g1(14,2)=(-params(25));
g1(14,3)=(-params(26));
g1(14,4)=(-params(27));
g1(14,5)=(-params(28));
g1(14,23)=1;
g1(15,1)=(-params(30));
g1(15,2)=(-params(31));
g1(15,3)=(-params(32));
g1(15,4)=(-params(33));
g1(15,5)=(-params(34));
g1(15,24)=1;

end
