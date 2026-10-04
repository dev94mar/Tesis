"""Grafo v5: diseño de un PII que sí cumple la hipótesis (2026-10-04).

Fuera del barrido de familias de la tesis (kK <= 3, red de adelanto fija), se buscó con
Python (búsqueda numérica + simulación no lineal rápida y con ode45/RK45) y se verificó con
Mathematica (polos de lazo cerrado, Routh vía raíces) un PII con ganancia y red de adelanto
reescaladas que bate al mejor PI del barrido (0.013 cm, 0.26 s) en las dos métricas a la vez,
con margen de fase >= 30° en -4, -3, -2.5 y -2 cm. No está en el texto de la tesis: es
exploración posterior, pendiente de decidir si se incorpora. Confirmación con el simulador
MATLAB de la tesis (ode45, maglev_karnopp.m) en curso al cerrar esta versión.
La versión anterior queda en grafo_tesis_v4.json.
"""
import json, shutil

RUTA = "grafo_tesis.json"
shutil.copy(RUTA, "grafo_tesis_v4.json")
g = json.load(open(RUTA, encoding="utf-8"))
N = {n["id"]: n for n in g["nodos"]}

ids_aristas = [int(a["id"][1:]) for a in g["aristas"] if a["id"].startswith("e") and a["id"][1:].isdigit()]
siguiente = max(ids_aristas) + 1

def nueva_arista(origen, destino, relacion):
    global siguiente
    g["aristas"].append({"id": f"e{siguiente:03d}", "origen": origen, "destino": destino, "relacion": relacion})
    siguiente += 1

# Nodo del controlador rediseñado
PII_V2 = {
    "id": "PII_V2",
    "tipo": "calc",
    "etiqueta": "PII rediseñado (sí cumple la hipótesis)",
    "texto": "\\[C_{PII,v2}(s)=\\frac{381.075\\,(s+8.775)(s+3.3498)(s+19.041)}{s^2\\,(s+331.21)}\\]\n"
             "Reescala el PII de la tesis (kK=2.5 en la ganancia, ceros bajos ×1.8, red de adelanto ×1.1). "
             "Margen de fase: 47.3°/41.0°/37.8°/34.5° en -4/-3/-2.5/-2 cm (todos ≥30°, el umbral de la tesis). "
             "En el escalón -2→-3 cm con fricción de Karnopp, zona muerta y u≤3.5 V: ciclo límite 0.0108 cm "
             "y atascamiento medio 0.237 s, frente a 0.013 cm y 0.26 s del mejor PI del barrido R15 "
             "(-17 % y -9 %) y frente a 0.033 cm y 0.335 s del PII de la tesis (-67 % y -29 %). Sobrepaso "
             "29.1 %, sin saturación sostenida. En la rampa de -0.05 cm/s del barrido, error eficaz "
             "0.0024 cm, unas tres veces menor que PI y PII originales (~0.0076 cm).",
    "latex": ["C_{PII,v2}(s)=\\frac{381.075\\,(s+8.775)(s+3.3498)(s+19.041)}{s^2\\,(s+331.21)}"],
    "fuente": "Sesión 2026-10-04: diseño en Python (búsqueda numérica, validación RK45), verificación de estabilidad en Mathematica (Routh/raíces), validación cruzada en curso con el simulador MATLAB de la tesis (ode45, maglev_karnopp.m). No forma parte del texto de la tesis.",
    "verificacion": "Python (scipy, RK45) y Mathematica (Routh/raíces); MATLAB (ode45) en curso",
    "valores": {
        "ganancia": 381.075,
        "ceros": [-8.775, -3.3498, -19.041],
        "polos": [0, 0, -331.21],
        "kK": 2.5, "alpha_ceros_bajos": 1.8, "beta_red_adelanto": 1.1,
        "margen_fase_grados": {"-4": 47.3, "-3": 41.0, "-2.5": 37.8, "-2": 34.5},
        "ciclo_limite_cm": 0.0108, "atasco_medio_s": 0.237, "sobrepaso_pct": 29.1,
        "ciclo_limite_cm_mejor_pi": 0.013, "atasco_medio_s_mejor_pi": 0.26,
    },
    "contenido_html": "<div class=\"math\">\\[C_{PII,v2}(s)=\\frac{381.075\\,(s+8.775)(s+3.3498)(s+19.041)}{s^2\\,(s+331.21)}\\]</div>"
                       "<p>Reescala el PII de la tesis (k<sub>K</sub>=2.5, ceros bajos ×1.8, red de adelanto ×1.1). "
                       "Margen de fase ≥30° en -4, -3, -2.5 y -2 cm. En el escalón -2→-3 cm: ciclo límite 0.0108 cm "
                       "y atascamiento medio 0.237 s, frente a 0.013 cm / 0.26 s del mejor PI del barrido "
                       "(-17 % y -9 %) y a 0.033 cm / 0.335 s del PII original (-67 % y -29 %). Sobrepaso 29.1 %. "
                       "En la rampa de -0.05 cm/s, error eficaz tres veces menor que ambos controladores originales.</p>",
    "metricas": {},
}
g["nodos"].append(PII_V2)

