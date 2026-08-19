# SESSION 2026-08-19 — W1 Sanctum smoke (Quest 304)

**MCP Play · Studio-only BFs + client remotes**

## Recipe

1. `QuestSeedCompletedBF` → Q1 done  
2. `QuestAcceptBF` → **304 Accept** (Player instance, not UserId)  
3. `KamiSanctumBF` SeedQA  
4. Client: `KamiSanctum` Open → PreviewSynthesize {1,2} → PreviewDisintegrate idx 2  

## Results

| Step | Result | Evidence |
|------|--------|----------|
| Q1 seed | **PASS** | `QuestSeedCompletedBF:Invoke(player, {1})` → true |
| 304 Accept | **PASS** | «Квест принят!» · ZoneHint «Святилище Ками у Мики (E)» |
| Open Sanctum | **PASS** | `KamiSanctumGui` visible |
| Preview Synth | **PASS** | Status: `Сила 0.60 · Unique ~8% · тир Common · медь 80 · осталось 3 \| vid Огненный Кот` |
| Preview Disintegrate | **PASS** | Status: `Возможный лут: Осколок: … · Звёзды: … \| осталось 8` (grouped 301/310) |
| Quest 304 progress | **PASS** | `OpenKamiSanctum` **1/1** · `ReadyToTurnIn: true` |

**Overall: PASS**

## Hands UI (2026-08-19)

Setup: Q1 seeded (Studio BF). **Hands path:** walk → **E** → click «Звёзды трансформации» → «Принять квест».

| Step | Result |
|------|--------|
| 304 in list at Mika | **PASS** |
| Mika dialogue (#301 / #310) | **PASS** |
| UI Accept → active 304 | **PASS** (server 0/1 OpenKamiSanctum) |
| NextStepChip → shrine | **PASS** (после fix: `QuestAccepted` + `ZoneHint`, sync `NextStepChip`) |

**Ctrl+S** после patch `QuestSystem`.

## Notes

- `QuestAcceptBF:Invoke(userId, …)` ломается (`QuestSystem:1372`) — передавать **Player**.
- `NextStepChip` остался на FTUE «Выход в Акихабару» — BF-Accept не шлёт `QuestAccepted` на клиент; в руках chip обновится после Accept через UI.
- `KamiSanctumShrine` не найден `FindFirstChild(..., true)` в client luau — Open всё равно OK (session open).
- Шум: `user_RoS_ShortGrass` FEFF — внешний plugin.

## SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** если были правки в Edit до Play.
