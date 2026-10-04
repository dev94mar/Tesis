% Barrido conjunto del PI de comparación: ganancia (kK), cero de baja frecuencia
% (alpha) Y red de adelanto (beta: su propio cero-polo -15/-400, analogo al que
% familias_R15.m mantenia fijo). Cierra la pregunta que dejo abierta la
% comparacion simetrica de validacion/barrido_03 (extender_ambos.m), que solo
% habia variado kK con alpha y beta fijos en el optimo ya conocido.
%
% Metodo: filtro lineal barato (margen de fase >=30 grados en -4,-3,-2.5,-2 cm)
% sobre toda la rejilla; despues, simulacion no lineal (Karnopp, zona muerta,
% saturacion, ode45) SOLO de los candidatos que pasan el filtro, en paralelo
% (Parallel Computing Toolbox) para que sea viable en tiempo razonable.
%
% Resultado: el mejor PI de todo este espacio, para compararlo con el mejor PII
% encontrado en extender_ambos.m (kK=3, ciclo=0.01312 cm, atasc=0.844 s) y con
% PII_V2 (ciclo=0.011018 cm, atasc=0.2444 s).

clear; clc
aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, '..', 'inestable', 'PII_inestable'));
addpath(fullfile(aqui, '..', 'inestable', 'PI_inestable'));
m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;

S = load(fullfile(aqui, '..', 'inestable', 'PI_inestable', 'PI.mat'));
Cpi = zpk(S.C); z = Cpi.Z{1}; p = Cpi.P{1}; k = Cpi.K;
[~, i_bajo] = min(abs(z)); i_alto = setdiff(1:numel(z), i_bajo);
i_polo_origen = find(abs(p) < 1e-9); i_polo_red = setdiff(1:numel(p), i_polo_origen);
z_bajo = z(i_bajo); z_alto = z(i_alto); p_red = p(i_polo_red);

planta = @(x) tf(ss([0 1; 4*g/(a - x) -c1], [0; 1/(m*b*(a - x)^4)], [1 0], 0));
xs = [-4 -3 -2.5 -2]; Gs = arrayfun(planta, xs, 'UniformOutput', false);

kKs    = [1 1.5 2 2.5 3 3.5 4 4.5 5 5.5];
alphas = [0.3 0.5 0.758 1.0 1.4 1.8 2.2 2.6 3.0];
betas  = [1.0 1.05 1.1 1.15 1.2];

%% Filtro lineal (barato, secuencial)
cand = struct('kK', {}, 'alpha', {}, 'beta', {}, 'pm_min', {}, 'z', {}, 'p', {}, 'k', {});
for kK = kKs
  for al = alphas
    for be = betas
      zz = [z_bajo*al, z_alto*be]; pp = [0, p_red*be];
      Cz = zpk(zz, pp, k*kK);
      ok = true; pms = zeros(1,4);
      for j = 1:4
        L = Cz*Gs{j};
        if ~isstable(feedback(L,1)), ok = false; break; end
        [~, pm] = margin(L); pms(j) = pm;
      end
      if ~ok || min(pms) < 30, continue; end
      cand(end+1) = struct('kK', kK, 'alpha', al, 'beta', be, 'pm_min', min(pms), ...
          'z', zz, 'p', pp, 'k', k*kK); %#ok<SAGROW>
    end
  end
end
Ncand = numel(cand);
fprintf('Candidatos con margen >= 30 grados: %d de %d\n', Ncand, numel(kKs)*numel(alphas)*numel(betas));

%% Simulacion no lineal en paralelo de todos los candidatos que pasan el filtro
pool = gcp('nocreate');
if isempty(pool), pool = parpool('local'); end
addAttachedFiles(pool, {which('maglev_karnopp')});

resultados = struct('kK', cell(1,Ncand), 'alpha', cell(1,Ncand), 'beta', cell(1,Ncand), ...
    'pm_min', cell(1,Ncand), 'ciclo_pp_cm', cell(1,Ncand), 'atasc_medio_s', cell(1,Ncand), ...
    'frac_saturado', cell(1,Ncand), 'diverge', cell(1,Ncand));

parfor idx = 1:Ncand
  c = cand(idx);
  Cz = zpk(c.z, c.p, c.k); %#ok<PFBNS>
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
  resultados(idx) = struct('kK', c.kK, 'alpha', c.alpha, 'beta', c.beta, 'pm_min', c.pm_min, ...
      'ciclo_pp_cm', ciclo, 'atasc_medio_s', atasc, 'frac_saturado', sum(up>=3.5-1e-4)/N, 'diverge', diverge);
end

validos = resultados(~[resultados.diverge]);
fprintf('No divergen: %d de %d\n', numel(validos), Ncand);
[~, iCiclo] = min([validos.ciclo_pp_cm]);
[~, iAtasc] = min([validos.atasc_medio_s]);
fprintf('\nMejor ciclo: kK=%.3f alpha=%.3f beta=%.2f pm=%.1f | ciclo=%.5f cm atasc=%.3f s\n', ...
    validos(iCiclo).kK, validos(iCiclo).alpha, validos(iCiclo).beta, validos(iCiclo).pm_min, ...
    validos(iCiclo).ciclo_pp_cm, validos(iCiclo).atasc_medio_s);
fprintf('Mejor atasco: kK=%.3f alpha=%.3f beta=%.2f pm=%.1f | ciclo=%.5f cm atasc=%.3f s\n', ...
    validos(iAtasc).kK, validos(iAtasc).alpha, validos(iAtasc).beta, validos(iAtasc).pm_min, ...
    validos(iAtasc).ciclo_pp_cm, validos(iAtasc).atasc_medio_s);

fid = fopen(fullfile(aqui, 'barrido_conjunto_PI.json'), 'w');
fprintf(fid, '%s', jsonencode(resultados, 'PrettyPrint', true));
fclose(fid);
fprintf('\nGuardado en %s (%d candidatos, %d simulados)\n', fullfile(aqui, 'barrido_conjunto_PI.json'), Ncand, Ncand);
