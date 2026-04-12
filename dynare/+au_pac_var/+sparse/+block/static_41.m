function [y, T, residual, g1] = static_41(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(75))-(y(75)*params(131)+y(1)*params(132)+y(9)*params(133)+x(33));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(131);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
