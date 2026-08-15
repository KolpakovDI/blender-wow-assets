# -*- coding: utf-8 -*-
"""Emit Luau apply scripts that set Module/Script Source from long string parts."""
from pathlib import Path
import json

out = Path(r"C:\Users\Asus\Projects\blender-wow-assets\.tmp_extract\ros_push_q1")
for jf in out.glob("apply_*.json"):
    data = json.loads(jf.read_text(encoding="utf-8"))
    name = data["name"]
    parent = data["parent"]
    className = data["className"]
    parts = data["parts"]
    # Build Luau that concatenates long strings safely with [=[ ]=]
    lines = [
        f'local parent = game.{parent}',
        f'local name = "{name}"',
        f'local className = "{className}"',
        "local old = parent:FindFirstChild(name)",
        "if old then old:Destroy() end",
        "local inst = Instance.new(className)",
        "inst.Name = name",
        "local src = \"\"",
    ]
    for i, part in enumerate(parts):
        # escape ]=] sequences in part
        safe = part.replace("]=]", "] =]")
        lines.append(f"src ..= [=======[{safe}]=======]")
    lines += [
        "inst.Source = src",
        "inst.Parent = parent",
        'return string.format("pushed %s %d", name, #src)',
    ]
    luau = "\n".join(lines)
    (out / f"push_{name}.luau").write_text(luau, encoding="utf-8")
    print(name, "luau bytes", len(luau.encode("utf-8")))
