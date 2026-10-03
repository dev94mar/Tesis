"""Grafo v4: correcciones del segundo barrido de validación (2026-10-03).

Corrige los datos estructurados y los textos que contradecían la implementación
vigente (H03: saturación de 5 V, Fs en N, nota c2 = c1/m), la unidad de b (H02),
la selección R15 de 57 PI y 51 PII (H04), el alcance de las conclusiones (H05),
la zona muerta implementada (H06), la fórmula del atascamiento (H07), el signo de
Kv (H08), la rigidez neta del PD (H09), el criterio de saturación (H11, N02), el
movimiento desde -4 cm (H12) y la sensibilidad numérica del barrido (N01, N03).
Registra la revisión R24. La versión anterior queda en grafo_tesis_v3.json.
"""
import json, re, shutil

RUTA = "grafo_tesis.json"
shutil.copy(RUTA, "grafo_tesis_v3.json")
g = json.load(open(RUTA, encoding="utf-8"))
N = {n["id"]: n for n in g["nodos"]}


def reemplazar(nid, viejo, nuevo, html=None):
    """Sustituye en texto y en contenido_html; html=(viejo, nuevo) si el HTML difiere."""
    n = N[nid]
    assert viejo in n["texto"], (nid, "texto", viejo)
    n["texto"] = n["texto"].replace(viejo, nuevo)
    hv, hn = html or (viejo, nuevo)
    assert hv in n["contenido_html"], (nid, "contenido_html", hv)
    n["contenido_html"] = n["contenido_html"].replace(hv, hn)


# H03: datos estructurados
N["ZM"]["valores"]["saturacion"]["max"] = 3.5
N["KARN"]["valores"]["Fs"] = {"valor": 20, "unidad": "kg·cm/s^2", "equivalente": "0.2 N"}
N["PAR"]["valores"]["c"]["nota"] = "por unidad de masa; el simulador corregido lo usa directamente como c1"
# H02: unidad de b
N["PAR"]["valores"]["b"]["unidad"] = "V·s^2/(kg·cm^5)"
N["PAR"]["valores"]["b"]["equivalente_SI_mixto"] = "1.6163e-4 V/(N·cm^4)"
reemplazar("PAR", "1.6163×10⁻⁶ V/(N·cm⁴)", "1.6163×10⁻⁶ V·s²/(kg·cm⁵), es decir, 1.6163×10⁻⁴ V/(N·cm⁴)")

# H06: zona muerta implementada
reemplazar("ZM", "Los umbrales de D(u) son relativos a ue (corregido en la verificación de consistencia).",
           "Los umbrales de D(u) son relativos a ue. La retención implementada no equivale a D(u): tiene memoria y se desactiva con el imán atascado; los resultados valen para esa implementación. Sin zona muerta, el ciclo del PII persiste con un 8 % menos de amplitud.",
           ("Los umbrales de D(u) son relativos a u<sub>e</sub> (corregido en la verificación de consistencia).",
            "Los umbrales de D(u) son relativos a u<sub>e</sub>. La retención implementada no equivale a D(u): tiene memoria y se desactiva con el imán atascado; los resultados valen para esa implementación. Sin zona muerta, el ciclo del PII persiste con un 8 % menos de amplitud."))

# H04, H11, N01-N03: barrido R15
reemplazar("SINT", "256 variantes estables con MF ≥ 30° en −3 a −2 cm; 54 PI y 51 PII completan sin saturar el escalón −2 → −3 cm",
           "256 variantes linealmente estables con MF ≥ 30° en −3, −2.5 y −2 cm; 57 PI y 51 PII completan, sin divergir y con el voltaje aplicado (tras la retención) por debajo de 3.5 V, el escalón −2 → −3 cm")
reemplazar("SINT", "512 trayectorias en GPU (31 s), extremos validados con ode45.",
           "512 trayectorias en GPU (31 s); exportador con criterio explícito en exportar_R15.py. Repetidas en doble precisión: diferencia mediana < 1 %, un PI con 16 % confirmado por ode45; con 20 subpasos los PII aceptados son 52. Si se excluye todo recorte superior previo a la retención: 53 PI y 50 PII, mejor PI 0.019 cm (cociente 1.4 en lugar de 1.9).")
reemplazar("SINT", "0.22 s | 0.20 s", "0.17 s | 0.20 s", ("<td>0.22 s</td>", "<td>0.17 s</td>"))
reemplazar("F_R15", "para las variantes que operan sin saturar.",
           "para los 57 PI y 51 PII cuyo voltaje aplicado no alcanza 3.5 V en el escalón ni en la rampa.")
reemplazar("APA", "Barridos en GPU (RK4) validados con ode45 (< 8 %).",
           "Barridos en GPU (RK4, precisión simple); repetidos en doble precisión con diferencia mediana < 1 % y un caso del 16 %.",
           ("Barridos en GPU (RK4) validados con ode45 (&lt; 8 %).",
            "Barridos en GPU (RK4, precisión simple); repetidos en doble precisión con diferencia mediana &lt; 1 % y un caso del 16 %."))
reemplazar("REG", "3.28 V, sin saturar", "3.28 V, sin alcanzar 3.5 V (toca 0 V en el escalón)")
reemplazar("F_TRAP_U", "sin saturar.", "sin alcanzar ninguna de las dos cotas del actuador.")

# H05: alcance de las conclusiones
reemplazar("K9", "En 256 variantes estables, ningún PII alcanza un ciclo límite menor que el mejor PI (0.026 frente a 0.013 cm)",
           "En las familias y condiciones ensayadas, ningún PII aceptado alcanza un ciclo límite menor que el mejor PI (0.026 frente a 0.013 cm, o 0.019 cm con el criterio de recorte estricto); no es una demostración general ni una validación experimental")
