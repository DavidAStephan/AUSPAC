function [y, T, residual, g1] = dynamic_14(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(240))-((1+params(143)+params(144)+params(145))*(y(241)-(y(242)*(T(1)*params(144)+T(3)*params(145))+T(3)*params(145)*y(243)))-(y(371)*params(134)*params(143)+T(1)*params(144)*y(387)+T(3)*params(145)*y(388)));
  residual(2)=(y(257))-(y(387));
  residual(3)=(y(256))-(y(371));
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
