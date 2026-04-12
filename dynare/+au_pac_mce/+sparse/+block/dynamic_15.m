function [y, T, residual, g1] = dynamic_15(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(282))-((1+params(156)+params(157)+params(158))*(y(283)-(y(284)*(T(1)*params(157)+params(158)*T(3))+params(158)*T(3)*y(285)))-(y(436)*params(151)*params(156)+T(1)*params(157)*y(454)+params(158)*T(3)*y(455)));
  residual(2)=(y(301))-(y(454));
  residual(3)=(y(300))-(y(436));
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
