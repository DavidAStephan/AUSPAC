function [y, T, residual, g1] = static_56(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(92))-(x(9)+y(1)*params(21)+params(19)*(y(67)-y(68))+params(20)*y(93)+y(111));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(19);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
