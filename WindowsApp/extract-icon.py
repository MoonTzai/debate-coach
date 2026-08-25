from __future__ import annotations

import base64
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "Debate-Coach-web.html"
OUT_DIR = ROOT / "WindowsApp" / "generated"
PNG_OUT = OUT_DIR / "Debate-Coach-logo.png"
ICO_OUT = OUT_DIR / "Debate-Coach.ico"


def main() -> int:
    text = MASTER.read_text(encoding="utf-8")
    match = re.search(
        r'<img\s+class="entry-logo-img"\s+src="data:image/png;base64,([A-Za-z0-9+/=]+)"',
        text,
    )
    if not match:
        raise RuntimeError("entry-logo-img PNG data URI not found in Debate-Coach-web.html")

    data = base64.b64decode(match.group(1), validate=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PNG_OUT.write_bytes(data)

    with Image.open(PNG_OUT) as image:
        rgba = image.convert("RGBA")
        alpha = rgba.getchannel("A")
        alpha_min, alpha_max = alpha.getextrema()
        if alpha_min >= 255:
            raise RuntimeError("entry logo has no transparent pixels; refusing opaque EXE icon")
        if alpha_max <= 0:
            raise RuntimeError("entry logo is fully transparent")
        rgba.save(
            ICO_OUT,
            format="ICO",
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
        )
        print(f"source={MASTER}")
        print(f"png={PNG_OUT}")
        print(f"ico={ICO_OUT}")
        print(f"size={rgba.width}x{rgba.height}")
        print(f"alpha_min={alpha_min}")
        print(f"alpha_max={alpha_max}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
