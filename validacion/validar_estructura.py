"""Auditoría de fuentes, grafo y datos exportados; solo biblioteca estándar.
Ejecución: python3 validacion/validar_estructura.py
No escribe fuera de validacion/.
"""
import collections
import copy
import csv
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re
import sys
sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
T = ROOT / 'icr/context/Tesis'
B = ROOT / 'icr/calculus/Final_Bien'
OUT = Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)
R = {}
texts = {}
missing = []

def walk(p):
    if p in texts:
        return
    if not p.exists():
        missing.append(str(p.relative_to(ROOT)))
        return
    s = re.sub(r'(?<!\\)%[^\n]*', '', p.read_text())
    texts[p] = s
    for rel in re.findall(r'\\(?:input|include)\{([^}]+)\}', s):
        if '\\' not in rel:
            q = T / rel
            if not q.suffix:
                q = q.with_suffix('.tex')
            walk(q)

walk(T / 'main.tex')
labels = collections.Counter()
refs, cites = set(), set()
csvrefs, graphics = [], []
for p, s in texts.items():
    labels.update(re.findall(r'\\label\{([^}]+)\}', s))
    refs.update(re.findall(r'\\(?:eqref|ref|pageref)\{([^}]+)\}', s))
    for c in re.findall(r'\\(?:\w*cite\w*)\*?(?:\[[^\]]*\])*\{([^}]+)\}', s):
        cites.update(c.split(','))
    csvrefs.extend(re.findall(r'\{([^{}]+\.csv)\}', s))
    graphics.extend(re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}', s))
bib = set(re.findall(r'@\w+\s*\{\s*([^,]+)', (T / 'bibliography/referencias.bib').read_text()))
R['latex'] = dict(archivos_activos=len(texts), etiquetas=len(labels), citas=len(cites),
    inputs_faltantes=missing, etiquetas_duplicadas={k:v for k,v in labels.items() if v>1},
    referencias_sin_etiqueta=sorted(x for x in refs-set(labels) if not x.startswith('#')), citas_sin_bib=sorted(cites-bib),
    csv_faltantes=sorted({x for x in csvrefs if not (T/x).is_file()}))
# Resolver las macros de imágenes empleadas por la identidad gráfica.
macros = {}
for s in texts.values():
    macros.update(re.findall(r'\\newcommand\{(\\\w+)\}\{([^{}]+)\}',s))
badgraphics=[]
for g in graphics:
    name=macros.get(g,g)
    if '\\' in name:
        continue
    choices=[T/name,T/'images'/name]
    if not any(p.exists() or (not p.suffix and any(p.with_suffix(e).exists() for e in ['.pdf','.png','.eps','.jpg'])) for p in choices):
        badgraphics.append(name)
R['latex']['imagenes_faltantes']=sorted(set(badgraphics))

graphpath = ROOT/'icr/grafo/grafo_tesis.json'
G = json.loads(graphpath.read_text())
ids = [n['id'] for n in G['nodos']]
pairs=[tuple(sorted((e['origen'],e['destino']))) for e in G['aristas']]
bad_sources=[]
for n in G['nodos']:
    src=n.get('fuente','').split(' · ')[0]
    if src.startswith('icr/') and not (ROOT/src).exists():
        bad_sources.append([n['id'],src])
spec=importlib.util.spec_from_file_location('consultar',ROOT/'icr/grafo/consultar.py')
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
new=mod.medir(copy.deepcopy(G))
R['grafo']=dict(nodos=len(ids),aristas=len(pairs),pares_no_dirigidos=len(set(pairs)),
    ids_duplicados=[k for k,v in collections.Counter(ids).items() if v>1],
    extremos_inexistentes=[e for e in G['aristas'] if e['origen'] not in ids or e['destino'] not in ids],
    fuentes_inexistentes=bad_sources,
    metricas_guardadas_coinciden=new['metricas_globales']==G['metricas_globales'],
    todas_revisiones_resueltas=all(n.get('estado')=='resuelta' for n in G['nodos'] if n['tipo']=='rev'))

