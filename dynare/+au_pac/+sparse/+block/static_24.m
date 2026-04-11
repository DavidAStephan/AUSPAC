function [y, T, residual, g1] = static_24(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(11, 1);
  residual(1)=(y(10))-(y(10)*params(7)+y(1)*params(8)+x(3));
  residual(2)=(y(57))-(y(57)*params(93)+y(1)*params(94)+x(26));
  residual(3)=(y(47))-(y(48)*params(73)+y(47)*params(74)+y(4)*params(75)+y(46)*params(76)+params(28)*y(56)+x(19));
  residual(4)=(y(59))-(y(28)*params(97)+y(32)*params(98)+y(37)*params(99)+y(57)*params(100)+y(47)*params(101)-y(49)*params(102));
  residual(5)=(y(46))-(y(46)*params(71)-y(9)*params(72)+params(72)*(y(10)-y(11))+x(18));
  residual(6)=(y(61))-(y(28)*params(109)+y(32)*params(110)+y(37)*params(111)+y(57)*params(112)+y(47)*params(113));
  residual(7)=(y(48))-(y(48)-y(47));
  residual(8)=(y(50))-(y(50)-y(49));
  residual(9)=(y(1))-(params(1)*y(4)+y(1)*params(2)-params(3)*(y(9)-y(10))+params(18)*y(59)+x(1));
  residual(10)=(y(9))-(y(9)*params(4)+(1-params(4))*(y(10)*params(5)+y(1)*params(6))+x(2));
  residual(11)=(y(49))-(y(50)*params(77)+y(49)*params(78)+params(79)*y(61)+y(46)*params(80)+x(20));
if nargout > 3
    g1_v = NaN(30, 1);
g1_v(1)=(-params(8));
g1_v(2)=(-params(94));
g1_v(3)=1-params(2);
g1_v(4)=(-((1-params(4))*params(6)));
g1_v(5)=1-params(93);
g1_v(6)=(-params(100));
g1_v(7)=(-params(112));
g1_v(8)=1-params(74);
g1_v(9)=(-params(101));
g1_v(10)=(-params(113));
g1_v(11)=1;
g1_v(12)=1;
g1_v(13)=(-params(18));
g1_v(14)=(-params(76));
g1_v(15)=1-params(71);
g1_v(16)=(-params(80));
g1_v(17)=1;
g1_v(18)=(-params(79));
g1_v(19)=(-params(73));
g1_v(20)=params(102);
g1_v(21)=1;
g1_v(22)=1-params(78);
g1_v(23)=1-params(7);
g1_v(24)=(-params(72));
g1_v(25)=(-params(3));
g1_v(26)=(-((1-params(4))*params(5)));
g1_v(27)=params(72);
g1_v(28)=params(3);
g1_v(29)=1-params(4);
g1_v(30)=(-params(77));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 11, 11);
end
end
