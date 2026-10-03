% =========================================================
% Magnetic levitation — Trapezoidal reference tracking
% PII controller + Karnopp friction model
% =========================================================
% Reference profile (period = 1250 s):
%   [0,   250] s  -> R = -4 cm        (flat)
%   [250, 500] s  -> ramp -4 to -5 cm (slope = -1/250 cm/s)
%   [500, 750] s  -> R = -5 cm        (flat)
%   [750,1000] s  -> ramp -5 to -4 cm (slope = +1/250 cm/s)
%   [1000,1250] s -> R = -4 cm        (flat)
% Total simulation: 2500 s (2 complete periods)
% =========================================================

format long
clear
close all
clc

% -----------------------------
% Simulation parameters
% -----------------------------
numero_de_iteracion = 2500000;   % 2500 s at T=0.001 s
tfin = numero_de_iteracion - 1;

T    = 0.001;
h    = 0;
Tsim = tfin * T;                 % 2500 s

% -----------------------------
% Controller (PII)
% -----------------------------
load('PII.mat')
[A, B, C, D] = zp2ss(C.Z{:}, C.P{:}, C.K);

% -----------------------------
% Initial conditions
% -----------------------------
u  = 1;              % input (ZOH)
y0 = [-4; 0];        % [position (cm); velocity (cm/s)]
x0 = zeros(size(C'));

% -----------------------------
% Storage
% -----------------------------
yp                  = zeros(tfin+1, 1);
yv                  = zeros(tfin+1, 1);
error_save          = zeros(tfin+1, 1);
volaje_antes_de_la_ZM = zeros(tfin+1, 1);
voltaje_despues_de_ZM = zeros(tfin+1, 1);

% =========================================================
% MAIN LOOP
% =========================================================
for k = 0:tfin

    lapzo = [h, h+T];

    % -------- PLANT (u held constant, ZOH) --------
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), lapzo, y0);

    y0 = y(2, :)';

    % ======== PERFECT STICKING CLAMP ========
    m   = 0.141;
    a   = 7.17184;
    b   = 1.6163e-6;
    g   = 981;
    Fs  = 20;
    vth = 0.02;

    x    = y0(1);
    v    = y0(2);

    gap  = max(a - x, 1e-6);
    Fext = u / (b * gap^4) - m*g;   % P1: fuerza magnetica sin doble division por m

    if abs(v) < vth && abs(Fext) <= Fs
        y0(2) = 0;     % <<--- PERFECT ZERO VELOCITY
    end

    yp(k+1) = y0(1);
    yv(k+1) = y0(2);

    % -------- Trapezoidal reference --------
    t_now = k * T;
    t_mod = mod(t_now, 1250);

    if t_mod < 250
        R = -4;
    elseif t_mod < 500
        R = -4 - (t_mod - 250) / 250;   % ramp -4 -> -5
    elseif t_mod < 750
        R = -5;
    elseif t_mod < 1000
        R = -5 + (t_mod - 750) / 250;   % ramp -5 -> -4
    else
        R = -4;
    end

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

    % -------- Dead-zone compensation --------
    if y0(2) == 0
        ZM = 0;               % exit dead zone
    else
        uzm = u;
        ZM  = 1;              % inside dead zone
    end

    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end

    voltaje_despues_de_ZM(k+1) = u;

    % -------- Advance time --------
    h = h + T;

end

% =========================================================
% Build reference vector for plotting
% =========================================================
tc   = (0:tfin) * T;
Rvec = zeros(size(tc));

for i = 1:length(tc)
    t_mod = mod(tc(i), 1250);
    if t_mod < 250
        Rvec(i) = -4;
    elseif t_mod < 500
        Rvec(i) = -4 - (t_mod - 250) / 250;
    elseif t_mod < 750
        Rvec(i) = -5;
    elseif t_mod < 1000
        Rvec(i) = -5 + (t_mod - 750) / 250;
    else
        Rvec(i) = -4;
    end
end

% =========================================================
% Destination folder
% =========================================================
ruta_destino = '/Users/marino/DEVELOPMENT/TESIS/Tesis/images/seguimiento_results';

if ~exist(ruta_destino, 'dir')
    mkdir(ruta_destino)
end

% =========================================================
% PLOTS + SAVE
% =========================================================

% --- Figure 1: Position ---
f1 = figure(1);
plot(tc, yp, 'LineWidth', 3); hold on
plot(tc, Rvec, '--', 'LineWidth', 1.5)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('posición [cm]', 'FontSize', 36)
legend('Posición levitante', 'Referencia trapezoidal', ...
       'FontSize', 30, 'Location', 'southeast')
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f1, 'PaperPositionMode', 'auto');
hold off
saveas(f1, fullfile(ruta_destino, 'fig_trap_pos.eps'), 'epsc')

% --- Figure 2: Velocity ---
f2 = figure(2);
plot(tc, yv, 'LineWidth', 3)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('velocidad [cm/s]', 'FontSize', 36)
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f2, 'PaperPositionMode', 'auto');
saveas(f2, fullfile(ruta_destino, 'fig_trap_vel.eps'), 'epsc')

% --- Figure 3: Tracking error ---
f3 = figure(3);
plot(tc, error_save, 'LineWidth', 3)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('error [cm]', 'FontSize', 36)
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f3, 'PaperPositionMode', 'auto');
saveas(f3, fullfile(ruta_destino, 'fig_trap_error.eps'), 'epsc')

% --- Figure 4: Control signal (before / after dead zone) ---
f4 = figure(4);
plot(tc, volaje_antes_de_la_ZM, 'LineWidth', 3); hold on
plot(tc, voltaje_despues_de_ZM, 'LineWidth', 3)
xlabel('tiempo [s]', 'FontSize', 36)
ylabel('señal de control [V]', 'FontSize', 36)
legend('Antes de zona muerta', 'Después de zona muerta', ...
       'FontSize', 30, 'Location', 'northeast')
grid on
ax = gca;
ax.XAxis.FontSize = 22;
ax.YAxis.FontSize = 22;
set(f4, 'PaperPositionMode', 'auto');
hold off
saveas(f4, fullfile(ruta_destino, 'fig_trap_ctrl.eps'), 'epsc')
