# SESSION 2026-08-20g — UI package D (grid bags)

## Scope (P1-1)
Bag open: icon + stack grid, click → detail (ItemCatalog description + why tag).

## Studio
- `ReplicatedStorage.RealmOfSpirits.BagContentUI` — Mount API
- `ItemCatalog.GetIconEmoji` / `GetRarityColor`
- `UIController` wires `bagUI.Mount` (avoids Luau 200-local limit)

## Smoke (Client Play)
| Check | Result |
|-------|--------|
| UIController loads (no register overflow) | PASS |
| BagContentList = ScrollingFrame + BagGrid | PASS |
| BagDetailPanel present | PASS |
| Open BagSlot1 → cells with emoji/qty | PASS (4 cells) |
| Auto-select detail | «Ловушка · ловля» + Description |

## Docs mirrors
`studio/BagContentUI.lua`, `ItemCatalog.lua`, `UIController.lua` (Mount stub)
