# Validación de las cuatro pruebas de seguimiento

Fecha: 2026-10-04. Alcance: extender a las cuatro señales de seguimiento del capítulo 5 (senoidal, trapezoidal, diente de sierra, pulso cuadrado) la misma validación independiente que la primera auditoría ya había hecho solo para senoidal y trapezoidal.

## 1. CSV contra MAT (`validar_csv.m`, extendido)

Se agregaron `seguimiento_P5_diente` y `seguimiento_P5_pulso` a la lista de casos de `validacion/validar_csv.m` (antes solo cubría `regulacion_P4`, `seguimiento_P5_sen` y `seguimiento_P5_trap`). Verifica que cada punto de cada CSV de figura (posición, velocidad, error, control, detalle) corresponda exactamente a la serie completa guardada en el `.mat`, indexando por tiempo.

**Resultado: las 10 comparaciones nuevas (5 CSV × 2 señales) dan error a nivel de precisión de máquina** (10⁻¹³–10⁻¹⁴ en tiempo y en datos), igual que las señales originales. Sin discrepancias. Archivo: `validacion/csv_contra_mat.json`.

## 2. Métricas recalculadas desde la serie completa (`validar_metricas_seguimiento.m`, nuevo)

Se escribió un script independiente que recalcula, directamente de las series completas de `yp`, `yv`, `err`, `u_antes` en cada `.mat` —sin la decimación que usan las gráficas—, las métricas que cita el capítulo 5: error eficaz, error máximo, error medio, fracción atascada, rupturas, voltaje máximo/mínimo, fracción saturada y rango de posición.

**Resultado: todas las cifras coinciden exactamente con las guardadas en `met` de cada `.mat`** (y por tanto con las citadas en el capítulo 5), para las cuatro señales, **con una excepción menor y explicada**: el conteo de "rupturas" difiere en exactamente 1 en tres de las cuatro señales (sen: 4071 recalculado frente a 4072 citado; trap: 4399 frente a 4400; diente: 4235 frente a 4236; pulso: 4708 = 4708, coincide exacto).

La diferencia no es un error de datos: el script de validación cuenta las transiciones de inicio de atascamiento (`moviéndose → atascado`), mientras que `seguimiento_P5.m` cuenta las transiciones de ruptura propiamente dichas (`atascado → moviéndose`). Ambos conteos difieren como máximo en 1 según si la serie termina en movimiento o en reposo; no indican ninguna discrepancia en los datos. Se confirma leyendo el código de `simular()` en `seguimiento_P5.m`: `rupturas = sum(atascado(1:end-1) & ~atascado(2:end))`, la dirección opuesta a la que usó por defecto este script de verificación.

Archivo: `validacion/metricas_seguimiento_recalculadas.json`.

## Conclusión

Las cuatro pruebas de seguimiento del capítulo 5 —senoidal, trapezoidal, diente de sierra y pulso cuadrado— están validadas de forma independiente: los CSV que alimentan las figuras son fieles a las series simuladas, y las métricas citadas en el texto se reproducen exactamente desde esas series completas. La única discrepancia encontrada es un artefacto de definición (dirección de la transición contada), no un error de datos, y se documenta aquí para que quede trazado.
