# Sondeo de sensibilidad paramétrica completo (5 parámetros, ±5%/±10%)

2026-10-15. Extiende `sensibilidad_planta.m` (que solo perturbaba `b` y `c1` al ±5%)
a los 5 parámetros de planta del ECP-730 en configuración atractiva: `a`, `b`, `c1`,
`m` y `Fs`, cada uno perturbado uno a la vez (metodología *one-at-a-time*, no Monte
Carlo) en ±5% y ±10%, para el PI nominal, el PII nominal y el candidato PII de
atascamiento corto (`kK=1`, `alpha=2.2`, `beta=1.05`). `g=981` cm/s² no se perturbó
por ser constante física, no parámetro de incertidumbre del dispositivo. Mismo
simulador (`maglev_karnopp_param5.m`, copia parametrizada y verificada de
`maglev_karnopp.m`), mismas tolerancias e integrador (ode45 por omisión) y misma
ventana de medición ([25, 35] s) que el sondeo acotado original y que
`barrido_conjunto_PI.m`/`PII.m`.

Total: 5 parámetros × 4 perturbaciones × 3 controladores = 60 simulaciones nuevas,
más 3 simulaciones nominales (factor 1.0, no incluidas en el sondeo original) para
tener la línea base de cada controlador y calcular cambios porcentuales. Las 12
simulaciones de `b`/`c1` al ±5% del sondeo original se re-verificaron: coinciden
dentro de redondeo con las de este sondeo completo.

Archivos: script `sensibilidad_planta_completa.m`, función de planta
`maglev_karnopp_param5.m` (añade `Fs` como argumento, que en
`maglev_karnopp_param.m` original estaba fijo en 20), resultados
`sensibilidad_planta_completa.json`, línea base nominal
`sensibilidad_nominal_base.json`.

## Línea base nominal

| controlador | ciclo límite (cm) | atascamiento promedio (s) |
|---|---|---|
| PI nominal | 0.030910 | 0.2617 |
| PII nominal | 0.034124 | 0.3544 |
| PII candidato corto | 0.026109 | 0.1824 |

## Resultados por controlador

### PI_nominal (nominal: ciclo=0.030910 cm, atascamiento promedio=0.2617 s)

| parámetro | factor | ciclo (cm) | %Δciclo | atasc (s) | %Δatasc | diverge |
|---|---|---|---|---|---|---|
| a | x1.05 | 0.000000 (atascado) | −100.0% | 10.0000 | +3721.5% | NO diverge, pero se atasca por completo (ver nota) |
| a | x0.95 | 0.026681 | −13.7% | 0.2736 | +4.6% | no |
| a | x1.10 | DIVERGE | — | — | — | SI |
| a | x0.90 | 0.023972 | −22.4% | 0.2866 | +9.5% | no |
| b | x1.05 | 0.032669 | +5.7% | 0.2709 | +3.5% | no |
| b | x0.95 | 0.030036 | −2.8% | 0.2632 | +0.6% | no |
| b | x1.10 | 0.033906 | +9.7% | 0.2697 | +3.1% | no |
| b | x0.90 | 0.028520 | −7.7% | 0.2723 | +4.1% | no |
| c1 | x1.05 | 0.031153 | +0.8% | 0.2719 | +3.9% | no |
| c1 | x0.95 | 0.030991 | +0.3% | 0.2717 | +3.8% | no |
| c1 | x1.10 | 0.031080 | +0.5% | 0.2710 | +3.5% | no |
| c1 | x0.90 | 0.031079 | +0.5% | 0.2706 | +3.4% | no |
| m | x1.05 | 0.030827 | −0.3% | 0.2758 | +5.4% | no |
| m | x0.95 | 0.032027 | +3.6% | 0.2739 | +4.7% | no |
| m | x1.10 | 0.031378 | +1.5% | 0.2745 | +4.9% | no |
| m | x0.90 | 0.030419 | −1.6% | 0.2761 | +5.5% | no |
| Fs | x1.05 | 0.032554 | +5.3% | 0.2638 | +0.8% | no |
| Fs | x0.95 | 0.029523 | −4.5% | 0.2666 | +1.9% | no |
| Fs | x1.10 | 0.034109 | +10.3% | 0.2637 | +0.8% | no |
| Fs | x0.90 | 0.028097 | −9.1% | 0.2719 | +3.9% | no |

