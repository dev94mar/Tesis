
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
% -----------------------------
load('PII_lic.mat')
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
yp = zeros(tfin+1,1);
yv = zeros(tfin+1,1);
error_save = zeros(tfin+1,1);
u_save = zeros(tfin+1,1);

% -----------------------------
% References
% -----------------------------
ref1 = -4.5;
ref2 = -4;


% -----------------------------
% % Sinusoidal reference
% % % -----------------------------
% Aref  = 0.25;            % amplitude
% fref  = 0.001;             % frequency [Hz]
% wref  = 2*pi*fref;       % angular frequency
% x0_ref = -4.25;         % mean position
% 
% 
% % -----------------------------
% % Ramp reference (full duration)
% % -----------------------------
% x_start = -2;
% x_end   = -5.0;
% 
% slope = (x_end - x_start)/Tsim;

% =========================================================
% MAIN LOOP
% =========================================================
for k = 0:tfin

    lapzo = [h, h+T];

    % -------- PLANT (u held constant) --------
    [~, y] = ode45(@(t,y) maglev_karnopp(t, y, u), lapzo, y0);
    y0 = y(2, :)';

    yp(k+1) = y0(1);
    yv(k+1) = y0(2);

    % -------- Step Reference --------
    if k <= tfin/2
        R = ref1;
    else
        R = ref2;
    end
    % 

    % -------- Sinusoidal reference --------
    % R = x0_ref + Aref*sin(wref*(k-1)*T);


    % -------- Ramp refexrence --------
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
    u_save(k+1) = u;

end

% % build reference vector matching tc
tc = (0:tfin) * T;  % Time vector for the simulation
Rvec = zeros(size(tc));
half_idx = floor(length(tc)/2);
Rvec(1:half_idx) = ref1;
Rvec(half_idx+1:end) = ref2;
% 
% % -----------------------------
% % Time & reference for ramp plots
% % -----------------------------
% % Rvec = x_start + slope*tc;
% % Rvec = x0_ref + Aref*sin(wref*tc);
% 
% 
% % =========================================================
% % PLOTS
% % =========================================================

figure(1)
plot(tc, yp, 'LineWidth',1.5); hold on
plot(tc, Rvec,'--','LineWidth',1.5)
xlabel('Time [s]')
ylabel('Position')
grid on

figure(2)
plot(tc, yv, 'LineWidth', 1.5)
ylabel('Velocity')
grid on


figure(3)
plot(tc, error_save, 'LineWidth', 1.5)
xlabel('Time [s]')
ylabel('Error')
grid on

figure(4)
plot(tc, u_save, 'LineWidth', 1.5)
xlabel('Time [s]')
ylabel('Control input u')
title('Control Output')
grid on