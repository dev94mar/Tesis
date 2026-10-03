root='/Users/marino/DEVELOPMENT/TESIS/claude/icr/calculus/Final_Bien/inestable';
addpath(fullfile(root,'PII_inestable'));
S=load(fullfile(root,'PII_inestable','PII_lic.mat')); [A,B,C,D]=zp2ss(S.C.Z{:},S.C.P{:},S.C.K);
casos=[-2 -3; -4 -4.5; -4 -3.5; -3 -3.5]; umax=3.5;
if isempty(gcp('nocreate')), parpool('Processes',4); end
res=zeros(size(casos,1),4); X=cell(size(casos,1),1);
parfor i=1:size(casos,1)
  [x,e,u]=lazo(A,B,C,D,casos(i,1),casos(i,2),umax); X{i}=[x u];
  tl=numel(x)-4999:numel(x); res(i,:)=[x(end) max(abs(e(tl))) mean(u(tl)) mean(u>=umax-1e-4)];
end
for i=1:size(casos,1), fprintf('PII_lic %4.1f -> %4.1f  x=%8.3f  emax=%.3f  u=%.3f  sat=%.2f\n',casos(i,:),res(i,:)); end
t=(0:39999)*1e-3; f=figure('Visible','off','Position',[0 0 900 650]);
subplot(2,1,1); plot(t,X{1}(:,1),'LineWidth',1.5); hold on; plot(t,-2+(-1)*(t>=10),'k--'); ylabel('posición [cm]'); grid on; title('PII\_lic, u_{max}=3.5 V, escalón -2 \rightarrow -3 cm (simulador corregido)')
subplot(2,1,2); plot(t,X{1}(:,2),'LineWidth',1.5); yline(3.5,'r:'); ylabel('u [V]'); xlabel('tiempo [s]'); grid on
exportgraphics(f,'escalon_3v5.png','Resolution',110);
function [yp,ee,uu]=lazo(A,B,C,D,r1,r2,umax)
m=0.141;a=7.17184;b=1.6163e-6;g=981;Fs=20;vth=0.02;T=1e-3;N=40000;
[Ad,~]=c2d(A,B,T); ueq=min(m*g*b*(a-r1)^4,umax);
x0=[Ad-eye(size(A));C]\[zeros(size(A,1),1);ueq];   % arranque sin salto
y0=[r1;0];u=ueq;uzm=u;ZM=0;yp=zeros(N,1);uu=yp;ee=yp;
for k=1:N
  [~,y]=ode45(@(t,y) maglev_karnopp(t,y,u),[0 T],y0); y0=y(end,:)'; y0(1)=min(max(y0(1),-50),a-0.05);
  Fext=u/(b*max(a-y0(1),1e-6)^4)-m*g;
  if abs(y0(2))<vth && abs(Fext)<=Fs, y0(2)=0; end
  if y0(2)==0, ZM=0; else, uzm=u; ZM=1; end
  R=r1+(r2-r1)*((k-1)*T>=10); e=R-y0(1);
  [~,xc]=ode45(@(t,x) A*x+B*e,[0 T],x0); x0=xc(end,:)';
  u=min(max(C*x0+D*e,0),umax);
  if ZM==1 && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
  yp(k)=y0(1);uu(k)=u;ee(k)=e;
end
end
