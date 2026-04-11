function [g1, T_order, T] = static_g1(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T_order, T)
if nargin < 8
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = nk_simple.sparse.static_g1_tt(y, x, params, T_order, T);
g1_v = NaN(7, 1);
g1_v(1)=(-params(2));
g1_v(2)=(-((1-params(4))*params(6)));
g1_v(3)=(-params(1));
g1_v(4)=1-params(3);
g1_v(5)=(-((1-params(4))*params(5)));
g1_v(6)=params(1);
g1_v(7)=1-params(4);
if ~isoctave && matlab_ver_less_than('9.8')
    sparse_rowval = double(sparse_rowval);
    sparse_colval = double(sparse_colval);
end
g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
