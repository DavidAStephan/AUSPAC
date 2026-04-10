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
    T = au_pac.static_g1_tt(T, y, x, params);
end
g1 = zeros(53, 53);
g1(1,2)=(-1);
g1(1,6)=1;
g1(1,9)=1;
g1(2,3)=(-1);
g1(2,7)=1;
g1(2,10)=1;
g1(3,5)=(-1);
g1(3,8)=1;
g1(3,11)=1;
g1(4,1)=1-params(2);
g1(4,4)=(-params(1));
g1(4,9)=params(3);
g1(4,10)=(-params(3));
g1(4,53)=(-params(18));
g1(5,1)=(-((1-params(4))*params(6)));
g1(5,9)=1-params(4);
g1(5,10)=(-((1-params(4))*params(5)));
g1(6,1)=(-params(8));
g1(6,10)=1-params(7);
g1(7,4)=1-params(9);
g1(8,4)=(-params(11));
g1(8,11)=1-params(10);
g1(9,6)=1-params(12);
g1(10,7)=1-params(13);
g1(11,8)=1-params(14);
g1(12,7)=(-(1-params(23)));
g1(12,13)=1-params(23);
g1(13,7)=(-1);
g1(13,14)=1;
g1(14,12)=1;
g1(14,13)=(-1);
g1(15,1)=(-params(21));
g1(15,12)=1-params(20);
g1(15,13)=(-params(22));
g1(15,14)=(-(1-params(20)-params(22)));
g1(15,15)=(-params(19));
g1(16,1)=(-params(25));
g1(16,3)=(-params(26));
g1(16,7)=(-(1-params(24)-params(26)));
g1(16,16)=1-params(24);
g1(17,18)=1-params(34);
g1(18,19)=1;
g1(19,17)=1;
g1(19,18)=(-1);
g1(20,17)=(-1);
g1(20,21)=1;
g1(21,21)=(-1);
g1(21,22)=1;
g1(22,22)=(-1);
g1(22,23)=1;
g1(23,1)=(-params(33));
g1(23,17)=1-params(28);
g1(23,18)=(-params(32));
g1(23,20)=(-params(27));
g1(23,21)=(-params(29));
g1(23,22)=(-params(30));
g1(23,23)=(-params(31));
g1(24,25)=1-params(40);
g1(24,26)=(-(1-params(40)));
g1(25,1)=(-params(41));
g1(25,26)=1;
g1(26,24)=1;
g1(26,25)=(-1);
g1(27,1)=(-params(39));
g1(27,9)=(-params(38));
g1(27,10)=params(38);
g1(27,24)=1-params(36);
g1(27,25)=(-params(37));
g1(27,26)=(-(1-params(36)-params(37)));
g1(27,27)=(-params(35));
g1(28,29)=1-params(48);
g1(28,30)=(-(1-params(48)));
g1(29,30)=1;
g1(29,40)=params(49);
g1(30,28)=1;
g1(30,29)=(-1);
g1(31,28)=(-1);
g1(31,32)=1;
g1(32,1)=(-params(46));
g1(32,9)=(-params(47));
g1(32,10)=params(47);
g1(32,28)=1-params(43);
g1(32,29)=(-params(45));
g1(32,30)=(-(1-params(43)-params(44)-params(45)));
g1(32,31)=(-params(42));
g1(32,32)=(-params(44));
g1(33,34)=1-params(56);
g1(33,35)=(-(1-params(56)));
g1(34,9)=params(57);
g1(34,35)=1;
g1(35,33)=1;
g1(35,34)=(-1);
g1(36,33)=(-1);
g1(36,37)=1;
g1(37,1)=(-params(54));
g1(37,9)=(-params(55));
g1(37,10)=params(55);
g1(37,33)=1-params(51);
g1(37,34)=(-params(53));
g1(37,35)=(-(1-params(51)-params(52)-params(53)));
g1(37,36)=(-params(50));
g1(37,37)=(-params(52));
g1(38,39)=1-params(60);
g1(39,2)=(-(1-params(58)));
g1(39,38)=1-params(58);
g1(39,39)=(-(1-params(58)));
g1(40,38)=(-(1-params(61)));
g1(40,40)=1-params(61);
g1(41,9)=params(64);
g1(41,41)=1-params(63);
g1(42,42)=1;
g1(43,4)=(-params(67));
g1(43,41)=(-params(68));
g1(43,42)=1-params(66);
g1(43,43)=(-params(65));
g1(44,44)=1;
g1(45,1)=(-params(71));
g1(45,41)=(-params(72));
g1(45,44)=1-params(70);
g1(45,45)=(-params(69));
g1(46,7)=(-(1-params(73)-params(74)));
g1(46,12)=(-params(74));
g1(46,46)=1-params(73);
g1(47,7)=(-(1-params(75)-params(76)));
g1(47,12)=(-params(76));
g1(47,47)=1-params(75);
g1(48,7)=(-(1-params(77)-params(78)));
g1(48,12)=(-params(78));
g1(48,48)=1-params(77);
g1(49,7)=(-(1-params(79)-params(80)));
g1(49,12)=(-params(80));
g1(49,41)=(-params(81));
g1(49,49)=1-params(79);
g1(50,7)=(-(1-params(82)-params(83)));
g1(50,12)=(-params(83));
g1(50,41)=(-params(84));
g1(50,50)=1-params(82);
g1(51,1)=(-params(86));
g1(51,51)=1-params(85);
g1(52,7)=(-(1-params(87)-params(88)));
g1(52,12)=(-params(88));
g1(52,52)=1-params(87);
g1(53,24)=(-params(89));
g1(53,28)=(-params(90));
g1(53,33)=(-params(91));
g1(53,42)=(-params(93));
g1(53,44)=params(94);
g1(53,51)=(-params(92));
g1(53,53)=1;

end
