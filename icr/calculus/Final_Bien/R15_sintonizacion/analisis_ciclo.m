% =========================================================
% Análisis pedagógico del ciclo límite (R15)
%   1) Banda de fricción estática en voltaje y ganancias de baja frecuencia de PI y PII
%   2) Anatomía de los ciclos de regulacion_P4.mat (PII): fases, duración, voltaje, error
%   3) Mismo análisis con el PI (escalón -2 -> -3 cm, simulación nueva)
%   4) Controlador sin acción integral (PD derivado del PII): sin ciclo límite, error permanente
% Exporta CSV para TikZ y un JSON con todas las cifras citadas en la tesis.
% =========================================================
clear; clc
aqui = fileparts(mfilename('fullpath'));
raiz = fullfile(aqui, '..', 'inestable');
dest = fullfile(aqui, '..', '..', '..', 'context', 'Tesis', 'images', 'ciclo_results', 'tikz');
if ~exist(dest, 'dir'), mkdir(dest); end
addpath(fullfile(raiz, 'PII_inestable'));
m = 0.141; a = 7.17184; b = 1.6163e-6; c1 = 8.563; g = 981; Fs = 20; vth = 0.02; T = 1e-3;
R = struct();

%% 1) Banda de fricción y ganancias
x3 = -3; ue = m*g*b*(a - x3)^4;
R.banda = struct('u_e_V', ue, 'factor', Fs/(m*g), 'u_baja_V', ue*(1 - Fs/(m*g)), 'u_alta_V', ue*(1 + Fs/(m*g)), ...
                 'ancho_V', 2*ue*Fs/(m*g));
Cpii = zpk(load(fullfile(raiz, 'PII_inestable', 'PII_lic.mat')).C);
Cpi  = zpk(load(fullfile(raiz, 'PI_inestable', 'PI.mat')).C);
[rp, pp, kp] = residue(cell2mat(tf(Cpii).Num), cell2mat(tf(Cpii).Den));
[rq, pq, kq] = residue(cell2mat(tf(Cpi).Num),  cell2mat(tf(Cpi).Den));
% coeficientes de los términos 1/s^2 y 1/s (polo en el origen) y ganancia a frecuencia media
i0 = find(abs(pp) < 1e-9);  % polos en cero (doble)
R.pii = struct('K_ii', rp(i0(end)), 'K_i', rp(i0(1)), 'k_alta', kp, 'C_1rad', abs(freqresp(Cpii, 1)), 'C_10rad', abs(freqresp(Cpii, 10)), 'C_100rad', abs(freqresp(Cpii, 100)));
j0 = find(abs(pq) < 1e-9);
R.pi  = struct('K_i', rq(j0), 'k_alta', kq, 'C_1rad', abs(freqresp(Cpi, 1)), 'C_10rad', abs(freqresp(Cpi, 10)), 'C_100rad', abs(freqresp(Cpi, 100)));
G3 = tf(ss([0 1; 4*g/(a - x3) -c1], [0; 1/(m*b*(a - x3)^4)], [1 0], 0));
R.pi.Kv = abs(dcgain(minreal(tf('s')*Cpi*G3)));       % constante de velocidad del lazo (tipo 1)
R.pii.Ka = abs(dcgain(minreal(tf('s')^2*Cpii*G3)));   % constante de aceleración (tipo 2)

%% 2-4) simulaciones del escalón -2 -> -3 cm
Cpd = zpk(Cpii.Z{1}(abs(Cpii.Z{1} + 17.31) < 1e-2), -301.1, Cpii.K);   % PII sin integradores ni los ceros que los acompañan
ctrls = {'PII', Cpii, false; 'PI', Cpi, false; 'PD', Cpd, true};   % el PD lleva prealimentación de u_e(r)
R.pd = struct('ceros', Cpd.Z{1}', 'polos', Cpd.P{1}', 'k', Cpd.K, 'estable', all(arrayfun(@(x) isstable(feedback(Cpd*tf(ss([0 1; 4*g/(a - x) -c1], [0; 1/(m*b*(a - x)^4)], [1 0], 0)), 1)), [-2 -2.5 -3])));
sims = struct();
for i = 1:size(ctrls, 1)
    [tc, xp, vp, up, ep] = lazo(ctrls{i,2}, 40, ctrls{i,3});
    sims.(ctrls{i,1}) = struct('t', tc, 'x', xp, 'v', vp, 'u', up, 'e', ep);
    R.(lower(ctrls{i,1})).ciclos = anatomia(tc, xp, vp, up, ep, 20, 40);
end

