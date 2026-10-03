root='/Users/marino/DEVELOPMENT/TESIS/claude/icr/calculus/Final_Bien/inestable';
addpath(fullfile(root,'PII_inestable'));
S=load(fullfile(root,'PII_inestable','PII_lic.mat')); [A,B,C,D]=zp2ss(S.C.Z{:},S.C.P{:},S.C.K);
casos=[-5 5; -5 10; -4.5 5; -4.5 10; -3 5; -3 10];
if isempty(gcp('nocreate')), parpool('Processes',6); end
res=zeros(size(casos,1),4); tic
parfor i=1:size(casos,1)
  [x,e,u]=lazo(A,B,C,D,casos(i,1),casos(i,2));
  n=numel(x); tl=n-4999:n;
  res(i,:)=[x(end) max(abs(e(tl))) mean(u(tl)) mean(u>=casos(i,2)-1e-4)];
end
fprintf('MATLAB parfor: %.1f s\n',toc);
for i=1:size(casos,1), fprintf('PII_lic %5.1f %4.1f  x=%9.4f  emax=%.4f  u=%.3f  sat=%.3f\n',casos(i,:),res(i,:)); end
function [yp,ee,uu]=lazo(A,B,C,D,r2,umax)
m=0.141;a=7.17184;b=1.6163e-6;g=981;Fs=20;vth=0.02;T=1e-3;N=35000;
y0=[-4;0];x0=zeros(size(A,1),1);u=m*g*b*(a+4)^4;uzm=u;ZM=0;
yp=zeros(N,1);uu=yp;ee=yp;
for k=1:N
  [~,y]=ode45(@(t,y) maglev_karnopp(t,y,u),[0 T],y0); y0=y(end,:)';
  y0(1)=min(max(y0(1),-50),a-0.05);
  Fext=u/(b*max(a-y0(1),1e-6)^4)-m*g;
  if abs(y0(2))<vth && abs(Fext)<=Fs, y0(2)=0; end
  if y0(2)==0, ZM=0; else, uzm=u; ZM=1; end
  R=-4+(r2+4)*((k-1)*T>=5); e=R-y0(1);
  [~,xc]=ode45(@(t,x) A*x+B*e,[0 T],x0); x0=xc(end,:)';
  u=min(max(C*x0+D*e,0),umax);
  if ZM==1 && u<=uzm+0.025 && u>=uzm-0.02, u=uzm; end
  yp(k)=y0(1);uu(k)=u;ee(k)=e;
end
end
