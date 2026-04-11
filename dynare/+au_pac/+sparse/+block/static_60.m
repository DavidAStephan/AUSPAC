function [y, T, residual, g1] = static_60(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(64))-(y(64)*params(98)+y(12)*params(99)+y(67)*params(120)+y(7)*(1-params(98)-params(99)-params(120))+x(24));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(98);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
