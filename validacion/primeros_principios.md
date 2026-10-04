# Derivación de primeros principios y validación analítica de la hipótesis

Fecha: 2026-10-04. Herramienta: Mathematica (`wolframscript`, enlazado en `/opt/homebrew/bin`). Scripts en `icr/calculus/Final_Bien/primeros_principios/`.

## Objetivo

El usuario pidió derivar el modelo de la planta del ECP-730 desde primeros principios (no solo adoptar el modelo del fabricante como hace el capítulo 3 de la tesis) y usar ese modelo para validar, de forma analítica —no solo numérica—, la hipótesis central de la tesis sobre el PII frente al PI.

## 1. Fuerza electromagnética: derivación dipolo-dipolo

Script: `derivar_fuerza.wls`.

El capítulo 3 de la tesis cita cinco modelos de la literatura (Al-Muthair, Charara, El Hajjaji, Zhao, Zhang), todos de la forma $i^2/\text{entrehierro}^2$, y adopta en cambio el modelo del fabricante del ECP-730, $f_{\text{fld}}=u/[b(a-x)^4]$, sin derivarlo, señalando solo que "cada modelo está condicionado por la configuración del sistema".

Se derivó en Mathematica, a partir de dos modelos físicos distintos:

- **Circuito de reluctancia** (electroimán cercano a una armadura): energía del campo con $L(x)=\mu_0 N^2 S/[2(a-x)]$, fuerza $f=\tfrac12 i^2 dL/dx \propto i^2/(a-x)^2$. Reproduce exactamente la forma de los cinco modelos de la literatura citados en el capítulo 3.
- **Dipolo-dipolo de campo lejano** (bobina e imán permanente separados, ninguno cerca del otro): campo axial de un dipolo $B(z)\propto m_{\text{bob}}/z^3$, fuerza de interacción con otro dipolo $f_{\text{dip}}=-dU/dz \propto m_{\text{im}}m_{\text{bob}}/z^4$. Con la bobina resistiva ($i=u/R$, constante de tiempo eléctrica despreciable) y el momento de la bobina proporcional a la corriente, se obtiene $f_{\text{dip}}(u,x)\propto u/(a-x)^4$.

Se verificó simbólicamente que el cociente entre la fuerza dipolo-dipolo derivada y el modelo del fabricante es una constante pura, sin `x` ni `u`: **la forma funcional coincide exactamente**. El parámetro empírico `b` de la tesis se identifica con una combinación de la resistencia del embobinado, su geometría y el momento magnético del imán —ninguno de estos datos lo publica el fabricante, por lo que `b` sigue siendo, correctamente, un parámetro ajustado experimentalmente y no uno derivado.

Esta derivación explica, además, por qué el modelo del fabricante difiere en forma de los cinco citados en la literatura: corresponden a regímenes geométricos distintos (reluctancia cercana frente a dipolos lejanos), no a un desacuerdo experimental entre fuentes.

## 2. Equilibrio y linealización

Script: `derivar_linealizacion.wls`.

Partiendo únicamente de la fuerza derivada en primeros principios y la segunda ley de Newton con fricción viscosa, se rederivaron de forma independiente:

- El voltaje de equilibrio $u_e(x)=mgb(a-x)^4$ — coincide exactamente con la ecuación (3.8) de la tesis.
- La matriz de estado linealizada $\begin{bmatrix}0&1\\4g/(a-x)&-c_1\end{bmatrix}$ — coincide exactamente con la que usan `familias_R15.m` y el resto de los scripts del proyecto.
- La función de transferencia linealizada en $x_1^*=-4$~cm: $G(s)=281{,}68/(s^2+8{,}563s-351{,}24)$ — coincide, dentro del redondeo, con la ecuación (4.1) de la tesis: $G(s)=281{,}7/(s^2+8{,}563s-351{,}2)$.

**Conclusión de esta parte: el modelo de planta de la tesis es físicamente reproducible desde primeros principios**, bajo la hipótesis dipolo-dipolo de campo lejano, y su linealización coincide con la que usa todo el proyecto.

