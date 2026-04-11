function [y, T] = dynamic_16(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(200)=y(201)+y(202)+x(15);
  y(174)=params(35)*y(22)+y(153)*params(34);
  y(206)=y(200)+y(209);
  y(205)=y(200)+y(208);
  y(204)=y(200)+y(207);
  y(164)=params(16)+y(251)-y(99);
end
