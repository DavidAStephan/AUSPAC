function [y, T, residual, g1] = static_32(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(128))-((1+params(156)+params(157)+params(158))*(y(129)-(y(130)*(T(1)*params(157)+params(158)*T(2))+y(131)*params(158)*T(2)))-(y(128)*params(151)*params(156)+T(1)*params(157)*y(146)+params(158)*T(2)*y(147)));
  residual(2)=(y(146))-(y(128));
  residual(3)=(y(147))-(y(146));
if nargout > 3
    g1_v = NaN(7, 1);
g1_v(1)=T(1)*params(157);
g1_v(2)=1;
g1_v(3)=(-1);
g1_v(4)=1+params(151)*params(156);
g1_v(5)=(-1);
g1_v(6)=params(158)*T(2);
g1_v(7)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
