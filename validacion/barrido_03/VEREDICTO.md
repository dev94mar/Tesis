# Tercera auditoría — veredicto

Fecha: 2026-10-04. Estado base: commit `8f2a1a9`, con cambios no comprometidos presentes en el árbol de trabajo (ver sección final). Alcance acordado con el usuario: (1) los 18 archivos identificados en `MEMORY.md` como cambiados tras el segundo barrido, y (2) la verificación del nodo `PII_V2` incorporado hoy mismo al grafo de conocimiento.

Este informe es una auditoría independiente de lo ya presente en el repositorio; no repite simulaciones completas salvo donde se indica, y no sustituye los informes históricos de `validacion/informe_validacion.txt` ni de `validacion/barrido_02/VEREDICTO.md`, que conservan su validez para las fuentes que auditaron.

## 1. Validación estructural

`python3 validacion/validar_estructura.py validacion/barrido_03` se ejecutó sin errores: 38 CSV examinados, 0 filas inválidas; grafo sin extremos ni fuentes inexistentes, sin IDs duplicados, con las 306 aristas y 180 nodos esperados (más los agregados hoy, ver §3); LaTeX sin inputs, imágenes o citas faltantes, sin etiquetas duplicadas.

Huellas SHA-256 comparadas contra `validacion/barrido_02/estructura.json`: **18 archivos cambiados** y **4 nuevos**, exactamente la lista que anticipaba `MEMORY.md`:

- Cambiados: `R15_sintonizacion/analisis_ciclo.m`, `seguimiento_P5.m`, los 7 capítulos (`01`–`07`), los dos anexos (`simulacion.tex`, `verificacion.tex`), `images/ciclo_results/tikz/analisis_ciclo.json`, `images/r15_results/tikz/{familia_pi.csv,familia_pii.csv,resumen_R15.json}`, `sections/{abstract.tex,resumen.tex}`, `icr/grafo/grafo_tesis.json`.
- Nuevos: `R15_sintonizacion/exportar_R15.py` y `R15_sintonizacion/validacion_02/{atipicos_ode45.json,comparacion_R15.json,numerica_auditoria1.json}`.
- Ningún archivo auditado en `barrido_02` fue eliminado.

## 2. Revisión de los 18 cambios (correcciones del segundo barrido)

Se delegó una revisión exhaustiva de lectura (sin reejecutar MATLAB) cruzando cifra por cifra el capítulo 6, los anexos, el exportador y la caché contra `resumen_R15.json`, `analisis_ciclo.json` y los tres archivos de `validacion_02/`. Resultado, punto por punto:

1. **Criterio de aceptación (57 PI / 51 PII): CONFIRMADO.** `exportar_R15.py` define el criterio (no divergencia y voltaje tras la retención < 3,5 V) y `resumen_R15.json` lo reproduce con los mismos conteos; `familia_pi.csv` y `familia_pii.csv` tienen exactamente 57 y 51 filas de datos.
2. **Caché con firma SHA-256 en `seguimiento_P5.m`: CONFIRMADO, lógica correcta.** La firma depende de los polos/ceros/ganancia del controlador cargado, del caso de prueba y de las huellas SHA-256 del simulador y del propio script; no hay rama donde la caché quede permanentemente válida o permanentemente inválida.
3. **Capítulo 6: CONFIRMADO en todas las cifras citadas.** Tabla PI/PII, 256 estables, 57/51 aceptados, criterio estricto (53/50), diferencias de doble precisión (1,6 %/0,8 %), banda de voltaje, `Kv = -91,6 s⁻¹` con signo explicado, sin afirmaciones de inferioridad universal del PII ni de ciclo límite demostrado matemáticamente (el texto lo trata como fenómeno simulado, con `\emph{hunting}` citado de la literatura).
4. **Otros capítulos y anexos: CONFIRMADO por muestreo.** Sin listas "donde: x es…, y es…"; todas las ecuaciones desplegadas revisadas llevan `\label`; sin cifras del capítulo 6 repetidas con valores distintos en las secciones muestreadas.
5. **Grafo de conocimiento: CONFIRMADO, con una discrepancia de metadato.** `Fs`, `b`, `c1` y los límites de voltaje coinciden con las convenciones del proyecto. **Discrepancia:** los nodos `REG`, `SIN` y `TRAP` tienen `valores.controlador = "PII.mat"` (el controlador preliminar) aunque sus cifras numéricas corresponden a `PII_lic.mat` (el controlador de la tesis). No afecta ninguna cifra citada en el texto; es una etiqueta de metadato desactualizada que conviene corregir en `icr/grafo/grafo_tesis.json`.
6. **Archivos de `validacion_02/`: CONFIRMADO, sin discrepancias ocultas.** Documentan la comparación GPU/simple contra doble precisión (57/51 en ambos), el caso atípico del 16 % y la auditoría numérica más amplia (polos, `Kv`, `Ka`, rigidez del PD); todo lo que citan coincide con el capítulo 6, sin hallazgos adicionales no reflejados en el texto.

