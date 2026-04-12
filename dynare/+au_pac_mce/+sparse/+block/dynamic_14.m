function [y, T, residual, g1] = dynamic_14(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  T(3)=params(151)^3;
  T(4)=T(3)*params(162);
  residual(1)=(y(286))-((1+params(160)+params(161)+params(162))*(y(287)-(y(288)*(T(1)*params(161)+T(4))+T(4)*y(289)))-(y(440)*params(151)*params(160)+T(1)*params(161)*y(456)+T(4)*y(457)));
  residual(2)=(y(303))-(y(456));
  residual(3)=(y(302))-(y(440));
if nargout > 3
    g1_v = NaN(3, 1);
g1_v(1)=1;
g1_v(2)=1;
g1_v(3)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
