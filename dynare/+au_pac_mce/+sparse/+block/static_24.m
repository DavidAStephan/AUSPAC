function [y, T, residual, g1] = static_24(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  T(1)=params(137)^2;
  T(2)=T(1)*params(143);
  T(3)=params(137)^3;
  T(4)=params(144)*T(3);
  residual(1)=(y(106))-((1+params(142)+params(143)+params(144))*(y(107)-(y(108)*(T(2)+T(4))+y(109)*T(4)))-(y(106)*params(137)*params(142)+T(2)*y(124)+T(4)*y(125)));
  residual(2)=(y(125))-(y(124));
  residual(3)=(y(124))-(y(106));
if nargout > 3
    g1_v = NaN(7, 1);
g1_v(1)=1+params(137)*params(142);
g1_v(2)=(-1);
g1_v(3)=T(4);
g1_v(4)=1;
g1_v(5)=T(2);
g1_v(6)=(-1);
g1_v(7)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
