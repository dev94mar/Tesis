#!/usr/bin/env python3
"""Actualiza grafo_tesis.json de la versión 1 (estado original de la tesis) a la 2
(después de las correcciones P1-P9 del 2026-10-02). Lee grafo_tesis_v1.json y escribe
grafo_tesis.json con las métricas recalculadas."""
import html
import json
import re
from pathlib import Path

import consultar as Q

AQUI = Path(__file__).parent
g = json.load(open(AQUI / "grafo_tesis_v1.json", encoding="utf-8"))
N = {n["id"]: n for n in g["nodos"]}
CTX = "icr/context/Tesis/"
CAL = "icr/calculus/Final_Bien/"


def texto_plano(h):
    h = re.sub(r"<(td|th)[^>]*>", " | ", h)
    h = re.sub(r"</(p|tr|li|div|table)>", "\n", h)
    h = re.sub(r"<[^>]+>", "", h)
    h = html.unescape(h)
    return re.sub(r"[ \t]+", " ", re.sub(r"\n\s*\n+", "\n", h)).strip()


def latex(h):
    out = re.findall(r"\\\[(.+?)\\\]", h, re.S) + re.findall(r"\\\((.+?)\\\)", h, re.S)
    return [re.sub(r"\s+", " ", x).strip() for x in out]


def nodo(id, tipo, etiqueta, h, **extra):
    """Crea o reemplaza un nodo conservando los campos que no se indiquen."""
    n = N.get(id, {"id": id})
    n.update({"tipo": tipo, "etiqueta": etiqueta, "texto": texto_plano(h), "contenido_html": h})
    lx = latex(h)
    if lx:
        n["latex"] = lx
    else:
        n.pop("latex", None)
    for k, v in extra.items():
        if v is None:
            n.pop(k, None)
        else:
            n[k] = v
    N[id] = n
    return n


def fig(id, etiqueta, png, original, h, estado=None):
    return nodo(id, "fig", etiqueta, h, figura={"png": "img/" + png, "original": original},
                fuente=original, estado=estado)


def tabla(filas, cab):
    th = "".join(f"<th>{c}</th>" for c in cab)
    tr = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in f) + "</tr>" for f in filas)
    return f'<div class="tbl"><table><tr>{th}</tr>{tr}</table></div>'


# ------------------------------------------------------------------ modelo
nodo("PAR", "mod", "Parámetros del ECP-730",
     tabla([["a", "7.17184 cm"], ["b", "1.6163×10⁻⁶ V/(N·cm⁴)"], ["c₁", "8.563 s⁻¹ (por unidad de masa)"],
            ["m", "0.141 kg"], ["g", "981 cm/s²"], ["F<sub>s</sub>", "20 kg·cm/s² (0.2 N)"],
            ["DV", "0.02 cm/s"], ["u", "[0, 3.5] V"]], ["", "Valor"])
     + "<p style='margin-top:10px'>Identificados por Alcántara para la configuración repulsiva. Tabla 8.1 de la tesis, corregida en P7: "
       "b y g tenían valores erróneos, c₁ las unidades de su tesis (kg⁻¹) y F<sub>s</sub> estaba en N.</p>",
     fuente=CTX + "chapters/chapter_1/sections/final.tex · tab:parametros")
nodo("LIN", "mod", "Modelo linealizado (x* = −4 cm)",
     r"<div class='math'>\[\dot x=\begin{bmatrix}0&1\\ \dfrac{4g}{a-x_1^*}&-c_1\end{bmatrix}x+\begin{bmatrix}0\\ \dfrac{1}{mb(a-x_1^*)^4}\end{bmatrix}u\]</div>"
     r"<p>Con \(c_1\) por unidad de masa (corregido en P7; antes el texto usaba \(c_2=c_1/m\), incompatible con los polos reportados). "
     r"Como \(a-x_1^*>0\) siempre, todos los equilibrios atractivos son inestables.</p>")
nodo("KARN", "mod", "Método de Karnopp",
     r"<p>Banda de velocidad \(|v|\le DV\) tratada como velocidad cero para decidir entre atascamiento y deslizamiento.</p>"
     + tabla([["DV", "0.02 cm/s"], ["F<sub>s</sub>", "20 kg·cm/s² (0.2 N, 14 % del peso)"]], ["Parámetro", "Valor"])
     + "<p style='margin-top:10px'>Implementado en <code>maglev_karnopp.m</code>, corregido en P1: la fuerza magnética se dividía dos veces entre m "
       "y la fricción viscosa no se oponía al movimiento con v &lt; 0. Tras la corrección, el jacobiano coincide con el modelo linealizado.</p>",
     fuente=CAL + "inestable/PII_inestable/maglev_karnopp.m")
