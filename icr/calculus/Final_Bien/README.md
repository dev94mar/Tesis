# Cálculos de la tesis — SLM ECP-730 en configuración inestable

Todos los scripts vigentes usan el simulador corregido (`inestable/PII_inestable/maglev_karnopp.m`)
y el controlador que presenta la tesis (`PII_lic.mat`). Se ejecutan desde la carpeta en la que están.
Las figuras se escriben como CSV + TikZ en `../../context/Tesis/images/*/tikz/`.

## Modelo y controladores

| Archivo | Contenido |
|---|---|
| `inestable/PII_inestable/maglev_karnopp.m` | Planta no lineal atractiva con fricción de Karnopp (corregida en P1). |
| `inestable/linealization_inestable.m` | Linealización simbólica, configuración atractiva. |
| `estable/linealization_estable.m` | Linealización simbólica, configuración repulsiva. |
| `inestable/PII_inestable/PII_lic.mat` | **PII de la tesis**: 152.43 (s+4.875)(s+1.861)(s+17.31) / (s²(s+301.1)). |
| `inestable/PII_inestable/PII.mat` | PII preliminar, 186.11 (s+6.395)(s+14.36)(s+1.861) / (s²(s+400)). Solo para comparación. |
| `inestable/PI_inestable/PI.mat` | PI de la comparación, 178.14 (s+15)(s+12.91) / (s(s+400)). |
| `estable/PI_estable/CInestable.mat`, `estable/PII_estable/CInestable.mat` | Idénticos a `PI.mat` y `PII.mat`. |

## Script → sección de la tesis

| Script | Capítulo y sección (`capitulos/`) | Salida | Duración |
|---|---|---|---|
| `evidencia_P8.m` | 3, `sec:lazo_abierto` · 5, modelo lineal con AD y `Configuración estable` | `images/p8_results/tikz/` | ~30 s |
| `inestable/PII_inestable/diseno_PII_tikz.m` | 4, Bode, Nyquist y escalón | `images/pii_design/tikz/` | ~5 s |
| `verificacion_P1/barrido_3v5.py` (GPU) | 5, `sec:intervalo` | `verificacion_P1/barrido_3v5.json` | ~36 s |
| `inestable/PII_inestable/regulacion_sinAD_P3.m` | 5, no lineal sin AD (OE3) | `images/sin_ad_results/tikz/` | ~10 s |
| `inestable/PII_inestable/regulacion_P4.m` | 5, `sec:regulacion` (OE4) | `images/regulation_results/tikz/` | ~12 s |
| `inestable/PII_inestable/seguimiento_P5.m` | 5, seguimiento senoidal y trapezoidal | `images/seguimiento_results/tikz/` | ~4.5 min (`REUSAR = true` con caché vigente: segundos) |
| `inestable/comparar_PI_PII_P6.m` | 6, `sec:pi_pii` | `inestable/comparar_PI_PII_P6.json` | ~2.5 min |
| `R15_sintonizacion/familias_R15.m` → `simular_R15.py` (GPU) → `exportar_R15.py` | 6, `sec:barrido_familias` | `images/r15_results/tikz/` | ~1 min + 31 s + 1 s |
| `R15_sintonizacion/validar_R15.m` | 6, validación de casos representativos con `ode45` | consola | ~1 min |
| `R15_sintonizacion/analisis_ciclo.m`, `exportar_ciclo.py` | 6, `sec:analisis_ciclo` y `sec:ventaja_rampa` | `images/ciclo_results/tikz/` | ~3 min |

`exportar_R15.py` aplica el criterio de aceptación del barrido sin exclusiones manuales: en el escalón
y en la rampa, sin divergencia y con el voltaje aplicado (después de la retención de la zona muerta)
por debajo de 3.5 V. Produce 57 PI y 51 PII. `R15_sintonizacion/validacion_02/` guarda los resúmenes
del segundo barrido de validación (doble precisión, 20 subpasos, `ode45`) que cita la sección
`sec:barrido_familias`, y `numerica_auditoria1.json`, de la primera auditoría, con la sensibilidad
del PII sin zona muerta que cita `sec:zm_modelo`. Los scripts que los generan están en `validacion/`
de la raíz del proyecto.

`seguimiento_P5.m` reutiliza los MAT solo si su firma (controlador, duración y huellas SHA-256 de
`maglev_karnopp.m` y del propio script) coincide con la actual; los MAT sin firma se vuelven a simular.

Orden de ejecución: `regulacion_P4.m` antes que `regulacion_sinAD_P3.m` y `evidencia_P8.m`,
que leen `regulacion_P4.mat`. Las simulaciones largas usan Parallel Computing Toolbox (`parpool`).

Condiciones comunes: T = 1 ms, u ∈ [0, 3.5] V, zona muerta de −0.02/+0.025 V,
Karnopp con DV = 0.02 cm/s y F_s = 20 kg·cm/s², arranque sin salto del controlador.

## Verificación (P1)

`verificacion_P1/` contiene la verificación de la corrección del simulador
(`verificar_P1.m`), los barridos de estabilidad en GPU con MLX (`barrido_gpu.py`, `barrido_3v5.py`)
y su validación contra MATLAB (`validar_matlab.m`, `validar_3v5.m`).
Los scripts de Python requieren `mlx` y `numpy` (`python3 -m venv venv && venv/bin/pip install mlx numpy`).

## Archivo

| Carpeta | Contenido |
|---|---|
| `_respaldo_P1_2026-10-02/` | Versiones previas a la corrección del simulador (P1). |
| `_archivo_P2_2026-10-02/` | Scripts reemplazados (P2): usaban `PII.mat`, el simulador sin corregir o guardaban figuras en otra copia de la tesis. Se conservan la misma estructura de carpetas. |

Reemplazos principales: `Refactor_PII_inestable.m` → `regulacion_P4.m`;
`seguimiento_sinusoidal.m` y `seguimiento_trapezoidal.m` → `seguimiento_P5.m`;
`PII_inestable_fixed.m` → `regulacion_sinAD_P3.m`; `compare_PI_vs_PII.m` → `comparar_PI_PII_P6.m`;
`PI_estable.m`, `PII_estable.m`, `pplot.m` → `evidencia_P8.m`.

`planta_prueba/` y `runge_kuta/` no intervienen en los resultados de la tesis.
