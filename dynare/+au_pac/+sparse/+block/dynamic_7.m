function [y, T, residual, g1] = dynamic_7(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(226))-(y(94));
  residual(2)=(y(225))-(y(211)-y(80));
  residual(3)=(y(225))-(x(36)+y(81)*params(45)-y(80)+params(46)*y(226));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=(-params(46));
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
