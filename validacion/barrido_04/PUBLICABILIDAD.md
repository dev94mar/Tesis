# Veredicto de publicabilidad tras la cuarta auditoría

Fecha: **2026-10-05**. Base documental: cuarta auditoría del 2026-10-04, sobre el commit `250dc18`, que sigue siendo el HEAD local al emitir este dictamen, con cambios locales sin commit.

**Dictamen: existen resultados con potencial de publicación, pero el trabajo todavía no está listo para enviarse como artículo científico.** Merece desarrollarse como estudio de simulación, condicionado a corregir las inconsistencias y consolidar la comparación numérica y la novedad.

Esta evaluación se basa en el [veredicto de la cuarta auditoría](VEREDICTO.md), el [dictamen anterior de publicabilidad](../barrido_02/PUBLICABILIDAD.md) y una consulta bibliográfica dirigida. No añade simulaciones, experimentos ni una revisión bibliográfica exhaustiva; tampoco constituye una garantía de aceptación editorial. Los informes anteriores se conservan como evidencia histórica.

**Nota de vigencia:** este archivo conserva el dictamen emitido en la conversación. Al guardarlo, la memoria del proyecto ya registra correcciones locales del 2026-10-05 a los ocho hallazgos de la cuarta auditoría. Esas modificaciones no fueron revalidadas para este dictamen: los pendientes editoriales enumerados abajo describen el estado auditado y deben contrastarse con dichas correcciones antes de considerarlos todavía abiertos. Las correcciones de redacción no sustituyen las pruebas numéricas pendientes.

## Aporte con mayor sustento

El aporte más defendible es una **comparación reproducible de los compromisos entre oscilación, atascamiento y saturación de controladores PI y PII en el modelo atractivo del ECP-730**.

La cuarta auditoría aporta evidencia concreta:

- La regulación nominal y las métricas de las cuatro señales de seguimiento se reproducen. En el seguimiento se recalcularon métricas desde las series guardadas; no se resimularon las trayectorias completas.
- El PI nominal presenta menor oscilación pico a pico: **0,03091046 cm**, frente a **0,03339335 cm** del PII.
- El candidato PII `(kK=1; alpha=2,2; beta=1,05)` conserva un atascamiento corto al refinar la integración y cambiar la ventana de observación: aproximadamente **0,175–0,182 s** en las mediciones documentadas. No se volvió a optimizar toda la familia PI bajo esas condiciones.
- La comparación ampliada muestra compromisos que dependen de la sintonización y de las métricas consideradas.

Estos resultados no demuestran todavía que la segunda integración sea la causa de una ventaja ni que alguna estructura sea superior en general. La conclusión defendible se refiere a determinadas sintonizaciones frente a las alternativas exploradas, bajo el modelo, las métricas y las restricciones declaradas.

## Novedad y alcance

Ya existen antecedentes sobre levitación con fricción y acción integral, y sobre comparación PI/PII en motores con zona muerta:

