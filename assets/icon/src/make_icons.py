"""Draws the Planner app icon set from one geometry.

Mark: a filled accent circle with a check (one task done) above three empty
rings (three tasks a day). Based on the chosen AI concept, redrawn cleanly
with the exact brand colors.

Run from the repo root:  python3 assets/icon/src/make_icons.py
Writes SVG sources to assets/icon/src/ and PNGs to assets/icon/.
Needs only Pillow.
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent
SRC = OUT / "src"

ACCENT = "#D9480F"
PAPER = "#F6F3EE"
INK = "#1A1A1A"
INK_DARK = "#F2EEE8"
WHITE = "#FFFFFF"

# Geometry on a 1024 canvas. The whole mark fits inside the adaptive-icon
# safe circle (radius ~313 around the center), so no launcher mask crops it.
SIZE = 1024
CX, CY, R = 512, 440, 172
CHECK = [(450, 444), (494, 488), (582, 394)]
CHECK_W = 36
RING_Y, RING_R, RING_W, GAP = 700, 38, 15, 148
RINGS = [(CX + dx, RING_Y) for dx in (-GAP, 0, GAP)]

# Notification icon: just the done circle, on a 96 canvas.
N_SIZE, N_C, N_R = 96, 48, 40
N_CHECK = [(29, 49), (42, 62), (68, 35)]
N_CHECK_W = 10

LEGACY_SCALE = 1.3  # mark size on the full-square legacy icon
SS = 4  # supersampling factor for smooth edges


def _rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = hex_color.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def _polyline(draw, pts, width, fill, s):
    p = [(x * s, y * s) for x, y in pts]
    draw.line(p, fill=fill, width=int(width * s), joint="curve")
    r = width * s / 2
    for x, y in (p[0], p[-1]):  # round caps
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def _circle(draw, cx, cy, r, s, fill=None, outline=None, width=0):
    if outline:
        # Center the stroke on the radius, like SVG.
        ro = (r + width / 2) * s
        draw.ellipse(
            (cx * s - ro, cy * s - ro, cx * s + ro, cy * s + ro),
            outline=outline,
            width=int(width * s),
        )
    else:
        draw.ellipse(
            (cx * s - r * s, cy * s - r * s, cx * s + r * s, cy * s + r * s),
            fill=fill,
        )


def _finish(img: Image.Image, size: int) -> Image.Image:
    return img.resize((size, size), Image.Resampling.LANCZOS)


def colored_mark(accent, check, ring, bg=None) -> Image.Image:
    s = SS
    img = Image.new("RGBA", (SIZE * s, SIZE * s), _rgba(bg) if bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    _circle(d, CX, CY, R, s, fill=_rgba(accent))
    _polyline(d, CHECK, CHECK_W, _rgba(check), s)
    for x, y in RINGS:
        _circle(d, x, y, RING_R, s, outline=_rgba(ring), width=RING_W)
    return _finish(img, SIZE)


def white_cutout(size, c, r, check, check_w, rings=()) -> Image.Image:
    """Solid white shape with the check punched out (real transparency)."""
    s = SS
    alpha = Image.new("L", (size * s, size * s), 0)
    d = ImageDraw.Draw(alpha)
    _circle(d, c[0], c[1], r, s, fill=255)
    _polyline(d, check, check_w, 0, s)
    for x, y in rings:
        _circle(d, x, y, RING_R, s, outline=255, width=RING_W)
    img = Image.new("RGBA", alpha.size, _rgba(WHITE))
    img.putalpha(alpha)
    return _finish(img, size)


def _svg_mark(accent, check, ring, bg=None) -> str:
    pts = " ".join(f"L{x},{y}" for x, y in CHECK[1:])
    body = f'<rect width="{SIZE}" height="{SIZE}" fill="{bg}"/>' if bg else ""
    body += f'<circle cx="{CX}" cy="{CY}" r="{R}" fill="{accent}"/>'
    body += (
        f'<path d="M{CHECK[0][0]},{CHECK[0][1]} {pts}" fill="none" stroke="{check}" '
        f'stroke-width="{CHECK_W}" stroke-linecap="round" stroke-linejoin="round"/>'
    )
    for x, y in RINGS:
        body += (
            f'<circle cx="{x}" cy="{y}" r="{RING_R}" fill="none" '
            f'stroke="{ring}" stroke-width="{RING_W}"/>'
        )
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
        f'viewBox="0 0 {SIZE} {SIZE}">{body}</svg>\n'
    )


def main() -> None:
    variants = {
        # Adaptive foreground (background color is set in config).
        "icon_foreground": (ACCENT, PAPER, INK, None),
        # Dark splash: rings in light ink so they stay visible.
        "icon_foreground_dark": (ACCENT, PAPER, INK_DARK, None),
    }
    for name, (a, c, r, bg) in variants.items():
        colored_mark(a, c, r, bg).save(OUT / f"{name}.png", optimize=True)
        (SRC / f"{name}.svg").write_text(_svg_mark(a, c, r, bg))

    # Legacy full icon (Android 7): no launcher mask, so the mark can be
    # larger. Scale the foreground up around the center and put it on paper.
    big = colored_mark(ACCENT, PAPER, INK).resize(
        (int(SIZE * LEGACY_SCALE),) * 2, Image.Resampling.LANCZOS
    )
    off = (SIZE - big.width) // 2
    full = Image.new("RGBA", (SIZE, SIZE), _rgba(PAPER))
    full.alpha_composite(big.crop((-off, -off, -off + SIZE, -off + SIZE)))
    full.save(OUT / "icon.png", optimize=True)

    # Themed icon (Android 13+): white, check cut out.
    white_cutout(SIZE, (CX, CY), R, CHECK, CHECK_W, RINGS).save(
        OUT / "icon_monochrome.png", optimize=True
    )
    # Notification: bold done circle only, white, check cut out.
    white_cutout(N_SIZE, (N_C, N_C), N_R, N_CHECK, N_CHECK_W).save(
        OUT / "notification.png", optimize=True
    )
    print("Wrote icon set to", OUT)


if __name__ == "__main__":
    main()
