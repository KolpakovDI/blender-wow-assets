from __future__ import annotations

from pathlib import Path


def read_first_existing(paths: list[Path]) -> str | None:
    for path in paths:
        if path.exists():
            return path.read_text(encoding="utf-8", errors="replace")
    return None


def check_game_manager() -> list[str]:
    text = read_first_existing(
        [
            Path("docs/realm-of-spirits/studio/GameManager.lua"),
            Path("ServerScriptService/RealmOfSpirits/GameManager.lua"),
        ]
    )
    if text is None:
        return []

    issues: list[str] = []
    required = [
        "SendBattleUpdate",
        "battle.Active",
        "activeBattles",
        "BattleEvent:FireClient(player, \"End\"",
        "BuildPlayerAbilities",
        "GetEnemyAbilities",
        "CreateEffectsState",
        "ApplySkillEffect",
        "StepTimedEffects",
        "ComputeDamage",
        "ApplyBurnTick",
    ]
    for token in required:
        if token not in text:
            issues.append(f"GameManager missing token: {token}")
    return issues


def check_ui_controller() -> list[str]:
    text = read_first_existing(
        [
            Path("docs/realm-of-spirits/studio/UIController.lua"),
            Path("StarterGui/UIController.lua"),
        ]
    )
    if text is None:
        return []

    issues: list[str] = []
    required = [
        "EnterNormalMode",
        "BattleEvent.OnClientEvent",
        "action == \"End\"",
        "UpdateBattleSkillButtons",
        "PlayerSkills",
    ]
    for token in required:
        if token not in text:
            issues.append(f"UIController missing token: {token}")
    return issues


def main() -> int:
    issues = check_game_manager() + check_ui_controller()
    if issues:
        print("; ".join(issues))
    else:
        print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
