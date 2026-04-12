function [y, T, residual, g1] = dynamic_9(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(252))-(y(116));
  residual(2)=(y(251))-(y(245)-y(110));
  residual(3)=(y(251))-(x(9)+y(220)+y(136)*params(21)+params(19)*(y(80)-y(110))+params(20)*y(252)+y(270));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=(-params(20));
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
