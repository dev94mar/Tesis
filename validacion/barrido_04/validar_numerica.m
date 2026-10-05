% Auditoría independiente: no modifica los resultados ni los textos originales.
out = fileparts(mfilename('fullpath')); raiz=fileparts(fileparts(out));
base=fullfile(raiz,'icr','calculus','Final_Bien');
imgs=fullfile(raiz,'icr','context','Tesis','images');
addpath(fullfile(base,'inestable','PII_inestable'));
m=.141; a=7.17184; b=1.6163e-6; g=981; c1=8.563;
S=load(fullfile(base,'inestable','PII_inestable','PII_lic.mat')); Cpii=S.C;
S=load(fullfile(base,'inestable','PI_inestable','PI.mat')); Cpi=S.C;
R=struct('matlab',version);
for x=[-4 -3 -2.5 -2]
 G=tf(1/(m*b*(a-x)^4),[1 c1 -4*g/(a-x)]);
 [gm,pm,wg,wp]=margin(Cpii*G); si=stepinfo(feedback(Cpii*G,1));
 q=struct('x',x,'ue',m*g*b*(a-x)^4,'polos_planta',pole(G),...
 'pm',pm,'gm_db',20*log10(gm),'wg',wg,'wp',wp,'sobrepaso',si.Overshoot,...
 'ts',si.SettlingTime,'polos_lazo_real',real(pole(feedback(Cpii*G,1))),...
 'polos_lazo_imag',imag(pole(feedback(Cpii*G,1))));
 if ~isfield(R,'lineal'),R.lineal=q;else,R.lineal(end+1)=q;end
end
% El jacobiano de la planta con Karnopp en reposo NO es el de deslizamiento.
u=m*g*b*(a+4)^4; h=1e-6;
for v=[0 .5]
 J=zeros(2); y=[-4;v];
 for k=1:2,d=zeros(2,1);d(k)=h;J(:,k)=(maglev_karnopp(0,y+d,u)-maglev_karnopp(0,y-d,u))/(2*h);end
 if v==0,R.J_reposo=J;else,R.J_deslizamiento=J;end
end
G=tf(1/(m*b*(a+3)^4),[1 c1 -4*g/(a+3)]);
R.Kv_con_signo=dcgain(minreal(tf('s')*Cpi*G));
R.Ka_con_signo=dcgain(minreal(tf('s')^2*Cpii*G));
pd=152.42814198289167*17.31299059174172/301.1;
R.rigidez_PD_completa=pd/(b*(a+3)^4)-4*m*g/(a+3);
R.banda_PD_linealizada=20/R.rigidez_PD_completa;
R.banda_PD_exacta=[fzero(@(e) (m*g*b*(a+3)^4+pd*e)/(b*(a+3+e)^4)-m*g-20,.05),...
 fzero(@(e) (m*g*b*(a+3)^4+pd*e)/(b*(a+3+e)^4)-m*g+20,-.05)];
% Volver a medir series completas, sin sesgo por decimación de gráficas.
for nm=["regulacion_P4","regulacion_sinAD_P3","seguimiento_P5_sen","seguimiento_P5_trap","seguimiento_P5_diente","seguimiento_P5_pulso"]
 S=load(fullfile(base,'inestable','PII_inestable',nm+'.mat'));
 R.archivos.(nm)=fieldnames(S);
 if isfield(S,'yp') && isfield(S,'err')
   if startsWith(nm,'regulacion'), k=S.tc>=30;else,k=true(size(S.tc));end
   q=struct('muestras',numel(S.tc),'rms',sqrt(mean(S.err(k).^2)),...
      'error_max',max(abs(S.err(k))),'error_medio',mean(S.err(k)),...
      'pp',max(S.yp(k))-min(S.yp(k)), 'fraccion_atascado',mean(S.yv(k)==0));
   R.series.(nm)=q;
 end
end
guardar(R,out);
% Reproducción desde condiciones iniciales y pruebas de sensibilidad.
casos={ 'PII_original', Cpii, .001, .02, true, false;...
 'PII_tolerancia',Cpii,.001,.02,true,true;...
 'PII_T_mitad',Cpii,.0005,.02,true,true;...
 'PII_DV_mitad',Cpii,.001,.01,true,true;...
 'PII_sin_zm',Cpii,.001,.02,false,true;...
 'PI_original',Cpi,.001,.02,true,false};
