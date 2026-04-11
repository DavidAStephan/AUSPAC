function [y, T, residual, g1] = dynamic_5(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(232))-(y(100));
  residual(2)=(y(231))-(y(220)-y(89));
  residual(3)=(y(231))-(x(42)+y(90)*params(37)-y(89)+params(38)*y(232));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=(-params(38));
g1_v(3)=(-1);
g1_v(4)=1;
g1_v(5)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
