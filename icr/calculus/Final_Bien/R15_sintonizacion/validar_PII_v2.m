% Reproduce y valida de forma independiente el controlador PII_V2 descrito en
% icr/grafo/grafo_tesis.json (nodo PII_V2, revisión R25, añadido 2026-10-04 sin script
% ni datos que lo respaldaran). PII_V2 reescala el PII de la tesis (PII_lic.mat) con
% ganancia kK, ceros bajos *alpha y red de adelanto (cero y polo altos) *beta:
%
%   C_PII,v2(s) = k*kK * (s - z1*alpha)(s - z2*alpha)(s - z3*beta) / (s^2 (s - p3*beta))
%
% con kK = 2.5, alpha = 1.8, beta = 1.1, tomados tal cual del nodo del grafo.
%
% Verifica, en este orden:
%   1) que esa reescala reproduce los coeficientes numéricos citados en el nodo;
%   2) el margen de fase en -4, -3, -2.5 y -2 cm (mismo método que familias_R15.m);
%   3) el ciclo límite y el atascamiento medio en el escalón -2 -> -3 cm con
%      fricción de Karnopp, zona muerta y saturación (mismo método que validar_R15.m);
%   4) el error de seguimiento en la rampa de R15 (mismo método que simular_R15.py,
%      pero integrado con ode45, no MLX/RK4 de paso fijo).
%
% Usa el mismo simulador (maglev_karnopp.m) y la misma lógica de retención y
% saturación que el resto del barrido R15. No usa Python ni Mathematica: toda la
% verificación es MATLAB con ode45, para poder compararse directamente contra
% validar_R15.m (que ya se usó para validar los controladores base del barrido).

clear; clc
aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, '..', 'inestable', 'PII_inestable'));

m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;

%% 1) Reconstrucción de PII_V2 a partir del PII de la tesis
S = load(fullfile(aqui, '..', 'inestable', 'PII_inestable', 'PII_lic.mat'));
Cpii = zpk(S.C);
z = Cpii.Z{1}; p = Cpii.P{1}; k = Cpii.K;
fprintf('PII base (tesis): k=%.6g  z=[%s]  p=[%s]\n', k, sprintf('%.6g ', z), sprintf('%.6g ', p));

kK = 2.5; alpha = 1.8; beta = 1.1;
bajos = [-4.875 -1.861];          % ceros de baja frecuencia (igual que familias_R15.m)
[~, i_alto] = max(real(z));       % cero de la red de adelanto (el menos negativo... )
% el cero "alto" (red de adelanto) es el de mayor |parte real| negativa entre los no bajos;
% se identifica explícitamente por no estar en bajos, no por orden:
i_bajos = arrayfun(@(zb) find(abs(z - zb) == min(abs(z - zb)), 1), bajos);
i_alto = setdiff(1:numel(z), i_bajos);
assert(numel(i_alto) == 1, 'se esperaba un solo cero fuera de los bajos');
[~, i_polo_alto] = min(p);        % polo distinto de los dos integradores en el origen
i_polos_origen = find(abs(p) < 1e-9);
i_polo_red = setdiff(1:numel(p), i_polos_origen);
assert(numel(i_polo_red) == 1, 'se esperaba un solo polo fuera del origen');

z2 = z; z2(i_bajos) = z(i_bajos)*alpha; z2(i_alto) = z(i_alto)*beta;
p2 = p; p2(i_polo_red) = p(i_polo_red)*beta;
k2 = k*kK;
Cv2 = zpk(z2, p2, k2);

fprintf('\nPII_V2 reconstruido: k=%.6g  z=[%s]  p=[%s]\n', k2, sprintf('%.6g ', z2), sprintf('%.6g ', p2));
esperado_k = 381.075; esperado_z = sort([-8.775 -3.3498 -19.041]); esperado_p = sort([0 0 -331.21]);
obtenido_z = sort(z2'); obtenido_p = sort(p2');
fprintf('Nodo del grafo dice: k=%.6g  z=[%s]  p=[%s]\n', esperado_k, sprintf('%.6g ', esperado_z), sprintf('%.6g ', esperado_p));
err_k = abs(k2-esperado_k)/esperado_k;
err_z = max(abs(obtenido_z - esperado_z)./max(abs(esperado_z),1e-9));
fprintf('Diferencia relativa: ganancia %.4g, ceros %.4g\n\n', err_k, err_z);

%% 2) Margen de fase en -4, -3, -2.5, -2 cm
planta = @(x) tf(ss([0 1; 4*g/(a - x) -c1], [0; 1/(m*b*(a - x)^4)], [1 0], 0));
xs = [-4 -3 -2.5 -2];
pms = zeros(1, numel(xs));
for j = 1:numel(xs)
    L = Cv2*planta(xs(j));
    Tcl = feedback(L, 1);
    estable = isstable(Tcl);
    [~, pm] = margin(L);
    pms(j) = pm;
    fprintf('x=%.2f cm: lazo cerrado %s, margen de fase %.2f deg\n', xs(j), ...
        merge_str(estable), pm);
end

