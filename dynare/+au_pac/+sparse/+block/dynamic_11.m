function [y, T, residual, g1] = dynamic_11(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(228))-(y(96));
  residual(2)=(y(227))-(y(214)-y(83));
  residual(3)=(y(227))-(x(38)+y(84)*params(53)-y(83)+params(54)*y(228));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=(-params(54));
g1_v(3)=(-1);
g1_v(4)=1;
g1_v(5)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
