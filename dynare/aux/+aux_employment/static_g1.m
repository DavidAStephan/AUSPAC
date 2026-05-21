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
    T = aux_employment.static_g1_tt(T, y, x, params);
end
g1 = zeros(21, 21);
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
g1(14,2)=(-params(31));
g1(14,3)=(-params(30));
g1(14,4)=(-params(32));
g1(14,13)=(-params(27));
g1(14,14)=1-params(28);
g1(15,1)=(-params(38));
g1(15,14)=(-params(33));
g1(15,15)=params(33);
g1(15,16)=1;
g1(15,17)=(-params(34));
g1(15,18)=(-params(35));
g1(15,19)=(-params(36));
g1(15,20)=(-params(37));
g1(15,21)=(-1);
g1(16,16)=1;
g1(17,16)=(-1);
g1(17,17)=1;
g1(18,17)=(-1);
g1(18,18)=1;
g1(19,18)=(-1);
g1(19,19)=1;
g1(20,19)=(-1);
g1(20,20)=1;
g1(21,1)=(-params(41));
g1(21,2)=(-params(43));
g1(21,3)=(-params(42));
g1(21,4)=(-params(44));
g1(21,5)=(-params(45));
g1(21,6)=(-params(46));
g1(21,7)=(-params(47));
g1(21,8)=(-params(48));
g1(21,9)=(-params(49));
g1(21,10)=(-params(50));
g1(21,11)=(-params(51));
g1(21,12)=(-params(52));
g1(21,13)=(-params(53));
g1(21,14)=(-params(54));
g1(21,21)=1;

end