reemplazar("K13", "Parte 2 rechazada:", "Parte 2 sin respaldo en las simulaciones de las familias ensayadas:")

# H07: estado inicial del integrador
reemplazar("CICLO", "pero el término cuadrático solo domina después de 2Ki/Kii = 1.6 s.",
           "pero con estado inicial nulo el término cuadrático solo dominaría después de 2Ki/Kii = 1.6 s; la integral acumulada q₀ cambia ese umbral y reduce la pendiente inicial.",
           ("pero el término cuadrático solo domina después de 2K<sub>i</sub>/K<sub>ii</sub> = 1.6 s.",
            "pero con estado inicial nulo el término cuadrático solo dominaría después de 2K<sub>i</sub>/K<sub>ii</sub> = 1.6 s; la integral acumulada q₀ cambia ese umbral y reduce la pendiente inicial."))

# H10: jacobiano en la región de deslizamiento
reemplazar("APB", "jacobiano igual a la matriz A,",
           "jacobiano igual a la matriz A en la región de deslizamiento (v = 0.5 cm/s; en reposo dentro de la banda de Karnopp es la matriz nula),")
reemplazar("K12", "la duración del atascamiento la fija el término integral simple.",
           "en atascamientos de unos 0.35 s el término integral simple aporta la mayor parte del cambio de voltaje.")

# H08: signo de Kv
reemplazar("KV", "\\(K_v=91.6\\) s⁻¹ en −3 cm.", "\\(K_v=-91.6\\) s⁻¹ en −3 cm (signo de la planta inestable); con \\(\\dot r=-0.05\\) cm/s el error es positivo.")

# H09: rigidez neta del PD
reemplazar("PDFF", "dentro de la banda teórica \\(\\pm F_s/506.5 = \\pm0.039\\) cm.",
           "dentro de la banda de reposo: con la rigidez neta \\(k_{ef}=506.5-4mg/(a-r)=452.1\\), \\(F_s/k_{ef}=0.044\\) cm; sin linealizar, de −0.043 a +0.045 cm.")

# H12: movimiento desde -4 cm
reemplazar("VIA", "el imán se sostiene pero no se mueve.",
           "el imán se sostiene pero no sube; por debajo de ≈ 2.98 V se despega hacia abajo y cae sin recuperación. Alcanzable: error < 0.05 cm en los últimos 5 s (−3.95 cm desde −4 cumple solo por tolerancia).")
reemplazar("K6", "en −4 cm el imán se sostiene pero no se mueve;", "en −4 cm el imán se sostiene pero no sube, y si baja cae;")

REV = ("R24", "Segundo barrido de validación", "alta",
       "La auditoría del 3 de octubre de 2026 (validacion/barrido_02/VEREDICTO.md) encontró la unidad de b incompatible, datos obsoletos en el grafo, 54 PI publicados frente a 57 según el filtro, conclusiones más generales que el barrido, la retención de voltaje descrita como D(u), la fórmula del atascamiento sin estado inicial, Kv sin signo, la rigidez del PD sin la planta, el jacobiano sin precisar la región, «sin saturar» ambiguo, el movimiento desde −4 cm exagerado, la caché de seguimiento sin versión y la sensibilidad numérica del barrido sin informar.",
       "Unidad de b, grafo, exportador R15 reproducible (57 PI y 51 PII), conclusiones acotadas a las familias ensayadas, zona muerta implementada distinguida de D(u), fórmula con q₀, Kv con signo, rigidez neta del PD, jacobiano en deslizamiento, criterio de saturación explícito y alternativo, movimiento desde −4 cm y criterio de alcanzable, caché versionada con firma y sensibilidad del barrido (doble precisión, 20 subpasos, ode45). Las conclusiones siguen siendo de simulación.",
       "Correcciones aplicadas; no equivale a validación experimental.",
       ["PAR", "ZM", "KARN", "SINT", "F_R15", "K9", "K12", "K13", "CICLO", "KV", "PDFF", "VIA", "K6", "APA", "APB", "REG"])
rid, lab, prio, prob, res, resumen, destinos = REV
ids_aristas = [int(a["id"][1:]) for a in g["aristas"] if re.fullmatch(r"e\d+", a["id"])]
siguiente = max(ids_aristas) + 1
if rid not in N:
    g["nodos"].append({
        "id": rid, "tipo": "rev", "etiqueta": lab,
        "contenido_html": f"<p>{prob}</p><p><b>Resolución:</b> {res}</p>",
        "texto": f"{prob}\nResolución: {res}",
        "prioridad": prio, "estado": "resuelta", "resuelta_en": "validación 2026-10-03",
        "resolucion": resumen, "metricas": {},
    })
    for d in destinos:
        assert d in N, d
        g["aristas"].append({"id": f"e{siguiente:03d}", "origen": rid, "destino": d, "relacion": "afecta_a"})
        siguiente += 1

g["meta"]["version"] = 4
g["meta"]["generado"] = "2026-10-03"
g["meta"]["historial"].append({
    "version": 4, "fecha": "2026-10-03",
    "cambio": "Correcciones del segundo barrido de validación (H02-H13, N01-N03): datos de ZM, KARN y PAR, selección R15 de 57 PI y 51 PII, conclusiones acotadas y revisión R24. El estado «resuelta» indica que la corrección se aplicó, no que la tesis esté validada experimentalmente.",
})
json.dump(g, open(RUTA, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("grafo v4 escrito:", len(g["nodos"]), "nodos,", len(g["aristas"]), "aristas")
