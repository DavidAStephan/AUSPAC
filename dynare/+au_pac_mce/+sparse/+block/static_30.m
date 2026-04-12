function [y, T, residual, g1] = static_30(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(5, 1);
  residual(1)=(y(153))-(y(152));
  residual(2)=(y(152))-(y(151));
  residual(3)=(y(151))-(y(150));
  residual(4)=(y(150))-(y(136));
  T(5)=params(168)*params(151)^5;
  T(6)=params(167)*params(151)^4;
  residual(5)=(y(136))-((1+params(164)+params(165)+params(166)+params(167)+params(168))*(y(137)-(y(138)*(T(5)+T(6)+T(1)*params(165)+T(2)*params(166))+y(139)*(T(5)+T(6)+T(2)*params(166))+y(140)*(T(5)+T(6))+y(141)*T(5)))-(y(136)*params(151)*params(164)+T(1)*params(165)*y(150)+T(2)*params(166)*y(151)+T(6)*y(152)+T(5)*y(153)));
if nargout > 3
    g1_v = NaN(13, 1);
g1_v(1)=(-1);
g1_v(2)=1;
g1_v(3)=T(6);
g1_v(4)=(-1);
g1_v(5)=1;
g1_v(6)=T(2)*params(166);
g1_v(7)=(-1);
g1_v(8)=1;
g1_v(9)=T(1)*params(165);
g1_v(10)=(-1);
g1_v(11)=1+params(151)*params(164);
g1_v(12)=1;
g1_v(13)=T(5);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 5);
end
end