nodo("LAZO", "mod", "Lazo de control con zona muerta",
     "<p>Referencia → error → PII → saturación [0, 3.5] V → zona muerta → planta no lineal con Karnopp → posición. "
     "ode45 por intervalo de 1 ms con voltaje retenido; controlador inicializado en su estado estacionario (arranque sin salto).</p>",
     fuente=CAL + "inestable/PII_inestable/regulacion_P4.m")
nodo("MEST", "mod", "Configuración estable (repulsiva)",
     r"<div class='math'>\[\dot x=\begin{bmatrix}0&1\\ -\dfrac{4g}{a+x_1^*}&-c_1\end{bmatrix}x+\begin{bmatrix}0\\ \dfrac{1}{mb(a+x_1^*)^4}\end{bmatrix}u\]</div>"
     r"<p>Fuerza \(u/[b(a+x)^4]\). Polos \(-4.28\pm21.49j\) en 1 cm y \(-4.28\pm20.24j\) en 2 cm: estable con amortiguamiento ≈ 0.2.</p>",
     fuente=CAL + "estable/linealization_estable.m")

# ------------------------------------------------------------------ cálculos
nodo("PIIS", "calc", "PII preliminar (PII.mat)",
     r"<div class='math'>\[C_{pre}(s)=\frac{186.11\,(s+6.395)(s+14.36)(s+1.861)}{s^2\,(s+400)}\]</div>"
     "<p>Versión previa del PII. Generó las figuras originales de regulación y seguimiento; desde P2 ya no la usa ningún script vigente. "
     "Es idéntica al controlador de <code>estable/PII_estable/CInestable.mat</code>.</p>",
     fuente=CAL + "inestable/PII_inestable/PII.mat", estado="Ya no se usa")
nodo("PI", "calc", "Controlador PI (comparación)",
     r"<div class='math'>\[C_{PI}(s)=\frac{178.14\,(s+15)(s+12.91)}{s\,(s+400)}\]</div>"
     + tabla([["Margen de fase", "64.1° @ 118.6 rad/s"], ["Sobrepaso lineal", "17.6 %"], ["t<sub>s</sub> lineal", "0.240 s"]], ["Medida", "Valor"])
     + "<p style='margin-top:10px'>Idéntico al de <code>estable/PI_estable/CInestable.mat</code>.</p>",
     fuente=CAL + "inestable/PI_inestable/PI.mat", verificacion="MATLAB")
nodo("VIA", "calc", "Rango viable con u ≤ 3.5 V",
     r"<p>Para despegar hacia la bobina hay que vencer la fricción estática: \(u\ge (mg+F_s)\,b\,(a-x)^4 = 1.145\,u_e\). "
     r"En −4 cm, \(u_e=3.48\) V pero hacen falta ≈ 3.99 V: el imán se sostiene pero no se mueve.</p>"
     + tabla([["−4.0", "solo se sostiene"], ["−3.5", "−3.6 a −2.0"], ["−3.0", "−3.5 a −1.5"], ["−2.0", "−3.3 a −0.5"], ["−1.0", "−2.5 a +0.5"]],
             ["Posición inicial [cm]", "Referencias alcanzables [cm]"])
     + "<p style='margin-top:10px'>Por eso las pruebas se hicieron en el intervalo de −3 a −2 cm.</p>",
     fuente=CAL + "verificacion_P1/barrido_3v5.py", verificacion="GPU (MLX) + MATLAB")
nodo("SWEEP", "calc", "Barridos de estabilidad en GPU",
     "<p>Lazo cerrado completo (planta, Karnopp, zona muerta, saturación) en GPU con MLX, validado contra ode45 en MATLAB.</p>"
     + tabla([["u<sub>max</sub> × referencia × controlador", "1 464", "30.7 s"], ["posición inicial × referencia × controlador (3.5 V)", "7 503", "35.9 s"]],
             ["Barrido", "Trayectorias", "Tiempo GPU"])
     + "<p style='margin-top:10px'>Con 5 V, el escalón −4 → −5 cm de la versión original diverge: a −5 cm el equilibrio pide 4.91 V. "
       "Con ≥ 8 V todo el rango probado es estable.</p>",
     fuente=CAL + "verificacion_P1/barrido_gpu.py", verificacion="GPU (MLX) + MATLAB")
