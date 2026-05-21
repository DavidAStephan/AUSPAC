function [y, T, residual, g1] = static_15(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(16))-(x(15)+y(1)*params(38)+params(33)*(y(14)-y(15))+params(34)*y(17)+params(35)*y(18)+params(36)*y(19)+params(37)*y(20)+y(21));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(33);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
