"""Generate DevReady terminal demo PNG + GIF for README."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "docs" / "assets"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 900, 520
BG = (13, 17, 23)
TITLE_BAR = (22, 27, 34)
GREEN = (63, 185, 80)
CYAN = (88, 166, 255)
GRAY = (139, 148, 158)
WHITE = (230, 237, 243)
RED_DOT, YELLOW_DOT, GREEN_DOT = (255, 95, 86), (255, 189, 46), (39, 201, 63)

LINES = [
    ("PS>", WHITE),
    ("devready", CYAN),
    ("", WHITE),
    ("DevReady — Core health check", GRAY),
    ("", WHITE),
    ("  PASS  pwsh 7.5.2", GREEN),
    ("  PASS  git configured", GREEN),
    ("  PASS  profile loaded (512ms)", GREEN),
    ("  PASS  command-health 72/72", GREEN),
    ("", WHITE),
    ("Tier: Core  |  Passed: 31  |  Failed: 0", GRAY),
    ("", WHITE),
    ("Ready to work", GREEN),
]

FRAMES_TEXT = [
    ["PS> ", "d", "", "", "", "", "", "", "", "", ""],
    ["PS> ", "de", "", "", "", "", "", "", "", "", ""],
    ["PS> ", "dev", "", "", "", "", "", "", "", "", ""],
    ["PS> ", "devready", "", "", "", "", "", "", "", "", ""],
    ["PS> ", "devready", "", "DevReady — Core health check", "", "", "", "", "", "", ""],
    ["PS> ", "devready", "", "DevReady — Core health check", "  PASS  pwsh 7.5.2", "", "", "", "", "", ""],
    ["PS> ", "devready", "", "DevReady — Core health check", "  PASS  pwsh 7.5.2", "  PASS  git configured", "  PASS  profile loaded", "", "", "", ""],
    ["PS> ", "devready", "", "DevReady — Core health check", "  PASS  pwsh 7.5.2", "  PASS  git configured", "  PASS  profile loaded", "  PASS  command-health 72/72", "", "", ""],
    LINES[4][0] and "" or "",
]
# Final frame = full output
FINAL_ROWS = [l[0] for l in LINES if l[0] or True]
FINAL_ROWS = [x[0] for x in LINES]


def get_font(size: int):
    for name in ("CascadiaMono.ttf", "Consolas.ttf", "cour.ttf", "lucon.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_terminal(draw: ImageDraw.ImageDraw, rows: list[str], font, show_cursor: bool = False):
    draw.rectangle([0, 0, W, 36], fill=TITLE_BAR)
    for i, c in enumerate((RED_DOT, YELLOW_DOT, GREEN_DOT)):
        draw.ellipse([16 + i * 22, 12, 28 + i * 22, 24], fill=c)
    draw.text((W // 2 - 80, 10), "Windows Terminal", fill=GRAY, font=font)

    y = 52
    for i, row in enumerate(rows):
        if not row:
            y += 26
            continue
        color = CYAN if i == 1 else GREEN if row.strip().startswith("PASS") or row == "Ready to work" else GRAY if "Tier:" in row or "DevReady" in row else WHITE
        draw.text((24, y), row, fill=color, font=font)
        y += 26
    if show_cursor:
        draw.rectangle([24 + font.getlength(rows[1] if len(rows) > 1 else ""), 78, 26 + font.getlength(rows[1] if len(rows) > 1 else ""), 100], fill=CYAN)


def render_frame(rows: list[str], cursor: bool = False) -> Image.Image:
    img = Image.new("RGB", (W, H), BG)
    font = get_font(18)
    draw = ImageDraw.Draw(img)
    draw_terminal(draw, rows, font, cursor)
    return img


def build_frames():
    frames = []
    typed = "devready"
    for n in range(1, len(typed) + 1):
        frames.append(render_frame(["PS> " + typed[:n]], cursor=True))
    base = ["PS> devready", "", "DevReady — Core health check", ""]
    for extra in [
        [],
        ["  PASS  pwsh 7.5.2"],
        ["  PASS  pwsh 7.5.2", "  PASS  git configured"],
        ["  PASS  pwsh 7.5.2", "  PASS  git configured", "  PASS  profile loaded (512ms)"],
        ["  PASS  pwsh 7.5.2", "  PASS  git configured", "  PASS  profile loaded (512ms)", "  PASS  command-health 72/72"],
    ]:
        frames.append(render_frame(base + extra))
    final = [x[0] for x in LINES]
    frames.append(render_frame(final))
    frames.append(render_frame(final))
    frames.append(render_frame(final))
    return frames


def main():
    font = get_font(18)
    png = render_frame(FINAL_ROWS)
    png.save(OUT / "devready-demo.png", optimize=True)

    frames = build_frames()
    frames[0].save(
        OUT / "devready-demo.gif",
        save_all=True,
        append_images=frames[1:],
        duration=350,
        loop=0,
        optimize=True,
    )
    print(f"Wrote {OUT / 'devready-demo.png'} ({(OUT / 'devready-demo.png').stat().st_size} bytes)")
    print(f"Wrote {OUT / 'devready-demo.gif'} ({(OUT / 'devready-demo.gif').stat().st_size} bytes)")


if __name__ == "__main__":
    main()
