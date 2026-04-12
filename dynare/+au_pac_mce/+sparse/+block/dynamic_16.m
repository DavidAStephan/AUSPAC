function [y, T, residual, g1] = dynamic_16(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(5, 1);
  residual(1)=(y(307))-(y(460));
  residual(2)=(y(306))-(y(459));
  residual(3)=(y(305))-(y(458));
  residual(4)=(y(304))-(y(444));
  T(5)=params(167)*params(151)^4;
  T(6)=params(168)*params(151)^5;
  residual(5)=(y(290))-((1+params(164)+params(165)+params(166)+params(167)+params(168))*(y(291)-(y(292)*(T(6)+T(5)+T(1)*params(165)+T(3)*params(166))+y(293)*(T(6)+T(3)*params(166)+T(5))+y(294)*(T(5)+T(6))+T(6)*y(295)))-(y(444)*params(151)*params(164)+T(1)*params(165)*y(458)+T(3)*params(166)*y(459)+T(5)*y(460)+T(6)*y(461)));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=1;
g1_v(3)=1;
g1_v(4)=1;
g1_v(5)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 5);
end
end
