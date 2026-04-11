function [y, T, residual, g1] = static_32(y, x, params, sparse_rowval, sparse_colval, sparse_colptr, T)
residual=NaN(1, 1);
  residual(1)=(y(67))-(y(67)*params(105)+y(12)*params(106)+y(7)*(1-params(105)-params(106))+y(58)*params(107)+y(68)*params(123)+x(27));
if nargout > 3
    g1_v = NaN(1, 1);
g1_v(1)=1-params(105);
    if ~isoctave && matlab_ver_less_than('9.8')
        sparse_rowval = double(sparse_rowval);
        sparse_colval = double(sparse_colval);
    end
    g1 = sparse(sparse_rowval, sparse_colval, g1_v, 1, 1);
end
end
