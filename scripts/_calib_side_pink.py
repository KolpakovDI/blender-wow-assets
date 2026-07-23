"""Pink/non-white SIDE orthographic ref calibration for Tourbillon."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

IMG_PATH = Path(
    r"C:\Users\Asus\Projects\blender-wow-assets\docs\realm-of-spirits\assets\meshes\ref\tourbillon_side_wb274_h119.png"
)
WHITE_SUM = 3 * 245


def main() -> None:
    img = Image.open(IMG_PATH).convert("RGB")
    arr = np.asarray(img, dtype=np.int32)
    h, w = arr.shape[:2]
    content = (arr.sum(axis=2) < WHITE_SUM)
    ys, xs = np.where(content)
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    row_counts = content.sum(axis=1).astype(np.float64)

    # Ground: longest horizontal in lower third
    lt0 = int(h * 2 / 3)
    ground_row = int(lt0 + np.argmax(row_counts[lt0:]))

    # Roof: first strong local peak scanning downward from top of content
    # (upper dashed roof, before greenhouse / beltline)
    car_h = max(1, ground_row - y0)
    scan_lo = y0 + 1
    scan_hi = y0 + int(0.28 * car_h)  # only uppermost ~28% of body
    sm = np.convolve(row_counts, np.ones(3) / 3.0, mode="same")
    roof_row = int(scan_lo + np.argmax(sm[scan_lo:scan_hi]))
    # If that peak is weak, fall back to max in scan
    if sm[roof_row] < 40:
        roof_row = int(scan_lo + np.argmax(row_counts[scan_lo:scan_hi]))

    h_car = max(1, ground_row - roof_row)
    r_min = max(10, int(0.20 * h_car))
    r_max = max(r_min + 2, int(0.40 * h_car))
    band_top = max(0, ground_row - int(2.3 * r_max))
    band_bot = min(h - 1, ground_row + 3)
    band = content[band_top : band_bot + 1, :]
    pad = np.pad(band.astype(np.uint8), 1)
    neigh = pad[:-2, 1:-1] + pad[2:, 1:-1] + pad[1:-1, :-2] + pad[1:-1, 2:]
    edge = band & (neigh < 4)
    ey, ex = np.where(edge)
    rng = np.random.default_rng(0)
    if len(ex) > 6000:
        idx = rng.choice(len(ex), 6000, replace=False)
        ex, ey = ex[idx], ey[idx]
    bh, bw = band.shape

    circles: list[tuple[float, float, float, float]] = []
    for r in range(r_min, r_max + 1):
        cy_expect = ground_row - r
        cy_rel = cy_expect - band_top
        if not (r <= cy_rel < bh - r):
            continue
        acc = np.zeros(bw, dtype=np.float64)
        for dcy in range(-2, 3):
            cy_t = cy_rel + dcy
            if cy_t < 0 or cy_t >= bh:
                continue
            for x, y in zip(ex.astype(float), ey.astype(float)):
                dy = y - cy_t
                if abs(dy) > r:
                    continue
                dx = float(np.sqrt(max(0.0, r * r - dy * dy)))
                for sgn in (-1.0, 1.0):
                    cx = int(round(x - sgn * dx))
                    if 0 <= cx < bw:
                        acc[cx] += 1.0
        acc_s = np.convolve(acc, np.ones(5) / 5.0, mode="same")
        for _ in range(4):
            cx = int(np.argmax(acc_s))
            sc = float(acc_s[cx])
            if sc < 12:
                break
            a0, a1 = max(0, cx - r), min(bw, cx + r + 1)
            acc_s[a0:a1] = 0
            circles.append((sc, float(cx), float(cy_expect), float(r)))

    circles.sort(key=lambda t: -t[0])
    chosen: list[tuple[float, float, float, float]] = []
    for c in circles:
        if any(abs(c[1] - o[1]) < 0.55 * max(c[3], o[3]) for o in chosen):
            continue
        chosen.append(c)
        if len(chosen) >= 8:
            break

    content_w = float(x1 - x0)
    target_wb = content_w / (4675.0 / 2740.0)

    best = None
    best_key = -1e18
    for i in range(len(chosen)):
        for j in range(i + 1, len(chosen)):
            a, b = chosen[i], chosen[j]
            sep = abs(a[1] - b[1])
            ravg = 0.5 * (a[3] + b[3])
            if sep < 2.2 * ravg or sep > 7.5 * ravg:
                continue
            if abs(a[3] - b[3]) > 0.3 * ravg:
                continue
            if abs(a[2] - b[2]) > 10:
                continue
            score = a[0] + b[0] - 0.35 * abs(sep - target_wb) - 2.0 * ravg
            if score > best_key:
                best_key = score
                best = (a, b)

    if best is None:
        xs_c = sorted(chosen[:4], key=lambda t: t[1])
        best = (xs_c[0], xs_c[-1])

    a, b = best
    rear, front = (a, b) if a[1] < b[1] else (b, a)
    wheel_rear_cx = rear[1]
    wheel_front_cx = front[1]
    wheel_cy = 0.5 * (rear[2] + front[2])
    wheel_r = 0.5 * (rear[3] + front[3])

    wb_px = abs(wheel_front_cx - wheel_rear_cx)
    h_px = abs(ground_row - roof_row)
    ppm_wb = wb_px / 2.74
    ppm_h = h_px / 1.189

    out = {
        "img_w": w,
        "img_h": h,
        "content_bbox": {"x0": x0, "y0": y0, "x1": x1, "y1": y1},
        "ground_row": int(ground_row),
        "roof_row": int(roof_row),
        "wheel_front_cx": round(wheel_front_cx, 2),
        "wheel_rear_cx": round(wheel_rear_cx, 2),
        "wheel_cy": round(wheel_cy, 2),
        "wheel_r": round(wheel_r, 2),
        "wb_px": round(wb_px, 2),
        "px_per_m_from_wb": round(ppm_wb, 4),
        "h_px_ground_to_roof": int(h_px),
        "px_per_m_from_h": round(ppm_h, 4),
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
