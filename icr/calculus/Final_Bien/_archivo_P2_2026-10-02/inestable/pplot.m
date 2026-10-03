close all;clear;clc
% % Define the constant
% a = 7.17184;
% 
% % Define the range for x1_star
% x1_star = linspace(0.5, 3.8, 1000);
% 
% % Compute the function
% y = 16 ./ (a - x1_star);
% y_max = y(end);
% % Plot the function
% figure;
% plot(x1_star, y, 'b', 'LineWidth', 2);
% xlabel('x_1^*', 'Interpreter', 'latex');
% ylabel('$\frac{16}{a - x_1^*}$', 'Interpreter', 'latex');
% title('Plot of $\frac{16}{a - x_1^*}$ with $a = 7.17184$', 'Interpreter', 'latex');
% grid on;
% 
% c=8.563;
% m=0.1410;
% 
% xx=(c/m)^2; display(xx-y_max)


% Parámetros del levitador
m = 0.141;          % masa (kg)
a = 7.17184;        % constante (cm)
b = 1.6163e-6;      % constante
c1 = 8.563;         % coeficiente de fricción
g = 9.81;           % aceleración gravitacional (m/s^2)
u_input = 1.0;      % control input

% Definición del sistema
f = @(t, y)[y(2); - g + u_input/(b * m * (a - y(1))^4)];

% Rango del espacio de estados
y1 = linspace(0.5, 3.8, 20);  % posición
y2 = linspace(0, 10, 20);     % velocidad

% Crear la malla de puntos
[x, y] = meshgrid(y1, y2);

% Inicializar derivadas
u = zeros(size(x));
v = zeros(size(x));

% Calcular el campo de vectores
t = 0;
for i = 1:numel(x)
    Yprime = f(t, [x(i); y(i)]);
    u(i) = Yprime(1);
    v(i) = Yprime(2);
end

% Graficar el campo vectorial
quiver(x, y, u, v, 'r');
xlabel('x_1 (posición)')
ylabel('x_2 (velocidad)')
axis auto
axis auto
