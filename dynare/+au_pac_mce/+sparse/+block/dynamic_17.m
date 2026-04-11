function [y, T, residual, g1] = dynamic_17(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  residual(1)=(y(262))-(y(381));
  residual(2)=(y(250))-((1+params(153)+params(154))*(y(251)-T(1)*params(154)*y(252))-(y(381)*params(134)*params(153)+T(1)*params(154)*y(393)));
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
