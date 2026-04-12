function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  y(141)=params(1)*y(144)+params(2)*y(1)-params(3)*(y(9)-y(10))+params(18)*y(211)+x(1);
  y(270)=x(13)+y(232)+y(141)*params(58)+params(54)*(y(86)-y(118))+params(55)*y(271)+params(56)*y(272)+y(277)-y(233)*params(118);
  y(268)=x(12)+y(231)+y(141)*params(49)+y(9)*params(48)+params(45)*(y(85)-y(117))+params(46)*y(269)+y(276);
  y(273)=x(14)+y(9)*params(68)+y(141)*params(67)+y(234)+params(63)*(y(88)-y(119))+params(64)*y(274)+params(65)*y(275)+y(278);
  y(258)=y(118)+y(270);
  y(257)=y(117)+y(268);
  y(171)=y(257)-y(117);
  y(259)=y(119)+y(273);
  y(181)=y(259)-y(119);
  y(176)=y(258)-y(118);
  y(209)=params(108)*y(69)+y(141)*params(109)+x(28);
  y(213)=y(171)*params(124)+y(176)*params(125)+y(181)*params(126)+y(209)*params(127)+y(199)*params(128);
  y(201)=y(62)*params(92)+params(93)*y(61)+params(94)*y(213)+y(198)*params(95)+x(22);
  residual(1)=(y(211))-(y(171)*params(112)+y(176)*params(113)+y(181)*params(114)+y(209)*params(115)+y(199)*params(116)-y(201)*params(117));
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
