function [y, T] = dynamic_3(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(65)=y(15)*params(19)+params(20)*y(12)+y(66)*params(22)+y(54)*params(21)+(1-params(20)-params(22))*y(14)+x(9);
  y(100)=params(75)*y(47)+y(65)*params(76)+y(60)*(1-params(75)-params(76))+x(22);
  y(101)=params(77)*y(48)+y(65)*params(78)+y(60)*(1-params(77)-params(78))+x(23);
  y(102)=params(79)*y(49)+y(65)*params(80)+y(60)*(1-params(79)-params(80))+y(94)*params(81)+x(24);
  y(70)=y(20)*params(27)+y(17)*params(28)+y(21)*params(29)+y(22)*params(30)+params(31)*y(23)+y(71)*params(32)+y(54)*params(33)+x(11);
  y(103)=params(82)*y(50)+y(65)*params(83)+y(60)*(1-params(82)-params(83))+y(94)*params(84)+x(25);
  y(105)=params(87)*y(52)+y(65)*params(88)+y(60)*(1-params(87)-params(88))+x(27);
  y(99)=params(73)*y(46)+y(65)*params(74)+y(60)*(1-params(73)-params(74))+x(21);
  y(98)=y(45)-y(97);
  y(73)=y(71)+y(20)-y(70);
  y(80)=y(78)+y(27)-y(77);
  y(89)=y(87)+y(36)-y(86);
  y(69)=params(24)*y(16)+y(56)*params(26)+y(54)*params(25)+y(60)*(1-params(24)-params(26))+x(10);
  y(68)=y(66)+y(15)-y(65);
  y(84)=y(82)+y(31)-y(81);
end
