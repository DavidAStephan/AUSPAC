function [y, T, residual, g1] = static_54(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(94))-(x(11)+y(1)*params(40)+params(34)*(y(80)-y(81))+params(35)*y(95)+params(36)*y(96)+params(37)*y(97)+params(38)*y(98)+y(110));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(34);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