%% 3) Escalón -2 -> -3 cm con Karnopp (ode45), igual que validar_R15.m
[Ad, Bd, Cd, Dd] = discretiza(Cv2, T);
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
    x0c = paso_discreto(Ad, Bd, x0c, e);
    u = min(max(Cd*x0c + Dd*e, 0), 3.5);
    if mov && u <= uzm+0.025 && u >= uzm-0.02, u = uzm; end
    yp(kk) = y0(1); yv(kk) = y0(2); up(kk) = u;
end
tl = 25001:35000;
at = yv(tl) == 0;
ep = sum(at(2:end) & ~at(1:end-1));
sobrepaso = 100*(-3 - min(yp(5001:end)));
ciclo_pp = max(yp(tl)) - min(yp(tl));
atasc_medio = sum(at)*T/max(ep,1);
u_max = max(up);
frac_sat = sum(up >= 3.5-1e-4)/N;
diverge = yp(end) < -20 || ~isfinite(yp(end));
fprintf('\nEscalon -2->-3 cm: sobrepaso %.2f%%  ciclo_pp %.6f cm  atasc_medio %.4f s  u_max %.4f V  frac_sat %.4f  diverge=%d\n', ...
    sobrepaso, ciclo_pp, atasc_medio, u_max, frac_sat, diverge);

%% 4) Rampa de R15 (ode45), igual criterio que simular_R15.py pero con ode45
y0 = [-2;0]; u = ueq; uzm = u;
x0c = [Ad-eye(size(Ad)); Cd] \ [zeros(size(Ad,1),1); ueq];
Nr = 35000; eB = zeros(Nr,1); upR = zeros(Nr,1);
for kk = 1:Nr
    t = (kk-1)*T;
    [~,y] = ode45(@(t,y) maglev_karnopp(t,y,u), [0 T], y0); y0 = y(end,:)';
    Fe = u/(b*max(a-y0(1),1e-6)^4) - m*g;
    if abs(y0(2)) < vth && abs(Fe) <= Fs, y0(2) = 0; end
    mov = y0(2) ~= 0; if mov, uzm = u; end
    ref = max(min(-2 - 0.05*max(t-5,0), -2), -3);
    e = ref - y0(1);
    x0c = paso_discreto(Ad, Bd, x0c, e);
    u = min(max(Cd*x0c + Dd*e, 0), 3.5);
    if mov && u <= uzm+0.025 && u >= uzm-0.02, u = uzm; end
    eB(kk) = e; upR(kk) = u;
end
venB = 10001:25000; % t in [10,25) s, igual que VENT_B de simular_R15.py
error_medio = mean(eB(venB));
error_rms = sqrt(mean(eB(venB).^2));
frac_sat_r = sum(upR >= 3.5-1e-4)/Nr;
fprintf('Rampa R15: error_medio %.6f cm  error_rms %.6f cm  frac_sat %.4f\n\n', error_medio, error_rms, frac_sat_r);

%% Resumen y comparación contra lo afirmado en el nodo del grafo
nodo.margen_fase = struct('m4', 47.3, 'm3', 41.0, 'm2_5', 37.8, 'm2', 34.5);
nodo.ciclo_limite_cm = 0.0108; nodo.atasc_medio_s = 0.237; nodo.sobrepaso_pct = 29.1;
nodo.error_rms_rampa_cm = 0.0024;

resultado = struct();
resultado.reconstruccion = struct('k', k2, 'z', z2', 'p', p2', ...
    'err_relativo_k', err_k, 'err_relativo_z', err_z);
resultado.margen_fase_deg = struct('x_menos4', pms(1), 'x_menos3', pms(2), 'x_menos2_5', pms(3), 'x_menos2', pms(4));
resultado.escalon = struct('sobrepaso_pct', sobrepaso, 'ciclo_pp_cm', ciclo_pp, ...
    'atasc_medio_s', atasc_medio, 'u_max', u_max, 'frac_saturado', frac_sat, 'diverge', diverge);
resultado.rampa = struct('error_medio_cm', error_medio, 'error_rms_cm', error_rms, 'frac_saturado', frac_sat_r);
resultado.comparacion_contra_nodo_grafo = nodo;
resultado.metodo = 'ode45, lazo discreto ZOH T=1ms igual que validar_R15.m; mismo simulador maglev_karnopp.m';
resultado.fecha = datestr(now, 'yyyy-mm-dd');

fid = fopen(fullfile(aqui, 'validacion_PII_v2.json'), 'w');
fprintf(fid, '%s', jsonencode(resultado, 'PrettyPrint', true));
fclose(fid);
fprintf('Guardado en %s\n', fullfile(aqui, 'validacion_PII_v2.json'));

function s = merge_str(tf_)
    if tf_, s = 'estable'; else, s = 'INESTABLE'; end
end

function [Ad,Bd,Cd,Dd] = discretiza(Cz, T)
    sysd = c2d(ss(Cz), T, 'zoh');
    [Ad,Bd,Cd,Dd] = ssdata(sysd);
end

function xn = paso_discreto(Ad, Bd, x, e)
    xn = Ad*x + Bd*e;
end
