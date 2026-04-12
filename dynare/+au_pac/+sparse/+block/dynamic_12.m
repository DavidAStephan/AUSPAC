function [y, T] = dynamic_12(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(183)=y(184)+y(185)+x(15);
  y(189)=y(183)+y(192);
  y(147)=params(16)+y(245)-y(110);
  y(202)=params(105)*y(67)+y(147)*params(106)+y(142)*(1-params(105)-params(106))+y(193)*params(107)+y(203)*params(123)+x(27);
  y(188)=y(183)+y(191);
  y(187)=y(183)+y(190);
  y(199)=params(98)*y(64)+y(147)*params(99)+y(202)*params(120)+y(142)*(1-params(98)-params(99)-params(120))+x(24);
  y(157)=params(35)*y(22)+y(136)*params(34);
  y(186)=y(187)*params(77)+y(188)*params(78)+y(189)*params(79);
  y(181)=params(62)+y(186)-(y(199)-y(147));
  y(210)=params(131)*y(75)+y(136)*params(132)+y(9)*params(133)+x(33);
  y(243)=y(183)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(108);
  y(240)=params(146)*(1-params(145))+y(183)*(1-params(145))+params(145)*y(105);
  y(241)=y(183)*(1-params(145))+params(145)*y(106);
end