- Hernández Alcántara et al. (2014), [Control conmutado para un sistema de levitación magnética con atascamiento-deslizamiento](https://www.sciencedirect.com/science/article/pii/S1697791214000314).
- Pérez-Gómez et al. (2020), [Comparative Study Between Classical Controllers and Inverse Dead Zone Control for Position Control of a Permanent Magnet DC Motor with Dead zone](https://wseas.com/journals/articles.php?id=1168).

Por ello, emplear un PII o encontrar oscilaciones no constituye por sí solo una contribución nueva. El valor potencial está en establecer condiciones y límites de desempeño que esos antecedentes no resuelven. Esa diferenciación aún necesita una revisión bibliográfica más completa.

La ausencia de experimentos no descarta una publicación de simulación, pero exige una contribución numérica sólida y conclusiones limitadas al modelo estudiado. La formulación energética comprueba consistencia algebraica; no valida independientemente la física del dispositivo. Tampoco se ha demostrado que el aparato opere en el régimen de campo lejano supuesto por la derivación dipolar.

## Pendientes antes del envío

1. **Revalidar las fronteras con criterios comunes.** Uniformar restricciones, filtros de aceptación, estados iniciales, tolerancias y ventanas de medición. Una ventaja simultánea del PI destacado desaparece al refinar la integración. El cruce cercano a 0,008 cm es orientativo para los puntos explorados, no un umbral universal demostrado.
2. **Corregir las demostraciones y contradicciones.** Resolver el signo de la fuerza dipolar, la clasificación incorrecta de los controladores nominales respecto a 0,008 cm, las referencias usadas para calcular mejoras y las contradicciones residuales del capítulo 6. Presentar la rigidez de alta frecuencia como interpretación aproximada, no como demostración de la amplitud o existencia de un ciclo límite.
3. **Delimitar el alcance físico.** Distinguir la retención de voltaje con memoria de una zona muerta estática. Acotar las conclusiones sobre la ley magnética y el modelo energético, y separar consistencia matemática de validación física.
4. **Consolidar la novedad y la sensibilidad.** Separar los efectos de fricción y retención; comprobar los resultados principales ante variaciones pertinentes del modelo y escenarios adicionales. Un barrido de ganancias no sustituye el análisis de incertidumbre de la planta.

Estos pendientes son criterios técnicos de esta evaluación, no requisitos oficiales de una revista específica. Su cierre debe documentar las pruebas ejecutadas y sus resultados; una corrección editorial por sí sola no revalida una conclusión numérica.

## Revalidación posterior al dictamen (2026-10-05)

A petición del usuario se trabajaron los cuatro pendientes anteriores. Script y datos en esta misma carpeta (`revalidar_fronteras.m`, `fronteras_revalidadas.json`, `sensibilidad_planta.m`, `sensibilidad_planta.json`, `maglev_karnopp_param.m`, `frontera_params.json`).

**Pendientes 2 y 3 — corregidos y releídos directamente en la fuente, no solo reportados por el autor de la corrección.** Se releyó `icr/context/tesis/capitulos/03_modelo.tex` y `06_doble_integral.tex` tras el commit `51d37cb` (2026-10-05): el signo de la fuerza dipolar usa ahora la regla de la cadena explícita `dz/dx=-1` (ecs. `eq:fuerza_dipolo`–`eq:fuerza_dipolo_x`); la identificación física del régimen de campo lejano se acota explícitamente a "convergencia matemática... no que el aparato físico opere en él dentro de una tolerancia conocida"; la afirmación falsa "fuerza lineal en corriente implica circuito no lineal" ya no aparece en el texto (verificado por `grep`, sin resultados); la rigidez `C(∞)` se presenta como "indicador local y heurístico", con el factor de subestimación de 7 a 8 veces y el contraejemplo de dos PII con el mismo `C(∞)` y ciclos que difieren más del 70 %; la clasificación de los controladores nominales de la tabla 6.1 respecto al cruce de 0,008 cm está corregida en tres lugares (cap. 6 y 7); la cita de 0,26 s se corrigió a 0,3485 s (mejora recalculada a ~30 %, no 7 %); y la distinción entre la retención de voltaje con memoria y una zona muerta estática ya está en el capítulo 3. Se consideran cerrados.

**Pendiente 1 — revalidación numérica de las fronteras completas, no solo de puntos aislados.** Se reconstruyeron los 11 puntos de la frontera PI y los 10 de la frontera PII publicadas (fig. `fronteras`) con sus `(k_K,\alpha,\beta)` exactos, y se resimuló cada uno con tolerancias estrictas (`RelTol=1e-9`, `AbsTol=1e-11`, `MaxStep=T/10`) en la ventana original de 25 a 35 s, igual que la auditoría anterior hizo solo para 3 puntos.

- **20 de los 21 puntos son robustos:** el cambio en ciclo límite va de −4,2 % a +5,7 % y en atascamiento de −5,6 % a +3,5 %; ninguno diverge. El orden cualitativo general (PI mejor en la región de ciclo pequeño, PII mejor en la de ciclo grande) se sostiene en esos 20 puntos.
- **1 punto NO es robusto, y es significativo.** El extremo de menor ciclo de la frontera PII (`kK=4, α=0,3, β=1,15`), citado en el capítulo 6 como "un punto PII, de ciclo 0,003383 cm, que exige un atascamiento mayor que cualquier candidato de la frontera PI publicada en ese rango", cambia de **0,003383 a 0,009089 cm (+169 %)** en ciclo y de **0,705 a 1,111 s (+57 %)** en atascamiento al usar tolerancias estrictas: deja de ser un punto de ciclo extremo y su atascamiento casi se duplica. Este punto concreto, y la frase del capítulo 6 que lo cita, **no deben tratarse como confiables** sin una revisión adicional (ventana más larga, verificación con otro integrador). El resto de la frontera no se ve comprometido por este hallazgo.
- Cerca del cruce de 0,008 cm, la comparación puntual sigue siendo más matizada que un cruce limpio: con tolerancias estrictas, un punto PII de ciclo 0,0079 cm da un atascamiento de 0,268 s (peor que el PI de ciclo similar, 0,241 s a 0,0082 cm), pero otros puntos PII de ciclo apenas mayor (0,0083–0,0084 cm) dan atascamientos de 0,21–0,23 s, mejores que el PI más cercano. Esto es consistente con la propia cautela ya escrita en el capítulo 6 ("el cruce... es orientativo y no un umbral demostrado para un continuo"), no la contradice, pero refuerza que no debe presentarse como una frontera limpia y continua.

**Corregido en la tesis (2026-10-05, a petición del usuario).** Se eliminó el punto `(0,003383; 0,705)` de `images/pii_v2_results/tikz/frontera_pii.csv`; el capítulo 6 ahora documenta su exclusión junto a la del punto de 9,65 s de la frontera PI, y el párrafo que lo citaba como contraejemplo ("existe un punto PII, de ciclo 0,003383 cm... fuera de su alcance") se reescribió: con los 9 puntos robustos restantes, no hay evidencia de un candidato PII por debajo del cruce de 0,008 cm que supere al mejor PI disponible en ambas métricas. La figura 6.5 ya no muestra el pico espurio; el cruce cerca de 0,008 cm no se ve afectado. Respaldo en `icr/context/tesis/_respaldo_sensibilidad_2026-10-05/`; documento recompila sin errores, 81 páginas.

**Pendiente 4 — sondeo acotado de sensibilidad paramétrica, no un análisis de incertidumbre completo.** Se perturbaron `b` y `c1` (los dos parámetros de planta menos ciertos, heredados de Hernández Alcántara para la configuración repulsiva) en ±5 %, uno a la vez, para el PI nominal, el PII nominal y el candidato PII de atascamiento corto (`kK=1,α=2,2,β=1,05`), con tolerancias e integrador por omisión (ode45), 12 simulaciones en total.

- El PI y el PII nominales conservan el orden (PI con menor ciclo que PII) en las cuatro perturbaciones; los cambios de ciclo van de −5,4 % a +5,9 % y los de atascamiento de −3,4 % a +3,2 %. Robusto a esta perturbación acotada.
- El candidato PII de atascamiento corto, citado en el capítulo 6 como "robusto" frente a tolerancias de integración y ventana de medición, **diverge** con `b` aumentado un 5 % (la posición crece sin control). Con `b` reducido 5 % y con `c1` en cualquier sentido, se mantiene estable y con valores similares a los originales (ciclo 0,0247–0,0261 cm, atascamiento 0,18–0,19 s). Este candidato es, por tanto, robusto frente a tolerancias e integración, pero **no** frente a una incertidumbre moderada y plausible en `b`, el parámetro que la propia derivación de primeros principios (sección 3.2) ya identificó como no estimable de forma independiente para el dispositivo real.
- Este sondeo cubre solo 2 de los 5 parámetros de planta, solo ±5 %, y solo 3 controladores: **no sustituye** un análisis de incertidumbre completo (el pendiente 4 original lo pedía explícitamente). Ese análisis completo —variación conjunta de los cinco parámetros, con una caracterización de su incertidumbre real— sigue abierto.

**Corregido en la tesis (2026-10-05, a petición del usuario).** Se agregó, en el mismo párrafo del capítulo 6 que presenta este candidato, una reserva explícita: su ventaja es robusta frente a tolerancias de integración y ventana de medición, pero no frente a la incertidumbre de `b`, que no se identificó de forma independiente para el ECP-730 en configuración atractiva (sección de parámetros del capítulo 3), y que al perturbarlo +5 % hace que la simulación de este candidato diverja.

**Qué sigue genuinamente pendiente, sin reclamarlo resuelto:**

1. Revisión bibliográfica exhaustiva de novedad frente a los antecedentes citados (Hernández Alcántara 2014, Pérez-Gómez 2020 y otros no identificados aquí).
2. Análisis de incertidumbre de planta completo (los cinco parámetros, rango de variación justificado, no solo ±5 % en dos de ellos).
3. Identificación física del dispositivo real (geometría de bobina e imán) para acotar numéricamente la aproximación de campo lejano del capítulo 3 — sigue sin resolverse, como ya señalaba el dictamen original.

## Conclusión

**Hay una base potencialmente publicable y merece desarrollarse como artículo de simulación; la versión actual requiere revisiones científicas importantes antes del envío.** Los pendientes 2 y 3 del dictamen original (demostraciones, contradicciones y alcance físico en el texto) ya se corrigieron y se revalidaron por lectura directa. El pendiente 1 (fronteras) se revalidó en su mayor parte —20 de 21 puntos son robustos— y el único punto no robusto, citado en el texto, ya se corrigió: se excluyó de la frontera publicada y se reescribió el párrafo que dependía de su valor original. El pendiente 4 (sensibilidad) solo se sondeó de forma acotada: confirma la robustez de los controladores nominales ante una perturbación moderada, y la fragilidad encontrada en el candidato de atascamiento corto frente a `b` ya quedó documentada como reserva explícita en el capítulo 6, en vez de presentarse sin matices.

La hipótesis no necesita resultar favorable al PII para que el trabajo tenga valor. Identificar de manera fiable cuándo ciertas sintonizaciones ofrecen ventajas, qué costos introducen y hasta dónde se sostienen los resultados puede constituir el aporte científico. Con esta revalidación y sus correcciones aplicadas, esa fiabilidad es más sólida; lo que sigue abierto (revisión bibliográfica de novedad, análisis de incertidumbre completo, identificación física del dispositivo) son tareas de alcance mayor, no defectos puntuales del texto actual.
