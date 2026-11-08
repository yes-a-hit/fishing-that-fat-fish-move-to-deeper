"""用 rembg（u2net）把立绘真抠成透明底，再补 alpha-bleed。

必须在 ComfyUI 的 venv 里跑：
  E:\\Comfy-Desktop\\ComfyUI-Installs\\ComfyUI\\ComfyUI\\.venv\\Scripts\\python.exe tools/rembg_cut.py
"""

import io
import os
import sys

import numpy as np
from PIL import Image
from rembg import new_session, remove

ART = r"E:\godot_workplace\测试\assets\art\cast"
TARGETS = [
    r"ch2\chatgpt\full.webp",
    r"ch1\big\default.webp",
    r"ch1\mid\default.webp",
    r"ch2\claude\helm.webp",
]


def bleed(img: Image.Image) -> Image.Image:
    a = np.asarray(img.convert("RGBA")).astype(np.float32)
    rgb, al = a[:, :, :3], a[:, :, 3] / 255.0
    filled = rgb.copy()
    solid = al > 0.6
    for _ in range(8):
        acc = np.zeros_like(filled)
        cnt = np.zeros(al.shape, dtype=np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            m = np.roll(solid, (dy, dx), axis=(0, 1)).astype(np.float32)
            acc += np.roll(filled, (dy, dx), axis=(0, 1)) * m[:, :, None]
            cnt += m
        grow = (cnt > 0) & (~solid)
        filled[grow] = acc[grow] / cnt[grow][:, None]
        solid = solid | grow
    out = np.dstack([filled, al * 255.0]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def main() -> None:
    session = new_session("u2net")
    for rel in TARGETS:
        src = os.path.join(ART, rel)
        if not os.path.exists(src):
            print("missing", src)
            continue
        im = Image.open(src).convert("RGB")
        cut = remove(im, session=session, alpha_matting=False)
        cut = bleed(cut)
        dst = src[:-5] + "_cut.webp"
        cut.save(dst, "WEBP", quality=92, method=6)
        cov = (np.asarray(cut)[:, :, 3] > 12).mean()
        print(f"{os.path.basename(dst):22s} 覆盖 {cov:.1%}  {cut.size}")


if __name__ == "__main__":
    main()
