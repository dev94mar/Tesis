
clear variables
close
clc

%% Variables simbólicas

% Constantes del modelo
syms a b c g m lambda s

% Variables de estado y de entrada
syms x1 x2 u u1

% Variables de equilibrio
syms x1_eq 
%%
%%% Modelo en espacio de estados
dx1=x2;
dx2=(u/(m*b*(a+x1)^4))-g-c*x2;                      

dstates=[dx1,dx2];                                      
states=[x1,x2];                                        

%%% Linealización del modelo
A_l=jacobian(dstates,states);                              
B_l=jacobian(dstates,u);                                

%%% Puntos de equilibrio
[solx1, ~] = solve(dx2==0,dx1==0);   % solución del sistema de ecuaciones. Por ser de cuarto grado dx2 se tienen cuatro soluciones.                 
v=solve(solx1(4,1)==x1,u);           % se depeja la ecuación con respencto a u (voltaje)
v=subs(v,x1,x1_eq);

%%% Evaluacion del jacobiano en el punto de equilibrio
A_l=subs(A_l,u,v);
A_l=subs(A_l,x1,x1_eq);
B_l=subs(B_l,x1,x1_eq);

%% Modelo linealizado de tiempo continuo

%%% Parámetros
a=7.17184;              % constante a (cm)
b=1.6163e-6;            % constante b (V/N.cm^4)
c=8.563;                % coeficiente de fricción
g=981;                  % constante de la gravedad (N/cm*s^2)  
m=0.1410;               % masa (Kg)

%% Punto de equilibrio
x1_eq=4;               
x2_eq=0;

u=double(eval(v));      % voltaje de equilibrio 

%%% Evaluación del jacobiano en el punto de equilibrio
A=double(eval(A_l));
B=double(eval(B_l));
C=[1 0];
D=0;

%%% Observabilidad y controlabilidad
% Ob = obsv(A,C);
% Co = ctrb(A,B);

%%% Función de transferencia de tiempo continuo
  [num, den]=ss2tf(A,B,C,D);
 
%%% Caracterización de los polos y ceros de la función de transferencia
 G=tf(num(1,:),den);
 
%%%  Polos
polos=pole(G);
disp(polos)
controlSystemDesigner(G)

%%% figure;
% pzmap(G);
% % rlocus(G)
% %  step(G)
% % Polinomio de Cayley-Hamilton
% pol = eval(det(A-lambda*eye(2)));

%%% autovalores
% [D] = eig(A_l);

% lambda_1 = eval(D(1,1)); % valor de lambda_1
% lambda_2 = eval(D(2,1)); % valor de lambda_2