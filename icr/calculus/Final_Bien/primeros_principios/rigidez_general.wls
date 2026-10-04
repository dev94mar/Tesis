(* Generaliza la formula de rigidez (antes derivada solo para el PD) a CUALQUIER *)
(* controlador, usando su ganancia de alta frecuencia C(infinito), y predice la *)
(* amplitud del ciclo analiticamente para PI y PII, para comparar con la tabla 6.1. *)
m = 0.141; a = 7.17184; b = 1.6163*10^-6; g = 981; Fs = 20; r = -3;

Cpi[s_] := 178.136237306569*(s + 15)*(s + 12.906240226684375)/(s*(s + 400));
Cpii[s_] := 152.428*(s + 4.87511)*(s + 17.313)*(s + 1.86057)/(s^2*(s + 301.08));
CinfPI = Limit[Cpi[s], s -> Infinity];
CinfPII = Limit[Cpii[s], s -> Infinity];

kef[Cinf_] := Cinf/(b*(a - r)^4) - 4*m*g/(a - r);
kefPI = kef[CinfPI]; kefPII = kef[CinfPII];
Print["Rigidez neta k_ef, PI: ", kefPI, " kg cm/s^2 por cm"];
Print["Rigidez neta k_ef, PII: ", kefPII, " kg cm/s^2 por cm"];

(* Amplitud de ciclo predicha (orden de magnitud): 2 Fs / k_ef, el desplazamiento *)
(* que hace falta para que la fuerza en exceso Fs se reabsorba por la rigidez del lazo *)
ampPI = 2*Fs/kefPI; ampPII = 2*Fs/kefPII;
Print["Amplitud predicha (orden de magnitud), PI: ", ampPI, " cm  (tabla 6.1: 0.031 cm)"];
Print["Amplitud predicha (orden de magnitud), PII: ", ampPII, " cm  (tabla 6.1: 0.033 cm)"];
Print["Cociente predicho PII/PI: ", ampPII/ampPI, "   Cociente medido (tabla 6.1): ", 0.033/0.031 // N];
