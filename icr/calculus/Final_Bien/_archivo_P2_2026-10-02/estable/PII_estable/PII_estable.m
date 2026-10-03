clear
close all
clc

numero_de_iteracion = 100000;
tfin = numero_de_iteracion-1; % tiempo de simulacion

% Inicialización de los vectores
[yv,yp,y,voltaje_despues_de_ZM,volaje_antes_de_la_ZM,tc]=deal(zeros(tfin+1,1));
yc = zeros(tfin+1,2);

T = 0.025;       % paso de integración
h = 0;          % inicio del paso de integración

%%% Initial conditions
u = 1;           % voltaje inicial del paso de integración
error = 0.7;     % error inicial
y0 = [0.7, 0]; % condicion inicial
ZM = 0;

% Referencias de posición
ref1=1;
ref2=2;



% Parámetros del levitador
m = 0.141;          % masa
a = 7.17184;        % constante
b = 1.6163e-6;      % constante
c1 = 8.563;         % coeficiente de fricción
g = 981;            % aceleración de la gravedad

load('CInestable.mat')

[num, den] = zp2tf(C.Z{:}, C.P{:}, C.K);

[A, B, C, D] = tf2ss(num, den);

x0 = zeros(size(C'));

for k = 0:tfin

    lapzo = [h, h+T];


    [~, x] = ode45(@(t, x) (A*x + B*error), lapzo, x0);
    [x, x0] = deal(x(2,:)); 

    u = C*x' +D*error;

    
    volaje_antes_de_la_ZM(k+1) = u;
    
    if ZM == 1 && u <= uzm + 0.025 && u >= uzm - 0.02
        u = uzm;
    end
    
    voltaje_despues_de_ZM(k+1) = u;
    
    [t, yc] = ode45(@(t, y) [y(2); -c1*y(2) - g + u/(b*m*(a+y(1))^4)], lapzo, y0);
    
    y0 = yc(2, :);
   
    % registro de la posicion
    [yp(k+1), y(k+1)] = deal(yc(2, 1));

    % registro de la velocida
    yv(k+1) = yc(2, 2);

  
    if abs(yc(2, 2)) >= 0.045 
        ZM = 0;               
    else
        uzm = u;              
        ZM = 1;
    end


    %%% Referencia
    if k <= tfin/2
        
        % Referencia con valor 2
        R = ref1;
    else

        % Referencia con valor 1
        R = ref2;
    end
    
    %%% Error
      error = R - y(k+1);

    
    [tc(k+1), h] = deal(t(2)); % Registra el tiempo y guarda el inicio del intervalo de tiempo
end


% figure;
% 
% % Normalize signals to their max value
% yv_norm = yv / max(abs(yv));
% v_desp_norm = voltaje_despues_de_ZM / max(abs(voltaje_despues_de_ZM));
% v_antes_norm = volaje_antes_de_la_ZM / max(abs(volaje_antes_de_la_ZM));
% 
% % Plot all on same axes
% plot(tc, yv_norm, 'LineWidth', 1.5);
% hold on;
% % plot(tc, v_desp_norm, 'LineWidth', 1.5);
% plot(tc, v_antes_norm, 'LineWidth', 1.5);
% grid on;
% 
% xlabel('Tiempo [s]', 'FontSize', 14);
% ylabel('Valor Normalizado', 'FontSize', 14);
% legend({'Velocidad', 'Voltaje después ZM', 'Voltaje antes ZM'}, ...
%        'FontSize', 12, 'Location', 'best')





figure(1);
plot(tc, y, tc, yv);
grid on;
ylabel('Posición [cm] & Velocidad [cm/s]','FontSize', 18)
xlabel('Tiempo [s]','FontSize',18)
title(legend('Posición','Velocidad', 'Referencia','FontSize', 18),'Leyenda')

figure(2);
plot(tc, voltaje_despues_de_ZM, tc, volaje_antes_de_la_ZM);
grid on;
ylabel('Voltaje [V]','FontSize', 18)
xlabel('Tiempo [s]','FontSize', 18)
title(legend('Después de la ZM','Antes de la ZM','FontSize', 18.),'Leyenda')
 




% %%%%%%%%%%%%%%%%%%%%%   Guardar gráficas       %%%%%%%%%%%%%%%%%%%%%%%%%

% % Guardar las figuras en formato EPS
% for i = 1:2
%     figure(i);
%     set(gcf, 'Renderer', 'Painters');
%     set(gcf, 'Position', [100, 100, 800, 600]);
%     print(['figura', num2str(i)], '-depsc', '-r300');
% end

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

