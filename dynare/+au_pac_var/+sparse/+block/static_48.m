function [y, T, residual, g1] = static_48(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(112))-(y(48)*(1-params(176))+(1-params(176))*params(178)+params(176)*y(112));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(176);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
