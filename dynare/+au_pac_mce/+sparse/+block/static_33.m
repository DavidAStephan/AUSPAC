function [y, T, residual, g1] = static_33(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(11, 1);
  residual(1)=(y(1))-(params(1)*y(4)+y(1)*params(2)-params(3)*(y(9)-y(10))+params(18)*y(73)+x(1));
  residual(2)=(y(10))-(y(10)*params(7)+y(1)*params(8)+x(3));
  residual(3)=(y(60))-(y(60)*params(86)-y(9)*params(87)+params(87)*(y(10)-y(11))+x(20));
  residual(4)=(y(62))-(y(62)-y(61));
  residual(5)=(y(61))-(y(62)*params(88)+y(61)*params(89)+y(4)*params(90)+y(60)*params(91)+params(29)*y(70)+x(21));
  residual(6)=(y(64))-(y(64)-y(63));
  residual(7)=(y(63))-(y(64)*params(92)+y(63)*params(93)+params(94)*y(75)+y(60)*params(95)+x(22));
  residual(8)=(y(71))-(y(71)*params(108)+y(1)*params(109)+x(28));
  residual(9)=(y(73))-(y(31)*params(112)+y(37)*params(113)+y(42)*params(114)+y(71)*params(115)+y(61)*params(116)-y(63)*params(117));
  residual(10)=(y(75))-(y(31)*params(124)+y(37)*params(125)+y(42)*params(126)+y(71)*params(127)+y(61)*params(128));
  residual(11)=(y(9))-(y(9)*params(4)+(1-params(4))*(y(10)*params(5)+y(1)*params(6))+x(2));
if nargout > 3
    g1_v = NaN(30, 1);
g1_v(1)=(-params(3));
g1_v(2)=1-params(7);
g1_v(3)=(-params(87));
g1_v(4)=(-((1-params(4))*params(5)));
g1_v(5)=1-params(2);
g1_v(6)=(-params(8));
g1_v(7)=(-params(109));
g1_v(8)=(-((1-params(4))*params(6)));
g1_v(9)=1-params(86);
g1_v(10)=(-params(91));
g1_v(11)=(-params(95));
g1_v(12)=(-params(88));
g1_v(13)=1;
g1_v(14)=1-params(89);
g1_v(15)=(-params(116));
g1_v(16)=(-params(128));
g1_v(17)=1;
g1_v(18)=1-params(93);
g1_v(19)=params(117);
g1_v(20)=(-params(92));
g1_v(21)=1-params(108);
g1_v(22)=(-params(115));
g1_v(23)=(-params(127));
g1_v(24)=(-params(18));
g1_v(25)=1;
g1_v(26)=(-params(94));
g1_v(27)=1;
g1_v(28)=params(3);
g1_v(29)=params(87);
g1_v(30)=1-params(4);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 11, 11);
end
end
