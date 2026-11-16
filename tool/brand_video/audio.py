"""Music bed + sound effects for the brand video, synthesized (no samples, no
licences). 96 BPM: one bar = 2.5 s, so every scene cut lands on a bar.
Writes tool/brand_video/build/yaani_eh_brand.wav. Timings match index.html.
"""
import os
import wave

import numpy as np

SR = 44100
DUR = 62.5
BEAT = 60 / 96
N = int(SR * DUR)
rng = np.random.default_rng(7)
L = np.zeros(N)
R = np.zeros(N)


def at(t):
    return int(t * SR)


def add(sig, t, gain=1.0, pan=0.0):
    i = at(t)
    if i >= N:
        return
    sig = sig[: N - i] * gain
    L[i:i + len(sig)] += sig * np.sqrt(0.5 * (1 - pan))
    R[i:i + len(sig)] += sig * np.sqrt(0.5 * (1 + pan))


def tvec(d):
    return np.arange(int(d * SR)) / SR


def env(d, a=0.005, rel=None, decay=None):
    t = tvec(d)
    e = np.minimum(1, t / max(a, 1e-4))
    if decay:
        e *= np.exp(-t / decay)
    if rel:
        e *= np.clip((d - t) / rel, 0, 1)
    return e


def hz(m):
    return 440 * 2 ** ((m - 69) / 12)


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def keys(m, d, vel=1.0):
    """Electric-piano-ish note: sine + soft bell partials, slow tremolo."""
    t = tvec(d)
    f = hz(m)
    s = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 3)
    s += 0.12 * np.sin(2 * np.pi * 3.01 * f * t) * np.exp(-t * 6)
    s *= 1 + 0.12 * np.sin(2 * np.pi * 4.5 * t)
    return s * env(d, 0.01, 0.4, 2.2) * vel


def pad(m, d):
    t = tvec(d)
    f = hz(m)
    s = sum(np.sin(2 * np.pi * f * (1 + dt) * t + p) for dt, p in ((0, 0), (0.003, 1), (-0.004, 2)))
    a = np.minimum(1, t / 0.8) * np.clip((d - t) / 0.8, 0, 1)
    return s * a / 3


def bass(m, d):
    t = tvec(d)
    f = hz(m)
    return (np.sin(2 * np.pi * f * t) + 0.2 * np.sin(4 * np.pi * f * t)) * env(d, 0.01, 0.15, 1.2)


def kick():
    t = tvec(0.45)
    f = 45 + 90 * np.exp(-t * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7)


def hat(d=0.06):
    n = rng.standard_normal(int(d * SR))
    n = n - lowpass(n, 6000)
    return n * env(d, 0.001, None, 0.015)


def snare():
    d = 0.25
    n = lowpass(rng.standard_normal(int(d * SR)), 5000)
    t = tvec(d)
    return (n * 0.8 + 0.4 * np.sin(2 * np.pi * 190 * t)) * np.exp(-t * 18)


def whoosh(d=0.6, up=True):
    n = rng.standard_normal(int(d * SR))
    t = tvec(d)
    cut = np.linspace(300, 4000, len(t)) if up else np.linspace(4000, 300, len(t))
    # cheap moving filter: blend two lowpasses by the sweep
    lo, hi = lowpass(n, 400), lowpass(n, 4000)
    k = (cut - 300) / 3700
    s = lo * (1 - k) + hi * k
    return s * np.sin(np.pi * t / d) ** 2


def pop(f=900, d=0.12):
    t = tvec(d)
    fr = f * (1 + 0.6 * np.exp(-t * 40))
    return np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 30)


def click():
    d = 0.03
    n = rng.standard_normal(int(d * SR))
    n = n - lowpass(n, 2500)
    return n * np.exp(-tvec(d) * 220)


def chime(m, d=1.8):
    t = tvec(d)
    f = hz(m)
    return (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * 2.76 * f * t) * np.exp(-t * 4)) * np.exp(-t * 2.2)


def pour(d):
    n = lowpass(rng.standard_normal(int(d * SR)), 1200)
    t = tvec(d)
    gurgle = 1 + 0.5 * np.sin(2 * np.pi * 7 * t + 3 * np.sin(2 * np.pi * 1.3 * t))
    return n * gurgle * np.minimum(1, t / 0.08) * np.clip((d - t) / 0.2, 0, 1)


