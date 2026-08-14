import json
from pathlib import Path

base = Path(__file__).parent
files = {
    "OtakuHavenBuilder": ("ServerScriptService.RealmOfSpirits.OtakuHavenBuilder", base / "OtakuHavenBuilder.lua"),
    "ZoneSystem": ("ServerScriptService.RealmOfSpirits.ZoneSystem", base / "ZoneSystem.lua"),
    "ZoneController": ("StarterPlayer.StarterPlayerScripts.ZoneController", base / "ZoneController.lua"),
}

chunks_all = {}
for name, (path_expr, fp) in files.items():
    src = fp.read_text(encoding="utf-8")
    lines = src.split("\n")
    lua_chunks = []
    acc = []
    for i, line in enumerate(lines):
        acc.append(line)
        if len(acc) >= 35 or i == len(lines) - 1:
            block = "\n".join(acc)
            lua_chunks.append(block)
            acc = []
    chunks_all[name] = {"path": path_expr, "chunks": lua_chunks}

out = base / "upload_chunks.json"
out.write_text(json.dumps(chunks_all, ensure_ascii=False), encoding="utf-8")
print({k: len(v["chunks"]) for k, v in chunks_all.items()})
