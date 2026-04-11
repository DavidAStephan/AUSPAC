function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  y(133)=params(1)*y(136)+params(2)*y(1)-params(3)*(y(9)-y(10))+params(18)*y(203)+x(1);
  y(201)=params(108)*y(69)+y(133)*params(109)+x(28);
  y(242)=x(12)+y(133)*params(49)+y(9)*params(48)+params(45)*(y(82)-y(83))+params(46)*y(243)+y(250);
  y(247)=x(14)+y(9)*params(68)+y(133)*params(67)+params(63)*(y(88)-y(89))+params(64)*y(248)+params(65)*y(249)+y(252);
  y(244)=x(13)+y(9)*params(59)+y(133)*params(58)+params(54)*(y(85)-y(86))+params(55)*y(245)+params(56)*y(246)+y(251);
  y(218)=y(86)+y(244);
  y(215)=y(83)+y(242);
  y(163)=y(215)-y(83);
  y(168)=y(218)-y(86);
  y(221)=y(89)+y(247);
  y(173)=y(221)-y(89);
  y(205)=y(163)*params(124)+y(168)*params(125)+y(173)*params(126)+y(201)*params(127)+y(191)*params(128);
  y(193)=y(62)*params(92)+params(93)*y(61)+params(94)*y(205)+y(190)*params(95)+x(22);
  residual(1)=(y(203))-(y(163)*params(112)+y(168)*params(113)+y(173)*params(114)+y(201)*params(115)+y(191)*params(116)-y(193)*params(117));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-(params(112)*params(18)*params(49)+params(113)*params(18)*params(58)+params(114)*params(18)*params(67)+params(115)*params(18)*params(109)-params(117)*params(94)*(params(124)*params(18)*params(49)+params(125)*params(18)*params(58)+params(126)*params(18)*params(67)+params(127)*params(18)*params(109)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
