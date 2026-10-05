% Sondeo ACOTADO de sensibilidad parametrica (pendiente 4 de PUBLICABILIDAD.md).
% NO es un analisis de incertidumbre completo: solo perturba b y c1 (los dos
% parametros de planta menos conocidos, porque no los mide este trabajo sino
% que los hereda de Hernandez Alcantara et al. para la configuracion repulsiva)
% +-5% uno a la vez, para el PI nominal, el PII nominal y el candidato PII de
% atascamiento corto (kK=1, alpha=2.2, beta=1.05), y mide si el orden
% PI/PII y la ventaja del candidato sobreviven. Tolerancias e integrador
% identicos a barrido_conjunto_PI.m/PII.m (ode45 por omision), ventana
% [25,35] s.
clear; clc
aqui = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(aqui));
base = fullfile(root,'icr','calculus','Final_Bien');
addpath(fullfile(base,'inestable','PII_inestable'));
addpath(fullfile(base,'inestable','PI_inestable'));

m=0.141; a=7.17184; b0=1.6163e-6; c10=8.563; g=981; Fs=20; vth=0.02; T=1e-3;

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

perturbaciones = struct('param',{'b','b','c1','c1'},'factor',{1.05,0.95,1.05,0.95});

results = struct('controller',{},'param',{},'factor',{},'b',{},'c1',{},'ciclo',{},'atasc',{},'diverge',{});

for ci = 1:numel(controllers)
  Cz = controllers(ci).C;
  [Ad,Bd,Cd,Dd] = ssdata(c2d(ss(Cz), T, 'zoh'));
  n = size(Ad,1);
  for pj = 1:numel(perturbaciones)
    b = b0; c1 = c10;
    if strcmp(perturbaciones(pj).param,'b'), b = b0*perturbaciones(pj).factor; end
    if strcmp(perturbaciones(pj).param,'c1'), c1 = c10*perturbaciones(pj).factor; end
    ueq = m*g*b*(a+2)^4;
    x0c = [Ad-eye(n); Cd] \ [zeros(n,1); ueq];
    y0=[-2;0]; u=ueq; uzm=u; N=35000; yp=zeros(N,1); yv=yp; up=yp;
    for k=1:N
      [~,y]=ode45(@(t,yy) maglev_karnopp_param(t,yy,u,a,b,c1,m,g), [0 T], y0);
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
    diverge = max(abs(yp))>20;
    q = struct('controller',controllers(ci).name,'param',perturbaciones(pj).param, ...
        'factor',perturbaciones(pj).factor,'b',b,'c1',c1,'ciclo',ciclo,'atasc',atasc,'diverge',diverge);
    results(end+1) = q; %#ok<SAGROW>
    fprintf('%s %s x%.2f | ciclo=%.6f atasc=%.4f diverge=%d\n', controllers(ci).name, ...
        perturbaciones(pj).param, perturbaciones(pj).factor, ciclo, atasc, diverge);
    fid = fopen(fullfile(aqui,'sensibilidad_planta.json'), 'w');
    fprintf(fid, '%s', jsonencode(results, 'PrettyPrint', true));
    fclose(fid);
  end
end
fprintf('\nListo: %d simulaciones de sensibilidad.\n', numel(results));