nodo("LIN25", "calc", "PII en el intervalo de operación",
     tabla([["−4.0 (diseño)", "14.94", "59.9°", "16.9 %"], ["−3.0", "15.82", "54.5°", "19.2 %"], ["−2.5", "16.31", "51.1°", "21.6 %"], ["−2.0", "16.84", "47.4°", "24.7 %"]],
           ["x* [cm]", "Polo inestable", "Margen de fase", "Sobrepaso lineal"])
     + "<p style='margin-top:10px'>El PII diseñado en −4 cm sigue siendo estable donde se opera, con menos margen.</p>",
     verificacion="MATLAB")
nodo("BANDA", "calc", "Banda de atascamiento en lazo abierto",
     r"<p>Con el imán en reposo y \(u=u_e\), la fricción estática lo retiene mientras \(|u_e/[b(a-x)^4]-mg|\le F_s\).</p>"
     + tabla([["−4", "−4.44 a −3.63"], ["−3", "−3.41 a −2.66"], ["−2", "−2.37 a −1.70"]], ["Equilibrio [cm]", "Banda [cm]"])
     + "<p style='margin-top:10px'>La fricción estática enmascara la inestabilidad mientras el imán no se mueva.</p>",
     fuente=CAL + "evidencia_P8.m", verificacion="MATLAB")

# ------------------------------------------------------------------ simulaciones
nodo("LA", "sim", "Lazo abierto en los equilibrios",
     "<p>Modelo no lineal sin fricción estática, u = u<sub>e</sub> y perturbación inicial de 0.01 cm (fase 1b de la metodología).</p>"
     + tabla([["−4", "46 ms", "0.33 s"], ["−3", "44 ms", "0.32 s"], ["−2", "41 ms", "0.30 s"]], ["x* [cm]", "Duplicación", "Hasta 1 cm"])
     + "<p style='margin-top:10px'>El modelo lineal reproduce el crecimiento. Retrato de fase: punto silla.</p>",
     fuente=CAL + "evidencia_P8.m")
nodo("LINAD", "sim", "PII con AD sobre el modelo lineal",
     "<p>Modelo linealizado en −2.5 cm con zona muerta y Karnopp, escalón −2 → −3 cm (fase 2b de la metodología).</p>"
     + tabla([["Sobrepaso", "24.4 %", "23.6 %"], ["Banda ±5 %", "0.41 s", "0.40 s"], ["Ciclo límite", "0.028 cm", "0.033 cm"]],
             ["", "Lineal + AD", "No lineal + AD"])
     + "<p style='margin-top:10px'>El ciclo límite lo causan la zona muerta y la fricción estática, no la fuerza magnética.</p>",
     fuente=CAL + "evidencia_P8.m")
nodo("SINAD", "sim", "No lineal sin AD (OE3)",
     r"<p>Planta \(m\ddot x = u/(b(a-x)^4) - mg - mc_1\dot x\), sin Karnopp ni zona muerta. Escalón −2 → −3 cm, u ∈ [0, 3.5] V.</p>"
     + tabla([["Sobrepaso", "23.7 %"], ["Banda ±2 %", "0.48 s"], ["Error final", "1.8×10⁻¹⁵ cm"], ["u final", "2.3934 V = u<sub>e</sub>(−3)"]], ["Medida", "Valor"])
     + "<p style='margin-top:10px'>El sobrepaso cae entre lo que predice el modelo lineal en −3 y −2 cm (19.2–24.7 %).</p>",
     fuente=CAL + "inestable/PII_inestable/regulacion_sinAD_P3.m")
nodo("REG", "sim", "Regulación con AD (OE4)",
     "<p>PII de la tesis + zona muerta + Karnopp, escalón −2 → −3 cm en t = 10 s, u ∈ [0, 3.5] V, 40 s.</p>"
     + tabla([["Sobrepaso", "23.6 %"], ["Banda ±0.05 cm", "0.40 s"], ["Ciclo límite", "0.033 cm pico a pico"], ["Tiempo atascado", "74 %"],
              ["u máximo", "3.28 V, sin saturar"]], ["Medida", "Valor"]),
     fuente=CAL + "inestable/PII_inestable/regulacion_P4.m", estado=None)
nodo("SIN", "sim", "Seguimiento senoidal",
     r"<p>\(r(t)=-2.5+0.5\sin(2\pi\cdot0.001\,t)\), 2000 s.</p>"
     + tabla([["Error máx / eficaz", "0.0198 / 0.0124 cm"], ["Tiempo atascado", "75 %"], ["Rupturas", "4072 (~2/s)"], ["u", "1.33–2.78 V"]], ["Medida", "Valor"])
     + "<p style='margin-top:10px'>Ciclo límite continuo, no solo en las inversiones de la referencia.</p>",
     fuente=CAL + "inestable/PII_inestable/seguimiento_P5.m", estado=None)
