function [y, T, residual, g1] = static_62(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(120))-(x(14)+y(9)*params(68)+y(1)*params(67)+y(81)+params(63)*(y(93)-y(94))+params(64)*y(121)+params(65)*y(122)+y(125));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(63);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
