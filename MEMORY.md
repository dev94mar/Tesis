# Memoria del proyecto

Actualizada: **2026-10-04**. Estado observado en el commit **`8f2a1a9`** más cambios sin comprometer en el árbol de trabajo (grafo v5, ver más abajo).

Esta memoria permite retomar el trabajo. Resume decisiones y evidencia; no sustituye las fuentes, los datos ni una validación de cambios posteriores. Las peticiones actuales del usuario prevalecen sobre este resumen.

## Proyecto y propósito

Tesis de maestría de **Lázaro Marino Ávalos Carvajal**, MCIE, UAM Azcapotzalco: control de posición del levitador magnético **ECP-730 en configuración atractiva**, con atascamiento-deslizamiento, mediante un controlador con doble acción integral (**PII**).

El trabajo reciente comprende validación independiente del material producido con Claude, contraste entre scripts/datos/gráficas/LaTeX/grafo y evaluación de su preparación para publicación. El usuario pidió conservar los veredictos en **Markdown**. No ha solicitado enviar el artículo a una revista ni publicar externamente los resultados.

Idioma de trabajo: español. Entregar conclusiones claras, evidencia reproducible y enlaces a los archivos. Distinguir resultados de simulación, derivaciones analíticas y validación experimental.

## Dónde está cada cosa

El mapa completo está en [icr/project.md](icr/project.md) y los comandos en [icr/workflow.md](icr/workflow.md).

- Documento vigente: `icr/context/Tesis/main.tex`, siete capítulos en `capitulos/`, resumen, abstract y dos anexos.
- Simulaciones vigentes: `icr/calculus/Final_Bien/`.
- Controlador de la tesis: `inestable/PII_inestable/PII_lic.mat` dentro de esa carpeta.
- Planta corregida: `inestable/PII_inestable/maglev_karnopp.m`.
- Figuras: TikZ/pgfplots y CSV en `icr/context/Tesis/images/*/tikz/`.
- Grafo vigente: `icr/grafo/grafo_tesis.json`, **versión 4** observada en esta actualización.
- Auditorías independientes: `validacion/` y `validacion/barrido_02/`.
- Los directorios `_archivo_*`, `_respaldo_*` y capítulos antiguos no son la versión vigente del trabajo.

## Convenciones que deben conservarse

| Magnitud | Valor / interpretación |
|---|---|
| Posición `x` | cm, positiva hacia la bobina superior |
| Brecha | `a - x` |
| Masa `m` | 0,141 kg |
| Gravedad `g` | 981 cm/s² |
| `a` | 7,17184 cm |
| `b` usado numéricamente | 1,6163e-6 V·s²/(kg·cm⁵) |
| `b` con fuerzas en N y distancias en cm | 1,6163e-4 V/(N·cm⁴) |
| Fricción viscosa `c1` | 8,563 s⁻¹, ya por unidad de masa |
| Fricción estática `Fs` | 20 kg·cm/s² = 0,2 N; **no 20 N** |
| Banda Karnopp `DV` | 0,02 cm/s |
| Actuador | `[0; 3,5]` V |
| Retención simulada | umbrales de cambio −0,02 / +0,025 V |
| Muestreo nominal | 1 ms |
| Intervalo principal de pruebas | −3 a −2 cm |

La ley de fuerza es `u/[b(a-x)^4]`. No reintroducir la división duplicada por la masa ni fricción viscosa que impulse el movimiento con velocidad negativa.

La retención de voltaje implementada tiene memoria y se desactiva durante el atascamiento; **no equivale a una zona muerta estática centrada en el voltaje de equilibrio**. Las conclusiones deben precisar qué modelo se ensaya.

En −4 cm el límite de 3,5 V impide el despegue hacia la bobina, pero reducir el voltaje sí permite movimiento hacia abajo. No describirlo como imposibilidad de cualquier movimiento.

## Evidencia ya obtenida

### Primera auditoría

Informe histórico: [informe_validacion.txt](validacion/informe_validacion.txt).

- Se reprodujeron márgenes, polos y regulación nominal con MATLAB.
- Se recalcularon métricas desde los MAT de regulación y seguimiento; el seguimiento contiene 2 millones de muestras senoidales y 2,5 millones trapezoidales.
- Se cotejaron 16 CSV con las series MAT: diferencia máxima aproximada de 4,97e-14.
- Se reprodujeron 15 archivos exportados por las pruebas P8, sin AD y diseño lineal, con coincidencia byte por byte.
- Valores nominales confirmados: PII 0,0333933454 cm y PI 0,0309104627 cm de oscilación pico a pico; margen de fase PII en −4 cm de 59,8604°.
- Estos resultados corresponden a las fuentes auditadas entonces. No certifican automáticamente versiones modificadas después.

