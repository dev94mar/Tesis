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

| Script | Sección (cap. 8) | Salida | Duración |
|---|---|---|---|
| `evidencia_P8.m` | 8.6.1 lazo abierto · 8.6.3 lineal con AD · 8.6.7 configuración estable | `images/p8_results/tikz/` | ~30 s |
| `inestable/PII_inestable/diseno_PII_tikz.m` | 8.6.2 Bode, Nyquist, escalón | `images/pii_design/tikz/` | ~5 s |
| `inestable/PII_inestable/regulacion_sinAD_P3.m` | 8.6.4 no lineal sin AD (OE3) | `images/sin_ad_results/tikz/` | ~10 s |
| `inestable/PII_inestable/regulacion_P4.m` | 8.6.5 regulación (OE4) | `images/regulation_results/tikz/` | ~12 s |
| `inestable/PII_inestable/seguimiento_P5.m` | 8.6.6 seguimiento senoidal y trapezoidal | `images/seguimiento_results/tikz/` | ~4.5 min (`REUSAR = true`: segundos) |
| `inestable/comparar_PI_PII_P6.m` | 8.6.6 tabla PI vs PII | `inestable/comparar_PI_PII_P6.json` | ~2.5 min |
| `R15_sintonizacion/familias_R15.m` → `simular_R15.py` (GPU) → `validar_R15.m` | 8.6.6 familias PI y PII | `images/r15_results/tikz/` | ~1 min + 31 s + 1 min |

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
