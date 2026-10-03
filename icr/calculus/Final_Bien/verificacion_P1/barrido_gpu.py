"""Barrido en GPU (Apple Metal vía MLX) del lazo cerrado SLM + Karnopp + zona muerta.

Replica el lazo de Refactor_PII_inestable.m con el simulador corregido (P1):
planta RK4 con NSUB subpasos por periodo de muestreo T, voltaje retenido (ZOH),
sujeción de atascamiento, controlador discretizado exacto (c2d 'zoh' de MATLAB),
saturación [0, umax] y banda de zona muerta (-0.02, +0.025) V.
Cada trayectoria es una combinación (controlador, referencia final, umax).
"""
import json, sys, time
import numpy as np
import mlx.core as mx

dev = mx.gpu if len(sys.argv) < 2 or sys.argv[1] != "cpu" else mx.cpu
mx.set_default_device(dev)

m, a, b, c1, g = 0.141, 7.17184, 1.6163e-6, 8.563, 981.0
Fs, vth = 20.0, 0.02
T, NSUB = 1e-3, 10
X0, TSW, TFIN = -4.0, 5.0, 35.0

ctrl = json.load(open("controladores.json"))
names = ["PII_lic", "PII_sim", "PI"]
targets = np.round(np.arange(-5.5, -2.45, 0.05), 3)
umaxs = np.array([4.5, 5.0, 5.5, 6.0, 7.0, 8.0, 10.0, 12.0])
if len(sys.argv) > 2 and sys.argv[2] == "validar":
    targets, umaxs = np.array([-5.0, -4.5, -3.0]), np.array([5.0, 10.0])

grid = [(ci, r, um) for ci in range(len(names)) for r in targets for um in umaxs]
B = len(grid)


def pad(M, n=3):
    M = np.atleast_2d(np.array(M, dtype=np.float64))
    out = np.zeros((n, n)); out[: M.shape[0], : M.shape[1]] = M
    return out


Ad = np.stack([pad(ctrl[names[ci]]["Ad"]) for ci, _, _ in grid])
Bd = np.stack([np.pad(np.array(ctrl[names[ci]]["Bd"], float).ravel(), (0, 3 - len(ctrl[names[ci]]["Bd"]))) for ci, _, _ in grid])
Cc = np.stack([np.pad(np.array(ctrl[names[ci]]["C"], float).ravel(), (0, 3 - len(ctrl[names[ci]]["C"]))) for ci, _, _ in grid])
Dc = np.array([float(ctrl[names[ci]]["D"]) for ci, _, _ in grid])
R2 = np.array([r for _, r, _ in grid]); UM = np.array([u for _, _, u in grid])

f32 = lambda z: mx.array(z.astype(np.float32))
Ad, Bd, Cc, Dc, R2, UM = map(f32, (Ad, Bd, Cc, Dc, R2, UM))


def rhs(x, v, u):
    gap = mx.maximum(a - x, 1e-6)
    Fext = u / (b * gap**4) - m * g
    slide = mx.abs(v) > vth
    stick = mx.abs(Fext) <= Fs
    dv_slide = (Fext - m * c1 * v) / m
    dv_break = (Fext - Fs * mx.sign(Fext)) / m
    dx = mx.where(slide, v, mx.where(stick, 0.0, v))
    dv = mx.where(slide, dv_slide, mx.where(stick, 0.0, dv_break))
    return dx, dv


def paso(x, v, xc, u, uzm, zm, k):
    h = T / NSUB
    for _ in range(NSUB):
        k1x, k1v = rhs(x, v, u)
        k2x, k2v = rhs(x + h / 2 * k1x, v + h / 2 * k1v, u)
        k3x, k3v = rhs(x + h / 2 * k2x, v + h / 2 * k2v, u)
        k4x, k4v = rhs(x + h * k3x, v + h * k3v, u)
        x = x + h / 6 * (k1x + 2 * k2x + 2 * k3x + k4x)
        v = v + h / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)
    x = mx.clip(x, -50.0, a - 0.05)               # tope físico para trayectorias divergentes
    Fext = u / (b * mx.maximum(a - x, 1e-6) ** 4) - m * g
    v = mx.where((mx.abs(v) < vth) & (mx.abs(Fext) <= Fs), 0.0, v)
    moving = v != 0
    uzm = mx.where(moving, u, uzm)
    zm = moving
    R = mx.where(k * T >= TSW, R2, X0)
    e = R - x
    xc = (Ad @ xc[..., None]).squeeze(-1) + Bd * e[:, None]
    un = mx.clip((Cc * xc).sum(-1) + Dc * e, 0.0, UM)
    un = mx.where(zm & (un <= uzm + 0.025) & (un >= uzm - 0.02), uzm, un)
    return x, v, xc, un, uzm, zm, e


paso_c = mx.compile(paso)

N = int(round(TFIN / T))
ueq0 = m * g * b * (a - X0) ** 4
x = mx.full((B,), X0); v = mx.zeros((B,)); xc = mx.zeros((B, 3))
u = mx.full((B,), ueq0); uzm = u; zm = mx.zeros((B,), dtype=mx.bool_)
tail = int(5 / T)
emax = mx.zeros((B,)); sat = mx.zeros((B,)); xmin = mx.full((B,), X0); xmax = mx.full((B,), X0)
usum = mx.zeros((B,)); stick_t = mx.zeros((B,))
t0 = time.time()
for k in range(N):
    x, v, xc, u, uzm, zm, e = paso_c(x, v, xc, u, uzm, zm, mx.array(k, dtype=mx.float32))
    sat = sat + (u >= UM - 1e-4)
    xmin = mx.minimum(xmin, x); xmax = mx.maximum(xmax, x)
    stick_t = stick_t + (v == 0)
    if k >= N - tail:
        emax = mx.maximum(emax, mx.abs(e)); usum = usum + u
    if k % 500 == 0:
        mx.eval(x, v, xc, u, uzm, zm, emax, sat, xmin, xmax, usum, stick_t)
mx.eval(x, emax, sat, usum)
dt = time.time() - t0

xf = np.array(x); em = np.array(emax); sf = np.array(sat) / N; um = np.array(usum) / tail
st = np.array(stick_t) / N; xn = np.array(xmin); xx = np.array(xmax)
res = []
for i, (ci, r, umx) in enumerate(grid):
    ok = bool(np.isfinite(xf[i]) and em[i] < 0.05 and xn[i] > -20 and xx[i] < a - 0.1)
    res.append(dict(controlador=names[ci], referencia=float(r), umax=float(umx), estable=ok,
                    x_final=float(xf[i]), error_max_ult5s=float(em[i]), u_medio_ult5s=float(um[i]),
                    frac_saturado=float(sf[i]), frac_atascado=float(st[i]),
                    u_eq_referencia=float(m * g * b * (a - r) ** 4)))
out = "barrido_validar.json" if len(targets) == 3 else "barrido.json"
json.dump(dict(dispositivo=str(dev), trayectorias=B, pasos=N, subpasos=NSUB, segundos=dt, resultados=res),
          open(out, "w"), indent=1)
print(f"{B} trayectorias × {N} pasos × {NSUB} subpasos en {dt:.1f} s en {dev} → {out}")
