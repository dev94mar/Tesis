# Memoria del proyecto

Actualizada: **2026-10-05**. Estado observado en el commit **`250dc18`**, con cambios locales sin commit (incluida la corrección de esta fecha). La cuarta auditoría y su veredicto se registran al final de esta memoria; sus hallazgos matizan las conclusiones históricas anteriores.

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

**`PII_V2` verificado pero su ventaja NO generaliza (sesión 2026-10-04, completa).** El grafo había incorporado un nodo `PII_V2` (PII rediseñado: `kK=2,5`, ceros bajos ×1,8, red de adelanto ×1,1) sin script ni dato que lo respaldara. Se escribió `icr/calculus/Final_Bien/R15_sintonizacion/validar_PII_v2.m` (MATLAB/`ode45`, independiente del diseño original) y **confirmó** sus cifras dentro de 0,1–3 %: ciclo 0,011018 cm, atascamiento 0,2444 s, frente al mejor PI del barrido restringido (0,013403 cm / 0,2624 s). Hasta ahí, parecía respaldar la hipótesis de que PII es mejor.

El usuario pidió entonces que esto respaldara la hipótesis en el texto. Antes de escribirlo, se probó si la ventaja sobrevive a una comparación **simétrica** (dar al PI la misma libertad). **No sobrevive:** aplicarle al PI la receta idéntica de `PII_V2` da márgenes de fase lineales aún mejores (40–53°) pero **diverge** en la simulación no lineal (saturación 86 % del tiempo) — el margen lineal no garantiza viabilidad frente a la saturación. Extendiendo luego la ganancia de cada familia por separado sobre su propio óptimo ya conocido (cero bajo y red de adelanto fijos): el **PI domina al PII en ciclo límite y en atascamiento en todo nivel de ganancia común**, y tolera casi el doble de ganancia (`kK=4,5` con margen 30,2°, ciclo 0,00748 cm, atascamiento 0,398 s) antes de perder el margen de 30° que pierde el PII ya en `kK=3,5` (su último punto válido, `kK=3`, da ciclo 0,01312 cm, atascamiento 0,844 s).

**Conclusión real: la ventaja de `PII_V2` dependía de la forma particular de su red de adelanto, no de la segunda integración.** Dada la misma libertad, el PI mejora más. Esto se incorporó honestamente al capítulo 6 (sección "¿Ayuda liberar la red de adelanto?", `icr/context/Tesis/capitulos/06_doble_integral.tex`) y a su síntesis, reforzando —no respaldando— la conclusión ya existente del capítulo de que la segunda integración no reduce el ciclo límite ni el atascamiento. El grafo (`PII_V2`, `R25`) se actualizó con esta conclusión; el documento compila sin errores (63 páginas). Scripts y datos completos en `icr/calculus/Final_Bien/R15_sintonizacion/` (`validar_PII_v2.m`, `validar_PI_v2.m`, `buscar_PI_v2.m`, `probar_PI_dirigido.m`, `extender_ambos.m`) y detalle narrativo en [barrido_03/VEREDICTO.md](validacion/barrido_03/VEREDICTO.md).

**Cierre con barrido conjunto del PI (mismo día).** Se hizo el barrido conjunto pendiente: `icr/calculus/Final_Bien/R15_sintonizacion/barrido_conjunto_PI.m`, 450 combinaciones de `(kK, α, β)` del PI, 394 con margen de fase ≥30°, simuladas en paralelo (235 no divergen). Tras depurar candidatos degenerados (atascado lejos de la referencia, detectado y filtrado), **3 configuraciones superan a `PII_V2` en ciclo límite Y atascamiento a la vez** — la mejor (`kK=3,5`, `α=1,4`, `β=1,15`): ciclo 0,00789 cm, atascamiento 0,2412 s, pero con sobrepaso de 60,14 % (frente a 29,16 % de `PII_V2`), un costo no capturado por las dos métricas que se venían comparando. Otros puntos dan, por separado, el menor ciclo (0,00545 cm) o el menor atascamiento (0,209 s) de todo este trabajo. **Ninguna variante de PII encontrada en esta sesión iguala estos valores.** Verificado por resimulación directa (32 episodios de atascamiento, error final 0,003 cm, no es un artefacto de ventana). Un candidato más extremo (ciclo 0,00058 cm) quedó señalado como no concluyente por posible efecto de borde de ventana (atascamiento de 9,65 s, casi toda la ventana de medición).

