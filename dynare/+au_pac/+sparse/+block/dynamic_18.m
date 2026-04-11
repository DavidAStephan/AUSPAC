function [y, T] = dynamic_18(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(219)=params(105)*y(67)+y(164)*params(106)+y(159)*(1-params(105)-params(106))+y(210)*params(107)+y(220)*params(123)+x(27);
  y(216)=params(98)*y(64)+y(164)*params(99)+y(219)*params(120)+y(159)*(1-params(98)-params(99)-params(120))+x(24);
  y(203)=y(204)*params(77)+y(205)*params(78)+y(206)*params(79);
end
