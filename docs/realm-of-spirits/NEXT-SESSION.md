# NEXT SESSION

**Статус:** Checkpoint 2026-07-24 evening. Habitats + Путь Охотника 201–206 в Studio. **Play QA hunt** pending. PvP/MistPond PASS.

Дата якоря: 2026-07-24 → продолжение вечером / следующий день

## Старт сессии (порядок жёсткий)

1. Place SoT: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** если не сохранял
2. Studio MCP `user-Roblox_Studio` (если error → Restart MCP)
3. Этот файл
4. **Play QA: Путь Охотника** (ниже)

## Product progress

| Тема | Статус |
|------|--------|
| P0–P1 Core / Haven / Social | **DONE** |
| P2 PvP vertical slice | **DONE** (2p PASS) |
| P2 MistPond + Water Carp #6 | **DONE** (Play QA PASS) |
| Spirit habitats spread | **DONE** (min ~99 studs) |
| Hunt quest chain 201–206 | **CODE IN STUDIO** — Play QA pending |

## Точный next step (игра)

1. Ctrl+S → Play
2. Мика → **Путь Охотника I: Огонь**
3. Акихабара → поймать Огненного Кота → сдать → Знак Угольного Двора + медь/XP
4. Цепочка 202→206 (Корона Рассвета на финале)

После PASS → polish эво #106 (светлый реф) или доработка hunt UX.

## Закрыто 2026-07-24

- Духи разнесены: Combat / FrostRidge / MistPond / ShadowHollow / StormSpire / DawnMeadow
- `ZoneConfig.SpiritHabitats` HuntOrder; WorldSpawner `BuildSpiritHabitats`; loot по стихиям
- GameManager: raycast ignore BattleArena dome
- QuestSystem: Hunt 201–206, `CatchSpecificSpirit`, UniqueItems 8–13
- UI: QuestUI / QuestTrackerHud / ClientController `catch_hunt`

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` (не в git). **Ctrl+S.**

Ключевые модули: `ZoneConfig`, `WorldSpawner`, `WorldLootService`, `ZoneSystem`, `ZoneController`, `MusicController`, `GameManager`, `QuestSystem`, `QuestUI`, `QuestTrackerHud`, `ClientController`

Quality: `python scripts/quality_gate.py`
