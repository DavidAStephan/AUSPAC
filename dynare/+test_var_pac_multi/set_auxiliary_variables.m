function y = set_auxiliary_variables(y, x, params)
%
% Computes auxiliary variables of the static model
%
y(10)=0;
y(11)=y(10);
y(12)=0;
y(13)=y(12);
y(14)=params(23)+y(1)*params(24)+y(2)*params(25)+y(3)*params(26)+y(4)*params(27)+y(5)*params(28);
y(15)=params(29)+y(1)*params(30)+y(2)*params(31)+y(3)*params(32)+y(4)*params(33)+y(5)*params(34);
end
