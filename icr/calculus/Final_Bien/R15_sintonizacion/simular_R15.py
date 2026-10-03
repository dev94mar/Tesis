"""R15: simula en GPU (MLX) las familias PI y PII de familias_R15.json en dos pruebas.

  escalon: -2 -> -3 cm en t = 5 s
  rampa:   desde -2 cm, en t = 5 s rampa de -0.05 cm/s durante 20 s hasta -3 cm

Lazo idéntico a regulacion_P4.m: planta corregida (P1) con Karnopp, controlador discreto ZOH,
saturación [0, 3.5] V, banda de zona muerta (-0.02, +0.025) V y arranque sin salto.
Uso: python simular_R15.py  ->  resultados_R15.json
"""
import json
import time

import mlx.core as mx
import numpy as np

mx.set_default_device(mx.gpu)
m, a, b, c1, g = 0.141, 7.17184, 1.6163e-6, 8.563, 981.0
Fs, vth, T, NSUB, UMAX = 20.0, 0.02, 1e-3, 10, 3.5
TFIN, T0 = 35.0, 5.0
VENT_A = (25.0, 35.0)      # estado estacionario del escalón
VENT_B = (10.0, 25.0)      # rampa, sin sus primeros 5 s

ctrl = json.load(open("familias_R15.json"))
casos = [(i, p) for i in range(len(ctrl)) for p in ("escalon", "rampa")]
B = len(casos)
Ad = np.array([ctrl[i]["Ad"] for i, _ in casos], float)
Bd = np.array([np.ravel(ctrl[i]["Bd"]) for i, _ in casos], float)
Cc = np.array([np.ravel(ctrl[i]["C"]) for i, _ in casos], float)
Dc = np.array([float(ctrl[i]["D"]) for i, _ in casos])
RAMPA = np.array([p == "rampa" for _, p in casos])

x0 = -2.0
ueq0 = m * g * b * (a - x0) ** 4
XC0 = np.zeros((B, 3))
for k in range(B):                       # estado estacionario del controlador con u = u_eq
    M = np.vstack([Ad[k] - np.eye(3), Cc[k][None, :]])
    XC0[k] = np.linalg.lstsq(M, np.r_[np.zeros(3), ueq0], rcond=None)[0]

f32 = lambda z: mx.array(np.asarray(z, dtype=np.float32))
Ad, Bd, Cc, Dc, XC0 = map(f32, (Ad, Bd, Cc, Dc, XC0))
RAMPA = mx.array(RAMPA)


def rhs(x, v, u):
    Fext = u / (b * mx.maximum(a - x, 1e-6) ** 4) - m * g
    slide = mx.abs(v) > vth
    stick = mx.abs(Fext) <= Fs
    dv = mx.where(slide, (Fext - m * c1 * v) / m, mx.where(stick, 0.0, (Fext - Fs * mx.sign(Fext)) / m))
    dx = mx.where(slide, v, mx.where(stick, 0.0, v))
    return dx, dv


def referencia(t):
    esc = mx.where(t >= T0, -3.0, -2.0)
    ram = mx.clip(-2.0 - 0.05 * mx.maximum(t - T0, 0.0), -3.0, -2.0)
    return mx.where(RAMPA, ram, esc)


def paso(x, v, xc, u, uzm, t):
    h = T / NSUB
    for _ in range(NSUB):
        k1x, k1v = rhs(x, v, u)
        k2x, k2v = rhs(x + h / 2 * k1x, v + h / 2 * k1v, u)
        k3x, k3v = rhs(x + h / 2 * k2x, v + h / 2 * k2v, u)
        k4x, k4v = rhs(x + h * k3x, v + h * k3v, u)
        x = x + h / 6 * (k1x + 2 * k2x + 2 * k3x + k4x)
        v = v + h / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)
    x = mx.clip(x, -50.0, a - 0.05)
    Fext = u / (b * mx.maximum(a - x, 1e-6) ** 4) - m * g
    v = mx.where((mx.abs(v) < vth) & (mx.abs(Fext) <= Fs), 0.0, v)
    moving = v != 0
    uzm = mx.where(moving, u, uzm)
    e = referencia(t) - x
    xc = (Ad @ xc[..., None]).squeeze(-1) + Bd * e[:, None]
    un = mx.clip((Cc * xc).sum(-1) + Dc * e, 0.0, UMAX)
    un = mx.where(moving & (un <= uzm + 0.025) & (un >= uzm - 0.02), uzm, un)
    return x, v, xc, un, uzm, e


