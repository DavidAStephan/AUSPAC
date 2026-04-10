function [y, T, residual, g1] = static_15(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(49))-(y(49)*params(79)+y(12)*params(80)+y(7)*(1-params(79)-params(80))+y(41)*params(81)+x(24));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(79);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
