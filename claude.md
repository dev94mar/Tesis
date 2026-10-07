# Tesis: control PII del levitador magnético ECP-730

## Memoria de continuidad

Consultar [MEMORY.md](MEMORY.md) al retomar el proyecto: reúne las validaciones, las correcciones posteriores y los pendientes. El mapa está en [icr/project.md](icr/project.md) y el procedimiento en [icr/workflow.md](icr/workflow.md). Los informes históricos corresponden a sus fuentes auditadas; no certifican cambios posteriores.

Tesis de maestría (MCIE, UAM Azcapotzalco) de Lázaro Marino Ávalos Carvajal: control de posición del sistema de levitación magnética ECP-730 en configuración atractiva (inestable en lazo abierto) con atascamiento-deslizamiento, mediante un controlador lineal con doble acción integral (PII). Todo el trabajo se escribe en español.

## Estructura

- `icr/context/tesis/` — documento LaTeX. `main.tex` incluye `sections/resumen.tex` y `sections/abstract.tex`, los siete capítulos de `capitulos/` y los anexos de `chapters/apendices/`. Los capítulos son: `01_introduccion` (contexto, motivación, revisión bibliográfica, formulación e hipótesis, objetivos y metodología), `02_fundamentos`, `03_modelo` (modelo, linealización, lazo abierto, análisis estático del actuador), `04_controlador` (PII y PI de comparación), `05_desempeno` (intervalo de operación y simulaciones), `06_doble_integral` (PI frente a PII y mecanismo del ciclo límite) y `07_conclusiones`. Cada tema tiene un solo capítulo dueño; los demás remiten con `\ref`. La carpeta se simplificó el 2026-10-07: se eliminaron los antiguos `sections/{introduccion,antecedentes,justificacion,objetivos,metodologia,marco_teorico}.tex`, `chapters/chapter_*` y todos los respaldos sueltos (`*.respaldo_*`, carpetas `_respaldo_*`), que ya no se compilaban. El respaldo completo previo a esa limpieza está fuera del repo, en `TESIS/backups/tesis_pre_limpieza_20261006_235931.tar.gz`. El estilo es la identidad v5 «UAM Dato» en `preamble/uamdato.tex`. Las figuras de resultados son TikZ/pgfplots en `images/*/tikz/` y leen CSV generados por los scripts.
- `icr/calculus/Final_Bien/` — scripts de MATLAB y Python que generan todos los resultados. `README.md` relaciona cada script con su sección y su orden de ejecución. Las versiones obsoletas están en `_archivo_P2_*` y `_respaldo_P1_*`.
- `icr/grafo/` — grafo de conocimiento de la tesis (`grafo_tesis.json`, v4), con consultas y métricas en `consultar.py`. Las fuentes de los nodos apuntan a `capitulos/` con la etiqueta de sección; `actualizar_v4.py` documenta el último cambio y `grafo_tesis_v3.json` conserva la versión anterior. Tras modificar el grafo, recalcular con `python3 consultar.py medir`.
- `icr/context/*.pdf` — antecedentes: tesis de Hernández Alcántara (ECP-730 repulsivo) y de Pérez-Gómez (PII en motor de CD).

## Compilar

```
cd icr/context/tesis && latexmk main.tex
```

Usa lualatex (por `.latexmkrc`) y biber. El `biber` de TeX Live 2024 está roto en esta Mac; se usa el binario arm64 enlazado en `/opt/homebrew/bin/biber`.

## Convenciones del modelo

- Posición $x$ en cm, positiva hacia la bobina superior; distancia imán–bobina $a - x$. Fuerzas en kg·cm/s² ($mg = 138.3$).
- Parámetros: $a = 7.17184$ cm, $b = 1.6163\times10^{-6}$, $c_1 = 8.563$ s⁻¹ (por unidad de masa), $m = 0.141$ kg, $g = 981$ cm/s², $F_s = 20$, $DV = 0.02$ cm/s.
- Actuador $u \in [0, 3.5]$ V; zona muerta simulada de −0.02/+0.025 V. Las pruebas se hacen entre −3 y −2 cm (en −4 cm el imán no puede moverse con 3.5 V).
- Controlador de la tesis: `PII_lic.mat`. Simulador: `inestable/PII_inestable/maglev_karnopp.m` (corregido; no reintroducir la versión anterior).

## Al editar

- Ya no se guardan respaldos sueltos dentro de `icr/context/tesis/` (se limpiaron el 2026-10-07); para cambios grandes, respaldar fuera del repo (p. ej. `TESIS/backups/`) y verificar que compile sin avisos.
- Toda cifra del texto debe salir de los datos de simulación (JSON de métricas en `images/*/tikz/` o en los scripts).
- Punto decimal en todo el documento, pese al español (`0.5`, no `0{,}5`; cambio hecho el 2026-10-07 a pedido del autor); figuras nuevas en TikZ, sin la opción `/pgf/number format/use comma` en pgfplots.
- Aplicar las reglas de `~/.claude/reglas/escritura_matematica.md` (toda ecuación desplegada numerada, con `\label` y puntuación; símbolos explicados en prosa; siglas definidas una vez, en su primer uso).
- Extensiones fijadas por el autor: la introducción ocupa el 10 % de las páginas del documento y las conclusiones entre el 3 y el 5 %. Medirlas tras cualquier cambio que altere el total.