F=json.loads((B/'R15_sintonizacion/familias_R15.json').read_text())
rows=json.loads((B/'R15_sintonizacion/resultados_R15.json').read_text())['resultados']
key=lambda r:(r['familia'],r['kK'],r['alpha'])
ram={key(r):r for r in rows if r['prueba']=='rampa'}
valid=[r for r in rows if r['prueba']=='escalon' and not r['diverge'] and r['frac_saturado']==0
       and not ram[key(r)]['diverge'] and ram[key(r)]['frac_saturado']==0]
R['familias']=dict(controladores=len(F),trayectorias=len(rows),
    por_familia=dict(collections.Counter(r['familia'] for r in F)),
    validos_ambas_pruebas=dict(collections.Counter(r['familia'] for r in valid)),
    mejores={f:min((r for r in valid if r['familia']==f),key=lambda r:r['ciclo_pp_cm']) for f in ['PI','PII']})
sweep=json.loads((B/'verificacion_P1/barrido_3v5.json').read_text())['resultados']
R['barrido']=dict(trayectorias=len(sweep),controladores=dict(collections.Counter(r['controlador'] for r in sweep)),intervalos={})
for x in [-4,-3.5,-3,-2,-1]:
    rs=[r['referencia'] for r in sweep if r['controlador']=='PII_lic' and abs(r['x_inicial']-x)<1e-6 and r['estable']]
    R['barrido']['intervalos'][str(x)]=[min(rs),max(rs)] if rs else []

# Recalcular el ajuste de potencia directamente de los resultados, sin numpy.
R['ajuste_ganancia']={}
for fam in ['PI','PII']:
    rr=[r for r in rows if r['familia']==fam and r['prueba']=='escalon' and abs(r['alpha']-1)<1e-6 and not r['diverge'] and r['frac_saturado']==0]
    x=[math.log(r['kK']) for r in rr];y=[math.log(r['ciclo_pp_cm']) for r in rr]
    xm=sum(x)/len(x);ym=sum(y)/len(y)
    slope=sum((a-xm)*(b-ym) for a,b in zip(x,y))/sum((a-xm)**2 for a in x)
    R['ajuste_ganancia'][fam]=dict(n=len(x),exponente=slope,coef=math.exp(ym-slope*xm))

R['csv']=[]
for p in sorted((T/'images').glob('*/tikz/*.csv')):
    with p.open() as f:
        rr=list(csv.DictReader(f))
    bad=[];sep=0;partial_nan=0;textcols=set()
    for i,r in enumerate(rr,2):
        vals=[]
        for col,v in r.items():
            try: vals.append(float(v))
            except (ValueError,TypeError):
                if col=='familia' and v in ['PI','PII']:textcols.add(col)
                else:bad.append(i)
        if all(math.isnan(v) for v in vals):sep+=1
        elif any(math.isnan(v) for v in vals):partial_nan+=1
        elif any(math.isinf(v) for v in vals):bad.append(i)
    R['csv'].append(dict(archivo=str(p.relative_to(ROOT)),filas=len(rr),separadores_nan=sep,
        filas_con_nan_parcial=partial_nan,columnas_texto=sorted(textcols),filas_invalidas=bad))

# Huellas de evidencia: detectan si cambia el material auditado.
paths=set(texts)|{graphpath}|set((T/'images').glob('*/tikz/*'))
paths.update(p for p in B.rglob('*') if p.is_file() and p.suffix in ['.m','.py','.mat','.json'] and not any(x.startswith(('_archivo','_respaldo')) for x in p.parts))
R['sha256']={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths) if p.is_file()}
(OUT/'estructura.json').write_text(json.dumps(R,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in R.items() if k not in ['sha256','csv']},ensure_ascii=False,indent=2))
print('CSV examinados:',len(R['csv']),'con filas inválidas:',sum(bool(x['filas_invalidas']) for x in R['csv']))
