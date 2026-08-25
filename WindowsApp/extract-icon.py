from __future__ import annotations

import base64
import re
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "Debate-Coach-web.html"
OUT_DIR = ROOT / "WindowsApp" / "generated"
PNG_OUT = OUT_DIR / "Debate-Coach-logo.png"
ICON_PNG_OUT = OUT_DIR / "Debate-Coach-icon.png"
ICO_OUT = OUT_DIR / "Debate-Coach.ico"


def largest_alpha_component_mask(
    alpha: Image.Image,
    *,
    threshold: int = 64,
) -> tuple[Image.Image, tuple[int, int, int, int], int]:
    """Return a mask, bounding box and area for the dominant visible component."""
    width, height = alpha.size
    pixels = alpha.load()
    visited = bytearray(width * height)
    best_bbox: tuple[int, int, int, int] | None = None
    best_area = 0
    best_members: list[int] = []

    for y in range(height):
        row = y * width
        for x in range(width):
            start = row + x
            if visited[start] or pixels[x, y] <= threshold:
                continue

            visited[start] = 1
            queue = deque([start])
            members: list[int] = []
            min_x = max_x = x
            min_y = max_y = y

            while queue:
                pos = queue.popleft()
                members.append(pos)
                py, px = divmod(pos, width)
                min_x = min(min_x, px)
                max_x = max(max_x, px)
                min_y = min(min_y, py)
                max_y = max(max_y, py)

                for nx, ny in (
                    (px - 1, py),
                    (px + 1, py),
                    (px, py - 1),
                    (px, py + 1),
                    (px - 1, py - 1),
                    (px + 1, py - 1),
                    (px - 1, py + 1),
                    (px + 1, py + 1),
                ):
                    if nx < 0 or nx >= width or ny < 0 or ny >= height:
                        continue
                    neighbor = ny * width + nx
                    if visited[neighbor] or pixels[nx, ny] <= threshold:
                        continue
                    visited[neighbor] = 1
                    queue.append(neighbor)

            area = len(members)
            if area > best_area:
                best_area = area
                best_members = members
                best_bbox = (min_x, min_y, max_x + 1, max_y + 1)

    if best_bbox is None:
        raise RuntimeError("entry logo has no visible alpha component")

    mask = Image.new("L", alpha.size, 0)
    mask_pixels = mask.load()
    for pos in best_members:
        py, px = divmod(pos, width)
        mask_pixels[px, py] = 255
    return mask, best_bbox, best_area


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
        full_bbox = alpha.getbbox()
        if full_bbox is None:
            raise RuntimeError("entry logo has no visible alpha bounds")
        # The entry logo also contains a detached A3 wordmark in the upper-right.
        # Using the full alpha bbox makes that small detached element determine
        # the EXE icon scale, leaving the actual mascot visibly undersized even
        # inside a valid 256x256 ICO frame.  Desktop icons should use the main
        # brand mark, so isolate the dominant connected component.  Connectivity
        # is detected above a modest alpha threshold so faint anti-alias noise
        # cannot bridge the detached wordmark into the mascot.  Dilate the chosen
        # mask slightly before multiplying it by the original alpha channel so
        # the mascot keeps its antialiased edge pixels without retaining A3.
        component_mask, component_bbox, icon_area = largest_alpha_component_mask(alpha)
        component_mask = component_mask.filter(ImageFilter.MaxFilter(5))
        icon_alpha = ImageChops.multiply(alpha, component_mask)
        icon_bbox = icon_alpha.getbbox()
        if icon_bbox is None:
            raise RuntimeError("dominant icon component became empty")
        icon_source = rgba.copy()
        icon_source.putalpha(icon_alpha)
        cropped = icon_source.crop(icon_bbox)
        # Windows shell icons are expected to have square frames.  Center the
        # tightly cropped mascot on a square canvas with only a minimal safety
        # margin, then let Pillow derive exact square ICO sizes.
        max_dim = max(cropped.width, cropped.height)
        padding = max(1, round(max_dim * 0.01))
        side = max_dim + 2 * padding
        icon_rgba = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        x = (side - cropped.width) // 2
        y = (side - cropped.height) // 2
        icon_rgba.alpha_composite(cropped, (x, y))
        icon_rgba.save(ICON_PNG_OUT, format="PNG")
        icon_rgba.save(
            ICO_OUT,
            format="ICO",
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
        )
        print(f"source={MASTER}")
        print(f"png={PNG_OUT}")
        print(f"icon_png={ICON_PNG_OUT}")
        print(f"ico={ICO_OUT}")
        print(f"source_size={rgba.width}x{rgba.height}")
        print(f"full_alpha_bbox={full_bbox}")
        print(f"component_bbox={component_bbox}")
        print(f"icon_component_bbox={icon_bbox}")
        print(f"icon_component_area={icon_area}")
        print(f"cropped_size={cropped.width}x{cropped.height}")
        print(f"icon_padding={padding}")
        print(f"icon_canvas={side}x{side}")
        print(f"alpha_min={alpha_min}")
        print(f"alpha_max={alpha_max}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
