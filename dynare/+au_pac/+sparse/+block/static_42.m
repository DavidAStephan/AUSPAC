function [y, T, residual, g1] = static_42(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(84))-(y(84)*params(168)+y(77)*params(169)+y(78)*params(170)+y(79)*params(171)+x(41));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(168);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
