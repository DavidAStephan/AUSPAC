function [y, T] = dynamic_17(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(179)=params(70)*y(48)+(1-params(70))*(y(133)+y(180))+x(15);
  y(184)=y(179)+y(187);
  y(183)=y(179)+y(186);
  y(182)=y(179)+y(185);
  y(143)=params(16)+y(209)-y(78);
  y(153)=params(35)*y(22)+y(132)*params(34);
  y(197)=params(103)*y(66)+y(143)*params(104)+y(138)*(1-params(103)-params(104))+y(188)*params(105)+y(198)*params(121)+x(27);
  y(194)=params(96)*y(63)+y(143)*params(97)+y(197)*params(118)+y(138)*(1-params(96)-params(97)-params(118))+x(24);
  y(181)=y(182)*params(75)+y(183)*params(76)+y(184)*params(77);
  y(177)=params(61)+y(181)-(y(194)-y(143));
end