**Conclusión de todo el trabajo de esta sesión sobre PI/PII:** no hay evidencia, en ningún punto explorado, de que la segunda acción integral reduzca el ciclo límite o el atascamiento frente a un PI con libertad de sintonización equivalente; la evidencia apunta en sentido contrario. Incorporado al capítulo 6, al grafo (`PII_V2`/`R25`) y documentado en el tercer addendum de [barrido_03/VEREDICTO.md](validacion/barrido_03/VEREDICTO.md).

## Reescritura pedagógica del modelo energético (2026-10-04)

A petición del usuario, la subsección 3.2.2 ("Modelo energético sin disipación") se reescribió para un lector de mitad de carrera con nociones elementales de Euler-Lagrange/Hamilton. Construye la energía cinética y la potencial gravitacional paso a paso, y dedica el núcleo de la explicación al **acoplamiento electromecánico**: por qué la fuerza magnética exige un término que dependa de `x` y `u` a la vez (no solo de `x`, a diferencia de un sistema puramente mecánico), y por qué ese término es la **coenergía** `W'`, no la energía `W`, cuando la variable independiente es la corriente/voltaje — con el diagrama clásico de áreas en el plano `i`-`λ` como justificación gráfica del signo `F=+∂W'/∂x` (en vez de `F=-∂V/∂x`).

Se agregaron dos figuras TikZ nuevas en `images/energia/tikz/`: `energia_coenergia.tex` (el diagrama de áreas i-λ) y `coenergia_posicion.tex` (la coenergía `W'(x,u)` graficada contra la posición para tres voltajes, mostrando visualmente por qué crece de forma abrupta cerca de la bobina — la raíz de la inestabilidad). Se muestra además, explícitamente, que para un circuito lineal la coenergía `W'=½L(x)i²` reproduce exactamente la fuerza de reluctancia ya derivada por otro camino en la subsección anterior, conectando ambas partes del capítulo.

Documento: 78 páginas (antes 75), compila sin errores. Grafo (nodo `ENERGIA`) actualizado. Validador estructural limpio (188 nodos, 343 aristas, 0 hallazgos).

## Convergencia del modelo dipolo-dipolo a la ecuación del fabricante (2026-10-04)

A petición del usuario ("la solución obtenida por primeros principios debe converger a la ecuación dada por el fabricante"), se reforzó la justificación dipolo-dipolo del capítulo 3: en vez de solo mostrar que la forma coincide, se derivó el campo **exacto** de Biot-Savart de una espira circular finita (sin aproximar a dipolo puntual) y se demostró en Mathematica, con `Limit` y desarrollo en serie, que la fuerza dipolo-dipolo es el **límite de campo lejano** genuino de esa espira real: el error relativo es `-1+(1+(Rbob/z)²)^(-5/2)`, de orden `(Rbob/z)²`, y se anula exactamente cuando `Rbob/z→0` (0,025% de error con entrehierro=100×radio de la bobina, 2,5% con 10×). No es una forma impuesta por construcción: es una convergencia asintótica demostrada.

Incorporado al capítulo 3 (ecuaciones 3.14-3.15, justo después de la derivación original). Nodo `DIPOLO` del grafo actualizado. Compila sin errores, 75 páginas. Validador estructural limpio (188 nodos, 343 aristas).

## Validación de las cuatro señales de seguimiento (2026-10-04)

