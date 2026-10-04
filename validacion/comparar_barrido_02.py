"""Contrasta el nuevo barrido completo en doble precisión con el GPU guardado."""
import json
import hashlib
import statistics
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'validacion/barrido_02'
original=ROOT/'icr/calculus/Final_Bien/R15_sintonizacion/resultados_R15.json'
nuevo=OUT/'R15_doble.json'
old=json.loads(original.read_text())['resultados']
new=json.loads(nuevo.read_text())['resultados']
def key(r):return (r['familia'],r['kK'],r['alpha'],r['prueba'])
O={key(r):r for r in old};N={key(r):r for r in new}
assert O.keys()==N.keys() and len(N)==512
def seleccion(rows):
    idx={key(r):r for r in rows}
    return [r for r in rows if r['prueba']=='escalon'
      and not r['diverge'] and r['frac_saturado']==0
      and not idx[key(r)[:-1]+('rampa',)]['diverge']
      and idx[key(r)[:-1]+('rampa',)]['frac_saturado']==0]
a=seleccion(old);b=seleccion(new)
R={'trayectorias':len(N),'fuentes_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [original,nuevo]},
   'seleccion':{},'cambios_divergencia':[],'cambios_saturacion_superior':[],'diferencias_ciclo':{}}
for fam in ['PI','PII']:
    aa=[r for r in a if r['familia']==fam];bb=[r for r in b if r['familia']==fam]
    R['seleccion'][fam]={'validos_gpu':len(aa),'validos_doble':len(bb),
      'mejor_gpu':min(aa,key=lambda r:r['ciclo_pp_cm']),
      'mejor_doble':min(bb,key=lambda r:r['ciclo_pp_cm']),
      'entran':[list(key(r)) for r in bb if key(r) not in {key(x) for x in aa}],
      'salen':[list(key(r)) for r in aa if key(r) not in {key(x) for x in bb}]}
for k,n in N.items():
    o=O[k]
    if o['diverge']!=n['diverge']:R['cambios_divergencia'].append(list(k))
    if (o['frac_saturado']==0)!=(n['frac_saturado']==0):R['cambios_saturacion_superior'].append(list(k))
for fam in ['PI','PII']:
    d=[]
    for r in b:
        k=key(r)
        if r['familia']==fam and k in {key(x) for x in a}:
            d.append({'clave':list(k),'ciclo_gpu':O[k]['ciclo_pp_cm'],'ciclo_doble':r['ciclo_pp_cm'],
                      'diferencia_relativa_pct':100*abs(r['ciclo_pp_cm']/O[k]['ciclo_pp_cm']-1)})
    R['diferencias_ciclo'][fam]={'n':len(d),'mediana_pct':statistics.median(x['diferencia_relativa_pct'] for x in d),
       'maximo':max(d,key=lambda x:x['diferencia_relativa_pct']),
       'mayores_8pct':[x for x in d if x['diferencia_relativa_pct']>8]}
R['diagnosticos_adicionales']={'no_finitos':sum(r['no_finito_en_trayectoria'] for r in new),
    'recorte_posicion':sum(r['recorte_posicion'] for r in new),
    'con_recorte_inferior':sum(r['frac_recorte_inferior']>0 for r in new),
    'validos_escalon_con_recorte_inferior':sum(r['frac_recorte_inferior']>0 for r in b)}
R['recorte_superior_antes_retencion']={}
for fam in ['PI','PII']:
    idx=N
    filtrados=[r for r in b if r['familia']==fam and r['frac_recorte_superior']==0
       and idx[key(r)[:-1]+('rampa',)]['frac_recorte_superior']==0]
    R['recorte_superior_antes_retencion'][fam]={'validos':len(filtrados),
       'mejor':min(filtrados,key=lambda r:r['ciclo_pp_cm']),
       'excluidos':[r for r in b if r['familia']==fam and r['frac_recorte_superior']>0]}
refinado=OUT/'R15_doble_sub20.json'
if refinado.exists():
    rr=json.loads(refinado.read_text())['resultados'];ref={key(r):r for r in rr}
    R['refinamiento_20_subpasos']={}
    for fam in ['PI','PII']:
        vv=[r for r in seleccion(rr) if r['familia']==fam]
        dd=[{'clave':list(key(r)),'ciclo_sub10':r['ciclo_pp_cm'],'ciclo_sub20':ref[key(r)]['ciclo_pp_cm'],
             'diferencia_pct':100*abs(ref[key(r)]['ciclo_pp_cm']/r['ciclo_pp_cm']-1)}
            for r in b if r['familia']==fam]
        R['refinamiento_20_subpasos'][fam]={'validos':len(vv),'mejor':min(vv,key=lambda r:r['ciclo_pp_cm']),
           'entran_frente_sub10':[list(key(r)) for r in vv if key(r) not in {key(x) for x in b}],
           'salen_frente_sub10':[list(key(r)) for r in b if r['familia']==fam and key(r) not in {key(x) for x in vv}],
           'mediana_diferencia_pct':statistics.median(x['diferencia_pct'] for x in dd),
           'maximo':max(dd,key=lambda x:x['diferencia_pct'])}
(OUT/'comparacion_R15.json').write_text(json.dumps(R,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(R,ensure_ascii=False,indent=2))
