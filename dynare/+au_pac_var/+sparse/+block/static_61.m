function [y, T, residual, g1] = static_61(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(105))-(x(13)+y(9)*params(59)+y(1)*params(58)+y(88)+params(54)*(y(83)-y(93))+params(55)*y(106)+params(56)*y(107)+y(112));
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