A petición del usuario se extendió a las cuatro pruebas de seguimiento (senoidal, trapezoidal, diente de sierra, pulso cuadrado) la validación independiente que antes solo cubría las dos originales. Informe: [VALIDACION_SEGUIMIENTO.md](validacion/VALIDACION_SEGUIMIENTO.md).

- `validar_csv.m` extendido con los dos casos nuevos: los 10 CSV de diente/pulso coinciden con sus `.mat` a precisión de máquina (10⁻¹³–10⁻¹⁴), igual que sen/trap.
- `validar_metricas_seguimiento.m` (nuevo): recalcula desde las series completas (sin decimación) todas las métricas citadas en el capítulo 5 para las cuatro señales. Coinciden exactamente, salvo una diferencia de ±1 en "rupturas" en tres de las cuatro, explicada: es un artefacto de qué dirección de transición se cuenta (inicio de atascamiento vs. ruptura propiamente dicha), no un error de datos.

Sin hallazgos que requieran cambios en el documento.

## Modelo energético sin disipación (Lagrange/Hamilton, 2026-10-04)

A petición del usuario se construyó un modelo energético (sin fricción) cuyas ecuaciones de movimiento reproducen exactamente la fuerza del fabricante que usa la tesis, `f_fld(u,x)=u/[b(a-x)^4]`, como verificación independiente del modelo dipolo-dipolo ya incorporado. Se propuso la coenergía magnética `W'(x,u)=u/[3b(a-x)^3]` (cumple `∂W'/∂x=f_fld`), y con ella el lagrangiano `L=½mẋ²-mgx+W'(x,u)`. La ecuación de Euler-Lagrange da exactamente `mẍ=f_fld(u,x)-mg` (idéntica a la ecuación de movimiento sin fricción). Verificación cruzada independiente con el formalismo hamiltoniano (momento canónico, transformada de Legendre, ecuaciones de Hamilton): mismo resultado. Ambas verificaciones dieron `True` en Mathematica (`icr/calculus/Final_Bien/primeros_principios/derivar_energia.wls`).

Incorporado al capítulo 3 como subsección 3.2.2 "Modelo energético sin disipación" (ecuaciones 3.14–3.17), justo después de la justificación dipolo-dipolo. Se agregó el nodo `ENERGIA` al grafo. Documento compila sin errores, 74 páginas. Validador estructural limpio (188 nodos, 343 aristas, sin duplicados ni referencias rotas).

## Actualización del grafo y validación de consistencia (2026-10-04)

A petición del usuario se actualizó el grafo (versión 5, `icr/grafo/grafo_tesis.json`) y se validó la consistencia completa del proyecto. Hallazgos y correcciones:

**En el grafo (estaba desactualizado desde varios commits atrás):**
- Nodo `PDFF`/`F_PD` (comparación con el PD) marcado como histórico: ese contenido se retiró del capítulo 6 (commits `ddc8284`/`a6e9901`) pero el grafo seguía citándolo como vigente, con una arista de soporte (`sustenta` a K11) y una referencia a un archivo de figura ya borrado. Se corrigió el texto, se redirigió el soporte de K11 a `CICLO`/`F_ANAT` (la figura de anatomía del ciclo, que sostiene el mismo argumento sin el PD).
- Se agregaron `DIENTE` y `PULSO` (pruebas de seguimiento nuevas del capítulo 5) y `DIPOLO`/`RIGIDEZ_GRAL` (derivación de primeros principios y validación analítica del capítulo 3/6), que no se habían incorporado al grafo pese a estar en la tesis desde los commits `85138bf` y `1504384`.
- Se corrigieron dos nodos de conclusión con datos obsoletos: `K1` decía "los dos seguimientos" (ahora son cuatro) y `K3` afirmaba que el control "nunca supera 3,3 V" (falso desde que diente/pulso saturan brevemente a 3,5 V y 0 V).

