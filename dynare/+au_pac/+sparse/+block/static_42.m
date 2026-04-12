function [y, T, residual, g1] = static_42(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(85))-(y(85)*params(165)+y(77)*params(166)+y(78)*params(167)+y(79)*params(168)+y(80)*params(169)+y(84)*params(170)+x(39));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(165);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
