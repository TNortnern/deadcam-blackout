#!/usr/bin/env python3
"""Synthesize the combat-feel, enemy and interface WAVs added in the polish pass."""
import wave
from pathlib import Path
import numpy as np
from scipy.signal import butter, lfilter

OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
SR = 44100


def save(name, data, peak=0.92):
    data = np.asarray(data, dtype=np.float64)
    m = np.max(np.abs(data)) or 1.0
    pcm = (np.clip(data / m * peak, -0.98, 0.98) * 32767.0).astype(np.int16)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())
    print(f"  {name}.wav {len(data) / SR:.2f}s")


def tt(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def lp(x, hz, order=3):
    b, a = butter(order, min(hz / (SR * 0.5), 0.99), btype="low")
    return lfilter(b, a, x)


def hp(x, hz, order=2):
    b, a = butter(order, hz / (SR * 0.5), btype="high")
    return lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR * 0.5), min(hi / (SR * 0.5), 0.99)], btype="band")
    return lfilter(b, a, x)


def fade(x, a=0.004, r=0.02):
    n = len(x)
    env = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    if na > 0:
        env[:na] = np.linspace(0, 1, na)
    if nr > 0:
        env[-nr:] = np.linspace(1, 0, nr)
    return x * env


def sweep(t, f0, f1, k):
    f = f1 + (f0 - f1) * np.exp(-t * k)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def main():
    rng = np.random.default_rng(77)

    # Blunt melee impact: a dull body thud with a short wooden knock on top
    t = tt(0.34)
    n = rng.standard_normal(len(t))
    thud = sweep(t, 150, 52, 30) * np.exp(-t * 17)
    knock = bp(n, 380, 1500) * np.exp(-t * 70) * 0.9
    crunch = bp(n, 1800, 5200) * np.exp(-t * 95) * 0.28
    save("melee_blunt", fade(np.tanh((thud * 1.5 + knock + crunch) * 1.5)))

    # Tool striking masonry or metal: bright clank with inharmonic ring
    t = tt(0.42)
    n = rng.standard_normal(len(t))
    ring = sum(np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * np.exp(-t * d) * a for f, d, a in
               [(1180, 16, 0.5), (1932, 21, 0.38), (2870, 27, 0.28), (4110, 34, 0.18), (640, 13, 0.3)])
    tick = hp(n, 2400) * np.exp(-t * 140) * 0.9
    body = sweep(t, 210, 80, 40) * np.exp(-t * 30) * 0.5
    save("melee_wall", fade(np.tanh((ring + tick + body) * 1.2)))

    # Shove: cloth rustle whoosh plus a soft body bump
    t = tt(0.26)
    n = rng.standard_normal(len(t))
    whoosh = bp(n, 300, 2400) * np.sin(np.pi * np.clip(t / 0.16, 0, 1)) ** 2 * 0.7
    bump = sweep(t, 120, 60, 22) * np.exp(-((t - 0.09) ** 2) / 0.0012) * 0.9
    save("shove", fade(whoosh + bump), 0.8)

    # Heartbeat loop: lub-dub at 100 bpm, loop length exactly one beat
    beat = 0.60
    t = tt(beat)
    def pulse(t0, f, amp):
        e = np.exp(-np.clip(t - t0, 0, None) * 26) * (t >= t0)
        return np.sin(2 * np.pi * (f * np.exp(-np.clip(t - t0, 0, None) * 9) + 34) * (t - t0)) * e * amp
    hb = lp(pulse(0.02, 74, 1.0) + pulse(0.19, 60, 0.72), 220)
    save("heartbeat", fade(hb, 0.003, 0.03), 0.9)

    # Spitter: wet hawking retch then a spat glob
    t = tt(0.62)
    n = rng.standard_normal(len(t))
    gurgle = bp(n, 180, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * 27 * t + 3 * np.sin(2 * np.pi * 6 * t))) * np.clip(t / 0.30, 0, 1) * (t < 0.36)
    spit = bp(n, 900, 5200) * np.exp(-np.clip(t - 0.36, 0, None) * 26) * (t >= 0.36) * 1.3
    voice = sweep(t, 210, 120, 3) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 43 * t))) * np.clip(t / 0.2, 0, 1) * (t < 0.38) * 0.35
    save("zombie_spit", fade(np.tanh((gurgle * 1.2 + spit + voice) * 1.4)))

    # Acid sizzle (splash landing and the lingering pool)
    t = tt(0.9)
    n = rng.standard_normal(len(t))
    hiss = hp(n, 3200) * (0.55 + 0.45 * lp(np.abs(rng.standard_normal(len(t))), 40) * 6) * np.exp(-t * 2.6)
    splat = bp(n, 250, 1600) * np.exp(-t * 34) * 1.2
    save("acid_sizzle", fade(hiss * 0.6 + splat, 0.002, 0.2), 0.75)

    # Screamer: rising, tearing shriek with vibrato and breath noise
    t = tt(1.5)
    n = rng.standard_normal(len(t))
    f = 520 + 520 * np.clip(t / 0.35, 0, 1) + 40 * np.sin(2 * np.pi * 9 * t) + 60 * lp(rng.standard_normal(len(t)), 14) * 8
    ph = 2 * np.pi * np.cumsum(f) / SR
    vox = np.sin(ph) + 0.6 * np.sin(2 * ph) + 0.42 * np.sin(3 * ph + 0.4) + 0.3 * np.sin(4.02 * ph)
    rasp = bp(n, 1500, 6500) * 0.55
    env = np.clip(t / 0.10, 0, 1) * np.exp(-np.clip(t - 1.0, 0, None) * 6)
    save("zombie_scream", fade(np.tanh((bp(vox, 400, 6000) + rasp) * env * 1.8), 0.005, 0.12))

    # Bruiser ground slam: heavy sub drop with debris rattle
    t = tt(0.85)
    n = rng.standard_normal(len(t))
    sub = sweep(t, 115, 34, 13) * np.exp(-t * 6.5) * 1.3
    crack = bp(n, 300, 2600) * np.exp(-t * 28) * 0.8
    rubble = bp(n, 900, 4200) * np.exp(-t * 6) * (0.5 + 0.5 * lp(np.abs(rng.standard_normal(len(t))), 30) * 5) * 0.16
    save("zombie_slam", fade(np.tanh((sub + crack + rubble) * 1.5), 0.002, 0.1))

    # Bullet or blade glancing off armour plate
    t = tt(0.3)
    n = rng.standard_normal(len(t))
    ring = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) * a for f, d, a in [(2350, 30, 0.5), (3710, 38, 0.4), (5220, 52, 0.25), (1460, 24, 0.3)])
    save("armor_clank", fade(ring + hp(n, 3000) * np.exp(-t * 160) * 0.8))

    # Riot visor shattering
    t = tt(0.55)
    n = rng.standard_normal(len(t))
    shards = hp(n, 4200) * np.exp(-t * 9) * (lp(np.abs(rng.standard_normal(len(t))), 60) * 7).clip(0, 1.6)
    crack = bp(n, 700, 3800) * np.exp(-t * 60) * 1.2
    save("visor_break", fade(np.tanh(shards * 0.8 + crack), 0.001, 0.1), 0.85)

    # Interface: short muted tick, purchase confirmation, denial, points tick
    t = tt(0.045)
    save("ui_click", fade(np.sin(2 * np.pi * 1450 * t) * np.exp(-t * 130) + hp(rng.standard_normal(len(t)), 3000) * np.exp(-t * 220) * 0.3, 0.001, 0.005), 0.5)
    t = tt(0.03)
    save("ui_hover", fade(np.sin(2 * np.pi * 2100 * t) * np.exp(-t * 170), 0.001, 0.004), 0.28)
    t = tt(0.32)
    buy = np.sin(2 * np.pi * 620 * t) * np.exp(-t * 22) * (t < 0.11) + np.sin(2 * np.pi * 930 * (t - 0.09)) * np.exp(-np.clip(t - 0.09, 0, None) * 13) * (t >= 0.09)
    latch = bp(rng.standard_normal(len(t)), 900, 4500) * np.exp(-t * 90) * 0.5
    save("ui_buy", fade(buy * 0.8 + latch), 0.6)
    t = tt(0.2)
    deny = (np.sign(np.sin(2 * np.pi * 150 * t)) * 0.5 + np.sin(2 * np.pi * 150 * t)) * np.exp(-t * 16)
    save("ui_deny", fade(lp(deny, 1500)), 0.5)
    t = tt(0.06)
    save("points_tick", fade(np.sin(2 * np.pi * 1880 * t) * np.exp(-t * 80) + 0.5 * np.sin(2 * np.pi * 2820 * t) * np.exp(-t * 95), 0.001, 0.008), 0.38)

    # Wave start: distant, detuned air-raid style swell (kept dry and low so it reads as diegetic)
    t = tt(2.2)
    f = 196 + 34 * np.clip(t / 1.1, 0, 1)
    ph = 2 * np.pi * np.cumsum(f) / SR
    horn = np.sin(ph) + 0.5 * np.sin(2.01 * ph) + 0.33 * np.sin(3.0 * ph) + 0.4 * np.sin(0.5 * ph)
    env = np.clip(t / 0.5, 0, 1) * np.exp(-np.clip(t - 1.3, 0, None) * 2.6)
    save("wave_start", fade(lp(horn, 1400) * env, 0.02, 0.3), 0.6)
    # Wave cleared: two soft resolving tones
    t = tt(1.1)
    a = np.sin(2 * np.pi * 392 * t) * np.exp(-t * 4.5) + 0.4 * np.sin(2 * np.pi * 784 * t) * np.exp(-t * 7)
    b2 = (np.sin(2 * np.pi * 523.25 * (t - 0.22)) * np.exp(-np.clip(t - 0.22, 0, None) * 3.6) + 0.35 * np.sin(2 * np.pi * 1046.5 * (t - 0.22)) * np.exp(-np.clip(t - 0.22, 0, None) * 6)) * (t >= 0.22)
    save("wave_clear", fade(lp(a + b2, 3200), 0.004, 0.2), 0.5)

    # Zombie grab: cloth snatch plus a guttural bark
    t = tt(0.4)
    n = rng.standard_normal(len(t))
    snatch = bp(n, 500, 3200) * np.exp(-t * 26)
    bark = sweep(t, 260, 130, 9) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 38 * t))) * np.exp(-t * 8) * 0.6
    save("zombie_grab", fade(np.tanh((snatch + lp(bark, 1800)) * 1.5)))

    # Runner pounce leap: short snarling whoosh
    t = tt(0.45)
    n = rng.standard_normal(len(t))
    wsh = bp(n, 400, 3000) * np.sin(np.pi * np.clip(t / 0.4, 0, 1)) ** 1.5
    snarl = sweep(t, 330, 190, 6) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 52 * t))) * np.clip(t / 0.08, 0, 1) * np.exp(-t * 5) * 0.55
    save("zombie_pounce", fade(np.tanh((wsh * 0.8 + lp(snarl, 2400)) * 1.5)))


if __name__ == "__main__":
    main()
