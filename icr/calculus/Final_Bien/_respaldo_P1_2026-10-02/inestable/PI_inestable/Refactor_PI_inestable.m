% =========================================================
% Magnetic levitation with PI + Karnopp friction
% =========================================================

format long
clear
% close all
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
yp = zeros(tfin+1,1);
yv = zeros(tfin+1,1);
error_save = zeros(tfin+1,1);
u_save = zeros(tfin+1,1);
volaje_antes_de_la_ZM = zeros(tfin+1,1);
voltaje_despues_de_ZM = zeros(tfin+1,1);

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

    if y0(2) == 0
         ZM = 0;               % get out from ZM
    else
         uzm = u;              
         ZM = 1;               % get into ZM
    end

    % -------- Step Reference --------
    if k <= tfin/2
        R = ref1;
    else
        R = ref2;
    end
    % 

    % -------- Sinusoidal reference --------
    % t_now = (k-1)*T;
    % R = x0_ref + Aref*sin(wref*t_now);


    % -------- Ramp refexrence --------
    % t_now = (k-1)*T;
    % R = x_start + slope*t_now;

    % -------- Error --------
    error = R - yp(k+1);
    error_save(k+1) = error;

    % -------- PI controller --------
    [~, x] = ode45(@(t,x) A*x + B*error, lapzo, x0);
    x0 = x(2, :)';

    % -------- Control output --------
    u = C*x0 + D*error;
    u = min(max(u, 0), 5);
    volaje_antes_de_la_ZM(k+1) = u;

    % DZ width
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end
    
    voltaje_despues_de_ZM(k+1) = u;

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

figure(11)
plot(tc, yp, 'LineWidth',1.5); hold on
plot(tc, Rvec,'--','LineWidth',1.5)
xlabel('Time [s]')
ylabel('Position')
grid on

figure(22)
plot(tc, yv, 'LineWidth', 1.5)
ylabel('Velocity')
grid on


figure(33)
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