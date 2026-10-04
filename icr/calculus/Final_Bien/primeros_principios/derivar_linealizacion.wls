(* Ecuacion de movimiento, equilibrio y linealizacion, a partir de la fuerza de primeros
   principios F=u/(b(a-x)^4) (justificada en derivar_fuerza.wls) y la segunda ley de Newton,
   para contrastar simbolo a simbolo con capitulos/03_modelo.tex. *)

F[u_, x_] := u/(b*(a - x)^4);

(* Ecuacion de movimiento sin friccion: m xdd = F(u,x) - m g *)
eom = m*xdd == F[u, x] - m*g;
Print["Ecuacion de movimiento: ", eom];

(* Voltaje de equilibrio: F(ue,x) = m g *)
ueSol = Solve[F[ue, x] == m*g, ue][[1]];
Print["Voltaje de equilibrio u_e(x): ", ue /. ueSol];
Print["Comparar con eq:ue de la tesis: u_e(x) = m g b (a-x)^4"];

(* Linealizacion: variables de estado x1=x, x2=xdot; x2dot = F(u,x1)/m - g *)
f2[u_, x1_] := F[u, x1]/m - g;
A21 = D[f2[u, x1], x1] /. {u -> ue /. ueSol, x1 -> x};
A22 = 0; (* sin friccion viscosa aqui; se agrega aparte *)
B2 = D[f2[u, x1], u] /. {u -> ue /. ueSol, x1 -> x};
Print["df2/dx1 en el equilibrio (debe dar 4g/(a-x), eq:caracteristica): ", Simplify[A21]];
Print["df2/du en el equilibrio (debe dar 1/(m b (a-x)^4), coeficiente de entrada): ", Simplify[B2]];

(* Con friccion viscosa c1 (por unidad de masa), eq:mec + eq:friccion (regimen deslizante): *)
f2visc[u_, x1_, x2_] := F[u, x1]/m - g - c1*x2;
A21visc = D[f2visc[u, x1, x2], x1] /. {u -> ue /. ueSol, x1 -> x, x2 -> 0};
A22visc = D[f2visc[u, x1, x2], x2] /. {u -> ue /. ueSol, x1 -> x, x2 -> 0};
Print["Matriz de estado linealizada [0,1;",Simplify[A21visc],",",Simplify[A22visc],"]"];
Print["Comparar con icr/calculus/Final_Bien/R15_sintonizacion/familias_R15.m: [0 1; 4*g/(a-x) -c1]"];

(* Planta linealizada en x1*=-4 (eq:planta del capitulo 4): G(s) = B2 / (s^2 - A21visc s ... ) *)
(* En espacio de estados: dx/dt = A x + B u (incremental), y = x1 *)
Avisc = {{0, 1}, {A21visc, A22visc}};
Bvisc = {0, B2};
s = Symbol["s"];
Gs = Simplify[({1, 0} . Inverse[s*IdentityMatrix[2] - Avisc] . Bvisc)];
Print["G(s) simbolica: ", Gs];

(* Sustituir valores numericos del proyecto en x1*=-4 *)
valores = {m -> 0.141, a -> 7.17184, b -> 1.6163*10^-6, c1 -> 8.563, g -> 981, x -> -4};
Print["G(s) numerica en x=-4 cm: ", Gs /. valores // Simplify];
Print["Comparar con capitulos/04_controlador.tex eq:planta: G(s)=281.7/(s^2+8.563 s-351.2)"];
