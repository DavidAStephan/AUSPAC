function [y, T, residual, g1] = static_50(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(52))-(y(52)*params(81)+y(12)*params(82)+params(104)*y(56)+y(57)*params(107)+y(7)*(1-params(81)-params(82)-params(104))+x(21));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(81);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
