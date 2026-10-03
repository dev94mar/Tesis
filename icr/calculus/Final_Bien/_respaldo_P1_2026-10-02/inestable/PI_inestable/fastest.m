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
load('PI.mat')
[num, den] = zp2tf(C.Z{:}, C.P{:}, C.K); % from your file
[A, B, Cc, D] = tf2ss(num, den);

% -----------------------------
% Initial conditions
% -----------------------------
u  = 1;                 % input (ZOH)
y0 = [-4; 0];           % [position; velocity]
x0 = zeros(size(Cc'));  % controller states

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
    y0 = y(end,:)';

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
    x0 = x(end,:)';

    % -------- Control output --------
    u = Cc*x0 + D*error;
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



% =========================================================
% ----------- SUPPORT FUNCTIONS ---------------------------
% =========================================================

% ================= RK4 FIXED STEP ========================
function [t, x] = rk4_fixedstep(f, tspan, x0, h)
    t = tspan(1):h:tspan(2);
    x = zeros(length(t), length(x0));
    x(1,:) = x0;

    for k = 1:length(t)-1
        k1 = f(t(k), x(k,:)');
        k2 = f(t(k) + h/2, x(k,:)' + h*k1/2);
        k3 = f(t(k) + h/2, x(k,:)' + h*k2/2);
        k4 = f(t(k) + h,   x(k,:)' + h*k3);

        x(k+1,:) = x(k,:) + h*(k1 + 2*k2 + 2*k3 + k4)'/6;
    end
end


% ================= MAGLEV + KARNOPP ======================
function dy = maglev_karnopp(~, y, u)

m  = 0.141;
a  = 7.17184;
b  = 1.6163e-6;
c1 = 8.563;
g  = 981;

Fs  = 30;
vth = 0.02;

x = y(1);
v = y(2);

gap = max(a - x, 1e-6);
Fem  = u / (b * m * gap^4);
Fext = Fem - m*g;

if abs(v) > vth
    % sliding
    Ff = c1 * abs(v) * sign(v);
    dx = v;
    dv = (Fext - Ff)/m;

else
    % sticking region
    if abs(Fext) <= Fs
        dx = 0;
        dv = 0;
    else
        % breakaway
        Ff = Fs * sign(Fext);
        dx = v;
        dv = (Fext - Ff)/m;
    end
end

dy = [dx; dv];
end
