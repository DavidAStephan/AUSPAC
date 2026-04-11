function [y, T] = dynamic_20(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(198)=params(62)+y(203)-(y(216)-y(164));
  y(173)=params(31)*y(21)+y(155)*params(33)+y(175)*params(32)+y(159)*(1-params(31)-params(33))+y(172)*(1-params(31))+x(10);
  y(171)=y(173)-y(172);
  y(176)=y(264)-y(112);
  y(242)=(1-params(143))*y(90)+params(143)*params(141)+y(153)*0.05;
  y(247)=y(200)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(95);
  y(246)=y(200)*(1-params(145))+(1-params(145))*params(147)+params(145)*y(94);
  y(245)=y(200)*(1-params(145))+params(145)*y(93);
  y(244)=params(146)*(1-params(145))+y(200)*(1-params(145))+params(145)*y(92);
  y(227)=params(131)*y(75)+y(153)*params(132)+y(9)*params(133)+x(33);
  y(199)=y(198)-y(46);
end
