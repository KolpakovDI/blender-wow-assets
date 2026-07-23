from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

p = Path(r"C:\Users\Asus\Projects\blender-wow-assets\docs\realm-of-spirits\assets\meshes\ref\tourbillon_side_wb274_h119.png")
img = Image.open(p).convert("RGB")
arr = np.asarray(img, dtype=np.int32)
h, w = arr.shape[:2]
content = (arr.sum(axis=2) < 3*245)
print("size", w, h)
print("content", int(content.sum()), "bbox", content.any(1).nonzero()[0][[0,-1]], content.any(0).nonzero()[0][[0,-1]])
# row occupancy
rc = content.sum(1)
for y in range(h):
    if rc[y] > 40:
        print(f"row {y:3d}: {int(rc[y]):3d}  {'#'*min(60, int(rc[y]//4))}")
# pink-ish: high R, lower G/B
pink = (arr[:,:,0] > 180) & (arr[:,:,1] < 160) & (arr[:,:,2] < 200) & content
print("pink_pixels", int(pink.sum()))
prc = pink.sum(1)
print("--- pink rows >20 ---")
for y in range(h):
    if prc[y] > 20:
        print(f"row {y:3d}: {int(prc[y]):3d}")
# also check annotated
p2 = Path(r"C:\Users\Asus\Projects\blender-wow-assets\docs\realm-of-spirits\assets\meshes\ref\tourbillon_side_annotated.png")
if p2.exists():
    a2 = Image.open(p2)
    print("annotated", a2.size, a2.mode)