# ---------- music ----------
# A minor, warm: Am9 · Fmaj7 · Cmaj7 · G6 (one chord per 2.5 s bar)
CHORDS = [
    (45, [57, 60, 64, 67, 71]),
    (41, [57, 60, 64, 65, 69]),
    (48, [55, 59, 60, 64, 67]),
    (43, [55, 59, 62, 64, 67]),
]
BAR = 4 * BEAT
for b in range(25):
    t0 = b * BAR
    root, notes = CHORDS[b % 4]
    last = b == 24
    pad_gain = 0.05 if b < 2 else 0.035
    for m in notes[:4]:
        add(pad(m, BAR + (1.5 if last else 0.3)), t0, pad_gain)
    if b >= 2 and not last:
        # comped keys on beat 1 and the "and" of 2
        for off, vel in ((0, 0.9), (1.5 * BEAT, 0.6), (3 * BEAT, 0.5)):
            for j, m in enumerate(notes):
                add(keys(m + 12 if j > 2 else m, 1.6, vel), t0 + off + j * 0.012, 0.045, pan=(j - 2) * 0.25)
        add(bass(root, 2 * BEAT), t0, 0.22)
        add(bass(root + 7 if b % 2 else root, 2 * BEAT), t0 + 2 * BEAT, 0.16)
        for k in range(4):
            if k in (0, 2) or (k == 3 and b % 2):
                add(kick(), t0 + k * BEAT, 0.45)
            if k in (1, 3):
                add(snare(), t0 + k * BEAT, 0.13)
            for h in range(2):
                add(hat(), t0 + k * BEAT + h * BEAT / 2 + (0.03 if h else 0), 0.05 if h else 0.035, pan=0.3)
    if last:
        for j, m in enumerate([57, 60, 64, 67, 71, 76]):
            add(keys(m, 6.0, 0.8), t0 + j * 0.06, 0.05, pan=(j - 2.5) * 0.2)
        add(bass(45, 4.0), t0, 0.2)

# hook: a clock ticking while you stare at the menu
for k in range(8):
    add(click(), k * BEAT, 0.25, pan=0.2 if k % 2 else -0.2)

# ---------- sound effects ----------
for cut in (5, 10, 17.5, 25, 35, 42.5, 50, 55):
    add(whoosh(0.7), cut - 0.55, 0.12)
add(whoosh(0.5, up=False), 30.3, 0.08)  # card flips to step by step

for i in range(7):  # «؟» popping on the menu
    add(pop(700 + i * 60), 1.7 + i * 0.17, 0.12, pan=0.4 - i * 0.12)

add(kick(), 5.05, 0.7)  # logo hit
add(chime(81, 2.5), 5.05, 0.1)
add(chime(88, 2.0), 5.12, 0.05, pan=0.3)


def typing(t0, t1, n):
    for k in range(n):
        add(click(), t0 + (t1 - t0) * k / n + rng.uniform(-0.01, 0.01), 0.18, pan=rng.uniform(-0.3, 0.3))


typing(11.7, 13.0, 12)
typing(14.8, 16.1, 12)
typing(36.0, 37.4, 14)
typing(39.6, 40.6, 10)

for t in (21.0, 22.8, 32.35, 33.75):  # taps
    add(pop(1400, 0.06), t, 0.12)

# pronunciation: soft vocal-ish blips for each syllable
for start, end, *_ in ((19.2, 20.8), (21.6, 23.0), (23.4, 25.0)):
    for k, m in enumerate((69, 72, 74, 72)):
        add(keys(m + 12, 0.3, 0.6), start + (end - start) * k / 4.4, 0.05)

for i, s in enumerate((26.2, 27.3, 28.4)):  # pouring the layers
    add(pour(1.05), s, 0.07 - i * 0.01)

for i in range(2):  # pills
    add(pop(1100, 0.08), 29.45 + i * 0.12, 0.09)

for t, m in ((44.1, 76), (45.0, 79)):  # hearts
    add(pop(600, 0.15), t, 0.2)
    add(chime(m, 0.8), t + 0.02, 0.06)
add(lowpass(rng.standard_normal(int(0.2 * SR)), 300) * np.exp(-tvec(0.2) * 15), 46.25, 0.6)  # long-press thud

t = tvec(0.5)
add(np.sin(2 * np.pi * np.cumsum(900 * np.exp(-t * 3)) / SR) * np.exp(-t * 5), 50.9, 0.07)  # wifi drops

for i in range(7):  # outro chips
    add(pop(800 + i * 70, 0.09), 56.6 + i * 0.11, 0.08, pan=-0.4 + i * 0.13)
add(chime(84, 2.5), 57.9, 0.08)
add(chime(91, 2.0), 57.95, 0.04)

# ---------- master ----------
mix = np.stack([L, R], 1)
fade = np.clip((DUR - np.arange(N) / SR) / 1.2, 0, 1) * np.clip(np.arange(N) / SR / 0.05, 0, 1)
mix *= fade[:, None]
mix = np.tanh(mix * 1.6) / np.tanh(1.6)  # gentle saturation / limiter
mix *= 0.89 / np.max(np.abs(mix))
out = os.path.join(os.path.dirname(__file__), 'build', 'yaani_eh_brand.wav')
os.makedirs(os.path.dirname(out), exist_ok=True)
with wave.open(out, 'wb') as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((mix * 32767).astype('<i2').tobytes())
print('wrote', out)