% ventana de un ciclo típico para la figura de anatomía (PII y PI)
for nm = ["PII", "PI"]
    S = sims.(nm); k = S.t >= 20 & S.t <= 23;
    writetable(table(S.t(k), S.x(k), S.v(k), S.u(k), S.e(k), 'VariableNames', {'t','x','v','u','e'}), fullfile(dest, "anatomia_" + lower(nm) + ".csv"));
end
% comparación PD / PI / PII en todo el escalón (decimada)
k = 1:20:numel(sims.PII.t);
writetable(table(sims.PII.t(k), sims.PD.x(k), sims.PI.x(k), sims.PII.x(k), sims.PD.u(k), 'VariableNames', {'t','x_pd','x_pi','x_pii','u_pd'}), fullfile(dest, 'pd_pi_pii.csv'));
R.pd.error_final_cm = -3 - sims.PD.x(end);
R.pd.u_final_V = sims.PD.u(end); R.pd.k_dc = dcgain(Cpd);
R.pd.rigidez_fuerza_por_cm = dcgain(Cpd)/(b*(a - x3)^4);
R.pd.error_max_teorico_cm = Fs/R.pd.rigidez_fuerza_por_cm;
R.pd.v_final = sims.PD.v(end);
fid = fopen(fullfile(dest, 'analisis_ciclo.json'), 'w'); fprintf(fid, '%s', jsonencode(R, 'PrettyPrint', true)); fclose(fid);
disp(jsonencode(R, 'PrettyPrint', true))

%% ---------------------------------------------------------------
function [tc, yp, yv, uu, ee] = lazo(Cz, Tfin, ff)
if nargin < 3, ff = false; end
m = 0.141; a = 7.17184; b = 1.6163e-6; g = 981; Fs = 20; vth = 0.02; T = 1e-3;
[A, B, C, D] = ssdata(ss(Cz)); N = round(Tfin/T); tc = (0:N-1)'*T;
ueq = m*g*b*(a + 2)^4; Ad = c2d(ss(A, B, C, D), T).A;
if any(abs(eig(Ad) - 1) < 1e-9)          % con integradores: arranque sin salto
    x0 = [Ad - eye(size(A)); C] \ [zeros(size(A,1),1); ueq];
else                                     % sin integradores: estado estacionario con el error necesario
    x0 = zeros(size(A,1),1);
end
y0 = [-2; 0]; u = ueq; uzm = u; yp = zeros(N,1); yv = yp; uu = yp; ee = yp;
for k = 1:N
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), [0 T], y0); y0 = y(end, :)';
    Fe = u/(b*max(a - y0(1), 1e-6)^4) - m*g; if abs(y0(2)) < vth && abs(Fe) <= Fs, y0(2) = 0; end
    mov = y0(2) ~= 0; if mov, uzm = u; end
    r = -2 - (tc(k) >= 10); e = r - y0(1);
    [~, xc] = ode45(@(t,x) A*x + B*e, [0 T], x0); x0 = xc(end, :)';
    u = min(max(C*x0 + D*e + ff*m*g*b*(a - r)^4, 0), 3.5); if mov && u <= uzm + 0.025 && u >= uzm - 0.02, u = uzm; end
    yp(k) = y0(1); yv(k) = y0(2); uu(k) = u; ee(k) = e;
end
end

function c = anatomia(t, x, v, u, e, t0, t1)
% Estadística de los intervalos de atascamiento y deslizamiento en [t0, t1].
k = find(t >= t0 & t <= t1); at = v(k) == 0;
d = diff([0; at; 0]); ini = find(d == 1); fin = find(d == -1) - 1;
if isempty(ini), c = struct('n', 0, 'periodo_s', NaN, 'pp_cm', max(x(k)) - min(x(k))); return; end
ini = ini(2:end-1); fin = fin(2:end-1);                  % solo intervalos completos
dur = (fin - ini + 1)*(t(2) - t(1));
du = u(k(fin)) - u(k(ini));                             % cambio de voltaje durante cada atascamiento
e0 = e(k(ini));                                         % error con el que se atasca
desl = [];                                              % desplazamiento de cada deslizamiento
for j = 1:numel(fin) - 1, desl(end+1) = x(k(ini(j+1))) - x(k(fin(j))); end %#ok<AGROW>
c = struct('n', numel(dur), 'atasc_medio_s', mean(dur), 'atasc_max_s', max(dur), 'periodo_s', (t1 - t0)/max(1, numel(dur)/2), ...
    'du_medio_V', mean(abs(du)), 'e0_medio_cm', mean(abs(e0)), 'desliz_medio_cm', mean(abs(desl)), ...
    'pp_cm', max(x(k)) - min(x(k)), 'u_min_V', min(u(k)), 'u_max_V', max(u(k)));
end
