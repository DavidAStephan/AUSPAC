function [y, T, residual, g1] = static_51(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(100))-(x(14)+y(9)*params(68)+y(1)*params(67)+params(63)*(y(84)-y(85))+params(64)*y(101)+params(65)*y(102)+y(84)*params(145)+y(110));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(63);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
