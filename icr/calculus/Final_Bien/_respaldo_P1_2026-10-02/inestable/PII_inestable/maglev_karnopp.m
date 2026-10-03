function dy = maglev_karnopp(~, y, u)

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
Fext = u / (b * m * gap^4) - m*g;

if abs(v) > vth
    % -------- Sliding --------
    dx = v;
    Ff = c1 * abs(v);
    dv = (Fext - Ff)/m;

else
    % -------- Sticking Region --------
    if abs(Fext) <= Fs
        % Stick: zero velocity & zero accel
        dx = 0;
        dv = 0;
    else
        % Breakaway
        dx = 0;
        dv = (Fext - Fs * sign(Fext))/m;
    end
end

dy = [dx; dv];
end
