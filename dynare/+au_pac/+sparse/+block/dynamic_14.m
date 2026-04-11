function [y, T, residual, g1] = dynamic_14(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(6, 1);
  residual(1)=(y(239))-(y(107));
  residual(2)=(y(236))-(y(104));
  residual(3)=(y(235))-(x(11)+y(132)*params(43)+params(37)*(y(90)-y(91))+params(38)*y(236)+params(39)*y(237)+params(40)*y(238)+params(41)*y(239)+y(251));
  residual(4)=(y(238))-(y(106));
  residual(5)=(y(237))-(y(105));
  residual(6)=(y(235))-(y(222)-y(91));
if nargout > 3
    g1_v = NaN(11, 1);
g1_v(1)=1;
g1_v(2)=(-params(41));
g1_v(3)=1;
g1_v(4)=(-params(38));
g1_v(5)=1;
g1_v(6)=1;
g1_v(7)=(-params(40));
g1_v(8)=1;
g1_v(9)=(-params(39));
g1_v(10)=1;
g1_v(11)=(-1);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 6, 6);
end
end
