tic
close all
clear
clc

T=0.25; %Define el paso de integración T/40
h=0; %inicio del tiempo de simulación
tfin=25000; % el tiempo final es (tfin)*(T/40)

e0=0;
error=0; % Condiciones iniciales del controlador
bandera=1;
ZM=0; %banderas para entrar o salir de la ZM

y0=[0,0.1];
[yf,y,yct,tc,ctrlzm,ctrl] = deal(zeros(tfin+1,1));
yc = zeros(tfin+1,2);

for k=0:tfin
    lapzo=[h,h+T];
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %C(s)=1.15*(s+1)/s   %Controlador

    funCtrl=@(t,y)(error); % error expresado como una ecuación diferencial
  %%%%%%%%%%%%%                          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   [~,ub]=ode45(funCtrl,lapzo,e0); % solucióon de la ecuación diferencial

   ei=ub(2,1); ep=error;

   u=1.15*(1*ei+1*ep); % controlador PI

   e0=ub(2,1); % condición inicial de la ecuacion diferencial

   ctrl(k+1)=u; % se guarda la solucion de la ecuacion diferencial en un array

  %%%%%%%%%%%%%%%  ZM ##############################

   if ZM==1
     if u<= uzm+0.25 && u>= uzm-0.15
      u=uzm;
     end
   end
   ctrlzm(k+1)=u;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %G(s)=(0.5*s+0.5)/(s^2+2*s+2)
  %Proceso

   funPro=@(t,y)[y(2);-2*y(2)-2*y(1)+u];

  %%%%%%%%%%%%%                           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   [t,yc]=ode45(funPro,lapzo,y0);

   y0=yc(2,:);

   yct(k+1)=yc(2,1);

   yf(k+1)=yc(2,2);

   Salida=0.5*yc(2,1)+0.5*yc(2,2);

   y(k+1)=Salida;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%% Condición para ZM %%%%%%%%%%%%%%%%%%%%%%%

   if abs(yc(2,2))<0.02 && bandera==1
     uzm=u; bandera=0; ZM=1;
   end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%% Salida de ZM %%%%%%%%%%%%%%%%%%%%%%%%%%%%

   if abs(yc(2,2))>=0.02
     bandera=1; ZM=0;
   end

  %%%%%%%%%%%%%%%%%%%%%%%%% Referencia %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   if k<=tfin/2
     R=1;
   else
     R=2;
   end
   error=R-Salida;

  %%%%%%%%%%%%%%%%%%%%%% tiempo real %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   tc(k+1)=t(2);

   h=t(2);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

 % Create a tiled layout for 2 rows and 1 column
tiledlayout(2, 1); 

% First plot: Posición y Velocidad
nexttile; % First subplot
plot(tc, y, tc, yf); 
grid on;
ylabel('Posición [cm] & Velocidad [cm/s]', 'FontSize', 18);
xlabel('Tiempo [s]', 'FontSize', 18);
title('Posición y Velocidad', 'FontSize', 18); % Title of the plot
legend('Posición', 'Velocidad', 'Referencia', 'FontSize', 14); % Legend

% Second plot: Voltaje Antes y Después de la ZM
nexttile; % Second subplot
plot(tc, ctrlzm, tc, ctrl); 
grid on;
ylabel('Voltaje [V]', 'FontSize', 18);
xlabel('Tiempo [s]', 'FontSize', 18);
title('Voltaje Antes y Después de la ZM', 'FontSize', 18); % Title of the plot
legend('Después de la ZM', 'Antes de la ZM', 'FontSize', 14); % Legend

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1);
set(gcf, 'Renderer', 'Painters');
set(gcf, 'Position', [100, 100, 800, 600]);
print(['figura', num2str(1)], '-depsc', '-r300');
