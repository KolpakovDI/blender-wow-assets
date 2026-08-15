# -*- coding: utf-8 -*-
"""Push key RoS modules into Studio via MCP is manual; this packs sources for execute_luau."""
from pathlib import Path
import json
import base64

studio = Path(r"C:\Users\Asus\Projects\blender-wow-assets\docs\realm-of-spirits\studio")
out = Path(r"C:\Users\Asus\Projects\blender-wow-assets\.tmp_extract\ros_push_q1")
out.mkdir(parents=True, exist_ok=True)

# RS modules vs SSS modules
files = {
    "RS": [
        "QuestCatalog.lua",
        "ZoneConfig.lua",
        "HubFunnel.lua",
        "ProfileServiceAdapter.lua",
    ],
    "SSS": [
        "QuestSystem.lua",
        "ZoneSystem.lua",
        "WorldSpawner.lua",
        "PvPDuelSystem.lua",
        "GuildSystem.lua",
        "OtakuHavenService.lua",
    ],
}

manifest = []
for bucket, names in files.items():
    for name in names:
        p = studio / name
        if not p.exists():
            print("MISS", p)
            continue
        raw = p.read_text(encoding="utf-8")
        b64 = base64.b64encode(raw.encode("utf-8")).decode("ascii")
        chunk_size = 12000
        chunks = [b64[i : i + chunk_size] for i in range(0, len(b64), chunk_size)]
        meta = {"bucket": bucket, "name": name.replace(".lua", ""), "chunks": len(chunks), "chars": len(raw)}
        manifest.append(meta)
        for i, ch in enumerate(chunks):
            (out / f"{bucket}_{name.replace('.lua','')}_{i:02d}.b64").write_text(ch, encoding="ascii")
        (out / f"{bucket}_{name.replace('.lua','')}_meta.json").write_text(json.dumps(meta), encoding="utf-8")
        print(meta)

(out / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print("done", out)