**Veredicto de esta sección: las correcciones del segundo barrido están bien aplicadas e internamente consistentes.** Pendiente de acción: corregir la etiqueta `valores.controlador` en los nodos `REG`/`SIN`/`TRAP` del grafo.

## 3. Hallazgo no previsto: nodo `PII_V2` (grafo v5, hoy)

Al revisar el árbol de trabajo se encontró que, **después** del estado que describía `MEMORY.md`, el grafo fue modificado hoy (`icr/grafo/actualizar_v5.py`, fechado 2026-10-04) para agregar un nodo `PII_V2` y una revisión `R25`. Esta modificación **no está comprometida** (aparece como cambio sin confirmar en `git status`) y coexiste con una copia de respaldo `grafo_tesis_v4.json`.

El nodo afirma haber diseñado un controlador PII rediseñado,
\[
C_{PII,v2}(s)=\frac{381{,}075\,(s+8{,}775)(s+3{,}3498)(s+19{,}041)}{s^2\,(s+331{,}21)},
\]
que amplía la libertad del barrido de la tesis (ganancia `kK = 2,5` en vez de `kK ≤ 3` fijo con red de adelanto constante, más una red de adelanto reescalada ×1,1 y ceros bajos ×1,8). El nodo reporta márgenes de fase de 47,3°/41,0°/37,8°/34,5° en −4/−3/−2,5/−2 cm, ciclo límite de 0,0108 cm y atascamiento medio de 0,237 s frente a 0,013 cm/0,26 s del mejor PI del barrido R15 (mejoras de 17 % y 9 %), y un error eficaz en rampa unas tres veces menor que PI y PII originales. El propio nodo describe su procedencia como "diseño en Python (búsqueda numérica, validación RK45), verificación de estabilidad en Mathematica (Routh/raíces), validación cruzada en curso con el simulador MATLAB de la tesis", y aclara que no forma parte del texto de la tesis.

**Resultado de la verificación independiente: no se encontró ningún artefacto que respalde estas cifras.**

- No existe en el repositorio ningún script, log, notebook o archivo de datos con el nombre del controlador, sus coeficientes (`381,075`, `8,775`, `3,3498`, `19,041`, `331,21`) o sus métricas. Una búsqueda de esas cadenas en todo el árbol de trabajo (incluidos los *worktrees* en `.claude/worktrees/`) solo encontró una coincidencia espuria (un número de punto flotante no relacionado que contiene la subcadena `331.21`).
- No hay archivos `.nb` ni `.wls` en el repositorio que pudieran corresponder a la verificación en Mathematica.
- Una búsqueda en el directorio del usuario por archivos modificados después de `actualizar_v5.py` tampoco encontró rastro de Mathematica ni de un script de validación cruzada con MATLAB.
- No se intentó reproducir el diseño ni la simulación desde cero en esta auditoría: eso excede verificar lo ya producido y requeriría volver a ejecutar el mismo tipo de búsqueda numérica que generó la afirmación, con sus propios supuestos.

**Veredicto original de esta sección (antes del addendum): la afirmación de `PII_V2` era, con el estado del repositorio al momento de esta auditoría, irreproducible y no verificable.** El nodo mismo era honesto al respecto ("validación cruzada ... en curso", "no está en el texto de la tesis", "pendiente decidir"), pero tal como estaba documentado no cumplía el estándar de evidencia que exige el resto del proyecto (cadena verificable parámetros → simulación → métricas → cifra). Ver el addendum siguiente: esa reproducción ya se hizo.

