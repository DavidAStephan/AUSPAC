function [y, T] = dynamic_23(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(180)=y(181)+y(182)+x(15);
  y(186)=y(180)+y(189);
  y(185)=y(180)+y(188);
  y(184)=y(180)+y(187);
  y(144)=params(16)+y(210)-y(78);
  y(154)=params(35)*y(22)+y(133)*params(34);
  y(199)=params(105)*y(67)+y(144)*params(106)+y(139)*(1-params(105)-params(106))+y(190)*params(107)+y(200)*params(123)+x(27);
  y(196)=params(98)*y(64)+y(144)*params(99)+y(199)*params(120)+y(139)*(1-params(98)-params(99)-params(120))+x(24);
  y(183)=y(184)*params(77)+y(185)*params(78)+y(186)*params(79);
end
