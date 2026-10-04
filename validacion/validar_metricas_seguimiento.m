% Recalcula, directamente de las series completas en los .mat (sin la
% decimacion de las graficas), las metricas citadas en el capitulo 5 para
% las cuatro pruebas de seguimiento: senoidal, trapezoidal, diente de
% sierra y pulso cuadrado. Complementa validar_csv.m (que ya confirmo
% que los CSV son fieles a estas series) y extiende validar_numerica.m
% a las dos pruebas nuevas.
out = fileparts(mfilename('fullpath')); raiz = fileparts(out);
base = fullfile(raiz, 'icr', 'calculus', 'Final_Bien', 'inestable', 'PII_inestable');
R = struct();
for nm = ["seguimiento_P5_sen", "seguimiento_P5_trap", "seguimiento_P5_diente", "seguimiento_P5_pulso"]
  S = load(fullfile(base, nm + ".mat"));
  k = true(size(S.tc));
  at = S.yv(k) == 0;
  ep = sum(at(2:end) & ~at(1:end-1));
  q = struct('muestras', numel(S.tc), ...
      'error_rms', sqrt(mean(S.err(k).^2)), 'error_max', max(abs(S.err(k))), ...
      'error_medio', mean(S.err(k)), 'frac_atascado', mean(at), ...
      'rupturas', ep, 'rupturas_por_minuto', ep/(S.tc(end)/60), ...
      'u_max', max(S.u_antes(k)), 'u_min', min(S.u_antes(k)), ...
      'frac_saturado', mean(S.u_antes(k) >= 3.5-1e-4), ...
      'x_min', min(S.yp(k)), 'x_max', max(S.yp(k)));
  R.(nm) = q;
  fprintf('%s:\n', nm); disp(q)
  fprintf('  (comparar con met guardado en el mat): \n'); disp(S.met)
end
fid = fopen(fullfile(out, 'metricas_seguimiento_recalculadas.json'), 'w');
fprintf(fid, '%s', jsonencode(R, 'PrettyPrint', true));
fclose(fid);
fprintf('Guardado en %s\n', fullfile(out, 'metricas_seguimiento_recalculadas.json'));