## Addendum (mismo día): reproducción y validación independiente de `PII_V2`

A solicitud del usuario se escribió `icr/calculus/Final_Bien/R15_sintonizacion/validar_PII_v2.m`, un script MATLAB nuevo e independiente de cualquier script de Python o Mathematica previo, que:

1. Reconstruye `C_{PII,v2}(s)` algebraicamente a partir del PII de la tesis (`PII_lic.mat`) aplicando exactamente la receta descrita en el nodo (`kK=2,5` en la ganancia, ceros bajos `×1,8`, red de adelanto —cero y polo altos— `×1,1`), sin copiar los coeficientes numéricos del nodo.
2. Calcula el margen de fase en −4, −3, −2,5 y −2 cm con el mismo método que `familias_R15.m` (`margin` de Control System Toolbox).
3. Simula el escalón −2→−3 cm con fricción de Karnopp, zona muerta y saturación [0, 3,5] V integrando con `ode45`, con la misma lógica de retención y el mismo simulador (`maglev_karnopp.m`) que usó `validar_R15.m` para validar los controladores base del barrido R15.
4. Simula la rampa de −0,05 cm/s del barrido R15 con el mismo criterio que `simular_R15.py`, pero integrando con `ode45` en vez de RK4/MLX — un método de integración distinto al que generó la cifra original, para que la comparación sea una verificación real y no una repetición del mismo cálculo.

**Resultado (`icr/calculus/Final_Bien/R15_sintonizacion/validacion_PII_v2.json`, log en `validacion_PII_v2.log` de esta carpeta):**

| Cantidad | Afirmado en el nodo | Reproducido (ode45, MATLAB) | Diferencia |
|---|---:|---:|---:|
| Ganancia | 381,075 | 381,07 | 1,2×10⁻⁵ relativa |
| Ceros (bajos y red de adelanto) | −8,775 / −3,3498 / −19,041 | −8,775 / −3,349 / −19,044 | < 0,03 % |
| Margen de fase en −4 cm | 47,3° | 47,25° | 0,1 % |
| Margen de fase en −3 cm | 41,0° | 41,00° | exacto |
| Margen de fase en −2,5 cm | 37,8° | 37,73° | 0,2 % |
| Margen de fase en −2 cm | 34,5° | 34,42° | 0,2 % |
| Sobrepaso (escalón) | 29,1 % | 29,16 % | 0,2 % |
| Ciclo límite pico a pico | 0,0108 cm | 0,011018 cm | 2,0 % |
| Atascamiento medio | 0,237 s | 0,2444 s | 3,1 % |
| Error eficaz en rampa | 0,0024 cm | 0,002412 cm | 0,5 % |

Comparado contra el mejor PI del barrido R15 (0,013403 cm de ciclo límite, 0,2624 s de atascamiento medio, cifras ya confirmadas en §2 de este informe): la reproducción independiente da **−17,8 % en ciclo límite y −6,9 % en atascamiento medio**, consistente con el −17 %/−9 % que afirmaba el nodo. En la simulación reproducida el voltaje sí toca el límite de 3,5 V brevemente (0,17 % del tiempo total), lo cual es coherente con "sin saturación sostenida" pero conviene precisarlo si la cifra se usa en el texto.

**Veredicto del addendum: `PII_V2` queda CONFIRMADO por una validación independiente**, construida desde cero con un método de integración y una herramienta distintos a los que produjeron la cifra original, usando el mismo simulador y los mismos criterios de aceptación que el resto del barrido R15. Las diferencias (0,1–3 %) son del mismo orden que las diferencias de precisión ya documentadas entre métodos de integración en `validacion/barrido_02/comparacion_R15.json` (medianas 0,7–0,9 %, máximo 16 % en un caso atípico), y no cambian ninguna conclusión cualitativa.

El nodo del grafo (`icr/grafo/grafo_tesis.json`, nodo `PII_V2` y revisión `R25`) y `MEMORY.md` se actualizaron con esta verificación.

## Segundo addendum (mismo día): comparación simétrica — la ventaja de `PII_V2` no generaliza

