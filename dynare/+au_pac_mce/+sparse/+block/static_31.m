function [y, T, residual, g1] = static_31(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  residual(1)=(y(154))-(y(142));
  residual(2)=(y(142))-((1+params(170)+params(171))*(y(143)-y(144)*T(1)*params(171))-(y(142)*params(151)*params(170)+T(1)*params(171)*y(154)));
if nargout > 3
    g1_v = NaN(4, 1);
g1_v(1)=1;
g1_v(2)=T(1)*params(171);
g1_v(3)=(-1);
g1_v(4)=1+params(151)*params(170);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 2, 2);
end
end
