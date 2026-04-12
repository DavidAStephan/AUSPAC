function [y, T, residual, g1] = static_29(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  residual(1)=(y(145))-(y(125));
  residual(2)=(y(125))-((1+params(153)+params(154))*(y(126)-y(127)*params(154)*T(1))-(y(125)*params(151)*params(153)+params(154)*T(1)*y(145)));
if nargout > 3
    g1_v = NaN(4, 1);
g1_v(1)=1;
g1_v(2)=params(154)*T(1);
g1_v(3)=(-1);
g1_v(4)=1+params(151)*params(153);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 2, 2);
end
end
