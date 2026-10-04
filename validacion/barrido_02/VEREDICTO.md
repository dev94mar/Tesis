# Veredicto del segundo barrido de validación

**Fecha:** 3 de octubre de 2026.  
**Proyecto:** tesis del ECP-730, configuración atractiva, control PI/PII.  
**Dictamen:** **resultados principales reproducibles, con reservas numéricas y metodológicas. La tesis todavía requiere correcciones para considerarse validada integralmente.**

El nuevo barrido confirma que, **dentro de las familias y condiciones ensayadas**, el mejor PI produce una oscilación menor que el mejor PII. No demuestra que cualquier PI supere a cualquier PII ni descarta otras sintonizaciones. La interpretación depende además de qué se denomina «sin saturación».

El bloqueo de compilación detectado en la primera revisión ya no se reproduce: el logotipo está presente y las pasadas de LuaLaTeX y Biber terminaron correctamente. Persisten las inconsistencias de unidades, grafo y justificación matemática señaladas anteriormente.

## 1. Trabajo ejecutado en esta revisión

- Nuevo barrido de **256 controladores × 2 pruebas = 512 trayectorias**, desde condiciones iniciales, en MATLAB/CPU y doble precisión.
- Repetición de las **512 trayectorias con 20 subpasos**, frente a los 10 originales, manteniendo el muestreo del controlador en 1 ms.
- **Cuatro simulaciones adicionales con `ode45`**: dos variantes discrepantes, con tolerancias predeterminadas y con `RelTol=1e-8`, `AbsTol=1e-10`.
- Total: **1028 simulaciones nuevas**. Los dos barridos completos tardaron aproximadamente 42 y 83 segundos de cálculo.
- Nueva comprobación de 53 archivos LaTeX activos, 110 etiquetas, 43 claves bibliográficas, 38 CSV y el grafo de 180 nodos y 306 aristas.
- Compilación de comprobación: LuaLaTeX, Biber y otra pasada LuaLaTeX, con salidas aisladas en `latex/`.

Se conservaron los controladores discretizados de `familias_R15.json`, el modelo, el orden de actualización, las ventanas de medición y las restricciones del barrido original. Se utilizó una implementación nueva de la integración en MATLAB, no los resultados almacenados como sustituto de las simulaciones.

Las fuentes incluidas en las huellas de la auditoría anterior no muestran cambios. Esa comparación no cubría el logotipo entonces ausente; su presencia se comprobó por separado y mediante la compilación.

## 2. Resultado principal: se mantiene la comparación entre los mejores casos

Amplitud pico a pico del escalón, en cm, utilizando el **filtro original**: sin divergencia según su indicador y sin alcanzar la cota superior en el voltaje aplicado después de la retención, tanto en escalón como en rampa.

| Ejecución | PI aceptados | PII aceptados | Mejor PI | Mejor PII |
|---|---:|---:|---:|---:|
| GPU guardada, filtro recalculado | 57 | 51 | 0,01340318 | 0,02612686 |
| Nuevo RK4, doble precisión, 10 subpasos | 57 | 51 | 0,01362232 | 0,02632875 |
| Nuevo RK4, doble precisión, 20 subpasos | 57 | 52 | 0,01382749 | 0,02670578 |

Los mejores controladores siguen siendo:

- **PI:** `kK = 2,507876406`, `alpha = 0,757858283`.
- **PII:** `kK = 1,465078026`, `alpha = 0,435275282`.

Con 10 subpasos, sus amplitudes difieren del archivo GPU un **1,63 % y 0,77 %**, respectivamente. La conclusión comparativa sobre esos extremos es reproducible.

**La tesis y su figura todavía presentan 54 PI aceptados.** El filtro descrito y los indicadores guardados producen 57. El nuevo barrido confirma la discrepancia de selección de la primera revisión; no la corrige ni justifica las tres exclusiones.

## 3. Nuevos hallazgos y precisiones

### N01. Una variante PI tiene una discrepancia numérica confirmada superior al 8 %

Para el PI con `kK = 0,715484541` y `alpha = 0,757858283`:

| Método | Amplitud pico a pico [cm] |
|---|---:|
| GPU guardada | 0,05282021 |
| RK4 doble, 10 subpasos | 0,06172369 |
| RK4 doble, 20 subpasos | 0,06272375 |
| `ode45`, tolerancia predeterminada | 0,06161268 |
| `ode45`, tolerancia estricta | 0,06145982 |

