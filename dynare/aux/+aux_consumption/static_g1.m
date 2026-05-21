function g1 = static_g1(T, y, x, params, T_flag)
% function g1 = static_g1(T, y, x, params, T_flag)
%
% File created by Dynare Preprocessor from .mod file
%
% Inputs:
%   T         [#temp variables by 1]  double   vector of temporary terms to be filled by function
%   y         [M_.endo_nbr by 1]      double   vector of endogenous variables in declaration order
%   x         [M_.exo_nbr by 1]       double   vector of exogenous variables in declaration order
%   params    [M_.param_nbr by 1]     double   vector of parameter values in declaration order
%                                              to evaluate the model
%   T_flag    boolean                 boolean  flag saying whether or not to calculate temporary terms
%
% Output:
%   g1
%

if T_flag
    T = aux_consumption.static_g1_tt(T, y, x, params);
end
g1 = zeros(20, 20);
g1(1,1)=1-params(2);
g1(1,2)=(-params(3));
g1(1,3)=params(3);
g1(1,5)=(-params(1));
g1(2,1)=(-((1-params(4))*params(6)));
g1(2,2)=(-((1-params(4))*params(5)));
g1(2,3)=1-params(4);
g1(3,1)=(-params(8));
g1(3,2)=1-params(7);
g1(3,8)=(-((-params(17))-params(18)));
g1(3,10)=(-params(17));
g1(3,11)=(-params(18));
g1(3,12)=(-params(19));
g1(4,1)=(-params(16));
g1(4,4)=1-params(15);
g1(5,5)=1-params(9);
g1(6,5)=(-params(11));
g1(6,6)=1-params(10);
g1(7,7)=1-params(12);
g1(8,8)=1-params(13);
g1(9,9)=1-params(14);
g1(10,10)=1-params(23);
g1(11,11)=1-params(24);
g1(12,12)=1-params(25);
g1(13,13)=1-params(26);
g1(14,1)=(-params(29));
g1(14,4)=(-params(30));
g1(14,13)=(-params(31));
g1(14,14)=1-params(28);
g1(15,1)=(-params(34));
g1(15,4)=(-params(35));
g1(15,15)=1-params(33);
g1(16,1)=(-params(37));
g1(16,2)=(-params(39));
g1(16,3)=(-params(38));
g1(16,4)=(-params(40));
g1(16,13)=(-params(27));
g1(16,15)=(-params(41));
g1(16,16)=1-params(36);
g1(17,1)=(-params(45));
g1(17,3)=(-params(44));
g1(17,16)=(-params(42));
g1(17,17)=params(42);
g1(17,18)=1;
g1(17,19)=(-params(43));
g1(17,20)=(-1);
g1(18,18)=1;
g1(19,18)=(-1);
g1(19,19)=1;
g1(20,1)=(-params(48));
g1(20,2)=(-params(50));
g1(20,3)=(-params(49));
g1(20,4)=(-params(51));
g1(20,5)=(-params(52));
g1(20,6)=(-params(53));
g1(20,7)=(-params(54));
g1(20,8)=(-params(55));
g1(20,9)=(-params(56));
g1(20,10)=(-params(57));
g1(20,11)=(-params(58));
g1(20,12)=(-params(59));
g1(20,13)=(-params(60));
g1(20,14)=(-params(61));
g1(20,15)=(-params(62));
g1(20,16)=(-params(63));
g1(20,20)=1;

end