El usuario pidió que `PII_V2` respaldara la hipótesis de la tesis (que la segunda acción integral reduce el ciclo límite y el atascamiento). Antes de escribirlo así, se verificó si la ventaja de `PII_V2` sobrevive a una comparación simétrica, dándole al PI de comparación la misma libertad de sintonización. **No sobrevive.**

**Intento 1 — misma receta exacta (`icr/calculus/Final_Bien/R15_sintonizacion/validar_PI_v2.m`).** Se aplicó al PI de la tesis la receta idéntica de `PII_V2` (`kK=2,5`, escalar su cero de baja frecuencia por `α=1,8`, escalar su propio cero-polo de adelanto por `β=1,1`). El margen de fase lineal resultante es, de hecho, *mejor* que el de `PII_V2` (40,8°–53,4° en el intervalo, frente a 34,4°–47,3°). Pero la simulación no lineal **diverge**: el voltaje queda saturado en 3,5 V el 86 % del tiempo y el imán se aleja sin control (`validar_PI_v2.log`, `validacion_PI_v2.json`). Esto muestra que el margen de fase lineal, por sí solo, no garantiza un comportamiento aceptable frente a la saturación del actuador — una advertencia metodológica aparte, válida para cualquier controlador que se diseñe solo con criterios lineales en esta planta.

**Intento 2 — barrido amplio con selección por tiempo de asentamiento lineal (`buscar_PI_v2.m`).** Se filtraron 405 combinaciones de `(kK, α, β)` por margen de fase (368 pasaron) y se seleccionaron candidatos por el menor tiempo de asentamiento lineal, primero en general y luego uno por nivel de `kK`. En ambos casos el criterio escogió sistemáticamente `α=3,2` (el extremo superior del rango explorado), y todos esos candidatos **divergieron** de forma idéntica (ciclo "pp" de 1145,5 cm, un valor de saturación numérica sin significado físico). Conclusión metodológica: el tiempo de asentamiento lineal es un mal predictor de viabilidad no lineal cuando se permite `α` extremo; no es evidencia de que el PI no pueda liberarse, sino de que ese criterio de selección estaba sesgado hacia puntos inviables.

**Intento 3 — extensión dirigida desde el óptimo conocido (`probar_PI_dirigido.m`).** Partiendo del mejor PI ya validado del barrido restringido (`kK=2,5079`, `α=0,7579`), se probaron 8 puntos razonables extendiendo `kK` y `β` moderadamente. Ninguno divergió. El punto `kK=3,5`, `α=0,7579`, `β=1` dio un ciclo de **0,00981 cm, menor que el de `PII_V2`** (0,011018 cm), aunque con un atascamiento mayor (0,370 s frente a 0,2444 s). El punto `kK=4,0` dio un ciclo aún menor (0,00952 cm).

**Intento 4 — comparación simétrica definitiva (`extender_ambos.m`).** Se extendió, por separado, la ganancia de cada familia sobre su propio óptimo ya conocido del barrido (PI: `kK=2,5079`, `α=0,7579`; PII: `kK=1,465`, `α=0,4353`), dejando fijos en cada caso el cero bajo y la red de adelanto (`β=1`). Resultado, en el mismo escalón −2→−3 cm:

| `kK` | PI: ciclo / atascamiento | PII: ciclo / atascamiento |
|---:|---:|---:|
| 1,465 | 0,02337 cm / 0,326 s | 0,02718 cm / 0,739 s |
| 2,0 | 0,01695 cm / 0,350 s | 0,01875 cm / 0,751 s |
| 2,5 | 0,01336 cm / 0,347 s | 0,01570 cm / 0,843 s |
| 3,0 | 0,01151 cm / 0,346 s | 0,01312 cm / 0,844 s (**pierde el margen de 30° en kK=3,5**) |
| 3,5 | 0,00963 cm / 0,366 s | — |
| 4,0 | 0,00879 cm / 0,396 s | — |
| 4,5 | **0,00748 cm / 0,398 s (pierde el margen de 30° en kK=5)** | — |

