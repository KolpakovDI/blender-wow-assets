from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def read_mirror(name: str) -> str | None:
    path = ROOT / "docs" / "realm-of-spirits" / "studio" / name
    if not path.exists():
        return None
    return path.read_text(encoding="utf-8", errors="replace")


def check_tokens(text: str, label: str, required: list[str]) -> list[str]:
    issues: list[str] = []
    for token in required:
        if token not in text:
            issues.append(f"{label} missing token: {token}")
    return issues


def main() -> int:
    system = read_mirror("PvPDuelSystem.lua")
    controller = read_mirror("PvPDuelController.lua")
    issues: list[str] = []

    if system is None:
        issues.append("PvPDuelSystem.lua mirror missing")
    else:
        issues.extend(
            check_tokens(
                system,
                "PvPDuelSystem",
                [
                    "MAX_DISTANCE = 80",
                    "setupDuelVisuals",
                    "freezePlayer",
                    "unfreezePlayer",
                    "OriginA",
                    "offerRematch",
                    "returnPlayersToOrigin",
                    "RematchOffer",
                    "RematchAccept",
                    "RematchDecline",
                    "HideBattleBlade",
                    "ExecuteFairSkill",
                    "inChallengeZone",
                    "nearHaven",
                    "CHALLENGE_FROM_ARENA",
                ],
            )
        )
        if "ShowBattleBlade" in system and "HideBattleBlade" not in system:
            issues.append("PvPDuelSystem still shows blades without HideBattleBlade")

    if controller is None:
        issues.append("PvPDuelController.lua mirror missing")
    else:
        issues.extend(
            check_tokens(
                controller,
                "PvPDuelController",
                [
                    "showRematchOffer",
                    "RematchOffer",
                    "RematchAccept",
                    "RematchDecline",
                    "ReturnedHome",
                    "showDuelHud",
                ],
            )
        )

    interact = read_mirror("PlayerInteractController.lua")
    if interact is None:
        issues.append("PlayerInteractController.lua mirror missing")
    else:
        issues.extend(
            check_tokens(
                interact,
                "PlayerInteractController",
                [
                    "PlayerInteractGui",
                    'FireServer("Request"',
                    "Обмен",
                    "Дуэль",
                    "inChallengeZone",
                ],
            )
        )

    if issues:
        print("; ".join(issues))
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
