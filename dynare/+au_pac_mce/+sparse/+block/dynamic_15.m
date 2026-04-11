function [y, T, residual, g1] = dynamic_15(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(2, 1);
  residual(1)=(y(233))-((1+params(136)+params(137))*(y(234)-params(137)*T(1)*y(235))-(y(364)*params(134)*params(136)+params(137)*T(1)*y(384)));
  residual(2)=(y(253))-(y(364));
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
