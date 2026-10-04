function animar_caso(nombreMat, gifOut, Tfin, tramos, xlim_)
% Genera una animacion GIF del iman del ECP-730 controlado por el PII, a
% partir de un .mat de seguimiento_P5.m o regulacion_P4.m. Generaliza
% animar_levitador.m (que queda sin cambios, para no romper el GIF ya hecho)
% para las demas pruebas: senoidal, trapezoidal, diente de sierra, pulso
% cuadrado.
%
%   nombreMat: nombre del .mat (sin extension) en inestable/PII_inestable/
%   gifOut: ruta del GIF de salida
%   Tfin: duracion simulada total en s
%   tramos: matriz Nx3 [t0 t1 fraccion_de_cuadros] para el muestreo no
%           uniforme de cuadros (las fracciones deben sumar 1)
%   xlim_: [ymin ymax] para el eje de posicion (cm)
aqui = fileparts(mfilename('fullpath'));
S = load(fullfile(aqui, '..', 'inestable', 'PII_inestable', [nombreMat '.mat']));

fps = 25; Tgif = 18; Nframes = round(fps*Tgif);
t_key = [];
for r = 1:size(tramos,1)
    t_key = [t_key, linspace(tramos(r,1), tramos(r,2), round(Nframes*tramos(r,3)))]; %#ok<AGROW>
end
t_key = min(unique(sort(t_key)), S.tc(end)-S.tc(2));
idx = arrayfun(@(tt) find(S.tc>=tt,1), t_key);

fig = figure('Color','w','Position',[100 100 900 500], 'Visible','off');
tiledlayout(fig, 3,2, 'TileSpacing','compact', 'Padding','compact');

axEsq = nexttile([3 1]); hold(axEsq,'on'); axis(axEsq,'equal');
xlim(axEsq, [-1.2 1.2]); ylim(axEsq, xlim_);
axEsq.YDir = 'normal';
set(axEsq, 'XTick', [], 'Box','on');
ylabel(axEsq, 'posición x_1 [cm]');
title(axEsq, 'ECP-730, configuración atractiva');
topY = xlim_(2) - 0.08*(xlim_(2)-xlim_(1));
rectangle(axEsq, 'Position',[-0.6 topY 1.2 0.05*(xlim_(2)-xlim_(1))], 'FaceColor',[0.75 0.75 0.78], 'EdgeColor','k','LineWidth',1.2);
text(axEsq, 0, topY-0.05*(xlim_(2)-xlim_(1)), 'bobina \rightarrow (hacia x=+)', 'HorizontalAlignment','center','FontSize',8);
plot(axEsq, [0 0], [xlim_(1) topY], 'k-', 'LineWidth',1.5);
hRef = yline(axEsq, S.R(1), '--', 'Color',[0.75 0.2 0.1], 'LineWidth',1.3);
hIman = rectangle(axEsq, 'Position',[-0.45 S.yp(1)-0.04*(xlim_(2)-xlim_(1)) 0.9 0.08*(xlim_(2)-xlim_(1))], ...
    'FaceColor',[0.12 0.37 0.65], 'EdgeColor','k', 'LineWidth',1.2, 'Curvature',0.15);
hTxt = text(axEsq, 0.75, xlim_(1)+0.05*(xlim_(2)-xlim_(1)), '', 'FontSize',9);

axPos = nexttile; hold(axPos,'on'); grid(axPos,'on');
plot(axPos, S.tc, S.yp, 'Color',[0.12 0.37 0.65], 'LineWidth',0.9);
plot(axPos, S.tc, S.R, '--', 'Color',[0.75 0.2 0.1], 'LineWidth',0.9);
xlim(axPos,[0 Tfin]); ylim(axPos, xlim_); ylabel(axPos,'x_1 [cm]');
hMarkPos = plot(axPos, S.tc(1), S.yp(1), 'o', 'MarkerFaceColor',[0.9 0.6 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

axU = nexttile; hold(axU,'on'); grid(axU,'on');
plot(axU, S.tc, S.u_despues, 'Color',[0.75 0.2 0.1], 'LineWidth',0.8);
yline(axU, 3.5, ':', 'Color',[0.5 0.5 0.5]);
xlim(axU,[0 Tfin]); ylim(axU,[-0.1 3.7]); ylabel(axU,'u [V]');
hMarkU = plot(axU, S.tc(1), S.u_despues(1), 'o', 'MarkerFaceColor',[0.9 0.6 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

axV = nexttile; hold(axV,'on'); grid(axV,'on');
plot(axV, S.tc, S.yv, 'Color',[0.2 0.55 0.3], 'LineWidth',0.7);
xlim(axV,[0 Tfin]); ylim(axV,[min(S.yv)*1.15-0.05 max(S.yv)*1.15+0.05]); ylabel(axV,'v [cm/s]'); xlabel(axV,'t [s]');
hMarkV = plot(axV, S.tc(1), S.yv(1), 'o', 'MarkerFaceColor',[0.9 0.6 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

for k = 1:numel(idx)
    i = idx(k);
    hw = 0.04*(xlim_(2)-xlim_(1));
    set(hIman, 'Position', [-0.45 S.yp(i)-hw 0.9 2*hw]);
    set(hRef, 'Value', S.R(i));
    estado = 'deslizando';
    if S.yv(i) == 0, estado = 'atascado'; end
    set(hTxt, 'String', sprintf('t = %6.2f s\nu = %4.2f V\n%s', S.tc(i), S.u_despues(i), estado));
    set(hMarkPos, 'XData', S.tc(i), 'YData', S.yp(i));
    set(hMarkU, 'XData', S.tc(i), 'YData', S.u_despues(i));
    set(hMarkV, 'XData', S.tc(i), 'YData', S.yv(i));
    drawnow;
    fr = getframe(fig);
    [imind, cm] = rgb2ind(fr.cdata, 256);
    if k == 1
        imwrite(imind, cm, gifOut, 'gif', 'Loopcount', inf, 'DelayTime', 1/fps);
    else
        imwrite(imind, cm, gifOut, 'gif', 'WriteMode', 'append', 'DelayTime', 1/fps);
    end
end
fprintf('GIF escrito en %s (%d cuadros)\n', gifOut, numel(idx));
close(fig);
end
