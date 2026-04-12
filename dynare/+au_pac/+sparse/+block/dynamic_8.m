function [y, T, residual, g1] = dynamic_8(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(6, 1);
  residual(1)=(y(267))-(y(126));
  residual(2)=(y(263))-(y(260)-y(120));
  residual(3)=(y(264))-(y(123));
  residual(4)=(y(266))-(y(125));
  residual(5)=(y(263))-(x(11)+y(230)+y(141)*params(43)+params(37)*(y(83)-y(120))+params(38)*y(264)+params(39)*y(265)+params(40)*y(266)+params(41)*y(267)+y(279));
  residual(6)=(y(265))-(y(124));
if nargout > 3
    g1_v = NaN(11, 1);
g1_v(1)=1;
g1_v(2)=(-params(41));
g1_v(3)=(-1);
g1_v(4)=1;
g1_v(5)=(-params(38));
g1_v(6)=1;
g1_v(7)=(-params(40));
g1_v(8)=1;
g1_v(9)=1;
g1_v(10)=(-params(39));
g1_v(11)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 6, 6);
end
end
