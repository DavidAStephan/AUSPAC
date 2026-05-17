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
    T = aux_pQ.dynamic_g1_tt(T, y, x, params, steady_state, it_);
end
g1 = zeros(18, 48);
g1(1,1)=(-params(2));
g1(1,17)=1;
g1(1,2)=(-params(3));
g1(1,3)=params(3);
g1(1,5)=(-params(1));
g1(1,35)=(-1);
g1(2,1)=(-((1-params(4))*params(6)));
g1(2,2)=(-((1-params(4))*params(5)));
g1(2,3)=(-params(4));
g1(2,19)=1;
g1(2,36)=(-1);
g1(3,1)=(-params(8));
g1(3,2)=(-params(7));
g1(3,18)=1;
g1(3,8)=(-((-params(17))-params(18)));
g1(3,10)=(-params(17));
g1(3,11)=(-params(18));
g1(3,12)=(-params(19));
g1(3,37)=(-1);
g1(4,1)=(-params(16));
g1(4,4)=(-params(15));
g1(4,20)=1;
g1(4,43)=(-1);
g1(5,5)=(-params(9));
g1(5,21)=1;
g1(5,38)=(-1);
g1(6,5)=(-params(11));
g1(6,6)=(-params(10));
g1(6,22)=1;
g1(6,39)=(-1);
g1(7,7)=(-params(12));
g1(7,23)=1;
g1(7,40)=(-1);
g1(8,8)=(-params(13));
g1(8,24)=1;
g1(8,41)=(-1);
g1(9,9)=(-params(14));
g1(9,25)=1;
g1(9,42)=(-1);
g1(10,10)=(-params(23));
g1(10,26)=1;
g1(10,44)=(-1);
g1(11,11)=(-params(24));
g1(11,27)=1;
g1(11,45)=(-1);
g1(12,12)=(-params(25));
g1(12,28)=1;
g1(12,46)=(-1);
g1(13,13)=(-params(26));
g1(13,29)=1;
g1(13,47)=(-1);
g1(14,29)=(-1);
g1(14,15)=(-1);
g1(14,31)=1;
g1(15,17)=(-params(29));
g1(15,14)=params(27);
g1(15,15)=(-params(27));
g1(15,48)=(-1);
g1(15,32)=1;
g1(15,33)=(-params(28));
g1(15,34)=(-1);
g1(16,14)=1;
g1(16,30)=(-1);
g1(16,32)=1;
g1(17,16)=(-1);
g1(17,33)=1;
g1(18,1)=(-params(32));
g1(18,2)=(-params(34));
g1(18,3)=(-params(33));
g1(18,4)=(-params(35));
g1(18,5)=(-params(36));
g1(18,6)=(-params(37));
g1(18,7)=(-params(38));
g1(18,8)=(-params(39));
g1(18,9)=(-params(40));
g1(18,10)=(-params(41));
g1(18,11)=(-params(42));
g1(18,12)=(-params(43));
g1(18,13)=(-params(44));
g1(18,34)=1;

end
