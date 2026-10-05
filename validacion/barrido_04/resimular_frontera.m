root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
base=fullfile(root,'icr','calculus','Final_Bien'); out=fileparts(mfilename('fullpath'));
addpath(fullfile(base,'inestable','PII_inestable'));
m=.141;g=981;a=7.17184;b=1.6163e-6;T=.001;
R=struct([]);
cases={'PI',3.5,1.4,1.15;'PII',1,2.2,1.05;'PII',2.5,1.8,1.1};
for j=1:3
 fam=cases{j,1}; if strcmp(fam,'PI'), fn='PI.mat';else,fn='PII_lic.mat';end
 S=load(fullfile(base,'inestable',[fam '_inestable'],fn)); C=zpk(S.C); z=C.Z{1};p=C.P{1};
 [~,ih]=max(abs(z)); il=setdiff(1:numel(z),ih); z(il)=z(il)*cases{j,3};z(ih)=z(ih)*cases{j,4};p(abs(p)>1e-9)=p(abs(p)>1e-9)*cases{j,4};
 for strict=[false true]
  [A,B,Cc,D]=ssdata(c2d(ss(zpk(z,p,C.K*cases{j,2})),T,'zoh'));
  u=m*g*b*(a+2)^4;xc=[A-eye(size(A));Cc]\[zeros(size(A,1),1);u];y=[-2;0];N=70000;x=zeros(N,1);v=x;uu=x;
  if strict,opt=odeset('RelTol',1e-9,'AbsTol',1e-11,'MaxStep',T/10);else,opt=odeset;end
  for k=1:N
   prev=u;[~,ys]=ode45(@(t,y) maglev_karnopp(t,y,u),[0 T],y,opt);y=ys(end,:)';
   fe=u/(b*max(a-y(1),1e-6)^4)-m*g;if abs(y(2))<.02 && abs(fe)<=20,y(2)=0;end
   mov=y(2)~=0;e=-2-((k-1)*T>=5)-y(1);xc=A*xc+B*e;u=min(max(Cc*xc+D*e,0),3.5);
   if mov && u<=prev+.025 && u>=prev-.02,u=prev;end
   x(k)=y(1);v(k)=y(2);uu(k)=u;
  end
  for bounds=[25 60;35 70]
   idx=round(bounds(1)/T)+1:round(bounds(2)/T);at=v(idx)==0;starts=sum(at(2:end)&~at(1:end-1));
   q=struct('family',fam,'kK',cases{j,2},'alpha',cases{j,3},'beta',cases{j,4},'strict',strict,'window',bounds','pp',max(x(idx))-min(x(idx)),'atasc',sum(at)*T/max(starts,1),'episodes',starts,'mean_error',mean(-3-x(idx)),'sat_upper',mean(uu>=3.5-1e-4),'sat_lower',mean(uu==0));
   if isempty(R),R=q;else,R(end+1)=q;end;disp(q)
  end
  fid=fopen(fullfile(out,'frontera_resimulada.json'),'w');fprintf(fid,'%s',jsonencode(R,'PrettyPrint',true));fclose(fid);
 end
end
