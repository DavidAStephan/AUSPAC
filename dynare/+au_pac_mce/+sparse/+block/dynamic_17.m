function [y, T, residual, g1] = dynamic_17(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  residual(1)=(y(308))-(y(450));
  residual(2)=(y(296))-((1+params(170)+params(171))*(y(297)-T(1)*params(171)*y(298))-(y(450)*params(151)*params(170)+T(1)*params(171)*y(462)));
if nargout > 3
    g1_v = NaN(2, 1);
g1_v(1)=1;
g1_v(2)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 2, 2);
end
end
