function [y, T, residual, g1] = dynamic_19(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(5, 1);
  T(5)=params(153)*params(137)^4;
  T(6)=params(154)*params(137)^5;
  residual(1)=(y(246))-((1+params(150)+params(151)+params(152)+params(153)+params(154))*(y(247)-(y(248)*(T(6)+T(5)+T(1)*params(151)+T(3)*params(152))+y(249)*(T(6)+T(3)*params(152)+T(5))+y(250)*(T(5)+T(6))+T(6)*y(251)))-(y(378)*params(137)*params(150)+T(1)*params(151)*y(392)+T(3)*params(152)*y(393)+T(5)*y(394)+T(6)*y(395)));
  residual(2)=(y(263))-(y(394));
  residual(3)=(y(262))-(y(393));
  residual(4)=(y(261))-(y(392));
  residual(5)=(y(260))-(y(378));
if nargout > 3
    g1_v = NaN(5, 1);
g1_v(1)=1;
g1_v(2)=1;
g1_v(3)=1;
g1_v(4)=1;
g1_v(5)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 5, 5);
end
end
