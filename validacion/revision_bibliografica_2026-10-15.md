# Revisión bibliográfica dirigida: doble integrador y atascamiento-deslizamiento en levitación magnética

Fecha: 2026-10-15. Alcance: revisión dirigida (no exhaustiva) mediante varias rondas de búsqueda con términos distintos en español e inglés, usando motores de búsqueda web. No se tuvo acceso a bases de datos indexadas de pago (IEEE Xplore, ScienceDirect completo) más allá de lo que exponen sus páginas públicas, por lo que esta revisión debe tratarse como un sondeo y no como una búsqueda sistemática completa.

## 1. Antecedentes más cercanos encontrados

### 1.1 Hernández Alcántara et al. (2014) — ya citado en la tesis
"Control conmutado para un sistema de levitación magnética con atascamiento-deslizamiento", *Revista Iberoamericana de Automática e Informática Industrial*. https://www.sciencedirect.com/science/article/pii/S1697791214000314 (también https://elsevier.es/es-revista-revista-iberoamericana-automatica-e-informatica-331-articulo-control-conmutado-un-sistema-levitacion-S1697791214000314)

Aporta: usa el mismo ECP-730, pero en configuración REPULSIVA. Documenta explícitamente que añadir acción integral a un controlador de linealización por realimentación para eliminar error de estado estacionario *empeora* el atascamiento-deslizamiento, y resuelve el problema con una ley de control conmutada basada en la caracterización experimental de la superficie de deslizamiento (stick-slip), no con un segundo integrador.

Diferencia con esta tesis: no usa doble acción integral (PII); su solución es conmutación, no una segunda integral. Configuración repulsiva, no atractiva. No hace un análisis de frontera de Pareto ni concluye nada sobre el carácter acotado de una ventaja del doble integrador.

### 1.2 Pérez-Gómez et al. (2020) — ya citado en la tesis
Comparación PI/PII/control de zona muerta inversa en motor de CD con zona muerta, WSEAS.

Aporta: el antecedente directo de la idea de "doble acción integral" en el linaje de este grupo de trabajo, pero en un motor de CD con zona muerta, no en un sistema de levitación ni con atascamiento-deslizamiento por fricción seca tipo Stribeck.

