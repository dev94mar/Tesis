# Cuarta auditoría: cálculos, demostraciones y resultados

Fecha: 2026-10-04. Fuente: commit `250dc18`, con cambios locales preexistentes en las instrucciones y archivos no versionados. Se consultaron MEMORY.md, claude.md, el mapa y el procedimiento. No se modificaron la tesis, los datos originales ni los informes históricos.

**Veredicto: validación numérica parcial favorable; aprobación científica integral pendiente de correcciones importantes.** La regulación nominal y las métricas de seguimiento son reproducibles. La comparación ampliada contiene resultados reales y útiles, pero algunas afirmaciones exceden la evidencia o se contradicen. Las nuevas demostraciones no pueden aprobarse íntegramente tal como están redactadas.

## Pruebas ejecutadas

- Validación estructural de las fuentes actuales: 67 archivos LaTeX activos, 145 etiquetas, 188 nodos y 343 aristas; sin referencias rotas, archivos faltantes ni filas inválidas en los 54 CSV examinados. Esto comprueba estructura, no verdad científica.
- Recálculo de métricas de las cuatro señales a partir de 9,5 millones de muestras guardadas. No se resimularon esos 9500 segundos.
- Contraste de 26 CSV con sus MAT, incluido seguimiento y regulación: diferencia máxima `4,973799150320701e-14`.
- Diez simulaciones del verificador numérico: nominales PI/PII, sensibilidad del PII y cuatro casos R15. El verificador contiene una planta escrita por separado del simulador original.
- Seis simulaciones adicionales de 70 segundos: tres controladores destacados, cada uno con tolerancias predeterminadas y estrictas (`RelTol=1e-9`, `AbsTol=1e-11`, `MaxStep=0,1 ms`). Controlador discretizado ZOH, muestreo 1 ms y planta original; ventanas [25,35] y [60,70] s. Son pruebas de reproducción/sensibilidad, no una segunda implementación independiente de la planta.
- Cálculo simbólico ejecutado con Wolfram y comprobación de fronteras directamente desde JSON/CSV mediante Python.

Los scripts y las salidas se conservan en esta carpeta. El arranque aislado de MATLAB/Wolfram falló; las ejecuciones efectivas se realizaron con autorización fuera del aislamiento. Se corrigió un fallo inicial de almacenamiento del nuevo verificador antes de completar las seis trayectorias.

## Resultados confirmados

| Magnitud | Recálculo actual |
|---|---:|
| Oscilación nominal PI, pico a pico | 0,0309104627 cm |
| Oscilación nominal PII, pico a pico | 0,0333933454 cm |
| Sobrepaso PI / PII | 25,8500 % / 23,6482 % |
| Margen de fase PII en −4 cm | 59,8604479° |
| Constante de velocidad PI en −3 cm | −91,604043 s⁻¹ |
| Error RMS senoidal | 0,0124018849 cm |
| Error RMS trapezoidal | 0,0114199236 cm |
| Error RMS diente de sierra | 0,0176801328 cm |
| Error RMS pulso | 0,0174323414 cm |

El filtro R15 sobre los datos guardados reproduce 57 PI y 51 PII. Los exponentes del ajuste de amplitud contra ganancia son −1,202864 y −1,122479. La sensibilidad nominal conserva el orden PI/PII: el PII da 0,03315793 cm con tolerancias estrictas, 0,03210249 cm con muestreo de 0,5 ms y 0,03056771 cm sin retención.

Se verifican algebraicamente el equilibrio `ue=mgb(a−x)^4`, la linealización viscosa, la banda de fricción y las ecuaciones mecánicas obtenidas por Lagrange/Hamilton. Los coeficientes de Laurent, calculados con los controladores redondeados del script simbólico, son `Ki_PI=86,215090`, `Ki_PII=63,366737` y `Kii_PII=79,503383`. El cociente de tiempos 1,142820 se reproduce **bajo las hipótesis** `q0=0`, error 0,0151 cm y cambio de voltaje 0,346 V; no es una desigualdad general entre PI y PII.

## Hallazgos que impiden una aprobación integral

### 1. Error de signo en la derivación dipolar

En `03_modelo.tex`, ecuación `eq:fuerza_dipolo`, se escribe `−dU/dz` como positivo aunque `U=−A/z³`, con A positivo. El resultado correcto es `Fz=−3A/z⁴`. El propio `derivar_fuerza.wls`, ejecutado nuevamente, devuelve el signo negativo, incluso después de sustituir `z=a−x`: sustituir una coordenada sin transformar la componente de fuerza no cambia ese signo.

La fuerza positiva hacia la bobina se recupera con `Fx=−d[U(a−x)]/dx=+3A/(a−x)^4`, o declarando explícitamente que se trabaja con la magnitud de atracción. Es un error corregible en la demostración; no implica que el signo positivo usado por la planta sea erróneo. Evidencia: `fuerza.log` y `simbolica.log`.

### 2. Convergencia matemática correcta, identificación física no demostrada

