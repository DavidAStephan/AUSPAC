function [y, T, residual, g1] = static_54(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(97))-(x(13)+y(9)*params(59)+y(1)*params(58)+params(54)*(y(82)-y(83))+params(55)*y(98)+params(56)*y(99)+y(82)*params(141)+y(106));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(54);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
