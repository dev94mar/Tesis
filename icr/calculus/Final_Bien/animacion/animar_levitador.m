% Animacion del iman controlado por el PII en el escalon de regulacion -2 -> -3 cm
% (datos reales de regulacion_P4.mat: Karnopp, zona muerta, saturacion, u en [0,3.5]V).
% Dibuja la bobina superior, el iman en su posicion x(t), la varilla guia y la
% referencia, y anima el voltaje de control y la velocidad en paneles aparte.
% Exporta un GIF.
clear; clc
aqui = fileparts(mfilename('fullpath'));
S = load(fullfile(aqui, '..', 'inestable', 'PII_inestable', 'regulacion_P4.mat'));
a = 7.17184;  % posicion de la bobina (x=a)

% Decima a ~25 fps de animacion cubriendo los 40 s en ~20 s de GIF real (2x).
fps = 25; Tgif = 18; Nframes = round(fps*Tgif);
% Muestreo no uniforme: denso al inicio (transitorio), disperso despues.
% El escalon ocurre en t=10 s (S.R cambia de -2 a -3 ahi). Pocos cuadros para
% el tramo plano inicial, muchos para el transitorio y el ciclo limite despues.
t_key = [linspace(0,9.8,round(Nframes*0.06)), linspace(9.8,12,round(Nframes*0.34)), ...
         linspace(12,40,round(Nframes*0.60))];
t_key = min(unique(sort(t_key)), S.tc(end)-S.tc(2));
idx = arrayfun(@(tt) find(S.tc>=tt,1), t_key);

fig = figure('Color','w','Position',[100 100 900 500], 'Visible','off');
tiledlayout(fig, 3,2, 'TileSpacing','compact', 'Padding','compact');

% --- Panel izquierdo (ocupa las 3 filas, columna 1): esquema del dispositivo ---
axEsq = nexttile([3 1]); hold(axEsq,'on'); axis(axEsq,'equal');
xlim(axEsq, [-1.2 1.2]); ylim(axEsq, [-3.6 -1.4]);
axEsq.YDir = 'normal';
set(axEsq, 'XTick', [], 'Box','on');
ylabel(axEsq, 'posición x_1 [cm]');
title(axEsq, 'ECP-730, configuración atractiva');
% Bobina superior: esquematica, arriba del rango visible (la bobina real esta
% en x=a=7.17 cm, muy lejos de -2/-3 cm; aqui solo se indica la direccion).
rectangle(axEsq, 'Position',[-0.6 -1.55 1.2 0.12], 'FaceColor',[0.75 0.75 0.78], 'EdgeColor','k','LineWidth',1.2);
text(axEsq, 0, -1.66, 'bobina \rightarrow (hacia x=+)', 'HorizontalAlignment','center','FontSize',8);
% Varilla guia
plot(axEsq, [0 0], [-3.6 -1.55], 'k-', 'LineWidth',1.5);
% Referencia (linea punteada, se actualiza)
hRef = yline(axEsq, S.R(1), '--', 'Color',[0.75 0.2 0.1], 'LineWidth',1.3);
% Iman (rectangulo que se mueve)
hIman = rectangle(axEsq, 'Position',[-0.45 S.yp(1)-0.12 0.9 0.24], ...
    'FaceColor',[0.12 0.37 0.65], 'EdgeColor','k', 'LineWidth',1.2, 'Curvature',0.15);
hTxt = text(axEsq, 0.75, -1.5, '', 'FontSize',9);

% --- Panel superior derecho: posicion contra tiempo ---
axPos = nexttile; hold(axPos,'on'); grid(axPos,'on');
plot(axPos, S.tc, S.yp, 'Color',[0.12 0.37 0.65], 'LineWidth',0.9);
plot(axPos, S.tc, S.R, '--', 'Color',[0.75 0.2 0.1], 'LineWidth',0.9);
xlim(axPos,[0 40]); ylim(axPos,[-3.3 -1.9]); ylabel(axPos,'x_1 [cm]');
hMarkPos = plot(axPos, S.tc(1), S.yp(1), 'o', 'MarkerFaceColor',[0.9 0.6 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

% --- Panel medio derecho: voltaje de control ---
axU = nexttile; hold(axU,'on'); grid(axU,'on');
plot(axU, S.tc, S.u_despues, 'Color',[0.75 0.2 0.1], 'LineWidth',0.8);
yline(axU, 3.5, ':', 'Color',[0.5 0.5 0.5]);
xlim(axU,[0 40]); ylim(axU,[-0.1 3.7]); ylabel(axU,'u [V]');
hMarkU = plot(axU, S.tc(1), S.u_despues(1), 'o', 'MarkerFaceColor',[0.9 0.6 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

% --- Panel inferior derecho: velocidad ---
axV = nexttile; hold(axV,'on'); grid(axV,'on');
plot(axV, S.tc, S.yv, 'Color',[0.2 0.55 0.3], 'LineWidth',0.7);
xlim(axV,[0 40]); ylim(axV,[-1.3 1.3]); ylabel(axV,'v [cm/s]'); xlabel(axV,'t [s]');
hMarkV = plot(axV, S.tc(1), S.yv(1), 'o', 'MarkerFaceColor',[0.9 0.6 0.1], 'MarkerEdgeColor','k', 'MarkerSize',6);

gifFile = fullfile(aqui, 'levitador_controlado.gif');
for k = 1:numel(idx)
    i = idx(k);
    set(hIman, 'Position', [-0.45 S.yp(i)-0.12 0.9 0.24]);
    set(hRef, 'Value', S.R(i));
    estado = 'deslizando';
    if S.yv(i) == 0, estado = 'atascado'; end
    set(hTxt, 'String', sprintf('t = %5.2f s\nu = %4.2f V\n%s', S.tc(i), S.u_despues(i), estado));
    set(hMarkPos, 'XData', S.tc(i), 'YData', S.yp(i));
    set(hMarkU, 'XData', S.tc(i), 'YData', S.u_despues(i));
    set(hMarkV, 'XData', S.tc(i), 'YData', S.yv(i));
    drawnow;
    fr = getframe(fig);
    [imind, cm] = rgb2ind(fr.cdata, 256);
    if k == 1
        imwrite(imind, cm, gifFile, 'gif', 'Loopcount', inf, 'DelayTime', 1/fps);
    else
        imwrite(imind, cm, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', 1/fps);
    end
end
fprintf('GIF escrito en %s (%d cuadros)\n', gifFile, numel(idx));
close(fig);
