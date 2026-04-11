function [y, T, residual, g1] = dynamic_10(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(276))-(y(123));
  residual(2)=(y(275))-(x(9)+y(153)*params(21)+params(19)*(y(98)-y(99))+params(20)*y(276)+y(294));
  residual(3)=(y(275))-(y(251)-y(99));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=(-params(20));
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
