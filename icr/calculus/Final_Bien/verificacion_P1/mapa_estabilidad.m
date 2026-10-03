d=jsondecode(fileread('barrido.json')); R=struct2table(d.resultados);
C={'PII_lic','PII_sim','PI'}; tit={'PII de la tesis (PII\_lic.mat)','PII simulado (PII.mat)','PI (PI.mat)'};
ref=unique(R.referencia); um=unique(R.umax);
f=figure('Visible','off','Position',[0 0 1300 420]);
for i=1:3
  M=nan(numel(um),numel(ref)); T=R(strcmp(R.controlador,C{i}),:);
  for k=1:height(T), M(um==T.umax(k),ref==T.referencia(k))=T.estable(k); end
  subplot(1,3,i); imagesc(ref,1:numel(um),M); colormap([0.85 0.33 0.27; 0.30 0.62 0.45]); clim([0 1]);
  set(gca,'YDir','normal','YTick',1:numel(um),'YTickLabel',string(um)); hold on
  xline(-5,'k--','LineWidth',1.2); xline(-4,'k:');
  xlabel('referencia final [cm] (desde -4 cm)'); ylabel('u_{max} [V]'); title(tit{i});
  idx5=find(um==5); plot([min(ref) max(ref)],[idx5 idx5],'w-','LineWidth',1)
end
sgtitle('Escalón desde -4 cm con simulador corregido (verde: estable, rojo: diverge)');
exportgraphics(f,'mapa_estabilidad.png','Resolution',110);
