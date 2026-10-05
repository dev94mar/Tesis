# Mapa del proyecto

La memoria de continuidad y el estado de validación se mantienen en [MEMORY.md](../MEMORY.md). Este archivo describe la organización, no duplica los informes.

| Ruta | Contenido |
|---|---|
| `context/Tesis/main.tex` | Entrada del documento vigente |
| `context/Tesis/capitulos/01_introduccion.tex` | Contexto, antecedentes, hipótesis y objetivos |
| `context/Tesis/capitulos/02_fundamentos.tex` | Herramientas teóricas |
| `context/Tesis/capitulos/03_modelo.tex` | Modelo, linealización y límites del actuador |
| `context/Tesis/capitulos/04_controlador.tex` | PII y PI de comparación |
| `context/Tesis/capitulos/05_desempeno.tex` | Regulación, seguimiento y configuración estable |
| `context/Tesis/capitulos/06_doble_integral.tex` | Comparación y análisis del atascamiento |
| `context/Tesis/capitulos/07_conclusiones.tex` | Conclusiones y trabajo futuro |
| `context/Tesis/chapters/apendices/` | Implementación y verificación |
| `context/Tesis/images/*/tikz/` | Figuras, CSV y métricas JSON |
| `context/Tesis/bibliography/referencias.bib` | Bibliografía |
| `calculus/Final_Bien/` | MATLAB/Python vigentes; consultar su README |
| `calculus/Final_Bien/R15_sintonizacion/` | Familias PI/PII, barrido, exportadores y análisis |
| `calculus/Final_Bien/verificacion_P1/` | Verificación de planta y barridos del intervalo |
| `grafo/grafo_tesis.json` | Grafo de conocimiento vigente; versión observada: 4 |
| `grafo/consultar.py` | Consultas y recálculo de métricas del grafo |
| `../validacion/` | Pruebas e informes independientes |
| `context/*.pdf` | Antecedentes locales |

El controlador nominal está en `calculus/Final_Bien/inestable/PII_inestable/PII_lic.mat`. `PII.mat` es otro controlador preliminar: no intercambiarlos. La planta vigente es `maglev_karnopp.m` en esa misma carpeta.

Los respaldos y archivos obsoletos se conservan para trazabilidad. Los antiguos `chapters/chapter_*` y varias secciones introductorias sueltas no forman parte de la compilación vigente. La lista de entradas de `main.tex` decide qué se compila.
