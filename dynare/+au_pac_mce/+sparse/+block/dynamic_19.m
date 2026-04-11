function [y, T, residual, g1] = dynamic_19(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(5, 1);
  T(5)=params(150)*params(134)^4;
  T(6)=params(151)*params(134)^5;
  residual(1)=(y(244))-((1+params(147)+params(148)+params(149)+params(150)+params(151))*(y(245)-(y(246)*(T(6)+T(5)+T(1)*params(148)+T(3)*params(149))+y(247)*(T(6)+T(3)*params(149)+T(5))+y(248)*(T(5)+T(6))+T(6)*y(249)))-(y(375)*params(134)*params(147)+T(1)*params(148)*y(389)+T(3)*params(149)*y(390)+T(5)*y(391)+T(6)*y(392)));
  residual(2)=(y(261))-(y(391));
  residual(3)=(y(260))-(y(390));
  residual(4)=(y(259))-(y(389));
  residual(5)=(y(258))-(y(375));
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