for j=1:size(casos,1)
 tic; q=simular(casos{j,2:end}); q.segundos=toc;
 R.reproduccion.(casos{j,1})=q;
 fprintf('%s: pp=%.8f, OS=%.5f, atasco=%.4f, segundos=%.1f\n',casos{j,1},q.pp,q.os,q.atascado,q.segundos);
 guardar(R,out);
end
% Repetir los cuatro casos empleados por la validación R15 original.
F=jsondecode(fileread(fullfile(base,'R15_sintonizacion','familias_R15.json')));
sel={'PI',2.5079,.7579;'PII',1.4651,.4353;'PI',1,1;'PII',1,1};
for j=1:4
 k=find(arrayfun(@(c) strcmp(c.familia,sel{j,1}) && abs(c.kK-sel{j,2})<1e-3 && abs(c.alpha-sel{j,3})<1e-3,F),1);
 f=F(k); q=simular(zpk(f.ceros,f.polos,f.k),.001,.02,true,false,5,35);
 q.familia=f.familia;q.kK=f.kK;q.alpha=f.alpha;
 if ~isfield(R,'R15'),R.R15=q;else,R.R15(end+1)=q;end
 fprintf('R15 %s %.4f %.4f pp %.8f atasco %.5f\n',f.familia,f.kK,f.alpha,q.pp,q.atasc_medio);
 guardar(R,out);
end

function guardar(R,out)
 f=fopen(fullfile(out,'numerica.json'),'w');fprintf(f,'%s',jsonencode(R,'PrettyPrint',true));fclose(f);
end
function q=simular(Cz,T,DV,zm,estricto,tsw,Tfin)
 if nargin<7,tsw=10;Tfin=40;end
 m=.141;a=7.17184;b=1.6163e-6;g=981;
 [A,B,C,D]=zp2ss(Cz.Z{:},Cz.P{:},Cz.K); Ad=c2d(ss(A,B,C,D),T).A;
 u=m*g*b*(a+2)^4; xc=[Ad-eye(size(A));C]\[zeros(size(A,1),1);u];y=[-2;0];
 if estricto,opt=odeset('RelTol',1e-8,'AbsTol',1e-10);else,opt=odeset;end
 N=round(Tfin/T);t=(0:N-1)'*T;x=zeros(N,1);v=x;uu=x;umin=x;
 for k=1:N
  [~,z]=ode45(@(~,z) planta(z,u,DV),[0 T],y,opt);y=z(end,:)';
  fe=u/(b*max(a-y(1),1e-6)^4)-m*g;
  if abs(y(2))<DV && abs(fe)<=20,y(2)=0;end
  mov=y(2)~=0;prev=u;e=-2-(t(k)>=tsw)-y(1);
  [~,z]=ode45(@(~,z) A*z+B*e,[0 T],xc,opt);xc=z(end,:)';
  un=C*xc+D*e;u=min(max(un,0),3.5);umin(k)=u;
  if zm && mov && u<=prev+.025 && u>=prev-.02,u=prev;end
  x(k)=y(1);v(k)=y(2);uu(k)=u;
 end
 tl=t>=Tfin-10;at=v(tl)==0;ep=sum(at(2:end)&~at(1:end-1));
 q=struct('T',T,'DV',DV,'zona_muerta',zm,'estricto',estricto,...
 'pp',max(x(tl))-min(x(tl)),'os',100*(-3-min(x(t>=tsw))),...
 'error_medio',mean(-3-x(tl)),'atascado',mean(at),'u_max',max(uu),...
 'fraccion_limite_inferior',mean(umin==0),'atasc_medio',sum(at)*T/max(ep,1));
end
function dy=planta(y,u,DV)
 m=.141;a=7.17184;b=1.6163e-6;g=981;c1=8.563;
 fe=u/(b*max(a-y(1),1e-6)^4)-m*g;
 if abs(y(2))>DV,dy=[y(2);fe/m-c1*y(2)];
 elseif abs(fe)<=20,dy=[0;0];else,dy=[y(2);(fe-20*sign(fe))/m];end
end
