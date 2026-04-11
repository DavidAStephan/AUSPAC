function [y, T, residual, g1] = static_50(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(99))-(x(14)+y(9)*params(67)+y(1)*params(66)+params(62)*(y(83)-y(84))+params(63)*y(100)+params(64)*y(101)+y(83)*params(142)+y(109));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(62);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
