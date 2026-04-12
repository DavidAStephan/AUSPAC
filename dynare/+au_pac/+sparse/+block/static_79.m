function [y, T, residual, g1] = static_79(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(125))-(x(13)+y(88)+y(9)*params(59)+y(1)*params(58)+params(54)*(y(83)-y(113))+params(55)*y(126)+params(56)*y(127)+y(132));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(54);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
