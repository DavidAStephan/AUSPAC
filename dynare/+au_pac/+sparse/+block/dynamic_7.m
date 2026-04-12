function [y, T, residual, g1] = dynamic_7(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(6, 1);
  residual(1)=(y(257))-(y(121));
  residual(2)=(y(253))-(y(250)-y(115));
  residual(3)=(y(254))-(y(118));
  residual(4)=(y(256))-(y(120));
  residual(5)=(y(253))-(x(11)+y(221)+y(136)*params(43)+params(37)*(y(81)-y(115))+params(38)*y(254)+params(39)*y(255)+params(40)*y(256)+params(41)*y(257)+y(269));
  residual(6)=(y(255))-(y(119));
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
