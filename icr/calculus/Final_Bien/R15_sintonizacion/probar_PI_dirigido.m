% Prueba dirigida: en vez de combinar kK/alpha/beta al azar, extiende el mejor PI
% del barrido R15 (kK=2.5079, alpha=0.7579, beta=1 fijo) hacia mayor ganancia, y
% por separado libera solo la red de adelanto (beta) con ese mismo kK/alpha. Busca
% si, moviendose en direcciones sensatas desde el optimo ya conocido, el PI alcanza
% a PII_V2 (ciclo 0.011 cm, atasco 0.24 s) sin diverger.
clear; clc
aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, '..', 'inestable', 'PII_inestable'));
addpath(fullfile(aqui, '..', 'inestable', 'PI_inestable'));
m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;
S = load(fullfile(aqui, '..', 'inestable', 'PI_inestable', 'PI.mat'));
Cpi = zpk(S.C); z = Cpi.Z{1}; p = Cpi.P{1}; k = Cpi.K;
[~, i_bajo] = min(abs(z)); i_alto = setdiff(1:numel(z), i_bajo);
z_bajo = z(i_bajo); z_alto = z(i_alto); p_red = p(abs(p)>1e-9);

planta = @(x) tf(ss([0 1; 4*g/(a - x) -c1], [0; 1/(m*b*(a - x)^4)], [1 0], 0));
xs = [-4 -3 -2.5 -2]; Gs = arrayfun(planta, xs, 'UniformOutput', false);

casos = [2.5079 0.7579 1.00;
         3.0    0.7579 1.00;
         3.5    0.7579 1.00;
         4.0    0.7579 1.00;
         2.5079 0.7579 1.10;
         3.0    0.7579 1.10;
         3.5    0.7579 1.10;
         2.5079 1.0    1.10];

for i = 1:size(casos,1)
  kK=casos(i,1); al=casos(i,2); be=casos(i,3);
  zz=[z_bajo*al, z_alto*be]; pp=[0, p_red*be]; Cz=zpk(zz,pp,k*kK);
  pms = zeros(1,4); ok = true;
  for j=1:4
    L=Cz*Gs{j}; if ~isstable(feedback(L,1)), ok=false; break; end
    [~,pm]=margin(L); pms(j)=pm;
  end
  if ~ok || min(pms) < 30
    fprintf('kK=%.3f a=%.3f b=%.2f: NO cumple margen (pm_min=%.1f, ok=%d)\n', kK,al,be,min(pms),ok);
    continue
  end
  [Ad,Bd,Cd,Dd] = ssdata(c2d(ss(Cz), T, 'zoh'));
  ueq = m*g*b*(a+2)^4;
  x0c = [Ad-eye(size(Ad)); Cd] \ [zeros(size(Ad,1),1); ueq];
  y0=[-2;0]; u=ueq; uzm=u; N=35000; yp=zeros(N,1); yv=yp; up=yp;
  for kk=1:N
    [~,y]=ode45(@(t,y) maglev_karnopp(t,y,u), [0 T], y0); y0=y(end,:)';
    Fe=u/(b*max(a-y0(1),1e-6)^4)-m*g;
    if abs(y0(2))<vth && abs(Fe)<=Fs, y0(2)=0; end
    mov=y0(2)~=0; if mov, uzm=u; end
    e = -2 - ((kk-1)*T>=5) - y0(1);
    x0c = Ad*x0c + Bd*e;
    u = min(max(Cd*x0c+Dd*e,0),3.5);
    if mov && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
    yp(kk)=y0(1); yv(kk)=y0(2); up(kk)=u;
  end
  tl=25001:35000; at=yv(tl)==0; ep=sum(at(2:end)&~at(1:end-1));
  ciclo=max(yp(tl))-min(yp(tl)); atasc=sum(at)*T/max(ep,1);
  diverge = max(abs(yp))>20;
  fprintf('kK=%.3f a=%.3f b=%.2f pm=%.1f | ciclo=%.5f cm atasc=%.3f s sat=%.3f diverge=%d\n', ...
      kK,al,be,min(pms), ciclo, atasc, sum(up>=3.5-1e-4)/N, diverge);
end