En **cada** nivel de ganancia que ambos toleran, el PI tiene un ciclo límite menor y un atascamiento más corto que el PII, y además el PI tolera casi el doble de ganancia (`kK=4,5` frente a `kK=3`) antes de perder el margen de fase mínimo de 30° que exige la tesis.

**Veredicto final: la ventaja de `PII_V2` no generaliza.** Dependía específicamente de la forma en que se reescaló su red de adelanto (`β=1,1` combinado con `α=1,8` en los ceros bajos), no de la segunda acción integral. Al dar a ambos controladores el mismo tipo de libertad —extender la ganancia sobre su propio óptimo conocido—, **el PI domina al PII en ambas métricas y en todo el intervalo de ganancia común**. Esto no es una búsqueda exhaustiva (no se optimizaron conjuntamente ganancia, cero bajo y red de adelanto de ambos controladores con un método formal), por lo que no se descarta que exista una combinación para el PII que cierre la brecha. Pero con la evidencia reunida, **no hay base para afirmar que la segunda integración por sí sola mejora el ciclo límite o el atascamiento; la evidencia adicional apunta en sentido contrario**.

Esto se incorporó al capítulo 6 de la tesis (`icr/context/Tesis/capitulos/06_doble_integral.tex`, sección "¿Ayuda liberar la red de adelanto?", que reemplaza a la versión anterior de esta misma sección escrita en el primer addendum) y a la síntesis del capítulo. El documento compila sin errores ni referencias rotas (63 páginas). El nodo `PII_V2` y la revisión `R25` del grafo se actualizaron para reflejar este resultado; `PII_V2` se conserva como hallazgo verificado y reproducible, pero explícitamente anotado como no generalizable.

## Tercer addendum (mismo día): barrido conjunto del PI, cierre de la comparación

El segundo addendum dejó abierta una pregunta: la extensión simétrica solo había variado la ganancia (`kK`), dejando fijos el cero bajo (`α`) y la red de adelanto (`β`) de cada familia en su propio óptimo ya conocido. Faltaba optimizar los tres parámetros a la vez para el PI, como ya se había hecho para el PII en `familias_R15.m` (aunque esta sin variar `β`). Se escribió `icr/calculus/Final_Bien/R15_sintonizacion/barrido_conjunto_PI.m`: una rejilla de $k_K\in\{1,\dots,5{,}5\}$ (10 valores), $\alpha\in\{0{,}3,\dots,3{,}0\}$ (9 valores) y $\beta\in\{1{,}0,\dots,1{,}2\}$ (5 valores) — 450 combinaciones —, filtrada por margen de fase ≥30° en los cuatro puntos del intervalo (394 pasan) y simulada en el escalón −2→−3 cm con `ode45`, en paralelo (Parallel Computing Toolbox, 10 núcleos) para que fuera viable en tiempo razonable.

**Depuración de resultados degenerados.** De las 394 simulaciones, 235 no divergen según el criterio de posición acotada, pero una inspección posterior reveló candidatos con "ciclo límite" aparentemente nulo que en realidad correspondían al imán atascado lejos de la referencia (un caso verificado terminó en $x=-3{,}70$~cm, a 0,70~cm del objetivo). Se añadió un filtro adicional (ciclo > 0,0005 cm) y se verificaron individualmente, por resimulación directa con inspección del error final, los candidatos de interés antes de usarlos. Con ese filtro quedan 193 candidatos válidos.

**Resultado.** Tres candidatos superan a `PII_V2` (ciclo 0,011018 cm, atascamiento 0,2444 s) en **ambas métricas a la vez**:

| `kK` | `α` | `β` | Margen de fase mín. | Ciclo pp | Atascamiento medio |
|---:|---:|---:|---:|---:|---:|
| 2,50 | 1,40 | 1,10 | 41,5° | 0,01061 cm | 0,239 s |
| 3,00 | 1,40 | 1,15 | 40,0° | 0,00991 cm | 0,239 s |
| **3,50** | **1,40** | **1,15** | **37,4°** | **0,00789 cm** | **0,241 s** |

