function [y, T, residual, g1] = static_26(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(5, 1);
  T(5)=params(151)*params(134)^5;
  T(6)=params(150)*params(134)^4;
  residual(1)=(y(113))-((1+params(147)+params(148)+params(149)+params(150)+params(151))*(y(114)-(y(115)*(T(5)+T(6)+T(1)*params(148)+T(3)*params(149))+y(116)*(T(5)+T(6)+T(3)*params(149))+y(117)*(T(5)+T(6))+y(118)*T(5)))-(y(113)*params(134)*params(147)+T(1)*params(148)*y(127)+T(3)*params(149)*y(128)+T(6)*y(129)+T(5)*y(130)));
  residual(2)=(y(130))-(y(129));
  residual(3)=(y(129))-(y(128));
  residual(4)=(y(128))-(y(127));
  residual(5)=(y(127))-(y(113));
if nargout > 3
    g1_v = NaN(13, 1);
g1_v(1)=1+params(134)*params(147);
g1_v(2)=(-1);
g1_v(3)=T(5);
g1_v(4)=1;
g1_v(5)=T(6);
g1_v(6)=(-1);
g1_v(7)=1;
g1_v(8)=T(3)*params(149);
g1_v(9)=(-1);
g1_v(10)=1;
g1_v(11)=T(1)*params(148);
g1_v(12)=(-1);
g1_v(13)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 5);
end
end
