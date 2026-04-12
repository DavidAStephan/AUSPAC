function [y, T, residual, g1] = static_58(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(90))-(params(143)*y(90)+y(1)*params(144)+y(9)*params(145)+y(10)*params(146)+params(147)*y(22));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(143);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