## 3. Validación analítica de la hipótesis PII/PI

Scripts: `derivar_ciclo.wls`, `fix_ciclo.wls`, `rigidez_general.wls`.

El capítulo 6 de la tesis explica, con razonamiento y ajuste a los datos de simulación, por qué el PII se atasca más tiempo y tiene un ciclo límite similar o mayor que el PI. Se repitió esa derivación de forma simbólica e independiente, extrayendo los coeficientes directamente de las funciones de transferencia reales (no de los valores ya citados en el texto):

- **Duración del atascamiento.** El desarrollo de Laurent de $C(s)$ en $s=0$ da $K_i^{PI}=86{,}215$, $K_{ii}^{PII}=79{,}503$, $K_i^{PII}=63{,}367$ V/(cm·s o cm·s²) — coinciden con los 86,2/79,5/63,4 citados en el capítulo 6. Resolviendo la ecuación del cambio de voltaje durante el atascamiento para el mismo error inicial $e_0$ y el mismo ancho de banda $\Delta u$ en ambos controladores (aislando así el efecto de la estructura de su propio error de atascamiento, que en la simulación es distinto para cada uno), el PII tarda analíticamente un **14 % más** en romper la banda que el PI.
- **Amplitud del ciclo.** Se generalizó la fórmula de rigidez que antes solo se aplicaba al PD descartado (commit `ddc8284`) a la ganancia de alta frecuencia $C(\infty)$ de cualquier controlador propio. Con $C(\infty)_{PI}=178{,}1$ V/cm y $C(\infty)_{PII}=152{,}4$ V/cm, la rigidez neta predicha da un cociente de amplitudes PII/PI de **1,17**, del mismo orden y sentido que el 1,06 medido en la tabla 6.1 (0,033/0,031 cm). La magnitud absoluta subestima a la medida en casi un orden —la aproximación es estática y no captura la dinámica de la planta durante el deslizamiento—, pero el cociente, menos sensible a ese error sistemático, es consistente.

**Conclusión de esta parte: la derivación analítica confirma, por una vía independiente de toda simulación, lo que el capítulo 6 ya sostenía con datos — que la ventaja o desventaja del PII frente al PI es consecuencia de sus ganancias efectivas ($K_i$, $K_{ii}$, $C(\infty)$), no del número de integradores.** Esto es consistente con, y refuerza, el hallazgo de la auditoría anterior (`barrido_03/VEREDICTO.md`): cuando se amplía la libertad de sintonización del PI, este iguala o supera al PII en ambas métricas.

## Incorporación a la tesis

- Capítulo 3 (`03_modelo.tex`): nueva subsección "Justificación de primeros principios" (sección 3.2.1), con las ecuaciones (3.9)–(3.13).
- Capítulo 6 (`06_doble_integral.tex`): párrafo de verificación analítica en "Duración del atascamiento", y nueva ecuación general de rigidez (6.4) con su derivación en "Amplitud del ciclo".
- El documento compila sin errores ni referencias rotas, 66 páginas.

## Limitaciones

- La aproximación dipolo-dipolo requiere que el entrehierro sea grande frente al tamaño de la bobina y del imán; no se verificó contra las dimensiones físicas reales del ECP-730 (no publicadas), solo se argumentó que es razonable dado que $a=7{,}17$~cm es del orden del tamaño típico de estos dispositivos.
- El parámetro `b` no se derivó numéricamente desde primeros principios, solo se identificó su combinación de factores físicos; sigue dependiendo del ajuste experimental de Hernández Alcántara et al.
- La fórmula de rigidez general~(6.4) es una aproximación de orden de magnitud (subestima la amplitud absoluta casi 10×); se usó solo para el cociente entre controladores, no como predicción cuantitativa exacta.
- No se rederivó el modelo de fricción de Karnopp desde primeros principios: es un modelo fenomenológico estándar de la literatura de tribología, no una consecuencia de electromagnetismo o mecánica de cuerpo rígido, y la tesis ya lo trata así.
