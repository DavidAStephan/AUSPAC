function [y, T, residual, g1] = static_66(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(65))-(y(65)*params(100)+y(12)*params(101)+y(7)*(1-params(100)-params(101))+y(57)*params(102)+y(67)*params(30)+x(26));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(100);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
