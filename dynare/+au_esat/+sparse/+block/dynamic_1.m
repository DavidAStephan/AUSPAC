function [y, T] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(20)=y(9)*params(4)+(1-params(4))*(y(10)*params(5)+y(1)*params(6))+x(2);
  y(21)=y(10)*params(7)+y(1)*params(8)+x(3);
  y(15)=params(9)*y(4)+x(4);
  y(22)=params(10)*y(11)+y(4)*params(11)+x(5);
  y(17)=params(12)*y(6)+(1-params(12))*params(15)+x(6);
  y(18)=params(13)*y(7)+(1-params(13))*params(16)+x(7);
  y(19)=params(14)*y(8)+(1-params(14))*params(17)+x(8);
  y(12)=params(1)*y(15)+params(2)*y(1)-params(3)*(y(9)-y(10))+x(1);
  y(13)=y(20)+y(17);
  y(14)=y(21)+y(18);
  y(16)=y(22)+y(19);
end
