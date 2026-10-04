% Busca el mejor PI dentro de la misma libertad que se le dio a PII_V2 (ganancia,
% cero bajo y red de adelanto -zero y polo-, no solo el cero bajo del barrido R15).
% Primero filtra por margen de fase >=30 grados en -4,-3,-2.5,-2 cm (barato, lineal).
% Entre los que pasan, estima con stepinfo lineal (barato) cuáles son candidatos
% razonables, y solo a esos los simula de forma no lineal con Karnopp (caro, ode45),
% para ver si alguno iguala o supera a PII_V2 (ciclo 0,011 cm, atasco 0,24 s).

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

kKs = [1 1.5 2 2.5 3 3.5 4 4.5 5];
alphas = [1 1.2 1.4 1.6 1.8 2.0 2.4 2.8 3.2];
betas = [1.0 1.05 1.1 1.15 1.2];

cand = {};
for kK = kKs
  for al = alphas
    for be = betas
      zz = [z_bajo*al, z_alto*be];
      pp = [0, p_red*be];
      Cz = zpk(zz, pp, k*kK);
      ok = true; pms = zeros(1,4);
      for j = 1:4
        L = Cz*Gs{j};
        if ~isstable(feedback(L,1)), ok = false; break; end
        [~, pm] = margin(L); pms(j) = pm;
      end
      if ~ok || min(pms) < 30, continue; end
      si = stepinfo(feedback(Cz*Gs{2}, 1));
      cand{end+1} = struct('kK', kK, 'alpha', al, 'beta', be, 'pm_min', min(pms), ...
          'os_lineal', si.Overshoot, 'ts_lineal', si.SettlingTime, 'Cz', Cz); %#ok<SAGROW>
    end
  end
end
fprintf('Candidatos con margen >= 30 grados: %d de %d\n', numel(cand), numel(kKs)*numel(alphas)*numel(betas));

% El settling time lineal por si solo favorece ganancias extremas que saturan y
% divergen en no lineal (ya se vio con kK=2.5/alpha=1.8/beta=1.1). En vez de tomar
% los "mejores" globales, se toma un representante por cada nivel de kK (el de
% menor settling time dentro de ese kK), para cubrir el eje de ganancia completo
% igual que hace la figura de ciclo contra kK del capitulo 6.
kKvals = cellfun(@(c) c.kK, cand);
elegidos = [];
for kK = unique(kKvals)
  idxs = find(kKvals == kK);
  [~, j] = min(cellfun(@(c) c.ts_lineal, cand(idxs)));
  elegidos(end+1) = idxs(j); %#ok<SAGROW>
end

resultados = {};
for idx = elegidos
  c = cand{idx};
  [Ad, Bd, Cd, Dd] = ssdata(c2d(ss(c.Cz), T, 'zoh'));
  ueq = m*g*b*(a+2)^4;
  x0c = [Ad-eye(size(Ad)); Cd] \ [zeros(size(Ad,1),1); ueq];
  y0 = [-2;0]; u = ueq; uzm = u;
  N = 35000; yp = zeros(N,1); yv = yp; up = yp;
  for kk = 1:N
    [~,y] = ode45(@(t,y) maglev_karnopp(t,y,u), [0 T], y0); y0 = y(end,:)';
    Fe = u/(b*max(a-y0(1),1e-6)^4) - m*g;
    if abs(y0(2)) < vth && abs(Fe) <= Fs, y0(2) = 0; end
    mov = y0(2) ~= 0; if mov, uzm = u; end
    ref = -2 - ((kk-1)*T >= 5);
    e = ref - y0(1);
    x0c = Ad*x0c + Bd*e;
    u = min(max(Cd*x0c + Dd*e, 0), 3.5);
    if mov && u <= uzm+0.025 && u >= uzm-0.02, u = uzm; end
    yp(kk) = y0(1); yv(kk) = y0(2); up(kk) = u;
  end
  tl = 25001:35000; at = yv(tl) == 0; ep = sum(at(2:end) & ~at(1:end-1));
  ciclo_pp = max(yp(tl)) - min(yp(tl));
  atasc_medio = sum(at)*T/max(ep,1);
  diverge = yp(end) < -20 || ~isfinite(yp(end)) || max(abs(yp)) > 20;
  frac_sat = sum(up >= 3.5-1e-4)/N;
  r = struct('kK', c.kK, 'alpha', c.alpha, 'beta', c.beta, 'pm_min', c.pm_min, ...
      'ciclo_pp_cm', ciclo_pp, 'atasc_medio_s', atasc_medio, 'frac_saturado', frac_sat, 'diverge', diverge);
  resultados{end+1} = r; %#ok<SAGROW>
  fprintf('kK=%.2f a=%.2f b=%.2f pm=%.1f | ciclo=%.5f cm atasc=%.3f s sat=%.3f diverge=%d\n', ...
      c.kK, c.alpha, c.beta, c.pm_min, ciclo_pp, atasc_medio, frac_sat, diverge);
end

fid = fopen(fullfile(aqui, 'buscar_PI_v2.json'), 'w');
fprintf(fid, '%s', jsonencode(resultados, 'PrettyPrint', true));
fclose(fid);
fprintf('\nGuardado en %s\n', fullfile(aqui, 'buscar_PI_v2.json'));
