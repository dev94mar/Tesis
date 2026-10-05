function dy = maglev_karnopp_param(~, y, u, a, b, c1, m, g)
% Copia parametrizada de maglev_karnopp.m (icr/calculus/Final_Bien/inestable/PII_inestable)
% para el sondeo de sensibilidad de validacion/barrido_04/sensibilidad_planta.m.
% Misma fisica, con a,b,c1,m,g como argumentos en vez de constantes fijas.
Fs  = 20;
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
