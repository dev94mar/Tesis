% Verifica que cada punto dibujado corresponda a las series completas MAT.
out=fileparts(mfilename('fullpath'));root=fileparts(out);
B=fullfile(root,'icr','calculus','Final_Bien','inestable','PII_inestable');
I=fullfile(root,'icr','context','Tesis','images');
map=struct('x','yp','r','R','v','yv','e','err','u_antes','u_antes','u_desp','u_despues','u','u_despues');
cases={'regulacion_P4','regulation_results','';'seguimiento_P5_sen','seguimiento_results','sen_';'seguimiento_P5_trap','seguimiento_results','trap_'};
R=struct();
for j=1:size(cases,1)
 S=load(fullfile(B,[cases{j,1} '.mat'])); files=dir(fullfile(I,cases{j,2},'tikz',[cases{j,3} '*.csv']));
 for k=1:numel(files)
  X=readtable(fullfile(files(k).folder,files(k).name)); idx=round(X.t/.001)+1;
  q=struct('filas',height(X),'error_t',max(abs(X.t-S.tc(idx))),'error_datos',0);
  cols=X.Properties.VariableNames;
  for z=2:numel(cols),col=cols{z};q.error_datos=max(q.error_datos,max(abs(X.(col)-S.(map.(col))(idx))));end
  R.(matlab.lang.makeValidName([cases{j,1} '_' files(k).name]))=q;
 end
end
S=load(fullfile(B,'regulacion_sinAD_P3.mat')); A=load(fullfile(B,'regulacion_P4.mat'));
for nm=["comparacion","detalle"]
 X=readtable(fullfile(I,'sin_ad_results','tikz',nm+'.csv'));idx=round(X.t/.001)+1;
 Y=[S.yp(idx) S.R(idx) S.yv(idx) S.err(idx) S.uu(idx) A.yp(idx) A.yv(idx) A.err(idx) A.u_despues(idx)];
 R.(char(nm))=struct('filas',height(X),'error_t',max(abs(X.t-S.tc(idx))),'error_datos',max(abs(X{:,2:end}-Y),[],'all'));
end
f=fopen(fullfile(out,'csv_contra_mat.json'),'w');fprintf(f,'%s',jsonencode(R,'PrettyPrint',true));fclose(f);
disp(R)
