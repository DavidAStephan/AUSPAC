function [y, T, residual, g1] = static_25(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  T(3)=params(134)^3;
  T(4)=T(3)*params(145);
  residual(1)=(y(109))-((1+params(143)+params(144)+params(145))*(y(110)-(y(111)*(T(1)*params(144)+T(4))+y(112)*T(4)))-(y(109)*params(134)*params(143)+T(1)*params(144)*y(125)+T(4)*y(126)));
  residual(2)=(y(126))-(y(125));
  residual(3)=(y(125))-(y(109));
if nargout > 3
    g1_v = NaN(7, 1);
g1_v(1)=1+params(134)*params(143);
g1_v(2)=(-1);
g1_v(3)=T(4);
g1_v(4)=1;
g1_v(5)=T(1)*params(144);
g1_v(6)=(-1);
g1_v(7)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
