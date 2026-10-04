% Contraparte de validar_PII_v2.m: libera al PI de comparación exactamente igual que
% a PII_V2, para decidir si la ventaja de PII_V2 sobre el mejor PI del barrido R15 es
% un efecto estructural del PII o solo de haberle dado más libertad de sintonización
% al PII y no al PI.
%
% El barrido R15 (familias_R15.m) escala, para el PI, la ganancia (kK) y solo el cero
% de baja frecuencia (-12,906 rad/s, "bajos"); deja fijos el cero -15 y el polo -400,
% que forman una red de adelanto análoga a la de PII (zero < polo en magnitud). Se
% libera aquí esa misma red con el mismo factor beta que se usó en PII_V2:
%
%   C_PI,v2(s) = k*kK * (s - z_bajo*alpha) (s - z_adelanto*beta) / (s (s - p_adelanto*beta))
%
% con kK=2,5, alpha=1,8 (los mismos valores de PII_V2) y beta=1,1 (idem). Se evalúa con
% el mismo método que validar_PII_v2.m: margen de fase en -4,-3,-2.5,-2 cm y simulación
% no lineal (Karnopp, zona muerta, saturación) del escalón -2->-3 cm y de la rampa de
% R15, con ode45.

clear; clc
aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, '..', 'inestable', 'PII_inestable'));
addpath(fullfile(aqui, '..', 'inestable', 'PI_inestable'));

m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02; T=1e-3;

%% Reconstrucción de PI_v2 a partir del PI de comparación de la tesis
S = load(fullfile(aqui, '..', 'inestable', 'PI_inestable', 'PI.mat'));
Cpi = zpk(S.C);
z = Cpi.Z{1}; p = Cpi.P{1}; k = Cpi.K;
fprintf('PI base (tesis): k=%.6g  z=[%s]  p=[%s]\n', k, sprintf('%.6g ', z), sprintf('%.6g ', p));

kK = 2.5; alpha = 1.8; beta = 1.1;
[~, i_bajo] = min(abs(z));        % cero de baja frecuencia (el que escala familias_R15.m)
i_alto = setdiff(1:numel(z), i_bajo);
i_polo_origen = find(abs(p) < 1e-9);
i_polo_red = setdiff(1:numel(p), i_polo_origen);
assert(numel(i_alto) == 1 && numel(i_polo_red) == 1);

z2 = z; z2(i_bajo) = z(i_bajo)*alpha; z2(i_alto) = z(i_alto)*beta;
p2 = p; p2(i_polo_red) = p(i_polo_red)*beta;
k2 = k*kK;
Cv2 = zpk(z2, p2, k2);
fprintf('PI_V2 reconstruido: k=%.6g  z=[%s]  p=[%s]\n\n', k2, sprintf('%.6g ', z2), sprintf('%.6g ', p2));

%% Margen de fase en -4, -3, -2.5, -2 cm (mismo método que validar_PII_v2.m)
planta = @(x) tf(ss([0 1; 4*g/(a - x) -c1], [0; 1/(m*b*(a - x)^4)], [1 0], 0));
xs = [-4 -3 -2.5 -2];
pms = zeros(1, numel(xs));
for j = 1:numel(xs)
    L = Cv2*planta(xs(j));
    estable = isstable(feedback(L, 1));
    [~, pm] = margin(L);
    pms(j) = pm;
    fprintf('x=%.2f cm: lazo cerrado %s, margen de fase %.2f deg\n', xs(j), merge_str(estable), pm);
end
pm_min = min(pms);

if pm_min < 30
    fprintf('\nPI_V2 NO cumple el margen de fase minimo de 30 grados (mmin=%.2f). No se simula.\n', pm_min);
    resultado = struct('margen_fase_deg', struct('x_menos4', pms(1), 'x_menos3', pms(2), ...
        'x_menos2_5', pms(3), 'x_menos2', pms(4)), 'pm_min', pm_min, 'cumple_30deg', false);
    fid = fopen(fullfile(aqui, 'validacion_PI_v2.json'), 'w');
    fprintf(fid, '%s', jsonencode(resultado, 'PrettyPrint', true));
    fclose(fid);
    return
end

%% Escalón -2 -> -3 cm con Karnopp (ode45)
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
    x0c = Ad*x0c + Bd*e;
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

%% Rampa de R15 (ode45)
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
    x0c = Ad*x0c + Bd*e;
    u = min(max(Cd*x0c + Dd*e, 0), 3.5);
    if mov && u <= uzm+0.025 && u >= uzm-0.02, u = uzm; end
    eB(kk) = e; upR(kk) = u;
end
venB = 10001:25000;
error_medio = mean(eB(venB));
error_rms = sqrt(mean(eB(venB).^2));
frac_sat_r = sum(upR >= 3.5-1e-4)/Nr;
fprintf('Rampa R15: error_medio %.6f cm  error_rms %.6f cm  frac_sat %.4f\n\n', error_medio, error_rms, frac_sat_r);

resultado = struct();
resultado.reconstruccion = struct('k', k2, 'z', z2', 'p', p2');
resultado.margen_fase_deg = struct('x_menos4', pms(1), 'x_menos3', pms(2), 'x_menos2_5', pms(3), 'x_menos2', pms(4));
resultado.pm_min = pm_min; resultado.cumple_30deg = true;
resultado.escalon = struct('sobrepaso_pct', sobrepaso, 'ciclo_pp_cm', ciclo_pp, ...
    'atasc_medio_s', atasc_medio, 'u_max', u_max, 'frac_saturado', frac_sat, 'diverge', diverge);
resultado.rampa = struct('error_medio_cm', error_medio, 'error_rms_cm', error_rms, 'frac_saturado', frac_sat_r);
resultado.metodo = 'ode45, lazo discreto ZOH T=1ms, mismo criterio que validar_PII_v2.m; comparacion simetrica (misma kK, alpha, beta)';
resultado.fecha = datestr(now, 'yyyy-mm-dd');

fid = fopen(fullfile(aqui, 'validacion_PI_v2.json'), 'w');
fprintf(fid, '%s', jsonencode(resultado, 'PrettyPrint', true));
fclose(fid);
fprintf('Guardado en %s\n', fullfile(aqui, 'validacion_PI_v2.json'));

function s = merge_str(tf_)
    if tf_, s = 'estable'; else, s = 'INESTABLE'; end
end

function [Ad,Bd,Cd,Dd] = discretiza(Cz, T)
    sysd = c2d(ss(Cz), T, 'zoh');
    [Ad,Bd,Cd,Dd] = ssdata(sysd);
end
