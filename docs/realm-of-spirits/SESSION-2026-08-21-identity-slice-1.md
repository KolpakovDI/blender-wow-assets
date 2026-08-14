# SESSION 2026-08-21 — Identity slice 1 (вид + удар)

## Goal

После эволюции игрок видит **новый mesh** и **другой skill в слоте 1** (не только запись Id в данных).

## Root cause

Evolved `SkillIds` держали базовые навыки первыми (`11 → {1,2}`, `1011 → {1,2,3}`), поэтому слот 1 оставался «Огненный коготь». Templates уже разные (`SpiritTemplate11` vs `SpiritTemplate1011`).

## Fixes (Studio SoT)

| Module | Change |
|--------|--------|
| `SpiritDatabase` | Evolved `SkillIds`: signature storm skill **first** (напр. 1011 `{3,1,2}`) |
| `SkillCatalog.SpiritSkills` | Тот же порядок |
| `EvolutionSystem` | `UnlockedSkill` = `Skills[1]` (slot 1) |
| `GameManager` | `BuildPlayerAbilities` из `playerSpirit.SkillIds`; на Evolve: `CurrentSpiritId` + `ActiveSpiritName`; `DevBoostIdentity` ставит **Bond≥3**; `EvolveSpiritBF` синхронит Id/имя |
| `UIController` | `EvolutionSuccess` мержит `NewSpirit` в `PlayerData` сразу; toast с unlocked skill |

## Smoke (Studio Play / Server BF)

1. `PrepareEvoBF(userId, 11)` → lvl10 / bond3 / wins10 / crystals101×5  
2. `EvolveSpiritBF(userId, 1)` → **PASS**
   - `after.id=1011`, name «Огненный Тигр»
   - `slot1=Огненный шторм`, `attackDiff=true`
   - mesh `SpiritTemplate1011`

Edit verify earlier: `baseSlot1=Огненный коготь` vs `evoSlot1=Огненный шторм`.

## Manual (optional eyes)

`LeftAlt+B` / DevBoost → Evolve spirit 1 → бой слот 1 = «Огненный шторм»; UI имя «Огненный Тигр».

## Docs mirrors

`SpiritDatabase.lua`, `SkillCatalog.lua`, `GameManager.lua`, `UIController.lua`, `EvolutionSystem.lua`

## Checkpoint

Сохранено в `SESSION-2026-08-21-checkpoint.md` + `NEXT-SESSION.md` (2026-08-21). Следующее: week wrap.