El mejor de los tres (`kK=3,5`, `α=1,4`, `β=1,15`) se verificó por resimulación directa: converge a $x=-3{,}003$~cm (error final 0,003 cm), con 32 episodios de atascamiento en la ventana de medición (estadística confiable) y voltaje saturado solo el 0,48 % del tiempo. Tiene, sin embargo, un sobrepaso de **60,14 %**, muy superior al 29,16 % de `PII_V2` y al 23,6/25,9 % de la tabla~\ref{tab:pi_pii} del capítulo 6 — un costo no capturado por las dos métricas que se venían comparando.

Otros puntos del mismo barrido mejoran una sola métrica más allá de lo anterior: `kK=5,5, α=1,4, β=1,15` da el menor ciclo encontrado en todo este trabajo (0,00545 cm, con atascamiento 0,290 s), y `kK=1,0, α=1,4, β=1,10` da el menor atascamiento (0,209 s, con ciclo 0,0285 cm). Un candidato con `kK=4, α=0,3, β=1,2` reportó un ciclo aún menor (0,00058 cm) con atascamiento de 9,65 s (casi toda la ventana de 10 s); se verificó que no está atascado en la posición equivocada (error final de solo 0,0002 cm), pero esa duración, cercana al ancho completo de la ventana de medición, no permite descartar que sea un efecto de borde de la ventana más que un ciclo límite estacionario genuino. No se usó como cifra central por esta razón, y queda señalado para una verificación futura con una ventana de medición más larga.

**Conclusión final de esta línea de auditoría.** En ningún punto de este trabajo —ni el PII de la tesis, ni las familias del barrido original, ni `PII_V2`, ni la extensión simétrica de solo ganancia, ni este barrido conjunto— se encontró una configuración del PII que iguale el mejor desempeño encontrado para el PI en ciclo límite y atascamiento, cuando a ambos se les da una libertad de sintonización equivalente. La búsqueda del lado del PII no fue tan exhaustiva como la del PI (no se barrieron conjuntamente sus tres parámetros con red de adelanto variable), así que esto no demuestra una imposibilidad; pero con la evidencia reunida, **no hay base para sostener que la segunda acción integral reduzca el ciclo límite o el atascamiento en este sistema, y la evidencia disponible apunta en sentido contrario**.

Esto se incorporó al capítulo 6 (mismo archivo y sección) con el sobrepaso del mejor PI combinado señalado explícitamente como costo, al grafo (nodo `PII_V2`, revisión `R25`) y a `MEMORY.md`. El documento compiló de nuevo sin errores, 63 páginas.

## Cuarto addendum (mismo día): barrido conjunto simétrico del PII — las fronteras se cruzan

El tercer addendum dejó una asimetría explícita: el PI había recibido un barrido conjunto completo (ganancia, cero bajo y red de adelanto a la vez, 450 combinaciones), mientras que el PII solo se había explorado con un punto diseñado a mano (`PII_V2`) y una extensión de solo ganancia (`extender_ambos.m`). El usuario señaló correctamente que esta comparación no era simétrica y pidió completarla.

Se escribió `icr/calculus/Final_Bien/R15_sintonizacion/barrido_conjunto_PII.m`, idéntico en método a `barrido_conjunto_PI.m` (misma rejilla de `kK∈[1;5,5]`, `α∈[0,3;3]`, `β∈[1;1,2]`, mismo filtro de margen de fase ≥30° en los cuatro puntos del intervalo, misma simulación no lineal en paralelo), con el filtro de candidatos degenerados (atascados lejos de la referencia) incorporado desde el inicio, aprendido del barrido del PI.

**Resultado: 244 de 450 combinaciones cumplen el margen de fase** (frente a 394 del PI — el PII tolera menos ganancia antes de perder margen, consistente con lo ya visto en `extender_ambos.m`), **182 son válidas** tras filtrar divergencias y degenerados.

**Comparación contra el único punto de referencia usado hasta ahora** (el mejor PI combinado, `kK=3,5/α=1,4/β=1,15`: ciclo 0,0079 cm, atascamiento 0,241 s): **ningún** candidato del PII lo supera en ambas métricas a la vez. Hasta aquí, parecía confirmar el cierre del tercer addendum.

**Pero la comparación de un solo punto no es toda la comparación.** Se calculó la frontera de Pareto de cada barrido (el mejor atascamiento alcanzable para cada nivel de ciclo límite) y se encontró que **las dos fronteras se cruzan**, cerca de ciclo = 0,008 cm:

| Región | Controlador mejor | Ejemplo |
|---|---|---|
| Ciclo < 0,008 cm (ganancia alta, sintonización habitual) | PI | `kK=3,5/1,4/1,15`: 0,0079 cm / 0,241 s |
| Ciclo > 0,008 cm (ganancia baja, cero bajo desplazado) | PII | `kK=1/2,2/1,05`: 0,0261 cm / 0,182 s |

En el extremo de menor atascamiento de **todo** el trabajo (de las cuatro familias, `PII_V2`, las extensiones y ambos barridos conjuntos), el PII con `kK=1`, `α=2,2`, `β=1,05` da un ciclo de 0,0261 cm y un atascamiento de 0,182 s, y **supera al mejor PI de esa misma región** (`kK=1/1,4/1,10`: 0,0285 cm, 0,209 s) **en las dos métricas simultáneamente**. Se verificó por resimulación directa, fuera del barrido: converge a −2,989 cm (error final 0,011 cm), con 38 episodios de atascamiento en la ventana de medición (estadística confiable) — un resultado genuino, no un artefacto.

**Veredicto final, definitivo, de toda esta línea de auditoría:** la segunda acción integral no carece de toda ventaja, pero tampoco la tiene de forma general. Existe, acotada a un régimen específico (ganancia baja, ciclo límite relativamente grande, cero bajo desplazado lejos de su valor de diseño). En el régimen de ciclo pequeño —el que produce la sintonización habitual de ambos controladores en esta tesis, incluidos los de la tabla 6.1— el PI iguala o supera al PII. La hipótesis de la tesis ni se confirma en general ni se refuta en general: se sostiene, de forma acotada, en una región del espacio de sintonización que no es la habitual.

Se agregó la figura `images/pii_v2_results/tikz/fronteras.tex` (frontera de Pareto de ambos controladores, con las nubes de candidatos de fondo) al capítulo 6, y se reescribió la conclusión de la sección "¿Ayuda liberar la red de adelanto?" y la síntesis del capítulo para reflejar este hallazgo completo. El documento compiló sin errores, 74 páginas. El grafo (`PII_V2`, `R25`) se actualizó con el resultado definitivo.

Esto no agota el espacio de búsqueda: 450 combinaciones por controlador, en una rejilla discreta, no cubren el continuo de `(kK, α, β)`; podría existir una frontera verdadera distinta de la muestreada aquí. Pero con la evidencia reunida —cuatro familias de controladores, un rediseño manual, dos extensiones de ganancia y dos barridos conjuntos completos, todos con el mismo simulador y el mismo criterio— esta es la comparación más completa que se hizo en esta auditoría, y su resultado es el que se reporta arriba.

## 4. Pendientes y alcance no cubierto

- No se reejecutaron las 7503 trayectorias del mapa de operación completo ni el seguimiento largo; se verificó por lectura y cotejo de cifras, como en el segundo barrido.
- No se generó un PDF nuevo para inspección visual final; `main.pdf` existe pero su presencia no equivale a revisión visual de esta versión (igual que señalaba `MEMORY.md`).
- Queda pendiente decidir, como acción del usuario y no de esta auditoría, si `PII_V2` se descarta, se reproduce formalmente con script y validación MATLAB, o se documenta explícitamente como trabajo futuro sin cifras numéricas hasta tenerlas respaldadas.
- El cambio del grafo a v5 no está comprometido en git; si se decide conservarlo, debe hacerse junto con el respaldo del commit correspondiente y la corrección de la etiqueta de controlador señalada en §2.

## Conclusión

Las correcciones del segundo barrido (los 18 archivos) están bien aplicadas y son internamente consistentes; solo se encontró una etiqueta de metadato desactualizada en tres nodos del grafo, sin impacto en las cifras del texto. El hallazgo nuevo de esta auditoría es que el grafo v5 (sin comprometer) incorpora una afirmación de un controlador superior, `PII_V2`, que no tiene ningún artefacto reproducible en el repositorio y por lo tanto no puede certificarse ni usarse como base de ninguna conclusión mientras no se produzca y audite esa evidencia.
