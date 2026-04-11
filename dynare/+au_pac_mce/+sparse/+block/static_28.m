function [y, T, residual, g1] = static_28(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  residual(1)=(y(120))-((1+params(156)+params(157))*(y(121)-y(122)*T(1)*params(157))-(y(120)*params(137)*params(156)+T(1)*params(157)*y(132)));
  residual(2)=(y(132))-(y(120));
if nargout > 3
    g1_v = NaN(4, 1);
g1_v(1)=1+params(137)*params(156);
g1_v(2)=(-1);
g1_v(3)=T(1)*params(157);
g1_v(4)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 2, 2);
end
end
