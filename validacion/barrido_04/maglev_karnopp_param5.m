function dy = maglev_karnopp_param5(~, y, u, a, b, c1, m, g, Fs)
% Copia parametrizada de maglev_karnopp.m (icr/calculus/Final_Bien/inestable/PII_inestable)
% para el sondeo de sensibilidad completo de validacion/barrido_04/sensibilidad_planta_completa.m.
% Misma fisica que maglev_karnopp_param.m, pero con Fs tambien como argumento
% (ahi estaba fijo en 20) para poder perturbar los 5 parametros de planta.
vth = 0.02;

x = y(1);
v = y(2);

gap = max(a - x, 1e-6);
Fext = u / (b * gap^4) - m*g;

if abs(v) > vth
    dx = v;
    Ff = m * c1 * v;
    dv = (Fext - Ff)/m;
else
    if abs(Fext) <= Fs
        dx = 0;
        dv = 0;
    else
        dx = v;
        dv = (Fext - Fs * sign(Fext))/m;
    end
end

dy = [dx; dv];
end