**En el documento (inconsistencia real, no solo del grafo):** el capítulo 7 (conclusiones), el resumen y el abstract seguían afirmando sin matiz que "la segunda acción integral no reduce" el ciclo límite ni el atascamiento, una conclusión que el capítulo 6 ya había superado con el hallazgo final del barrido conjunto (fronteras de Pareto cruzadas, ventaja acotada del PII en régimen de ganancia baja — ver "Cierre definitivo de la comparación PI/PII" más abajo). Se reescribió el párrafo "La hipótesis" del capítulo 7, la relación con los antecedentes, el resumen y el abstract para reflejar el hallazgo completo y acotado, y se mencionaron las cuatro pruebas de seguimiento (antes solo se nombraban dos). También se actualizó la frase de apertura del capítulo 6.

**Limpieza del grafo:** se encontraron y corrigieron una arista duplicada (`CICLO`→`K11` repetida) y un archivo CSV sin usar con filas inválidas (`destacados.csv`, no referenciado por ninguna figura, borrado). El validador estructural (`validar_estructura.py`) corre ahora sin ningún hallazgo: 0 aristas duplicadas, 0 fuentes inexistentes, 0 referencias LaTeX rotas, 0 CSV con filas inválidas, 187 nodos y 341 aristas. El documento compila sin errores, 74 páginas.

## Cierre definitivo de la comparación PI/PII: las fronteras se cruzan (2026-10-04)

El usuario señaló correctamente que la comparación anterior (barrido conjunto solo del PI contra `PII_V2`) no era simétrica: al PII nunca se le dio la misma libertad conjunta (kK+α+β) que al PI. Se hizo `icr/calculus/Final_Bien/R15_sintonizacion/barrido_conjunto_PII.m`, idéntico en método al del PI (misma rejilla de 450 combinaciones, mismo filtro de margen ≥30°, misma simulación). Resultado: 244/450 pasan el margen (menos que las 394 del PI), 182 válidos.

Comparado solo contra el único punto de referencia anterior (mejor PI combinado: ciclo 0,0079 cm, atasco 0,241 s), ningún PII lo supera en ambas métricas — pero esa comparación de un solo punto era incompleta. Al calcular la **frontera de Pareto completa de cada controlador**, se encontró que **las fronteras se cruzan en ciclo≈0,008 cm**: por debajo (ganancia alta, sintonización habitual de ambos controladores en esta tesis), el PI es mejor; por encima (ganancia baja, cero bajo desplazado), **el PII es mejor**, y en el extremo de menor atascamiento de todo el trabajo (PII con `kK=1,α=2,2,β=1,05`: ciclo 0,0261 cm, atasco 0,182 s) el PII **domina al PI en ambas métricas a la vez** (mejor PI de esa región: 0,0285 cm/0,209 s), verificado por resimulación directa (38 episodios, converge bien).

**Conclusión final y definitiva de toda la línea de auditoría PI/PII:** la segunda acción integral sí tiene una ventaja real, pero acotada a un régimen específico de sintonización (ganancia baja, ciclo relativamente grande), no al régimen habitual (ciclo pequeño, el que usan los controladores de la tabla 6.1 de la tesis), donde el PI iguala o supera al PII. La hipótesis de la tesis ni se confirma ni se refuta en general: se sostiene de forma acotada.

Se agregó la figura de fronteras de Pareto (`images/pii_v2_results/tikz/fronteras.tex`) y se reescribió la conclusión del capítulo 6 (sección "¿Ayuda liberar la red de adelanto?" y síntesis) para reflejar este resultado completo. Grafo (`PII_V2`/`R25`) actualizado. Compila sin errores, 74 páginas. Detalle completo en el cuarto addendum de [barrido_03/VEREDICTO.md](validacion/barrido_03/VEREDICTO.md).

## Nuevas pruebas de seguimiento: diente de sierra y pulso cuadrado (2026-10-04)

