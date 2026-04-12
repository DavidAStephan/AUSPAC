function [y, T] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(7)=y(2)*params(4)+(1-params(4))*(y(3)*params(5)+y(1)*params(6))+x(2);
  y(8)=y(3)*params(7)+y(1)*params(8)+x(3);
  y(9)=params(9)*y(4)+x(4);
  y(10)=params(10)*y(5)+y(4)*params(11)+x(5);
  y(6)=params(3)*y(9)+params(1)*y(1)-params(2)*(y(2)-y(3))+x(1);
end
