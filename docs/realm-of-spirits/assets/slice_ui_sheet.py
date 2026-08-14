"""Slice WoW-style UI asset sheet into Roblox-ready PNGs."""
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Install Pillow: pip install Pillow")

ROOT = Path(__file__).resolve().parent
SHEET = ROOT / "ui-asset-sheet.png"
OUT = ROOT / "ui"

# Approximate crop boxes (x, y, w, h) for 1376x768 sheet — tweak if layout shifts
SLICES = {
    "skill_frame_64.png": (40, 40, 64, 64),
    "skill_frame_64_alt.png": (120, 40, 64, 64),
    "unit_frame_portrait.png": (520, 30, 180, 180),
    "bar_hp.png": (40, 280, 320, 48),
    "bar_mp.png": (40, 340, 320, 48),
    "minimap_ring_200.png": (900, 80, 200, 200),
    "panel_parchment.png": (40, 420, 256, 128),
    "panel_wood.png": (320, 420, 256, 128),
    "gem_red.png": (600, 420, 32, 32),
    "gem_blue.png": (640, 420, 32, 32),
}

def main():
    if not SHEET.exists():
        raise FileNotFoundError(SHEET)
    OUT.mkdir(parents=True, exist_ok=True)
    img = Image.open(SHEET).convert("RGBA")
    w, h = img.size
    print(f"Sheet size: {w}x{h}")
    for name, (x, y, cw, ch) in SLICES.items():
        x2, y2 = min(x + cw, w), min(y + ch, h)
        crop = img.crop((x, y, x2, y2))
        path = OUT / name
        crop.save(path)
        print(f"  {name} -> {crop.size[0]}x{crop.size[1]}")
    print(f"Done: {OUT}")

if __name__ == "__main__":
    main()
