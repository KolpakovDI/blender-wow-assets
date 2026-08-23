# SESSION 2026-08-23 — W2 Exit side chain (113→114)

**Трек:** [`MONTH-PLAN-2026-09-dev.md`](MONTH-PLAN-2026-09-dev.md) W2 · candidate **C**  
**Place:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`  
**Тип:** MCP smoke (Server BFs, не hands)

## Вердикт: **PASS** (MCP Play)

| Шаг | Результат |
|-----|-----------|
| Seed Q1 complete | **PASS** |
| Accept **113** «Кэш у выхода» | **PASS** |
| `VisitZone` Exit | **PASS** (prog 1/1) |
| TurnIn **113** | **PASS** |
| Accept **114** «Искра на тропе» | **PASS** |
| `CollectItem` **101** ×1 (GrantItem + progress) | **PASS** (prog 1/1) |
| TurnIn **114** | **PASS** |

## Контент

| Id | Название | Цель | Prereq |
|----|----------|------|--------|
| **113** | Кэш у выхода | VisitZone **Exit** | Q1 |
| **114** | Искра на тропе | CollectItem **101** ×1 у Exit | Q113 |

- **Loot:** crystal **101** at `(-18, 2, 66)` — `WorldLootService`
- **SoT:** квесты inline в `QuestSystem.QuestDatabase` (нет `QuestCatalog` ModuleScript)
- **Mirror:** `QuestCatalog.lua` + `QuestUI.lua` + `WorldLootService.lua`

## Hotfix (smoke blocker)

Studio `QuestSystem:UpdateProgress` **не имел** ветки `VisitZone` — side 107–112 и новый 113 не прогрессировали через BF/ZoneSystem.

**Fix:** добавлен `elseif progressType == "VisitZone"` (ZoneDetail match) в SoT `QuestSystem`.

## Оговорки

- MCP BFs принимают **`Player`**, не `UserId` (`QuestAcceptBF` / `TurnIn` / `UpdateQuestProgress`).
- `GetPlayerDataBF.CompletedQuests` может не отражать свежий turn-in в том же Play — ориентир: BF return + prog 1/1.
- **Ctrl+S** place после сессии.

## Prior session

- **Hands Resonant loop PASS** (user) — [`SESSION-2026-08-23-resonant-loop-smoke.md`](SESSION-2026-08-23-resonant-loop-smoke.md)

## Next

Month **W3** Identity/Resonant depth (Dex `[R]` или essences в UI) · hands 113→114 пешком (Exit E + crystal)
