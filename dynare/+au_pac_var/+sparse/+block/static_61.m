function [y, T, residual, g1] = static_61(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(92))-(params(157)*y(92)+y(1)*params(158)+y(10)*params(159)+params(160)*y(22));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(157);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
