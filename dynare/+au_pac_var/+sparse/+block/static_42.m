function [y, T, residual, g1] = static_42(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(85))-(y(85)*params(151)+y(77)*params(152)+y(78)*params(153)+y(79)*params(154)+y(80)*params(155)+y(84)*params(156)+x(39));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(151);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
