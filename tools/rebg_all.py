"""把所有还没去背的立绘批量抠一遍，输出同目录的 *_cut.webp。

跑在 ComfyUI 的 venv 里（装了 rembg + onnxruntime）。
"""

import os
import sys

from PIL import Image
from rembg import new_session, remove

ROOT = r"E:\godot_workplace\测试\assets\art\cast"
SESSION = new_session("u2net")


def main() -> None:
    todo = []
    for dirpath, _d, files in os.walk(ROOT):
        for f in sorted(files):
            if not f.endswith(".webp") or f.endswith("_cut.webp"):
                continue
            src = os.path.join(dirpath, f)
            dst = os.path.join(dirpath, f[:-5] + "_cut.webp")
            if os.path.exists(dst):
                continue
            todo.append((src, dst))

    print("待抠 %d 张" % len(todo))
    for i, (src, dst) in enumerate(todo, 1):
        try:
            im = Image.open(src).convert("RGBA")
            out = remove(im, session=SESSION)
            out.save(dst, "WEBP", quality=92, method=6)
            print("[%d/%d] %s" % (i, len(todo), os.path.basename(dst)))
        except Exception as e:  # noqa: BLE001
            print("[%d/%d] 失败 %s: %s" % (i, len(todo), src, e), file=sys.stderr)
    print("完成")


if __name__ == "__main__":
    main()
