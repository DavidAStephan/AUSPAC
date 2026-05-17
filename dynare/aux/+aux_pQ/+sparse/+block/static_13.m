function [y, T, residual, g1] = static_13(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(14))-(y(14)*params(23)+y(1)*params(24)+y(3)*params(25)+y(2)*params(26)+y(4)*params(27)+y(13)*params(28)+x(14));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(23);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
