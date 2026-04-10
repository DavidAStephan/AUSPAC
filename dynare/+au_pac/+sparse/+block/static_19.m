function [y, T, residual, g1] = static_19(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(47))-(y(47)*params(75)+y(12)*params(76)+y(7)*(1-params(75)-params(76))+x(22));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(75);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
