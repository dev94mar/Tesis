$Assumptions = zAux > 0 && Rbob > 0 && mu0 > 0 && mIm > 0 && R > 0;

Bexacto[i_, Rbob_, z_] := (mu0/2) * i * Rbob^2 / (z^2 + Rbob^2)^(3/2);
FexactoAux[mIm_, i_, Rbob_, z_] := Simplify[-D[-mIm*Bexacto[i, Rbob, z], z]];

(* Derivar primero respecto a zAux (simbolo simple), sustituir despues *)
Fz = FexactoAux[mIm, u/R, Rbob, zAux];
Print["Fuerza exacta, variable auxiliar zAux: F = ", Fz];

Fux = Fz /. zAux -> (a - xv);
Print["Sustituyendo zAux = a - x: F(u,x) = ", Fux];

serieRbob = Series[Fz, {Rbob, 0, 2}] // Normal // FullSimplify;
Print["Limite de campo lejano (orden Rbob^2), antes de sustituir x: F -> ", serieRbob];
serieRbobX = serieRbob /. zAux -> (a - xv);
Print["Con z = a-x: F -> ", serieRbobX];

(* Confirmar que esto es EXACTAMENTE u/(b(a-x)^4) para algun b *)
bImplicito = Simplify[u/((a-xv)^4 * serieRbobX)];
Print["\nb implicito = u / [(a-x)^4 F] = ", bImplicito, "  (debe ser constante, sin u ni x)"];
