from __future__ import annotations

import shutil
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CURSOR_DIR = ROOT / ".cursor"


def main() -> int:
    profile = (sys.argv[1] if len(sys.argv) > 1 else "dev").strip().lower()
    src = CURSOR_DIR / f"hooks.{profile}.json"
    dst = CURSOR_DIR / "hooks.json"

    if profile not in {"dev", "strict"}:
        print("Usage: python scripts/switch_hooks_profile.py [dev|strict]")
        return 2
    if not src.exists():
        print(f"Profile file not found: {src}")
        return 1

    shutil.copyfile(src, dst)
    print(f"Hooks profile switched to '{profile}' -> {dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
