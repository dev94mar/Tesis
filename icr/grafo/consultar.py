#!/usr/bin/env python3
"""Consulta y medición del grafo de conocimiento de la tesis (grafo_tesis.json).

Solo usa la biblioteca estándar. Ejemplos:

  python3 consultar.py resumen
  python3 consultar.py nodo PII
  python3 consultar.py vecinos LIN --relacion produce
  python3 consultar.py tipo calc
  python3 consultar.py buscar karnopp
  python3 consultar.py camino OE4 K1
  python3 consultar.py top intermediacion -n 10
  python3 consultar.py valores MRG
  python3 consultar.py cobertura
  python3 consultar.py citas FALT
  python3 consultar.py revisiones [--abiertas]
  python3 consultar.py medir          # recalcula métricas y reescribe el JSON
"""
import argparse
import json
import sys
from collections import Counter, deque
from pathlib import Path

RUTA = Path(__file__).with_name("grafo_tesis.json")


# ---------------------------------------------------------------- carga

def cargar(ruta=RUTA):
    with open(ruta, encoding="utf-8") as f:
        return json.load(f)


def guardar(g, ruta=RUTA):
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(g, f, ensure_ascii=False, indent=2)
        f.write("\n")


def adyacencia(g, dirigido=False):
    adj = {n["id"]: set() for n in g["nodos"]}
    for a in g["aristas"]:
        adj[a["origen"]].add(a["destino"])
        if not dirigido:
            adj[a["destino"]].add(a["origen"])
    return adj


# ---------------------------------------------------------------- métricas

def bfs_distancias(adj, s):
    dist = {s: 0}
    cola = deque([s])
    while cola:
        v = cola.popleft()
        for w in adj[v]:
            if w not in dist:
                dist[w] = dist[v] + 1
                cola.append(w)
    return dist


def intermediacion(adj):
    """Brandes, grafo no dirigido, normalizada a [0, 1]."""
    cb = dict.fromkeys(adj, 0.0)
    for s in adj:
        pila, pred = [], {v: [] for v in adj}
        sigma = dict.fromkeys(adj, 0)
        sigma[s] = 1
        dist = dict.fromkeys(adj, -1)
        dist[s] = 0
        cola = deque([s])
        while cola:
            v = cola.popleft()
            pila.append(v)
            for w in adj[v]:
                if dist[w] < 0:
                    dist[w] = dist[v] + 1
                    cola.append(w)
                if dist[w] == dist[v] + 1:
                    sigma[w] += sigma[v]
                    pred[w].append(v)
        delta = dict.fromkeys(adj, 0.0)
        while pila:
            w = pila.pop()
            for v in pred[w]:
                delta[v] += sigma[v] / sigma[w] * (1 + delta[w])
            if w != s:
                cb[w] += delta[w]
    n = len(adj)
    escala = 1 / ((n - 1) * (n - 2)) if n > 2 else 1
    return {v: c * escala for v, c in cb.items()}  # /2 no dirigido * 2 normalización


def cercania(adj):
    """Cercanía de Wasserman-Faust (válida con varias componentes)."""
    n = len(adj)
    out = {}
    for v in adj:
        d = bfs_distancias(adj, v)
        alcanzables = len(d) - 1
        total = sum(d.values())
        out[v] = (alcanzables / (n - 1)) * (alcanzables / total) if total else 0.0
    return out


def pagerank(adj_dir, d=0.85, iteraciones=200, tol=1e-12):
    nodos = list(adj_dir)
    n = len(nodos)
    pr = dict.fromkeys(nodos, 1 / n)
    for _ in range(iteraciones):
        colgantes = sum(pr[v] for v in nodos if not adj_dir[v])
        nuevo = dict.fromkeys(nodos, (1 - d) / n + d * colgantes / n)
        for v in nodos:
            if adj_dir[v]:
                parte = d * pr[v] / len(adj_dir[v])
                for w in adj_dir[v]:
                    nuevo[w] += parte
        if sum(abs(nuevo[v] - pr[v]) for v in nodos) < tol:
            pr = nuevo
            break
        pr = nuevo
    return pr


