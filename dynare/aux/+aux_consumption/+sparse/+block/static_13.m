function [y, T, residual, g1] = static_13(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(14))-(y(14)*params(29)+y(1)*params(30)+y(3)*params(31)+y(2)*params(32)+y(4)*params(33)+y(13)*params(34)+x(14));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(29);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
