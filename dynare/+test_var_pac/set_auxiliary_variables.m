function y = set_auxiliary_variables(y, x, params)
%
% Computes auxiliary variables of the static model
%
y(7)=0;
y(8)=y(7);
y(9)=params(17)+y(1)*params(18)+y(2)*params(19)+y(3)*params(20)+y(4)*params(21);
end
