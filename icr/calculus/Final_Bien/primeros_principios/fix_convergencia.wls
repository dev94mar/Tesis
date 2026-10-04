(* La "fuerza exacta" de este script y la "FdipoloPuntual" de derivar_fuerza.wls
   difieren en el signo global por una convencion de orientacion de los dipolos
   (ya señalada ahi: "el signo negativo solo refleja la convencion de
   orientacion; la magnitud coincide"). Se corrige aqui comparando magnitudes. *)
$Assumptions = z > 0 && Rbob > 0 && mu0 > 0 && mIm > 0 && mBob > 0;

Bexacto[i_, Rbob_, z_] := (mu0/2) * i * Rbob^2 / (z^2 + Rbob^2)^(3/2);
Fexacto[mIm_, i_, Rbob_, z_] := Simplify[-D[-mIm*Bexacto[i, Rbob, z], z]];

FexactoEnMbob = Fexacto[mIm, mBob/(Pi*Rbob^2), Rbob, z] // FullSimplify;
FdipoloPuntual = -(3*mu0*mIm*mBob)/(2*Pi*z^4);  (* mismo signo que Fexacto *)

Print["Fuerza exacta (espira finita): ", FexactoEnMbob];
Print["Dipolo puntual (mismo signo): ", FdipoloPuntual];

errorRelativo = FullSimplify[(FexactoEnMbob - FdipoloPuntual)/FdipoloPuntual, Rbob > 0 && z > 0];
Print["Error relativo exacto: ", errorRelativo];
limiteError = Limit[errorRelativo, Rbob -> 0, Assumptions -> z > 0];
Print["Limite cuando Rbob/z -> 0 (debe ser 0): ", limiteError];

Print["\n--- Error relativo numerico para Rbob/z = 0.01, 0.1, 0.3, 0.5, 1 ---"];
Do[
  err = errorRelativo /. {Rbob -> raz, z -> 1} // N;
  Print["Rbob/z = ", raz, " -> error relativo = ", err*100, " %"],
  {raz, {0.01, 0.1, 0.3, 0.5, 1.0}}
]

(* Serie de Taylor del error relativo en Rbob/z, para ver el orden del primer *)
(* termino no nulo (deberia ser (Rbob/z)^2). *)
serieError = Series[errorRelativo /. z -> 1, {Rbob, 0, 4}];
Print["\nSerie de Taylor del error relativo en Rbob (con z=1): ", serieError];
