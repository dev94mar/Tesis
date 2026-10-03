% Valida con ode45 los extremos de la comparación R15 (escalón -2 -> -3 cm).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'inestable', 'PII_inestable'));
F = jsondecode(fileread('familias_R15.json'));
sel = {'PI', 2.5079, 0.7579; 'PII', 1.4651, 0.4353; 'PI', 1, 1; 'PII', 1, 1};
m=0.141;a=7.17184;b=1.6163e-6;g=981;Fs=20;vth=0.02;T=1e-3;N=35000;
for s = 1:size(sel,1)
  k = find(arrayfun(@(c) strcmp(c.familia, sel{s,1}) && abs(c.kK-sel{s,2})<1e-3 && abs(c.alpha-sel{s,3})<1e-3, F), 1);
  c = F(k); Cz = zpk(c.ceros, c.polos, c.k); [A,B,C,D] = ssdata(ss(Cz));
  Ad = c2d(ss(A,B,C,D),T).A; ueq = m*g*b*(a+2)^4;
  x0 = [Ad-eye(size(A)); C] \ [zeros(size(A,1),1); ueq];
  y0=[-2;0]; u=ueq; uzm=u; yp=zeros(N,1); yv=yp;
  for kk=1:N
    [~,y]=ode45(@(t,y) maglev_karnopp(t,y,u),[0 T],y0); y0=y(end,:)';
    Fe=u/(b*max(a-y0(1),1e-6)^4)-m*g; if abs(y0(2))<vth && abs(Fe)<=Fs, y0(2)=0; end
    mov = y0(2)~=0; if mov, uzm=u; end
    e = -2 - ((kk-1)*T>=5) - y0(1);
    [~,xc]=ode45(@(t,x) A*x+B*e,[0 T],x0); x0=xc(end,:)';
    u=min(max(C*x0+D*e,0),3.5); if mov && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
    yp(kk)=y0(1); yv(kk)=y0(2);
  end
  tl = 25001:35000; at = yv(tl)==0; ep = sum(at(2:end) & ~at(1:end-1));
  fprintf('%-3s kK=%.2f a=%.2f | OS %.1f%% ciclo %.4f cm atasc medio %.3f s\n', sel{s,:}, 100*(-3-min(yp(5001:end))), max(yp(tl))-min(yp(tl)), sum(at)*T/max(ep,1));
end
