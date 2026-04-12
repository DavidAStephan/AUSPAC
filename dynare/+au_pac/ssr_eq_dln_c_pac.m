function [s, fake1, fake2, fake3, fake4] = ssr_eq_dln_c_pac(params, data, M_, oo_)

% Evaluates the sum of square residuals for equation eq_dln_c_pac.
% File created by Dynare (12-Apr-2026 20:49:00).

fake1 = 0;
fake2 = [];
fake3 = [];
fake4 = [];

M_.params(45) = params(1);
M_.params(46) = params(2);
M_.params(48) = params(3);
M_.params(49) = params(4);

M_ = pac.update.parameters('pac_c', M_, oo_, false);

r = data(2:end,2)-(+data(2:end,69)+data(2:end,80).*M_.params(49)+data(1:end-1,45).*M_.params(48)+M_.params(45).*(data(1:end-1,16)-data(1:end-1,50))+M_.params(46).*data(2:end,7)+M_.params(182)+data(1:end-1,78).*M_.params(183)+data(1:end-1,46).*M_.params(184)+data(1:end-1,65).*M_.params(185)+data(1:end-1,77).*M_.params(186)+data(1:end-1,82).*M_.params(187)+data(1:end-1,62).*M_.params(188)+data(1:end-1,54).*M_.params(189)+data(1:end-1,79).*M_.params(190)+data(1:end-1,16).*M_.params(191)+data(1:end-1,47).*M_.params(192)+data(1:end-1,75).*M_.params(193)+data(1:end-1,49).*M_.params(194));
s = r'*r;
