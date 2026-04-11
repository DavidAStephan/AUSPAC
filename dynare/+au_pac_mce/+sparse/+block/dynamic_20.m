function [y, T, residual, g1] = dynamic_20(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(6, 1);
  residual(1)=(y(226))-(y(93));
  residual(2)=(y(223))-(y(90));
  residual(3)=(y(222))-(x(11)+y(133)*params(43)+params(37)*(y(86)-y(87))+params(38)*y(223)+params(39)*y(224)+params(40)*y(225)+params(41)*y(226)+y(86)*params(149)+y(246));
  residual(4)=(y(222))-(y(219)-y(87));
  residual(5)=(y(225))-(y(92));
  residual(6)=(y(224))-(y(91));
if nargout > 3
    g1_v = NaN(11, 1);
g1_v(1)=1;
g1_v(2)=(-params(41));
g1_v(3)=1;
g1_v(4)=(-params(38));
g1_v(5)=1;
g1_v(6)=1;
g1_v(7)=(-1);
g1_v(8)=(-params(40));
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
