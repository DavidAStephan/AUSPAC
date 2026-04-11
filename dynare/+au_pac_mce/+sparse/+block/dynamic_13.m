function [y, T, residual, g1] = dynamic_13(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(3, 1);
  residual(1)=(y(255))-(y(385));
  residual(2)=(y(254))-(y(367));
  T(1)=params(134)^2;
  T(2)=T(1)*params(140);
  T(3)=params(134)^3;
  T(4)=params(141)*T(3);
  residual(3)=(y(236))-((1+params(139)+params(140)+params(141))*(y(237)-(y(238)*(T(2)+T(4))+T(4)*y(239)))-(y(367)*params(134)*params(139)+T(2)*y(385)+T(4)*y(386)));
if nargout > 3
    g1_v = NaN(3, 1);
g1_v(1)=1;
g1_v(2)=1;
g1_v(3)=1;
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 3, 3);
end
end
