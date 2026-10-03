root='/Users/marino/DEVELOPMENT/TESIS/claude/icr/calculus/Final_Bien/inestable';
F={'PII_lic',fullfile(root,'PII_inestable','PII_lic.mat'); 'PII_sim',fullfile(root,'PII_inestable','PII.mat'); 'PI',fullfile(root,'PI_inestable','PI.mat')};
s=struct();
for i=1:size(F,1)
  S=load(F{i,2}); [A,B,C,D]=zp2ss(S.C.Z{:},S.C.P{:},S.C.K);
  sd=c2d(ss(A,B,C,D),1e-3,'zoh');
  s.(F{i,1})=struct('Ad',sd.A,'Bd',sd.B,'C',sd.C,'D',sd.D);
end
fid=fopen('controladores.json','w'); fprintf(fid,'%s',jsonencode(s)); fclose(fid); disp('ok')
