% =========================================================
% Comparación PI vs PII (P6) con el simulador corregido (P1)
% Zona muerta + Karnopp, u en [0, 3.5] V, mismas condiciones para ambos.
%   escalon: -2 -> -3 cm en t = 10 s, 40 s
%   trap:    un periodo de la referencia trapezoidal (-2/-3 cm, rampas de 250 s), 1250 s
% =========================================================
clear; close all; clc

aqui = fileparts(mfilename('fullpath'));
addpath(fullfile(aqui, 'PII_inestable'));
ctrl = {'PI',  fullfile(aqui, 'PI_inestable', 'PI.mat'); ...
        'PII', fullfile(aqui, 'PII_inestable', 'PII_lic.mat')};
pruebas = {'escalon', 40, @(t) -2 - (t >= 10); ...
           'trap', 1250, @ref_trapezoidal};

casos = {};
for i = 1:size(ctrl,1)
    S = load(ctrl{i,2}); [A,B,C,D] = zp2ss(S.C.Z{:}, S.C.P{:}, S.C.K);
    for j = 1:size(pruebas,1)
        casos{end+1} = struct('ctrl', ctrl{i,1}, 'prueba', pruebas{j,1}, 'Tfin', pruebas{j,2}, ...
                              'ref', pruebas{j,3}, 'A', A, 'B', B, 'C', C, 'D', D); %#ok<SAGROW>
    end
end

if isempty(gcp('nocreate')), parpool('Processes', numel(casos)); end
res = cell(size(casos));
parfor i = 1:numel(casos)
    res{i} = simular(casos{i});
end

out = struct();
for i = 1:numel(casos)
    out.(casos{i}.prueba).(casos{i}.ctrl) = res{i};
    fprintf('== %s / %s\n', casos{i}.prueba, casos{i}.ctrl); disp(res{i})
end
fid = fopen(fullfile(aqui, 'comparar_PI_PII_P6.json'), 'w');
fprintf(fid, '%s', jsonencode(out, 'PrettyPrint', true)); fclose(fid);

% ---------------------------------------------------------
function r = ref_trapezoidal(t)
tm = mod(t, 1250);
if tm < 250,      r = -2;
elseif tm < 500,  r = -2 - (tm - 250)/250;
elseif tm < 750,  r = -3;
elseif tm < 1000, r = -3 + (tm - 750)/250;
else,             r = -2;
end
end

function met = simular(c)
m = 0.141; a = 7.17184; b = 1.6163e-6; g = 981; Fs = 20; vth = 0.02;
T = 0.001; umax = 3.5;
A = c.A; B = c.B; C = c.C; D = c.D;
N = round(c.Tfin/T); tc = (0:N-1)'*T;
r0 = c.ref(0); ueq = m*g*b*(a - r0)^4;
Ad = c2d(ss(A, B, C, D), T).A;
x0 = [Ad - eye(size(A)); C] \ [zeros(size(A,1),1); ueq];
y0 = [r0; 0]; u = ueq; uzm = u; ZM = 0;
yp = zeros(N,1); yv = yp; err = yp; uu = yp;
for k = 1:N
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), [0 T], y0); y0 = y(end, :)';
    Fext = u/(b*max(a - y0(1), 1e-6)^4) - m*g;
    if abs(y0(2)) < vth && abs(Fext) <= Fs, y0(2) = 0; end
    if y0(2) == 0, ZM = 0; else, uzm = u; ZM = 1; end
    e = c.ref(tc(k)) - y0(1);
    [~, xc] = ode45(@(t,x) A*x + B*e, [0 T], x0); x0 = xc(end, :)';
    u = min(max(C*x0 + D*e, 0), umax);
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02, u = uzm; end
    yp(k) = y0(1); yv(k) = y0(2); err(k) = e; uu(k) = u;
end
at = yv == 0;
% duración de cada intervalo de atascamiento (después del primer movimiento)
i0 = find(~at, 1);
d = diff([0; at(i0:end); 0]); ini = find(d == 1); fin = find(d == -1);
dur = (fin - ini)*T;
met = struct('error_rms_cm', sqrt(mean(err(i0:end).^2)), 'error_max_cm', max(abs(err(i0:end))), ...
    'frac_atascado', mean(at(i0:end)), 'rupturas', numel(fin) - (fin(end) > numel(at) - i0), ...
    'atasc_medio_s', mean(dur), 'atasc_max_s', max(dur), ...
    'u_max_V', max(uu), 'frac_saturado', mean(uu >= umax - 1e-4), ...
    'diverge', any(yp < -20));
if strcmp(c.prueba, 'escalon')
    post = tc >= 10; [xpk, ~] = min(yp(post)); tl = tc >= 30;
    met.sobrepaso_pct = 100*(-3 - xpk);
    met.ciclo_pp_cm = max(yp(tl)) - min(yp(tl));
    met.error_medio_ult10s_cm = mean(err(tl));
else
    rampa = (tc >= 270 & tc < 500) | (tc >= 770 & tc < 1000);   % rampas sin sus primeros 20 s
    plano = (tc >= 520 & tc < 750) | (tc >= 1020);
    met.error_medio_rampas_cm = mean(abs(err(rampa)) .* sign(err(rampa)) .* sign(gradient(arrayfun(c.ref, tc(rampa)))));
    met.error_rms_rampas_cm = sqrt(mean(err(rampa).^2));
    met.error_rms_planos_cm = sqrt(mean(err(plano).^2));
end
end
