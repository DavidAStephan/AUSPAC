function [y, T, residual, g1] = static_25(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(126))-(y(110));
  residual(2)=(y(110))-((1+params(146)+params(147)+params(148))*(y(111)-(y(112)*(T(1)*params(147)+T(3)*params(148))+y(113)*T(3)*params(148)))-(y(110)*params(137)*params(146)+T(1)*params(147)*y(126)+T(3)*params(148)*y(127)));
  residual(3)=(y(127))-(y(126));
if nargout > 3
    g1_v = NaN(7, 1);
g1_v(1)=1;
g1_v(2)=T(1)*params(147);
g1_v(3)=(-1);
g1_v(4)=(-1);
g1_v(5)=1+params(137)*params(146);
g1_v(6)=T(3)*params(148);
g1_v(7)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
