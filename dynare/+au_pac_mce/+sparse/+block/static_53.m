function [y, T, residual, g1] = static_53(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(96))-(x(13)+y(9)*params(58)+y(1)*params(57)+params(53)*(y(81)-y(82))+params(54)*y(97)+params(55)*y(98)+y(81)*params(138)+y(105));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(53);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