A petición del usuario se agregaron dos referencias de seguimiento nuevas al capítulo 5 (sección 5.5), con el mismo simulador, controlador (`PII_lic.mat`) y metodología que las ya existentes (senoidal, trapezoidal): `seguimiento_P5.m` se extendió con `ref_diente` (rampa −2→−3 cm en 250 s con reinicio instantáneo, periodo 250 s) y `ref_pulso` (escalón −2/−3 cm con planos de 250 s y transición instantánea, periodo 500 s), ambas con la misma pendiente/duración que la prueba trapezoidal pero sin sus rampas de transición. Al editar el script su propia huella SHA-256 invalidó la caché completa, así que los 4 casos (incluidos senoidal y trapezoidal) se resimularon; los resultados de esos dos coinciden con los valores ya publicados en la tesis.

Resultados: diente de sierra, error eficaz 0,0177 cm, error máximo 1,012 cm (el salto mismo de la referencia, no error de seguimiento), 77,9 % atascado, 4236 rupturas, saturación superior brevísima (0,017 % del tiempo), sobrepaso hasta −1,70 cm. Pulso cuadrado: error eficaz 0,0174 cm, error máximo 1,014 cm, 77,3 % atascado, 4708 rupturas (la cifra más alta de las cuatro pruebas), satura por arriba y por abajo brevemente (0,0075 %), sobrepaso hasta −3,25/−1,71 cm. Ambas pruebas son, con diferencia, las más exigentes para el actuador de las cuatro de seguimiento, por los reinicios/transiciones instantáneos.

Se agregaron 8 figuras TikZ nuevas (`images/seguimiento_results/tikz/diente_*.tex`, `pulso_*.tex`) y dos subsecciones nuevas en `05_desempeno.tex` (5.5.3 y 5.5.4), con las ecuaciones de referencia numeradas y la prosa siguiendo las reglas de escritura matemática. Documento compila sin errores, 73 páginas (antes 66).

## Derivación de primeros principios y validación analítica (2026-10-04)

Informe: [primeros_principios.md](validacion/primeros_principios.md). Scripts: `icr/calculus/Final_Bien/primeros_principios/` (Mathematica/`wolframscript`).

Se derivó la fuerza electromagnética del ECP-730 desde primeros principios (modelo dipolo-dipolo de campo lejano: bobina e imán como dipolos, bobina resistiva con `i=u/R`), reproduciendo **exactamente** la forma `u/(a-x)⁴` del modelo del fabricante que la tesis adopta sin derivar. Se explicó además por qué los cinco modelos de la literatura citados en el capítulo 3 usan `i²/entrehierro²`: corresponden al régimen de reluctancia cercana (electroimán-armadura), un régimen físico distinto, no un desacuerdo experimental. Equilibrio, matriz linealizada y función de transferencia derivados de esta fuerza coinciden exactamente (dentro del redondeo) con los del capítulo 3/4.

Con esa base, se validó analíticamente (sin simular) la hipótesis PII/PI: extrayendo `Ki`/`Kii` directamente del desarrollo de Laurent de las funciones de transferencia reales (coinciden con los valores del capítulo 6), se confirmó que el PII tarda analíticamente un 14 % más en romper la banda de fricción que el PI con el mismo error de atascamiento, y que una fórmula de rigidez generalizada (ganancia de alta frecuencia `C(∞)` de cualquier controlador propio, no solo del PD ya descartado) predice un ciclo límite 17 % mayor para el PII, consistente en sentido con el 6 % medido. **Conclusión: la derivación analítica confirma, por una vía independiente de toda simulación, que la ventaja/desventaja del PII depende de sus ganancias efectivas, no del número de integradores** — refuerza el hallazgo de la tercera auditoría (barrido conjunto del PI).

Incorporado a la tesis: capítulo 3 (subsección "Justificación de primeros principios", ecs. 3.9–3.13) y capítulo 6 (verificación de Ki/Kii y ecuación de rigidez general 6.4). Compila sin errores, 66 páginas.

## El repositorio de GitHub cambió: ahora es público, con un deck web (2026-10-04)

