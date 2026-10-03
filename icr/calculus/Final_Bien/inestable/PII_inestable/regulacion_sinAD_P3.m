% =========================================================
% OE3 (P3): PII de la tesis sobre el modelo NO LINEAL sin
% atascamiento-deslizamiento (sin Karnopp ni zona muerta).
%   m*dv = u/(b*(a-x)^4) - m*g - m*c1*v
% Mismas condiciones que regulacion_P4.m (escalón -2 -> -3 cm en t = 10 s,
% u en [0, 3.5] V) para comparar con el caso con AD.
% Requiere haber corrido regulacion_P4.m (usa regulacion_P4.mat).
% =========================================================
clear; close all; clc

aqui = fileparts(mfilename('fullpath'));
dest = fullfile(aqui, '..', '..', '..', '..', 'context', 'Tesis', 'images', 'sin_ad_results', 'tikz');
if ~exist(dest, 'dir'), mkdir(dest); end

m = 0.141; a = 7.17184; b = 1.6163e-6; c1 = 8.563; g = 981;
T = 0.001; Tfin = 40; tsw = 10; ref1 = -2; ref2 = -3; umax = 3.5;

S = load(fullfile(aqui, 'PII_lic.mat'));
[A, B, C, D] = zp2ss(S.C.Z{:}, S.C.P{:}, S.C.K);

planta = @(y, u) [y(2); u/(m*b*max(a - y(1), 1e-6)^4) - g - c1*y(2)];

ueq1 = m*g*b*(a - ref1)^4;
Ad = c2d(ss(A, B, C, D), T).A;
x0 = [Ad - eye(size(A)); C] \ [zeros(size(A,1),1); ueq1];   % arranque sin salto

N  = round(Tfin/T);
tc = (0:N-1)'*T;
y0 = [ref1; 0]; u = ueq1;
yp = zeros(N,1); yv = yp; err = yp; R = yp; uu = yp;
for k = 1:N
    [~, y] = ode45(@(t,y) planta(y, u), [0 T], y0);
    y0 = y(end, :)';
    R(k) = ref1 + (ref2 - ref1)*(tc(k) >= tsw);
    e = R(k) - y0(1);
    [~, xc] = ode45(@(t,x) A*x + B*e, [0 T], x0);
    x0 = xc(end, :)';
    u = min(max(C*x0 + D*e, 0), umax);
    yp(k) = y0(1); yv(k) = y0(2); err(k) = e; uu(k) = u;
end

% -----------------------------
% Métricas (sin AD) y comparación con el caso con AD (P4)
% -----------------------------
P4 = load(fullfile(aqui, 'regulacion_P4.mat'));
post = tc >= tsw; tl = tc >= Tfin - 10;
[xpk, ipk] = min(yp(post));
fuera = find(abs(yp - ref2) > 0.02 & post, 1, 'last');
met = struct( ...
    'pico_cm', xpk, 'sobrepaso_pct', 100*(ref2 - xpk)/abs(ref2 - ref1), ...
    't_pico_s', tc(find(post,1) + ipk - 1) - tsw, ...
    't_establecimiento_2pct_s', tc(fuera) - tsw, ...
    'error_max_ult10s_cm', max(abs(err(tl))), ...
    'u_final_V', uu(end), 'u_eq_ref2_V', m*g*b*(a - ref2)^4, ...
    'u_max_V', max(uu), 'u_min_V', min(uu), ...
    'frac_saturado', mean(uu >= umax - 1e-4), ...
    'conAD_sobrepaso_pct', P4.met.sobrepaso_pct, ...
    'conAD_error_max_ult10s_cm', P4.met.error_max_ult10s_cm, ...
    'conAD_ciclo_limite_pp_cm', P4.met.ciclo_limite_pp_cm);
disp(met)
fid = fopen(fullfile(dest, 'sinAD_metricas.json'), 'w');
fprintf(fid, '%s', jsonencode(met, 'PrettyPrint', true)); fclose(fid);
save(fullfile(aqui, 'regulacion_sinAD_P3.mat'), 'tc', 'yp', 'yv', 'err', 'R', 'uu', 'met');

% -----------------------------
% CSV: sin AD y con AD en la misma tabla (decimación min-max)
% -----------------------------
Y = [yp R yv err uu P4.yp P4.yv P4.err P4.u_despues];
cols = {'t','x','r','v','e','u','x_ad','v_ad','e_ad','u_ad'};
escribir(fullfile(dest, 'comparacion.csv'), cols, tc, Y, [1 3 4 5 6 7 8 9], 100);
k = find(tc >= 9.8 & tc <= 12);
escribir(fullfile(dest, 'detalle.csv'), cols, tc(k), Y(k,:), [1 6], 4);
fprintf('CSV escritos en %s\n', dest);

function escribir(archivo, cols, t, Y, clave, w)
n = numel(t); keep = false(n,1); keep([1 n]) = true;
for i0 = 1:w:n
    i1 = min(i0 + w - 1, n);
    for c = clave
        [~, a] = min(Y(i0:i1, c)); [~, b] = max(Y(i0:i1, c));
        keep(i0 + a - 1) = true; keep(i0 + b - 1) = true;
    end
end
writetable(array2table([t(keep) Y(keep,:)], 'VariableNames', cols), archivo);
end