nodo("TRAP", "sim", "Seguimiento trapezoidal",
     "<p>Planos en −2 y −3 cm, rampas de 250 s (0.004 cm/s), periodo 1250 s, 2500 s.</p>"
     + tabla([["Error máx / eficaz", "0.0223 / 0.0114 cm"], ["Tiempo atascado", "78 %"], ["Rupturas", "4400"], ["u", "1.32–2.78 V"]], ["Medida", "Valor"])
     + "<p style='margin-top:10px'>Al inicio de la primera rampa el imán queda atascado ~1 s; después, escalones de atascamiento-deslizamiento.</p>",
     fuente=CAL + "inestable/PII_inestable/seguimiento_P5.m", estado=None)
nodo("CMP", "sim", "Comparación PI vs PII",
     tabla([["Sobrepaso (escalón)", "25.9 %", "23.6 %"], ["Ciclo límite", "0.031 cm", "0.033 cm"], ["Atascamiento medio (escalón)", "0.26 s", "0.36 s"],
            ["Atascamiento medio (trapezoidal)", "0.29 s", "0.39 s"], ["Atascamiento máximo (trapezoidal)", "1.07 s", "3.13 s"],
            ["Error medio en rampa", "−3×10⁻⁵ cm", "1×10⁻⁵ cm"]], ["", "PI", "PII"])
     + "<p style='margin-top:10px'>Mismas condiciones: zona muerta, Karnopp, u ∈ [0, 3.5] V. Tabla <code>tab:pi_pii</code> de la tesis.</p>",
     fuente=CAL + "inestable/comparar_PI_PII_P6.m", estado=None)
nodo("EST", "sim", "Regulación en configuración estable",
     "<p>Escalón 1 → 2 cm con zona muerta, Karnopp y u ∈ [0, 3.5] V.</p>"
     + tabla([["Margen de fase", "50.7°", "51.0°", "43.3°"], ["Sobrepaso con AD", "10.5 %", "11.1 %", "9.8 %"], ["Banda ±5 %", "0.24 s", "0.36 s", "0.35 s"],
              ["Ciclo límite", "0.018 cm", "0.023 cm", "0.020 cm"]], ["", "PI", "PII prelim.", "PII tesis"]),
     fuente=CAL + "evidencia_P8.m")