def agrupamiento(adj):
    out = {}
    for v, vec in adj.items():
        k = len(vec)
        if k < 2:
            out[v] = 0.0
            continue
        vec = list(vec)
        enlaces = sum(1 for i in range(k) for j in range(i + 1, k) if vec[j] in adj[vec[i]])
        out[v] = 2 * enlaces / (k * (k - 1))
    return out


def componentes(adj):
    vistos, comps = set(), []
    for v in adj:
        if v not in vistos:
            c = set(bfs_distancias(adj, v))
            vistos |= c
            comps.append(c)
    return comps


def medir(g):
    """Calcula métricas por nodo y globales y las escribe en g."""
    adj = adyacencia(g)
    adj_dir = adyacencia(g, dirigido=True)
    entrada = Counter(a["destino"] for a in g["aristas"])
    salida = Counter(a["origen"] for a in g["aristas"])
    bc, cc, pr, cl = intermediacion(adj), cercania(adj), pagerank(adj_dir), agrupamiento(adj)
    excentricidad = {}
    suma_dist, pares = 0, 0
    for v in adj:
        d = bfs_distancias(adj, v)
        excentricidad[v] = max(d.values())
        suma_dist += sum(d.values())
        pares += len(d) - 1
    for n in g["nodos"]:
        v = n["id"]
        n["metricas"] = {
            "grado": len(adj[v]),
            "grado_entrada": entrada[v],
            "grado_salida": salida[v],
            "intermediacion": round(bc[v], 6),
            "cercania": round(cc[v], 6),
            "pagerank": round(pr[v], 6),
            "agrupamiento": round(cl[v], 6),
            "excentricidad": excentricidad[v],
        }
    nn, na = len(g["nodos"]), len(g["aristas"])
    comps = componentes(adj)
    tipo_de = {n["id"]: n["tipo"] for n in g["nodos"]}

    def top(clave, k=10):
        orden = sorted(g["nodos"], key=lambda n: -n["metricas"][clave])[:k]
        return [{"id": n["id"], "etiqueta": n["etiqueta"], clave: n["metricas"][clave]} for n in orden]

    g["metricas_globales"] = {
        "nodos": nn,
        "aristas": na,
        "densidad": round(2 * na / (nn * (nn - 1)), 6),
        "grado_medio": round(2 * na / nn, 4),
        "componentes_conexas": len(comps),
        "diametro": max(excentricidad.values()),
        "radio": min(excentricidad.values()),
        "centro": sorted(v for v, e in excentricidad.items() if e == min(excentricidad.values())),
        "longitud_media_camino": round(suma_dist / pares, 4),
        "agrupamiento_medio": round(sum(cl.values()) / nn, 6),
        "nodos_por_tipo": dict(Counter(n["tipo"] for n in g["nodos"])),
        "aristas_por_relacion": dict(Counter(a["relacion"] for a in g["aristas"])),
        "aristas_por_par_de_tipos": dict(Counter(f'{tipo_de[a["origen"]]}->{tipo_de[a["destino"]]}' for a in g["aristas"])),
        "top_grado": top("grado"),
        "top_intermediacion": top("intermediacion"),
        "top_pagerank": top("pagerank"),
        "cobertura_objetivos": cobertura(g),
    }
    return g


def cobertura(g):
    """Para cada objetivo: qué cálculos, simulaciones, figuras y conclusiones alcanza siguiendo aristas dirigidas."""
    adj_dir = adyacencia(g, dirigido=True)
    tipo = {n["id"]: n["tipo"] for n in g["nodos"]}
    out = {}
    for n in g["nodos"]:
        if n["tipo"] != "obj":
            continue
        alc = set(bfs_distancias(adj_dir, n["id"])) - {n["id"]}
        out[n["id"]] = {t: sorted(v for v in alc if tipo[v] == t) for t in ("mod", "calc", "sim", "fig", "conc", "fut")}
        out[n["id"]]["total"] = len(alc)
    return out


