function [y, T, residual, g1] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(6))-(params(4)*y(3)+(1-params(4))*(y(5)*params(5)+y(4)*params(6))+x(1));
  residual(2)=(y(4))-(y(7)-params(1)*(y(6)-y(8)));
  residual(3)=(y(5))-(y(8)*params(3)+y(4)*params(2));
if nargout > 3
    g1_v = NaN(11, 1);
g1_v(1)=(-params(4));
g1_v(2)=1;
g1_v(3)=params(1);
g1_v(4)=(-((1-params(4))*params(6)));
g1_v(5)=1;
g1_v(6)=(-params(2));
g1_v(7)=(-((1-params(4))*params(5)));
g1_v(8)=1;
g1_v(9)=(-1);
g1_v(10)=(-params(1));
g1_v(11)=(-params(3));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 9);
end
end
