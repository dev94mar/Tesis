% =========================================================
% Evidencia para P8 (alcance de la metodología)
%   A) Fase 1b: sistema no lineal en lazo abierto en los puntos de equilibrio
%   B) Fase 2b: PII con zona muerta + Karnopp sobre el modelo LINEAL
%   C) Configuración estable (repulsiva): linealización, márgenes y simulación
% Simulador corregido (P1). Exporta CSV para TikZ y un JSON de métricas.
% Requiere regulacion_P4.mat (para comparar B con el modelo no lineal).
% =========================================================
clear; close all; clc

aqui = fileparts(mfilename('fullpath'));
dest = fullfile(aqui, '..', '..', 'context', 'Tesis', 'images', 'p8_results', 'tikz');
if ~exist(dest, 'dir'), mkdir(dest); end
addpath(fullfile(aqui, 'inestable', 'PII_inestable'));

P = struct('m', 0.141, 'a', 7.17184, 'b', 1.6163e-6, 'c1', 8.563, 'g', 981, 'Fs', 20, 'vth', 0.02);
m = P.m; a = P.a; b = P.b; c1 = P.c1; g = P.g; Fs = P.Fs;
ueq_at = @(x) m*g*b*(a - x)^4;          % configuración atractiva
ueq_st = @(x) m*g*b*(a + x)^4;          % configuración repulsiva (estable)
met = struct();

%% ===================== A) Fase 1b =====================
xs = [-4 -3 -2]; d0 = 0.01; tA = linspace(0, 0.6, 601)';
colsA = {'t'}; YA = tA;
for i = 1:numel(xs)
    x0 = xs(i); u0 = ueq_at(x0);
    f = @(t,y) [y(2); u0/(m*b*(a - y(1))^4) - g - c1*y(2)];
    opts = odeset('RelTol', 1e-9, 'AbsTol', 1e-12, 'Events', @(t,y) salir(t, y, x0));
    [tt, yy] = ode45(f, [0 0.6], [x0 + d0; 0], opts);
    dnl = interp1(tt, yy(:,1) - x0, tA, 'linear', NaN);
    lam = eig([0 1; 4*g/(a - x0) -c1]); l1 = min(lam); l2 = max(lam);
    dli = d0*(-l1*exp(l2*tA) + l2*exp(l1*tA))/(l2 - l1);
    dli(dli > 2) = NaN;
    tag = sprintf('m%d', abs(xs(i)));
    YA = [YA dnl dli]; colsA = [colsA {['nl_' tag], ['lin_' tag]}]; %#ok<AGROW>
    % banda en la que la fricción estática retiene el imán con u = u_eq (Karnopp)
    gmin = (u0/(b*(m*g + Fs)))^(1/4); gmax = (u0/(b*(m*g - Fs)))^(1/4);
    met.lazo_abierto.(tag) = struct('x_eq', x0, 'u_eq', u0, 'lambda_inestable', l2, ...
        't_duplicacion_s', log(2)/l2, 't_hasta_1cm_s', tt(end), ...
        'banda_atasco_cm', [a - gmax, a - gmin]);
end
YA(:, 2:end) = abs(YA(:, 2:end));
writetable(array2table(YA, 'VariableNames', colsA), fullfile(dest, 'lazo_abierto.csv'));

% Retrato de fase no lineal sin fricción estática alrededor de x* = -4
x0 = -4; u0 = ueq_at(x0);
f = @(t,y) [y(2); u0/(m*b*(a - y(1))^4) - g - c1*y(2)];
[X, V] = meshgrid(linspace(-4.5, -3.5, 21), linspace(-10, 10, 21));
DX = V; DV = u0./(m*b*(a - X).^4) - g - c1*V;
sx = 1/1.0; sv = 1/20;                              % escala de cada eje para normalizar flechas
nrm = hypot(DX*sx, DV*sv); nrm(nrm == 0) = 1; L = 0.035;   % flecha nula en el equilibrio
writetable(table(X(:), V(:), L*DX(:)*sx./nrm(:), L*DV(:)./nrm(:), ...
    'VariableNames', {'x','v','dx','dv'}), fullfile(dest, 'campo.csv'));
