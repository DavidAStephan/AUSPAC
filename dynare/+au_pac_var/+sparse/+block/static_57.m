function [y, T, residual, g1] = static_57(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(110))-(x(12)+y(1)*params(49)+y(9)*params(48)+params(45)*(y(82)-y(83))+params(46)*y(111)+y(118));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(45);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
