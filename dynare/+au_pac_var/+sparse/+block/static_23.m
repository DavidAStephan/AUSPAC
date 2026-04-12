function [y, T, residual, g1] = static_23(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(104))-(x(40)+y(93)*params(63)-y(92)+params(64)*y(105));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