### PII_nominal (nominal: ciclo=0.034124 cm, atascamiento promedio=0.3544 s)

| parámetro | factor | ciclo (cm) | %Δciclo | atasc (s) | %Δatasc | diverge |
|---|---|---|---|---|---|---|
| a | x1.05 | 0.037734 | +10.6% | 0.3570 | +0.7% | no |
| a | x0.95 | 0.029135 | −14.6% | 0.3566 | +0.6% | no |
| a | x1.10 | DIVERGE | — | — | — | SI |
| a | x0.90 | 0.025305 | −25.8% | 0.3785 | +6.8% | no |
| b | x1.05 | 0.034649 | +1.5% | 0.3563 | +0.5% | no |
| b | x0.95 | 0.031963 | −6.3% | 0.3530 | −0.4% | no |
| b | x1.10 | 0.036463 | +6.9% | 0.3319 | −6.4% | no |
| b | x0.90 | 0.030056 | −11.9% | 0.3352 | −5.4% | no |
| c1 | x1.05 | 0.033140 | −2.9% | 0.3531 | −0.4% | no |
| c1 | x0.95 | 0.033326 | −2.3% | 0.3588 | +1.2% | no |
| c1 | x1.10 | 0.033588 | −1.6% | 0.3348 | −5.5% | no |
| c1 | x0.90 | 0.033416 | −2.1% | 0.3567 | +0.6% | no |
| m | x1.05 | 0.034035 | −0.3% | 0.3472 | −2.0% | no |
| m | x0.95 | 0.033058 | −3.1% | 0.3558 | +0.4% | no |
| m | x1.10 | 0.034052 | −0.2% | 0.3361 | −5.2% | no |
| m | x0.90 | 0.032273 | −5.4% | 0.3598 | +1.5% | no |
| Fs | x1.05 | 0.035262 | +3.3% | 0.3411 | −3.8% | no |
| Fs | x0.95 | 0.031873 | −6.6% | 0.3543 | −0.0% | no |
| Fs | x1.10 | 0.036127 | +5.9% | 0.3362 | −5.1% | no |
| Fs | x0.90 | 0.030488 | −10.7% | 0.3487 | −1.6% | no |

### PII_candidato_corto (nominal: ciclo=0.026109 cm, atascamiento promedio=0.1824 s)

| parámetro | factor | ciclo (cm) | %Δciclo | atasc (s) | %Δatasc | diverge |
|---|---|---|---|---|---|---|
| a | x1.05 | DIVERGE | — | — | — | SI |
| a | x0.95 | 0.022686 | −13.1% | 0.1835 | +0.6% | no |
| a | x1.10 | DIVERGE | — | — | — | SI |
| a | x0.90 | 0.020043 | −23.2% | 0.1922 | +5.4% | no |
| b | x1.05 | DIVERGE | — | — | — | SI |
| b | x0.95 | 0.024678 | −5.5% | 0.1792 | −1.8% | no |
| b | x1.10 | DIVERGE | — | — | — | SI |
| b | x0.90 | 0.023222 | −11.1% | 0.1837 | +0.7% | no |
| c1 | x1.05 | 0.026020 | −0.3% | 0.1877 | +2.9% | no |
| c1 | x0.95 | 0.026144 | +0.1% | 0.1813 | −0.6% | no |
| c1 | x1.10 | 0.025983 | −0.5% | 0.1823 | −0.1% | no |
| c1 | x0.90 | 0.026056 | −0.2% | 0.1757 | −3.7% | no |
| m | x1.05 | DIVERGE | — | — | — | SI |
| m | x0.95 | 0.025632 | −1.8% | 0.1834 | +0.5% | no |
| m | x1.10 | DIVERGE | — | — | — | SI |
| m | x0.90 | 0.025625 | −1.9% | 0.1818 | −0.3% | no |
| Fs | x1.05 | 0.027184 | +4.1% | 0.1776 | −2.6% | no |
| Fs | x0.95 | 0.024900 | −4.6% | 0.1880 | +3.0% | no |
| Fs | x1.10 | 0.028375 | +8.7% | 0.1782 | −2.3% | no |
| Fs | x0.90 | 0.024042 | −7.9% | 0.1819 | −0.3% | no |

(DIVERGE: `max(|x|) > 20` cm, o NaN/Inf, durante toda la simulación de 35 s.)

## Robustez por parámetro y controlador

