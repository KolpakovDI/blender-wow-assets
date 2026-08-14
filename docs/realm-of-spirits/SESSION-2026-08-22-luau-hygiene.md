# SESSION 2026-08-22 — Luau / remote hygiene

## Scope

Проверка по `luau-roblox-style` + `roblox-client-server`. Полный перевод 54 модулей на `--!strict` **не делался** (GameManager/UIController ~2–3k строк — отдельный рефактор).

## Уже было ок

- Нет deprecated `wait()` / `spawn()` / `delay()` — везде `task.*`
- Нет `Instance.new(class, parent)` — Parent last
- Catch/Battle в Studio SoT уже требовали `TargetInstanceId` + range

## Исправлено (Studio + docs mirrors)

| Место | Проблема | Фикс |
|-------|----------|------|
| `GameManager` Catch | spiritId без tonumber; Inventory/Stats nil crash | tonumber + `or {}` |
| `GameManager` Battle | action spoof; EnemyId не number; Attack yield 0.18s; SkillIndex любой | typeof + tonumber + clamp 1–3 + без wait |
| `GameManager` Start | abilities только из шаблона | `playerSpirit.SkillIds` |
| `GameManager` Evolve | индекс без границ | clamp по `#Spirits` + CurrentSpiritId |
| `EvolutionSystem` | `ipairs(nil Inventory)` | nil-safe |
| `BattleOrchestrator` | skillIndex не число | floor/tonumber |
| `QuestSystem` | action любой тип | typeof string |

## Не трогали (долг)

- `--!strict` на гигантских Script/LocalScript
- Knit-разбиение GameManager/UIController
- Online AI mesh / PvP

## Studio

Открыт **AutoRecovery** (`RealmOfSpirits second_AutoRecovery_0.rbxl`). После правок — **Ctrl+S** в основной `RealmOfSpirits second.rbxl`, не только в recovery.
