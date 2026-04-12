function [y, T] = dynamic_11(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(152)=params(16)+y(255)-y(115);
  y(188)=y(189)+y(190)+x(15);
  y(207)=params(105)*y(67)+y(152)*params(106)+y(147)*(1-params(105)-params(106))+y(198)*params(107)+y(208)*params(123)+x(27);
  y(194)=y(188)+y(197);
  y(193)=y(188)+y(196);
  y(192)=y(188)+y(195);
  y(204)=params(98)*y(64)+y(152)*params(99)+y(207)*params(120)+y(147)*(1-params(98)-params(99)-params(120))+x(24);
  y(191)=y(192)*params(77)+y(193)*params(78)+y(194)*params(79);
  y(186)=params(62)+y(191)-(y(204)-y(152));
  y(215)=params(131)*y(75)+y(141)*params(132)+y(9)*params(133)+x(33);
  y(253)=y(188)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(113);
  y(250)=params(146)*(1-params(145))+y(188)*(1-params(145))+params(145)*y(110);
  y(251)=y(188)*(1-params(145))+params(145)*y(111);
end
