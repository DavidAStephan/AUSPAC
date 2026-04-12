function [y, T, residual, g1] = static_83(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(130))-(x(13)+y(92)+y(1)*params(58)+params(54)*(y(86)-y(118))+params(55)*y(131)+params(56)*y(132)+y(137)-y(93)*params(118));
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