**Cambio importante de infraestructura, no solo de contenido.** El repositorio privado original `dev94mar/Tesis` se **eliminó por completo** de GitHub (a petición explícita del usuario) y se **recreó como repositorio público** con el mismo nombre y la misma URL remota (`https://github.com/dev94mar/Tesis.git`), con todo el historial de commits de esta sesión. La copia local en este disco nunca se tocó; solo cambió el remoto. Quien retome el proyecto debe saber que `git push`/`git pull` ya operan contra un repo **público**, no el privado original.

Se construyó además un **deck interactivo de divulgación** en HTML puro (sin frameworks, con capacidades propias): física del ECP-730 animada, diagrama de bloques del lazo, un panel de simulación en vivo con **selector de las 5 pruebas** (escalón, senoidal, trapezoidal, diente de sierra, pulso cuadrado) que reutiliza el mismo motor de canvas/gráficas con datos reales decimados (~40-50 KB por señal), y la gráfica de fronteras de Pareto PI/PII. Usa la identidad gráfica oficial de la UAM (rojo Unidad Azcapotzalco Pantone 186C `#CD032E`, Acuerdo 06/2012 núm. 5.3; tipografía Verdana obligatoria para web, núm. 4.1) y no usa ningún logotipo.

- Fuente: `deck/index.html` (idéntico a `docs/index.html`, que es la ruta que sirve GitHub Pages).
- **En vivo:** https://dev94mar.github.io/Tesis/ (GitHub Pages activado desde `/docs` en la rama `master`).
- Se corrigió un bug real de viewport: el archivo no tenía su propia `<meta name="viewport">` (dependía antes de que el Artifact tool la inyectara); sin ella, los celulares reales habrían cargado la página a ancho de escritorio. Verificado con Puppeteer a 390px.
- Existió un repo público intermedio, `dev94mar/ecp730-deck` (creado cuando `Tesis` aún era privado) — **ya se eliminó**; todo vive ahora en el propio repo de la tesis.
- Se generaron también 5 animaciones GIF con MATLAB (`icr/calculus/Final_Bien/animacion/`, ~20-30 MB cada una) análogas al panel web pero para verlas fuera del navegador. **El usuario pidió explícitamente no subirlas a GitHub** (son pesadas); quedan solo como archivos locales en este disco, no están en el repositorio.

## Próximo paso recomendado

1. **Hecho:** el barrido conjunto equivalente del PII (ver "Cierre definitivo de la comparación PI/PII"), la validación de las cuatro señales de seguimiento, la derivación de primeros principios con su convergencia demostrada, y el deck web público.
2. El candidato con ciclo 0,00058 cm (PI, `kK=4, α=0,3, β=1,2`) sigue necesitando una ventana de medición más larga para confirmar que es un ciclo límite genuino y no un efecto de borde; no se usó en ninguna conclusión final.
3. Actualizar el dictamen de publicabilidad ([PUBLICABILIDAD.md](validacion/barrido_02/PUBLICABILIDAD.md)) con la conclusión definitiva: la segunda integración sí ofrece una ventaja real pero acotada a un régimen de sintonización específico, no al habitual — un resultado más matizado y, posiblemente, más publicable que "el PII no sirve" o "el PII es mejor".
4. El repositorio ahora es público (ver sección anterior): antes de añadir cualquier dato sensible o aún no listo para publicarse, confirmar con el usuario, ya que cualquier commit queda visible de inmediato.

## Limpieza editorial: sin referencias directas a archivos mathematica/matlab/python en la tesis (2026-10-04)

