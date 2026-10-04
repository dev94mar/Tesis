clear; clc
aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, '..', 'inestable', 'PII_inestable'));
addpath(fullfile(aqui, '..', 'inestable', 'PI_inestable'));
m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;
S = load(fullfile(aqui, '..', 'inestable', 'PI_inestable', 'PI.mat'));
Cpi = zpk(S.C); z = Cpi.Z{1}; p = Cpi.P{1}; k = Cpi.K;
[~, i_bajo] = min(abs(z)); i_alto = setdiff(1:numel(z), i_bajo);
p_red = p(abs(p)>1e-9);
z_bajo = z(i_bajo); z_alto = z(i_alto);

casos = [4.00 0.30 1.20;   % menor ciclo (sospechoso: atasc=9.65)
         5.50 1.40 1.15;   % segundo menor ciclo
         1.00 1.40 1.10];  % menor atascamiento
for i=1:size(casos,1)
  kK=casos(i,1); al=casos(i,2); be=casos(i,3);
  zz=[z_bajo*al, z_alto*be]; pp=[0, p_red*be]; Cz=zpk(zz,pp,k*kK);
  [Ad,Bd,Cd,Dd] = ssdata(c2d(ss(Cz), T, 'zoh'));
  n=size(Ad,1); ueq = m*g*b*(a+2)^4;
  x0c = [Ad-eye(n); Cd] \ [zeros(n,1); ueq];
  y0=[-2;0]; u=ueq; uzm=u; N=35000; yp=zeros(N,1); yv=yp;
  for kk=1:N
    [~,y]=ode45(@(t,y) maglev_karnopp(t,y,u), [0 T], y0); y0=y(end,:)';
    Fe=u/(b*max(a-y0(1),1e-6)^4)-m*g;
    if abs(y0(2))<vth && abs(Fe)<=Fs, y0(2)=0; end
    mov=y0(2)~=0; if mov, uzm=u; end
    e = -2 - ((kk-1)*T>=5) - y0(1);
    x0c = Ad*x0c + Bd*e;
    u = min(max(Cd*x0c+Dd*e,0),3.5);
    if mov && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
    yp(kk)=y0(1); yv(kk)=y0(2);
  end
  tl=25001:35000;
  fprintf('kK=%.2f a=%.2f b=%.2f: y_final=%.6f error_final=%.6f min=%.6f max=%.6f quieto_todo=%d\n', ...
      kK,al,be, yp(end), -3-yp(end), min(yp(tl)), max(yp(tl)), all(yv(tl)==0));
end
