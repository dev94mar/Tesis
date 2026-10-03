clear;close all;clc;


%% Variables simbólicas

% Constantes del modelo
syms  a b c g m lambda h

% Variables de estado y de entrada
syms x1 x2 u u1

% Variables posición y velocidad
syms q dq 

% Variables de equilibrio
syms x1_eq z1 z2 s 

%% Modelo en espacio de estados
dx1=x2;
dx2=(u/(m*b*(a-x1)^4))-g-c*x2;    

eqs=[dx1,dx2];                                      
dev=[x1,x2];                                        

%% Linealización del modelo
A_l=jacobian(eqs,dev);                              
B_l=jacobian(eqs,u);                                

%% Puntos de equilibrio
[solx1, ~] = solve(dx2==0,dx1==0);                  
v1=solve(solx1(3,1)==x1,u);                         
v1=subs(v1,x1,x1_eq);

%% Evaluacion del jacobiano en el punto de equilibrio
 A_l=subs(A_l,u,v1);
 A_l=subs(A_l,x1,x1_eq);
 B_l=subs(B_l,x1,x1_eq);

%% Modelo linealizado de tiempo continuo

%% Punto de equilibrios
x1_eq=-4;            % punto de equilibrio x1=-4 


%% Parametros
a=7.17184;          % constante a (cm)
b=1.6163e-6;        % constante b (V/N.cm^4)
c=8.563;            % coeficiente de fricción
g=981;              % constante de la gravedad (N/cm*s^2)  
m=0.1410;           % masa (Kg)


%%
u=eval(v1); 
A=eval(A_l);
B=eval(B_l);
C=[1 0];
D=0;


%  Función de transferencia de tiempo continuo
  [num, den]=ss2tf(A,B,C,D);
% 
% %%% Caracterización de los polos y ceros de la función de transferencia
G=tf(num(1,:),den);
% Gp='G';
% num1 = num(1,:);
% den1 = den

% %% Polos
 polos=pole(G);
 display(polos);

% 
% %%% figure;
% figure(1);pzmap(G)
% figure(2);rlocus(G)
%   % sisotool(G)
% 
% % figure(3);step(-G)
% % sisotool(G)
% %%% Polinomio de Cayley-Hamilton
% % pol = eval(det(A-lambda*eye(2)));
% % 
% % autovalores
% [Diagonal] = eig(A_l);
% 
% % 
% lambda_1 = eval(Diagonal(1,1)); % valor de lambda_1
% lambda_2 = eval(Diagonal(2,1)); % valor de lambda_2
% arr = [lambda_2,lambda_1];
% D = diag(arr);
% V = [1 0; 0 1];             % Use identity (standard basis) as dummy eigenvectors
% A = V * D / V;              % Construct system matrix A
% 
% % Generate vector field
% [x, y] = meshgrid(-5:0.5:5, -5:0.5:5);
% u = A(1,1)*x + A(1,2)*y;
% v = A(2,1)*x + A(2,2)*y;
% 
% % Phase portrait
% figure;
% quiver(x, y, u, v, 'r')
% axis equal;
% xlabel('z_1');
% ylabel('z_2');


%%
% Run Simulink
% 
% % Load model
%  load_system('SLM/Estable.slx');
%  
% % Simulate model
%  sim('SLM/Estable.slx');
%  
%  open_system('SLM/Estable.slx');

% polos = -23.5057; 14.9427
