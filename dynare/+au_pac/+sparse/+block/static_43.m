function [y, T, residual, g1] = static_43(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(100))-(x(13)+y(9)*params(53)+y(1)*params(52)+params(48)*(y(73)-y(74))+params(49)*y(101)+params(50)*y(102)+y(107));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(48);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
