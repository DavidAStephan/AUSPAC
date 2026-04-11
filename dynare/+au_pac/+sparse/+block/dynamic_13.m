function [y, T, residual, g1] = dynamic_13(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(6, 1);
  residual(1)=(y(281))-(y(128));
  residual(2)=(y(280))-(y(127));
  residual(3)=(y(277))-(x(11)+y(153)*params(43)+params(37)*(y(111)-y(112))+params(38)*y(278)+params(39)*y(279)+params(40)*y(280)+params(41)*y(281)+y(293));
  residual(4)=(y(279))-(y(126));
  residual(5)=(y(278))-(y(125));
  residual(6)=(y(277))-(y(264)-y(112));
if nargout > 3
    g1_v = NaN(11, 1);
g1_v(1)=1;
g1_v(2)=(-params(41));
g1_v(3)=1;
g1_v(4)=(-params(40));
g1_v(5)=1;
g1_v(6)=1;
g1_v(7)=(-params(39));
g1_v(8)=1;
g1_v(9)=(-params(38));
g1_v(10)=1;
g1_v(11)=(-1);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 6, 6);
end
end
