function [y, T, residual, g1] = static_20(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(46))-(y(46)*params(73)+y(12)*params(74)+y(7)*(1-params(73)-params(74))+x(21));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(73);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
