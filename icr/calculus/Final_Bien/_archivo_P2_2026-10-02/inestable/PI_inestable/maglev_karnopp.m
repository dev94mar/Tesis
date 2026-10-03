function dy = maglev_karnopp(~, y, u)
% Planta no lineal del SLM ECP-730 (configuración atractiva) con fricción de Karnopp.
%
%   m*dv = u/(b*(a-x)^4) - m*g - m*c1*v      (deslizamiento)
%
% Consistente con el modelo linealizado (linealization_inestable.m):
%   dx2 = u/(m*b*(a-x1)^4) - g - c1*x2
% c1 es fricción viscosa POR UNIDAD DE MASA (Hernández Alcántara, 2010).
% Fuerzas en kg*cm/s^2 (m*g = 138.3); Fs en las mismas unidades.
%
% Corrección P1 (2026-10-02):
%   - la fuerza magnética se dividía entre m dos veces (u/(b*m*gap^4));
%   - la fricción viscosa c1*|v| no se oponía al movimiento con v < 0
%     y no estaba escalada por la masa.

m  = 0.141;
a  = 7.17184;
b  = 1.6163e-6;
c1 = 8.563;
g  = 981;

Fs  = 20;       % static friction
vth = 0.02;     % band

x = y(1);
v = y(2);

gap = max(a - x, 1e-6);
Fext = u / (b * gap^4) - m*g;

if abs(v) > vth
    % -------- Sliding --------
    dx = v;
    Ff = m * c1 * v;
    dv = (Fext - Ff)/m;

else
    % -------- Sticking Region --------
    if abs(Fext) <= Fs
        % Stick: zero velocity & zero accel
        dx = 0;
        dv = 0;
    else
        % Breakaway
        dx = v;
        dv = (Fext - Fs * sign(Fext))/m;
    end
end

dy = [dx; dv];
end