# ------------------------------------------------------------------ figuras
TK = CTX + "images/"
F = [
    ("F_BODE", "Fig. Bode (TikZ)", "diseno_bode.png", "pii_design/tikz/bode.tex", "Magnitud y fase de L(s) = C(s)G(s) en −4 cm, con MG = −17.1 dB y MF = 59.9°."),
    ("F_NYQ", "Fig. Nyquist (TikZ)", "diseno_nyquist.png", "pii_design/tikz/nyquist.tex", "Nyquist real de L(s): rodeo antihorario a −1 (P = 1). La figura original era un lugar de las raíces."),
    ("F_STEP", "Fig. Respuesta escalón (TikZ)", "diseno_escalon.png", "pii_design/tikz/escalon.tex", "Lazo cerrado lineal: 16.9 % de sobrepaso y t<sub>s</sub> = 0.284 s."),
    ("F_POS", "Fig. Posición (regulación)", "reg_posicion.png", "regulation_results/tikz/posicion.tex", "Escalón −2 → −3 cm con detalle del transitorio y del ciclo límite."),
    ("F_VEL", "Fig. Velocidad (regulación)", "reg_velocidad.png", "regulation_results/tikz/velocidad.tex", "Tramos en cero: atascamiento."),
    ("F_ERR", "Fig. Error (regulación)", "reg_error.png", "regulation_results/tikz/error.tex", "Error e = r − x₁."),
    ("F_U", "Fig. Señal de control (regulación)", "reg_control.png", "regulation_results/tikz/control.tex", "Antes y después de la zona muerta; nunca alcanza 3.5 V."),
    ("F_SINAD_POS", "Fig. Posición sin/con AD", "sinad_posicion.png", "sin_ad_results/tikz/posicion.tex", "Transitorios prácticamente idénticos."),
    ("F_SINAD_VEL", "Fig. Velocidad sin/con AD", "sinad_velocidad.png", "sin_ad_results/tikz/velocidad.tex", "Velocidad sin y con atascamiento-deslizamiento."),
    ("F_SINAD_ERR", "Fig. Error sin/con AD", "sinad_error.png", "sin_ad_results/tikz/error.tex", "Sin AD el error converge a cero; con AD queda el ciclo límite."),
    ("F_SINAD_U", "Fig. Control sin/con AD", "sinad_control.png", "sin_ad_results/tikz/control.tex", "Sin AD converge a u<sub>e</sub> = 2.3934 V."),
    ("F_SEN_POS", "Fig. Posición (senoidal)", "seg_sen_posicion.png", "seguimiento_results/tikz/sen_posicion.tex", "Vista completa y detalle de 244 a 256 s."),
    ("F_SEN_VEL", "Fig. Velocidad (senoidal)", "seg_sen_velocidad.png", "seguimiento_results/tikz/sen_velocidad.tex", "Pulsos de deslizamiento continuos."),
    ("F_SEN_ERR", "Fig. Error (senoidal)", "seg_sen_error.png", "seguimiento_results/tikz/sen_error.tex", "Banda de ±0.02 cm sin picos aislados."),
    ("F_SEN_U", "Fig. Control (senoidal)", "seg_sen_control.png", "seguimiento_results/tikz/sen_control.tex", "Diente de sierra de la acción integral."),
    ("F_TRAP_POS", "Fig. Posición (trapezoidal)", "seg_trap_posicion.png", "seguimiento_results/tikz/trap_posicion.tex", "Detalle del inicio de la primera rampa."),
    ("F_TRAP_VEL", "Fig. Velocidad (trapezoidal)", "seg_trap_velocidad.png", "seguimiento_results/tikz/trap_velocidad.tex", "Reposo en el primer plano; ciclo límite después."),
    ("F_TRAP_ERR", "Fig. Error (trapezoidal)", "seg_trap_error.png", "seguimiento_results/tikz/trap_error.tex", "Banda de ±0.022 cm en rampas y planos."),
    ("F_TRAP_U", "Fig. Control (trapezoidal)", "seg_trap_control.png", "seguimiento_results/tikz/trap_control.tex", "Sigue el perfil trapezoidal sin saturar."),
    ("F_LA", "Fig. Lazo abierto", "p8_lazo_abierto.png", "p8_results/tikz/lazo_abierto.tex", "|x₁ − x*| en escala logarítmica: no lineal frente a lineal."),
    ("F_RET", "Fig. Retrato de fase", "p8_retrato_fase.png", "p8_results/tikz/retrato_fase.tex", "Punto silla en −4 cm, variedad inestable y banda de atascamiento."),
    ("F_LINAD", "Fig. Lineal vs no lineal con AD", "p8_lineal_ad.png", "p8_results/tikz/lineal_ad.tex", "Respuestas casi idénticas."),
    ("F_EST", "Fig. Configuración estable", "p8_estable.png", "p8_results/tikz/estable.tex", "Escalón 1 → 2 cm con el PI y el PII de la tesis."),
]
for fid, lab, png, orig, txt in F:
    fig(fid, lab, png, TK + orig, f"<p>{txt}</p>")
fig("F_MAPA", "Fig. Mapa de estabilidad (P1)", "p1_mapa_estabilidad.png", CAL + "verificacion_P1/mapa_estabilidad.png",
    "<p>Escalón desde −4 cm: región estable según u<sub>max</sub> y la referencia final, para los tres controladores.</p>", estado="Verificación, no está en la tesis")
fig("F_ESC35", "Fig. Escalón −2 → −3 cm con 3.5 V (P1)", "p1_escalon_3v5.png", CAL + "verificacion_P1/escalon_3v5.png",
    "<p>Validación en MATLAB del escalón elegido para P4.</p>", estado="Verificación, no está en la tesis")
for fid in ("F_PH", "F_PHL"):
    N[fid]["estado"] = "No incluida (reemplazada por el retrato de fase de P8)"

