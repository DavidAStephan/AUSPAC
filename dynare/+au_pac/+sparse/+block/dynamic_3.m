function [y, T, residual, g1] = dynamic_3(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(270))-(y(117));
  residual(2)=(y(269))-(x(38)+y(105)*params(54)-y(104)+params(55)*y(270));
  residual(3)=(y(269))-(y(256)-y(104));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=(-params(55));
g1_v(3)=1;
g1_v(4)=1;
g1_v(5)=(-1);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
