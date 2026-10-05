# Procedimiento de trabajo

Consultar primero [MEMORY.md](../MEMORY.md) y [claude.md](../claude.md). Los comandos siguientes parten de la raíz del repositorio, salvo donde se indica otra carpeta.

## Retomar una sesión

1. Revisar `git status --short` y `git log -5 --oneline`.
2. Identificar cambios posteriores al último informe antes de repetir sus conclusiones.
3. Revisar las fuentes activas y las métricas asociadas a la tarea. No asumir que el grafo o una revisión marcada «resuelta» sustituyen su comprobación.
4. Conservar los informes históricos y guardar nuevas pruebas en otra carpeta.

## Validación estructural

```sh
python3 validacion/validar_estructura.py validacion/barrido_03
```

Genera un inventario y huellas de las fuentes actuales en el destino indicado. No valida por sí solo las ecuaciones, la física ni la corrección semántica del grafo.

## Validación numérica disponible

```sh
/Applications/MATLAB_R2025a.app/bin/matlab -batch "run('validacion/validar_numerica.m')"
/Applications/MATLAB_R2025a.app/bin/matlab -batch "run('validacion/validar_csv.m')"
```

Estos dos scripts escriben en `validacion/`: preservar o redirigir sus salidas antes de una nueva auditoría. MATLAB está instalado fuera del PATH habitual; las pruebas previas requirieron ejecución fuera del aislamiento para iniciar correctamente.

El barrido completo independiente está en `validacion/barrido_R15_doble.m`; admite `SUBPASOS_AUDITORIA=20`. Su destino actual es `validacion/barrido_02/`. **Adaptar el destino antes de una tercera corrida** para conservar las evidencias existentes. El comparador es `validacion/comparar_barrido_02.py` y también tiene ese destino fijado.

El generador/exportador original actualizado está en `icr/calculus/Final_Bien/R15_sintonizacion/`. Comprobar sus dependencias y criterios al ejecutarlo. La GPU original usa MLX; el barrido independiente usa MATLAB en doble precisión. No describir sus diferencias como efectos exclusivos de precisión sin aislar las demás variables.

## Compilación

Desde `icr/context/Tesis/`:

```sh
latexmk main.tex
```

La configuración usa LuaLaTeX. En las validaciones se utilizó `/opt/homebrew/bin/biber` porque el lanzador de TeX Live 2024 había fallado en esta máquina. Ejecutar Biber con la carpeta de la tesis como directorio de trabajo permite resolver `bibliography/referencias.bib`.

Las pruebas con `lualatex -draftmode` verifican el procesamiento y la composición, pero no producen un PDF nuevo. Para aprobar el aspecto final hay que generar e inspeccionar el PDF. Si se usan salidas aisladas, preparar también el subdirectorio `preamble/` para los auxiliares.

## Cambios en resultados o texto

- Respaldar archivos de la tesis antes de modificarlos, como indican las convenciones existentes.
- Mantener una cadena verificable: parámetros/controlador → simulación → métricas → CSV → figuras → afirmaciones.
- Regenerar las cifras afectadas; no modificar un JSON para que coincida con una conclusión deseada.
- Declarar ventanas de medición, criterios de aceptación, ambas cotas de voltaje y si se mide antes o después de la retención.
- Comprobar invalidación de caché cuando cambien parámetros, controlador o código. La nueva firma de `seguimiento_P5.m` aún necesita revalidación de ejecución.
- Si se actualiza el grafo, revisar valores, prosa y HTML; después recalcular métricas con `python3 icr/grafo/consultar.py medir`. Este último comando reescribe el grafo.
- Tras cambios que alteren la extensión, medir introducción y conclusiones, dejando claro qué páginas forman el denominador.

## Cierre

Entregar un veredicto en Markdown con alcance, resultados, discrepancias y límites. Registrar en `MEMORY.md` la fecha, commit, cambios observados, pruebas ejecutadas y pendientes. No presentar como actual un informe de una revisión anterior ni dar por experimental una validación de simulación.
