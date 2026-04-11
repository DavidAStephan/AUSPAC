function [y, T] = dynamic_26(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(152)=params(31)*y(21)+y(134)*params(33)+y(154)*params(32)+y(138)*(1-params(31)-params(33))+y(151)*(1-params(31))+x(10);
  y(178)=y(177)-y(46);
  y(150)=y(152)-y(151);
  y(144)=params(23)*y(13)+y(150)*params(24)+params(25)*y(178)+y(138)*(1-params(23)-params(24));
end
