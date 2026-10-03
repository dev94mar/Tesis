% =========================================================
% Diseño PII: datos de Bode, Nyquist y respuesta al escalón
% para las figuras TikZ/pgfplots de la tesis.
% Lazo L(s) = C(s) G(s), modelo linealizado en x* = -4 cm.
% =========================================================
clear; close all; clc

aqui  = fileparts(mfilename('fullpath'));
dest  = fullfile(aqui, '..', '..', '..', '..', 'context', 'Tesis', 'images', 'pii_design', 'tikz');
if ~exist(dest, 'dir'), mkdir(dest); end

% -----------------------------
% Planta linealizada y controlador
% -----------------------------
a = 7.17184; b = 1.6163e-6; c1 = 8.563; g = 981; m = 0.141;
xs = -4;
A = [0 1; 4*g/(a - xs) -c1];
B = [0; 1/(m*b*(a - xs)^4)];
G = tf(ss(A, B, [1 0], 0));

S = load(fullfile(aqui, 'PII_lic.mat'));
C = tf(S.C);
L = C*G;
T = feedback(L, 1);

% -----------------------------
% Márgenes
% -----------------------------
[gm, pm, wg, wp] = margin(L);
fprintf('GM = %.4f (%.2f dB) @ %.3f rad/s | PM = %.2f deg @ %.3f rad/s\n', gm, 20*log10(gm), wg, pm, wp);

% -----------------------------
% Bode
% -----------------------------
w = logspace(-2, 4, 600)';
[mag, ph] = bode(L, w);
mag = squeeze(mag); ph = squeeze(ph);
writetable(table(w, 20*log10(mag), ph, 'VariableNames', {'w','mag_db','fase'}), fullfile(dest, 'bode.csv'));
[mg_wg, ph_wg] = bode(L, wg); [mg_wp, ph_wp] = bode(L, wp);

% -----------------------------
% Nyquist (zona alrededor de -1; |L| -> inf en baja frecuencia por el doble integrador)
% -----------------------------
wn = logspace(-1, 5, 1500)';
H  = squeeze(freqresp(L, wn));
re = real(H); im = imag(H);
dentro = re > -10 & re < 2 & abs(im) < 7;
k = find(dentro);
writetable(table(re(k), im(k), 'VariableNames', {'re','im'}), fullfile(dest, 'nyquist_pos.csv'));
writetable(table(re(k), -im(k), 'VariableNames', {'re','im'}), fullfile(dest, 'nyquist_neg.csv'));
% Rodeos de -1: con P = 1 polo inestable de L, la estabilidad exige N = -1 (un rodeo antihorario)
fprintf('Polos inestables de L: %d | lazo cerrado estable: %d\n', sum(real(pole(L)) > 0), isstable(T));

% -----------------------------
% Respuesta al escalón en lazo cerrado
% -----------------------------
ts = linspace(0, 0.6, 1200)';
ys = step(T, ts);
si = stepinfo(T);
writetable(table(ts, ys, 'VariableNames', {'t','y'}), fullfile(dest, 'escalon.csv'));

% -----------------------------
% Macros con los valores (para no escribir números a mano en el .tex)
% -----------------------------
fid = fopen(fullfile(dest, 'valores.tex'), 'w');
fprintf(fid, '%% Generado por diseno_PII_tikz.m\n');
fprintf(fid, '\\def\\PIIwg{%.4f}\n\\def\\PIImgwg{%.4f}\n', wg, 20*log10(mg_wg));
fprintf(fid, '\\def\\PIIwp{%.4f}\n\\def\\PIIphwp{%.4f}\n', wp, ph_wp);
fprintf(fid, '\\def\\PIIgmdb{%.1f}\n\\def\\PIIpm{%.1f}\n', 20*log10(gm), pm);
fprintf(fid, '\\def\\PIIos{%.1f}\n\\def\\PIIts{%.3f}\n\\def\\PIItp{%.4f}\n\\def\\PIIyp{%.4f}\n', ...
    si.Overshoot, si.SettlingTime, si.PeakTime, si.Peak);
% Flechas de sentido sobre la rama w > 0 (a 30 % y 75 % de su longitud de arco)
xr = re(k); yi = im(k);
sarc = [0; cumsum(hypot(diff(xr), diff(yi)))]; sarc = sarc/sarc(end);
for f = [0.3 0.75]
    i = find(sarc >= f, 1); j = min(i + 3, numel(xr));
    fprintf(fid, '\\def\\PIIflecha%s{(%.4f,%.4f) -- (%.4f,%.4f)}\n', char('A' + (f > 0.5)), xr(i), yi(i), xr(j), yi(j));
    % rama w < 0: conjugada y recorrida en sentido contrario
    fprintf(fid, '\\def\\PIIflecha%s{(%.4f,%.4f) -- (%.4f,%.4f)}\n', char('C' + (f > 0.5)), xr(j), -yi(j), xr(i), -yi(i));
end
fclose(fid);
fprintf('OS = %.2f %% | ts = %.3f s | pico %.4f @ %.4f s\n', si.Overshoot, si.SettlingTime, si.Peak, si.PeakTime);
fprintf('CSV escritos en %s\n', dest);
