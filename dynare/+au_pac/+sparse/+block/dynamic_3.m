function [y, T, residual, g1] = dynamic_3(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(218))-(params(4)*y(78)+(1-params(4))*(params(5)*y(79)+params(6)*y(77))+x(35));
  residual(2)=(y(219))-(params(7)*y(79)+params(8)*y(77)+x(36));
  residual(3)=(y(217))-(params(2)*y(77)-params(3)*(y(78)-y(79))+x(34));
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
