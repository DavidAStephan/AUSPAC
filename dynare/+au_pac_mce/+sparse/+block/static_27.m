function [y, T, residual, g1] = static_27(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(11, 1);
  residual(1)=(y(57))-(y(57)*params(84)-y(9)*params(85)+params(85)*(y(10)-y(11))+x(20));
  residual(2)=(y(59))-(y(59)-y(58));
  residual(3)=(y(58))-(y(59)*params(86)+y(58)*params(87)+y(4)*params(88)+y(57)*params(89)+params(29)*y(67)+x(21));
  residual(4)=(y(61))-(y(61)-y(60));
  residual(5)=(y(60))-(y(61)*params(90)+y(60)*params(91)+params(92)*y(72)+y(57)*params(93)+x(22));
  residual(6)=(y(9))-(y(9)*params(4)+(1-params(4))*(y(10)*params(5)+y(1)*params(6))+x(2));
  residual(7)=(y(68))-(y(68)*params(106)+y(1)*params(107)+x(28));
  residual(8)=(y(70))-(y(31)*params(110)+y(36)*params(111)+y(41)*params(112)+y(68)*params(113)+y(58)*params(114)-y(60)*params(115));
  residual(9)=(y(72))-(y(31)*params(122)+y(36)*params(123)+y(41)*params(124)+y(68)*params(125)+y(58)*params(126));
  residual(10)=(y(1))-(params(1)*y(4)+y(1)*params(2)-params(3)*(y(9)-y(10))+params(18)*y(70)+x(1));
  residual(11)=(y(10))-(y(10)*params(7)+y(1)*params(8)+x(3));
if nargout > 3
    g1_v = NaN(30, 1);
g1_v(1)=params(85);
g1_v(2)=1-params(4);
g1_v(3)=params(3);
g1_v(4)=(-params(86));
g1_v(5)=1-params(84);
g1_v(6)=(-params(89));
g1_v(7)=(-params(93));
g1_v(8)=(-params(90));
g1_v(9)=(-params(92));
g1_v(10)=1;
g1_v(11)=(-params(85));
g1_v(12)=(-((1-params(4))*params(5)));
g1_v(13)=(-params(3));
g1_v(14)=1-params(7);
g1_v(15)=1-params(106);
g1_v(16)=(-params(113));
g1_v(17)=(-params(125));
g1_v(18)=1;
g1_v(19)=1-params(91);
g1_v(20)=params(115);
g1_v(21)=1;
g1_v(22)=1-params(87);
g1_v(23)=(-params(114));
g1_v(24)=(-params(126));
g1_v(25)=1;
g1_v(26)=(-params(18));
g1_v(27)=(-((1-params(4))*params(6)));
g1_v(28)=(-params(107));
g1_v(29)=1-params(2);
g1_v(30)=(-params(8));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 11, 11);
end
end
