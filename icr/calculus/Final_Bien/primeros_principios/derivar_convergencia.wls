(* Demuestra que el modelo de dipolo puntual (derivar_fuerza.wls) no es una
   coincidencia de forma impuesta, sino el limite de campo lejano de la espira
   circular FINITA real. Se parte del campo exacto de una espira (Biot-Savart,
   sin aproximar) y se muestra que converge al termino u/(a-x)^4 del
   fabricante cuando el entrehierro z es grande frente al radio de la espira
   Rbob, con el termino de error explicito que se anula en ese limite. *)
$Assumptions = z > 0 && Rbob > 0 && mu0 > 0 && mIm > 0 && mBob > 0 && R > 0 && a > 0;

(* 1) Campo axial EXACTO de una espira circular de radio Rbob con corriente i *)
Bexacto[i_, Rbob_, z_] := (mu0/2) * i * Rbob^2 / (z^2 + Rbob^2)^(3/2);
Print["Campo exacto de la espira (Biot-Savart, sin aproximar): B(z) = ", Bexacto[i, Rbob, z]];

(* 2) Fuerza exacta sobre un dipolo puntual mIm a distancia z sobre el eje *)
Uexacto[mIm_, i_, Rbob_, z_] := -mIm*Bexacto[i, Rbob, z];
Fexacto[mIm_, i_, Rbob_, z_] := Simplify[-D[Uexacto[mIm, i, Rbob, z], z]];
Print["Fuerza exacta (sin aproximar): F(z) = ", Fexacto[mIm, i, Rbob, z]];

(* 3) Desarrollo en serie para Rbob pequeño frente a z (campo lejano) *)
serieF = Series[Fexacto[mIm, i, Rbob, z], {Rbob, 0, 4}] // Normal // FullSimplify;
Print["\nDesarrollo en serie de F para Rbob chico (campo lejano): F = ", serieF];

terminoLider = Coefficient[serieF, Rbob, 2]*Rbob^2 // FullSimplify;
Print["Termino principal (orden Rbob^2): ", terminoLider];

(* 4) Reescalar la corriente en terminos de mBob = i*Pi*Rbob^2 (fijo), y *)
(*    tomar el limite Rbob->0 (limite de dipolo puntual). *)
Flimite = terminoLider /. i -> mBob/(Pi*Rbob^2) // FullSimplify;
Print["\nTermino principal en terminos de mBob = i*Pi*Rbob^2: F -> ", Flimite];

FdipoloPuntual = (3*mu0*mIm*mBob)/(2*Pi*z^4);
Print["Comparar con el dipolo puntual ya derivado (derivar_fuerza.wls): F = ", FdipoloPuntual];
Print["¿Coinciden exactamente? ", FullSimplify[Flimite - FdipoloPuntual] == 0];

(* 5) Error relativo EXACTO (espira finita, sin truncar serie) frente al *)
(*    dipolo puntual, en funcion de Rbob/z. *)
FexactoEnMbob = Fexacto[mIm, mBob/(Pi*Rbob^2), Rbob, z] // FullSimplify;
Print["\nFuerza exacta en terminos de mBob: F = ", FexactoEnMbob];
errorRelativo = FullSimplify[(FexactoEnMbob - FdipoloPuntual)/FdipoloPuntual, Rbob > 0 && z > 0];
Print["Error relativo exacto (espira finita vs. dipolo puntual): ", errorRelativo];
limiteError = Limit[errorRelativo, Rbob -> 0, Assumptions -> z > 0];
Print["Limite del error relativo cuando Rbob/z -> 0: ", limiteError];

Print["\n--- Verificacion numerica, Rbob/z = 0.1, 0.3, 0.5, 1 ---"];
Do[
  err = errorRelativo /. {Rbob -> raz, z -> 1} // N;
  Print["Rbob/z = ", raz, " -> error relativo = ", err*100, " %"],
  {raz, {0.1, 0.3, 0.5, 1.0}}
]

(* 6) Lo mismo en terminos de u (voltaje) y x (posicion), z=a-x, i=u/R *)
Print["\n--- En terminos del modelo del fabricante u/(b(a-x)^4) ---"];
zsym = a - xv;
FexactoRaw = Fexacto[mIm, u/R, Rbob, zAux] // FullSimplify;
Print["Fuerza exacta en funcion de u, con z=zAux: F = ", FexactoRaw];
FexactoU = FexactoRaw /. zAux -> zsym;
Print["Sustituyendo zAux = a - x: F(u,x) = ", FexactoU];
serieFU = Series[FexactoRaw, {Rbob, 0, 2}] // Normal // FullSimplify;
serieFU = serieFU /. zAux -> zsym;
Print["Limite de campo lejano (orden Rbob^2): F -> ", serieFU];
Print["Forma del fabricante: F = u/(b(a-x)^4), con b = 2 Pi R/(3 mu0 Rbob^2... ) ya identificado en derivar_fuerza.wls."];
