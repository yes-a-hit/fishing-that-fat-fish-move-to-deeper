"""白底立绘去背：白 -> 透明，边缘羽化，再做 alpha-bleed 防白边。

用法：python tools/cutout.py <输入.webp> <输出.webp> [阈值]
"""

import sys

import numpy as np
from PIL import Image, ImageFilter


def cutout(src: str, dst: str, soft: int = 44) -> None:
    im = Image.open(src).convert("RGBA")
    a = np.asarray(im).astype(np.float32)
    rgb = a[:, :, :3]

    # 到纯白的距离：0 = 纯白（透明），>soft = 完全不透明
    dist = np.sqrt(((255.0 - rgb) ** 2).sum(axis=2))
    alpha = np.clip((dist - soft * 0.35) / (soft * 0.65), 0.0, 1.0)

    # alpha-bleed：把颜色往不透明区域里“渗”几圈，缩放时才不会出白边
    filled = rgb.copy()
    opaque = alpha > 0.6
    for _ in range(6):
        acc = np.zeros_like(filled)
        cnt = np.zeros(alpha.shape, dtype=np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            m = np.roll(opaque, (dy, dx), axis=(0, 1)).astype(np.float32)
            acc += np.roll(filled, (dy, dx), axis=(0, 1)) * m[:, :, None]
            cnt += m
        grow = (cnt > 0) & (~opaque)
        filled[grow] = acc[grow] / cnt[grow][:, None]
        opaque = opaque | grow

    out = np.dstack([filled, alpha * 255.0]).astype(np.uint8)
    res = Image.fromarray(out, "RGBA")

    # 软化边缘（只对 alpha 做，颜色不动）
    al = res.getchannel("A").filter(ImageFilter.GaussianBlur(1.2))
    res.putalpha(al)
    res.save(dst, "WEBP", quality=92, method=6)
    print(f"{dst}  alpha>0 占比 {(alpha > 0.05).mean():.2%}")


if __name__ == "__main__":
    cutout(sys.argv[1], sys.argv[2])
