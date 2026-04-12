function [y, T] = dynamic_1(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(144)=params(9)*y(4)+x(4);
  y(151)=params(10)*y(11)+y(4)*params(11)+x(5);
  y(146)=params(12)*y(6)+(1-params(12))*params(15)+x(6);
  y(147)=params(13)*y(7)+(1-params(13))*params(16)+x(7);
  y(148)=params(14)*y(8)+(1-params(14))*params(17)+x(8);
  y(221)=params(9)*y(81)+x(43);
  y(158)=params(27)*y(18)+x(30);
  y(160)=y(158)/(1-params(26));
  y(154)=y(147);
  y(189)=params(74)*y(49)+params(73)*(1-params(74))+x(16);
  y(195)=(1-params(80))*params(83)+params(80)*y(55)+x(17);
  y(196)=(1-params(81))*params(84)+params(81)*y(56)+x(18);
  y(197)=(1-params(82))*params(85)+params(82)*y(57)+x(19);
  y(208)=params(28)*y(68)+y(144)*0.10+x(31);
  y(247)=(1-params(143))*y(107)+params(143)*params(140);
  y(249)=(1-params(143))*y(109)+params(143)*params(142);
end
