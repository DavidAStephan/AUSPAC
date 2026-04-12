function [y, T] = dynamic_25(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(173)=y(175)-y(174);
  y(167)=params(23)*y(13)+y(173)*params(24)+params(25)*y(202)+y(161)*(1-params(23)-params(24));
  y(246)=(1-params(143))*y(92)+params(143)*params(141)+y(155)*0.05;
  y(251)=y(204)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(97);
  y(250)=y(204)*(1-params(145))+(1-params(145))*params(147)+params(145)*y(96);
  y(249)=y(204)*(1-params(145))+params(145)*y(95);
  y(248)=params(146)*(1-params(145))+y(204)*(1-params(145))+params(145)*y(94);
  y(231)=params(131)*y(77)+y(155)*params(132)+y(9)*params(133)+x(33);
  y(178)=y(263)-y(109);
  y(228)=y(175)-y(166)-y(174);
  y(255)=y(101)+y(167)-params(16);
  y(180)=y(172)/(1-params(26))-params(118)*y(228);
  y(170)=(1-params(62))*y(16)+y(191)*params(62);
end
