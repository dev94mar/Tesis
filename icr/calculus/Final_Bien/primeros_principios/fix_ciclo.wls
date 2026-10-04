Cpii[s_] := 152.428*(s + 4.87511)*(s + 17.313)*(s + 1.86057)/(s^2*(s + 301.08));
KiiPII = Limit[Cpii[s]*s^2, s -> 0];
KlinPII = Limit[(Cpii[s] - KiiPII/s^2)*s, s -> 0];

Cpi[s_] := 178.136237306569*(s + 15)*(s + 12.906240226684375)/(s*(s + 400));
KiPI = Limit[Cpi[s]*s, s -> 0];

(* Ecuacion cuadratica evaluada con numeros desde el inicio *)
e0val = 0.0151; Duval = 0.346;
sol = Solve[(KlinPII*e0val)*t + (KiiPII*e0val/2)*t^2 == Duval, t];
Print["Raices (numerico): ", sol];
tpos = Select[t /. sol, # > 0 &][[1]];
Print["t_PII (mismo e0 que el PI) = ", tpos, " s"];

tPIval = Duval/(KiPI*e0val);
Print["t_PI (mismo Du, e0) = ", tPIval, " s"];
Print["Cociente t_PII/t_PI, MISMO e0 para ambos: ", tpos/tPIval];
Print[""];
Print["Con los e0 realmente medidos en cada controlador (tesis: e0_PI=0.0151, e0_PII=?):"];
(* Para el PII, resolver tambien con su propio e0 observado si se conoce; aqui se deja *)
(* con el mismo e0 para aislar el efecto de la estructura del controlador. *)
