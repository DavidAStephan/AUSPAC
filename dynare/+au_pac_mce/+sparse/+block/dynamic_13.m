function [y, T, residual, g1] = dynamic_13(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  T(1)=params(151)^2;
  T(2)=params(154)*T(1);
  residual(1)=(y(279))-((1+params(153)+params(154))*(y(280)-T(2)*y(281))-(y(433)*params(151)*params(153)+T(2)*y(453)));
  residual(2)=(y(299))-(y(433));
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