# ------------------------------------------------------------------ conclusiones y trabajo futuro
K = {
    "K1": ("El PII estabiliza el SLM inestable con AD", "En regulación y en los dos seguimientos, sin compensar explícitamente la zona muerta ni la fricción estática."),
    "K2": ("Error medio nulo con ciclo límite", "Sin AD el error converge a cero; con AD queda un ciclo límite de ~0.03 cm con error medio prácticamente nulo."),
    "K3": ("Control implementable en [0, 3.5] V", "La señal de control nunca supera 3.3 V en las pruebas con el PII."),
    "K4": ("No confirma la hipótesis de Pérez-Gómez", "La amplitud del ciclo límite con el PII es similar a la del PI: la doble acción integral no la reduce."),
    "K5": ("Extiende a Alcántara a la configuración atractiva", "Un controlador lineal sin conmutación basta para estabilizar la configuración inestable con AD, a costa de un ciclo límite pequeño."),
    "K6": ("El actuador limita el rango de operación", "Con 3.5 V, en −4 cm el imán se sostiene pero no se mueve; los cambios de referencia son viables desde ≈ −3.6 cm."),
    "K7": ("El ciclo límite viene de la ZM y la fricción", "El modelo lineal con AD reproduce el mismo ciclo límite: no lo causa la no linealidad de la fuerza magnética."),
    "K8": ("El mismo PII estabiliza la configuración estable", "Margen de fase de 43.3° y 9.8 % de sobrepaso con AD en el escalón de 1 a 2 cm."),
    "K9": ("La doble acción integral no mejora al PI", "Reduce algo el sobrepaso, pero alarga los atascamientos; el error en rampa no se distingue con 0.004 cm/s."),
    "K10": ("La fricción estática enmascara la inestabilidad", "En reposo con u = u<sub>e</sub>, el imán queda retenido en una banda de ~0.8 cm alrededor de cada equilibrio."),
}
for kid, (lab, txt) in K.items():
    nodo(kid, "conc", lab, f"<p>{txt}</p>", fuente=CTX + "chapters/chapter_1/sections/conclusiones.tex")
nodo("W6", "fut", "Ganancia programada", "<p>Ajustar el PII según el punto de operación en x* ∈ [−3.6, −0.5] cm, el intervalo viable con 3.5 V.</p>")
nodo("W9", "fut", "Ajuste del PII frente al ciclo límite",
     "<p>Barrido de ceros y ganancia del PII, rampas de mayor pendiente y rediseño en −2.5 cm, donde el margen de fase baja a 51°.</p>")

# ------------------------------------------------------------------ revisiones
RES = {
    "R1": ("P2", "Todas las figuras usan PII_lic.mat; los scripts que cargaban PII.mat están archivados."),
    "R2": ("P4", "Regulación regenerada con un único escalón −2 → −3 cm, coherente entre texto, figura y script."),
    "R3": ("P1", "maglev_karnopp.m corregido; jacobiano idéntico al modelo linealizado."),
    "R4": ("P7", "Tabla 8.1 corregida (b, g, unidades de c₁, F<sub>s</sub>, DV, u)."),
    "R5": ("P5", "Referencia senoidal redefinida en −2.5 ± 0.5 cm, igual en texto y script."),
    "R6": ("P5", "Las 8 figuras de seguimiento existen en TikZ y el texto describe los resultados reales."),
    "R7": ("P9", "\\cite{el} para El Hajjaji y \\cite{charara} en lugar de la clave duplicada ali."),
    "R8": ("P9", "[ci] sustituido por \\cite{armstrong,olsson,berman}; F<sub>c</sub> y F<sub>v</sub> eliminadas."),
}
for rid, (p, txt) in RES.items():
    N[rid].update(estado="resuelta", resuelta_en=p, resolucion=txt)
NUEVAS = [
    ("R9", "alta", "resuelta", "P6", "Conclusiones con 6 objetivos", "Las conclusiones numeraban 6 objetivos específicos; objetivos.tex tiene 4.", "Conclusiones reescritas con los 4 objetivos."),
    ("R10", "alta", "resuelta", "P3", "OE3 sin evidencia", "No había ninguna simulación no lineal sin AD en la tesis.", "Subsección 8.6.4 con 4 figuras TikZ."),
    ("R11", "media", "resuelta", "P8", "Fases 1b y 2b sin evidencia", "La metodología prometía simular el lazo abierto y el controlador con AD en el modelo lineal.", "Subsecciones 8.6.1 y 8.6.3."),
    ("R12", "media", "resuelta", "P8", "Configuración estable ausente", "El resumen decía que se diseñaron controladores para ambas configuraciones.", "Subsección 8.6.7; resumen y abstract ajustados."),
    ("R13", "alta", "resuelta", "P5", "El \"Nyquist\" era un lugar de las raíces", "La figura titulada Diagrama de Nyquist era un Root Locus Editor ampliado.", "Nyquist real de L(s) en TikZ."),
    ("R14", "media", "resuelta", "P7", "c₂ = c₁/m y Fₛ en N", "Con c₂ = c₁/m los polos no coincidían; F<sub>s</sub> = 20 \"N\" sería 14 veces el peso.", "Modelo con c₁ por unidad de masa y F<sub>s</sub> en kg·cm/s²."),
    ("R15", "alta", "abierta", None, "La doble acción integral no supera al PI", "La comparación de P6 no confirma la motivación del PII. Discutir con los directores si es cuestión de sintonización.", None),
    ("R16", "media", "abierta", None, "Biber no funciona", "La bibliografía no se genera: las citas salen como claves. Actualizar biber (tlmgr update biber).", None),
    ("R17", "baja", "abierta", None, "Memoria de pdflatex al 82 %", "Con más figuras con datos conviene compilar con lualatex.", None),
    ("R18", "baja", "abierta", None, "Cita de suspensión activa", "Verificar que Charara et al. sostiene la frase sobre suspensión activa de la introducción.", None),
]
for rid, prio, est, p, lab, txt, res in NUEVAS:
    nodo(rid, "rev", lab, f"<p>{txt}</p>" + (f"<p><b>Resolución:</b> {res}</p>" if res else ""),
         prioridad=prio, estado=est, resuelta_en=p, resolucion=res)
