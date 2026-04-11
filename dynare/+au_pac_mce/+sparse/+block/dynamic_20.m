function [y, T, residual, g1] = dynamic_20(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(6, 1);
  residual(1)=(y(224))-(y(92));
  residual(2)=(y(220))-(x(11)+y(132)*params(43)+params(37)*(y(85)-y(86))+params(38)*y(221)+params(39)*y(222)+params(40)*y(223)+params(41)*y(224)+y(85)*params(146)+y(244));
  residual(3)=(y(220))-(y(217)-y(86));
  residual(4)=(y(223))-(y(91));
  residual(5)=(y(222))-(y(90));
  residual(6)=(y(221))-(y(89));
if nargout > 3
    g1_v = NaN(11, 1);
g1_v(1)=1;
g1_v(2)=(-params(41));
g1_v(3)=1;
g1_v(4)=1;
g1_v(5)=(-1);
g1_v(6)=(-params(40));
g1_v(7)=1;
g1_v(8)=(-params(39));
g1_v(9)=1;
g1_v(10)=(-params(38));
g1_v(11)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 6, 6);
end
end
