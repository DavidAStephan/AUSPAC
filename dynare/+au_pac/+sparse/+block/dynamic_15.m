function [y, T] = dynamic_15(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(242)=y(183)*(1-params(145))+(1-params(145))*params(147)+params(145)*y(107);
  y(159)=y(250)-y(115);
  y(182)=y(181)-y(46);
  y(238)=(1-params(143))*y(103)+params(143)*params(141)+y(136)*0.05;
  y(233)=y(171)*(-params(113))-(y(237)-params(140))+params(137)*(y(240)-(params(15)+params(73)+params(146)));
end
