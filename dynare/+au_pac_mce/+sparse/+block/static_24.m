function [y, T, residual, g1] = static_24(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  T(1)=params(134)^2;
  T(2)=params(137)*T(1);
  residual(1)=(y(102))-((1+params(136)+params(137))*(y(103)-y(104)*T(2))-(y(102)*params(136)*params(134)+T(2)*y(122)));
  residual(2)=(y(122))-(y(102));
if nargout > 3
    g1_v = NaN(4, 1);
g1_v(1)=1+params(136)*params(134);
g1_v(2)=(-1);
g1_v(3)=T(2);
g1_v(4)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 2, 2);
end
end
