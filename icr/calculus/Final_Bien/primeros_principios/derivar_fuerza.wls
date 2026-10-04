(* Derivacion de primeros principios de la fuerza electromagnetica del ECP-730. *)
(* Hipotesis fisica: el embobinado se modela como un dipolo magnetico (lazo de corriente),
   el iman permanente como otro dipolo, y se usa el campo axial lejano de un dipolo (no el
   circuito de reluctancia de un electroiman cercano, que es el modelo que usa casi toda la
   literatura citada en el capitulo 3 de la tesis, con fuerza ~ i^2/gap^2). *)

(* Campo axial de un dipolo magnetico (lejos del dipolo) *)
Bz[mCoil_, z_] := (mu0/(4 Pi)) * (2 mCoil)/z^3;

(* Energia de interaccion dipolo-dipolo (dipolos alineados sobre el eje) *)
Upot[mMag_, mCoil_, z_] := -mMag*Bz[mCoil, z];

(* Fuerza = -dU/dz *)
Fdipolo[mMag_, mCoil_, z_] := Simplify[-D[Upot[mMag, mCoil, z], z]];
Print["Fuerza dipolo-dipolo (campo lejano): F(z) = ", Fdipolo[mMag, mCoil, z]];

(* El embobinado es resistivo (constante de tiempo electrica << mecanica): i = u/R, *)
(* y el momento del lazo de corriente es proporcional a la corriente: mCoil = kTurns*i *)
FdipoloU = Fdipolo[mMag, kTurns*u/R, z];
Print["Sustituyendo i=u/R, mCoil=kTurns*i: F(u,z) = ", FdipoloU];

(* Gap geometrico: z = a - x (posicion x medida hacia la bobina, igual que la tesis) *)
FdipoloX = FdipoloU /. z -> (a - x);
Print["Con z=a-x: F(u,x) = ", FdipoloX];

(* Comparacion con el modelo del fabricante que usa la tesis, eq:fld *)
Ffabricante = u/(b*(a - x)^4);
Print["Modelo del fabricante (tesis, eq:fld): F(u,x) = ", Ffabricante];

razon = Simplify[FdipoloX/Ffabricante];
Print["Cociente (debe ser una constante, sin x ni u, si las formas coinciden): ", razon];

(* Para contraste: modelo de circuito de reluctancia (electroiman cercano, como en la *)
(* literatura citada: Al-Muthair, Charara, Zhao, Zhang). Energia coenergia con L(x) con *)
(* entrehierro simple en serie. *)
Lind[x_] := mu0*nTurns^2*areaPolo/(2*(a - x));  (* reluctancia de un entrehierro simple *)
FreluctanciaI = Simplify[(1/2)*i^2*D[Lind[x], x]];
Print["Fuerza de reluctancia (electroiman cercano, i constante): F(i,x) = ", FreluctanciaI];
