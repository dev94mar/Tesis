% =========================================================
% Magnetic levitation with PI + Karnopp friction
% =========================================================

format long
clear
close all
clc

% -----------------------------
% Simulation parameters
% -----------------------------
numero_de_iteracion = 1000000;
tfin = numero_de_iteracion - 1;

T = 0.001;
h = 0;
Tsim = tfin*T;

% -----------------------------
% Controller (PI)
% FIX #1: was loading 'PII_lic.mat' (wrong file); correct file is 'PI.mat'
% -----------------------------
load('PI.mat')
[A, B, C, D] = zp2ss(C.Z{:}, C.P{:}, C.K);

% -----------------------------
% Initial conditions
% -----------------------------
u  = 1;              % input (ZOH)
y0 = [-4; 0];        % [position; velocity]
x0 = zeros(size(C'));

% -----------------------------
% Storage
% -----------------------------
yp                   = zeros(tfin+1, 1);
yv                   = zeros(tfin+1, 1);
error_save           = zeros(tfin+1, 1);
u_save               = zeros(tfin+1, 1);
voltaje_antes_de_ZM  = zeros(tfin+1, 1);
voltaje_despues_de_ZM = zeros(tfin+1, 1);

% -----------------------------
% Plant parameters (for sticking clamp)
% -----------------------------
m   = 0.141;
a   = 7.17184;
b   = 1.6163e-6;
g   = 981;
Fs  = 20;
vth = 0.02;

% -----------------------------
% References
% -----------------------------
ref1 = -4.5;
ref2 = -4;

% =========================================================
% MAIN LOOP
% =========================================================
for k = 0:tfin

    lapzo = [h, h+T];

    % -------- PLANT (u held constant) --------
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), lapzo, y0);
    y0 = y(2, :)';

    % FIX #2: perfect sticking clamp — zero velocity when stuck to avoid drift
    gap  = max(a - y0(1), 1e-6);
    Fext = u / (b * m * gap^4) - m*g;
    if abs(y0(2)) < vth && abs(Fext) <= Fs
        y0(2) = 0;
    end

    yp(k+1) = y0(1);
    yv(k+1) = y0(2);

    % FIX #3: dead zone (ZM) logic
    if y0(2) == 0
        ZM = 0;
    else
        uzm = u;
        ZM  = 1;
    end

    % -------- Step Reference --------
    if k <= tfin/2
        R = ref1;
    else
        R = ref2;
    end

    % -------- Sinusoidal reference (commented out) --------
    % R = x0_ref + Aref*sin(wref*(k-1)*T);

    % -------- Ramp reference (commented out) --------
    % R = x_start + slope*(k-1)*T;

    % -------- Error --------
    error = R - yp(k+1);
    error_save(k+1) = error;

    % -------- PI controller --------
    [~, x] = ode45(@(t,x) A*x + B*error, lapzo, x0);
    x0 = x(2, :)';

    % -------- Control output --------
    u = C*x0 + D*error;
    u = min(max(u, 0), 5);
    voltaje_antes_de_ZM(k+1) = u;

    % FIX #3: apply dead zone
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end

    voltaje_despues_de_ZM(k+1) = u;
    u_save(k+1) = u;

end

% build reference vector matching tc
tc = (0:tfin) * T;
Rvec = zeros(size(tc));
half_idx = floor(length(tc)/2);
Rvec(1:half_idx) = ref1;
Rvec(half_idx+1:end) = ref2;

% =========================================================
% PLOTS
% FIX #4-6: added legends, titles, and missing xlabels
% =========================================================

figure(1)
plot(tc, yp, 'LineWidth', 1.5); hold on
plot(tc, Rvec, '--', 'LineWidth', 1.5)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Position [cm]', 'FontSize', 14)
title('Position vs Time', 'FontSize', 14)
legend({'Posicion', 'Referencia'}, 'FontSize', 12)
grid on

figure(2)
plot(tc, yv, 'LineWidth', 1.5)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Velocity [cm/s]', 'FontSize', 14)
title('Velocity vs Time', 'FontSize', 14)
legend('Velocity', 'FontSize', 12)
grid on

figure(3)
plot(tc, error_save, 'LineWidth', 1.5)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Error [cm]', 'FontSize', 14)
title('Tracking Error', 'FontSize', 14)
grid on

figure(4)
plot(tc, voltaje_despues_de_ZM, 'LineWidth', 1.5); hold on
plot(tc, voltaje_antes_de_ZM, '--', 'LineWidth', 1.5)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Voltage [V]', 'FontSize', 14)
title('Control Output', 'FontSize', 14)
legend('After ZM', 'Before ZM', 'FontSize', 12)
grid on
