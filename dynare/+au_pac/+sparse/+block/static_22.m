function [y, T, residual, g1] = static_22(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(96))-(x(38)+y(84)*params(53)-y(83)+params(54)*y(97));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
