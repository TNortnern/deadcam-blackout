#!/usr/bin/env python3
"""Synthesize crisp realistic tactical horror WAV audio effects for DEADCAM: BLACKOUT."""
import wave
from pathlib import Path
import numpy as np
from scipy.signal import butter, lfilter

OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
SR = 44100


def save_wav(name: str, data: np.ndarray):
    data = np.clip(data, -0.98, 0.98)
    pcm = (data * 32767.0).astype(np.int16)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())
    print(f"  saved audio: {name}.wav ({len(data)/SR:.2f}s)")


def lowpass(x, cutoff, order=3):
    b, a = butter(order, cutoff / (SR * 0.5), btype="low")
    return lfilter(b, a, x)


def bandpass(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR * 0.5), hi / (SR * 0.5)], btype="band")
    return lfilter(b, a, x)


def gen_gunshot(name: str, dur: float, punch_hz: float, crack_decay: float, tail_decay: float, seed: int):
    rng = np.random.default_rng(seed)
    t = np.linspace(0, dur, int(SR * dur), endpoint=False)
    noise = rng.standard_normal(len(t))
    # Sharp supersonic crack
    crack = bandpass(noise, 800, 7500) * np.exp(-t * crack_decay) * 1.35
    # Chest-thumping sub punch
    freq = punch_hz * np.exp(-t * 28.0) + 42.0
    punch = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t * 16.0) * 1.15
    # Concrete/forest echo tail
    tail = lowpass(noise, 1400) * np.exp(-t * tail_decay) * 0.55
    sig = np.tanh((crack + punch + tail) * 1.6)
    save_wav(name, sig)


def gen_sfx():
    gen_gunshot("gun_pistol", 0.55, 220.0, 34.0, 6.5, 1)
    gen_gunshot("gun_rifle", 0.72, 185.0, 26.0, 5.2, 2)
    gen_gunshot("gun_shotgun", 0.95, 135.0, 18.0, 3.8, 3)

    # Flashlight click
    rng = np.random.default_rng(4)
    t = np.linspace(0, 0.08, int(SR * 0.08))
    click = bandpass(rng.standard_normal(len(t)), 1800, 6200) * np.exp(-t * 95.0)
    save_wav("flashlight_click", click * 0.9)

    # Mechanical reload clack
    t = np.linspace(0, 0.42, int(SR * 0.42))
    sig = np.zeros_like(t)
    for onset, freq in ((0.02, 2600), (0.18, 1900), (0.30, 3200)):
        m = t >= onset
        dt = t[m] - onset
        sig[m] += bandpass(rng.standard_normal(len(dt)), freq * 0.6, freq * 1.6) * np.exp(-dt * 55.0) * 0.85
    save_wav("reload_mech", sig)

    # Eerie zombie guttural rasp/growl
    t = np.linspace(0, 1.1, int(SR * 1.1))
    env = np.sin(np.pi * t / 1.1) ** 1.4
    f0 = 78.0 + 18.0 * np.sin(t * 7.5)
    vocal = np.sign(np.sin(2 * np.pi * np.cumsum(f0) / SR)) * 0.45
    rasp = bandpass(rng.standard_normal(len(t)), 280, 1100) * 0.85
    growl = lowpass((vocal + rasp) * env, 1300)
    save_wav("zombie_growl", np.tanh(growl * 1.8) * 0.85)

    # Distant thunder / dark horror ambience loop (4s)
    t = np.linspace(0, 4.0, int(SR * 4.0), endpoint=False)
    wind = lowpass(rng.standard_normal(len(t)), 220) * (0.35 + 0.15 * np.sin(2 * np.pi * t / 4.0))
    drone = np.sin(2 * np.pi * 46.0 * t) * 0.12 + np.sin(2 * np.pi * 69.0 * t) * 0.07
    save_wav("ambient_horror", (wind + drone) * 0.75)

    # Footstep crunch
    t = np.linspace(0, 0.18, int(SR * 0.18))
    step = bandpass(rng.standard_normal(len(t)), 350, 2800) * np.exp(-t * 28.0) * 0.7
    save_wav("footstep", step)


if __name__ == "__main__":
    print("Generating tactical horror audio...")
    gen_sfx()
    print("Audio done!")
