function [y, T, residual, g1] = static_52(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(93))-(x(11)+y(1)*params(39)+params(33)*(y(79)-y(80))+params(34)*y(94)+params(35)*y(95)+params(36)*y(96)+params(37)*y(97)+y(109));
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
