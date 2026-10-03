% =========================================================
% Seguimiento (P5): PII de la tesis + zona muerta + Karnopp
% Simulador corregido (P1), u en [0, 3.5] V, rango de operación -3 a -2 cm.
%   Senoidal:    r(t) = -2.5 + 0.5 sin(2*pi*0.001 t), 2000 s (2 periodos)
%   Trapezoidal: planos en -2 y -3 cm, rampas de 250 s, periodo 1250 s, 2500 s
% Exporta CSV para las figuras TikZ/pgfplots de la tesis.
% =========================================================
clear; close all; clc

REUSAR = true;   % true: si ya existen seguimiento_P5_*.mat, solo vuelve a exportar los CSV

aqui = fileparts(mfilename('fullpath'));
dest = fullfile(aqui, '..', '..', '..', '..', 'context', 'Tesis', 'images', 'seguimiento_results', 'tikz');
if ~exist(dest, 'dir'), mkdir(dest); end

S = load(fullfile(aqui, 'PII_lic.mat'));
[A, B, C, D] = zp2ss(S.C.Z{:}, S.C.P{:}, S.C.K);

casos = { ...
    struct('nombre', 'sen',  'Tfin', 2000, 'ref', @ref_senoidal,    'zoom', [244 256]), ...
    struct('nombre', 'trap', 'Tfin', 2500, 'ref', @ref_trapezoidal, 'zoom', [246 266])};

res = cell(size(casos));
archivos = cellfun(@(c) fullfile(aqui, ['seguimiento_P5_' c.nombre '.mat']), casos, 'UniformOutput', false);
if REUSAR && all(cellfun(@isfile, archivos))
    for i = 1:numel(casos), res{i} = load(archivos{i}); end
else
    if isempty(gcp('nocreate')), parpool('Processes', numel(casos)); end
    parfor i = 1:numel(casos)
        res{i} = simular(A, B, C, D, casos{i});
    end
end

for i = 1:numel(casos)
    r = res{i}; n = casos{i}.nombre;
    if ~isfile(archivos{i}), save(archivos{i}, '-struct', 'r'); end
    exportar(dest, n, r, casos{i}.zoom);
    fid = fopen(fullfile(dest, ['seguimiento_' n '_metricas.json']), 'w');
    fprintf(fid, '%s', jsonencode(r.met, 'PrettyPrint', true)); fclose(fid);
    fprintf('== %s\n', n); disp(r.met)
end
fprintf('CSV escritos en %s\n', dest);

% ---------------------------------------------------------
function r = ref_senoidal(t)
r = -2.5 + 0.5*sin(2*pi*0.001*t);
end

function r = ref_trapezoidal(t)
tm = mod(t, 1250);
if tm < 250,      r = -2;
elseif tm < 500,  r = -2 - (tm - 250)/250;
elseif tm < 750,  r = -3;
elseif tm < 1000, r = -3 + (tm - 750)/250;
else,             r = -2;
end
end

% ---------------------------------------------------------
function out = simular(A, B, C, D, caso)
m = 0.141; a = 7.17184; b = 1.6163e-6; g = 981; Fs = 20; vth = 0.02;
T = 0.001; umax = 3.5;
N  = round(caso.Tfin/T);
tc = (0:N-1)'*T;

r0 = caso.ref(0);
ueq = m*g*b*(a - r0)^4;
Ad = c2d(ss(A, B, C, D), T).A;
x0 = [Ad - eye(size(A)); C] \ [zeros(size(A,1),1); ueq];   % arranque sin salto
y0 = [r0; 0]; u = ueq; uzm = u; ZM = 0;

yp = zeros(N,1); yv = yp; err = yp; R = yp; u_antes = yp; u_despues = yp;
for k = 1:N
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), [0 T], y0);
    y0 = y(end, :)';
    Fext = u/(b*max(a - y0(1), 1e-6)^4) - m*g;
    if abs(y0(2)) < vth && abs(Fext) <= Fs, y0(2) = 0; end
    if y0(2) == 0, ZM = 0; else, uzm = u; ZM = 1; end

    R(k) = caso.ref(tc(k));
    e = R(k) - y0(1);
    [~, xc] = ode45(@(t,x) A*x + B*e, [0 T], x0);
    x0 = xc(end, :)';
    u = min(max(C*x0 + D*e, 0), umax);
    u_antes(k) = u;
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02, u = uzm; end
    u_despues(k) = u;
    yp(k) = y0(1); yv(k) = y0(2); err(k) = e;
end

atascado = yv == 0;
rupturas = sum(atascado(1:end-1) & ~atascado(2:end));
out.tc = tc; out.yp = yp; out.yv = yv; out.err = err; out.R = R;
out.u_antes = u_antes; out.u_despues = u_despues;
out.met = struct( ...
    'error_rms_cm', sqrt(mean(err.^2)), ...
    'error_max_cm', max(abs(err)), ...
    'error_medio_cm', mean(err), ...
    'frac_atascado', mean(atascado), ...
    'rupturas', rupturas, ...
    'rupturas_por_minuto', rupturas/(caso.Tfin/60), ...
    'u_max_V', max(u_antes), 'u_min_V', min(u_antes), ...
    'frac_saturado', mean(u_antes >= umax - 1e-4), ...
    'x_min_cm', min(yp), 'x_max_cm', max(yp));
end

% ---------------------------------------------------------
function exportar(dest, n, r, zoom)
pre = fullfile(dest, n);
w = 2000;   % bloques para la vista completa (~2*N/w puntos)
escribir([pre '_posicion.csv'],  {'t','x','r'},            r.tc, [r.yp r.R],                1,     w);
escribir([pre '_velocidad.csv'], {'t','v'},                r.tc, r.yv,                      1,     w);
escribir([pre '_error.csv'],     {'t','e'},                r.tc, r.err,                     1,     w);
escribir([pre '_control.csv'],   {'t','u_antes','u_desp'}, r.tc, [r.u_antes r.u_despues],   [1 2], 2*w);
% ventana de detalle, con decimación más fina
k = find(r.tc >= zoom(1) & r.tc <= zoom(2));
escribir([pre '_detalle.csv'], {'t','x','r','v','u'}, r.tc(k), ...
    [r.yp(k) r.R(k) r.yv(k) r.u_despues(k)], [1 3 4], 12);
end

function escribir(archivo, cols, t, Y, clave, w)
% Decimación min-max en bloques de w muestras (conserva picos) + extremos.
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