A petición del usuario se removieron del texto de la tesis las citas literales de rutas/archivos y nombres de software: `capitulos/03_modelo.tex` (dos menciones a Mathematica con la ruta de `primeros_principios/`), `capitulos/04_controlador.tex` (`Control System Designer de MATLAB`), `capitulos/06_doble_integral.tex` (un comentario LaTeX con nombres de script y dos menciones a Mathematica con ruta) y `chapters/apendices/simulacion.tex` (`ode45 de MATLAB`, dos veces, y la tabla~\ref{tab:scripts} que listaba nombres de archivo `.m`/`.py`). En todos los casos se sustituyó por una descripción genérica del cálculo o la herramienta ("cálculo simbólico", "integrador numérico de paso variable", "editores interactivos de Bode y del lugar de las raíces"); la tabla del apéndice ahora describe procedimientos, no nombres de archivo del repositorio.

Es un cambio de redacción, no de contenido: ninguna cifra ni conclusión cambió. Los campos `fuente`/`verificacion` del grafo (nodos `DIPOLO`, `ENERGIA`, `RIGIDEZ_GRAL`) conservan la ruta real del script de Mathematica como metadato del grafo, porque ese archivo es metadato de ingeniería del proyecto, no texto de la tesis. Commit `47a6abf`. Documento recompilado sin avisos (78 páginas, sin overfull/underfull ni referencias indefinidas). Validador estructural limpio (0 filas de CSV inválidas).

## Mantenimiento

### Cuarta auditoría independiente, 2026-10-04 — estado observado en `250dc18`

Informe vigente para esta revisión: [barrido_04/VEREDICTO.md](validacion/barrido_04/VEREDICTO.md). **Validación numérica parcial favorable; aprobación científica integral pendiente de correcciones importantes.** Este resultado matiza los cierres «definitivos» anteriores: las entradas previas se conservan como historia, no como certificación de todas las conclusiones actuales.

Pruebas ejecutadas: validación estructural limpia; 26 CSV contra MAT con error máximo 4,97e-14; métricas de las cuatro señales sobre 9,5 millones de muestras guardadas; diez simulaciones del verificador numérico y seis trayectorias nuevas de 70 s de tres candidatos destacados, con tolerancias originales/estrictas y dos ventanas. Se reprodujeron las amplitudes nominales PI 0,03091046 cm y PII 0,03339335 cm. El candidato PII `(kK=1, alpha=2,2, beta=1,05)` conserva atascamiento corto bajo refinamiento y ventana posterior.

Hallazgos **detectados, todavía no corregidos en la tesis**: signo incorrecto de `−dU/dz` en la derivación dipolar; aplicabilidad física del campo lejano sin demostrar; formulación energética consistente pero no validación física independiente; rigidez C(∞) tratada con más fuerza demostrativa de la que admite la aproximación; nominales de 0,031/0,033 cm clasificados erróneamente por debajo de 0,008 cm; contradicciones residuales en capítulo 6 y filtrado de frontera PI incompletamente reproducible. La ventaja simultánea del PI destacado sobre PII_V2 se reproduce con el método original, pero desaparece con tolerancias estrictas en 25–35 s (PI: 0,00816165 cm / 0,2408125 s; PII_V2: 0,01087412 cm / 0,2348438 s). La comparación de PII_V2 con el mejor PI restringido también usa un atascamiento de referencia incorrecto: 0,26 s es del PI nominal, mientras el mejor PI restringido da aproximadamente 0,3485 s.

No se reejecutó el barrido completo, el mapa de operación ni el seguimiento largo; no se hizo revisión visual del PDF. No se modificaron fuentes de tesis, grafo, resultados originales ni informes anteriores. No hubo commit ni publicación externa. Antes de actualizar texto o declarar lista la tesis, consultar los hallazgos y límites del informe nuevo.

Actualizar fecha y commit cuando cambie el estado del proyecto. Para cada hallazgo distinguir: detectado, corrección observada, prueba ejecutada y resultado confirmado. Enlazar a la evidencia; no sustituir cifras reproducibles por recuerdos ni convertir una tarea propuesta en trabajo realizado.

### Correcciones de la cuarta auditoría aplicadas a la tesis, 2026-10-05

