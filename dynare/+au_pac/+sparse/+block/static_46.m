function [y, T, residual, g1] = static_46(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(101))-(x(13)+y(9)*params(54)+y(1)*params(53)+params(49)*(y(74)-y(75))+params(50)*y(102)+params(51)*y(103)+y(108));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(49);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
