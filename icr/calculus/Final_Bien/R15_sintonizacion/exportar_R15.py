"""R15: exporta las familias PI y PII de resultados_R15.json para la figura de la sección sec:barrido_familias.

Criterio de aceptación (el mismo en las dos familias, sin exclusiones manuales):
  un controlador se acepta si, tanto en el escalón como en la rampa,
  - no diverge (diverge == False, es decir, x final >= -20 cm y finito), y
  - el voltaje aplicado, posterior a la retención de la zona muerta, nunca alcanza
    la cota superior (frac_saturado == 0, con u >= 3,5 - 1e-4 V).
El criterio no examina la cota inferior (0 V), que todos los escalones alcanzan,
ni la orden del controlador antes del recorte; véase la sección sec:barrido_familias.

Uso: python exportar_R15.py  ->  ../../../context/tesis/images/r15_results/tikz/{familia_pi,familia_pii}.csv y resumen_R15.json
"""
import json
import os

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(AQUI, "..", "..", "..", "context", "tesis", "images", "r15_results", "tikz")

res = json.load(open(os.path.join(AQUI, "resultados_R15.json")))["resultados"]
casos = {}
for r in res:
    casos.setdefault((r["familia"], r["kK"], r["alpha"]), {})[r["prueba"]] = r


def aceptado(p):
    return all(not p[q]["diverge"] and p[q]["frac_saturado"] == 0 for q in ("escalon", "rampa"))


resumen = {"criterio": "escalon y rampa: diverge == false y frac_saturado == 0 (voltaje aplicado < 3,5 - 1e-4 V)",
           "estables": len(casos), "validos": {}}
for fam in ("PI", "PII"):
    filas = sorted((k, p) for k, p in casos.items() if k[0] == fam and aceptado(p))
    with open(os.path.join(SALIDA, f"familia_{fam.lower()}.csv"), "w") as f:
        f.write("ciclo,atasc,os,erampa,kK,alpha\n")
        for (_, kK, alpha), p in filas:
            e, r = p["escalon"], p["rampa"]
            f.write(f"{e['ciclo_pp_cm']:.5f},{e['atasc_medio_s']:.4f},{e['sobrepaso_pct']:.2f},"
                    f"{1e3 * r['error_medio_rampa_cm']:.4f},{kK:.4f},{alpha:.4f}\n")
    esc = [p["escalon"] for _, p in filas]
    ram = [p["rampa"] for _, p in filas]
    mejor = min(esc, key=lambda e: e["ciclo_pp_cm"])
    resumen["validos"][fam] = len(filas)
    resumen[fam] = dict(ciclo_min=mejor["ciclo_pp_cm"], kK_ciclo_min=mejor["kK"], alpha_ciclo_min=mejor["alpha"],
                        atasc_min=min(e["atasc_medio_s"] for e in esc),
                        erampa_min_1e3=1e3 * min(abs(r["error_medio_rampa_cm"]) for r in ram),
                        erampa_max_1e3=1e3 * max(abs(r["error_medio_rampa_cm"]) for r in ram),
                        erms_rampa_min_1e3=1e3 * min(r["error_rms_rampa_cm"] for r in ram))
json.dump(resumen, open(os.path.join(SALIDA, "resumen_R15.json"), "w"), indent=1)
print({f: resumen["validos"][f] for f in ("PI", "PII")}, {f: round(resumen[f]["ciclo_min"], 5) for f in ("PI", "PII")})
