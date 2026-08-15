# -*- coding: utf-8 -*-
"""Validate QuestCatalog / ZoneConfig anchors — mitigates empty-landscape & catalog drift."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STUDIO = ROOT / "docs" / "realm-of-spirits" / "studio"


def fail(msg: str) -> None:
    print(msg)
    raise SystemExit(1)


def main() -> int:
    qs = (STUDIO / "QuestSystem.lua").read_text(encoding="utf-8")
    cat = (STUDIO / "QuestCatalog.lua").read_text(encoding="utf-8")
    zc = (STUDIO / "ZoneConfig.lua").read_text(encoding="utf-8")

    # Risk 1: no inline QuestDatabase monolith regression
    if re.search(r"local\s+QuestDatabase\s*=", qs):
        fail("validate_quest_catalog: QuestSystem still defines local QuestDatabase")
    if "require(realmFolder:WaitForChild(\"QuestCatalog\"))" not in qs and "WaitForChild(\"QuestCatalog\")" not in qs:
        fail("validate_quest_catalog: QuestSystem missing QuestCatalog require")
    if "continue" in qs:
        fail("validate_quest_catalog: QuestSystem uses continue (prefer if-not-Deprecated)")

    # Risk 2: every QuestLocations key has VisitZone quest
    loc_keys = re.findall(r"^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*\{", zc.split("QuestLocations")[1].split("function ZoneConfig")[0] if "QuestLocations" in zc else "")
    # More reliable: keys under QuestLocations block
    m = re.search(r"ZoneConfig\.QuestLocations\s*=\s*\{(.*?)\n\}", zc, re.S)
    if not m:
        fail("validate_quest_catalog: ZoneConfig.QuestLocations missing")
    block = m.group(1)
    keys = re.findall(r"^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*\{", block, re.M)
    if len(keys) < 4:
        fail(f"validate_quest_catalog: expected ≥4 QuestLocations, got {keys}")

    visit_details = set(re.findall(r'ZoneDetail\s*=\s*"([A-Za-z0-9_]+)"', cat))
    orphans = [k for k in keys if k not in visit_details]
    if orphans:
        fail(f"validate_quest_catalog: QuestLocations without VisitZone quest: {orphans}")

    # VisitZone must be handled in QuestSystem
    if 'progressType == "VisitZone"' not in qs and "progressType == 'VisitZone'" not in qs:
        fail("validate_quest_catalog: QuestSystem missing VisitZone progress handler")

    # Risk 3: ExpansionGate / stubs exist
    for name in ("ExpansionGate.lua", "ProfileServiceAdapter.lua", "SpiritMeshGenerationService.lua", "GuildSystem.lua"):
        if not (STUDIO / name).exists():
            fail(f"validate_quest_catalog: missing {name}")

    gate = (STUDIO / "ExpansionGate.lua").read_text(encoding="utf-8")
    if "AllowAiMeshOnline = false" not in gate or "AllowProfileService = false" not in gate:
        fail("validate_quest_catalog: ExpansionGate defaults must block AI mesh / ProfileService")

    psa = (STUDIO / "ProfileServiceAdapter.lua").read_text(encoding="utf-8")
    if "ExpansionGate" not in psa:
        fail("validate_quest_catalog: ProfileServiceAdapter must consult ExpansionGate")

    # Exploration quests 8-15 present
    for qid in range(8, 16):
        if f"[{qid}] =" not in cat and f"[{qid}]=" not in cat:
            fail(f"validate_quest_catalog: missing quest Id {qid}")

    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
