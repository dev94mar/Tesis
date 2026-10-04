# Evaluación de publicabilidad de los resultados

**Fecha:** 3 de octubre de 2026.  
**Dictamen:** **existe material potencialmente publicable, pero el trabajo actual necesita revisiones científicas mayores antes de enviarse como artículo de investigación.**

Esta es una evaluación técnica basada en la auditoría local, el segundo barrido y una búsqueda bibliográfica dirigida. No es una decisión editorial ni una garantía de aceptación. No se ha definido una revista o congreso de destino.

## 1. Qué resultado merece desarrollarse como publicación

El resultado defendible es una **comparación numérica de las limitaciones de PI y PII en un modelo atractivo del ECP-730 con fricción estática, retención de voltaje y límites del actuador**.

El segundo barrido ejecutó 1028 simulaciones nuevas. El orden entre los mejores casos PI y PII se conserva al utilizar doble precisión y refinar la integración. También permitió identificar dos cuestiones relevantes para reproducir la comparación: la sensibilidad de algunas trayectorias al método numérico y la dependencia de los resultados respecto a cómo se define la saturación. Véase el [veredicto numérico](VEREDICTO.md).

Sin embargo, esos datos no bastan para afirmar que la segunda integración nunca ayuda, que cualquier PI supera a cualquier PII o que el comportamiento observado representa experimentalmente al levitador real.

**Posible contribución, todavía por consolidar:** determinar, bajo restricciones explícitas y comparación equitativa, cuándo la segunda integración mejora el seguimiento y cuándo la fricción y la saturación dominan el desempeño. El resultado negativo puede tener valor si identifica sus condiciones de validez y permite a otros investigadores reproducirlo.

## 2. Novedad frente a antecedentes cercanos

| Antecedente primario | Qué establece | Implicación para este trabajo |
|---|---|---|
| Hernández Alcántara et al., 2014, *Control conmutado para un sistema de levitación magnética con atascamiento-deslizamiento* | En levitación repulsiva, presentan identificación y ensayos experimentales; la acción integral interactúa con la fricción y produce oscilaciones, que eliminan mediante conmutación. | La aparición de oscilaciones por integral y fricción no puede presentarse como descubrimiento nuevo. La diferencia relevante sería la configuración atractiva y una comparación PI/PII mejor delimitada. |
| Licéaga-Castro et al., 2012, *Slow-motion control of an unloaded hydraulic robot arm* | Utilizan doble acción integral en un robot hidráulico y añaden conmutación para eliminar oscilaciones de atascamiento-deslizamiento. | La doble integración por sí sola no es una contribución nueva; tampoco es nuevo que pueda coexistir con oscilaciones por fricción. |
| Pérez-Gómez et al., 2020, *Comparative Study Between Classical Controllers and Inverse Dead Zone Control for Position Control of a Permanent Magnet DC Motor with Dead zone* | Comparan PI, PII e inversa de zona muerta en un motor de CD y reportan ventajas del PII en ese sistema. | Ofrece una motivación concreta para estudiar los límites de transferencia del resultado. Una planta y una no linealidad diferentes no constituyen una refutación directa de ese artículo. |

