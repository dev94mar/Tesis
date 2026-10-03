% =========================================================
% R15: familias de controladores PI y PII para comparar en igualdad de condiciones.
% Se escalan la ganancia (kK) y los ceros de baja frecuencia (alpha) de cada controlador base.
%   PII base (tesis): 152.43 (s+4.875)(s+1.861)(s+17.31) / (s^2 (s+301.1))  -> se escalan 4.875 y 1.861
%   PI  base:         178.14 (s+15)(s+12.91) / (s (s+400))                  -> se escala 12.91
% Se conservan solo los lazos estables en x* = -2, -2.5 y -3 cm con margen de fase >= 30 grados.
% Exporta los controladores discretizados (c2d, ZOH, T = 1 ms) a familias_R15.json.
% =========================================================
clear; clc
aqui = fileparts(mfilename('fullpath'));
raiz = fullfile(aqui, '..', 'inestable');
m = 0.141; a = 7.17184; b = 1.6163e-6; c1 = 8.563; g = 981; T = 1e-3;
planta = @(x) tf(ss([0 1; 4*g/(a - x) -c1], [0; 1/(m*b*(a - x)^4)], [1 0], 0));
Gs = arrayfun(planta, [-2 -2.5 -3], 'UniformOutput', false);

Spii = zpk(load(fullfile(raiz, 'PII_inestable', 'PII_lic.mat')).C);
Spi  = zpk(load(fullfile(raiz, 'PI_inestable', 'PI.mat')).C);
base = struct('PII', struct('z', Spii.Z{1}, 'p', Spii.P{1}, 'k', Spii.K, 'bajos', [-4.875 -1.861]), ...
              'PI',  struct('z', Spi.Z{1},  'p', Spi.P{1},  'k', Spi.K,  'bajos', min(abs(Spi.Z{1}))*-1));

kKs = unique([logspace(log10(0.5), log10(3), 11) 1]);
alphas = unique([logspace(log10(0.25), log10(4), 11) 1]);
out = {};
for fam = ["PII", "PI"]
    B = base.(fam);
    for kK = kKs
        for al = alphas
            z = B.z;
            for zb = B.bajos, [~, i] = min(abs(z - zb)); z(i) = z(i)*al; end
            Cz = zpk(z, B.p, B.k*kK);
            ok = true; pms = zeros(1, 3);
            for j = 1:3
                L = Cz*Gs{j}; Tcl = feedback(L, 1);
                if ~isstable(Tcl), ok = false; break; end
                [~, pm] = margin(L); pms(j) = pm;
            end
            if ~ok || min(pms) < 30, continue; end
            si = stepinfo(feedback(Cz*Gs{2}, 1));
            [A, Bm, C, D] = ssdata(c2d(ss(Cz), T, 'zoh'));
            n = size(A, 1); P = zeros(3); P(1:n, 1:n) = A; Bp = zeros(3,1); Bp(1:n) = Bm; Cp = zeros(1,3); Cp(1:n) = C;
            out{end+1} = struct('familia', char(fam), 'kK', kK, 'alpha', al, 'ceros', z', 'polos', B.p', 'k', B.k*kK, ...
                'pm_min', min(pms), 'os_lineal', si.Overshoot, 'ts_lineal', si.SettlingTime, ...
                'base', abs(kK - 1) < 1e-6 && abs(al - 1) < 1e-6, 'Ad', P, 'Bd', Bp', 'C', Cp, 'D', D); %#ok<SAGROW>
        end
    end
end
fprintf('controladores estables con MF >= 30: %d (PII %d, PI %d)\n', numel(out), ...
    sum(cellfun(@(c) strcmp(c.familia, 'PII'), out)), sum(cellfun(@(c) strcmp(c.familia, 'PI'), out)));
fid = fopen(fullfile(aqui, 'familias_R15.json'), 'w'); fprintf(fid, '%s', jsonencode(out)); fclose(fid);
