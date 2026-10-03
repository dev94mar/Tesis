% Verificación de la corrección P1 del simulador maglev_karnopp
root = '/Users/marino/DEVELOPMENT/TESIS/claude/icr/calculus/Final_Bien';
out  = fileparts(mfilename('fullpath'));
m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981;

% --- versión anterior (respaldo) como función anónima
old = @(y,u) old_plant(y,u);
addpath(fullfile(root,'inestable','PII_inestable'));
new = @(y,u) maglev_karnopp(0,y,u);

%% 1) Voltaje de equilibrio
xs = -4;
ueq_lin = m*g*b*(a-xs)^4;
ueq_new = fzero(@(u) [0 1]*new([xs;1],u) + c1*1, 3);   % fuerza neta nula (descontando fricción viscosa)
ueq_old = m^2*g*b*(a-xs)^4;                            % Fext anterior = 0
fprintf('u_eq lineal %.4f | nuevo %.4f | anterior %.4f V\n', ueq_lin, ueq_new, ueq_old);

%% 2) Jacobiano numérico del régimen de deslizamiento vs modelo linealizado
A_lin = [0 1; 4*g/(a-xs) -c1];
h=1e-6; y0=[xs;0.5]; f0=new(y0,ueq_lin); f0(2)=f0(2)+c1*0.5; % quitar fricción en v=0.5
J=zeros(2);
for k=1:2, e=zeros(2,1); e(k)=h; J(:,k)=(new(y0+e,ueq_lin)-new(y0-e,ueq_lin))/(2*h); end
fprintf('A lineal  = [%g %g; %.4f %.4f]\n', A_lin');
fprintf('J nuevo   = [%g %g; %.4f %.4f]\n', J');
fprintf('polos J   = %s\n', mat2str(eig(J)',6));

%% 3) La fricción se opone al movimiento
fp = new([xs; 1],ueq_lin); fn = new([xs;-1],ueq_lin);
op = old([xs; 1],ueq_old); on = old([xs;-1],ueq_old);
fprintf('dv con v=+1: nuevo %.3f anterior %.3f | v=-1: nuevo %.3f anterior %.3f\n', fp(2), op(2), fn(2), on(2));

%% 4) Lazo cerrado PII_lic, saturación [0,5] V, ref -4 -> -5 cm
S = load(fullfile(root,'inestable','PII_inestable','PII_lic.mat'));
[Ac,Bc,Cc,Dc] = zp2ss(S.C.Z{:}, S.C.P{:}, S.C.K);
Tf = 60; T=1e-3; N=round(Tf/T);
for caso = ["nuevo","anterior"]
    if caso=="nuevo", P=new; kf=1; u0=ueq_lin; else, P=old; kf=m; u0=ueq_old; end
    [t,yp,uu,ee] = lazo(P,Ac,Bc,Cc,Dc,N,T,-4,-5,Tf/2,5,kf,u0);
    r.(caso) = struct('t',t,'x',yp,'u',uu,'e',ee);
    i1 = t>Tf/2-5 & t<=Tf/2; i2 = t>Tf-5;
    fprintf('[%s] x(%gs)=%.4f  x(%gs)=%.4f  |e|max ult.5s=%.4f  u medio: %.3f / %.3f V  sat5V: %.1f%%\n', ...
        caso, Tf/2, yp(find(t<=Tf/2,1,'last')), Tf, yp(end), max(abs(ee(i2))), mean(uu(i1)), mean(uu(i2)), 100*mean(uu>=4.999));
end
save(fullfile(out,'verificar_P1.mat'),'r');

f=figure('Visible','off','Position',[0 0 900 700]);
subplot(2,1,1); plot(r.nuevo.t,r.nuevo.x,'LineWidth',1.5); hold on; plot(r.anterior.t,r.anterior.x,'--','LineWidth',1.2);
yline(-4,':'); yline(-5,':'); ylabel('posición [cm]'); legend('corregido','anterior','Location','best'); grid on
subplot(2,1,2); plot(r.nuevo.t,r.nuevo.u,'LineWidth',1.5); hold on; plot(r.anterior.t,r.anterior.u,'--','LineWidth',1.2);
ylabel('u [V]'); xlabel('tiempo [s]'); grid on
exportgraphics(f, fullfile(out,'verificar_P1.png'),'Resolution',110);

function dy = old_plant(y,u)
m=0.141; a=7.17184; b=1.6163e-6; c1=8.563; g=981; Fs=20; vth=0.02;
x=y(1); v=y(2); gap=max(a-x,1e-6); Fext=u/(b*m*gap^4)-m*g;
if abs(v)>vth, dx=v; dv=(Fext-c1*abs(v))/m;
elseif abs(Fext)<=Fs, dx=0; dv=0;
else, dx=0; dv=(Fext-Fs*sign(Fext))/m; end
dy=[dx;dv];
end

function [t,yp,uu,ee] = lazo(P,A,B,C,D,N,T,r1,r2,tsw,umax,kf,u0)
m=0.141; a=7.17184; b=1.6163e-6; g=981; Fs=20; vth=0.02;
y0=[r1;0]; x0=zeros(size(A,1),1); u=u0; uzm=u; ZM=0;
t=(0:N-1)'*T; yp=zeros(N,1); uu=yp; ee=yp;
opts=odeset('RelTol',1e-6,'AbsTol',1e-8);
for k=1:N
    [~,y]=ode45(@(~,y) P(y,u),[0 T],y0,opts); y0=y(end,:)';
    Fext=u/(b*kf*max(a-y0(1),1e-6)^4)-m*g;
    if abs(y0(2))<vth && abs(Fext)<=Fs, y0(2)=0; end
    if y0(2)==0, ZM=0; else, uzm=u; ZM=1; end
    R=r1+(r2-r1)*(t(k)>=tsw); e=R-y0(1);
    [~,xc]=ode45(@(~,x) A*x+B*e,[0 T],x0); x0=xc(end,:)';
    u=min(max(C*x0+D*e,0),umax);
    if ZM==1 && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
    yp(k)=y0(1); uu(k)=u; ee(k)=e;
end
end
