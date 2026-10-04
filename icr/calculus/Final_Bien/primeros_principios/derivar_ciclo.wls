(* Derivacion simbolica del mecanismo del ciclo limite para PI y PII, a partir de sus
   funciones de transferencia reales (no de valores ya calculados en el capitulo 6), para
   validar analiticamente si la segunda integracion ayuda o no. *)

(* Controladores de la tesis (capitulos/04_controlador.tex eq:pi, eq:pii) *)
Cpi[s_] := 178.136237306569*(s + 15)*(s + 12.906240226684375)/(s*(s + 400));
Cpii[s_] := 152.428*(s + 4.87511)*(s + 17.313)*(s + 1.86057)/(s^2*(s + 301.08));

(* 1) Ganancia de alta frecuencia C(infinito): "rigidez" instantanea del controlador, *)
(*    analoga a k_PD de la seccion eliminada, pero derivada aqui de la TF real. *)
Chf[expr_] := Limit[expr, s -> Infinity];
Print["C_PI(infinito) = ", Chf[Cpi[s]], " V/cm"];
Print["C_PII(infinito) = ", Chf[Cpii[s]], " V/cm"];

(* 2) Desarrollo de Laurent en s=0 para extraer Ki y Kii directamente de las TF reales *)
seriePI = Series[Cpi[s], {s, 0, 1}] // Normal;
seriePII = Series[Cpii[s], {s, 0, 1}] // Normal;
Print["PI cerca de s=0: C_PI(s) ~ ", seriePI];
Print["PII cerca de s=0: C_PII(s) ~ ", seriePII];

KiPI = Coefficient[seriePI /. s -> 1/w, w, 1] // Simplify;
KiPII = Coefficient[Series[Cpii[s]*s^2, {s, 0, 0}] // Normal, s, 0];
KiiPII = Limit[Cpii[s]*s^2, s -> 0];
KlinPII = Limit[(Cpii[s] - KiiPII/s^2)*s, s -> 0];
Print["K_i del PI (comparar con 86.2 V/(cm s) del capitulo 6): ", KiPI];
Print["K_ii del PII (comparar con 79.5 V/(cm s^2)): ", KiiPII];
Print["K_i del PII, termino lineal (comparar con 63.4 V/(cm s)): ", KlinPII];

(* 3) Duracion del atascamiento: tiempo para que el controlador cambie el voltaje Du  *)
(*    necesario para romper la banda de friccion estatica, con error constante e0.    *)
(* PI: Du(t) = Ki e0 t -> t_rotura = Du/(Ki e0) *)
tPI = Du/(KiPI*e0);
Print["Duracion del atascamiento, PI (forma cerrada): t = ", tPI];

(* PII: Du(t) = (Ki e0 + Kii q0) t + (Kii e0/2) t^2, resolviendo para Du con q0=0 *)
tPII = Solve[(KlinPII*e0)*t + (KiiPII*e0/2)*t^2 == Du, t];
Print["Duracion del atascamiento, PII (q0=0), raices: ", tPII];
tPIIpos = t /. Select[tPII, (t /. #) > 0 &][[1]];
Print["Raiz positiva: t = ", Simplify[tPIIpos]];

(* 4) Evaluar numericamente con los valores del capitulo 6: Du=0.346 V promedio, *)
(*    e0_PI=0.0151 cm, e0_PII se toma igual para comparar el MISMO error de atascamiento *)
Print[""];
Print["--- Evaluacion numerica, mismo e0=0.0151 cm, Du=0.346 V, q0=0 para ambos ---"];
Print["t_PI = ", tPI /. {Du -> 0.346, e0 -> 0.0151}, " s  (tesis: 0.25 s medido)"];
Print["t_PII = ", tPIIpos /. {Du -> 0.346, e0 -> 0.0151}, " s"];
Print["Cociente t_PII/t_PI con el MISMO e0: ", (tPIIpos /. {Du -> 0.346, e0 -> 0.0151})/(tPI /. {Du -> 0.346, e0 -> 0.0151})];
Print["(el capitulo 6 mide e0 distinto para cada uno; este cociente aisla el efecto de Ki/Kii solos)"];
