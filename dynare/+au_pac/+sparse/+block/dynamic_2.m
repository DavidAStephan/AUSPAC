function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  y(219)=x(12)+y(122)*params(45)+y(9)*params(44)+params(41)*(y(70)-y(71))+params(42)*y(220)+y(227);
  y(192)=y(71)+y(219);
  y(224)=x(14)+y(9)*params(63)+y(122)*params(62)+params(58)*(y(76)-y(77))+params(59)*y(225)+params(60)*y(226)+y(229);
  y(149)=y(192)-y(71);
  y(221)=x(13)+y(9)*params(53)+y(122)*params(52)+params(48)*(y(73)-y(74))+params(49)*y(222)+params(50)*y(223)+y(228);
  y(195)=y(74)+y(221);
  y(178)=params(93)*y(57)+y(122)*params(94)+x(26);
  y(198)=y(77)+y(224);
  y(153)=y(195)-y(74);
  y(158)=y(198)-y(77);
  y(182)=y(149)*params(109)+y(153)*params(110)+y(158)*params(111)+y(178)*params(112)+y(168)*params(113);
  y(170)=y(50)*params(77)+params(78)*y(49)+params(79)*y(182)+y(167)*params(80)+x(20);
  y(180)=y(149)*params(97)+y(153)*params(98)+y(158)*params(99)+y(178)*params(100)+y(168)*params(101)-y(170)*params(102);
  residual(1)=(y(122))-(params(1)*y(125)+params(2)*y(1)-params(3)*(y(9)-y(10))+params(18)*y(180)+x(1));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(18)*(params(45)*params(97)+params(52)*params(98)+params(62)*params(99)+params(94)*params(100)-params(102)*params(79)*(params(45)*params(109)+params(52)*params(110)+params(62)*params(111)+params(94)*params(112)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