Fuentes: [artículo de levitación, DOI 10.1016/j.riai.2014.05.003](https://www.sciencedirect.com/science/article/pii/S1697791214000314), [robot hidráulico, DOI 10.1016/j.precisioneng.2012.01.001](https://www.sciencedirect.com/science/article/abs/pii/S0141635912000049), [comparación en motor de CD, DOI 10.37394/232016.2020.15.22](https://wseas.com/journals/ps/2020/a445116-072.pdf).

**Evaluación de novedad:** plausible como estudio comparativo específico; insuficientemente acreditada como contribución general de teoría de control. La búsqueda dirigida no demuestra prioridad ni ausencia de trabajos equivalentes. Antes del envío falta una revisión sistemática del problema exacto y de las referencias que citan estos antecedentes.

Como referencia editorial, las instrucciones de RIAI piden situar la contribución frente a trabajos anteriores y justificar sus aspectos nuevos. Ese es el punto débil principal, más que el número de simulaciones. [Directrices de RIAI](https://polipapers.upv.es/index.php/riai/about/submissions).

## 3. Evaluación de preparación para publicación

| Dimensión | Evidencia actual | Evaluación |
|---|---|---|
| Relevancia | Problema concreto de fricción, limitación de voltaje y precisión de posición | Favorable |
| Reproducibilidad nominal | Scripts, datos, métricas y reproducciones independientes | Favorable con excepciones documentadas |
| Novedad | Aplicación y comparación específicas; mecanismos principales conocidos | Pendiente de demostrar y delimitar |
| Comparación equitativa | Familias restringidas, distintas redes de adelanto, ganancias y reglas de selección | Insuficiente para atribuir causalmente la diferencia a la segunda integración |
| Fiabilidad numérica | Extremos reproducibles, pero un PI difiere 16,36 % de la GPU y cambia una aceptación al refinar | Requiere un criterio explícito de convergencia y tratamiento de excepciones |
| Correspondencia física | Parámetros heredados de configuración repulsiva; retención de voltaje distinta de zona muerta estática | Limitada al modelo simulado |
| Robustez | Barrido de ganancias y ceros; no equivale a incertidumbre de la planta | Insuficiente para afirmaciones robustas amplias |
| Justificación matemática | Errores de unidades, estados integrales, signo y rigidez ya identificados | Debe corregirse |
| Validación experimental | No realizada en este trabajo | Ausente; limita las afirmaciones físicas |
| Presentación | Compilación técnica restablecida; contenido aún requiere ajustes | No lista para envío |

## 4. Objeciones previsibles de un revisor

### A. «No está aislado el efecto del segundo integrador»

El PI y el PII comparados difieren también en ceros, polos y ganancias. Usar el mismo factor multiplicativo `kK` no iguala su respuesta en frecuencia. Un barrido de parámetros elegido para dos estructuras tampoco prueba que se hayan encontrado sus mejores soluciones posibles.

Se necesita un protocolo común: mismos escenarios de evaluación, mismas restricciones de voltaje, esfuerzo de control, margen de estabilidad y velocidad de respuesta; objetivo de sintonización declarado y esfuerzo de búsqueda comparable. Las compensaciones auxiliares, como prealimentación o anti-windup, deben ser comunes o declararse como diferencias del esquema completo. Es preferible comparar los compromisos entre error, oscilación y esfuerzo de control a elegir únicamente el mínimo de una métrica.

### B. «El resultado depende de cómo se define saturación»

Con el filtro original, el nuevo barrido de 10 subpasos da mínimos de 0,01362232 cm para PI y 0,02632875 cm para PII. Si se excluye toda intervención del recorte superior antes de la retención, pasan a 0,01939681 y 0,02632875 cm. El orden se mantiene, pero la relación PII/PI cambia aproximadamente de 1,93 a 1,36.

Esto debe incorporarse al resultado principal. Una publicación no debería afirmar una ventaja de un factor dos sin declarar la señal y el criterio de selección que producen esa cifra. También deben explicarse las tres variantes PI omitidas en la figura original.

### C. «No se ha demostrado que la oscilación sea una propiedad suficientemente estable del modelo»

La discrepancia del 16,36 % en una variante PI exige investigar convergencia y sensibilidad. Comparar GPU/single con CPU/double mezcla plataforma y precisión; no identifica una causa única.

La comprobación debe variar, por separado, precisión, subpaso del integrador, tolerancias, banda de Karnopp y duración de la ventana estacionaria. Debe incluir estados iniciales distintos para detectar dependencia de condiciones iniciales. Si no se demuestra la existencia y aislamiento de una órbita periódica, puede describirse honestamente como oscilación persistente compatible con atascamiento-deslizamiento; una demostración formal de ciclo límite no es obligatoria para todo artículo de simulación, pero sí para sostener esa afirmación matemática en sentido estricto.

### D. «La hipótesis sobre zona muerta se prueba con otra no linealidad»

El actuador simulado retiene el último voltaje durante el movimiento y transmite directamente la orden durante el atascamiento. Eso no equivale a una función estática de zona muerta centrada en el equilibrio.

Hay dos caminos válidos: limitar el artículo explícitamente a esa ley con memoria, o estudiar por separado una zona muerta estática y la retención implementada. Las conclusiones sobre el dispositivo requieren, además, identificar o justificar cuál corresponde a su actuador.

### E. «Se atribuye alcance físico o universal a resultados de un modelo nominal»

No se han validado experimentalmente la configuración atractiva, la fricción ni la ley del actuador. Tampoco se ha demostrado estabilidad global, ni que cualquier controlador de una familia sea inferior a cualquier controlador de la otra.

La ausencia de experimentos **no impide por sí sola publicar** un estudio numérico. Sí obliga a aportar una contribución numérica o analítica sólida y a mantener las conclusiones dentro de ese alcance. Si el artículo pretende ofrecer una recomendación de implementación real en el ECP-730, la evidencia experimental se vuelve especialmente importante.

## 5. Trabajo mínimo antes de considerar el envío

1. **Corregir los errores confirmados.** Unidades de `b`, datos contradictorios del grafo que alimenten el manuscrito, selección de variantes, estado inicial de la acción integral doble, signo de las constantes de error, rigidez efectiva del PD y descripción del jacobiano. Regenerar tablas y figuras desde un único exportador.
2. **Fijar la pregunta y la comparación.** Definir exactamente qué ventaja se mide, con qué restricciones y qué tratamientos auxiliares. Aplicar el mismo procedimiento de sintonización y evaluación a ambos controladores; separar escenarios de ajuste y de comprobación.
3. **Cerrar la validación numérica.** Establecer tolerancias de concordancia acordes con el tamaño del efecto que se afirma; refinar hasta justificar los resultados principales y publicar los casos sensibles. No ocultar la excepción del 16,36 % bajo una diferencia media pequeña.
4. **Separar causas.** Comparar fricción sin retención, retención sin fricción estática y ambas, además del caso suave. Si se pretende hablar de zonas muertas estáticas, incluir esa ley. El ensayo previo sin retención ya aporta una parte de esta evidencia.
5. **Evaluar incertidumbre y alcance.** Variar fricción, masa y parámetros magnéticos en intervalos sustentados por identificación o fuentes. Si no se conocen esos intervalos, declararlos como sensibilidad hipotética. Añadir varias referencias, posiciones iniciales, perturbaciones y tratamiento de saturación. Un barrido de ganancias no sustituye estas pruebas.
6. **Acreditar una contribución diferenciada.** Formular qué se aprende más allá de los antecedentes de 2012, 2014 y 2020. Si sigue siendo una observación de un único modelo, fortalecerla mediante análisis explicativo, varios modelos/escenarios o experimentos.
7. **Preparar un paquete reproducible.** Incluir modelo exacto, parámetros y unidades, versión de los controladores, dependencias, criterios de exclusión, métricas y scripts que reconstruyan todas las figuras. Corregir el comportamiento de la caché de seguimiento.

Estos son criterios técnicos propuestos para este trabajo, no una lista oficial de requisitos universales de una revista. Ejecutar muchas repeticiones de una simulación determinista idéntica no aumenta la evidencia como si fueran ensayos experimentales independientes.

## 6. Enfoque de artículo con mayor sustento

**Título de trabajo propuesto:** *Alcance de la doble acción integral en un modelo de levitación magnética con atascamiento-deslizamiento y saturación*.

**Pregunta:** ¿bajo qué condiciones una segunda integración mejora el seguimiento sin aumentar las oscilaciones de atascamiento-deslizamiento, cuando el actuador está limitado?

**Aporte potencial:** un estudio reproducible de esos compromisos, con comparación equitativa y cuantificación de la sensibilidad numérica. La identificación de límites de aplicabilidad puede ser útil aunque el PII no resulte ganador.

La comparación PI/PII de un único modelo, con sintonización interactiva y sin resolver los hallazgos abiertos, todavía es una contribución demasiado débil para sostener por sí sola un artículo sólido. Los errores de los scripts son asuntos de corrección interna; solo constituirían una aportación metodológica independiente si se formula y demuestra una lección general sobre simulación de sistemas no suaves.

No se recomienda aún una revista concreta ni se estima una probabilidad de aceptación. Un artículo teórico exigiría resultados formales nuevos; uno aplicado con afirmaciones sobre el equipo requeriría evidencia física adecuada; un estudio de simulación puede ser viable si resuelve los puntos anteriores y demuestra una aportación diferenciada.

## 7. Veredicto final

**¿Son publicables?** Hay una base potencialmente publicable. **¿Están listos para enviar hoy? No.**

La reproducibilidad de los extremos es un punto fuerte. Los obstáculos principales son la novedad aún no acreditada, la comparación no suficientemente controlada, las inconsistencias de modelado y la validación numérica incompleta en casos sensibles. El documento puede convertirse en un artículo defendible si se centra en una conclusión acotada, corrige los errores y completa esas pruebas.

Esta evaluación no añade experimentos nuevos ni declara cerrados los hallazgos del [segundo barrido](VEREDICTO.md). Complementa su validación numérica con un juicio de preparación científica para publicación.
