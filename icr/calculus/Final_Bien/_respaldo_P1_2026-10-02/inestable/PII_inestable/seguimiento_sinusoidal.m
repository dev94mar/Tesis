% =========================================================
% seguimiento_sinusoidal.m
% Magnetic levitation: sinusoidal reference tracking
% with PII controller + Karnopp friction model
% =========================================================

format long
clear
close all
clc

% -----------------------------
% Simulation parameters
% -----------------------------
% 2 000 000 steps × T=0.001 s = 2000 s
% fref = 0.001 Hz → period = 1000 s → 2 full cycles
numero_de_iteracion = 2000000;
tfin = numero_de_iteracion - 1;

T = 0.001;
h = 0;
Tsim = tfin * T;

% -----------------------------
% Controller (PII)
% -----------------------------
load('PII.mat')
[A, B, C, D] = zp2ss(C.Z{:}, C.P{:}, C.K);

% -----------------------------
% Initial conditions
% -----------------------------
u  = 1;              % initial control input [V]
y0 = [-4.25; 0];     % [position (cm); velocity (cm/s)]
x0 = zeros(size(C'));

% -----------------------------
% Sinusoidal reference parameters
% -----------------------------
Aref   = 0.25;        % amplitude [cm]
fref   = 0.001;       % frequency [Hz]
wref   = 2*pi*fref;   % angular frequency [rad/s]
x0_ref = -4.25;       % mean (offset) position [cm]

% -----------------------------
% Storage
% -----------------------------
yp             = zeros(tfin+1, 1);
yv             = zeros(tfin+1, 1);
error_save     = zeros(tfin+1, 1);
volaje_antes_de_la_ZM = zeros(tfin+1, 1);
voltaje_despues_de_ZM = zeros(tfin+1, 1);

% =========================================================
% MAIN LOOP
% =========================================================
for k = 0:tfin

    lapzo = [h, h+T];

    % -------- PLANT (u held constant — ZOH) --------
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), lapzo, y0);

    y0 = y(2, :)';

    % ======== PERFECT STICKING CLAMP ========
    m  = 0.141;
    a  = 7.17184;
    b  = 1.6163e-6;
    g  = 981;
    Fs = 20;
    vth = 0.02;

    x = y0(1);
    v = y0(2);

    gap  = max(a - x, 1e-6);
    Fext = u / (b * m * gap^4) - m*g;

    if abs(v) < vth && abs(Fext) <= Fs
        y0(2) = 0;     % <<--- PERFECT ZERO VELOCITY
    end

    yp(k+1) = y0(1);
    yv(k+1) = y0(2);

    % -------- Sinusoidal Reference --------
    t_now = k * T;
    R = x0_ref + Aref * sin(wref * t_now);

    % -------- Error --------
    error = R - yp(k+1);
    error_save(k+1) = error;

    % -------- PII controller --------
    [~, x] = ode45(@(t,x) A*x + B*error, lapzo, x0);
    x0 = x(2, :)';

    % -------- Control output --------
    u = C*x0 + D*error;
    u = min(max(u, 0), 5);

    volaje_antes_de_la_ZM(k+1) = u;

    % -------- Dead zone (velocity-based) --------
    if y0(2) == 0
        ZM = 0;          % exit ZM
    else
        uzm = u;
        ZM  = 1;         % enter ZM
    end

    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end

    voltaje_despues_de_ZM(k+1) = u;

    h = h + T;
end

% =========================================================
% Time vector and reference signal
% =========================================================
tc   = (0:tfin) * T;
Rvec = x0_ref + Aref * sin(wref * tc);

% =========================================================
% Destination folder
% =========================================================
ruta_destino = fullfile(fileparts(mfilename('fullpath')), ...
    '../../../../context/Tesis/images/seguimiento_results');

if ~exist(ruta_destino, 'dir')
    mkdir(ruta_destino)
end

% =========================================================
% PLOTS + SAVE
% =========================================================

f1 = figure(1);
plot(tc, yp, 'LineWidth', 3); hold on
plot(tc, Rvec, '--', 'LineWidth', 1.5)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('posición [cm]', 'FontSize', 36)
legend('Posición levitante', 'Referencia senoidal', ...
    'FontSize', 30, 'Location', 'best')
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f1, 'PaperPositionMode', 'auto');
hold off
saveas(f1, fullfile(ruta_destino, 'fig_sen_pos.eps'), 'epsc')

f2 = figure(2);
plot(tc, yv, 'LineWidth', 3)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('velocidad [cm/s]', 'FontSize', 36)
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f2, 'PaperPositionMode', 'auto');
saveas(f2, fullfile(ruta_destino, 'fig_sen_vel.eps'), 'epsc')

f3 = figure(3);
plot(tc, error_save, 'LineWidth', 3)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('error [cm]', 'FontSize', 36)
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f3, 'PaperPositionMode', 'auto');
saveas(f3, fullfile(ruta_destino, 'fig_sen_error.eps'), 'epsc')

f4 = figure(4);
plot(tc, volaje_antes_de_la_ZM, 'LineWidth', 3); hold on
plot(tc, voltaje_despues_de_ZM, 'LineWidth', 3)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('señal de control [V]', 'FontSize', 36)
legend('Antes de zona muerta', 'Después de zona muerta', ...
    'FontSize', 30, 'Location', 'best')
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f4, 'PaperPositionMode', 'auto');
hold off
saveas(f4, fullfile(ruta_destino, 'fig_sen_ctrl.eps'), 'epsc')