paso_c = mx.compile(paso)
N = int(round(TFIN / T))
x = mx.full((B,), x0); v = mx.zeros((B,)); xc = XC0 * 1.0
u = mx.full((B,), ueq0); uzm = u * 1.0
z = lambda: mx.zeros((B,))
xmin_esc = mx.full((B,), x0); xA_min = mx.full((B,), 99.0); xA_max = mx.full((B,), -99.0)
atA, epA, emaxA = z(), z(), z()
eB_sum, eB_sq, atB, epB = z(), z(), z(), z()
umax_t, sat, prev_at = z(), z(), mx.zeros((B,), dtype=mx.bool_)
t0 = time.time()
for k in range(N):
    t = k * T
    x, v, xc, u, uzm, e = paso_c(x, v, xc, u, uzm, mx.array(t, dtype=mx.float32))
    at = v == 0
    nuevo = at & ~prev_at
    prev_at = at
    umax_t = mx.maximum(umax_t, u); sat = sat + (u >= UMAX - 1e-4)
    if t >= T0:
        xmin_esc = mx.minimum(xmin_esc, x)
    if VENT_A[0] <= t < VENT_A[1]:
        xA_min = mx.minimum(xA_min, x); xA_max = mx.maximum(xA_max, x)
        atA = atA + at; epA = epA + nuevo; emaxA = mx.maximum(emaxA, mx.abs(e))
    if VENT_B[0] <= t < VENT_B[1]:
        eB_sum = eB_sum + e; eB_sq = eB_sq + e * e; atB = atB + at; epB = epB + nuevo
    if k % 500 == 0:
        mx.eval(x, v, xc, u, uzm, xmin_esc, xA_min, xA_max, atA, epA, emaxA, eB_sum, eB_sq, atB, epB, umax_t, sat, prev_at)
mx.eval(x, xmin_esc, xA_min, xA_max, atA, epA, emaxA, eB_sum, eB_sq, atB, epB, umax_t, sat)
dt = time.time() - t0

A = lambda q: np.array(q, dtype=float)
nA, nB = (VENT_A[1] - VENT_A[0]) / T, (VENT_B[1] - VENT_B[0]) / T
xf, xme, xa0, xa1 = A(x), A(xmin_esc), A(xA_min), A(xA_max)
atA, epA, emaxA, eBs, eBq, atB, epB, um, st = map(A, (atA, epA, emaxA, eB_sum, eB_sq, atB, epB, umax_t, sat))
res = []
for k, (i, p) in enumerate(casos):
    c = ctrl[i]
    r = dict(familia=c["familia"], kK=c["kK"], alpha=c["alpha"], base=c["base"], prueba=p, pm_min=c["pm_min"],
             os_lineal=c["os_lineal"], u_max=um[k], frac_saturado=st[k] / N, diverge=bool(xf[k] < -20 or not np.isfinite(xf[k])))
    if p == "escalon":
        r.update(sobrepaso_pct=100 * (-3 - xme[k]), ciclo_pp_cm=xa1[k] - xa0[k], error_max_cm=emaxA[k],
                 frac_atascado=atA[k] / nA, atasc_medio_s=(atA[k] * T / epA[k]) if epA[k] else float("nan"))
    else:
        r.update(error_medio_rampa_cm=eBs[k] / nB, error_rms_rampa_cm=float(np.sqrt(eBq[k] / nB)),
                 frac_atascado=atB[k] / nB, atasc_medio_s=(atB[k] * T / epB[k]) if epB[k] else float("nan"))
    res.append(r)
json.dump(dict(trayectorias=B, segundos=dt, resultados=res), open("resultados_R15.json", "w"), indent=1)
print(f"{B} trayectorias en {dt:.1f} s")