### 1.3 Beerens, Heemels, Van de Wouw, Nijmeijer y colaboradores — hallazgo nuevo de esta búsqueda
Varios artículos de este grupo (TU Eindhoven), entre ellos "Stick-slip and convergence of feedback-controlled systems with Coulomb friction" (arXiv:2006.08977, https://arxiv.org/pdf/2006.08977) y trabajos relacionados sobre control PID híbrido/reseteado para sistemas de movimiento con fricción (p. ej. "Hybrid PID control for transient performance improvement of motion systems with friction", HAL, https://hal.archives-ouvertes.fr/hal-01970887).

Aportan: un análisis riguroso de cómo la acción integral de un PID interactúa con fricción de Coulomb/Stribeck para producir ciclos de atascamiento-deslizamiento, y condiciones de convergencia según la ganancia integral. Es la literatura más cercana, en espíritu, al tipo de análisis de "régimen de ganancia" que hace el capítulo 6 de esta tesis.

Diferencia con esta tesis: son sistemas de posicionamiento mecánico genéricos (servoactuadores, mesas XY), no levitación magnética; no usan doble integrador (PII) sino PID simple, control reseteado o control híbrido; no se encontró que concluyan específicamente que una segunda acción integral tenga una ventaja acotada a un régimen de ganancia baja/ciclo grande frente a PI.

### 1.4 Control conmutado, modos deslizantes y variantes del ECP-730
Varios trabajos adicionales sobre el ECP-730 y sistemas de levitación similares: "Integral sliding mode control with integral switching gain for magnetic levitation apparatus" (PolyU, https://research.polyu.edu.hk/en/publications/integral-sliding-mode-control-with-integral-switching-gain-for-ma/); "Control PID deslizante con generador de tiempo base para un sistema de levitación magnética" (UAEH, https://repository.uaeh.edu.mx/revistas/index.php/icbi/article/view/10203); trabajos de super-twisting (segundo orden de modos deslizantes) aplicados al Maglev Model 730 (ITM Web of Conferences, https://www.itm-conferences.org/10.1051/itmconf/20203201004; arXiv:2007.05750, https://arxiv.org/pdf/2007.05750).

Aportan: confirman que el ECP-730 es una plataforma de referencia recurrente para comparar estrategias de control no lineal (modos deslizantes, control deslizante integral, super-twisting), pero ninguno de estos trabajos usa específicamente un controlador lineal con doble acción integral (PII) ni documenta una ventaja acotada por régimen de ganancia; se concentran en robustez frente a modos deslizantes de orden superior.

### 1.5 Control reseteado y zona muerta del integrador frente a atascamiento-deslizamiento
Trabajos sobre "reset control" y "deadband reset scheduling" para mitigar ciclos límite inducidos por integrador en sistemas con fricción (p. ej. Bisoffi et al., Politecnico di Milano, https://re.public.polimi.it/retrieve/08e58490-45e8-4bbf-b5e2-2d007d568d15/11311-1226436_Bisoffi.pdf; "Stacking Integrators Without Sacrificing the Overshoot in Reset Control Systems", https://ar5iv.labs.arxiv.org/html/2110.06268).

Aportan: estrategias alternativas (apilar integradores con reseteo, desactivar o detonar la integral cerca del punto de operación) para el mismo problema de fondo —integral y fricción seca interactuando para producir ciclos límite—, aplicadas a sistemas de movimiento en general.

Diferencia con esta tesis: no son levitación magnética; usan reseteo o conmutación del integrador, no una segunda integral lineal permanente; el artículo "Stacking Integrators..." sí "apila integradores" de forma conceptualmente cercana al PII, pero dentro de un esquema de control reseteado (no lineal), y no concluye nada sobre acotamiento por régimen de ganancia en un sistema de levitación.

## 2. Conclusión

No se encontró en esta revisión ningún trabajo que combine simultáneamente las cuatro características de esta tesis: (a) control lineal con doble acción integral (PII), (b) aplicado a un sistema de levitación magnética en configuración atractiva, (c) para mitigar o caracterizar atascamiento-deslizamiento por fricción seca, y (d) que documente que la ventaja del segundo integrador es acotada a un régimen específico de sintonización (ganancia baja, ciclo límite grande) en vez de universal, con un análisis tipo frontera de Pareto del compromiso oscilación/atascamiento/saturación.

El antecedente más cercano en el linaje directo de este trabajo sigue siendo Hernández Alcántara et al. (2014): mismo tipo de plataforma (ECP-730), mismo fenómeno (atascamiento-deslizamiento inducido por acción integral), pero en configuración repulsiva y resuelto con conmutación, no con un segundo integrador. En términos de la herramienta de control (doble integrador) y del tipo de análisis (dependencia del resultado del régimen de ganancia, con interacción entre acción integral y fricción seca), el antecedente más afín encontrado fuera del linaje propio del grupo es la línea de trabajo de Beerens, Heemels, Van de Wouw y colaboradores sobre PID/control reseteado y fricción de Coulomb en sistemas de movimiento, que analiza con rigor cuándo la acción integral agrava o resuelve el atascamiento-deslizamiento según la ganancia, pero en servosistemas mecánicos genéricos, no en levitación magnética, y sin usar un segundo integrador lineal.

Con la salvedad de que esta es una revisión dirigida y no exhaustiva (no se consultaron bases de datos de pago completas ni se hizo una búsqueda sistemática tipo PRISMA), la combinación específica de esta tesis —PII en levitación atractiva con atascamiento-deslizamiento y hallazgo de ventaja acotada, no universal— parece ser una aportación original dentro de la literatura encontrada. No se identificó un trabajo idéntico ni muy cercano en esa combinación exacta.

## 3. Términos de búsqueda utilizados

- double integral control stick-slip magnetic levitation
- "PII controller" dry friction limit cycle integral action tuning
- second integral action anti-stick-slip controller magnetic levitation ECP
- Pareto front PID gain tuning dry friction limit cycle stick-slip tradeoff
- Beerens stick-slip integral control Coulomb friction limit cycle tuning bound
- "double integral" controller magnetic levitation system design
- PII control doble integrador levitador atractivo atascamiento deslizamiento tesis
- reset control dead zone integrator stick-slip magnetic levitation gain tuning regime
- "PI" "PII" comparison dry friction limit cycle amplitude gain tradeoff controller tuning
- super-twisting sliding mode ECP 730 magnetic levitation stick-slip gain regime limitation
