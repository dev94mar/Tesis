"""Grafo v3: reestructuración integrada de la tesis (2026-10-02).

Actualiza las fuentes de los nodos a la nueva estructura `capitulos/`, corrige
números de capítulo y tabla, y registra tres revisiones resueltas: identidad
v5 «UAM Dato», reglas de escritura matemática y reestructuración integrada.
La versión anterior queda en grafo_tesis_v2.json.
"""
import json, re

RUTA = "grafo_tesis.json"
CAP = "icr/context/Tesis/capitulos/"
g = json.load(open(RUTA, encoding="utf-8"))
N = {n["id"]: n for n in g["nodos"]}

FUENTES = {
    **{k: CAP + "01_introduccion.tex · sec:objetivos" for k in ("OG", "OE1", "OE2", "OE3", "OE4")},
    "ANT": CAP + "01_introduccion.tex · sec:motivacion",
    "APP": CAP + "01_introduccion.tex · Contexto del problema",
    "SOA": CAP + "01_introduccion.tex · Revisión bibliográfica",
    "HIP": CAP + "01_introduccion.tex · Formulación del problema",
    "MARCO": CAP + "02_fundamentos.tex · chap:fundamentos",
    "MEC": CAP + "03_modelo.tex · sec:ec_movimiento",
    "FFLD": CAP + "03_modelo.tex · sec:fuerza",
    "FALT": CAP + "03_modelo.tex · sec:fuerza",
    "FRIC": CAP + "03_modelo.tex · sec:friccion_modelo",
    "ZM": CAP + "03_modelo.tex · sec:zm_modelo",
    "PAR": CAP + "03_modelo.tex · tab:parametros",
    "VIA": CAP + "05_desempeno.tex · sec:intervalo (tab:intervalo); análisis estático en 03_modelo.tex · sec:actuador_estatico",
    "BANDAV": CAP + "06_doble_integral.tex · sec:analisis_ciclo",
    "K11": CAP + "06_doble_integral.tex · sec:analisis_ciclo",
    "K12": CAP + "06_doble_integral.tex · sec:analisis_ciclo",
    "KV": CAP + "06_doble_integral.tex · sec:ventaja_rampa",
    **{k: CAP + "07_conclusiones.tex · sec:conclusiones"
       for k in ("K1", "K2", "K3", "K4", "K5", "K6", "K7", "K8", "K9", "K10", "K13")},
}
for k, f in FUENTES.items():
    N[k]["fuente"] = f

def reemplazar(nid, viejo, nuevo):
    n = N[nid]
    for campo in ("texto", "contenido_html"):
        assert viejo in n[campo], (nid, campo, viejo)
        n[campo] = n[campo].replace(viejo, nuevo)

reemplazar("PAR", "Tabla 8.1 de la tesis", "Tabla 3.1 de la tesis")
reemplazar("MARCO", "Capítulo 6:", "Capítulo 2 (antes «Marco teórico»):")
N["MARCO"]["etiqueta"] = "Fundamentos teóricos"
N["APA"]["etiqueta"] = N["APA"]["etiqueta"].replace("Apéndice A", "Anexo A")
N["APB"]["etiqueta"] = N["APB"]["etiqueta"].replace("Apéndice B", "Anexo B")

REVS = [
    ("R21", "Identidad gráfica v5 «UAM Dato»", "baja",
     "El documento usaba una identidad UAM anterior y los capítulos se encadenaban en la misma página.",
     "Plantilla v5 «UAM Dato» adaptada a la clase book (preamble/uamdato.tex): kicker, chip y filete por capítulo, cabecera y pie con emblema, portada nueva sin el logotipo de la CBI; cada capítulo abre página nueva.",
     "Formato v5 aplicado.", ["T"]),
    ("R22", "Reglas de escritura matemática", "media",
     "Había ecuaciones desplegadas sin número ni puntuación, listas «donde…» tras las ecuaciones, siglas sin definir, citas sin espacio irrompible y un choque de notación (b₀).",
     "Revisión contra ~/.claude/reglas/escritura_matematica.md: todas las ecuaciones numeradas, con etiqueta y puntuación; símbolos explicados en prosa; siglas definidas en su primer uso; ~\\cite; b₀ de la planta renombrado β; f_fric unificado como f_fr.",
     "Reglas aplicadas en todo el documento.", ["MEC", "FFLD", "FALT", "ZM", "FRIC", "LIN", "CO"]),
    ("R23", "Reestructuración integrada", "alta",
     "La estructura heredada repetía contenido entre la introducción, los antecedentes, el planteamiento, los objetivos y la metodología; las conclusiones ocupaban el 8 % del documento.",
     "Siete capítulos con un dueño por tema (capitulos/01–07): introducción (10 % del documento) con antecedentes, hipótesis, objetivos y metodología; fundamentos; modelo; diseño del controlador; desempeño; papel de la doble acción integral; conclusiones (4 %). Redacción con el agente academic-prose-editor y auditoría de cifras contra las fuentes.",
     "Estructura nueva; respaldo en Tesis/_respaldo_reestructura_2026-10-02.", ["T", "MARCO", "HIP", "ANT", "SOA", "OG", "VIA", "K13"]),
]
ids_aristas = [int(a["id"][1:]) for a in g["aristas"] if re.fullmatch(r"e\d+", a["id"])]
siguiente = max(ids_aristas) + 1
for rid, lab, prio, prob, res, resumen, destinos in REVS:
    if rid in N:
        continue
    g["nodos"].append({
        "id": rid, "tipo": "rev", "etiqueta": lab,
        "contenido_html": f"<p>{prob}</p><p><b>Resolución:</b> {res}</p>",
        "texto": f"{prob}\nResolución: {res}",
        "prioridad": prio, "estado": "resuelta", "resuelta_en": "reestructuración 2026-10-02",
        "resolucion": resumen, "metricas": {},
    })
    for d in destinos:
        assert d in N, d
        g["aristas"].append({"id": f"e{siguiente:03d}", "origen": rid, "destino": d, "relacion": "afecta_a"})
        siguiente += 1

g["meta"]["version"] = 3
g["meta"]["historial"].append({
    "version": 3, "fecha": "2026-10-02",
    "cambio": "Reestructuración integrada en siete capítulos (capitulos/01–07), identidad v5 «UAM Dato» y reglas de escritura matemática: fuentes de los nodos actualizadas, números de capítulo y tabla corregidos y revisiones R21–R23.",
})
json.dump(g, open(RUTA, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("grafo v3 escrito:", len(g["nodos"]), "nodos,", len(g["aristas"]), "aristas")
