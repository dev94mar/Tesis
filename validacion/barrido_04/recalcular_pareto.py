import json, csv
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
b=ROOT/'icr/calculus/Final_Bien/R15_sintonizacion'
i=ROOT/'icr/context/Tesis/images/pii_v2_results/tikz'
result={}
for family in ['PI','PII']:
    data=json.loads((b/f'barrido_conjunto_{family}.json').read_text())
    def read(name):
        return [(float(q['ciclo']),float(q['atasc'])) for q in csv.DictReader((i/f'{name}_{family.lower()}.csv').open())]
    cloud=read('nube'); saved=read('frontera')
    frontier=sorted(set(q for q in cloud if not any(r!=q and r[0]<=q[0] and r[1]<=q[1] for r in cloud)))
    valid=[q for q in data if not q['diverge']]
    omitted=[q for q in valid if not any(abs(q['ciclo_pp_cm']-a)<1e-12 and abs(q['atasc_medio_s']-t)<1e-12 for a,t in cloud)]
    result[family]=dict(candidatos=len(data),no_divergen=len(valid),nube=len(cloud),frontera_correcta_para_nube=frontier==saved,frontera=frontier,omitidos=omitted,sin_correspondencia_json=[q for q in cloud if not any(abs(v['ciclo_pp_cm']-q[0])<1e-12 and abs(v['atasc_medio_s']-q[1])<1e-12 for v in data)])
Path(__file__).with_name('pareto.json').write_text(json.dumps(result,indent=2))
