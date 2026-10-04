out=fullfile(fileparts(mfilename('fullpath')),'barrido_02');
root=fileparts(fileparts(out));
F=jsondecode(fileread(fullfile(root,'icr/calculus/Final_Bien/R15_sintonizacion/familias_R15.json')));
sel={'PI',.7154845405526278,.757858283255199;'PII',.7154845405526278,.32987697769322355};
R={};
for i=1:2
 k=find(arrayfun(@(f) strcmp(f.familia,sel{i,1}) && abs(f.kK-sel{i,2})<1e-8 && abs(f.alpha-sel{i,3})<1e-8,F),1);
 f=F(k);
 for estricto=[false true]
  q=simular(zpk(f.ceros,f.polos,f.k),.001,.02,true,estricto,5,35);
  q.familia=f.familia;q.kK=f.kK;q.alpha=f.alpha;R{end+1}=q;
  fprintf('%s estricto=%d pp=%.9f\n',f.familia,estricto,q.pp);
 end
end
fid=fopen(fullfile(out,'atipicos_ode45.json'),'w');fprintf(fid,'%s',jsonencode(R,'PrettyPrint',true));fclose(fid);
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