### Segundo barrido

Informe histórico: [VEREDICTO.md](validacion/barrido_02/VEREDICTO.md).

Se ejecutaron **1028 simulaciones nuevas**: 512 trayectorias R15 con RK4/doble precisión/10 subpasos, otras 512 con 20 subpasos y cuatro comprobaciones con `ode45`.

| Ejecución, filtro original | PI aceptados | PII aceptados | Mejor PI [cm] | Mejor PII [cm] |
|---|---:|---:|---:|---:|
| GPU guardada, filtro recalculado | 57 | 51 | 0,01340318 | 0,02612686 |
| RK4 doble, 10 subpasos | 57 | 51 | 0,01362232 | 0,02632875 |
| RK4 doble, 20 subpasos | 57 | 52 | 0,01382749 | 0,02670578 |

El filtro original observa el voltaje aplicado después del limitador y de la retención, y solo su cota superior. Excluir además cualquier recorte superior **antes** de la retención deja, en el barrido de 10 subpasos, 53 PI y 50 PII; los mínimos son 0,01939681 y 0,02632875 cm. La ventaja cambia de magnitud, aunque conserva el orden.

Casos que deben recordarse:

- PI `kK=0,715484541`, `alpha=0,757858283`: amplitud GPU 0,05282021 cm frente a 0,06145982 cm con `ode45` estricto; diferencia **16,36 %**.
- PII `kK=1`, `alpha=1,319507911`: su aceptación cambia al pasar de 10 a 20 subpasos.
- Cinco controladores aceptados por el filtro original experimentan recorte superior previo a la retención, incluido el mejor PI; todos los 108 escalones aceptados a 10 subpasos experimentan recorte inferior.

No se reejecutaron las 7503 trayectorias del mapa de operación ni todo el seguimiento largo. Se simularon los controladores discretizados disponibles; no se regeneró su diseño completo.

## Cambios posteriores a los informes: estado actual observado

**No tratar los estados «abierto» de los informes históricos como un inventario actualizado.** Después de esas evaluaciones se incorporó el commit `4e5d993` («Aplica las correcciones del segundo barrido de validación») y se resolvió la fusión del logotipo en `8f2a1a9`.

Al crear esta memoria se compararon las huellas del segundo barrido: **18 archivos auditados han cambiado**. Mediante lectura se confirmó:

- Grafo v4: límites de 3,5 V, `Fs` en kg·cm/s² y unidades de `b` corregidos; nota de fricción por unidad de masa actualizada.
- Nuevo exportador `R15_sintonizacion/exportar_R15.py`; el resumen y las tablas exportadas presentan 57 PI y 51 PII con criterio explícito.
- Capítulo 6: se acota el resultado a las familias ensayadas, se explica la saturación antes/después de la retención, se incorpora el estado integral inicial y se conserva el signo negativo de `Kv`.
- `seguimiento_P5.m`: se añadió firma de caché con parámetros/controlador y huellas SHA-256, y guardado de resultados de simulación nueva.
- Existe `icr/context/Tesis/main.pdf`. Su presencia **no equivale a una revisión visual de esta versión**.

Estas son **correcciones observadas**, no una tercera validación numérica completada. Falta verificar su ejecución y coherencia de extremo a extremo. Los informes anteriores deben conservarse como evidencia histórica, sin reescribirlos para hacer parecer que probaron código posterior.

## Publicabilidad

Evaluación previa: [PUBLICABILIDAD.md](validacion/barrido_02/PUBLICABILIDAD.md). Su listado de errores abiertos antecede a las correcciones recién observadas; su evaluación metodológica sigue siendo una referencia, pendiente de actualización formal.

Dictamen previo: **material potencialmente publicable, todavía no listo para envío**. La aportación posible es delimitar las ventajas y limitaciones de la segunda integración bajo fricción y saturación. No es nuevo, por sí solo, que integral y fricción produzcan oscilaciones.

La búsqueda dirigida identificó antecedentes cercanos: Hernández Alcántara et al. (2014, levitación repulsiva y control conmutado), Licéaga-Castro et al. (2012, robot hidráulico con doble integral y conmutación) y Pérez-Gómez et al. (2020, comparación PI/PII/inversa de zona muerta en motor CD). Los enlaces y el análisis están en el informe. No se certificó prioridad ni se realizó una revisión bibliográfica exhaustiva.

Pendientes científicos que una corrección editorial por sí sola no resuelve:

1. Comparación PI/PII con objetivos, restricciones y esfuerzo de sintonización equivalentes.
2. Convergencia y sensibilidad del caso numérico discrepante y de las variantes de frontera.
3. Separación del efecto de fricción, retención y zona muerta estática; alcance físico del modelo.
4. Sensibilidad a parámetros de planta y escenarios no usados para ajustar controladores.
5. Novedad frente a antecedentes y limitación de afirmaciones a evidencia de simulación.
6. Evidencia experimental si se pretende validar recomendaciones sobre el dispositivo real.

No afirmar inferioridad universal del PII, estabilidad no lineal global ni existencia demostrada de ciclo límite cuando solo hay oscilaciones persistentes simuladas. Un estudio exclusivamente numérico puede ser publicable si su contribución y validación son suficientes.

## Tercera auditoría (completada)

Informe: [barrido_03/VEREDICTO.md](validacion/barrido_03/VEREDICTO.md).

Se verificaron los 18 archivos cambiados tras el segundo barrido (exportador `exportar_R15.py`, caché con firma SHA-256 de `seguimiento_P5.m`, capítulo 6, anexos, grafo). **Las seis comprobaciones dieron CONFIRMADO**: el criterio 57 PI/51 PII, la lógica de invalidación de caché, todas las cifras citadas en el capítulo 6 (incluida la distinción de saturación antes/después de la retención y el signo de `Kv`), ausencia de sobregeneralizaciones (no se afirma inferioridad universal del PII ni ciclo límite demostrado matemáticamente), y los valores de `Fs`/`b`/voltaje en el grafo. Única discrepancia: los nodos `REG`/`SIN`/`TRAP` del grafo tienen `valores.controlador = "PII.mat"` (el preliminar) en vez de `PII_lic.mat`, aunque sus cifras sí corresponden a este último; es un metadato por corregir, sin impacto en el texto.

**Hallazgo del mismo día, ya resuelto:** el grafo había sido modificado hoy (`icr/grafo/actualizar_v5.py`) para agregar un nodo `PII_V2` (PII rediseñado, `kK=2,5`, red de adelanto ×1,1, ceros bajos ×1,8) sin ningún script ni dato que lo respaldara. A petición del usuario se escribió `icr/calculus/Final_Bien/R15_sintonizacion/validar_PII_v2.m`, independiente del Python/Mathematica originales, que reconstruye el controlador desde `PII_lic.mat` y lo valida con MATLAB/`ode45` usando el mismo simulador y criterio que el barrido R15. **Resultado: CONFIRMADO.** Margen de fase, sobrepaso, ciclo límite (0,011018 cm reproducido frente a 0,0108 cm afirmado), atascamiento medio (0,2444 s frente a 0,237 s) y error eficaz en rampa (0,002412 cm frente a 0,0024 cm) coinciden dentro de 0,1–3 %, el mismo orden que las diferencias de precisión ya documentadas en el proyecto. Frente al mejor PI del barrido (0,013403 cm / 0,2624 s): −17,8 % en ciclo límite y −6,9 % en atascamiento, consistente con lo afirmado. Datos en `icr/calculus/Final_Bien/R15_sintonizacion/validacion_PII_v2.json`; detalle completo en el addendum de [barrido_03/VEREDICTO.md](validacion/barrido_03/VEREDICTO.md). El grafo (nodo `PII_V2`, revisión `R25` ahora "resuelta") se actualizó con estas cifras y quedó en **versión 5**, aún sin comprometer en git.

## Próximo paso recomendado

1. Comprometer en git el grafo v5 (con `PII_V2` verificado) junto con la corrección de metadato de §REG/SIN/TRAP (`valores.controlador` debe decir `PII_lic.mat`, no `PII.mat`).
2. `PII_V2` sigue **sin estar incorporado al capítulo 6 de la tesis**: es decisión del usuario si se añade como contraejemplo acotado o se deja como trabajo futuro, y con qué alcance narrativo (cuidar no convertirlo en afirmación de optimalidad: solo se amplió la libertad de `kK` y de la red de adelanto frente al barrido original).
3. Actualizar el dictamen de publicabilidad ([PUBLICABILIDAD.md](validacion/barrido_02/PUBLICABILIDAD.md)) si `PII_V2` se incorpora al documento.

## Mantenimiento

Actualizar fecha y commit cuando cambie el estado del proyecto. Para cada hallazgo distinguir: detectado, corrección observada, prueba ejecutada y resultado confirmado. Enlazar a la evidencia; no sustituir cifras reproducibles por recuerdos ni convertir una tarea propuesta en trabajo realizado.