for rid, (p, txt) in RES.items():
    n = N[rid]
    if "Resolución" not in n["contenido_html"]:
        nodo(rid, "rev", n["etiqueta"], n["contenido_html"] + f"<p><b>Resolución ({p}):</b> {txt}</p>")

# ------------------------------------------------------------------ referencias
for k in ("gregory", "ali"):
    N.pop("ref:" + k, None)
    g["bibliografia"].pop(k, None)
g["bibliografia"].update({   # entradas de referencias.bib citadas a partir de P9
    "el": {"autores": "A. El Hajjaji, M. Ouladsine", "anio": 2001, "titulo": "Modeling and nonlinear control of magnetic levitation systems"},
    "armstrong": {"autores": "B. Armstrong-Hélouvry", "anio": 1993, "titulo": "Stick slip and control in low-speed motion"},
    "olsson": {"autores": "H. Olsson, K. J. Åström, C. Canudas de Wit, M. Gäfvert, P. Lischinsky", "anio": 1998, "titulo": "Friction models and friction compensation"},
    "berman": {"autores": "A. D. Berman, W. A. Ducker, J. N. Israelachvili", "anio": 1996, "titulo": "Origin and characterization of different stick-slip friction mechanisms"},
})
for k in ("el", "armstrong", "olsson", "berman"):
    b = g["bibliografia"][k]; a, y, t = b["autores"], b["anio"], b["titulo"]
    nodo("ref:" + k, "ref", f"{a.split(',')[0].split()[-1]} ({y})", f"<p><b>{t}</b></p><p>{a}, {y}.</p>",
         referencia={"clave": k, "autores": a, "anio": y, "titulo": t}, fuente=CTX + "bibliography/referencias.bib · " + k)

# ------------------------------------------------------------------ aristas
quitar = {("OE3", "REG"), ("PIIS", "REG"), ("PIIS", "SIN"), ("PIIS", "SIN"), ("PIIS", "TRAP"), ("K1", "K4"), ("R3", "UEQ")}
aristas = [(a["origen"], a["destino"]) for a in g["aristas"]
           if a["origen"] in N and a["destino"] in N and (a["origen"], a["destino"]) not in quitar]
nuevas = [
    ("OE1", "LA"), ("LA", "F_LA"), ("LA", "F_RET"), ("BANDA", "F_RET"), ("KARN", "BANDA"), ("UEQ", "BANDA"), ("LA", "K10"), ("BANDA", "K10"),
    ("OE2", "LINAD"), ("LIN", "LINAD"), ("ZM", "LINAD"), ("KARN", "LINAD"), ("PII", "LINAD"), ("LINAD", "F_LINAD"), ("LINAD", "K7"),
    ("OE3", "SINAD"), ("FFLD", "SINAD"), ("PII", "SINAD"), ("SINAD", "F_SINAD_POS"), ("SINAD", "F_SINAD_VEL"), ("SINAD", "F_SINAD_ERR"),
    ("SINAD", "F_SINAD_U"), ("SINAD", "K2"), ("SINAD", "K7"), ("PII", "REG"), ("PII", "SIN"), ("PII", "TRAP"),
    ("SIN", "F_SEN_POS"), ("SIN", "F_SEN_VEL"), ("SIN", "F_SEN_ERR"), ("SIN", "F_SEN_U"),
    ("TRAP", "F_TRAP_POS"), ("TRAP", "F_TRAP_VEL"), ("TRAP", "F_TRAP_ERR"), ("TRAP", "F_TRAP_U"), ("SIN", "K1"), ("TRAP", "K1"), ("SIN", "K3"),
    ("KARN", "VIA"), ("UEQ", "VIA"), ("SWEEP", "VIA"), ("SWEEP", "F_MAPA"), ("SWEEP", "F_ESC35"), ("VIA", "K6"), ("VIA", "REG"),
    ("LIN", "LIN25"), ("PII", "LIN25"), ("LIN25", "W9"), ("BAR", "LIN25"),
    ("MEC", "MEST"), ("MEST", "EST"), ("PI", "EST"), ("PII", "EST"), ("PIIS", "EST"), ("EST", "F_EST"), ("EST", "K8"), ("T", "EST"),
    ("PI", "CMP"), ("CMP", "K9"), ("CMP", "K4"), ("CMP", "W9"), ("K9", "W9"), ("VIA", "W6"),
    ("ref:el", "FALT"), ("ref:armstrong", "FRIC"), ("ref:olsson", "FRIC"), ("ref:berman", "FRIC"),
    ("R9", "K1"), ("R10", "OE3"), ("R10", "SINAD"), ("R11", "LA"), ("R11", "LINAD"), ("R12", "EST"), ("R12", "MEST"), ("R13", "F_NYQ"),
    ("R14", "LIN"), ("R14", "KARN"), ("R14", "PAR"), ("R15", "K9"), ("R15", "K4"), ("R15", "CMP"), ("R16", "T"), ("R17", "T"), ("R18", "ref:charara"),
    ("R3", "SWEEP"),
]
vistos, final = set(), []
for a in aristas + nuevas:
    assert a[0] in N and a[1] in N, a
    if a not in vistos:
        vistos.add(a); final.append(a)

