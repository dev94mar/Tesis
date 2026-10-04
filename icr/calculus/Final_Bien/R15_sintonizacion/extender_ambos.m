% Extiende, por separado y de forma simetrica, el mejor PI y el mejor PII del
% barrido R15 (familias_R15.json) a lo largo del eje de ganancia kK, mas alla del
% limite kK<=3 que fijaba el barrido original, dejando fijos sus ceros de baja
% frecuencia (alpha) y su red de adelanto (beta=1, sin modificar). El objetivo es
% comparar a los dos tipos de controlador con la MISMA receta de extension
% (solo ganancia), en vez de comparar un PII rediseñado a mano (PII_V2) contra un
% PI con una receta distinta.
clear; clc
aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, '..', 'inestable', 'PII_inestable'));
addpath(fullfile(aqui, '..', 'inestable', 'PI_inestable'));
m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;

Spii = zpk(load(fullfile(aqui, '..', 'inestable', 'PII_inestable', 'PII_lic.mat')).C);
Spi  = zpk(load(fullfile(aqui, '..', 'inestable', 'PI_inestable', 'PI.mat')).C);

planta = @(x) tf(ss([0 1; 4*g/(a - x) -c1], [0; 1/(m*b*(a - x)^4)], [1 0], 0));
xs = [-4 -3 -2.5 -2]; Gs = arrayfun(planta, xs, 'UniformOutput', false);

familias = struct();
familias.PI  = struct('z', Spi.Z{1},  'p', Spi.P{1},  'k', Spi.K,  'bajos', [-12.906240226684375], 'alpha', 0.757858283255199);
familias.PII = struct('z', Spii.Z{1}, 'p', Spii.P{1}, 'k', Spii.K, 'bajos', [-4.875 -1.861], 'alpha', 0.435275281648062);

kKs = [1.465 2 2.5 3 3.5 4 4.5 5 5.5 6];

for fam = ["PI","PII"]
  B = familias.(fam);
  fprintf('\n=== %s (alpha=%.4f fijo, beta=1 fijo) ===\n', fam, B.alpha);
  for kK = kKs
    z = B.z;
    for zb = B.bajos, [~, i] = min(abs(z - zb)); z(i) = z(i)*B.alpha; end
    Cz = zpk(z, B.p, B.k*kK);
    pms = zeros(1,4); ok = true;
    for j=1:4
      L=Cz*Gs{j}; if ~isstable(feedback(L,1)), ok=false; break; end
      [~,pm]=margin(L); pms(j)=pm;
    end
    if ~ok || min(pms) < 30
      fprintf('kK=%.3f: NO cumple margen (pm_min=%.1f)\n', kK, min(pms));
      continue
    end
    [Ad,Bd,Cd,Dd] = ssdata(c2d(ss(Cz), T, 'zoh'));
    n = size(Ad,1);
    ueq = m*g*b*(a+2)^4;
    x0c = [Ad-eye(n); Cd] \ [zeros(n,1); ueq];
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
    fprintf('kK=%.3f pm=%.1f | ciclo=%.5f cm atasc=%.3f s sat=%.3f diverge=%d\n', ...
        kK, min(pms), ciclo, atasc, sum(up>=3.5-1e-4)/N, diverge);
  end
end
