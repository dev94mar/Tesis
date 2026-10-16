% Sondeo de sensibilidad parametrica COMPLETO (extension de sensibilidad_planta.m,
% pendiente 4 de PUBLICABILIDAD.md). Perturba uno a la vez (one-at-a-time, no
% Monte Carlo) los 5 parametros de planta (a, b, c1, m, Fs) en +-5% y +-10%,
% para el PI nominal, el PII nominal y el candidato PII de atascamiento corto
% (kK=1, alpha=2.2, beta=1.05). g=981 cm/s^2 NO se perturba: es una constante
% fisica, no un parametro de incertidumbre del dispositivo.
% Tolerancias e integrador identicos a barrido_conjunto_PI.m/PII.m y a
% sensibilidad_planta.m (ode45 por omision), ventana [25,35] s.
clear; clc
aqui = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(aqui));
base = fullfile(root,'icr','calculus','Final_Bien');
addpath(fullfile(base,'inestable','PII_inestable'));
addpath(fullfile(base,'inestable','PI_inestable'));
addpath(aqui);

m0=0.141; a0=7.17184; b0=1.6163e-6; c10=8.563; g=981; Fs0=20; vth=0.02; T=1e-3;

Spi = load(fullfile(base,'inestable','PI_inestable','PI.mat'));
Cpi_nom = zpk(Spi.C);

Spii = load(fullfile(base,'inestable','PII_inestable','PII_lic.mat'));
Cpii_nom = zpk(Spii.C);
zpii = Cpii_nom.Z{1}; ppii = Cpii_nom.P{1}; kpii = Cpii_nom.K;
bajos = [-4.875 -1.861];
i_bajos = arrayfun(@(zb) find(abs(zpii - zb) == min(abs(zpii - zb)), 1), bajos);
i_alto = setdiff(1:numel(zpii), i_bajos);
i_po = find(abs(ppii) < 1e-9); i_pr = setdiff(1:numel(ppii), i_po);
zalto = zpii(i_alto); pred = ppii(i_pr);
al=2.2; be=1.05; kK=1;
zz_cand = zpii; zz_cand(i_bajos) = zpii(i_bajos)*al; zz_cand(i_alto) = zalto*be;
pp_cand = ppii; pp_cand(i_pr) = pred*be;
Ccand = zpk(zz_cand, pp_cand, kpii*kK);

controllers = struct('name',{'PI_nominal','PII_nominal','PII_candidato_corto'}, ...
    'C', {Cpi_nom, Cpii_nom, Ccand});

params = {'a','b','c1','m','Fs'};
factores = [1.05, 0.95, 1.10, 0.90];
perturbaciones = struct('param',{},'factor',{});
for pp = 1:numel(params)
  for ff = 1:numel(factores)
    perturbaciones(end+1) = struct('param',params{pp},'factor',factores(ff)); %#ok<SAGROW>
  end
end

results = struct('controller',{},'param',{},'factor',{},'a',{},'b',{},'c1',{},'m',{},'Fs',{},'ciclo',{},'atasc',{},'diverge',{});

for ci = 1:numel(controllers)
  Cz = controllers(ci).C;
  [Ad,Bd,Cd,Dd] = ssdata(c2d(ss(Cz), T, 'zoh'));
  n = size(Ad,1);
  for pj = 1:numel(perturbaciones)
    a=a0; b=b0; c1=c10; m=m0; Fs=Fs0;
    switch perturbaciones(pj).param
      case 'a',  a  = a0 *perturbaciones(pj).factor;
      case 'b',  b  = b0 *perturbaciones(pj).factor;
      case 'c1', c1 = c10*perturbaciones(pj).factor;
      case 'm',  m  = m0 *perturbaciones(pj).factor;
      case 'Fs', Fs = Fs0*perturbaciones(pj).factor;
    end
    ueq = m*g*b*(a+2)^4;
    x0c = [Ad-eye(n); Cd] \ [zeros(n,1); ueq];
    y0=[-2;0]; u=ueq; uzm=u; N=35000; yp=zeros(N,1); yv=yp; up=yp;
    for k=1:N
      [~,y]=ode45(@(t,yy) maglev_karnopp_param5(t,yy,u,a,b,c1,m,g,Fs), [0 T], y0);
      y0=y(end,:)';
      Fe=u/(b*max(a-y0(1),1e-6)^4)-m*g;
      if abs(y0(2))<vth && abs(Fe)<=Fs, y0(2)=0; end
      mov=y0(2)~=0; if mov, uzm=u; end
      e = -2 - ((k-1)*T>=5) - y0(1);
      x0c = Ad*x0c + Bd*e;
      u = min(max(Cd*x0c+Dd*e,0),3.5);
      if mov && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
      yp(k)=y0(1); yv(k)=y0(2); up(k)=u;
    end
    tl=25001:35000; at=yv(tl)==0; ep=sum(at(2:end)&~at(1:end-1));
    ciclo=max(yp(tl))-min(yp(tl)); atasc=sum(at)*T/max(ep,1);
    diverge = max(abs(yp))>20 || any(isnan(yp)) || any(isinf(yp));
    q = struct('controller',controllers(ci).name,'param',perturbaciones(pj).param, ...
        'factor',perturbaciones(pj).factor,'a',a,'b',b,'c1',c1,'m',m,'Fs',Fs, ...
        'ciclo',ciclo,'atasc',atasc,'diverge',diverge);
    results(end+1) = q; %#ok<SAGROW>
    fprintf('%s %s x%.2f | ciclo=%.6f atasc=%.4f diverge=%d\n', controllers(ci).name, ...
        perturbaciones(pj).param, perturbaciones(pj).factor, ciclo, atasc, diverge);
    fid = fopen(fullfile(aqui,'sensibilidad_planta_completa.json'), 'w');
    fprintf(fid, '%s', jsonencode(results, 'PrettyPrint', true));
    fclose(fid);
  end
end
fprintf('\nListo: %d simulaciones de sensibilidad completa.\n', numel(results));
