function [y, T] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(139)=params(9)*y(4)+x(4);
  y(146)=params(10)*y(11)+y(4)*params(11)+x(5);
  y(141)=params(12)*y(6)+(1-params(12))*params(15)+x(6);
  y(142)=params(13)*y(7)+(1-params(13))*params(16)+x(7);
  y(143)=params(14)*y(8)+(1-params(14))*params(17)+x(8);
  y(153)=params(27)*y(18)+x(30);
  y(155)=y(153)/(1-params(26));
  y(149)=y(142);
  y(184)=params(74)*y(49)+params(73)*(1-params(74))+x(16);
  y(190)=(1-params(80))*params(83)+params(80)*y(55)+x(17);
  y(191)=(1-params(81))*params(84)+params(81)*y(56)+x(18);
  y(192)=(1-params(82))*params(85)+params(82)*y(57)+x(19);
  y(203)=params(28)*y(68)+y(139)*0.10+x(31);
  y(237)=(1-params(143))*y(102)+params(143)*params(140);
  y(239)=(1-params(143))*y(104)+params(143)*params(142);
end
