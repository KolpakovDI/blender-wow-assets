from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def run_check(script_name: str) -> tuple[bool, str]:
    script_path = ROOT / "scripts" / script_name
    if not script_path.exists():
        return True, f"{script_name}: skipped (not found)"

    proc = subprocess.run(
        [sys.executable, str(script_path)],
        capture_output=True,
        text=True,
        cwd=str(ROOT),
    )
    output = (proc.stdout or "").strip() or (proc.stderr or "").strip() or "OK"
    if proc.returncode != 0:
        return False, f"{script_name}: failed ({output})"
    if output != "OK":
        return False, f"{script_name}: {output}"
    return True, f"{script_name}: OK"


def main() -> int:
    checks = [
        "validate_spirit_database.py",
        "battle_sanity_check.py",
        "fair_combat_check.py",
        "pvp_sanity_check.py",
    ]
    ok = True
    lines: list[str] = []

    for check in checks:
        passed, message = run_check(check)
        lines.append(message)
        if not passed:
            ok = False

    print("\n".join(lines))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
