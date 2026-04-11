function [y, T, residual, g1] = static_43(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(21))-(y(21)*params(31)+y(3)*params(33)+y(23)*params(32)+y(7)*(1-params(31)-params(33))+y(20)*(1-params(31))+x(10));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(31);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
