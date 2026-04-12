function [y, T, residual, g1] = static_28(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(148))-(y(132));
  T(1)=params(151)^2;
  T(2)=params(151)^3;
  T(3)=T(1)*params(161);
  T(4)=T(2)*params(162);
  residual(2)=(y(132))-((1+params(160)+params(161)+params(162))*(y(133)-(y(134)*(T(3)+T(4))+y(135)*T(4)))-(y(132)*params(151)*params(160)+T(3)*y(148)+T(4)*y(149)));
  residual(3)=(y(149))-(y(148));
if nargout > 3
    g1_v = NaN(7, 1);
g1_v(1)=1;
g1_v(2)=T(3);
g1_v(3)=(-1);
g1_v(4)=(-1);
g1_v(5)=1+params(151)*params(160);
g1_v(6)=T(4);
g1_v(7)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
