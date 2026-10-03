%tic
format long
clear
close all
clc


% Parameters
m = 0.141;          % mass
a = 7.17184;        % constante
b = 1.6163e-6;      % constante
c1 = 8.563;         % friction coeficient
g = 981;            % gravity aceleration

numero_de_iteracion = 1000000;
tfin = numero_de_iteracion-1; % simulation time

T = 0.001;       % integration step
h = 0;           % initial integration step

load('PII_lic.mat')
[A, B, C, D] = zp2ss(C.Z{:}, C.P{:}, C.K);

% Initial conditions
u = 4;           % initial voltaje
y0 = [-4, 0];    % initial position and velocity
x0 = zeros(size(C,2),1);

% Inicializacion de los vectores
% FIX #6: corrected typo 'volaje' -> 'voltaje'
[yv, yp, voltaje_despues_de_ZM, voltaje_antes_de_la_ZM, tc, error_save] = deal(zeros(tfin+1, 1));

% Output reference
ref1 = -4;
ref2 = -5;


for k = 0:tfin

    lapzo = [h, h+T];

    % plant
    [~, y] = ode45(@(t, y) [y(2); -c1*y(2) - g + u/(b*m*(a-y(1))^4)], lapzo, y0);

    y0 = y(2, :);

    % position and velocity register
    [yp(k+1), yv(k+1)] = deal(y(2, 1), y(2, 2));

    % FIX #4: ZM exit condition checks velocity magnitude (intentional —
    % exits dead zone when plant velocity is near zero / settled)
    if abs(y0(1,2)) <= 0.2
        ZM = 0;               % get out from ZM
    else
        uzm = u;
        ZM = 1;               % get into ZM
    end

    % References
    if k <= tfin/2
        R = ref1;
    else
        R = ref2;
    end

    % Error
    error = R - yp(k+1);
    error_save(k+1) = error;

    % controller
    [t, x] = ode45(@(t, x) (A*x + B*error), lapzo, x0);

    x0 = x(2, :);

    u = C*x0' + D*error;

    u = min(max(u, 0), 10);

    % FIX #6: renamed from 'volaje_antes_de_la_ZM'
    voltaje_antes_de_la_ZM(k+1) = u;

    % FIX #3: dead zone bands are intentionally asymmetric (+0.025 / -0.02)
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end

    voltaje_despues_de_ZM(k+1) = u;

    [tc(k+1), h] = deal(t(2));

end

% build reference vector matching tc
Rvec = zeros(size(tc));
half_idx = floor(length(tc)/2);
Rvec(1:half_idx) = ref1;
Rvec(half_idx+1:end) = ref2;

% FIX #1: added yv to plot so all 3 legend entries have a corresponding curve
% FIX #2: separated legend() and title() calls so figure gets its own title
figure(21)
plot(tc, yp, tc, yv, tc, Rvec);
grid on;
ylabel('Posicion [cm] & Velocidad [cm/s]', 'FontSize', 18)
xlabel('Tiempo [s]', 'FontSize', 18)
title('Posicion y Velocidad vs Tiempo', 'FontSize', 18)
legend('Posicion', 'Velocidad', 'Referencia', 'FontSize', 18)

figure(22);
plot(tc, voltaje_despues_de_ZM, tc, voltaje_antes_de_la_ZM);
grid on;
ylabel('Voltaje [V]', 'FontSize', 18)
xlabel('Tiempo [s]', 'FontSize', 18)
title('Voltaje de control', 'FontSize', 18)
legend('Despues de la ZM', 'Antes de la ZM', 'FontSize', 18)

figure(23);
plot(tc, error_save);
grid on;
ylabel('Error', 'FontSize', 18);
xlabel('Tiempo [s]', 'FontSize', 18);
title('Error de seguimiento', 'FontSize', 18);
