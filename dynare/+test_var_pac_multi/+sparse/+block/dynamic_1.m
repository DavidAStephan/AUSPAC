function [y, T] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(16)=params(1)*y(1)-params(2)*(y(2)-y(3))+x(1);
  y(17)=y(2)*params(3)+(1-params(3))*(y(3)*params(4)+y(1)*params(5))+x(2);
  y(18)=y(3)*params(6)+y(1)*params(7)+x(3);
  y(19)=params(8)*y(4)+y(1)*params(9)+y(2)*params(10)+y(3)*params(11)+x(4);
  y(20)=params(12)*y(5)+y(1)*params(13)+y(2)*params(14)+y(3)*params(15)+x(5);
  y(26)=y(10);
  y(28)=y(12);
  y(29)=params(23)+y(1)*params(24)+y(2)*params(25)+y(3)*params(26)+y(4)*params(27)+y(5)*params(28);
  y(30)=params(29)+y(1)*params(30)+y(2)*params(31)+y(3)*params(32)+y(4)*params(33)+y(5)*params(34);
  y(25)=x(6)+y(16)*params(18)+params(16)*(y(4)-y(7))+params(17)*y(26)+y(30);
  y(27)=x(7)+y(16)*params(21)+params(19)*(y(5)-y(9))+params(20)*y(28)+y(29);
  y(24)=y(9)+y(27);
  y(23)=y(24)-y(9);
  y(22)=y(7)+y(25);
  y(21)=y(22)-y(7);
end
