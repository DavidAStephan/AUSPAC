function [y, T, residual, g1] = static_48(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(111))-(x(13)+y(9)*params(58)+y(1)*params(57)+params(53)*(y(84)-y(85))+params(54)*y(112)+params(55)*y(113)+y(118));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(53);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
