"""Draws the Planner app icon set from one geometry.

Mark: a check inside a ring of three arcs (three tasks a day), white on a
rounded stormy-blue tile. Compact, reads at 24 px, and the same shapes are
drawn in code by lib/core/widgets/brand_mark.dart.

Run from the repo root:  python3 assets/icon/src/make_icons.py
Writes PNGs to assets/icon/ and an SVG source to assets/icon/src/.
Needs only Pillow.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent
SRC = OUT / "src"

ACCENT = "#2E4A6B"
ACCENT_DARK = "#8EB0D6"
PAGE_DARK = "#121519"
WHITE = "#FFFFFF"

SIZE = 1024
SS = 4  # supersampling for smooth edges

# Mark geometry as fractions of the tile side T (keep in sync with
# brand_mark.dart).
CORNER = 0.28  # tile corner radius
RING_R = 0.30  # ring radius (to the middle of the stroke)
STROKE = 0.075  # ring and check stroke width
ARC_SWEEP = 100  # degrees per arc; 3 arcs + 3 gaps of 20 = 360
ARC_START = -80  # first arc starts just right of 12 o'clock
CHECK = [(-0.125, 0.005), (-0.035, 0.095), (0.13, -0.075)]

# On the 1024 splash canvas the tile is 384 px: 96 dp at 4x, the size the
# in-app splash draws (AppSizes.brandMarkLarge), so the handoff is seamless.
SPLASH_TILE = 384


def _rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = hex_color.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def _mark(draw, cx, cy, t, fill, s=SS):
    """Ring of three arcs and a check, centered at (cx, cy), tile side t."""
    r = RING_R * t
    w = STROKE * t
    box = [(cx - r - w / 2) * s, (cy - r - w / 2) * s,
           (cx + r + w / 2) * s, (cy + r + w / 2) * s]
    for i in range(3):
        a0 = ARC_START + i * 120
        a1 = a0 + ARC_SWEEP
        draw.arc(box, a0, a1, fill=fill, width=int(w * s))
        for a in (a0, a1):  # round caps
            x = cx + r * math.cos(math.radians(a))
            y = cy + r * math.sin(math.radians(a))
            draw.ellipse(((x - w / 2) * s, (y - w / 2) * s,
                          (x + w / 2) * s, (y + w / 2) * s), fill=fill)
    pts = [((cx + dx * t) * s, (cy + dy * t) * s) for dx, dy in CHECK]
    draw.line(pts, fill=fill, width=int(w * s), joint="curve")
    for x, y in (pts[0], pts[-1]):
        rr = w * s / 2
        draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=fill)


def _canvas(size=SIZE, bg=None):
    img = Image.new("RGBA", (size * SS, size * SS), _rgba(bg) if bg else (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def _done(img, size=SIZE):
    return img.resize((size, size), Image.Resampling.LANCZOS)


def tile(t, tile_color, mark_color, size=SIZE):
    """Rounded tile of side t with the mark, centered on a clear canvas."""
    img, d = _canvas(size)
    c = size / 2
    h = t / 2
    d.rounded_rectangle(
        ((c - h) * SS, (c - h) * SS, (c + h) * SS, (c + h) * SS),
        radius=CORNER * t * SS,
        fill=_rgba(tile_color),
    )
    _mark(d, c, c, t, _rgba(mark_color))
    return _done(img, size)


def bare_mark(t, color, size=SIZE):
    img, d = _canvas(size)
    _mark(d, size / 2, size / 2, t, _rgba(color))
    return _done(img, size)


def _svg() -> str:
    t, c = SPLASH_TILE, SIZE / 2
    r, w = RING_R * t, STROKE * t
    parts = [
        f'<rect x="{c - t / 2}" y="{c - t / 2}" width="{t}" height="{t}" '
        f'rx="{CORNER * t}" fill="{ACCENT}"/>'
    ]
    for i in range(3):
        a0 = math.radians(ARC_START + i * 120)
        a1 = math.radians(ARC_START + i * 120 + ARC_SWEEP)
        x0, y0 = c + r * math.cos(a0), c + r * math.sin(a0)
        x1, y1 = c + r * math.cos(a1), c + r * math.sin(a1)
        parts.append(
            f'<path d="M{x0:.1f},{y0:.1f} A{r},{r} 0 0 1 {x1:.1f},{y1:.1f}" '
            f'fill="none" stroke="{WHITE}" stroke-width="{w}" stroke-linecap="round"/>'
        )
    pts = " L".join(f"{c + dx * t:.1f},{c + dy * t:.1f}" for dx, dy in CHECK)
    parts.append(
        f'<path d="M{pts}" fill="none" stroke="{WHITE}" stroke-width="{w}" '
        'stroke-linecap="round" stroke-linejoin="round"/>'
    )
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
        f'viewBox="0 0 {SIZE} {SIZE}">{"".join(parts)}</svg>\n'
    )


def main() -> None:
    # Adaptive icon (Android 8+): accent background (set in config) and a
    # white mark sized to stay inside the launcher's safe circle (r ~313).
    adaptive_t = 760
    bare_mark(adaptive_t, WHITE).save(OUT / "icon_foreground.png", optimize=True)
    # Themed icon (Android 13+): same shapes, white; the system tints it.
    bare_mark(adaptive_t, WHITE).save(OUT / "icon_monochrome.png", optimize=True)

    # Legacy icon (Android 7): the whole tile, edge to edge.
    tile(SIZE, ACCENT, WHITE).save(OUT / "icon.png", optimize=True)

    # Native splash: the tile at 96 dp, light and dark.
    tile(SPLASH_TILE, ACCENT, WHITE).save(OUT / "splash.png", optimize=True)
    tile(SPLASH_TILE, ACCENT_DARK, PAGE_DARK).save(
        OUT / "splash_dark.png", optimize=True
    )

    # Notification icon: white mark on 96 px, as large as fits.
    bare_mark(128, WHITE, size=96).save(OUT / "notification.png", optimize=True)

    for old in ("icon_foreground_dark.png",):
        (OUT / old).unlink(missing_ok=True)
    for old in SRC.glob("*.svg"):
        old.unlink()
    (SRC / "mark.svg").write_text(_svg())
    print("Wrote icon set to", OUT)


if __name__ == "__main__":
    main()