[Vec, Lam] = eig([0 1; 4*g/(a - x0) -c1]); [~, is] = min(diag(Lam)); [~, iu] = max(diag(Lam));
tray = [];
semillas = [-4.45 6; -4.45 9; -3.55 -6; -3.55 -9; -4.2 10; -3.8 -10; -4.45 3; -3.55 -3];
for s = 1:size(semillas,1)
    [~, yy] = ode45(f, [0 1], semillas(s,:)', odeset('Events', @(t,y) caja(t, y)));
    tray = [tray; yy; NaN NaN]; %#ok<AGROW>
end
for sgn = [-1 1]   % variedades estable (hacia atrás) e inestable (hacia adelante)
    [~, yy] = ode45(@(t,y) -f(t,y), [0 1], [x0; 0] + 1e-4*sgn*Vec(:,is), odeset('Events', @(t,y) caja(t, y)));
    tray = [tray; yy; NaN NaN]; %#ok<AGROW>
end
writetable(array2table(tray, 'VariableNames', {'x','v'}), fullfile(dest, 'trayectorias.csv'));
var = [];
for sgn = [-1 1]
    [~, yy] = ode45(f, [0 1], [x0; 0] + 1e-4*sgn*Vec(:,iu), odeset('Events', @(t,y) caja(t, y)));
    var = [var; yy; NaN NaN]; %#ok<AGROW>
end
writetable(array2table(var, 'VariableNames', {'x','v'}), fullfile(dest, 'variedad_inestable.csv'));
met.retrato = struct('x_eq', x0, 'banda_atasco_cm', met.lazo_abierto.m4.banda_atasco_cm);

%% ===================== B) Fase 2b =====================
S = load(fullfile(aqui, 'inestable', 'PII_inestable', 'PII_lic.mat'));
[Ac, Bc, Cc, Dc] = zp2ss(S.C.Z{:}, S.C.P{:}, S.C.K);
xl = -2.5; ul = ueq_at(xl); A21 = 4*g/(a - xl); b0 = 1/(m*b*(a - xl)^4);
Fext_lin = @(x, u) m*(A21*(x - xl) + b0*(u - ul));    % fuerza neta linealizada (sin fricción)
planta_lin = @(y, u) karnopp(y, Fext_lin(y(1), u), P);
ueq_lin = @(x) ul - A21*(x - xl)/b0;                   % equilibrio del modelo lineal
[tB, xB, uB] = lazo(planta_lin, Fext_lin, Ac, Bc, Cc, Dc, -2, -3, 10, 40, 3.5, ueq_lin(-2), P);
P4 = load(fullfile(aqui, 'inestable', 'PII_inestable', 'regulacion_P4.mat'));
met.lineal_AD = resumen_escalon(tB, xB, uB, -2, -3, 10);
met.lineal_AD.u_eq_lineal_final_V = ueq_lin(-3);
met.no_lineal_AD = resumen_escalon(P4.tc, P4.yp, P4.u_despues, -2, -3, 10);
escribir(fullfile(dest, 'lineal_ad.csv'), {'t','x_lin','u_lin','x_nl','u_nl'}, tB, ...
    [xB uB P4.yp P4.u_despues], [1 2 3 4], 100);

%% ===================== C) Configuración estable =====================
xs_st = [1 1.5 2];
for i = 1:numel(xs_st)
    x0 = xs_st(i);
    lam = eig([0 1; -4*g/(a + x0) -c1]);
    met.estable.lineal.(sprintf('x%d', round(10*x0))) = struct('x_eq', x0, 'u_eq', ueq_st(x0), ...
        'polos_re', real(lam)', 'polos_im', imag(lam)');
end
G = tf(ss([0 1; -4*g/(a + 1.5) -c1], [0; 1/(m*b*(a + 1.5)^4)], [1 0], 0));
nombres = {'PI', 'PII_prelim', 'PII_tesis'};
arch = {fullfile(aqui,'estable','PI_estable','CInestable.mat'), fullfile(aqui,'estable','PII_estable','CInestable.mat'), ...
        fullfile(aqui,'inestable','PII_inestable','PII_lic.mat')};