Se confirma `Fexact/Fdip=(1+(Rbob/z)^2)^(-5/2)` y su límite 1. El error escrito en `eq:error_convergencia` es `(Fexact−Fdip)/Fdip`, no un error normalizado por la fuerza exacta. A Rbob/z=0,1 ambos convenios dan −2,4569 % y +2,5188 %, respectivamente.

La prueba corresponde a una espira ideal y un imán puntual. No demuestra que la bobina real y el imán del ECP-730 estén en campo lejano en el intervalo utilizado: faltan tamaños, geometría y una cota del error del dispositivo. Tampoco identifica numéricamente b a partir de geometría, resistencia y momento magnético. La frase que justifica campo lejano por una separación «del orden del tamaño» no establece una separación mucho mayor. Además, la expresión microscópica de b debe declarar un sistema de unidades compatible con μ0 y convertirlo al convenio kg–cm–s de la tesis.

El límite dipolar estándar puede contrastarse con [Circular Current Loop, University of Texas](https://farside.ph.utexas.edu/teaching/jk1/Electromagnetism/node52.html). La inferencia sobre el aparato real requiere evidencia adicional del proyecto.

### 3. El modelo energético verifica consistencia, no prueba independiente de la ley de fuerza

Integrar la fuerza ya adoptada para construir `W'=u/[3b(a−x)^3]` y volver a derivarla reproduce exactamente la ecuación mecánica. Hamilton y Lagrange son formulaciones equivalentes de ese mismo modelo: su acuerdo verifica álgebra, no valida por separado la física ni la parametrización.

La afirmación «fuerza lineal en corriente implica circuito magnético no lineal» no se sigue. Un modelo con flujo de imán permanente `λ=L0 i+λpm(x)` tiene coenergía de interacción `i λpm(x)` y fuerza lineal en i aun con respuesta incremental lineal. La función propuesta puede interpretarse como término de interacción; no se ha derivado aquí la energía electromagnética completa. La formulación general de fuerza a partir de coenergía y corrientes está descrita en [MIT, Macroscopic Magnetic Forces](https://web.mit.edu/6.013_book/www/chapter11/11.7.html).

Con u variable, `dH/dt=−udot/[3b(a−x)^3]`: ausencia de fricción no significa conservación de H bajo excitación variable. Conviene explicitar `L(x,xdot;u(t))` y el alcance mecánico del modelo.

### 4. La rigidez de alta frecuencia es una heurística, no una demostración del ciclo límite

Se reproducen las rigideces 10240,745 y 8754,973 y el cociente 1,169706. Pero las amplitudes calculadas son 0,003906 y 0,004569 cm, frente a 0,030910 y 0,033393 cm: errores de factores aproximadamente 7,9 y 7,3. No se demuestra que el error se cancele al dividir ni se establece un régimen asintótico controlado.

Los propios datos muestran que C(∞) no determina por sí sola la amplitud: con kK=1, dos PII válidos tienen el mismo C(∞) y oscilaciones 0,025309 y 0,043034 cm al cambiar α/β. La expresión ofrece una interpretación local; no prueba existencia, unicidad o estabilidad de una órbita periódica ni independencia de los integradores. La explicación del 14 % de atascamiento también depende de ganancias y estados iniciales específicos.

### 5. La clasificación de los controladores nominales respecto al cruce es falsa

Los capítulos 6 y 7 sitúan a los controladores de la tabla de comparación directa en el régimen de ciclo menor que 0,008 cm. Esa tabla da 0,031 y 0,033 cm: ambos están por encima. Comparar nominales particulares y comparar fronteras optimizadas son operaciones distintas. Debe corregirse la vinculación entre el régimen nominal y el umbral.

También subsisten frases incompatibles: el capítulo 6 dice que ningún PII alcanza el atascamiento de 0,21 s, y después presenta uno con 0,182 s. El pie de la figura de extensión ubica la pérdida de margen en kK=3, mientras la prosa la ubica en 3,5 y considera válido kK=3. Son hallazgos actuales, no corregidos en esta auditoría.

### 6. Fronteras finitas y filtrado insuficientemente documentado

Los JSON contienen 394 PI (235 no divergentes) y 244 PII (199 no divergentes; 182 tras el filtro adicional). Las nubes publicadas contienen 193 y 182 puntos, respectivamente, y todos corresponden a resultados guardados.

La frontera PII coincide con los puntos no dominados de su nube. A la frontera PI le falta el punto `(0,000575164 cm; 9,65 s)` que sí permanece en la nube. Su exclusión por posible efecto de ventana es razonable, pero debe ser explícita y aplicarse de forma coherente. El script PI no guarda x_final ni implementa el mismo filtro final que el PII; por ello no puede verificarse la equivalencia del filtro de error final para todos los PI a partir de ese JSON.

Las líneas entre puntos discretos no son desempeños efectivamente simulados. Por ejemplo, para un presupuesto de amplitud 0,0081 cm, el PI disponible `(0,007892; 0,241188)` mejora el atascamiento del PII disponible `(0,008022; 0,2652)`, aunque 0,0081 es mayor que 0,008. En cambio, en 0,008283 cm aparece un PII con 0,221457 s. El cruce es orientativo, no un umbral demostrado para un continuo. Tampoco se puede afirmar que el PI sea mejor en toda amplitud inferior: existe un punto PII de 0,003383 cm que requiere un atasco mayor, fuera del alcance mínimo de la frontera PI publicada.

La misma rejilla de factores relativos da igual número de oportunidades, pero no aísla causalmente la segunda integración: las familias tienen ceros, polos y ganancias base diferentes. El resultado defendible es una ventaja de **ciertas sintonizaciones PII frente a las PI exploradas**, bajo las métricas y restricciones declaradas.

### 7. La dominancia del PI destacado sobre PII_V2 cambia con la integración y la ventana

| Caso | Método / ventana [s] | Oscilación [cm] | Atascamiento [s] |
|---|---|---:|---:|
| PI (3,5; 1,4; 1,15) | Predeterminado / 25–35 | 0,00789236 | 0,2411875 |
| PII_V2 (2,5; 1,8; 1,1) | Predeterminado / 25–35 | 0,01101814 | 0,2443871 |
| PI destacado | Estricto / 25–35 | 0,00816165 | 0,2408125 |
| PII_V2 | Estricto / 25–35 | 0,01087412 | 0,2348438 |
| PI destacado | Predeterminado / 60–70 | 0,00853657 | 0,2501613 |
| PII_V2 | Predeterminado / 60–70 | 0,01072421 | 0,2355313 |

La dominancia simultánea del primer par se reproduce, pero desaparece con tolerancias estrictas en la misma ventana y con una ventana posterior usando el método original. No es una conclusión robusta. Esto no invalida toda la comparación: obliga a expresar el compromiso entre métricas y a revalidar los puntos de frontera antes de calificarlos como óptimos.

El PII de atascamiento corto `(1;2,2;1,05)` sí conserva valores favorables: 0,026109 cm / 0,182421 s originalmente; 0,025718 cm / 0,174923 s con tolerancias estrictas en 25–35 s; 0,026503 cm / 0,180526 s en 60–70 s. Hay evidencia robusta de ese comportamiento del candidato. No se volvió a optimizar toda la familia PI bajo estas condiciones.

### 8. Referencia incorrecta para una reducción porcentual

El capítulo 6 compara PII_V2 con el mejor PI restringido y le atribuye a ese PI un atascamiento de 0,26 s, del que deriva una mejora del 7 %. El JSON R15 da 0,3485 s para el mejor PI de ciclo mínimo; la resimulación actual da 0,346273 s. Los 0,261684 s corresponden al PI nominal. PII_V2 da 0,244387 s, de modo que la mejora frente al mejor PI restringido es aproximadamente 30 %, si se usan esas ventanas y métodos. Debe compararse con la fila y definición correctas.

Además, PII_V2 alcanza saturación superior, mientras el barrido restringido exigía no alcanzarla después de la retención. La ampliación cambia las restricciones, además de liberar parámetros, y debe decirlo al interpretar la mejora.

## Alcance del dictamen

**Sí respaldado:** regulación y seguimiento del modelo en los ensayos reproducidos; superioridad nominal del PI en amplitud y tiempo de atascamiento; existencia de candidatos PII con atascamientos cortos; compromiso dependiente de sintonización entre las métricas.

**No demostrado:** superioridad universal de una estructura, atribución causal de las ventajas a la segunda integración, convergencia física exacta del aparato al modelo dipolar en su intervalo real, estabilidad no lineal global o existencia matemática de un ciclo límite. La palabra «estabiliza» debe leerse como desempeño acotado observado en las simulaciones, no como prueba general de estabilidad asintótica.

No se reejecutaron las 7503 trayectorias del mapa de operación, los 900 diseños del barrido conjunto ni el seguimiento completo desde condiciones iniciales. Tampoco se auditó exhaustivamente la bibliografía, se identificó el dispositivo real o se inspeccionó visualmente el PDF. El conteo del script de seguimiento llamado «rupturas» cuenta entradas al atascamiento; las diferencias de una unidad ya conocidas requieren uniformar la definición, no invalidan las series.

**Decisión:** conservar los resultados reproducibles; corregir las demostraciones y contradicciones señaladas; revalidar las fronteras con criterios comunes, tolerancias y ventanas explícitas. La tesis es defendible como estudio numérico condicionado al modelo, pero esta versión no merece un «todo correcto» ni un dictamen de lista para envío científico.

## Evidencia reproducible

- `estructura.json`, `estructura_resumen.txt`: inventario y huellas de fuentes actuales.
- `numerica.json`, `matlab.log`: márgenes, series y diez simulaciones.
- `csv_contra_mat.json`, `metricas_seguimiento_recalculadas.json`: recálculo desde MAT.
- `simbolica.wls`, `simbolica.log`, `fuerza.log`: identidad energética, signos, límite y rigidez.
- `recalcular_pareto.py`, `pareto.json`: relación entre barridos, nubes y fronteras.
- `resimular_frontera.m`, `frontera_resimulada.json`, `frontera.log`: seis trayectorias de 70 s y doce mediciones por ventana.

Los tres scripts `validar_*.m` de esta carpeta son copias de los verificadores existentes con rutas de entrada/salida adaptadas para preservar las auditorías históricas.
