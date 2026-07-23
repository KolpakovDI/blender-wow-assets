from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
STUDIO = ROOT / "docs" / "realm-of-spirits" / "studio"


def read(name: str) -> str | None:
    path = STUDIO / name
    if not path.exists():
        return None
    return path.read_text(encoding="utf-8", errors="replace")


def extract_function(text: str, name: str) -> str | None:
    """Best-effort extract of `local function name(...)` body until next top-level function."""
    pattern = rf"local function {re.escape(name)}\b"
    match = re.search(pattern, text)
    if not match:
        return None
    start = match.start()
    next_fn = re.search(r"\nlocal function |\nfunction ", text[match.end() :])
    end = match.end() + next_fn.start() if next_fn else len(text)
    return text[start:end]


def check_gacha_cosmetics_only(haven: str) -> list[str]:
    issues: list[str] = []
    body = extract_function(haven, "grantGachaReward")
    if body is None:
        return ["OtakuHavenService missing grantGachaReward"]

    if "playerData.Cosmetics" not in body:
        issues.append("grantGachaReward must write playerData.Cosmetics")
    if 'Type = "Cosmetic"' not in body and "Type = 'Cosmetic'" not in body:
        issues.append("grantGachaReward must return Type = Cosmetic")
    if "только косметика" not in body:
        issues.append("grantGachaReward message must say только косметика")

    # Combat inventory grants inside gacha reward = pay/coin → combat regression
    banned = [
        "giveInventoryItem",
        "ItemId = 1",
        "ItemId = 2",
        'Id = 1, Quantity',
        'Id = 2, Quantity',
    ]
    for token in banned:
        if token in body:
            issues.append(f"grantGachaReward must not grant combat inventory ({token})")

    return issues


def check_flex(haven: str) -> list[str]:
    issues: list[str] = []
    for token in (
        "EquippedCosmeticId",
        "applyFlexVisual",
        "OpenWardrobe",
        "EquipCosmetic",
        "FlexBillboard",
    ):
        if token not in haven:
            issues.append(f"OtakuHavenService missing flex token: {token}")
    return issues


def check_gacha_ui_clarity(controller: str) -> list[str]:
    issues: list[str] = []
    if "Disclaimer" not in controller:
        issues.append("OtakuHavenController missing Gacha Disclaimer label")
    if "Только косметика" not in controller and "только косметика" not in controller:
        issues.append("OtakuHavenController must show косметика clarity text")
    if "FlexWardrobeGui" not in controller:
        issues.append("OtakuHavenController missing FlexWardrobeGui")
    return issues


def check_item_catalog(catalog: str) -> list[str]:
    issues: list[str] = []
    for item_id in (1, 2, 3):
        # Shop combat utilities must be flagged for audits
        pattern = rf"\[{item_id}\]\s*=\s*\{{[^}}]*CombatUtility\s*="
        if not re.search(pattern, catalog, re.DOTALL):
            issues.append(f"ItemCatalog shop id {item_id} missing CombatUtility flag")
    if "IsCombatUtility" not in catalog:
        issues.append("ItemCatalog missing IsCombatUtility helper")
    return issues


def check_trade(trade: str) -> list[str]:
    issues: list[str] = []
    for token in (
        'Name = "PlayerTrade"',
        "isInSafeZone",
        'action == "Request"',
        'action == "SetOffer"',
        'action == "Ready"',
        "Обмен только в Safe",
        "MAX_DISTANCE",
    ):
        if token not in trade:
            issues.append(f"PlayerTradeSystem missing token: {token}")
    return issues


def check_trade_client(controller: str) -> list[str]:
    issues: list[str] = []
    for token in (
        'WaitForChild("PlayerTrade")',
        'FireServer("SetOffer"',
        'FireServer("Ready"',
        "PlayerTradeGui",
        "InPlayerTrade",
    ):
        if token not in controller:
            issues.append(f"PlayerTradeController missing token: {token}")
    return issues


def check_interact_client(controller: str) -> list[str]:
    issues: list[str] = []
    for token in (
        "PlayerInteractGui",
        'FireServer("Request"',
        "Обмен",
        "Дуэль",
    ):
        if token not in controller:
            issues.append(f"PlayerInteractController missing token: {token}")
    return issues


def main() -> int:
    issues: list[str] = []

    haven = read("OtakuHavenService.lua")
    if haven is None:
        print("OtakuHavenService.lua: missing docs mirror")
        return 1
    issues += check_gacha_cosmetics_only(haven)
    issues += check_flex(haven)

    haven_ui = read("OtakuHavenController.lua")
    if haven_ui is None:
        issues.append("OtakuHavenController.lua: missing docs mirror")
    else:
        issues += check_gacha_ui_clarity(haven_ui)

    catalog = read("ItemCatalog.lua")
    if catalog is None:
        issues.append("ItemCatalog.lua: missing docs mirror")
    else:
        issues += check_item_catalog(catalog)

    trade = read("PlayerTradeSystem.lua")
    if trade is None:
        issues.append("PlayerTradeSystem.lua: missing docs mirror")
    else:
        issues += check_trade(trade)

    trade_ui = read("PlayerTradeController.lua")
    if trade_ui is None:
        issues.append("PlayerTradeController.lua: missing docs mirror")
    else:
        issues += check_trade_client(trade_ui)

    interact_ui = read("PlayerInteractController.lua")
    if interact_ui is None:
        issues.append("PlayerInteractController.lua: missing docs mirror")
    else:
        issues += check_interact_client(interact_ui)

    policy = ROOT / "docs" / "realm-of-spirits" / "FAIR-COMBAT.md"
    if not policy.exists():
        issues.append("FAIR-COMBAT.md missing")

    if issues:
        print("; ".join(issues))
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
