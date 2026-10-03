% =========================================================
% Magnetic levitation with PI + Karnopp friction
% RK4 FIXED STEP (No ODE45 Anywhere)
% =========================================================
format long
clear
close all
clc

% -----------------------------
% Simulation parameters
% -----------------------------
numero_de_iteracion = 100000;
tfin = numero_de_iteracion - 1;

T = 0.001;          % sampling period
h = 0;              % time start

% -----------------------------
% Controller (PI)
% -----------------------------
load('PII.mat')
[A, B, C, D] = zp2ss(C.Z{:}, C.P{:}, C.K);

% -----------------------------
% Initial conditions
% -----------------------------
u  = 1;                 % input (ZOH)
y0 = [-4; 0];           % [position; velocity]
x0 = zeros(size(C'));  % controller states

% -----------------------------
% Storage
% -----------------------------
yp = zeros(tfin+1,1);
yv = zeros(tfin+1,1);
error_save = zeros(tfin+1,1);
u_save = zeros(tfin+1,1);
dv_save = zeros(tfin+1,1);

% -----------------------------
% References (sinusoidal / ramp / whatever later)
% -----------------------------
ref1 = -4.5;
ref2 = -4;

% =========================================================
% MAIN LOOP
% =========================================================
for k = 0:tfin

    lapzo = [h, h+T];

    % -------- PLANT (RK4, u held constant) --------
    [~, y] = rk4_fixedstep(@(t,y) maglev_karnopp(t,y,u), lapzo, y0, T);
    y0 = y(2, :)';

    yp(k+1) = y0(1);
    yv(k+1) = y0(2);

    % also store acceleration
    dy = maglev_karnopp(0, y0, u);
    dv_save(k+1) = dy(2);

    % -------- Reference --------
    if k <= tfin/2
        R = ref1;
    else
        R = ref2;
    end

    % -------- Error --------
    error = R - yp(k+1);
    error_save(k+1) = error;

    % -------- PI controller (RK4) --------
    [~, x] = rk4_fixedstep(@(t,x) A*x + B*error, lapzo, x0, T);
    x0 = x(2, :)';

    % -------- Control output --------
    u = C*x0 + D*error;
    u = min(max(u, 0), 5);
    u_save(k+1) = u;

    h = h + T;
end

% build time vector
tc = (0:tfin) * T;

% build reference vector
Rvec = zeros(size(tc));
half_idx = floor(length(tc)/2);
Rvec(1:half_idx) = ref1;
Rvec(half_idx+1:end) = ref2;

% =========================================================
% PLOTS
% =========================================================
figure(1)
plot(tc, yp, 'LineWidth', 1.5); hold on
plot(tc, Rvec, '--', 'LineWidth', 1.5)
ylabel('Position')
legend({'Position','Reference'})
grid on

figure(2)
plot(tc, yv, 'LineWidth', 1.5)
ylabel('Velocity')
grid on

figure(3)
plot(tc, dv_save, 'LineWidth', 1.5)
xlabel('Time [s]')
ylabel('Acceleration dv')
title('Acceleration')
grid on

figure(4)
plot(tc, u_save, 'LineWidth', 1.5)
xlabel('Time [s]')
ylabel('Control input u')
title('Control Output')
grid on
