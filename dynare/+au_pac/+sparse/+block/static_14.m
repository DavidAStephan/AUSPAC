function [y, T, residual, g1] = static_14(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  residual(1)=(y(15))-(y(13)+y(15)-y(12));
  residual(2)=(y(12))-(y(15)*params(19)+y(12)*params(20)+y(13)*params(22)+y(1)*params(21)+y(14)*(1-params(20)-params(22))+x(9));
if nargout > 3
    g1_v = NaN(3, 1);
g1_v(1)=1;
g1_v(2)=1-params(20);
g1_v(3)=(-params(19));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 2, 2);
end
end
