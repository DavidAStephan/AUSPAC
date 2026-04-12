function [y, T, residual, g1] = static_78(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(81))-(y(89)+0.98*y(81)+(-(params(137)+params(138)+params(139)))*0.02);
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=0.02000000000000002;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