# ---------------------------------------------------------------- consultas

def idx(g):
    return {n["id"]: n for n in g["nodos"]}


def fila(n, extra=""):
    return f'{n["id"]:<16} {n["tipo"]:<5} {n["etiqueta"]}{extra}'


def cmd_resumen(g, a):
    m = g["metricas_globales"]
    print(g["meta"]["titulo"])
    print(f'{m["nodos"]} nodos, {m["aristas"]} aristas, densidad {m["densidad"]}, '
          f'diámetro {m["diametro"]}, camino medio {m["longitud_media_camino"]}, componentes {m["componentes_conexas"]}')
    print("\nNodos por tipo:")
    for t, c in sorted(m["nodos_por_tipo"].items(), key=lambda x: -x[1]):
        print(f'  {t:<5} {g["tipos_nodo"][t]["nombre"]:<15} {c}')
    print("\nAristas por relación:")
    for r, c in sorted(m["aristas_por_relacion"].items(), key=lambda x: -x[1]):
        print(f"  {r:<18} {c}")
    print("\nMás centrales (intermediación):")
    for t in m["top_intermediacion"][:5]:
        print(f'  {t["id"]:<16} {t["intermediacion"]:.4f}  {t["etiqueta"]}')


def cmd_nodo(g, a):
    n = idx(g).get(a.id)
    if not n:
        sys.exit(f"No existe el nodo {a.id!r}. Usa 'buscar' para encontrarlo.")
    print(json.dumps({k: v for k, v in n.items() if k != "contenido_html"}, ensure_ascii=False, indent=2))


def cmd_vecinos(g, a):
    I = idx(g)
    if a.id not in I:
        sys.exit(f"No existe el nodo {a.id!r}.")
    for e in g["aristas"]:
        if a.relacion and e["relacion"] != a.relacion:
            continue
        if e["origen"] == a.id:
            print(fila(I[e["destino"]], f'   ← {e["relacion"]} (saliente)'))
        elif e["destino"] == a.id:
            print(fila(I[e["origen"]], f'   → {e["relacion"]} (entrante)'))


def cmd_tipo(g, a):
    for n in g["nodos"]:
        if n["tipo"] == a.tipo:
            print(fila(n))


def cmd_buscar(g, a):
    q = a.texto.lower()
    for n in g["nodos"]:
        campos = " ".join([n["id"], n["etiqueta"], n.get("texto", ""), " ".join(n.get("latex", [])),
                           json.dumps(n.get("referencia", {}), ensure_ascii=False)]).lower()
        if q in campos:
            print(fila(n))


def cmd_camino(g, a):
    adj = adyacencia(g, dirigido=a.dirigido)
    I = idx(g)
    for v in (a.origen, a.destino):
        if v not in I:
            sys.exit(f"No existe el nodo {v!r}.")
    prev, cola = {a.origen: None}, deque([a.origen])
    while cola:
        v = cola.popleft()
        if v == a.destino:
            break
        for w in sorted(adj[v]):
            if w not in prev:
                prev[w] = v
                cola.append(w)
    if a.destino not in prev:
        sys.exit("Sin camino entre esos nodos.")
    ruta, v = [], a.destino
    while v:
        ruta.append(v)
        v = prev[v]
    ruta.reverse()
    rel = {(e["origen"], e["destino"]): e["relacion"] for e in g["aristas"]}
    for i, v in enumerate(ruta):
        print(fila(I[v]))
        if i < len(ruta) - 1:
            w = ruta[i + 1]
            r = rel.get((v, w)) or (rel.get((w, v)) and f'{rel[(w, v)]} (inversa)')
            print(f"   │ {r}")
    print(f"\nLongitud: {len(ruta) - 1}")


