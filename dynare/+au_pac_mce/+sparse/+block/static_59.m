function [y, T, residual, g1] = static_59(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(89))-(x(11)+y(1)*params(43)+params(37)*(y(85)-y(86))+params(38)*y(90)+params(39)*y(91)+params(40)*y(92)+params(41)*y(93)+y(85)*params(146)+y(113));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=params(37);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
