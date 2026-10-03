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

% Inicialización de los vectores
[yv,yp,voltaje_despues_de_ZM,volaje_antes_de_la_ZM,tc, error_save]=deal(zeros(tfin+1,1));

% Output reference
ref1=-4;
ref2=-5;


for k = 0:tfin

    lapzo = [h, h+T];

    % plant
    [~, y] = ode45(@(t, y) [y(2); -c1*y(2) - g + u/(b*m*(a-y(1))^4)],lapzo, y0);

     y0 = y(2, :);

    % position and velocity register
    [yp(k+1), yv(k+1)] = deal(y(2, 1), y(2, 2));
 
       
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
    % display(error)
    error_save(k+1)=error;

    % controller
    [t, x] = ode45(@(t, x) (A*x + B*error), lapzo, x0);

    x0 = x(2, :);
    
    u = C*x0' + D*error;
    
    u = min(max(u, 0), 10);

    volaje_antes_de_la_ZM(k+1) = u;

    % DZ width
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

figure(21)
plot(tc, yp, tc, Rvec);
grid on;
ylabel('Posición [cm] & Velocidad [cm/s]','FontSize', 18)
xlabel('Tiempo [s]','FontSize',18)
title(legend('Posición','Velocidad', 'Referencia','FontSize', 18),'Leyenda')

figure(22);
plot(tc, voltaje_despues_de_ZM,tc,volaje_antes_de_la_ZM);
grid on;
ylabel('Voltaje [V]','FontSize', 18)
xlabel('Tiempo [s]','FontSize', 18)
title(legend('Después de la ZM','Antes de la ZM','FontSize', 18.),'Leyenda')

figure(23);
plot(tc, error_save);
grid on;
ylabel('Error', 'FontSize', 18);
xlabel('Tiempo [s]', 'FontSize', 18);




% %%%%%%%%%%%%%%%%%%%%%   Guardar gráficas       %%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % Ruta de origen y destino para la copia de los archivos EPS
% ruta_origen = fileparts(mfilename('fullpath'));  % Ruta actual del archivo de código MATLAB
% ruta_destino = '/Users/marino/Downloads/figuras/controladores/estable/';  % Ruta de destino para guardar las figuras EPS
% 
% % Copiar las figuras EPS a la ruta de destino
% for i = 1:2
%     figura_origen = fullfile(ruta_origen, ['figura', num2str(i), '.eps']);
%     figura_destino = fullfile(ruta_destino, ['figura', num2str(i), '.eps']);
%     copyfile(figura_origen, figura_destino);
% end
% 
% toc
% 
% 
% % Parámetros del modelo de Stribeck
% mu_s = 0.8;   % Coeficiente de fricción estática
% mu_c = 0.6;   % Coeficiente de fricción cinética
% v_c = 0.05;   % Velocidad de conmutación
% v = 0:0.01:1; % Velocidad relativa
% 
% % Cálculo de la fuerza de fricción no lineal utilizando el modelo de Stribeck
% f_friction = zeros(size(v));
% for i = 1:length(v)
%     if v(i) < v_c
%         f_friction(i) = mu_s * v(i);
%     else
%         f_friction(i) = mu_c * v_c + (mu_s - mu_c) * (v(i) - v_c);
%     end
% end
% 
% % Gráfico de la fuerza de fricción no lineal
% plot(v, f_friction);
% xlabel('Velocidad relativa');
% ylabel('Fuerza de fricción');
% title('Modelo de Stribeck - Fricción no lineal');