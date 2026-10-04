(* Modelo energetico (lagrangiano y hamiltoniano, SIN disipacion) cuyas ecuaciones
   de movimiento reproducen exactamente la fuerza del modelo de la tesis,
   f_fld(u,x) = u/[b(a-x)^4] (eq:fld), sin friccion (c1=0), es decir
   m xdd = f_fld(u,x) - m g. El voltaje u se trata como parametro externo
   (cuasi-estatico, bobina resistiva: ver derivar_fuerza.wls), no como variable
   dinamica propia; es la coenergia magnetica W'(x,u), no la energia W(x,lambda),
   la que entra en el lagrangiano, como es estandar en sistemas electromecanicos
   con corriente (o aqui voltaje, via i=u/R) como variable independiente. *)

x[t]; xdd := D[x[t], {t, 2}];

(* 1) Fuerza del modelo de la tesis (adoptada del fabricante, eq:fld) *)
Ffld[u_, xv_] := u/(b*(a - xv)^4);
Print["f_fld(u,x) = ", Ffld[u, xv]];

(* 2) Coenergia magnetica W'(x,u) tal que dW'/dx = f_fld(u,x) *)
Wco[xv_, u_] := Integrate[Ffld[u, s], {s, 0, xv}] // Simplify;
Wco2[xv_, u_] := u/(3*b*(a - xv)^3);  (* forma cerrada, salvo una constante en xv *)
Print["Coenergia W'(x,u) (forma cerrada, hasta una constante): ", Wco2[xv, u]];
Print["Verificacion dW'/dx = f_fld: ", Simplify[D[Wco2[xv, u], xv] - Ffld[u, xv]] == 0];

(* 3) Lagrangiano: L = T - V_grav + W'(x,u), con V_grav = m g x (x crece hacia *)
(*    la bobina, igual que en el capitulo 3) y SIN termino de friccion (c1=0). *)
L = (1/2)*m*xdd1^2 - m*g*x1 + Wco2[x1, u] /. {xdd1 -> xdot, x1 -> xpos};
LL[xpos_, xdot_] := (1/2)*m*xdot^2 - m*g*xpos + Wco2[xpos, u];
Print["\nLagrangiano L(x,xdot) = ", LL[xpos, xdot]];

(* Ecuacion de Euler-Lagrange: d/dt(dL/dxdot) - dL/dx = 0, con x=x(t) *)
Lsym = LL[x[t], x'[t]];
EL = D[D[Lsym, x'[t]], t] - D[Lsym, x[t]] == 0;
ELexpand = EL /. Derivative[2][x][t] -> xddsym // Simplify;
Print["Ecuacion de Euler-Lagrange: ", ELexpand];

elResuelta = Solve[ELexpand, xddsym][[1]];
Print["Despejando la aceleracion: m xdd = ", Simplify[m*xddsym /. elResuelta]];
Print["Comparar con eq:mec sin friccion: m xdd = f_fld(u,x) - m g = ", Simplify[Ffld[u, x[t]] - m*g]];
coincideEL = Simplify[(m*xddsym /. elResuelta) - (Ffld[u, x[t]] - m*g)] == 0;
Print["¿Coinciden exactamente? ", coincideEL];

(* 4) Formulacion hamiltoniana: momento canonico, transformada de Legendre y *)
(*    ecuaciones de Hamilton, como verificacion cruzada independiente. *)
Print["\n--- Hamiltoniano ---"];
pcan = D[LL[xpos, xdot], xdot];
Print["Momento canonico p = dL/dxdot = ", pcan];
xdotFromP = Solve[pcan == psym, xdot][[1]];
Print["xdot(p) = ", xdot /. xdotFromP];

Ham = (psym*xdot - LL[xpos, xdot]) /. xdotFromP // Simplify;
Print["Hamiltoniano H(x,p) = p xdot - L = ", Ham];

xdotH = D[Ham, psym];
pdotH = -D[Ham, xpos];
Print["Ecuaciones de Hamilton:"];
Print["  dx/dt = dH/dp = ", xdotH];
Print["  dp/dt = -dH/dx = ", pdotH];

(* Combinando: d/dt(dx/dt) = d/dt(p/m) = (dp/dt)/m = pdotH/m, y como p=m xdot, *)
(* xdd = pdotH/m. Verificar que coincide con el modelo de la tesis. *)
xddHam = Simplify[pdotH /. {psym -> m*xdot}];
Print["m xdd = m*(dp/dt)/m = ", Simplify[pdotH]];
coincideHam = Simplify[pdotH - (Ffld[u, xpos] - m*g)] == 0;
Print["¿Coincide con f_fld(u,x) - m g? ", coincideHam];

Print["\n=== RESULTADO FINAL ==="];
Print["Euler-Lagrange reproduce el modelo de la tesis (sin friccion): ", coincideEL];
Print["Hamilton reproduce el modelo de la tesis (sin friccion):       ", coincideHam];
