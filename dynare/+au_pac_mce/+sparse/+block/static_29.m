function [y, T, residual, g1] = static_29(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(105))-((1+params(139)+params(140)+params(141))*(y(106)-(y(107)*(T(1)*params(140)+params(141)*T(3))+y(108)*params(141)*T(3)))-(y(105)*params(134)*params(139)+T(1)*params(140)*y(123)+params(141)*T(3)*y(124)));
  residual(2)=(y(123))-(y(105));
  residual(3)=(y(124))-(y(123));
if nargout > 3
    g1_v = NaN(7, 1);
g1_v(1)=1+params(134)*params(139);
g1_v(2)=(-1);
g1_v(3)=T(1)*params(140);
g1_v(4)=1;
g1_v(5)=(-1);
g1_v(6)=params(141)*T(3);
g1_v(7)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
