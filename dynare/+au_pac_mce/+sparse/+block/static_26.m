function [y, T, residual, g1] = static_26(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(5, 1);
  T(5)=params(154)*params(137)^5;
  T(6)=params(153)*params(137)^4;
  residual(1)=(y(114))-((1+params(150)+params(151)+params(152)+params(153)+params(154))*(y(115)-(y(116)*(T(5)+T(6)+T(1)*params(151)+T(3)*params(152))+y(117)*(T(5)+T(6)+T(3)*params(152))+y(118)*(T(5)+T(6))+y(119)*T(5)))-(y(114)*params(137)*params(150)+T(1)*params(151)*y(128)+T(3)*params(152)*y(129)+T(6)*y(130)+T(5)*y(131)));
  residual(2)=(y(131))-(y(130));
  residual(3)=(y(130))-(y(129));
  residual(4)=(y(129))-(y(128));
  residual(5)=(y(128))-(y(114));
if nargout > 3
    g1_v = NaN(13, 1);
g1_v(1)=T(6);
g1_v(2)=(-1);
g1_v(3)=1;
g1_v(4)=T(5);
g1_v(5)=1;
g1_v(6)=T(3)*params(152);
g1_v(7)=(-1);
g1_v(8)=1;
g1_v(9)=T(1)*params(151);
g1_v(10)=(-1);
g1_v(11)=1;
g1_v(12)=1+params(137)*params(150);
g1_v(13)=(-1);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 5);
end
end
