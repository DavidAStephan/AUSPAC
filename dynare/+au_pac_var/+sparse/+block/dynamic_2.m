function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  y(257)=x(14)+y(9)*params(68)+y(138)*params(67)+y(218)+params(63)*(y(93)-y(94))+params(64)*y(258)+params(65)*y(259)+y(262);
  y(252)=x(12)+y(216)+y(138)*params(49)+y(9)*params(48)+params(45)*(y(87)-y(88))+params(46)*y(253)+y(260);
  y(254)=x(13)+y(9)*params(59)+y(138)*params(58)+y(217)+params(54)*(y(90)-y(91))+params(55)*y(255)+params(56)*y(256)+y(261);
  y(206)=params(108)*y(69)+y(138)*params(109)+x(28);
  y(225)=y(88)+y(252);
  y(231)=y(94)+y(257);
  y(168)=y(225)-y(88);
  y(228)=y(91)+y(254);
  y(173)=y(228)-y(91);
  y(178)=y(231)-y(94);
  y(210)=y(168)*params(124)+y(173)*params(125)+y(178)*params(126)+y(206)*params(127)+y(196)*params(128);
  y(198)=y(62)*params(92)+params(93)*y(61)+params(94)*y(210)+y(195)*params(95)+x(22);
  y(208)=y(168)*params(112)+y(173)*params(113)+y(178)*params(114)+y(206)*params(115)+y(196)*params(116)-y(198)*params(117);
  residual(1)=(y(138))-(params(1)*y(141)+params(2)*y(1)-params(3)*(y(9)-y(10))+params(18)*y(208)+x(1));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(18)*(params(49)*params(112)+params(58)*params(113)+params(67)*params(114)+params(109)*params(115)-params(117)*params(94)*(params(49)*params(124)+params(58)*params(125)+params(67)*params(126)+params(109)*params(127)));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
