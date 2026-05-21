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
    T = aux_business_inv.dynamic_g1_tt(T, y, x, params, steady_state, it_);
end
g1 = zeros(20, 54);
g1(1,1)=(-params(2));
g1(1,19)=1;
g1(1,2)=(-params(3));
g1(1,3)=params(3);
g1(1,5)=(-params(1));
g1(1,39)=(-1);
g1(2,1)=(-((1-params(4))*params(6)));
g1(2,2)=(-((1-params(4))*params(5)));
g1(2,3)=(-params(4));
g1(2,21)=1;
g1(2,40)=(-1);
g1(3,1)=(-params(8));
g1(3,2)=(-params(7));
g1(3,20)=1;
g1(3,8)=(-((-params(17))-params(18)));
g1(3,10)=(-params(17));
g1(3,11)=(-params(18));
g1(3,12)=(-params(19));
g1(3,41)=(-1);
g1(4,1)=(-params(16));
g1(4,4)=(-params(15));
g1(4,22)=1;
g1(4,47)=(-1);
g1(5,5)=(-params(9));
g1(5,23)=1;
g1(5,42)=(-1);
g1(6,5)=(-params(11));
g1(6,6)=(-params(10));
g1(6,24)=1;
g1(6,43)=(-1);
g1(7,7)=(-params(12));
g1(7,25)=1;
g1(7,44)=(-1);
g1(8,8)=(-params(13));
g1(8,26)=1;
g1(8,45)=(-1);
g1(9,9)=(-params(14));
g1(9,27)=1;
g1(9,46)=(-1);
g1(10,10)=(-params(23));
g1(10,28)=1;
g1(10,48)=(-1);
g1(11,11)=(-params(24));
g1(11,29)=1;
g1(11,49)=(-1);
g1(12,12)=(-params(25));
g1(12,30)=1;
g1(12,50)=(-1);
g1(13,13)=(-params(26));
g1(13,31)=1;
g1(13,51)=(-1);
g1(14,1)=(-params(30));
g1(14,2)=(-params(31));
g1(14,4)=(-params(32));
g1(14,13)=(-params(27));
g1(14,14)=(-params(29));
g1(14,32)=1;
g1(14,52)=(-1);
g1(15,3)=(-params(34));
g1(15,13)=(-params(28));
g1(15,15)=(-params(33));
g1(15,33)=1;
g1(15,53)=(-1);
g1(16,19)=(-params(38));
g1(16,14)=(-params(35));
g1(16,16)=params(35);
g1(16,54)=(-1);
g1(16,35)=1;
g1(16,36)=(-params(36));
g1(16,37)=(-params(37));
g1(16,38)=(-1);
g1(17,16)=1;
g1(17,34)=(-1);
g1(17,35)=1;
g1(18,17)=(-1);
g1(18,36)=1;
g1(19,18)=(-1);
g1(19,37)=1;
g1(20,1)=(-params(41));
g1(20,2)=(-params(43));
g1(20,3)=(-params(42));
g1(20,4)=(-params(44));
g1(20,5)=(-params(45));
g1(20,6)=(-params(46));
g1(20,7)=(-params(47));
g1(20,8)=(-params(48));
g1(20,9)=(-params(49));
g1(20,10)=(-params(50));
g1(20,11)=(-params(51));
g1(20,12)=(-params(52));
g1(20,13)=(-params(53));
g1(20,14)=(-params(54));
g1(20,15)=(-params(55));
g1(20,38)=1;

end
