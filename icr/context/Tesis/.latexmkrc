# Compilar con lualatex: no tiene el límite fijo de memoria de pdflatex,
# que con las figuras pgfplots de la tesis llegaba al 82 %.
# Para volver a pdflatex: latexmk -pdf main.tex
$pdf_mode = 4;