REL = {
    ("tesis", "obj"): "tiene_objetivo", ("obj", "obj"): "se_desglosa_en", ("tesis", "mod"): "se_enmarca_en",
    ("obj", "mod"): "se_aborda_con", ("mod", "mod"): "deriva_en", ("mod", "fig"): "se_ilustra_en",
    ("mod", "calc"): "produce", ("calc", "mod"): "parametriza", ("calc", "fig"): "se_visualiza_en",
    ("obj", "calc"): "se_cumple_con", ("calc", "calc"): "deriva_en", ("calc", "sim"): "se_usa_en",
    ("mod", "sim"): "se_usa_en", ("obj", "sim"): "se_valida_con", ("sim", "fig"): "genera",
    ("sim", "conc"): "sustenta", ("calc", "conc"): "sustenta", ("fig", "conc"): "sustenta", ("mod", "conc"): "sustenta",
    ("conc", "conc"): "implica", ("tesis", "conc"): "concluye", ("conc", "fut"): "motiva", ("mod", "fut"): "motiva",
    ("calc", "fut"): "motiva", ("sim", "fut"): "motiva", ("fig", "calc"): "sustenta", ("tesis", "sim"): "incluye",
}
T = {k: n["tipo"] for k, n in N.items()}


def rel(s, t):
    if T[s] == "rev":
        return "afecta_a"
    if T[s] == "ref":
        return "citada_en"
    return REL.get((T[s], T[t]), "relacionado_con")


g["aristas"] = [{"id": f"e{i:03d}", "origen": s, "destino": t, "relacion": rel(s, t)} for i, (s, t) in enumerate(final, 1)]
g["relaciones"]["incluye"] = "la tesis incluye esa simulación como evidencia complementaria"
orden = list(dict.fromkeys([n["id"] for n in g["nodos"]] + list(N)))
g["nodos"] = [N[i] for i in orden if i in N]
g["bibliografia"] = {k: v for k, v in g["bibliografia"].items()}
g["meta"].update(version=2, generado="2026-10-02",
                 descripcion=g["meta"]["descripcion"] + " Las revisiones tienen estado (resuelta/abierta) y, si están resueltas, la prioridad (P1-P9) que las resolvió.")
g["meta"]["historial"] = [
    {"version": 1, "fecha": "2026-10-02", "cambio": "Grafo inicial a partir de la tesis original y los scripts de MATLAB."},
    {"version": 2, "fecha": "2026-10-02", "cambio": "Correcciones P1-P9: simulador corregido, límite de 3.5 V, nuevas simulaciones (OE3, fases 1b y 2b, "
     "configuración estable, PI vs PII), figuras TikZ, conclusiones reescritas y 18 revisiones (14 resueltas, 4 abiertas)."},
]
Q.medir(g)
Q.guardar(g, AQUI / "grafo_tesis.json")
m = g["metricas_globales"]
print(f'{m["nodos"]} nodos, {m["aristas"]} aristas, diámetro {m["diametro"]}, componentes {m["componentes_conexas"]}')
print("relaciones sin tipo:", sum(1 for a in g["aristas"] if a["relacion"] == "relacionado_con"))
print("nodos aislados:", [n["id"] for n in g["nodos"] if n["metricas"]["grado"] == 0])
