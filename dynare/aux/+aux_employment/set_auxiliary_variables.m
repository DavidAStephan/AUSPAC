function y = set_auxiliary_variables(y, x, params)
%
% Computes auxiliary variables of the static model
%
y(15)=0;
y(16)=y(15);
y(17)=y(16);
y(18)=y(17);
y(19)=y(18);
y(20)=params(38)+y(1)*params(39)+y(3)*params(40)+y(2)*params(41)+y(4)*params(42)+y(5)*params(43)+y(6)*params(44)+y(7)*params(45)+y(8)*params(46)+y(9)*params(47)+y(10)*params(48)+y(11)*params(49)+y(12)*params(50)+y(13)*params(51);
end
