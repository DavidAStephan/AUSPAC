function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  y(223)=x(14)+y(9)*params(68)+y(116)*params(67)+y(204)+params(63)*(y(84)-y(94))+params(64)*y(224)+params(65)*y(225)+y(228);
  y(209)=y(94)+y(223);
  y(220)=x(13)+y(9)*params(59)+y(116)*params(58)+y(203)+params(54)*(y(83)-y(93))+params(55)*y(221)+params(56)*y(222)+y(227);
  y(208)=y(93)+y(220);
  y(218)=x(12)+y(202)+y(116)*params(49)+y(9)*params(48)+params(45)*(y(82)-y(92))+params(46)*y(219)+y(226);
  y(184)=params(108)*y(69)+y(116)*params(109)+x(28);
  y(207)=y(92)+y(218);
  y(156)=y(209)-y(94);
  y(151)=y(208)-y(93);
  y(146)=y(207)-y(92);
  y(188)=y(146)*params(124)+y(151)*params(125)+y(156)*params(126)+y(184)*params(127)+y(174)*params(128);
  y(176)=y(62)*params(92)+params(93)*y(61)+params(94)*y(188)+y(173)*params(95)+x(22);
  y(186)=y(146)*params(112)+y(151)*params(113)+y(156)*params(114)+y(184)*params(115)+y(174)*params(116)-y(176)*params(117);
  residual(1)=(y(116))-(params(1)*y(119)+params(2)*y(1)-params(3)*(y(9)-y(10))+params(18)*y(186)+x(1));
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