A petición del usuario se aplicaron a la tesis los ocho hallazgos de [barrido_04/VEREDICTO.md](validacion/barrido_04/VEREDICTO.md) (cambios locales, sin commit). Respaldo previo en `icr/context/Tesis/_respaldo_barrido04_2026-10-05/` y `icr/grafo/grafo_tesis.json.respaldo_barrido04_2026-10-05`.

1. **Signo de la fuerza dipolo-dipolo** (`03_modelo.tex`, ecs. 3.11-3.12): se corrigió la derivación para mostrar honestamente que `f_z=-dU/dz` es negativa (atrae hacia z decreciente) y que la fuerza positiva en x se obtiene con la regla de la cadena explícita `z=a-x`, antes implícita.
2. **Convergencia dipolar** (misma sección, ec. 3.15): se precisó que el error de convergencia está referido a la aproximación dipolar, no a la fuerza exacta (ambas convenciones dan -2,46 %/+2,52 % en Rbob/z=0,1), y se atenuó la conclusión a "convergencia matemática demostrada, aplicabilidad física al ECP-730 real no establecida" (faltan dimensiones reales de bobina e imán).
3. **Modelo energético** (misma sección): se eliminó la afirmación de que una fuerza lineal en u implica necesariamente un circuito magnético no lineal (contraejemplo: flujo de imán permanente), y se aclaró que Lagrange/Hamilton verifican consistencia algebraica, no una validación física independiente.
4. **Rigidez C(∞)** (`06_doble_integral.tex`): se reescribió como indicador heurístico/local, no demostración; se documentó el factor de subestimación (7-8×) y el caso de dos PII con el mismo C(∞) y ciclos distintos (0,0253 vs 0,0430 cm).
5. **Clasificación falsa de los controladores nominales**: se corrigió toda referencia que situaba a los controladores de la tabla 6.1 (PI 0,031 cm / PII 0,033 cm) en el régimen de ciclo pequeño (<0,008 cm) de las fronteras de Pareto optimizadas; están muy por encima de ese umbral y son una comparación distinta. Corregido en `06_doble_integral.tex` (dos lugares) y `07_conclusiones.tex`. También se corrigió el pie de figura de la extensión de ganancia (`kK=3` → `kK=3,5`, con `kK=3` como último punto válido).
6. **Filtrado de fronteras**: se documentó explícitamente el filtro de divergencia/atascamiento lejos de la referencia (235→193 PI, aplicado igual al PII) y la exclusión del punto `(0,000575 cm; 9,65 s)` por posible efecto de ventana; se suavizó la afirmación de dominio del PI "en toda amplitud menor a 0,008 cm" con los contraejemplos del veredicto.
7. **Robustez de la dominancia PI-destacado/PII_V2**: se agregó que esa comparación puntual no es robusta bajo tolerancias estrictas ni ventana [60,70]s (el PII pasa a tener menor atascamiento en ambos casos), mientras que el candidato PII de atascamiento corto (kK=1,α=2,2,β=1,05) sí lo es.
8. **Referencia incorrecta en la reducción porcentual**: se corrigió el atascamiento de referencia del "mejor PI restringido" de 0,26 s (que era del PI nominal) a 0,3485 s, cambiando la mejora reportada de PII_V2 de 7 % a ~30 %; se añadió que PII_V2 satura por arriba mientras el barrido restringido lo prohibía.

Verificación: la tesis compila sin errores ni avisos (`latexmk main.tex`, 81 páginas, antes 78). El grafo (`icr/grafo/grafo_tesis.json`) se actualizó en los nodos `DIPOLO`, `ENERGIA`, `RIGIDEZ_GRAL` y `PII_V2` con los mismos matices, y su historial (`meta.historial`) registra el cambio fechado 2026-10-05; `python3 consultar.py medir` confirma 188 nodos y 343 aristas, estructura íntegra. No se tocaron las cifras de regulación, seguimiento ni los demás capítulos; los hallazgos que el veredicto califica como "ya incorporados" (sobregeneralizaciones, criterio 57 PI/51 PII, etc.) no requerían cambio adicional.
