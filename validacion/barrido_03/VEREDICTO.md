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

El nodo del grafo (`icr/grafo/grafo_tesis.json`, nodo `PII_V2` y revisión `R25`) y `MEMORY.md` se actualizaron con esta verificación. **Sigue sin estar incorporado al capítulo 6 de la tesis**; la decisión de si debe entrar al documento —y con qué alcance— es del usuario, no de esta auditoría.

## 4. Pendientes y alcance no cubierto

- No se reejecutaron las 7503 trayectorias del mapa de operación completo ni el seguimiento largo; se verificó por lectura y cotejo de cifras, como en el segundo barrido.
- No se generó un PDF nuevo para inspección visual final; `main.pdf` existe pero su presencia no equivale a revisión visual de esta versión (igual que señalaba `MEMORY.md`).
- Queda pendiente decidir, como acción del usuario y no de esta auditoría, si `PII_V2` se descarta, se reproduce formalmente con script y validación MATLAB, o se documenta explícitamente como trabajo futuro sin cifras numéricas hasta tenerlas respaldadas.
- El cambio del grafo a v5 no está comprometido en git; si se decide conservarlo, debe hacerse junto con el respaldo del commit correspondiente y la corrección de la etiqueta de controlador señalada en §2.

## Conclusión

Las correcciones del segundo barrido (los 18 archivos) están bien aplicadas y son internamente consistentes; solo se encontró una etiqueta de metadato desactualizada en tres nodos del grafo, sin impacto en las cifras del texto. El hallazgo nuevo de esta auditoría es que el grafo v5 (sin comprometer) incorpora una afirmación de un controlador superior, `PII_V2`, que no tiene ningún artefacto reproducible en el repositorio y por lo tanto no puede certificarse ni usarse como base de ninguna conclusión mientras no se produzca y audite esa evidencia.
