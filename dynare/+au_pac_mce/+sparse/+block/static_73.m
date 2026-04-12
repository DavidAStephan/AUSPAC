function [y, T, residual, g1] = static_73(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(112))-(x(11)+y(1)*params(43)+params(37)*(y(108)-y(109))+params(38)*y(113)+params(39)*y(114)+params(40)*y(115)+params(41)*y(116)+y(108)*params(163)+y(136));
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
