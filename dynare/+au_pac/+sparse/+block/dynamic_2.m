function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  y(123)=params(1)*y(126)+params(2)*y(1)-params(3)*(y(9)-y(10))+params(18)*y(182)+x(1);
  y(226)=x(14)+y(9)*params(63)+y(123)*params(62)+params(58)*(y(77)-y(78))+params(59)*y(227)+params(60)*y(228)+y(231);
  y(180)=params(93)*y(58)+y(123)*params(94)+x(26);
  y(221)=x(12)+y(123)*params(46)+y(9)*params(45)+params(42)*(y(71)-y(72))+params(43)*y(222)+y(229);
  y(194)=y(72)+y(221);
  y(223)=x(13)+y(9)*params(54)+y(123)*params(53)+params(49)*(y(74)-y(75))+params(50)*y(224)+params(51)*y(225)+y(230);
  y(197)=y(75)+y(223);
  y(150)=y(194)-y(72);
  y(154)=y(197)-y(75);
  y(200)=y(78)+y(226);
  y(159)=y(200)-y(78);
  y(184)=y(150)*params(109)+y(154)*params(110)+y(159)*params(111)+y(180)*params(112)+y(170)*params(113);
  y(172)=y(51)*params(77)+params(78)*y(50)+params(79)*y(184)+y(169)*params(80)+x(20);
  residual(1)=(y(182))-(y(150)*params(97)+y(154)*params(98)+y(159)*params(99)+y(180)*params(100)+y(170)*params(101)-y(172)*params(102));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-(params(97)*params(18)*params(46)+params(98)*params(18)*params(53)+params(99)*params(18)*params(62)+params(100)*params(18)*params(94)-params(102)*params(79)*(params(109)*params(18)*params(46)+params(110)*params(18)*params(53)+params(111)*params(18)*params(62)+params(112)*params(18)*params(94)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