La diferencia entre `ode45` estricto y el archivo GPU es **16,36 %**. El cambio persiste con otro integrador y con menor paso de RK4. Por tanto, la concordancia inferior al 8 % observada previamente en casos representativos **no puede extenderse a todo el barrido**.

Esto no identifica por sí solo una causa única: se están comparando implementaciones distintas y precisiones distintas de un sistema no suave. No debe atribuirse exclusivamente al redondeo sin una prueba adicional controlada.

En una variante PII también apareció inicialmente una diferencia del 8,17 % (`kK = 0,715484541`, `alpha = 0,329876978`). En ese caso, el refinamiento de RK4 da 0,05950213 cm y `ode45` estricto 0,05918009 cm, frente a 0,05950928 cm de la GPU. **La discrepancia inicial del PII no persiste con el refinamiento.**

Las diferencias medianas de amplitud entre GPU y RK4 doble con 10 subpasos son 0,92 % para PI y 0,74 % para PII, sobre los casos aceptados comunes. Es necesario informar tanto esas diferencias típicas como los casos excepcionales.

### N02. El indicador de saturación no registra toda intervención del limitador

El código recorta la salida del controlador a `[0; 3,5]` V y después aplica la retención de voltaje. El indicador original examina el voltaje **posterior a esa retención**. Puede informar cero saturación superior aunque el limitador haya recortado antes una orden mayor que 3,5 V.

En el barrido nuevo de 10 subpasos, **cinco controladores aceptados** presentan ese recorte superior previo. Entre ellos está el PI de menor amplitud: su orden fue recortada en **7 de 35 000 muestras**, aunque el voltaje finalmente aplicado no alcanzó 3,5 V.

Si se exige que **no intervenga el recorte superior antes de la retención**, en ninguna de las dos pruebas, el resultado pasa a ser:

| Criterio más estricto, RK4 doble con 10 subpasos | PI | PII |
|---|---:|---:|
| Controladores aceptados | 53 | 50 |
| Menor amplitud [cm] | 0,01939681 | 0,02632875 |
| `kK` del mejor caso | 2,096481356 | 1,465078026 |
| `alpha` del mejor caso | 0,435275282 | 0,435275282 |

El mejor PI sigue teniendo menor amplitud, pero la relación PII/PI pasa de aproximadamente **1,93 a 1,36**. La frase «el mejor PII duplica el ciclo del mejor PI» depende del criterio utilizado.

Además, los **108 escalones aceptados por el filtro original** pasan por el recorte inferior. Debe evitarse la expresión general «sin saturar»: hay que declarar la cota, la señal medida y el punto del algoritmo en que se evalúa.

### N03. Una aceptación cambia al refinar la integración

El PII con `kK = 1` y `alpha = 1,319507911` alcanza 3,5 V durante dos muestras con 10 subpasos; con 20 subpasos su máximo aplicado es 3,47502429 V y pasa el filtro. Esto explica el cambio de **51 a 52 PII aceptados**.

No cambian los mejores controladores. Sin embargo, el número exacto de variantes aceptadas es sensible al tratamiento numérico de las transiciones. Deben publicarse los criterios y la sensibilidad de los casos próximos a la frontera.

No se observaron estados no finitos en el barrido de 10 subpasos. Hubo 59 trayectorias con recorte artificial de posición; todas quedaron clasificadas como divergentes por el criterio original. Esos recortes no afectaron al subconjunto aceptado.

## 4. Estado de los hallazgos anteriores

Los identificadores remiten al [primer informe](../informe_validacion.txt).

| Hallazgo | Estado actual |
|---|---|
| H01. Logotipo ausente / compilación bloqueada | **Resuelto en la comprobación técnica.** Recurso presente; LuaLaTeX y Biber concluyen correctamente. No equivale a aprobación visual del PDF. |
| H02. Unidad de `b` incompatible con el valor usado | **Abierto.** Deben unificarse unidades y conversión. |
| H03. Grafo con 5 V, 20 N y nota antigua de fricción | **Abierto.** La estructura del grafo es válida; su contenido sigue siendo contradictorio. |
| H04. 54 PI publicados frente a 57 según el filtro | **Confirmado nuevamente.** Falta justificar las exclusiones y añadir el exportador reproducible. |
| H05. Conclusiones universales a partir de familias restringidas | **Abierto.** El nuevo barrido amplía la evidencia, no autoriza esa generalización. |
| H06. Zona muerta implementada distinta de la ley estática descrita | **Abierto como limitación del modelo.** |
| H07. Fórmula PII sin estado inicial integral | **Abierto.** |
| H08. Pérdida del signo de las constantes de error | **Abierto.** |
| H09. Banda del PD sin rigidez de la planta | **Abierto.** |
| H10. Jacobiano de deslizamiento presentado sin esa precisión | **Abierto.** |
| H11. «Sin saturar» solo considera la cota superior | **Confirmado y ampliado por N02.** También importa medir antes o después de la retención. |
| H12. Imposibilidad de desplazamiento desde −4 cm demasiado general | **Abierto.** Debe distinguirse dirección y capacidad de regulación. |
| H13. Caché de seguimiento puede conservar MAT antiguos | **Abierto.** |

