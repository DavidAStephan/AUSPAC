function [y, T, residual, g1] = static_13(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(5, 1);
  residual(1)=(y(20))-(y(18)+y(20)-y(17));
  residual(2)=(y(21))-(y(17));
  residual(3)=(y(22))-(y(21));
  residual(4)=(y(23))-(y(22));
  residual(5)=(y(17))-(y(20)*params(27)+y(17)*params(28)+y(21)*params(29)+y(22)*params(30)+y(23)*params(31)+y(18)*params(32)+y(1)*params(33)+x(11));
if nargout > 3
    g1_v = NaN(12, 1);
g1_v(1)=1;
g1_v(2)=(-1);
g1_v(3)=1-params(28);
g1_v(4)=1;
g1_v(5)=(-1);
g1_v(6)=(-params(29));
g1_v(7)=1;
g1_v(8)=(-1);
g1_v(9)=(-params(30));
g1_v(10)=1;
g1_v(11)=(-params(31));
g1_v(12)=(-params(27));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 5);
end
end