def cmd_top(g, a):
    nodos = [n for n in g["nodos"] if not a.tipo or n["tipo"] == a.tipo]
    for n in sorted(nodos, key=lambda n: -n["metricas"][a.metrica])[: a.n]:
        print(f'{n["metricas"][a.metrica]:>10.4f}  ' + fila(n))


def cmd_valores(g, a):
    for n in g["nodos"]:
        if "valores" in n and (not a.id or n["id"] == a.id):
            print(f'## {n["id"]} · {n["etiqueta"]}')
            print(json.dumps(n["valores"], ensure_ascii=False, indent=2))


def cmd_cobertura(g, a):
    I = idx(g)
    for oid, c in g["metricas_globales"]["cobertura_objetivos"].items():
        print(f'{oid}: {I[oid]["etiqueta"]}  (alcanza {c["total"]} nodos)')
        for t in ("calc", "sim", "fig", "conc"):
            print(f'  {t:<5} {", ".join(c[t]) or "—"}')


def cmd_citas(g, a):
    I = idx(g)
    if a.id.startswith("ref:") or a.id in g["bibliografia"]:
        rid = a.id if a.id.startswith("ref:") else "ref:" + a.id
        for e in g["aristas"]:
            if e["origen"] == rid:
                print(fila(I[e["destino"]]))
    else:
        for e in g["aristas"]:
            if e["destino"] == a.id and e["relacion"] == "citada_en":
                r = I[e["origen"]]["referencia"]
                print(f'{r["clave"]:<14} {r["anio"]}  {r["autores"]} · {r["titulo"]}')


def cmd_revisiones(g, a):
    orden = {"alta": 0, "media": 1, "baja": 2}
    revs = [n for n in g["nodos"] if n["tipo"] == "rev" and not (a.abiertas and n.get("estado") == "resuelta")]
    for n in sorted(revs, key=lambda n: (n.get("estado") == "resuelta", orden[n["prioridad"]])):
        afecta = [e["destino"] for e in g["aristas"] if e["origen"] == n["id"]]
        est = n.get("estado", "abierta") + (f' ({n["resuelta_en"]})' if n.get("resuelta_en") else "")
        print(f'[{n["prioridad"]:<5}] {est:<15} {n["id"]:<4} {n["etiqueta"]}  → {", ".join(afecta)}')


def cmd_medir(g, a):
    medir(g)
    guardar(g, a.archivo)
    print(f"Métricas recalculadas y guardadas en {a.archivo.name}.")
    cmd_resumen(g, a)


def main():
    p = argparse.ArgumentParser(description="Consulta el grafo de conocimiento de la tesis.")
    p.add_argument("--archivo", type=Path, default=RUTA)
    s = p.add_subparsers(dest="cmd", required=True)
    s.add_parser("resumen")
    x = s.add_parser("nodo"); x.add_argument("id")
    x = s.add_parser("vecinos"); x.add_argument("id"); x.add_argument("--relacion")
    x = s.add_parser("tipo"); x.add_argument("tipo")
    x = s.add_parser("buscar"); x.add_argument("texto")
    x = s.add_parser("camino"); x.add_argument("origen"); x.add_argument("destino"); x.add_argument("--dirigido", action="store_true")
    x = s.add_parser("top"); x.add_argument("metrica", choices=["grado", "grado_entrada", "grado_salida", "intermediacion", "cercania", "pagerank", "agrupamiento", "excentricidad"]); x.add_argument("-n", type=int, default=10); x.add_argument("--tipo")
    x = s.add_parser("valores"); x.add_argument("id", nargs="?")
    s.add_parser("cobertura")
    x = s.add_parser("citas"); x.add_argument("id")
    x = s.add_parser("revisiones"); x.add_argument("--abiertas", action="store_true")
    s.add_parser("medir")
    a = p.parse_args()
    g = cargar(a.archivo)
    globals()["cmd_" + a.cmd](g, a)


if __name__ == "__main__":
    main()
