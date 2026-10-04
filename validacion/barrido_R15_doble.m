% Nuevo barrido completo R15 en CPU/doble precisión, sin modificar la tesis.
% Replica el RK4 de 10 subpasos y las ventanas del barrido MLX original.
% Agrega contadores de saturación inferior y estados no finitos durante la prueba.
out=fullfile(fileparts(mfilename('fullpath')),'barrido_02');
if ~isfolder(out),mkdir(out);end
root=fileparts(fileparts(out));
F=jsondecode(fileread(fullfile(root,'icr/calculus/Final_Bien/R15_sintonizacion/familias_R15.json')));
subpasos=10;
if exist('SUBPASOS_AUDITORIA','var'),subpasos=SUBPASOS_AUDITORIA;end
n=2*numel(F);T=.001;h=T/subpasos;N=35000;
A=zeros(n,3,3);B=zeros(n,3);C=B;D=zeros(n,1);xc=B;
ue=.141*981*1.6163e-6*(7.17184+2)^4;
for i=1:n
 f=F(ceil(i/2));A(i,:,:)=f.Ad;B(i,:)=f.Bd(:)';C(i,:)=f.C(:)';D(i)=f.D;
 xc(i,:)=([f.Ad-eye(3);f.C(:)']\[zeros(3,1);ue])';
end
A1=squeeze(A(:,1,:));A2=squeeze(A(:,2,:));A3=squeeze(A(:,3,:));
x=-2*ones(n,1);v=zeros(n,1);u=ue*ones(n,1);uzm=u;
ram=mod((1:n)',2)==0;
z=zeros(n,1);xmin=x;amin=99+z;amax=-99+z;atA=z;epA=z;emax=z;
sumB=z;sqB=z;atB=z;epB=z;umax=z;sat=z;satlo=z;cliphi=z;cliplo=z;
prev=false(n,1);nonfinite=prev;ever_clip=prev;
tic
for k=1:N
 t=(k-1)*T;
 for j=1:subpasos
  [kx1,kv1]=rhs(x,v,u);
  [kx2,kv2]=rhs(x+h/2*kx1,v+h/2*kv1,u);
  [kx3,kv3]=rhs(x+h/2*kx2,v+h/2*kv2,u);
  [kx4,kv4]=rhs(x+h*kx3,v+h*kv3,u);
  x=x+h/6*(kx1+2*kx2+2*kx3+kx4);
  v=v+h/6*(kv1+2*kv2+2*kv3+kv4);
 end
 nonfinite=nonfinite|~isfinite(x)|~isfinite(v);
 ever_clip=ever_clip|x<-50|x>7.17184-.05;
 x=min(max(x,-50),7.17184-.05);
 fe=u./(1.6163e-6*max(7.17184-x,1e-6).^4)-.141*981;
 v(abs(v)<.02 & abs(fe)<=20)=0;
 mov=v~=0;uzm(mov)=u(mov);
 r=(-2-(t>=5))*ones(n,1);r(ram)=min(max(-2-.05*max(t-5,0),-3),-2);
 e=r-x;
 xc=[sum(A1.*xc,2),sum(A2.*xc,2),sum(A3.*xc,2)]+B.*e;
 raw=sum(C.*xc,2)+D.*e;
 cliphi=cliphi+(raw>3.5);cliplo=cliplo+(raw<0);
 u=min(max(raw,0),3.5);
 hold=mov & u<=uzm+.025 & u>=uzm-.02;u(hold)=uzm(hold);
 at=v==0;nuevo=at & ~prev;prev=at;
 umax=max(umax,u);sat=sat+(u>=3.5-1e-4);satlo=satlo+(u<=1e-4);
 if t>=5,xmin=min(xmin,x);end
 if t>=25
  amin=min(amin,x);amax=max(amax,x);atA=atA+at;epA=epA+nuevo;emax=max(emax,abs(e));
 end
 if t>=10 && t<25
  sumB=sumB+e;sqB=sqB+e.^2;atB=atB+at;epB=epB+nuevo;
 end
 if mod(k,5000)==0,fprintf('t=%g s / 35, transcurrido %.1f s\n',k*T,toc);end
end
elapsed=toc;
R=struct('matlab',version,'precision','double','integrador','RK4','T',T,...
 'subpasos',subpasos,'trayectorias',n,'segundos',elapsed);
res=cell(n,1);
for i=1:n
 f=F(ceil(i/2));
 q=struct('familia',f.familia,'kK',f.kK,'alpha',f.alpha,'base',f.base,...
 'pm_min',f.pm_min,'os_lineal',f.os_lineal,'u_max',umax(i),...
 'frac_saturado',sat(i)/N,'frac_limite_inferior',satlo(i)/N,...
 'frac_recorte_superior',cliphi(i)/N,'frac_recorte_inferior',cliplo(i)/N,...
 'diverge',x(i)<-20 || ~isfinite(x(i)),...
 'no_finito_en_trayectoria',nonfinite(i),'recorte_posicion',ever_clip(i));
 if ~ram(i)
  q.prueba='escalon';q.sobrepaso_pct=100*(-3-xmin(i));q.ciclo_pp_cm=amax(i)-amin(i);
  q.error_max_cm=emax(i);q.frac_atascado=atA(i)/10000;q.atasc_medio_s=atA(i)*T/epA(i);
 else
  q.prueba='rampa';q.error_medio_rampa_cm=sumB(i)/15000;
  q.error_rms_rampa_cm=sqrt(sqB(i)/15000);q.frac_atascado=atB(i)/15000;q.atasc_medio_s=atB(i)*T/epB(i);
 end
 res{i}=q;
end
R.resultados=res;
nombre='R15_doble.json';
if subpasos~=10,nombre=sprintf('R15_doble_sub%d.json',subpasos);end
fid=fopen(fullfile(out,nombre),'w');fprintf(fid,'%s',jsonencode(R,'PrettyPrint',true));fclose(fid);
fprintf('Completadas %d trayectorias en %.1f s\n',n,elapsed);
function [dx,dv]=rhs(x,v,u)
 fe=u./(1.6163e-6*max(7.17184-x,1e-6).^4)-.141*981;
 slide=abs(v)>.02;stick=abs(fe)<=20;
 dx=v;dv=(fe-20*sign(fe))/.141;
 dx(~slide & stick)=0;dv(~slide & stick)=0;
 dv(slide)=(fe(slide)-.141*8.563*v(slide))/.141;
end