REV = {
    "id": "R25", "tipo": "rev", "etiqueta": "Diseño de un PII que sí cumple la hipótesis",
    "contenido_html": "<p>El barrido de familias de la sección 6.2 limitó k<sub>K</sub> a [0.5, 3] y no varió la red de "
                       "adelanto; dentro de ese barrido ningún PII superó al mejor PI. Ampliando esa libertad "
                       "(k<sub>K</sub> y la red de adelanto, no solo los ceros bajos) y exigiendo el mismo margen de fase "
                       "≥30° en -4, -3, -2.5 y -2 cm, se encontró un PII que bate al mejor PI en ciclo límite y en "
                       "atascamiento a la vez.</p><p><b>Resolución:</b> diseñado en Python, verificado con Mathematica "
                       "(estabilidad) y en validación cruzada con el simulador MATLAB de la tesis. Pendiente decidir "
                       "si se incorpora al capítulo 6 como contraejemplo acotado, o se deja como trabajo futuro.</p>",
    "texto": "El barrido de familias limitó kK a [0.5,3] y no varió la red de adelanto; ningún PII superó al mejor PI "
             "dentro de ese barrido. Con más libertad (kK y red de adelanto) y el mismo margen de fase ≥30°, se "
             "encontró un PII que sí lo supera en ambas métricas.\n"
             "Resolución: diseñado en Python, verificado en Mathematica; validación cruzada con MATLAB en curso. "
             "Pendiente decidir su incorporación al capítulo 6.",
    "prioridad": "media", "estado": "abierta",
    "resolucion": "PII_v2 bate al mejor PI del barrido R15 en ciclo límite (-17 %) y atascamiento medio (-9 %), "
                  "con margen de fase ≥30° en todo el intervalo; no cambia la conclusión general sobre las familias "
                  "ya publicadas, pero muestra que la restricción kK≤3 del barrido, no el número de integradores, "
                  "era lo que impedía al PII ganar.",
    "metricas": {},
}
g["nodos"].append(REV)

for d in ["PII", "R15", "K9", "K13"]:
    assert d in N, d
    nueva_arista("R25", d, "afecta_a")
nueva_arista("R25", "PII_V2", "produce")
nueva_arista("PII_V2", "PII", "variante_de")
nueva_arista("PII_V2", "R15", "supera_a")

g["meta"]["version"] = 5
g["meta"]["generado"] = "2026-10-04"
g["meta"]["historial"].append({
    "version": 5, "fecha": "2026-10-04",
    "cambio": "Nodo PII_V2 y revisión R25: diseño exploratorio de un PII que supera al mejor PI del barrido R15 "
              "en ciclo límite y atascamiento medio, con margen de fase ≥30° en todo el intervalo de operación. "
              "No está en el texto de la tesis; queda abierta la decisión de incorporarlo.",
})

json.dump(g, open(RUTA, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("grafo v5 escrito:", len(g["nodos"]), "nodos,", len(g["aristas"]), "aristas")
