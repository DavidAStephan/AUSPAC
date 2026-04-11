function [y, T, residual, g1] = dynamic_2(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  y(79)=y(54)*params(41);
  y(81)=y(31)*params(42)+y(28)*params(43)+params(44)*y(32)+y(82)*params(45)+y(54)*params(46)+(y(9)-y(10))*params(47)+(1-params(43)-params(44)-params(45))*y(30)+x(13);
  y(97)=y(45)*params(69)+params(70)*y(44)+y(54)*params(71)+y(94)*params(72)+x(20);
  y(104)=params(85)*y(51)+y(54)*params(86)+x(26);
  y(86)=y(36)*params(50)+y(33)*params(51)+params(52)*y(37)+y(87)*params(53)+y(54)*params(54)+(y(9)-y(10))*params(55)+(1-params(51)-params(52)-params(53))*y(35)+x(14);
  y(78)=params(40)*y(25)+(1-params(40))*y(79);
  y(77)=y(27)*params(35)+params(36)*y(24)+y(78)*params(37)+(y(9)-y(10))*params(38)+y(54)*params(39)+(1-params(36)-params(37))*y(26)+x(12);
  y(106)=y(77)*params(89)+y(81)*params(90)+y(86)*params(91)+y(104)*params(92)+y(95)*params(93)-y(97)*params(94);
  residual(1)=(y(54))-(params(1)*y(57)+params(2)*y(1)-params(3)*(y(9)-y(10))+params(18)*y(106)+x(1));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(18)*(params(89)*(params(39)+params(37)*(1-params(40))*params(41))+params(46)*params(90)+params(54)*params(91)+params(86)*params(92)-params(71)*params(94));
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