YC = []; Fext_st = @(x, u) u/(b*(a + x)^4) - m*g;
planta_st = @(y, u) karnopp(y, Fext_st(y(1), u), P);
for i = 1:numel(nombres)
    S = load(arch{i}); Cz = zpk(S.C);
    L = Cz*G; [gm, pm, wg, wp] = margin(L); T = feedback(L, 1); si = stepinfo(T);
    [A_, B_, C_, D_] = ssdata(ss(Cz));
    [tC, xC, uC] = lazo(planta_st, Fext_st, A_, B_, C_, D_, 1, 2, 10, 40, 3.5, ueq_st(1), P);
    r = resumen_escalon(tC, xC, uC, 1, 2, 10);
    r.ceros = Cz.Z{1}'; r.polos = Cz.P{1}'; r.ganancia = Cz.K;
    r.margen_fase_deg = pm; r.wc_fase = wp; r.margen_ganancia_dB = 20*log10(gm); r.wc_ganancia = wg;
    r.lineal_sobrepaso_pct = si.Overshoot; r.lineal_ts_s = si.SettlingTime; r.lazo_cerrado_estable = isstable(T);
    met.estable.(nombres{i}) = r;
    YC = [YC xC uC]; %#ok<AGROW>
end
escribir(fullfile(dest, 'estable.csv'), {'t','x_pi','u_pi','x_piip','u_piip','x_pii','u_pii'}, tC, YC, [1 2 5 6], 100);

% pgfplots solo reconoce 'nan' en minúsculas
for f = dir(fullfile(dest, '*.csv'))'
    txt = fileread(fullfile(dest, f.name));
    txt = strrep(txt, 'NaN', 'nan');   % filas nan,nan separan trayectorias (unbounded coords=jump)
    fid = fopen(fullfile(dest, f.name), 'w'); fprintf(fid, '%s', txt); fclose(fid);
end

fid = fopen(fullfile(dest, 'evidencia_P8_metricas.json'), 'w');
fprintf(fid, '%s', jsonencode(met, 'PrettyPrint', true)); fclose(fid);
disp(jsonencode(met, 'PrettyPrint', true));

%% ===================== funciones =====================
function [v, term, dir] = salir(~, y, x0)
v = 1 - abs(y(1) - x0);   % se detiene a 1 cm del equilibrio
term = 1; dir = 0;
end

function [v, term, dir] = caja(~, y)
v = min([y(1) + 4.5, -3.5 - y(1), 10 - y(2), y(2) + 10]); term = 1; dir = -1;
end

function dy = karnopp(y, Fext, P)
v = y(2);
if abs(v) > P.vth
    dy = [v; (Fext - P.m*P.c1*v)/P.m];
elseif abs(Fext) <= P.Fs
    dy = [0; 0];
else
    dy = [v; (Fext - P.Fs*sign(Fext))/P.m];
end
end

function [tc, yp, uu] = lazo(planta, Fext, A, B, C, D, r1, r2, tsw, Tfin, umax, u0, P)
T = 1e-3; N = round(Tfin/T); tc = (0:N-1)'*T;
Ad = c2d(ss(A, B, C, D), T).A;
x0 = [Ad - eye(size(A)); C] \ [zeros(size(A,1),1); u0];
y0 = [r1; 0]; u = u0; uzm = u; ZM = 0; yp = zeros(N,1); uu = yp;
for k = 1:N
    [~, y] = ode45(@(t,y) planta(y, u), [0 T], y0); y0 = y(end, :)';
    if abs(y0(2)) < P.vth && abs(Fext(y0(1), u)) <= P.Fs, y0(2) = 0; end
    if y0(2) == 0, ZM = 0; else, uzm = u; ZM = 1; end
    e = r1 + (r2 - r1)*(tc(k) >= tsw) - y0(1);
    [~, xc] = ode45(@(t,x) A*x + B*e, [0 T], x0); x0 = xc(end, :)';
    u = min(max(C*x0 + D*e, 0), umax);
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02, u = uzm; end
    yp(k) = y0(1); uu(k) = u;
end
end

function r = resumen_escalon(t, x, u, r1, r2, tsw)
post = t >= tsw; tl = t >= t(end) - 10; s = sign(r2 - r1);
pk = max(s*(x(post) - r2));
fuera = find(abs(x - r2) > 0.05*abs(r2 - r1) & post, 1, 'last');
r = struct('sobrepaso_pct', 100*pk/abs(r2 - r1), 't_banda_5pct_s', t(fuera) - tsw, ...
    'ciclo_pp_cm', max(x(tl)) - min(x(tl)), 'error_medio_ult10s_cm', mean(r2 - x(tl)), ...
    'u_max_V', max(u), 'u_medio_ult10s_V', mean(u(tl)));
end

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
