% =========================================================
% Comparison: PI vs PII controller — step reference
% Same plant (maglev_karnopp), same initial conditions
% =========================================================

format long
clear
close all
clc

% -----------------------------
% Paths to both controller .mat files
% -----------------------------
pi_dir  = fullfile(fileparts(mfilename('fullpath')), 'PI_inestable');
pii_dir = fullfile(fileparts(mfilename('fullpath')), 'PII_inestable');
addpath(pi_dir, pii_dir);

% -----------------------------
% Simulation parameters
% -----------------------------
tfin = 199999;       % 200 s total
T    = 0.001;
h    = 0;

% Step reference
ref1 = -4;           % initial position [cm]
ref2 = -5;           % step target    [cm]

% Plant parameters (for sticking clamp)
m   = 0.141;
a   = 7.17184;
b   = 1.6163e-6;
g   = 981;
Fs  = 20;
vth = 0.02;

% =========================================================
%  RUN PI CONTROLLER
% =========================================================
fprintf('Running PI ...\n');

load(fullfile(pi_dir, 'PI.mat'))
[Api, Bpi, Cpi, Dpi] = zp2ss(C.Z{:}, C.P{:}, C.K);

u    = 1;
y0   = [-4; 0];
x0   = zeros(size(Cpi'));

pi_yp    = zeros(tfin+1, 1);
pi_yv    = zeros(tfin+1, 1);
pi_err   = zeros(tfin+1, 1);
pi_u     = zeros(tfin+1, 1);

for k = 0:tfin
    lapzo = [h, h+T];

    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), lapzo, y0);
    y0 = y(2, :)';

    % sticking clamp
    gap  = max(a - y0(1), 1e-6);
    Fext = u / (b * m * gap^4) - m*g;
    if abs(y0(2)) < vth && abs(Fext) <= Fs
        y0(2) = 0;
    end

    pi_yp(k+1) = y0(1);
    pi_yv(k+1) = y0(2);

    if y0(2) == 0
        ZM = 0;
    else
        uzm = u;
        ZM  = 1;
    end

    R     = ref1 + (ref2 - ref1) * (k > tfin/2);
    error = R - pi_yp(k+1);
    pi_err(k+1) = error;

    [~, x] = ode45(@(t,x) Api*x + Bpi*error, lapzo, x0);
    x0 = x(2, :)';

    u = Cpi*x0 + Dpi*error;
    u = min(max(u, 0), 5);

    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end
    pi_u(k+1) = u;
end

% =========================================================
%  RUN PII CONTROLLER
% =========================================================
fprintf('Running PII ...\n');

load(fullfile(pii_dir, 'PII_lic.mat'))
[Apii, Bpii, Cpii, Dpii] = zp2ss(C.Z{:}, C.P{:}, C.K);

u    = 4;
y0   = [-4; 0];
x0   = zeros(size(Cpii, 2), 1);
h    = 0;

pii_yp  = zeros(tfin+1, 1);
pii_yv  = zeros(tfin+1, 1);
pii_err = zeros(tfin+1, 1);
pii_u   = zeros(tfin+1, 1);

for k = 0:tfin
    lapzo = [h, h+T];

    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), lapzo, y0);
    y0 = y(2, :)';

    % sticking clamp
    gap  = max(a - y0(1), 1e-6);
    Fext = u / (b * m * gap^4) - m*g;
    if abs(y0(2)) < vth && abs(Fext) <= Fs
        y0(2) = 0;
    end

    pii_yp(k+1) = y0(1);
    pii_yv(k+1) = y0(2);

    if y0(2) == 0
        ZM = 0;
    else
        uzm = u;
        ZM  = 1;
    end

    R     = ref1 + (ref2 - ref1) * (k > tfin/2);
    error = R - pii_yp(k+1);
    pii_err(k+1) = error;

    [~, x] = ode45(@(t,x) Apii*x + Bpii*error, lapzo, x0);
    x0 = x(2, :)';

    u = Cpii*x0 + Dpii*error;
    u = min(max(u, 0), 10);

    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end
    pii_u(k+1) = u;
end

% =========================================================
%  BUILD TIME & REFERENCE VECTORS
% =========================================================
tc   = (0:tfin) * T;
Rvec = ref1 * ones(size(tc));
Rvec(tc > tc(end)/2) = ref2;

% =========================================================
%  PLOTS
% =========================================================

figure(1)
plot(tc, pi_yp,  'b',  'LineWidth', 1.5); hold on
plot(tc, pii_yp, 'r',  'LineWidth', 1.5)
plot(tc, Rvec,   'k--','LineWidth', 1.2)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Position [cm]', 'FontSize', 14)
title('Step Response — Position', 'FontSize', 14)
legend({'PI', 'PII', 'Reference'}, 'FontSize', 12)
grid on

figure(2)
plot(tc, pi_err,  'b', 'LineWidth', 1.5); hold on
plot(tc, pii_err, 'r', 'LineWidth', 1.5)
yline(0, 'k--', 'LineWidth', 1.0)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Error [cm]', 'FontSize', 14)
title('Tracking Error', 'FontSize', 14)
legend({'PI', 'PII'}, 'FontSize', 12)
grid on

figure(3)
plot(tc, pi_u,  'b', 'LineWidth', 1.5); hold on
plot(tc, pii_u, 'r', 'LineWidth', 1.5)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Voltage [V]', 'FontSize', 14)
title('Control Output', 'FontSize', 14)
legend({'PI', 'PII'}, 'FontSize', 12)
grid on

figure(4)
plot(tc, pi_yv,  'b', 'LineWidth', 1.5); hold on
plot(tc, pii_yv, 'r', 'LineWidth', 1.5)
xlabel('Time [s]', 'FontSize', 14)
ylabel('Velocity [cm/s]', 'FontSize', 14)
title('Velocity', 'FontSize', 14)
legend({'PI', 'PII'}, 'FontSize', 12)
grid on

fprintf('Done.\n');
