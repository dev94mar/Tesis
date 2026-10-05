% Revalida con tolerancias estrictas de integracion TODOS los puntos de las
% fronteras de Pareto publicadas de PI y PII (icr/context/tesis, fig:fronteras),
% para el pendiente 1 de PUBLICABILIDAD.md ("revalidar las fronteras con
% criterios comunes"). Reconstruye cada controlador exactamente como
% barrido_conjunto_PI.m / barrido_conjunto_PII.m, simula con
% RelTol=1e-9, AbsTol=1e-11, MaxStep=T/10 en la ventana original [25,35] s,
% y compara contra el valor original (tolerancias por omision de ode45).
clear; clc
aqui = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(aqui));
base = fullfile(root,'icr','calculus','Final_Bien','R15_sintonizacion');
addpath(fullfile(root,'icr','calculus','Final_Bien','inestable','PII_inestable'));
addpath(fullfile(root,'icr','calculus','Final_Bien','inestable','PI_inestable'));

m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;

params = jsondecode(fileread(fullfile(aqui,'frontera_params.json')));

Spi = load(fullfile(root,'icr','calculus','Final_Bien','inestable','PI_inestable','PI.mat'));
Cpi = zpk(Spi.C); zpi = Cpi.Z{1}; ppi = Cpi.P{1}; kpi = Cpi.K;
[~, i_bajo_pi] = min(abs(zpi)); i_alto_pi = setdiff(1:numel(zpi), i_bajo_pi);
i_po_pi = find(abs(ppi) < 1e-9); i_pr_pi = setdiff(1:numel(ppi), i_po_pi);
zbajo_pi = zpi(i_bajo_pi); zalto_pi = zpi(i_alto_pi); pred_pi = ppi(i_pr_pi);

Spii = load(fullfile(root,'icr','calculus','Final_Bien','inestable','PII_inestable','PII_lic.mat'));
Cpii = zpk(Spii.C); zpii = Cpii.Z{1}; ppii = Cpii.P{1}; kpii = Cpii.K;
bajos = [-4.875 -1.861];
i_bajos_pii = arrayfun(@(zb) find(abs(zpii - zb) == min(abs(zpii - zb)), 1), bajos);
i_alto_pii = setdiff(1:numel(zpii), i_bajos_pii);
i_po_pii = find(abs(ppii) < 1e-9); i_pr_pii = setdiff(1:numel(ppii), i_po_pii);
zalto_pii = zpii(i_alto_pii); pred_pii = ppii(i_pr_pii);

results = struct('family',{},'kK',{},'alpha',{},'beta',{},'ciclo_original',{},'atasc_original',{}, ...
    'ciclo_estricto',{},'atasc_estricto',{},'diverge',{});

for fam = {'PI','PII'}
  f = fam{1};
  pts = params.(f);
  for idx = 1:numel(pts)
    p = pts(idx);
    kK = p.kK; al = p.alpha; be = p.beta;
    if strcmp(f,'PI')
      zz = [zbajo_pi*al, zalto_pi*be]; pp = [0, pred_pi*be]; kk = kpi*kK;
    else
      zz = zpii; zz(i_bajos_pii) = zpii(i_bajos_pii)*al; zz(i_alto_pii) = zpii(i_alto_pii)*be;
      pp = ppii; pp(i_pr_pii) = ppii(i_pr_pii)*be; kk = kpii*kK;
    end
    Cz = zpk(zz, pp, kk);
    [Ad,Bd,Cd,Dd] = ssdata(c2d(ss(Cz), T, 'zoh'));
    n = size(Ad,1);
    ueq = m*g*b*(a+2)^4;
    x0c = [Ad-eye(n); Cd] \ [zeros(n,1); ueq];
    y0=[-2;0]; u=ueq; uzm=u; N=35000; yp=zeros(N,1); yv=yp; up=yp;
    opt = odeset('RelTol',1e-9,'AbsTol',1e-11,'MaxStep',T/10);
    for kk_step=1:N
      [~,y]=ode45(@(t,y) maglev_karnopp(t,y,u), [0 T], y0, opt); y0=y(end,:)';
      Fe=u/(b*max(a-y0(1),1e-6)^4)-m*g;
      if abs(y0(2))<vth && abs(Fe)<=Fs, y0(2)=0; end
      mov=y0(2)~=0; if mov, uzm=u; end
      e = -2 - ((kk_step-1)*T>=5) - y0(1);
      x0c = Ad*x0c + Bd*e;
      u = min(max(Cd*x0c+Dd*e,0),3.5);
      if mov && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
      yp(kk_step)=y0(1); yv(kk_step)=y0(2); up(kk_step)=u;
    end
    tl=25001:35000; at=yv(tl)==0; ep=sum(at(2:end)&~at(1:end-1));
    ciclo=max(yp(tl))-min(yp(tl)); atasc=sum(at)*T/max(ep,1);
    diverge = max(abs(yp))>20;
    q = struct('family',f,'kK',kK,'alpha',al,'beta',be, ...
        'ciclo_original',p.ciclo,'atasc_original',p.atasc, ...
        'ciclo_estricto',ciclo,'atasc_estricto',atasc,'diverge',diverge);
    results(end+1) = q; %#ok<SAGROW>
    fprintf('%s kK=%.2f a=%.3f b=%.2f | orig ciclo=%.6f atasc=%.4f | estricto ciclo=%.6f atasc=%.4f | diverge=%d\n', ...
        f, kK, al, be, p.ciclo, p.atasc, ciclo, atasc, diverge);
    fid = fopen(fullfile(aqui,'fronteras_revalidadas.json'), 'w');
    fprintf(fid, '%s', jsonencode(results, 'PrettyPrint', true));
    fclose(fid);
  end
end
fprintf('\nListo: %d puntos revalidados.\n', numel(results));