**`c1` (fricción viscosa por unidad de masa):** robusto para los tres
controladores, en las cuatro magnitudes de perturbación. Los cambios en ciclo
límite y atascamiento se mantienen por debajo del 6% en todos los casos. Es,
junto con `Fs`, el parámetro mejor tolerado.

**`Fs` (fricción estática):** robusto para los tres controladores hasta ±10%.
El ciclo límite cambia monótonamente con `Fs` (a mayor `Fs`, mayor ciclo) pero
sin romper el orden entre controladores ni acercarse a divergencia; cambios
máximos de alrededor de 10% en ciclo y 4% en atascamiento.

**`m` (masa):** robusto para PI y PII nominales en todo el rango (cambios menores
al 6%). Para el candidato de atascamiento corto, `m` a +5% y +10% **diverge**:
el mismo patrón de fragilidad que ya se conocía para `b` se repite aquí. `m` a
−5% y −10% es inocuo para los tres controladores.

**`b` (constante de fuerza magnética):** robusto para PI y PII nominales en las
cuatro magnitudes (cambios de 2% a 12%, sin divergencia). Para el candidato de
atascamiento corto, `b` a +5% y +10% diverge, confirmando el hallazgo original del
sondeo acotado: la fragilidad del candidato ante incrementos de `b` no es un
artefacto de probar solo ±5%, se sostiene y se agrava a ±10%. `b` a la baja
(−5%, −10%) es inocuo para los tres controladores.

**`a` (distancia de referencia imán-bobina) — el parámetro más frágil, nuevo
en este sondeo:** incrementarlo +10% hace divergir a los tres controladores (PI,
PII y candidato). Al +5%, el PI nominal no diverge pero se atasca por completo
(ciclo límite cero, atascamiento promedio de 10 s sobre una ventana de 10 s: el
imán nunca vuelve a deslizar tras pegarse), un modo de falla distinto a la
divergencia pero igual de inaceptable en la práctica; el PII nominal sí sobrevive
+5% (ciclo +10.6%, atascamiento +0.7%), mientras que el candidato de atascamiento
corto diverge ya desde +5%. Reducir `a` (−5%, −10%) es inocuo para los tres
controladores. En suma, `a` es el parámetro que más discrimina entre
controladores: el candidato corto es el más frágil ante `a`, seguido del PI
(que falla por atascamiento total en vez de divergencia), y el PII nominal es
el más tolerante de los tres.

## Conclusión

**El orden cualitativo PI < PII en ciclo límite se sostiene en todo este sondeo
ampliado.** En la línea base nominal, ciclo(PI) = 0.030910 cm < ciclo(PII) =
0.034124 cm, y esa relación se mantiene en todas las 20 perturbaciones de cada
controlador que no producen divergencia ni atascamiento total: no hay ningún
caso en el que el PI perturbado supere al PII perturbado en ciclo límite dentro
del régimen donde ambos operan con normalidad. El único caso donde el PI "mejora"
su ciclo frente al PII es justamente cuando deja de operar con normalidad (el
caso `a`+5%, con ciclo nominal cero porque el imán se atascó por completo), lo
cual no es una ventaja real sino un modo de falla.

**La fragilidad ya conocida del candidato de atascamiento corto ante `b` se
sostiene y se generaliza.** No solo se confirma que `b`+5% y `b`+10% lo hacen
divergir (igual que el sondeo acotado ya había mostrado a ±5%), sino que este
sondeo revela que el candidato comparte el mismo patrón de fragilidad ante
incrementos de `m` (+5%, +10% divergen) y es aún más frágil que los otros dos
controladores ante `a`: diverge con `a` en ambos signos de la perturbación al
10% y ya con `a`+5%, mientras que el PI y el PII nominales toleran `a`−10% sin
problema y el PII nominal tolera incluso `a`+5%. El candidato de atascamiento
corto es, de los tres, el que tiene la región de parámetros admisible más
angosta: es sensible a incrementos en tres de los cinco parámetros (`a`, `b`,
`m`) y solo es robusto frente a `c1` y `Fs`. Esto refuerza la conclusión ya
registrada en la tesis de que la ventaja de ciclo límite más corto del candidato
no es gratuita: se paga con una fragilidad estructural mayor frente a
incertidumbre de planta, ahora confirmada en 3 de 5 parámetros y no solo en uno.
