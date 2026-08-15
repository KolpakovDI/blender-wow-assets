# -*- coding: utf-8 -*-
from pathlib import Path
import json

studio = Path(r"C:\Users\Asus\Projects\blender-wow-assets\docs\realm-of-spirits\studio")
out = Path(r"C:\Users\Asus\Projects\blender-wow-assets\.tmp_extract\ros_push_q1")
out.mkdir(parents=True, exist_ok=True)

items = [
    ("QuestCatalog.lua", "ReplicatedStorage.RealmOfSpirits", "ModuleScript"),
    ("ZoneConfig.lua", "ReplicatedStorage.RealmOfSpirits", "ModuleScript"),
    ("ProfileServiceAdapter.lua", "ReplicatedStorage.RealmOfSpirits", "ModuleScript"),
    ("QuestSystem.lua", "ServerScriptService.RealmOfSpirits", "Script"),
    ("ZoneSystem.lua", "ServerScriptService.RealmOfSpirits", "Script"),
    ("WorldSpawner.lua", "ServerScriptService.RealmOfSpirits", "Script"),
    ("GuildSystem.lua", "ServerScriptService.RealmOfSpirits", "ModuleScript"),
    ("PvPDuelSystem.lua", "ServerScriptService.RealmOfSpirits", "ModuleScript"),
    ("OtakuHavenService.lua", "ServerScriptService.RealmOfSpirits", "Script"),
    ("OtakuHavenBuilder.lua", "ServerScriptService.RealmOfSpirits", "ModuleScript"),
]

for path, parent, className in items:
    src = (studio / path).read_text(encoding="utf-8")
    parts = [src[i : i + 7000] for i in range(0, len(src), 7000)]
    name = path.replace(".lua", "")
    payload = {"parent": parent, "name": name, "className": className, "parts": parts}
    (out / f"apply_{name}.json").write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    print(path, "parts", len(parts), "len", len(src))
