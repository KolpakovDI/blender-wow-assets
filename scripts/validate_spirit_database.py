from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
STUDIO = ROOT / "docs" / "realm-of-spirits" / "studio"


def find_db_file() -> Path | None:
    candidates = [
        STUDIO / "SpiritDatabase.lua",
        ROOT / "docs" / "realm-of-spirits" / "SpiritDatabase.lua",
        Path("ReplicatedStorage/RealmOfSpirits/SpiritDatabase.lua"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def extract_table_body(text: str, assignment: str) -> str | None:
    """Extract `{...}` body after `assignment` (e.g. SpiritDatabase.Spirits =)."""
    match = re.search(rf"{re.escape(assignment)}\s*=\s*\{{", text)
    if not match:
        return None
    start = match.end() - 1
    depth = 0
    for idx in range(start, len(text)):
        ch = text[idx]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start + 1 : idx]
    return None


def extract_spirit_blocks(spirits_body: str) -> list[tuple[int, str]]:
    blocks: list[tuple[int, str]] = []
    for match in re.finditer(r"\[(\d+)\]\s*=\s*\{", spirits_body):
        spirit_id = int(match.group(1))
        start = match.end() - 1
        depth = 0
        end = start
        for idx in range(start, len(spirits_body)):
            ch = spirits_body[idx]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = idx + 1
                    break
        blocks.append((spirit_id, spirits_body[start:end]))
    return blocks


def load_skill_ids() -> set[int]:
    path = STUDIO / "SkillCatalog.lua"
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8", errors="replace")
    body = extract_table_body(text, "SkillCatalog.ById") or extract_table_body(text, "ById")
    if not body:
        # Fallback: any [n] = in file under SkillCatalog
        return {int(x) for x in re.findall(r"\[(\d+)\]\s*=\s*\{", text)}
    return {int(x) for x in re.findall(r"\[(\d+)\]\s*=\s*\{", body)}


def parse_skill_ids(block: str) -> tuple[list[int], list[str]]:
    issues: list[str] = []
    match = re.search(r"SkillIds\s*=\s*\{([^}]*)\}", block)
    if not match:
        return [], ["missing SkillIds table"]
    ids: list[int] = []
    for raw in re.findall(r"\d+", match.group(1)):
        ids.append(int(raw))
    if not ids:
        issues.append("empty SkillIds table")
    return ids, issues


def main() -> int:
    db_file = find_db_file()
    if db_file is None:
        print("OK")
        return 0

    text = db_file.read_text(encoding="utf-8", errors="replace")
    issues: list[str] = []

    spirits_body = extract_table_body(text, "SpiritDatabase.Spirits")
    if spirits_body is None:
        print("SpiritDatabase.Spirits table not found")
        return 1

    blocks = extract_spirit_blocks(spirits_body)
    ids = [sid for sid, _ in blocks]
    if ids:
        duplicates = sorted({x for x in ids if ids.count(x) > 1})
        if duplicates:
            issues.append(f"duplicate spirit ids: {duplicates}")

    if len(ids) < 5:
        issues.append(f"too few spirits detected: {len(ids)}")

    catalog_ids = load_skill_ids()

    for spirit_id, block in blocks:
        for required in ("Name =", "BaseStats", "CatchRate"):
            if required not in block:
                issues.append(f"spirit[{spirit_id}] missing field: {required}")

        if "SkillIds" not in block and "Skills" not in block:
            issues.append(f"spirit[{spirit_id}] missing SkillIds/Skills")

        stats_m = re.search(r"BaseStats\s*=\s*\{([^{}]*)\}", block)
        if stats_m:
            stats = stats_m.group(1)
            for stat_name in ("HP", "Attack", "Defense", "Speed"):
                if re.search(rf"{stat_name}\s*=", stats) is None:
                    issues.append(f"spirit[{spirit_id}] BaseStats missing {stat_name}")
        else:
            issues.append(f"spirit[{spirit_id}] invalid BaseStats")

        rate_m = re.search(r"CatchRate\s*=\s*([0-9]*\.?[0-9]+)", block)
        if rate_m:
            rate = float(rate_m.group(1))
            if rate < 0 or rate > 1:
                issues.append(f"spirit[{spirit_id}] CatchRate out of range: {rate}")
        else:
            issues.append(f"spirit[{spirit_id}] missing CatchRate value")

        skill_ids, skill_issues = parse_skill_ids(block)
        for i in skill_issues:
            # Allow legacy Skills= if SkillIds absent
            if i == "missing SkillIds table" and "Skills" in block:
                continue
            issues.append(f"spirit[{spirit_id}] {i}")

        if catalog_ids and skill_ids:
            for sid in skill_ids:
                if sid not in catalog_ids:
                    issues.append(f"spirit[{spirit_id}] SkillId {sid} not in SkillCatalog")

        movement_m = re.search(r'MovementType\s*=\s*"([^"]+)"', block)
		if movement_m and movement_m.group(1) not in {"Walk", "Fly", "Swim"}:
            issues.append(f"spirit[{spirit_id}] invalid MovementType={movement_m.group(1)}")

    if issues:
        print("; ".join(issues))
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
