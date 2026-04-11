function [y, T, residual, g1] = dynamic_14(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(242))-((1+params(146)+params(147)+params(148))*(y(243)-(y(244)*(T(1)*params(147)+T(3)*params(148))+T(3)*params(148)*y(245)))-(y(374)*params(137)*params(146)+T(1)*params(147)*y(390)+T(3)*params(148)*y(391)));
  residual(2)=(y(259))-(y(390));
  residual(3)=(y(258))-(y(374));
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
