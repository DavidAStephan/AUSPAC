function [y, T, residual, g1] = static_82(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(72))-(y(72)*params(110)+(y(21)-y(20))*params(111)+y(7)*(1-params(110)-params(111))+x(29));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(110);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
