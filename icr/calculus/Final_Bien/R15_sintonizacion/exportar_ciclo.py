"""Exporta los datos de las figuras de 'Análisis del ciclo límite' (requiere numpy).

Se ejecuta después de analisis_ciclo.m (anatomia_*.csv, analisis_ciclo.json) y de
simular_R15.py (resultados_R15.json):
  atasco_{pi,pii}.csv      voltaje durante cada atascamiento, alineado al inicio y con el signo del error
  atasco_{pi,pii}_teo.csv  predicción K_i e0 t + K_ii e0 t^2 / 2
  ganancia_{pi,pii}.csv    ciclo límite y atascamiento medio contra la ganancia (alpha = 1)
"""
import csv
import json
from pathlib import Path

import numpy as np

AQUI = Path(__file__).parent
D = AQUI / ".." / ".." / ".." / "context" / "Tesis" / "images" / "ciclo_results" / "tikz"
A = json.load(open(D / "analisis_ciclo.json"))
Ki = {"pi": A["pi"]["K_i"], "pii": A["pii"]["K_i"]}
Kii = {"pi": 0.0, "pii": A["pii"]["K_ii"]}

for nm in ("pi", "pii"):
    rows = list(csv.DictReader(open(D / f"anatomia_{nm}.csv")))
    t, v, u, e = (np.array([float(r[c]) for r in rows]) for c in ("t", "v", "u", "e"))
    at = (v == 0).astype(int)
    d = np.diff(np.r_[0, at, 0])
    segs = list(zip(np.where(d == 1)[0], np.where(d == -1)[0] - 1))[1:-1]   # solo intervalos completos
    lineas, e0s = ["tau,du"], []
    for i0, i1 in segs:
        s = np.sign(e[i0])
        tt, du = t[i0:i1 + 1] - t[i0], (u[i0:i1 + 1] - u[i0]) * s
        lineas += [f"{a:.4f},{b:.4f}" for a, b in zip(tt[::5], du[::5])] + ["nan,nan"]
        e0s.append(abs(e[i0]))
    (D / f"atasco_{nm}.csv").write_text("\n".join(lineas) + "\n")
    e0, tau = float(np.mean(e0s)), np.linspace(0, 0.5, 51)
    teo = Ki[nm] * e0 * tau + Kii[nm] * e0 * tau ** 2 / 2
    (D / f"atasco_{nm}_teo.csv").write_text("tau,du\n" + "\n".join(f"{a:.4f},{b:.4f}" for a, b in zip(tau, teo)) + "\n")
    print(nm, "atascamientos:", len(segs), "e0 medio:", round(e0, 5))

R = json.load(open(AQUI / "resultados_R15.json"))["resultados"]
ajuste = {}
for f in ("PI", "PII"):
    E = sorted((r for r in R if r["familia"] == f and r["prueba"] == "escalon" and abs(r["alpha"] - 1) < 1e-6
                and not r["diverge"] and r["frac_saturado"] == 0), key=lambda r: r["kK"])
    k, c, a = (np.array([r[x] for r in E]) for x in ("kK", "ciclo_pp_cm", "atasc_medio_s"))
    p = np.polyfit(np.log(k), np.log(c), 1)
    ajuste[f] = {"exponente": float(p[0]), "coef": float(np.exp(p[1]))}
    (D / f"ganancia_{f.lower()}.csv").write_text("kK,ciclo,atasc\n" + "\n".join(f"{x:.4f},{y:.5f},{z:.4f}" for x, y, z in zip(k, c, a)) + "\n")
json.dump(ajuste, open(D / "ajuste_ganancia.json", "w"), indent=1)
print(ajuste)
