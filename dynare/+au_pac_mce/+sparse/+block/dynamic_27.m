function [y, T] = dynamic_27(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(156)=y(219)-y(87);
  y(207)=params(131)*y(75)+y(133)*params(132)+y(9)*params(133)+x(33);
  y(148)=(1-params(62))*y(16)+y(168)*params(62);
  y(153)=params(31)*y(21)+y(135)*params(33)+y(155)*params(32)+y(139)*(1-params(31)-params(33))+y(152)*(1-params(31))+x(10);
  y(151)=y(153)-y(152);
  y(179)=y(178)-y(46);
  y(145)=params(23)*y(13)+y(151)*params(24)+params(25)*y(179)+y(139)*(1-params(23)-params(24));
end
