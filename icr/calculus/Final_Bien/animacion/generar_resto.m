aqui = fileparts(mfilename('fullpath'));
% Senoidal: 2000 s, r(t)=-2.5+0.5sin(2*pi*0.001*t), periodo 1000 s. Denso al
% inicio para mostrar el arranque, disperso despues (el ciclo limite es
% practicamente estacionario desde el principio).
animar_caso('seguimiento_P5_sen', fullfile(aqui,'senoidal.gif'), 2000, ...
    [0 60 0.5; 60 2000 0.5], [-3.3 -1.9]);

% Trapezoidal: 2500 s, planos de 250s + rampas de 250s, periodo 1250s.
% Denso en el primer periodo completo para mostrar rampa+plano+rampa.
animar_caso('seguimiento_P5_trap', fullfile(aqui,'trapezoidal.gif'), 2500, ...
    [0 250 0.08; 250 1260 0.62; 1260 2500 0.30], [-3.3 -1.9]);

% Diente de sierra: 2500 s, periodo 250s, reinicio instantaneo. Denso en
% los primeros 3 periodos para mostrar varios reinicios.
animar_caso('seguimiento_P5_diente', fullfile(aqui,'diente.gif'), 2500, ...
    [0 760 0.55; 760 2500 0.45], [-3.2 -1.6]);

% Pulso cuadrado: 2500 s, periodo 500s. Denso en los primeros 2 periodos.
animar_caso('seguimiento_P5_pulso', fullfile(aqui,'pulso.gif'), 2500, ...
    [0 1010 0.55; 1010 2500 0.45], [-3.35 -1.6]);