Estos estados se basan en la revisión actual de estructura y en la comparación de las fuentes con sus huellas anteriores; no implican que se hayan repetido todas las derivaciones analíticas de la primera auditoría.

## 5. Compilación y estructura documental

La nueva comprobación estática no encuentra inputs, imágenes o CSV ausentes, etiquetas duplicadas, referencias internas sin destino ni claves bibliográficas sin entrada.

Biber procesó **43 claves** y generó la bibliografía. La segunda pasada LuaLaTeX terminó con código de salida cero, sin avisos `LaTeX Warning`, referencias indefinidas ni cajas `Overfull/Underfull` en su salida. El aviso de `draftmode` es esperado.

**Alcance:** se compiló con `-draftmode`; se calcularon páginas, figuras y referencias, pero no se generó ni inspeccionó visualmente un PDF nuevo. No se certifica todavía la maquetación final.

El archivo auxiliar informa **61 páginas físicas**. El índice sitúa la introducción entre las páginas numeradas 3 y 9: siete páginas, aproximadamente **11,48 % del total físico**. Con ese denominador, no coincide exactamente con el objetivo de 10 % establecido en las instrucciones del proyecto. Conviene fijar explícitamente el denominador y la tolerancia aceptada antes de ajustar extensión.

## 6. Conclusión que sí respaldan las pruebas

> En las familias PI y PII evaluadas, bajo el modelo de fricción, la retención de voltaje y las referencias simuladas, el PI de menor amplitud presenta una oscilación menor que el mejor PII. Ese orden se conserva al utilizar doble precisión y reducir el paso de integración. La magnitud de la ventaja depende del criterio de saturación. Existen variantes con discrepancias numéricas relevantes y casos cuya aceptación cambia con el refinamiento; por ello deben documentarse la sensibilidad y las restricciones antes de generalizar el resultado.

**Decisión:** conservar los resultados principales como evidencia de simulación, corregir los hallazgos abiertos y actualizar las conclusiones y la selección de variantes. No presentar todavía el conjunto como una validación experimental ni como una demostración general sobre PI frente a PII.

## 7. Evidencias y reproducción

- [Barrido nuevo: doble precisión, 10 subpasos](R15_doble.json).
- [Barrido refinado: 20 subpasos](R15_doble_sub20.json).
- [Comparación, selección y casos sensibles](comparacion_R15.json).
- [Comprobación de discrepancias con ode45](atipicos_ode45.json).
- [Auditoría estructural y huellas de fuentes](estructura.json).
- [Segunda pasada LaTeX](latex/pasada2.log) y [registro de Biber](latex/main.blg).
- [Código del barrido](../barrido_R15_doble.m), [comparador](../comparar_barrido_02.py) y [comprobación con ode45](../validar_atipicos_02.m).

Desde la raíz del proyecto:

```sh
python3 validacion/validar_estructura.py validacion/barrido_02
/Applications/MATLAB_R2025a.app/bin/matlab -batch "run('validacion/barrido_R15_doble.m')"
/Applications/MATLAB_R2025a.app/bin/matlab -batch "SUBPASOS_AUDITORIA=20; run('validacion/barrido_R15_doble.m')"
/Applications/MATLAB_R2025a.app/bin/matlab -batch "run('validacion/validar_atipicos_02.m')"
python3 validacion/comparar_barrido_02.py
```

El barrido de esta revisión corresponde a **R15**. No se reejecutaron las 7503 trayectorias del mapa de operación ni las simulaciones completas de seguimiento senoidal/trapezoidal. Tampoco se regeneró la familia de controladores desde su diseñador: se validó el comportamiento de los 256 controladores discretizados disponibles. Los originales de la tesis y sus resultados se conservaron.
