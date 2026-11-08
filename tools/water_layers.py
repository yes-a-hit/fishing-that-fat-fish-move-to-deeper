"""重制水层：一截同色的水 + 悬浮颗粒 + 光柱，不含海底、不承担深度信息。

三条硬要求：
1. 不出现海底、礁石、船骸——任何具体地貌都不画；
2. 纵向 repeat 无接缝——整张只有 ±3% 的呼吸感，首尾同色；
3. 层与层之间不需要对应——每张都是独立的一截水，深浅靠色相区分，
   真正「越往下越暗」交给运行时按深度调暗（不要在贴图里画死）。

用法：python tools/water_layers.py
"""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = r"E:\godot_workplace\测试"
OUT_DIR = os.path.join(ROOT, "assets", "art", "cg", "ch2", "water")
W, H = 1216, 1024

# 每层：(基色, 光柱强度, 颗粒数)
LAYERS = {
    "shallow": ((0x62, 0xC4, 0xDA), 0.55, 260),
    "mid": ((0x24, 0x84, 0xA4), 0.26, 180),
    "deep": ((0x0A, 0x36, 0x4C), 0.08, 120),
    "seattle": ((0x3C, 0x4E, 0x57), 0.14, 220),
}


def base_water(base):
    t = np.linspace(0.0, 1.0, H, dtype=np.float32)
    breath = (1.0 + 0.03 * np.sin(t * math.pi * 2.0))[:, None]
    col = np.zeros((H, W, 3), dtype=np.float32)
    for i in range(3):
        col[:, :, i] = base[i] * breath
    return col


def add_grain(img, rng, count):
    layer = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        x = int(rng.integers(0, W))
        y = int(rng.integers(0, H))
        r = int(rng.integers(1, 4))
        a = int(rng.integers(20, 70))
        d.ellipse((x - r, y - r, x + r, y + r), fill=a)
    layer = layer.filter(ImageFilter.GaussianBlur(0.6))
    arr = np.asarray(layer, dtype=np.float32)[:, :, None] / 255.0
    return img + arr * 120.0


def add_shafts(img, strength, rng):
    if strength <= 0.01:
        return img
    layer = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(layer)
    for _ in range(5):
        x = int(rng.integers(-200, W))
        wide = int(rng.integers(60, 190))
        a = int(40 * strength + rng.integers(0, 25))
        d.polygon([(x, -40), (x + wide, -40),
                   (x + wide - 180, H + 40), (x - 180, H + 40)], fill=a)
    layer = layer.filter(ImageFilter.GaussianBlur(46))
    arr = np.asarray(layer, dtype=np.float32)[:, :, None] / 255.0
    return img + arr * (150.0 * strength)


def vignette(img, strength=0.22):
    x = np.linspace(-1, 1, W, dtype=np.float32)[None, :]
    y = np.linspace(-1, 1, H, dtype=np.float32)[:, None]
    r = np.sqrt(x * x * 0.55 + y * y)
    v = np.clip(1.0 - strength * r, 0.60, 1.0)
    return img * v[:, :, None]


def build(name, base, shaft, grains):
    rng = np.random.default_rng(abs(hash(name)) % (2 ** 32))
    img = base_water(base)
    img = add_shafts(img, shaft, rng)
    img = add_grain(img, rng, grains)
    img = vignette(img)
    return np.clip(img, 0, 255).astype(np.uint8)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, (base, shaft, grains) in LAYERS.items():
        arr = build(name, base, shaft, grains)
        im = Image.fromarray(arr)
        path = os.path.join(OUT_DIR, "layer_%s.webp" % name)
        im.save(path, "WEBP", quality=92, method=6)
        gap = float(np.abs(arr[0].astype(np.float32) - arr[-1].astype(np.float32)).max())
        print("%-8s %s  顶/底最大色差 %.1f" % (name, im.size, gap))


if __name__ == "__main__":
    main()
