% =========================================================
% Regulación (P4): PII de la tesis + zona muerta + Karnopp
% Simulador corregido (P1), escalón -2 -> -3 cm, u en [0, 3.5] V
% Exporta CSV para las figuras TikZ/pgfplots de la tesis.
% =========================================================
clear; close all; clc

aqui  = fileparts(mfilename('fullpath'));
tesis = fullfile(aqui, '..', '..', '..', '..', 'context', 'Tesis');
dest  = fullfile(tesis, 'images', 'regulation_results', 'tikz');
if ~exist(dest, 'dir'), mkdir(dest); end

% -----------------------------
% Parámetros
% -----------------------------
m = 0.141; a = 7.17184; b = 1.6163e-6; g = 981;
Fs = 20; vth = 0.02;

T    = 0.001;           % periodo de muestreo [s]
Tfin = 40;              % duración [s]
tsw  = 10;              % instante del escalón [s]
ref1 = -2;              % [cm]
ref2 = -3;              % [cm]
umax = 3.5;             % [V]

% -----------------------------
% Controlador PII (C(s) de la tesis)
% -----------------------------
S = load(fullfile(aqui, 'PII_lic.mat'));
[A, B, C, D] = zp2ss(S.C.Z{:}, S.C.P{:}, S.C.K);

% Arranque sin salto: integradores en el estado que da u = u_eq(ref1) con e = 0
ueq1 = m*g*b*(a - ref1)^4;
Ad = c2d(ss(A, B, C, D), T).A;
x0 = [Ad - eye(size(A)); C] \ [zeros(size(A,1),1); ueq1];

% -----------------------------
% Simulación
% -----------------------------
N  = round(Tfin/T);
tc = (0:N-1)'*T;
y0 = [ref1; 0];
u  = ueq1; uzm = u; ZM = 0;
yp = zeros(N,1); yv = yp; err = yp; R = yp; u_antes = yp; u_despues = yp;

for k = 1:N
    % planta con u retenido
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), [0 T], y0);
    y0 = y(end, :)';

    % sujeción de atascamiento
    Fext = u/(b*max(a - y0(1), 1e-6)^4) - m*g;
    if abs(y0(2)) < vth && abs(Fext) <= Fs
        y0(2) = 0;
    end
    if y0(2) == 0, ZM = 0; else, uzm = u; ZM = 1; end

    % referencia y error
    R(k)   = ref1 + (ref2 - ref1)*(tc(k) >= tsw);
    e      = R(k) - y0(1);

    % controlador
    [~, xc] = ode45(@(t,x) A*x + B*e, [0 T], x0);
    x0 = xc(end, :)';
    u  = min(max(C*x0 + D*e, 0), umax);
    u_antes(k) = u;

    % zona muerta
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end
    u_despues(k) = u;

    yp(k) = y0(1); yv(k) = y0(2); err(k) = e;
end

% -----------------------------
% Métricas
% -----------------------------
ueq2 = m*g*b*(a - ref2)^4;
post = tc >= tsw;
tl   = tc >= Tfin - 10;
[xpk, ipk] = min(yp(post));                  % la referencia baja: el pico es el mínimo
fuera = find(abs(yp - ref2) > 0.05 & post, 1, 'last');
met = struct( ...
    'u_eq_ref1_V', ueq1, 'u_eq_ref2_V', ueq2, ...
    'pico_cm', xpk, 'sobrepaso_pct', 100*(ref2 - xpk)/abs(ref2 - ref1), ...
    't_pico_s', tc(find(post,1) + ipk - 1) - tsw, ...
    't_banda_005cm_s', tc(fuera) - tsw, ...
    'ciclo_limite_pp_cm', max(yp(tl)) - min(yp(tl)), ...
    'error_max_ult10s_cm', max(abs(err(tl))), ...
    'error_medio_ult10s_cm', mean(err(tl)), ...
    'u_medio_ult10s_V', mean(u_despues(tl)), ...
    'u_max_V', max(u_antes), 'u_min_V', min(u_antes), ...
    'frac_saturado', mean(u_antes >= umax - 1e-4), ...
    'frac_atascado_ult10s', mean(yv(tl) == 0));
disp(met)
fid = fopen(fullfile(dest, 'regulacion_P4_metricas.json'), 'w');
fprintf(fid, '%s', jsonencode(met, 'PrettyPrint', true)); fclose(fid);
save(fullfile(aqui, 'regulacion_P4.mat'), 'tc', 'yp', 'yv', 'err', 'R', 'u_antes', 'u_despues', 'met');

% -----------------------------
% CSV para pgfplots (decimación min-max: conserva picos)
% -----------------------------
escribir(fullfile(dest, 'posicion.csv'),  {'t','x','r'},            tc, [yp R],                  1);
escribir(fullfile(dest, 'velocidad.csv'), {'t','v'},                tc, yv,                      1);
escribir(fullfile(dest, 'error.csv'),     {'t','e'},                tc, err,                     1);
escribir(fullfile(dest, 'control.csv'),   {'t','u_antes','u_desp'}, tc, [u_antes u_despues],     [1 2]);
fprintf('CSV escritos en %s\n', dest);

function escribir(archivo, cols, t, Y, clave)
% Conserva, en cada bloque de 20 muestras, los índices del mínimo y del máximo
% de las columnas indicadas en 'clave', más el primer y último punto.
n = numel(t); w = 50; keep = false(n,1); keep([1 n]) = true;
for i0 = 1:w:n
    i1 = min(i0 + w - 1, n);
    for c = clave
        [~, a] = min(Y(i0:i1, c)); [~, b] = max(Y(i0:i1, c));
        keep(i0 + a - 1) = true; keep(i0 + b - 1) = true;
    end
end
T = array2table([t(keep) Y(keep,:)], 'VariableNames', cols);
writetable(T, archivo);
end
